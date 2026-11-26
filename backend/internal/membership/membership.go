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
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
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

// ErrNotOwner is returned by RequireOwner for a Member who is not the Owner.
var ErrNotOwner = errors.New("not the owner of the list")

// Membership is one List a User is a Member of.
type Membership struct {
	ListID uuid.UUID
	Role   Role
	// MemberCount is how many Members the List has, including the Owner.
	MemberCount int
}

// Querier runs queries, on the pool or inside a transaction.
type Querier interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// Service answers who is a Member of a List.
type Service struct {
	db *pgxpool.Pool
}

// NewService returns a Service backed by db.
func NewService(db *pgxpool.Pool) *Service {
	return &Service{db: db}
}

// Grant makes userID a Member of listID with role, as of at. It runs on q so the
// caller can make it part of a larger transaction.
func (s *Service) Grant(ctx context.Context, q Querier, listID, userID uuid.UUID, role Role, at time.Time) error {
	if _, err := q.Exec(ctx,
		"INSERT INTO list_members (list_id, user_id, role, joined_at) VALUES ($1, $2, $3, $4)",
		listID, userID, string(role), at); err != nil {
		return fmt.Errorf("membership: grant: %w", err)
	}
	return nil
}

// RoleOf returns userID's Role on listID, or ErrNotAMember.
func (s *Service) RoleOf(ctx context.Context, listID, userID uuid.UUID) (Role, error) {
	var role string
	err := s.db.QueryRow(ctx,
		"SELECT role FROM list_members WHERE list_id = $1 AND user_id = $2", listID, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotAMember
	}
	if err != nil {
		return "", fmt.Errorf("membership: role: %w", err)
	}
	return Role(role), nil
}

// RequireOwner returns nil if userID is the Owner of listID, ErrNotOwner if they
// are another kind of Member, and ErrNotAMember if they are not a Member.
func (s *Service) RequireOwner(ctx context.Context, listID, userID uuid.UUID) error {
	role, err := s.RoleOf(ctx, listID, userID)
	if err != nil {
		return err
	}
	if role != Owner {
		return ErrNotOwner
	}
	return nil
}

// Of returns every List userID is a Member of.
func (s *Service) Of(ctx context.Context, userID uuid.UUID) ([]Membership, error) {
	rows, err := s.db.Query(ctx, `
		SELECT m.list_id, m.role, (SELECT count(*) FROM list_members c WHERE c.list_id = m.list_id)
		FROM list_members m WHERE m.user_id = $1`, userID)
	if err != nil {
		return nil, fmt.Errorf("membership: of: %w", err)
	}
	ms, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Membership, error) {
		var m Membership
		var role string
		err := row.Scan(&m.ListID, &role, &m.MemberCount)
		m.Role = Role(role)
		return m, err
	})
	if err != nil {
		return nil, fmt.Errorf("membership: of: %w", err)
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
