package sync

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/tsantanadev/cesta/backend/internal/membership"
	"github.com/tsantanadev/cesta/backend/internal/platform/changeseq"
	"github.com/tsantanadev/cesta/backend/internal/platform/names"
)

// MaxNameLength is the longest Item name, in characters.
const MaxNameLength = 80

// MaxNoteLength is the longest Item note, in characters.
const MaxNoteLength = 200

// Units are the units an Item's quantity can have. The set is fixed.
var Units = []string{"un", "kg", "g", "L", "ml", "pack"}

// quantityPattern is a positive decimal with up to 6 integer and 3 fractional digits.
var quantityPattern = regexp.MustCompile(`^[0-9]{1,6}(\.[0-9]{1,3})?$`)

// apply makes m's change inside tx, or returns why it can't.
func (s *Service) apply(ctx context.Context, tx pgx.Tx, userID uuid.UUID, m Mutation, now time.Time) (Result, error) {
	switch m.Type {
	case ItemCreate:
		return s.create(ctx, tx, userID, m, now)
	case ItemUpdate, ItemDelete:
		return s.change(ctx, tx, userID, m, now)
	default:
		return rejected(ReasonInvalidRequest, fmt.Sprintf("unknown mutation type %q", m.Type)), nil
	}
}

func (s *Service) create(ctx context.Context, tx pgx.Tx, userID uuid.UUID, m Mutation, now time.Time) (Result, error) {
	if m.ListID == uuid.Nil {
		return rejected(ReasonInvalidRequest, "listId is required to create an Item"), nil
	}
	if m.Fields.Name == nil {
		return rejected(ReasonInvalidItem, "an Item needs a name"), nil
	}
	f, bad := validate(m.Fields)
	if bad != nil {
		return *bad, nil
	}
	if r, ok, err := s.lockList(ctx, tx, userID, m.ListID, ReasonListNotFound); err != nil || !ok {
		return r, err
	}
	var listID uuid.UUID
	var deletedAt *time.Time
	err := tx.QueryRow(ctx, "SELECT list_id, deleted_at FROM items WHERE id = $1 FOR UPDATE", m.EntityID).
		Scan(&listID, &deletedAt)
	switch {
	case err == nil && listID != m.ListID:
		return rejected(ReasonInvalidItem, "another Item has this id"), nil
	case err == nil && deletedAt != nil:
		return rejected(ReasonItemDeleted, "the Item was removed"), nil
	case err == nil:
		// Created already under another mutation ID: set the fields like an update.
		return s.update(ctx, tx, userID, m.EntityID, f, now)
	case !errors.Is(err, pgx.ErrNoRows):
		return Result{}, err
	}
	var live int
	if err := tx.QueryRow(ctx,
		"SELECT count(*) FROM items WHERE list_id = $1 AND deleted_at IS NULL", m.ListID).Scan(&live); err != nil {
		return Result{}, err
	}
	if live >= s.maxItems {
		r := rejected(ReasonLimitExceeded, fmt.Sprintf("the List already holds the limit of %d Items", s.maxItems))
		r.Limit = s.maxItems
		return r, nil
	}
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return Result{}, err
	}
	var checkedBy *uuid.UUID
	var checkedAt *time.Time
	if f.Checked != nil && *f.Checked {
		checkedBy, checkedAt = &userID, &now
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO items (id, list_id, name, quantity, unit, note, added_by, added_at, checked_by, checked_at, updated_at, seq)
		VALUES ($1, $2, $3, $4::numeric, $5, $6, $7, $8, $9, $10, $8, $11)`,
		m.EntityID, m.ListID, *f.Name, f.Quantity.Value, f.Unit.Value, f.Note.Value, userID, now, checkedBy, checkedAt, seq)
	if err != nil {
		return Result{}, err
	}
	return applied(), nil
}

// change applies an ItemUpdate or ItemDelete to an existing Item.
func (s *Service) change(ctx context.Context, tx pgx.Tx, userID uuid.UUID, m Mutation, now time.Time) (Result, error) {
	var listID uuid.UUID
	err := tx.QueryRow(ctx, "SELECT list_id FROM items WHERE id = $1", m.EntityID).Scan(&listID)
	if errors.Is(err, pgx.ErrNoRows) {
		return rejected(ReasonItemNotFound, "no such Item"), nil
	}
	if err != nil {
		return Result{}, err
	}
	if r, ok, err := s.lockList(ctx, tx, userID, listID, ReasonItemNotFound); err != nil || !ok {
		return r, err
	}
	var deletedAt *time.Time
	if err := tx.QueryRow(ctx, "SELECT deleted_at FROM items WHERE id = $1 FOR UPDATE", m.EntityID).
		Scan(&deletedAt); err != nil {
		return Result{}, err
	}
	if m.Type == ItemDelete {
		if deletedAt != nil {
			return applied(), nil // removing it again changes nothing
		}
		seq, err := changeseq.Next(ctx, tx)
		if err != nil {
			return Result{}, err
		}
		_, err = tx.Exec(ctx, "UPDATE items SET deleted_at = $2, updated_at = $2, seq = $3 WHERE id = $1",
			m.EntityID, now, seq)
		if err != nil {
			return Result{}, err
		}
		return applied(), nil
	}
	if deletedAt != nil {
		return rejected(ReasonItemDeleted, "the Item was removed"), nil
	}
	f, bad := validate(m.Fields)
	if bad != nil {
		return *bad, nil
	}
	return s.update(ctx, tx, userID, m.EntityID, f, now)
}

// update sets the fields f carries on a live Item, leaving the others as they are.
func (s *Service) update(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID, f Fields, now time.Time) (Result, error) {
	set := []string{}
	args := []any{id}
	add := func(col string, v any) {
		args = append(args, v)
		set = append(set, fmt.Sprintf("%s = $%d", col, len(args)))
	}
	if f.Name != nil {
		add("name", *f.Name)
	}
	if f.Quantity.Present {
		args = append(args, f.Quantity.Value)
		set = append(set, fmt.Sprintf("quantity = $%d::numeric", len(args)))
	}
	if f.Unit.Present {
		add("unit", f.Unit.Value)
	}
	if f.Note.Present {
		add("note", f.Note.Value)
	}
	if f.Checked != nil {
		if *f.Checked {
			add("checked_by", userID)
			add("checked_at", now)
		} else {
			add("checked_by", nil)
			add("checked_at", nil)
		}
	}
	if len(set) == 0 {
		return applied(), nil
	}
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return Result{}, err
	}
	add("updated_at", now)
	add("seq", seq)
	if _, err := tx.Exec(ctx, "UPDATE items SET "+strings.Join(set, ", ")+" WHERE id = $1", args...); err != nil {
		return Result{}, err
	}
	return applied(), nil
}

// lockList checks userID is a Member of listID and the List is not deleted,
// and locks it until tx ends, so the change can't race a delete or another
// change's limit check. ok false comes with the rejection: notFound if userID
// is not a Member or the List is gone, ReasonListDeleted if it is deleted.
func (s *Service) lockList(ctx context.Context, tx pgx.Tx, userID, listID uuid.UUID, notFound Reason) (Result, bool, error) {
	missing := rejected(notFound, "no such List")
	if notFound == ReasonItemNotFound {
		missing.Message = "no such Item"
	}
	_, err := s.members.RoleOf(ctx, listID, userID)
	if errors.Is(err, membership.ErrNotAMember) {
		return missing, false, nil
	}
	if err != nil {
		return Result{}, false, err
	}
	var deletedAt *time.Time
	err = tx.QueryRow(ctx, "SELECT deleted_at FROM lists WHERE id = $1 FOR UPDATE", listID).Scan(&deletedAt)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return missing, false, nil
	case err != nil:
		return Result{}, false, err
	case deletedAt != nil:
		return rejected(ReasonListDeleted, "the List is deleted"), false, nil
	}
	return Result{}, true, nil
}

// validate normalizes f, or returns the rejection for its first invalid field.
func validate(f Fields) (Fields, *Result) {
	invalid := func(msg string) (Fields, *Result) {
		r := rejected(ReasonInvalidItem, msg)
		return Fields{}, &r
	}
	if f.Name != nil {
		name, ok := names.Normalize(*f.Name, MaxNameLength)
		if !ok {
			return invalid(fmt.Sprintf("Item name must be 1 to %d visible characters", MaxNameLength))
		}
		f.Name = &name
	}
	if q := f.Quantity.Value; q != nil {
		n, ok := normalizeQuantity(*q)
		if !ok {
			return invalid("quantity must be a positive decimal with up to 6 digits and 3 decimals")
		}
		f.Quantity.Value = &n
	}
	if u := f.Unit.Value; u != nil && !isUnit(*u) {
		return invalid("unit must be one of " + strings.Join(Units, ", "))
	}
	if n := f.Note.Value; n != nil {
		note, ok := normalizeNote(*n)
		if !ok {
			return invalid(fmt.Sprintf("note must be at most %d characters", MaxNoteLength))
		}
		f.Note.Value = note
	}
	return f, nil
}

// normalizeQuantity returns q without leading or trailing zeros ("01.50" is
// "1.5") and reports whether it is a valid, positive quantity.
func normalizeQuantity(q string) (string, bool) {
	if !quantityPattern.MatchString(q) {
		return "", false
	}
	if v, err := strconv.ParseFloat(q, 64); err != nil || v <= 0 {
		return "", false
	}
	whole, frac, _ := strings.Cut(q, ".")
	whole = strings.TrimLeft(whole, "0")
	if whole == "" {
		whole = "0"
	}
	frac = strings.TrimRight(frac, "0")
	if frac == "" {
		return whole, true
	}
	return whole + "." + frac, true
}

// normalizeNote trims a note; an empty note clears it (nil). Line breaks are
// allowed, other control characters are not.
func normalizeNote(note string) (*string, bool) {
	note = strings.TrimSpace(note)
	if !utf8.ValidString(note) || utf8.RuneCountInString(note) > MaxNoteLength {
		return nil, false
	}
	for _, r := range note {
		if unicode.IsControl(r) && r != '\n' {
			return nil, false
		}
	}
	if note == "" {
		return nil, true
	}
	return &note, true
}

func isUnit(u string) bool {
	for _, x := range Units {
		if u == x {
			return true
		}
	}
	return false
}
