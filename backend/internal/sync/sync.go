// Package sync owns Items and the offline-first sync of them (ADR-0001).
//
// Devices push batches of mutations from their outbox and pull the changes
// made since their cursor. The server is authoritative:
//   - Every mutation is idempotent by its client mutation ID: the first result
//     is stored and returned again on any retry.
//   - Each mutation re-checks that the User is a Member of the Item's List
//     (package membership decides).
//   - Conflicts resolve last-write-wins per field, in order of server receipt.
//     A mutation changes only the fields it carries.
//   - A delete wins: a removed Item keeps a tombstone row, and later edits to it
//     are rejected with ReasonItemDeleted.
//
// Every change a pull must see is numbered by package changeseq, so a pull
// cursor is a position in one ordered stream of changes.
package sync

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
)

// DefaultMaxItemsPerList is how many Items a List can hold, not counting removed ones.
const DefaultMaxItemsPerList = 500

// MaxBatch is the most mutations one push can carry.
const MaxBatch = 100

// MutationType is what a mutation does to its Item.
type MutationType string

// The mutation types.
const (
	ItemCreate MutationType = "item_create"
	ItemUpdate MutationType = "item_update"
	ItemDelete MutationType = "item_delete"
)

// Field is an optional field of a mutation. Present false leaves the field as
// it is; Present with a nil Value clears it.
type Field[T any] struct {
	Present bool
	Value   *T
}

// Fields are the Item fields a mutation sets.
type Fields struct {
	// Name is required on ItemCreate and can't be cleared; nil leaves it as it is.
	Name     *string
	Quantity Field[string]
	Unit     Field[string]
	Note     Field[string]
	// Checked true marks the Item bought by the pushing User at receipt time;
	// false unchecks it; nil leaves it as it is.
	Checked *bool
}

// Mutation is one change from a device's outbox.
type Mutation struct {
	// ID is chosen by the client; retrying the same ID is safe.
	ID       uuid.UUID
	Type     MutationType
	EntityID uuid.UUID
	// ListID is required on ItemCreate and ignored otherwise.
	ListID uuid.UUID
	Fields Fields
	// ClientTimestamp is recorded for diagnosis only; receipt order decides conflicts.
	ClientTimestamp time.Time
}

// Reason is why a mutation was rejected. The values are the API error codes.
type Reason string

// The reasons a mutation is rejected.
const (
	ReasonInvalidRequest Reason = "invalid_request"
	ReasonInvalidItem    Reason = "invalid_item"
	ReasonItemNotFound   Reason = "item_not_found"
	ReasonItemDeleted    Reason = "item_deleted"
	ReasonListNotFound   Reason = "list_not_found"
	ReasonListDeleted    Reason = "list_deleted"
	ReasonLimitExceeded  Reason = "limit_exceeded"
)

// Result is what became of a mutation.
type Result struct {
	MutationID uuid.UUID
	Applied    bool
	// Reason, Message and (for ReasonLimitExceeded) Limit explain a rejection.
	Reason  Reason
	Message string
	Limit   int
}

// ErrInvalidBatch is returned for a push with no mutations, more than
// MaxBatch, or a mutation without an ID.
var ErrInvalidBatch = errors.New("sync: invalid batch")

// Service applies pushed mutations and serves pulls.
type Service struct {
	db       *pgxpool.Pool
	clock    clock.Clock
	members  *membership.Service
	maxItems int
}

// NewService returns a Service backed by db. maxItemsPerList <= 0 means DefaultMaxItemsPerList.
func NewService(db *pgxpool.Pool, c clock.Clock, members *membership.Service, maxItemsPerList int) *Service {
	if maxItemsPerList <= 0 {
		maxItemsPerList = DefaultMaxItemsPerList
	}
	return &Service{db: db, clock: c, members: members, maxItems: maxItemsPerList}
}

// Push applies ms in order, each in its own transaction, on behalf of userID
// and returns one Result per mutation. A rejection never stops the batch; an
// unexpected error does, leaving the mutations before it applied.
func (s *Service) Push(ctx context.Context, userID uuid.UUID, ms []Mutation) ([]Result, error) {
	if len(ms) == 0 || len(ms) > MaxBatch {
		return nil, ErrInvalidBatch
	}
	for _, m := range ms {
		if m.ID == uuid.Nil {
			return nil, ErrInvalidBatch
		}
	}
	out := make([]Result, 0, len(ms))
	for _, m := range ms {
		r, err := s.pushOne(ctx, userID, m)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, nil
}

// pushOne applies m once: a retry returns the stored result unchanged.
func (s *Service) pushOne(ctx context.Context, userID uuid.UUID, m Mutation) (Result, error) {
	var res Result
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		// Serialize concurrent retries of the same mutation.
		if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock(hashtextextended('sync:mutation:' || $1 || ':' || $2, 0))",
			userID.String(), m.ID.String()); err != nil {
			return err
		}
		stored, found, err := storedResult(ctx, tx, userID, m.ID)
		if err != nil || found {
			res = stored
			return err
		}
		now := s.clock.Now()
		res, err = s.apply(ctx, tx, userID, m, now)
		if err != nil {
			return err
		}
		res.MutationID = m.ID
		var limit *int
		if res.Limit > 0 {
			limit = &res.Limit
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO sync_mutations (user_id, id, applied, reason_code, reason, reason_limit, received_at)
			VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''), $6, $7)`,
			userID, m.ID, res.Applied, string(res.Reason), res.Message, limit, now)
		return err
	})
	if err != nil {
		return Result{}, fmt.Errorf("sync: push: %w", err)
	}
	return res, nil
}

func storedResult(ctx context.Context, tx pgx.Tx, userID, mutationID uuid.UUID) (Result, bool, error) {
	r := Result{MutationID: mutationID}
	var code, msg *string
	var limit *int
	err := tx.QueryRow(ctx,
		"SELECT applied, reason_code, reason, reason_limit FROM sync_mutations WHERE user_id = $1 AND id = $2",
		userID, mutationID).Scan(&r.Applied, &code, &msg, &limit)
	if errors.Is(err, pgx.ErrNoRows) {
		return Result{}, false, nil
	}
	if err != nil {
		return Result{}, false, err
	}
	if code != nil {
		r.Reason = Reason(*code)
	}
	if msg != nil {
		r.Message = *msg
	}
	if limit != nil {
		r.Limit = *limit
	}
	return r, true, nil
}

func applied() Result { return Result{Applied: true} }

func rejected(reason Reason, message string) Result {
	return Result{Reason: reason, Message: message}
}

// UncheckedCounts returns how many Items to buy (not removed, not checked)
// each of listIDs has. Lists with none are missing from the map.
func (s *Service) UncheckedCounts(ctx context.Context, listIDs []uuid.UUID) (map[uuid.UUID]int, error) {
	rows, err := s.db.Query(ctx, `
		SELECT list_id, count(*) FROM items
		WHERE list_id = ANY($1) AND deleted_at IS NULL AND checked_at IS NULL
		GROUP BY list_id`, listIDs)
	if err != nil {
		return nil, fmt.Errorf("sync: unchecked counts: %w", err)
	}
	out := map[uuid.UUID]int{}
	var id uuid.UUID
	var n int
	_, err = pgx.ForEachRow(rows, []any{&id, &n}, func() error {
		out[id] = n
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("sync: unchecked counts: %w", err)
	}
	return out, nil
}
