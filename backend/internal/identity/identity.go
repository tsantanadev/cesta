// Package identity owns Users: it maps a verified identity from the identity
// provider to the internal User, and holds the User's email and display name.
//
// It is the only module that sees the identity provider (ADR-0003): it
// verifies the provider's ID token, applies the per-User rate limit keyed by
// the provider's subject, and hands back the internal User. Other modules know
// a User only by its internal ID (User.ID), never by the provider's subject.
package identity

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
	"github.com/tsantanadev/cesta/backend/internal/platform/names"
	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
)

// MaxDisplayNameLength is the longest display name, in characters.
const MaxDisplayNameLength = 50

// ErrInvalidDisplayName is returned for a display name that is empty after
// trimming, longer than MaxDisplayNameLength or contains control characters.
var ErrInvalidDisplayName = errors.New("invalid display name")

// User is a person with a Cesta account.
type User struct {
	ID          uuid.UUID
	Email       string
	DisplayName string
	// DisplayNameConfirmed is false while DisplayName is only the suggestion
	// made when the User was created.
	DisplayNameConfirmed bool
}

// ErrUnauthenticated is returned by Authenticate for a token the identity
// provider did not issue, or that has expired.
var ErrUnauthenticated = errors.New("identity: invalid token")

// RateLimitedError is returned by Authenticate when the User is over the
// per-User rate limit. Wait is how long until they may try again.
type RateLimitedError struct {
	Wait time.Duration
}

func (e *RateLimitedError) Error() string {
	return fmt.Sprintf("identity: rate limited; retry in %s", e.Wait)
}

// Service authenticates, resolves and updates Users.
type Service struct {
	db       *pgxpool.Pool
	clock    clock.Clock
	verifier auth.TokenVerifier
	perUser  *ratelimit.Limiter
}

// NewService returns a Service backed by db that verifies tokens with verifier
// and limits each User's requests with perUser.
func NewService(db *pgxpool.Pool, c clock.Clock, verifier auth.TokenVerifier, perUser *ratelimit.Limiter) *Service {
	return &Service{db: db, clock: c, verifier: verifier, perUser: perUser}
}

// Authenticate returns the User a provider ID token belongs to, creating the
// User on first sight. It returns ErrUnauthenticated for a token that is not
// valid and a *RateLimitedError for a User over the limit; the limit is checked
// before any database work, so a flood never reaches the database.
func (s *Service) Authenticate(ctx context.Context, token string) (User, error) {
	id, err := s.verifier.Verify(ctx, token)
	if errors.Is(err, auth.ErrInvalidToken) {
		return User{}, ErrUnauthenticated
	}
	if err != nil {
		return User{}, fmt.Errorf("identity: verify token: %w", err)
	}
	if ok, wait := s.perUser.Allow(id.Subject); !ok {
		return User{}, &RateLimitedError{Wait: wait}
	}
	return s.resolve(ctx, id)
}

const userColumns = "id, email, display_name, display_name_confirmed"

func scanUser(row pgx.Row) (User, error) {
	var u User
	err := row.Scan(&u.ID, &u.Email, &u.DisplayName, &u.DisplayNameConfirmed)
	return u, err
}

// resolve returns the User for a verified identity, creating it on first sight.
// A changed email at the provider is copied onto the User.
func (s *Service) resolve(ctx context.Context, id auth.Identity) (User, error) {
	u, err := scanUser(s.db.QueryRow(ctx,
		"SELECT "+userColumns+" FROM users WHERE auth_subject = $1", id.Subject))
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return s.create(ctx, id)
	case err != nil:
		return User{}, fmt.Errorf("identity: find user: %w", err)
	case u.Email != id.Email:
		return scanUserOrWrap(s.db.QueryRow(ctx,
			"UPDATE users SET email = $2, updated_at = $3 WHERE auth_subject = $1 RETURNING "+userColumns,
			id.Subject, id.Email, s.clock.Now()), "update email")
	default:
		return u, nil
	}
}

func (s *Service) create(ctx context.Context, id auth.Identity) (User, error) {
	now := s.clock.Now()
	// ON CONFLICT covers two first requests racing: the loser updates nothing
	// and reads back the winner's row.
	return scanUserOrWrap(s.db.QueryRow(ctx, `
		INSERT INTO users (auth_subject, email, display_name, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $4)
		ON CONFLICT (auth_subject) DO UPDATE SET auth_subject = EXCLUDED.auth_subject
		RETURNING `+userColumns,
		id.Subject, id.Email, suggestDisplayName(id), now), "create user")
}

// SetDisplayName sets and confirms the User's display name. It returns
// ErrInvalidDisplayName if name is not acceptable.
func (s *Service) SetDisplayName(ctx context.Context, userID uuid.UUID, name string) (User, error) {
	name, ok := normalizeDisplayName(name)
	if !ok {
		return User{}, ErrInvalidDisplayName
	}
	return scanUserOrWrap(s.db.QueryRow(ctx, `
		UPDATE users SET display_name = $2, display_name_confirmed = true, updated_at = $3
		WHERE id = $1 RETURNING `+userColumns,
		userID, name, s.clock.Now()), "set display name")
}

// DisplayNamesIn returns the display name of each of userIDs that exists,
// read inside the caller's transaction tx.
func (s *Service) DisplayNamesIn(ctx context.Context, tx pgx.Tx, userIDs []uuid.UUID) (map[uuid.UUID]string, error) {
	rows, err := tx.Query(ctx, "SELECT id, display_name FROM users WHERE id = ANY($1)", userIDs)
	if err != nil {
		return nil, fmt.Errorf("identity: display names: %w", err)
	}
	out := make(map[uuid.UUID]string, len(userIDs))
	var id uuid.UUID
	var name string
	if _, err := pgx.ForEachRow(rows, []any{&id, &name}, func() error {
		out[id] = name
		return nil
	}); err != nil {
		return nil, fmt.Errorf("identity: display names: %w", err)
	}
	return out, nil
}

func scanUserOrWrap(row pgx.Row, what string) (User, error) {
	u, err := scanUser(row)
	if err != nil {
		return User{}, fmt.Errorf("identity: %s: %w", what, err)
	}
	return u, nil
}

// normalizeDisplayName trims name and reports whether it is acceptable.
func normalizeDisplayName(name string) (string, bool) {
	return names.Normalize(name, MaxDisplayNameLength)
}

// suggestDisplayName picks a starting display name: the provider's name if it
// is acceptable, else the part of the email address before the @, cut to fit.
// The User confirms or changes it in the app.
func suggestDisplayName(id auth.Identity) string {
	if name, ok := normalizeDisplayName(id.Name); ok {
		return name
	}
	local, _, _ := strings.Cut(id.Email, "@")
	local = strings.Map(func(r rune) rune {
		if unicode.IsControl(r) {
			return -1
		}
		return r
	}, strings.TrimSpace(local))
	if runes := []rune(local); len(runes) > MaxDisplayNameLength {
		local = string(runes[:MaxDisplayNameLength])
	}
	return local
}

type userKey struct{}

// WithUser returns ctx carrying the signed-in User.
func WithUser(ctx context.Context, u User) context.Context {
	return context.WithValue(ctx, userKey{}, u)
}

// FromContext returns the signed-in User carried by ctx, if any.
func FromContext(ctx context.Context) (User, bool) {
	u, ok := ctx.Value(userKey{}).(User)
	return u, ok
}
