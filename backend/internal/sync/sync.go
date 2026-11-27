// Package sync carries Item changes between devices and the server, offline
// first (ADR-0001). Package lists owns the Items; this package applies the
// mutations devices push through it and serves the changes they pull.
//
// Devices push batches of mutations from their outbox and pull the changes
// made since their cursor. The server is authoritative:
//   - Every mutation is idempotent by its client mutation ID: the first result
//     is stored and returned again on any retry, with the client timestamp
//     recorded for diagnosis.
//   - Each mutation is applied by package lists, which re-checks under a lock
//     on the Item's List that the User is a Member of it and it is not deleted.
//   - Conflicts resolve last-write-wins per field, in order of server receipt.
//     A mutation changes only the fields it carries.
//   - A delete wins: a removed Item keeps a tombstone, and later edits to it
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

	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/lists"
	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
)

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

// Mutation is one change from a device's outbox.
type Mutation struct {
	// ID is chosen by the client; retrying the same ID is safe.
	ID       uuid.UUID
	Type     MutationType
	EntityID uuid.UUID
	// ListID is required on ItemCreate and ignored otherwise.
	ListID uuid.UUID
	// Fields are what ItemCreate and ItemUpdate set; Checked true marks the
	// Item bought by the pushing User at receipt time.
	Fields lists.ItemFields
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
	lists    *lists.Service
	members  *membership.Service
	identity *identity.Service
}

// NewService returns a Service backed by db.
func NewService(
	db *pgxpool.Pool, c clock.Clock, ls *lists.Service, members *membership.Service, users *identity.Service,
) *Service {
	return &Service{db: db, clock: c, lists: ls, members: members, identity: users}
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
			INSERT INTO sync_mutations (user_id, id, applied, reason_code, reason, reason_limit, received_at, client_timestamp)
			VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''), $6, $7, $8)`,
			userID, m.ID, res.Applied, string(res.Reason), res.Message, limit, now, clientTimestamp(m.ClientTimestamp))
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

// clientTimestamp is t to record, or nil when the client sent none.
func clientTimestamp(t time.Time) *time.Time {
	if t.IsZero() {
		return nil
	}
	return &t
}

// apply makes m's change inside tx through package lists, or returns why it can't.
func (s *Service) apply(ctx context.Context, tx pgx.Tx, userID uuid.UUID, m Mutation, now time.Time) (Result, error) {
	var err error
	switch m.Type {
	case ItemCreate:
		if m.ListID == uuid.Nil {
			return rejected(ReasonInvalidRequest, "listId is required to create an Item"), nil
		}
		err = s.lists.CreateItem(ctx, tx, userID, m.ListID, m.EntityID, m.Fields, now)
	case ItemUpdate:
		err = s.lists.UpdateItem(ctx, tx, userID, m.EntityID, m.Fields, now)
	case ItemDelete:
		err = s.lists.RemoveItem(ctx, tx, userID, m.EntityID, now)
	default:
		return rejected(ReasonInvalidRequest, fmt.Sprintf("unknown mutation type %q", m.Type)), nil
	}
	return result(err)
}

// result turns what package lists answered into a Result: a rejection for a
// change it refused, or the error for anything unexpected.
func result(err error) (Result, error) {
	if invalid, ok := errors.AsType[*lists.InvalidItemError](err); ok {
		return rejected(ReasonInvalidItem, invalid.Message), nil
	}
	if full, ok := errors.AsType[*lists.ItemLimitError](err); ok {
		r := rejected(ReasonLimitExceeded, fmt.Sprintf("the List already holds the limit of %d Items", full.Limit))
		r.Limit = full.Limit
		return r, nil
	}
	switch {
	case err == nil:
		return applied(), nil
	case errors.Is(err, lists.ErrNotFound):
		return rejected(ReasonListNotFound, "no such List"), nil
	case errors.Is(err, lists.ErrDeleted):
		return rejected(ReasonListDeleted, "the List is deleted"), nil
	case errors.Is(err, lists.ErrItemNotFound):
		return rejected(ReasonItemNotFound, "no such Item"), nil
	case errors.Is(err, lists.ErrItemDeleted):
		return rejected(ReasonItemDeleted, "the Item was removed"), nil
	case errors.Is(err, lists.ErrItemIDTaken):
		return rejected(ReasonInvalidItem, "another Item has this id"), nil
	default:
		return Result{}, err
	}
}

func applied() Result { return Result{Applied: true} }

func rejected(reason Reason, message string) Result {
	return Result{Reason: reason, Message: message}
}
