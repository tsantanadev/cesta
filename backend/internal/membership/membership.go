// Package membership owns who is a Member of which List and with what Role.
// It is the authorization source for List access: other modules ask it whether
// a User is a Member, and whether they are the Owner.
//
// It knows Lists and Users only by ID. The lists module calls Grant inside its
// own transaction when it creates a List, so the List and its Owner appear together.
package membership

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/tsantanadev/cesta/backend/internal/platform/changeseq"
)

// Role is a Member's level of access on a List.
type Role string

// The Roles a Member can have.
const (
	Owner  Role = "owner"
	Editor Role = "editor"
)

// ErrNotAMember is returned when the User has no Role on the List.
var ErrNotAMember = errors.New("not a member of the list")

// Membership is one List a User is a Member of.
type Membership struct {
	ListID uuid.UUID
	Role   Role
	// MemberCount is how many Members the List has, including the Owner.
	MemberCount int
}

// Service answers who is a Member of a List.
type Service struct {
	db *pgxpool.Pool
}

// NewService returns a Service backed by db.
func NewService(db *pgxpool.Pool) *Service {
	return &Service{db: db}
}

// Grant makes userID a Member of listID with role, as of at, inside the
// caller's transaction tx. Joining is a numbered change (package changeseq),
// so the User's next sync pull brings the whole List.
func (s *Service) Grant(ctx context.Context, tx pgx.Tx, listID, userID uuid.UUID, role Role, at time.Time) error {
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return fmt.Errorf("membership: grant: %w", err)
	}
	if _, err := tx.Exec(ctx,
		"INSERT INTO list_members (list_id, user_id, role, joined_at, seq) VALUES ($1, $2, $3, $4, $5)",
		listID, userID, string(role), at, seq); err != nil {
		return fmt.Errorf("membership: grant: %w", err)
	}
	return nil
}

// RoleOf returns userID's Role on listID, or ErrNotAMember.
func (s *Service) RoleOf(ctx context.Context, listID, userID uuid.UUID) (Role, error) {
	return roleOf(ctx, s.db, listID, userID)
}

// RoleIn is RoleOf inside the caller's transaction tx, so the answer holds for
// the rest of a change made under a lock the caller took on the List.
func (s *Service) RoleIn(ctx context.Context, tx pgx.Tx, listID, userID uuid.UUID) (Role, error) {
	return roleOf(ctx, tx, listID, userID)
}

func roleOf(ctx context.Context, q interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}, listID, userID uuid.UUID,
) (Role, error) {
	var role string
	err := q.QueryRow(ctx,
		"SELECT role FROM list_members WHERE list_id = $1 AND user_id = $2", listID, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotAMember
	}
	if err != nil {
		return "", fmt.Errorf("membership: role: %w", err)
	}
	return Role(role), nil
}

// Joined is a List a User is a Member of, and the change number (package
// changeseq) at which they joined it.
type Joined struct {
	ListID uuid.UUID
	Seq    int64
}

// JoinedIn returns every List userID is a Member of, with when they joined
// it, read inside the caller's transaction tx.
func (s *Service) JoinedIn(ctx context.Context, tx pgx.Tx, userID uuid.UUID) ([]Joined, error) {
	rows, err := tx.Query(ctx, "SELECT list_id, seq FROM list_members WHERE user_id = $1", userID)
	if err != nil {
		return nil, fmt.Errorf("membership: joined: %w", err)
	}
	js, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Joined, error) {
		var j Joined
		err := row.Scan(&j.ListID, &j.Seq)
		return j, err
	})
	if err != nil {
		return nil, fmt.Errorf("membership: joined: %w", err)
	}
	return js, nil
}

// Memberships returns every List userID is a Member of, with their Role on it.
func (s *Service) Memberships(ctx context.Context, userID uuid.UUID) ([]Membership, error) {
	rows, err := s.db.Query(ctx, `
		SELECT m.list_id, m.role, (SELECT count(*) FROM list_members c WHERE c.list_id = m.list_id)
		FROM list_members m WHERE m.user_id = $1`, userID)
	if err != nil {
		return nil, fmt.Errorf("membership: memberships: %w", err)
	}
	ms, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Membership, error) {
		var m Membership
		var role string
		err := row.Scan(&m.ListID, &role, &m.MemberCount)
		m.Role = Role(role)
		return m, err
	})
	if err != nil {
		return nil, fmt.Errorf("membership: memberships: %w", err)
	}
	return ms, nil
}

// Count returns how many Members listID has.
func (s *Service) Count(ctx context.Context, listID uuid.UUID) (int, error) {
	var n int
	if err := s.db.QueryRow(ctx, "SELECT count(*) FROM list_members WHERE list_id = $1", listID).Scan(&n); err != nil {
		return 0, fmt.Errorf("membership: count: %w", err)
	}
	return n, nil
}

// DefaultMaxPerList is how many Members a List can have, including the Owner.
const DefaultMaxPerList = 20

// ErrListFull is returned by Join when the List already has the most Members allowed.
var ErrListFull = errors.New("list is full")

// Join makes userID an Editor of listID, as of at, inside the caller's
// transaction tx, unless they are already a Member (then joined is false and
// nothing changes). It returns ErrListFull if the List already has maxMembers
// Members. The caller holds a lock on the List, so two joins can't both take
// the last place.
func (s *Service) Join(ctx context.Context, tx pgx.Tx, listID, userID uuid.UUID, at time.Time, maxMembers int) (joined bool, err error) {
	_, err = roleOf(ctx, tx, listID, userID)
	switch {
	case err == nil:
		return false, nil
	case !errors.Is(err, ErrNotAMember):
		return false, err
	}
	var n int
	if err := tx.QueryRow(ctx, "SELECT count(*) FROM list_members WHERE list_id = $1", listID).Scan(&n); err != nil {
		return false, fmt.Errorf("membership: join: %w", err)
	}
	if n >= maxMembers {
		return false, ErrListFull
	}
	return true, s.Grant(ctx, tx, listID, userID, Editor, at)
}
