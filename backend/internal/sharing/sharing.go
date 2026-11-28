// Package sharing owns Invitations: an Owner invites an email address to a
// List, and whoever holds the Invitation's token (or is signed in with the
// invited address) accepts it, becoming an Editor, or declines it.
//
// Only the SHA-256 hash of an Invitation's token is stored; the token itself
// exists only in the email package notify sends. An Invitation expires
// ExpiresAfter it is created, by the Clock.
//
// Who owns a List, and whether it is deleted, is asked of package lists;
// joining it goes through package membership, which enforces the Member limit.
package sharing

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"net/mail"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/lists"
	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/notify"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
)

// ExpiresAfter is how long an Invitation can be accepted after it is created.
const ExpiresAfter = 14 * 24 * time.Hour

// MaxPerDay is how many Invitations a User can send in any 24 hours.
const MaxPerDay = 20

// MaxEmailLength is the longest email address that can be invited.
const MaxEmailLength = 254

var (
	// ErrInvalidEmail is returned for an address that is not a plain email address.
	ErrInvalidEmail error = sharingError("invalid email address")
	// ErrNotFound is returned for a token no Invitation has, or an Invitation
	// id that is not addressed to the User (or not on the List, for the Owner).
	ErrNotFound error = sharingError("invitation not found")
	// ErrCancelled is returned for an Invitation the Owner cancelled.
	ErrCancelled error = sharingError("invitation cancelled")
	// ErrDeclined is returned for an Invitation that was declined.
	ErrDeclined error = sharingError("invitation declined")
	// ErrExpired is returned for an Invitation more than ExpiresAfter old.
	ErrExpired error = sharingError("invitation expired")
	// ErrAccepted is returned for an Invitation someone else already accepted.
	ErrAccepted error = sharingError("invitation already accepted")
	// ErrLimitReached is returned when the User already sent MaxPerDay
	// Invitations in the last 24 hours.
	ErrLimitReached error = sharingError("invitation limit reached")
)

// Status is where an Invitation stands.
type Status string

// The Statuses of an Invitation. Expired is never stored: a pending
// Invitation past its expiry is expired.
const (
	Pending   Status = "pending"
	Accepted  Status = "accepted"
	Declined  Status = "declined"
	Cancelled Status = "cancelled"
	Expired   Status = "expired"
)

// Invitation is an offer to an email address to become an Editor of a List.
type Invitation struct {
	ID          uuid.UUID
	ListID      uuid.UUID
	ListName    string
	Email       string
	InvitedBy   uuid.UUID
	InviterName string
	Status      Status
	CreatedAt   time.Time
	ExpiresAt   time.Time
}

// Ref identifies an Invitation by its token or, for one addressed to the
// User's email, by its ID. Exactly one of them is set.
type Ref struct {
	Token string
	ID    uuid.UUID
}

// Invitee is the signed-in User acting on an Invitation.
type Invitee struct {
	ID    uuid.UUID
	Email string
}

// Service manages Invitations.
type Service struct {
	db       *pgxpool.Pool
	clock    clock.Clock
	lists    *lists.Service
	members  *membership.Service
	users    *identity.Service
	notifier *notify.Notifier
}

// NewService returns a Service backed by db that emails Invitations through notifier.
func NewService(db *pgxpool.Pool, c clock.Clock, ls *lists.Service, members *membership.Service,
	users *identity.Service, notifier *notify.Notifier,
) *Service {
	return &Service{db: db, clock: c, lists: ls, members: members, users: users, notifier: notifier}
}

// Create invites address to listID, which inviter must own, and emails it the
// Invitation's deep link in lang. It returns ErrInvalidEmail, ErrLimitReached,
// or lists.ErrNotFound, lists.ErrNotOwner or lists.ErrDeleted.
func (s *Service) Create(ctx context.Context, inviter, listID uuid.UUID, address string, lang notify.Language) (Invitation, error) {
	address, ok := normalizeEmail(address)
	if !ok {
		return Invitation{}, ErrInvalidEmail
	}
	token, hash, err := newToken()
	if err != nil {
		return Invitation{}, wrap("create", err)
	}
	now := s.clock.Now()
	inv := Invitation{
		ListID: listID, Email: address, InvitedBy: inviter, Status: Pending,
		CreatedAt: now, ExpiresAt: now.Add(ExpiresAfter),
	}
	err = pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		if inv.ListName, err = s.lists.LockOwnedLive(ctx, tx, inviter, listID); err != nil {
			return err
		}
		// Serialize the inviter's Invitations so two at the limit can't both pass.
		if _, err := tx.Exec(ctx,
			"SELECT pg_advisory_xact_lock(hashtextextended('invitations:inviter:' || $1, 0))", inviter.String()); err != nil {
			return err
		}
		var sent int
		if err := tx.QueryRow(ctx,
			"SELECT count(*) FROM invitations WHERE invited_by = $1 AND created_at > $2",
			inviter, now.Add(-24*time.Hour)).Scan(&sent); err != nil {
			return err
		}
		if sent >= MaxPerDay {
			return ErrLimitReached
		}
		if err := tx.QueryRow(ctx, `
			INSERT INTO invitations (list_id, email, token_hash, invited_by, created_at, expires_at)
			VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
			listID, address, hash, inviter, inv.CreatedAt, inv.ExpiresAt).Scan(&inv.ID); err != nil {
			return err
		}
		names, err := s.users.DisplayNamesIn(ctx, tx, []uuid.UUID{inviter})
		if err != nil {
			return err
		}
		inv.InviterName = names[inviter]
		// Sent before commit: if the email can't go out, no Invitation is left
		// behind that nobody received.
		return s.notifier.Invited(ctx, notify.Invitation{
			To: address, InviterName: inv.InviterName, ListName: inv.ListName,
			Token: token, ExpiresAt: inv.ExpiresAt, Language: lang,
		})
	})
	if err != nil {
		return Invitation{}, wrap("create", err)
	}
	return inv, nil
}

// ForList returns the pending Invitations to listID, which owner must own,
// newest first. It returns lists.ErrNotFound, lists.ErrNotOwner or lists.ErrDeleted.
func (s *Service) ForList(ctx context.Context, owner, listID uuid.UUID) ([]Invitation, error) {
	var out []Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		if _, err := s.lists.LockOwnedLive(ctx, tx, owner, listID); err != nil {
			return err
		}
		var err error
		out, err = s.query(ctx, tx, "list_id = $1 AND status = 'pending' AND expires_at > $2", listID, s.clock.Now())
		return err
	})
	if err != nil {
		return nil, wrap("for list", err)
	}
	return out, nil
}

// ForUser returns the pending Invitations addressed to who's email, on Lists
// that are not deleted, newest first.
func (s *Service) ForUser(ctx context.Context, who Invitee) ([]Invitation, error) {
	var out []Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		var err error
		out, err = s.query(ctx, tx, "email = lower($1) AND status = 'pending' AND expires_at > $2",
			strings.TrimSpace(who.Email), s.clock.Now())
		return err
	})
	if err != nil {
		return nil, wrap("for user", err)
	}
	return out, nil
}

// Lookup returns the Invitation ref identifies for who, whatever its status.
// It returns ErrNotFound if there is none, or its List is deleted.
func (s *Service) Lookup(ctx context.Context, who Invitee, ref Ref) (Invitation, error) {
	var inv Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		var err error
		inv, err = s.find(ctx, tx, who, ref, false)
		return err
	})
	if err != nil {
		return Invitation{}, wrap("lookup", err)
	}
	return inv, nil
}

// Accept makes who an Editor of the List the Invitation ref identifies, and
// returns the List's ID. A retry by the User who accepted it changes nothing.
// It returns ErrNotFound, ErrCancelled, ErrDeclined, ErrExpired, ErrAccepted,
// lists.ErrDeleted or membership.ErrListFull.
func (s *Service) Accept(ctx context.Context, who Invitee, ref Ref) (uuid.UUID, error) {
	var listID uuid.UUID
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		inv, err := s.find(ctx, tx, who, ref, true)
		if err != nil {
			return err
		}
		listID = inv.ListID
		// The List before the Invitation, the same order as Cancel, and so
		// joins to the List are serialized for the Member limit.
		if _, err := s.lists.LockLive(ctx, tx, listID); err != nil {
			if errors.Is(err, lists.ErrNotFound) {
				return ErrNotFound
			}
			return err
		}
		var respondedBy *uuid.UUID
		if inv, respondedBy, err = s.lock(ctx, tx, inv.ID); err != nil {
			return err
		}
		switch inv.Status {
		case Accepted:
			if respondedBy != nil && *respondedBy == who.ID {
				return nil // a retry
			}
			return ErrAccepted
		case Pending:
		default:
			return statusError(inv.Status)
		}
		now := s.clock.Now()
		if _, err := s.members.Join(ctx, tx, listID, who.ID, now, membership.DefaultMaxPerList); err != nil {
			return err
		}
		return s.respond(ctx, tx, inv.ID, Accepted, who.ID, now)
	})
	if err != nil {
		return uuid.Nil, wrap("accept", err)
	}
	return listID, nil
}

// Decline declines the Invitation ref identifies, so its link stops working.
// Declining twice changes nothing. It returns ErrNotFound, ErrCancelled,
// ErrExpired or ErrAccepted.
func (s *Service) Decline(ctx context.Context, who Invitee, ref Ref) (Invitation, error) {
	var inv Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		found, err := s.find(ctx, tx, who, ref, true)
		if err != nil {
			return err
		}
		if inv, _, err = s.lock(ctx, tx, found.ID); err != nil {
			return err
		}
		switch inv.Status {
		case Declined:
			return nil
		case Pending:
		default:
			return statusError(inv.Status)
		}
		inv.Status = Declined
		return s.respond(ctx, tx, inv.ID, Declined, who.ID, s.clock.Now())
	})
	if err != nil {
		return Invitation{}, wrap("decline", err)
	}
	return inv, nil
}

// Cancel cancels the Invitation invitationID to listID, which owner must own,
// so its link stops working. Cancelling twice, or an expired Invitation,
// returns it cancelled. It returns ErrNotFound, ErrAccepted, ErrDeclined, or
// lists.ErrNotFound, lists.ErrNotOwner or lists.ErrDeleted.
func (s *Service) Cancel(ctx context.Context, owner, listID, invitationID uuid.UUID) (Invitation, error) {
	var inv Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		if _, err := s.lists.LockOwnedLive(ctx, tx, owner, listID); err != nil {
			return err
		}
		var err error
		if inv, _, err = s.lock(ctx, tx, invitationID); err != nil {
			return err
		}
		switch {
		case inv.ListID != listID:
			return ErrNotFound
		case inv.Status == Accepted || inv.Status == Declined:
			return statusError(inv.Status)
		case inv.Status == Cancelled:
			return nil
		}
		inv.Status = Cancelled
		_, err = tx.Exec(ctx, "UPDATE invitations SET status = 'cancelled' WHERE id = $1", inv.ID)
		return err
	})
	if err != nil {
		return Invitation{}, wrap("cancel", err)
	}
	return inv, nil
}

const invitationColumns = "id, list_id, email, invited_by, status, created_at, expires_at, responded_by"

type row struct {
	inv         Invitation
	respondedBy *uuid.UUID
}

func scanRow(r pgx.CollectableRow) (row, error) {
	var x row
	var status string
	err := r.Scan(&x.inv.ID, &x.inv.ListID, &x.inv.Email, &x.inv.InvitedBy, &status,
		&x.inv.CreatedAt, &x.inv.ExpiresAt, &x.respondedBy)
	x.inv.Status = Status(status)
	x.inv.CreatedAt, x.inv.ExpiresAt = x.inv.CreatedAt.UTC(), x.inv.ExpiresAt.UTC()
	return x, err
}

// query returns the Invitations matching where, newest first, with their List
// and inviter names; those whose List is deleted are left out.
func (s *Service) query(ctx context.Context, tx pgx.Tx, where string, args ...any) ([]Invitation, error) {
	rows, err := tx.Query(ctx,
		"SELECT "+invitationColumns+" FROM invitations WHERE "+where+" ORDER BY created_at DESC, id DESC", args...)
	if err != nil {
		return nil, err
	}
	found, err := pgx.CollectRows(rows, scanRow)
	if err != nil {
		return nil, err
	}
	invs := make([]Invitation, 0, len(found))
	for _, r := range found {
		invs = append(invs, r.inv)
	}
	return s.complete(ctx, tx, invs)
}

// complete fills in List and inviter names and the expired Status, dropping
// Invitations whose List is deleted.
func (s *Service) complete(ctx context.Context, tx pgx.Tx, invs []Invitation) ([]Invitation, error) {
	listIDs := make([]uuid.UUID, 0, len(invs))
	userIDs := make([]uuid.UUID, 0, len(invs))
	for _, inv := range invs {
		listIDs = append(listIDs, inv.ListID)
		userIDs = append(userIDs, inv.InvitedBy)
	}
	listNames, err := s.lists.LiveNamesIn(ctx, tx, listIDs)
	if err != nil {
		return nil, err
	}
	userNames, err := s.users.DisplayNamesIn(ctx, tx, userIDs)
	if err != nil {
		return nil, err
	}
	out := make([]Invitation, 0, len(invs))
	now := s.clock.Now()
	for _, inv := range invs {
		name, live := listNames[inv.ListID]
		if !live {
			continue
		}
		inv.ListName, inv.InviterName = name, userNames[inv.InvitedBy]
		if inv.Status == Pending && !now.Before(inv.ExpiresAt) {
			inv.Status = Expired
		}
		out = append(out, inv)
	}
	return out, nil
}

// find returns the Invitation ref identifies for who: the one with ref.Token,
// or the one with ref.ID addressed to who's email. With anyList it is found
// even if its List is deleted (its List name is then empty).
func (s *Service) find(ctx context.Context, tx pgx.Tx, who Invitee, ref Ref, anyList bool) (Invitation, error) {
	var rows pgx.Rows
	var err error
	switch {
	case ref.Token != "" && ref.ID == uuid.Nil:
		rows, err = tx.Query(ctx, "SELECT "+invitationColumns+" FROM invitations WHERE token_hash = $1",
			hashToken(ref.Token))
	case ref.Token == "" && ref.ID != uuid.Nil:
		rows, err = tx.Query(ctx, "SELECT "+invitationColumns+" FROM invitations WHERE id = $1 AND email = lower($2)",
			ref.ID, strings.TrimSpace(who.Email))
	default:
		return Invitation{}, ErrNotFound
	}
	if err != nil {
		return Invitation{}, err
	}
	r, err := pgx.CollectExactlyOneRow(rows, scanRow)
	if errors.Is(err, pgx.ErrNoRows) {
		return Invitation{}, ErrNotFound
	}
	if err != nil {
		return Invitation{}, err
	}
	invs, err := s.complete(ctx, tx, []Invitation{r.inv})
	switch {
	case err != nil:
		return Invitation{}, err
	case len(invs) == 1:
		return invs[0], nil
	case anyList:
		return r.inv, nil
	default:
		return Invitation{}, ErrNotFound
	}
}

// lock locks invitationID until tx ends and returns it, with who responded to it.
func (s *Service) lock(ctx context.Context, tx pgx.Tx, invitationID uuid.UUID) (Invitation, *uuid.UUID, error) {
	rows, err := tx.Query(ctx, "SELECT "+invitationColumns+" FROM invitations WHERE id = $1 FOR UPDATE", invitationID)
	if err != nil {
		return Invitation{}, nil, err
	}
	r, err := pgx.CollectExactlyOneRow(rows, scanRow)
	if errors.Is(err, pgx.ErrNoRows) {
		return Invitation{}, nil, ErrNotFound
	}
	if err != nil {
		return Invitation{}, nil, err
	}
	invs, err := s.complete(ctx, tx, []Invitation{r.inv})
	if err != nil {
		return Invitation{}, nil, err
	}
	inv := r.inv
	if len(invs) == 1 {
		inv = invs[0]
	} else if inv.Status == Pending && !s.clock.Now().Before(inv.ExpiresAt) {
		inv.Status = Expired
	}
	return inv, r.respondedBy, nil
}

func (s *Service) respond(ctx context.Context, tx pgx.Tx, id uuid.UUID, status Status, by uuid.UUID, at time.Time) error {
	_, err := tx.Exec(ctx,
		"UPDATE invitations SET status = $2, responded_by = $3, responded_at = $4 WHERE id = $1",
		id, string(status), by, at)
	return err
}

// statusError is the error for acting on an Invitation that is no longer pending.
func statusError(st Status) error {
	switch st {
	case Accepted:
		return ErrAccepted
	case Declined:
		return ErrDeclined
	case Cancelled:
		return ErrCancelled
	case Expired:
		return ErrExpired
	default:
		return fmt.Errorf("sharing: unexpected status %q", st)
	}
}

// newToken returns a random single-use token (256 bits, URL-safe) and its hash.
func newToken() (string, []byte, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", nil, err
	}
	token := base64.RawURLEncoding.EncodeToString(b)
	return token, hashToken(token), nil
}

func hashToken(token string) []byte {
	h := sha256.Sum256([]byte(token))
	return h[:]
}

// normalizeEmail trims and lowercases address and reports whether it is a
// plain email address (no display name), at most MaxEmailLength long.
func normalizeEmail(address string) (string, bool) {
	address = strings.ToLower(strings.TrimSpace(address))
	if address == "" || len(address) > MaxEmailLength {
		return "", false
	}
	parsed, err := mail.ParseAddress(address)
	if err != nil || parsed.Address != address || !strings.Contains(address[strings.LastIndex(address, "@"):], ".") {
		return "", false
	}
	return address, true
}

// sharingError is the type of this package's sentinel errors, so wrap passes
// them through.
type sharingError string

func (e sharingError) Error() string { return string(e) }

// wrap adds context to unexpected errors and passes sentinel errors (this
// package's, and those of lists and membership callers handle) through.
func wrap(what string, err error) error {
	if err == nil {
		return nil
	}
	if _, ok := errors.AsType[sharingError](err); ok {
		return err
	}
	for _, known := range []error{lists.ErrNotFound, lists.ErrNotOwner, lists.ErrDeleted, membership.ErrListFull} {
		if errors.Is(err, known) {
			return err
		}
	}
	return fmt.Errorf("sharing: %s: %w", what, err)
}
