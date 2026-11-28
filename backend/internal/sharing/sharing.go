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
	// ErrAlreadyMember is returned for inviting an address that belongs to a
	// Member of the List, the Owner included.
	ErrAlreadyMember error = sharingError("already a member of the list")
	// ErrNotSent is returned when the Invitation's email couldn't be sent; no
	// Invitation was made.
	ErrNotSent error = sharingError("invitation email not sent")
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
	Email       Email
	InvitedBy   uuid.UUID
	InviterName string
	Status      Status
	CreatedAt   time.Time
	ExpiresAt   time.Time
	// listLive is false when the List is deleted (ListName is then empty).
	listLive bool
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
	Email Email
}

// Email is an email address in the one form it is stored and compared in:
// trimmed and lowercased.
type Email string

// CanonicalEmail returns address in canonical form, without checking that it
// is an email address: for one the identity provider vouched for.
func CanonicalEmail(address string) Email {
	return Email(strings.ToLower(strings.TrimSpace(address)))
}

// ParseEmail returns address in canonical form, or ErrInvalidEmail unless it
// is a plain email address (no display name) at most MaxEmailLength long.
func ParseEmail(address string) (Email, error) {
	e := CanonicalEmail(address)
	plain := string(e)
	if plain == "" || len(plain) > MaxEmailLength {
		return "", ErrInvalidEmail
	}
	parsed, err := mail.ParseAddress(plain)
	if err != nil || parsed.Address != plain || !strings.Contains(plain[strings.LastIndex(plain, "@"):], ".") {
		return "", ErrInvalidEmail
	}
	return e, nil
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
// Invitation's deep link in lang. It returns ErrInvalidEmail, ErrAlreadyMember,
// ErrLimitReached, ErrNotSent, or lists.ErrNotFound, lists.ErrNotOwner or
// lists.ErrDeleted.
func (s *Service) Create(ctx context.Context, inviter, listID uuid.UUID, address string, lang notify.Language) (Invitation, error) {
	to, err := ParseEmail(address)
	if err != nil {
		return Invitation{}, err
	}
	token, hash, err := newToken()
	if err != nil {
		return Invitation{}, wrap("create", err)
	}
	now := s.clock.Now()
	inv := Invitation{
		ListID: listID, Email: to, InvitedBy: inviter, Status: Pending,
		CreatedAt: now, ExpiresAt: now.Add(ExpiresAfter), listLive: true,
	}
	err = pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		if inv.ListName, err = s.lists.LockOwnedLive(ctx, tx, inviter, listID); err != nil {
			return err
		}
		// Under the List's lock, so nobody joins between this check and the insert.
		if err := s.requireNotMember(ctx, tx, listID, to); err != nil {
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
			listID, string(to), hash, inviter, inv.CreatedAt, inv.ExpiresAt).Scan(&inv.ID); err != nil {
			return err
		}
		names, err := s.users.DisplayNamesIn(ctx, tx, []uuid.UUID{inviter})
		if err != nil {
			return err
		}
		inv.InviterName = names[inviter]
		return nil
	})
	if err != nil {
		return Invitation{}, wrap("create", err)
	}
	// Sent after commit, so no lock is held through the call to the email
	// provider. If the email can't go out, the Invitation is removed: none is
	// left behind that nobody received. Nobody else has its token meanwhile.
	if err := s.notifier.Invited(ctx, notify.Invitation{
		To: string(to), InviterName: inv.InviterName, ListName: inv.ListName,
		Token: token, ExpiresAt: inv.ExpiresAt, Language: lang,
	}); err != nil {
		err = fmt.Errorf("%w: %w", ErrNotSent, err)
		if _, delErr := s.db.Exec(context.WithoutCancel(ctx), "DELETE FROM invitations WHERE id = $1", inv.ID); delErr != nil {
			err = errors.Join(err, fmt.Errorf("remove unsent invitation: %w", delErr))
		}
		return Invitation{}, err
	}
	return inv, nil
}

// requireNotMember returns ErrAlreadyMember if a User with address is a Member
// of listID.
func (s *Service) requireNotMember(ctx context.Context, tx pgx.Tx, listID uuid.UUID, address Email) error {
	userIDs, err := s.users.WithEmailIn(ctx, tx, string(address))
	if err != nil {
		return err
	}
	for _, id := range userIDs {
		_, err := s.members.RoleIn(ctx, tx, listID, id)
		switch {
		case err == nil:
			return ErrAlreadyMember
		case !errors.Is(err, membership.ErrNotAMember):
			return err
		}
	}
	return nil
}

// ForList returns the open Invitations to listID, which owner must own: those
// pending, and those expired, so the Owner sees who never joined, until the
// address is invited again. Newest first. It
// returns lists.ErrNotFound, lists.ErrNotOwner or lists.ErrDeleted.
func (s *Service) ForList(ctx context.Context, owner, listID uuid.UUID) ([]Invitation, error) {
	var out []Invitation
	err := pgx.BeginFunc(ctx, s.db, func(tx pgx.Tx) error {
		if _, err := s.lists.OwnedLive(ctx, tx, owner, listID); err != nil {
			return err
		}
		var err error
		// An expired one drops out once its address is invited to the List again.
		out, err = s.listWhere(ctx, tx, `list_id = $1 AND status = 'pending' AND (expires_at > $2 OR NOT EXISTS (
			SELECT 1 FROM invitations newer
			WHERE newer.list_id = invitations.list_id AND newer.email = invitations.email
				AND newer.created_at > invitations.created_at))`, listID, s.clock.Now())
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
		out, err = s.listWhere(ctx, tx, "email = $1 AND status = 'pending' AND expires_at > $2",
			string(who.Email), s.clock.Now())
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
		found, err := s.find(ctx, tx, who, ref)
		if err == nil && !found.listLive {
			return ErrNotFound
		}
		inv = found
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
		inv, err := s.find(ctx, tx, who, ref)
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
		if _, err := s.members.Join(ctx, tx, listID, who.ID, now); err != nil {
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
		found, err := s.find(ctx, tx, who, ref)
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

// stored is an Invitation as stored, with who responded to it.
type stored struct {
	inv         Invitation
	respondedBy *uuid.UUID
}

func scanStored(r pgx.CollectableRow) (stored, error) {
	var st stored
	var email, status string
	err := r.Scan(&st.inv.ID, &st.inv.ListID, &email, &st.inv.InvitedBy, &status,
		&st.inv.CreatedAt, &st.inv.ExpiresAt, &st.respondedBy)
	st.inv.Email, st.inv.Status = Email(email), Status(status)
	st.inv.CreatedAt, st.inv.ExpiresAt = st.inv.CreatedAt.UTC(), st.inv.ExpiresAt.UTC()
	return st, err
}

// listWhere returns the Invitations matching where, newest first, with their
// List and inviter names; those whose List is deleted are left out.
func (s *Service) listWhere(ctx context.Context, tx pgx.Tx, where string, args ...any) ([]Invitation, error) {
	rows, err := tx.Query(ctx,
		"SELECT "+invitationColumns+" FROM invitations WHERE "+where+" ORDER BY created_at DESC, id DESC", args...)
	if err != nil {
		return nil, err
	}
	found, err := pgx.CollectRows(rows, scanStored)
	if err != nil {
		return nil, err
	}
	invs := make([]Invitation, 0, len(found))
	for _, st := range found {
		invs = append(invs, st.inv)
	}
	named, err := s.withNames(ctx, tx, invs)
	if err != nil {
		return nil, err
	}
	live := named[:0]
	for _, inv := range named {
		if inv.listLive {
			live = append(live, inv)
		}
	}
	return live, nil
}

// withNames returns invs with their List and inviter names, whether their
// List is live, and the expired Status filled in.
func (s *Service) withNames(ctx context.Context, tx pgx.Tx, invs []Invitation) ([]Invitation, error) {
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
		inv.ListName, inv.listLive = listNames[inv.ListID]
		inv.InviterName = userNames[inv.InvitedBy]
		inv.Status = inv.statusAt(now)
		out = append(out, inv)
	}
	return out, nil
}

// statusAt is inv's Status at now: a pending Invitation is expired from its
// ExpiresAt on.
func (inv Invitation) statusAt(now time.Time) Status {
	if inv.Status == Pending && !now.Before(inv.ExpiresAt) {
		return Expired
	}
	return inv.Status
}

// find returns the Invitation ref identifies for who, even if its List is
// deleted: the one with ref.Token, or the one with ref.ID addressed to who's
// email. It returns ErrNotFound if there is none.
func (s *Service) find(ctx context.Context, tx pgx.Tx, who Invitee, ref Ref) (Invitation, error) {
	const query = "SELECT " + invitationColumns + " FROM invitations WHERE "
	var st stored
	var err error
	switch {
	case ref.Token != "" && ref.ID == uuid.Nil:
		st, err = s.queryOne(ctx, tx, query+"token_hash = $1", hashToken(ref.Token))
	case ref.Token == "" && ref.ID != uuid.Nil:
		st, err = s.queryOne(ctx, tx, query+"id = $1 AND email = $2", ref.ID, string(who.Email))
	default:
		return Invitation{}, ErrNotFound
	}
	return st.inv, err
}

// lock locks invitationID until tx ends and returns it, even if its List is
// deleted, with who responded to it. It returns ErrNotFound if there is none.
func (s *Service) lock(ctx context.Context, tx pgx.Tx, invitationID uuid.UUID) (Invitation, *uuid.UUID, error) {
	st, err := s.queryOne(ctx, tx,
		"SELECT "+invitationColumns+" FROM invitations WHERE id = $1 FOR UPDATE", invitationID)
	return st.inv, st.respondedBy, err
}

// queryOne returns the one Invitation query selects, with its names, or
// ErrNotFound if there is none.
func (s *Service) queryOne(ctx context.Context, tx pgx.Tx, query string, args ...any) (stored, error) {
	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return stored{}, err
	}
	st, err := pgx.CollectExactlyOneRow(rows, scanStored)
	if errors.Is(err, pgx.ErrNoRows) {
		return stored{}, ErrNotFound
	}
	if err != nil {
		return stored{}, err
	}
	named, err := s.withNames(ctx, tx, []Invitation{st.inv})
	if err != nil {
		return stored{}, err
	}
	st.inv = named[0]
	return st, nil
}

func (s *Service) respond(ctx context.Context, tx pgx.Tx, id uuid.UUID, status Status, by uuid.UUID, at time.Time) error {
	_, err := tx.Exec(ctx,
		"UPDATE invitations SET status = $2, responded_by = $3, responded_at = $4 WHERE id = $1",
		id, string(status), by, at)
	return err
}

// closedErrors is the error for acting on an Invitation in each Status that
// is no longer pending.
var closedErrors = map[Status]error{
	Accepted:  ErrAccepted,
	Declined:  ErrDeclined,
	Cancelled: ErrCancelled,
	Expired:   ErrExpired,
}

// statusError is the error for acting on an Invitation that is no longer pending.
func statusError(st Status) error {
	if err, ok := closedErrors[st]; ok {
		return err
	}
	return fmt.Errorf("sharing: unexpected status %q", st)
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
