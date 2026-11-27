// Package lists owns Lists and their Items: creating, naming, deleting and
// restoring Lists, purging deleted ones after RestoreWindow, and adding,
// changing, checking and removing Items. Package sync carries Item changes to
// and from devices (ADR-0001) and calls this package to apply and read them.
//
// Every change a sync pull must see is numbered by package changeseq: an
// Item's every change, and a List's deletion and restore, so pulls tell
// Members the List went away or came back.
//
// Who may see or change a List is decided by package membership; this package
// asks it and never reads list_members itself. Users are known only by ID.
package lists

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/platform/changeseq"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
	"github.com/tsantanadev/cesta/backend/internal/platform/names"
)

// MaxNameLength is the longest List name, in characters.
const MaxNameLength = 60

// DefaultMaxPerUser is how many Lists a User can own that are not deleted.
const DefaultMaxPerUser = 100

var (
	// ErrInvalidName is returned for a name that is empty after trimming, longer
	// than MaxNameLength or contains control characters.
	ErrInvalidName error = listError("invalid list name")
	// ErrIDTaken is returned when creating a List with an ID another User's List has.
	ErrIDTaken error = listError("list id taken")
	// ErrLimitReached is returned when the User already owns the most Lists allowed.
	ErrLimitReached error = listError("list limit reached")
	// ErrNotFound is returned when the List doesn't exist, is gone for good, or
	// the User is not a Member of it. The three are indistinguishable on purpose.
	ErrNotFound error = listError("list not found")
	// ErrNotOwner is returned when a Member who is not the Owner tries an Owner-only change.
	ErrNotOwner error = listError("not the list owner")
	// ErrDeleted is returned for a change to a deleted List other than restoring it.
	ErrDeleted error = listError("list deleted")
)

// RestoreWindow is how long after deletion the Owner can restore a List. After
// it the List is gone, and the purge removes it.
const RestoreWindow = 30 * 24 * time.Hour

// Summary is a List as one of its Members sees it.
type Summary struct {
	ID          uuid.UUID
	Name        string
	Role        membership.Role
	MemberCount int
	CreatedAt   time.Time
}

// Deleted is a deleted List its Owner can still restore.
type Deleted struct {
	ID        uuid.UUID
	Name      string
	DeletedAt time.Time
	// PurgeAt is when the List stops being restorable: DeletedAt + RestoreWindow.
	PurgeAt time.Time
}

// Service manages Lists.
type Service struct {
	db         *pgxpool.Pool
	clock      clock.Clock
	members    *membership.Service
	maxPerUser int
	maxItems   int
}

// Limits are how much a User and a List can hold. Zero fields take the defaults.
type Limits struct {
	// ListsPerUser is how many live Lists a User can own; 0 means DefaultMaxPerUser.
	ListsPerUser int
	// ItemsPerList is how many Items a List can hold; 0 means DefaultMaxItemsPerList.
	ItemsPerList int
}

// NewService returns a Service backed by db, with limits.
func NewService(db *pgxpool.Pool, c clock.Clock, members *membership.Service, limits Limits) *Service {
	if limits.ListsPerUser <= 0 {
		limits.ListsPerUser = DefaultMaxPerUser
	}
	if limits.ItemsPerList <= 0 {
		limits.ItemsPerList = DefaultMaxItemsPerList
	}
	return &Service{db: db, clock: c, members: members, maxPerUser: limits.ListsPerUser, maxItems: limits.ItemsPerList}
}

// MaxPerUser returns the configured maximum number of live Lists a User can own.
func (s *Service) MaxPerUser() int {
	return s.maxPerUser
}

// Create makes a List with the client-chosen id, owned by owner. Retrying with
// an id owner already has returns that List unchanged and created false.
func (s *Service) Create(ctx context.Context, owner, id uuid.UUID, name string) (sum Summary, created bool, err error) {
	name, ok := normalizeName(name)
	if !ok {
		return Summary{}, false, ErrInvalidName
	}
	now := s.clock.Now()
	err = pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		// Lock the owner first so a retry racing the original create sees it.
		if err := lockOwner(ctx, tx, owner); err != nil {
			return err
		}
		var existingOwner uuid.UUID
		var deletedAt *time.Time
		err := tx.QueryRow(ctx, "SELECT owner_id, deleted_at FROM lists WHERE id = $1", id).
			Scan(&existingOwner, &deletedAt)
		switch {
		case err == nil && existingOwner == owner && deletedAt != nil:
			return ErrDeleted
		case err == nil && existingOwner == owner:
			return nil // a retry
		case err == nil:
			return ErrIDTaken
		case !errors.Is(err, pgx.ErrNoRows):
			return err
		}
		if err := s.requireRoomFor(ctx, tx, owner); err != nil {
			return err
		}
		tag, err := tx.Exec(ctx, `
			INSERT INTO lists (id, owner_id, name, created_at, updated_at) VALUES ($1, $2, $3, $4, $4)
			ON CONFLICT (id) DO NOTHING`, id, owner, name, now)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrIDTaken // another User created it concurrently
		}
		created = true
		return s.members.Grant(ctx, tx, id, owner, membership.Owner, now)
	})
	if err != nil {
		return Summary{}, false, wrap("create", err)
	}
	sum, err = s.summary(ctx, id, owner)
	return sum, created, err
}

// Mine returns every List userID is a Member of that is not deleted, newest first.
func (s *Service) Mine(ctx context.Context, userID uuid.UUID) ([]Summary, error) {
	ms, err := s.members.Memberships(ctx, userID)
	if err != nil {
		return nil, err
	}
	byList := make(map[uuid.UUID]membership.Membership, len(ms))
	ids := make([]uuid.UUID, 0, len(ms))
	for _, m := range ms {
		byList[m.ListID] = m
		ids = append(ids, m.ListID)
	}
	rows, err := s.db.Query(ctx, `
		SELECT id, name, created_at FROM lists
		WHERE id = ANY($1) AND deleted_at IS NULL
		ORDER BY created_at DESC, id`, ids)
	if err != nil {
		return nil, wrap("mine", err)
	}
	out, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Summary, error) {
		var l Summary
		if err := row.Scan(&l.ID, &l.Name, &l.CreatedAt); err != nil {
			return Summary{}, err
		}
		m := byList[l.ID]
		l.Role, l.MemberCount = m.Role, m.MemberCount
		return l, nil
	})
	if err != nil {
		return nil, wrap("mine", err)
	}
	return out, nil
}

// Rename sets the name of a List userID owns.
func (s *Service) Rename(ctx context.Context, userID, listID uuid.UUID, name string) (Summary, error) {
	name, ok := normalizeName(name)
	if !ok {
		return Summary{}, ErrInvalidName
	}
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		l, err := s.lockOwned(ctx, tx, userID, listID)
		if err != nil {
			return err
		}
		if l.deletedAt != nil {
			return ErrDeleted
		}
		_, err = tx.Exec(ctx,
			"UPDATE lists SET name = $2, updated_at = $3 WHERE id = $1 AND deleted_at IS NULL",
			listID, name, s.clock.Now())
		return err
	})
	if err != nil {
		return Summary{}, wrap("rename", err)
	}
	return s.summary(ctx, listID, userID)
}

// Delete deletes a List userID owns, for every Member at once. The Owner can
// restore it within RestoreWindow. Deleting a deleted List changes nothing.
func (s *Service) Delete(ctx context.Context, userID, listID uuid.UUID) (Deleted, error) {
	d := Deleted{ID: listID}
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		l, err := s.lockOwned(ctx, tx, userID, listID)
		if err != nil {
			return err
		}
		d.Name = l.name
		if l.deletedAt != nil {
			d.DeletedAt = l.deletedAt.UTC() // keep the original deletion time
			return nil
		}
		d.DeletedAt = s.clock.Now()
		seq, err := changeseq.Next(ctx, tx)
		if err != nil {
			return err
		}
		_, err = tx.Exec(ctx, "UPDATE lists SET deleted_at = $2, updated_at = $2, visible_seq = $3 WHERE id = $1",
			listID, d.DeletedAt, seq)
		return err
	})
	if err != nil {
		return Deleted{}, wrap("delete", err)
	}
	d.PurgeAt = d.DeletedAt.Add(RestoreWindow)
	return d, nil
}

// Restore brings back a List userID owns and deleted less than RestoreWindow
// ago, for every Member. Restoring a List that isn't deleted changes nothing.
func (s *Service) Restore(ctx context.Context, userID, listID uuid.UUID) (Summary, error) {
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		// The owner before the List, in the same order as Create.
		if err := lockOwner(ctx, tx, userID); err != nil {
			return err
		}
		l, err := s.lockOwned(ctx, tx, userID, listID)
		if err != nil || l.deletedAt == nil {
			return err
		}
		if err := s.requireRoomFor(ctx, tx, userID); err != nil {
			return err
		}
		seq, err := changeseq.Next(ctx, tx)
		if err != nil {
			return err
		}
		_, err = tx.Exec(ctx, "UPDATE lists SET deleted_at = NULL, updated_at = $2, visible_seq = $3 WHERE id = $1",
			listID, s.clock.Now(), seq)
		return err
	})
	if err != nil {
		return Summary{}, wrap("restore", err)
	}
	return s.summary(ctx, listID, userID)
}

// lockOwner takes a transaction-scoped advisory lock for owner. Every change
// that adds to the Lists owner owns takes it first, so two at the limit can't
// both pass.
func lockOwner(ctx context.Context, tx pgx.Tx, owner uuid.UUID) error {
	_, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock(hashtextextended('lists:owner:' || $1, 0))", owner.String())
	return err
}

// requireRoomFor returns ErrLimitReached if owner already owns the most Lists
// allowed. The caller holds lockOwner.
func (s *Service) requireRoomFor(ctx context.Context, tx pgx.Tx, owner uuid.UUID) error {
	var owned int
	if err := tx.QueryRow(ctx,
		"SELECT count(*) FROM lists WHERE owner_id = $1 AND deleted_at IS NULL", owner).Scan(&owned); err != nil {
		return err
	}
	if owned >= s.maxPerUser {
		return ErrLimitReached
	}
	return nil
}

// Purge removes for good every List deleted at least RestoreWindow before now,
// with its memberships, and returns how many it removed. Reads already treat
// such Lists as gone, so how long after the window the purge runs doesn't show.
func (s *Service) Purge(ctx context.Context, now time.Time) (int, error) {
	var n int
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx,
			"DELETE FROM lists WHERE deleted_at IS NOT NULL AND deleted_at <= $1", now.Add(-RestoreWindow))
		if err != nil {
			return wrap("purge", err)
		}
		n = int(tag.RowsAffected())
		return nil
	})
	return n, err
}

// RecentlyDeleted returns the Lists owner deleted and can still restore, most
// recently deleted first. Lists other Users own never appear here.
func (s *Service) RecentlyDeleted(ctx context.Context, owner uuid.UUID) ([]Deleted, error) {
	rows, err := s.db.Query(ctx, `
		SELECT id, name, deleted_at FROM lists
		WHERE owner_id = $1 AND deleted_at IS NOT NULL AND deleted_at > $2
		ORDER BY deleted_at DESC, id`, owner, s.clock.Now().Add(-RestoreWindow))
	if err != nil {
		return nil, wrap("recently deleted", err)
	}
	out, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Deleted, error) {
		var d Deleted
		err := row.Scan(&d.ID, &d.Name, &d.DeletedAt)
		d.DeletedAt = d.DeletedAt.UTC()
		d.PurgeAt = d.DeletedAt.Add(RestoreWindow)
		return d, err
	})
	if err != nil {
		return nil, wrap("recently deleted", err)
	}
	return out, nil
}

// listRow is the state of a List the access checks need.
type listRow struct {
	name      string
	deletedAt *time.Time
}

// lockOwned locks listID until tx ends and returns it if userID owns it, so
// the caller's change can't race a delete or the purge. It returns ErrNotFound
// if userID is not a Member or the List is gone (purged, or deleted longer than
// RestoreWindow ago), and ErrNotOwner for any other Member.
func (s *Service) lockOwned(ctx context.Context, tx pgx.Tx, userID, listID uuid.UUID) (listRow, error) {
	role, err := s.members.RoleIn(ctx, tx, listID, userID)
	if errors.Is(err, membership.ErrNotAMember) {
		return listRow{}, ErrNotFound
	}
	if err != nil {
		return listRow{}, err
	}
	var l listRow
	err = tx.QueryRow(ctx, "SELECT name, deleted_at FROM lists WHERE id = $1 FOR UPDATE", listID).
		Scan(&l.name, &l.deletedAt)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return listRow{}, ErrNotFound
	case err != nil:
		return listRow{}, err
	case l.deletedAt != nil && !s.restorable(*l.deletedAt):
		return listRow{}, ErrNotFound
	case role != membership.Owner:
		return listRow{}, ErrNotOwner
	}
	return l, nil
}

// restorable reports whether a List deleted at deletedAt can still be restored.
func (s *Service) restorable(deletedAt time.Time) bool {
	return s.clock.Now().Before(deletedAt.Add(RestoreWindow))
}

// summary returns listID as userID sees it, or ErrNotFound if it was purged
// (or userID removed) since the caller's change committed.
func (s *Service) summary(ctx context.Context, listID, userID uuid.UUID) (Summary, error) {
	role, err := s.members.RoleOf(ctx, listID, userID)
	if errors.Is(err, membership.ErrNotAMember) {
		return Summary{}, ErrNotFound
	}
	if err != nil {
		return Summary{}, err
	}
	count, err := s.members.Count(ctx, listID)
	if err != nil {
		return Summary{}, err
	}
	l := Summary{ID: listID, Role: role, MemberCount: count}
	err = s.db.QueryRow(ctx, "SELECT name, created_at FROM lists WHERE id = $1", listID).Scan(&l.Name, &l.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return Summary{}, ErrNotFound
	}
	if err != nil {
		return Summary{}, wrap("read", err)
	}
	return l, nil
}

// listError is the type of this package's sentinel errors, so wrap can pass
// every one of them through without keeping a list.
type listError string

func (e listError) Error() string { return string(e) }

// wrap adds context to unexpected errors and passes sentinel errors through.
func wrap(what string, err error) error {
	if err == nil {
		return nil
	}
	if _, ok := errors.AsType[listError](err); ok {
		return err
	}
	return fmt.Errorf("lists: %s: %w", what, err)
}

// normalizeName trims name and reports whether it is acceptable.
func normalizeName(name string) (string, bool) {
	return names.Normalize(name, MaxNameLength)
}
