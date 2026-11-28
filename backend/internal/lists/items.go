package lists

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

// DefaultMaxItemsPerList is how many Items a List can hold, not counting removed ones.
const DefaultMaxItemsPerList = 500

// MaxItemNameLength is the longest Item name, in characters.
const MaxItemNameLength = 80

// MaxItemNoteLength is the longest Item note, in characters.
const MaxItemNoteLength = 200

// Units are the units an Item's quantity can have. The set is fixed.
var Units = []string{"un", "kg", "g", "L", "ml", "pack"}

// quantityPattern is a positive decimal with up to 6 integer and 3 fractional digits.
var quantityPattern = regexp.MustCompile(`^[0-9]{1,6}(\.[0-9]{1,3})?$`)

var (
	// ErrItemNotFound is returned for a change to an Item that doesn't exist,
	// or whose List the User is not a Member of.
	ErrItemNotFound error = listError("item not found")
	// ErrItemDeleted is returned for a change to a removed Item: a delete wins.
	ErrItemDeleted error = listError("item deleted")
	// ErrItemIDTaken is returned when creating an Item with the id of an Item on another List.
	ErrItemIDTaken error = listError("item id taken")
	// ErrItemNotChecked is returned for clearing an Item that is not checked.
	ErrItemNotChecked error = listError("item not checked")
)

// InvalidItemError is returned for Item fields that are not acceptable.
type InvalidItemError struct {
	Message string
}

func (e *InvalidItemError) Error() string { return "lists: invalid item: " + e.Message }

// ItemLimitError is returned when a List already holds the most Items allowed.
type ItemLimitError struct {
	Limit int
}

func (e *ItemLimitError) Error() string {
	return fmt.Sprintf("lists: the List already holds the limit of %d Items", e.Limit)
}

// ItemField is an optional field of an Item change. Present false leaves the
// field as it is; Present with a nil Value clears it.
type ItemField[T any] struct {
	Present bool
	Value   *T
}

// ItemFields are the Item fields a change sets.
type ItemFields struct {
	// Name is required to create an Item and can't be cleared; nil leaves it as it is.
	Name     *string
	Quantity ItemField[string]
	Unit     ItemField[string]
	Note     ItemField[string]
	// Checked true marks the Item bought by the changing User at that moment;
	// false unchecks it; nil leaves it as it is.
	Checked *bool
}

// Item is one thing to buy on a List. Users are known by ID only.
type Item struct {
	ID       uuid.UUID
	ListID   uuid.UUID
	Name     string
	Quantity *string
	Unit     *string
	Note     *string
	AddedBy  uuid.UUID
	AddedAt  time.Time
	// CheckedAt and CheckedBy are set while the Item is checked (in the basket).
	CheckedAt *time.Time
	CheckedBy *uuid.UUID
	UpdatedAt time.Time
}

// CreateItem adds Item id with fields f to listID on behalf of userID, inside
// the caller's transaction tx, at now. Creating an Item that exists already
// on that List sets its fields like UpdateItem, so a retry is harmless.
//
// It returns ErrNotFound if userID is not a Member or the List is gone,
// ErrDeleted for a deleted List, ErrItemIDTaken, ErrItemDeleted, an
// *InvalidItemError or an *ItemLimitError.
func (s *Service) CreateItem(
	ctx context.Context, tx pgx.Tx, userID, listID, id uuid.UUID, f ItemFields, now time.Time,
) error {
	if f.Name == nil {
		return &InvalidItemError{Message: "an Item needs a name"}
	}
	f, err := validateItem(f)
	if err != nil {
		return err
	}
	if err := s.lockForItems(ctx, tx, userID, listID); err != nil {
		return err
	}
	var onList uuid.UUID
	var deletedAt *time.Time
	err = tx.QueryRow(ctx, "SELECT list_id, deleted_at FROM items WHERE id = $1 FOR UPDATE", id).
		Scan(&onList, &deletedAt)
	switch {
	case err == nil && onList != listID:
		return ErrItemIDTaken
	case err == nil && deletedAt != nil:
		return ErrItemDeleted
	case err == nil:
		return updateItem(ctx, tx, userID, id, f, now)
	case !errors.Is(err, pgx.ErrNoRows):
		return wrap("create item", err)
	}
	var live int
	if err := tx.QueryRow(ctx,
		"SELECT count(*) FROM items WHERE list_id = $1 AND deleted_at IS NULL", listID).Scan(&live); err != nil {
		return wrap("create item", err)
	}
	if live >= s.maxItems {
		return &ItemLimitError{Limit: s.maxItems}
	}
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return err
	}
	var checkedBy *uuid.UUID
	var checkedAt *time.Time
	if f.Checked != nil && *f.Checked {
		checkedBy, checkedAt = &userID, &now
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO items (id, list_id, name, quantity, unit, note, added_by, added_at, checked_by, checked_at, updated_at, seq)
		VALUES ($1, $2, $3, $4::numeric, $5, $6, $7, $8, $9, $10, $8, $11)`,
		id, listID, *f.Name, f.Quantity.Value, f.Unit.Value, f.Note.Value, userID, now, checkedBy, checkedAt, seq)
	return wrap("create item", err)
}

// UpdateItem sets the fields f carries on Item id on behalf of userID, inside
// tx, at now, leaving the others as they are.
//
// It returns ErrItemNotFound, ErrDeleted for an Item of a deleted List,
// ErrItemDeleted or an *InvalidItemError.
func (s *Service) UpdateItem(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID, f ItemFields, now time.Time) error {
	deletedAt, err := s.lockItem(ctx, tx, userID, id)
	if err != nil {
		return err
	}
	if deletedAt != nil {
		return ErrItemDeleted
	}
	f, err = validateItem(f)
	if err != nil {
		return err
	}
	return updateItem(ctx, tx, userID, id, f, now)
}

// RemoveItem removes Item id on behalf of userID, inside tx, at now. The
// Item keeps a tombstone, so later changes to it fail with ErrItemDeleted.
// Removing it again changes nothing.
//
// It returns ErrItemNotFound or ErrDeleted for an Item of a deleted List.
func (s *Service) RemoveItem(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID, now time.Time) error {
	deletedAt, err := s.lockItem(ctx, tx, userID, id)
	if err != nil || deletedAt != nil {
		return err
	}
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return err
	}
	_, err = tx.Exec(ctx, "UPDATE items SET deleted_at = $2, updated_at = $2, seq = $3 WHERE id = $1", id, now, seq)
	return wrap("remove item", err)
}

// ClearItem clears Checked Item id from its List on behalf of userID, inside
// tx, at now (Clear checked): the Item is removed, keeping a tombstone, and
// recorded in the List's Item history as it was. Clearing it again changes
// nothing.
//
// It returns ErrItemNotFound, ErrDeleted for an Item of a deleted List,
// ErrItemNotChecked, or ErrItemDeleted for an Item removed without being cleared.
func (s *Service) ClearItem(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID, now time.Time) error {
	deletedAt, err := s.lockItem(ctx, tx, userID, id)
	if err != nil {
		return err
	}
	if deletedAt != nil {
		var cleared bool
		if err := tx.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM item_history WHERE item_id = $1)", id).
			Scan(&cleared); err != nil {
			return wrap("clear item", err)
		}
		if cleared {
			return nil
		}
		return ErrItemDeleted
	}
	var checked bool
	if err := tx.QueryRow(ctx, "SELECT checked_at IS NOT NULL FROM items WHERE id = $1", id).
		Scan(&checked); err != nil {
		return wrap("clear item", err)
	}
	if !checked {
		return ErrItemNotChecked
	}
	// Two numbers: the tombstone and the history entry share the Item's id,
	// and a pull cursor tells changes apart by number, then id.
	removedSeq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return err
	}
	historySeq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO item_history (item_id, list_id, name, quantity, unit, note, cleared_by, cleared_at, seq)
		SELECT id, list_id, name, quantity, unit, note, $2, $3, $4 FROM items WHERE id = $1`,
		id, userID, now, historySeq); err != nil {
		return wrap("clear item", err)
	}
	_, err = tx.Exec(ctx, "UPDATE items SET deleted_at = $2, updated_at = $2, seq = $3 WHERE id = $1", id, now, removedSeq)
	return wrap("clear item", err)
}

// lockItem locks Item id's List (see lockForItems), then the Item, and
// returns when it was removed, if it was.
func (s *Service) lockItem(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID) (*time.Time, error) {
	var listID uuid.UUID
	err := tx.QueryRow(ctx, "SELECT list_id FROM items WHERE id = $1", id).Scan(&listID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrItemNotFound
	}
	if err != nil {
		return nil, wrap("lock item", err)
	}
	switch err := s.lockForItems(ctx, tx, userID, listID); {
	case errors.Is(err, ErrNotFound):
		return nil, ErrItemNotFound
	case err != nil:
		return nil, err
	}
	var deletedAt *time.Time
	if err := tx.QueryRow(ctx, "SELECT deleted_at FROM items WHERE id = $1 FOR UPDATE", id).
		Scan(&deletedAt); err != nil {
		return nil, wrap("lock item", err)
	}
	return deletedAt, nil
}

// lockForItems locks listID until tx ends, if userID is a Member of it, so a
// change to its Items can't race the List being deleted, restored or purged,
// nor another change's check of how many Items it holds. It returns
// ErrNotFound if userID is not a Member or the List is gone, and ErrDeleted
// if the List is deleted.
func (s *Service) lockForItems(ctx context.Context, tx pgx.Tx, userID, listID uuid.UUID) error {
	var deletedAt *time.Time
	err := tx.QueryRow(ctx, "SELECT deleted_at FROM lists WHERE id = $1 FOR UPDATE", listID).Scan(&deletedAt)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return ErrNotFound
	case err != nil:
		return wrap("lock for items", err)
	}
	// Under the lock, so the answer holds for the caller's whole change.
	if _, err := s.members.RoleIn(ctx, tx, listID, userID); errors.Is(err, membership.ErrNotAMember) {
		return ErrNotFound
	} else if err != nil {
		return err
	}
	if deletedAt != nil {
		return ErrDeleted
	}
	return nil
}

// updateItem sets the fields f carries on live Item id, leaving the others as they are.
func updateItem(ctx context.Context, tx pgx.Tx, userID, id uuid.UUID, f ItemFields, now time.Time) error {
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
		return nil
	}
	seq, err := changeseq.Next(ctx, tx)
	if err != nil {
		return err
	}
	add("updated_at", now)
	add("seq", seq)
	_, err = tx.Exec(ctx, "UPDATE items SET "+strings.Join(set, ", ")+" WHERE id = $1", args...)
	return wrap("update item", err)
}

// UncheckedCounts returns how many Items to buy (not removed, not checked)
// each of listIDs has. Lists with none are missing from the map.
func (s *Service) UncheckedCounts(ctx context.Context, listIDs []uuid.UUID) (map[uuid.UUID]int, error) {
	rows, err := s.db.Query(ctx, `
		SELECT list_id, count(*) FROM items
		WHERE list_id = ANY($1) AND deleted_at IS NULL AND checked_at IS NULL
		GROUP BY list_id`, listIDs)
	if err != nil {
		return nil, wrap("unchecked counts", err)
	}
	out := map[uuid.UUID]int{}
	var id uuid.UUID
	var n int
	_, err = pgx.ForEachRow(rows, []any{&id, &n}, func() error {
		out[id] = n
		return nil
	})
	if err != nil {
		return nil, wrap("unchecked counts", err)
	}
	return out, nil
}

// validateItem normalizes f, or returns an *InvalidItemError for its first invalid field.
func validateItem(f ItemFields) (ItemFields, error) {
	invalid := func(msg string) (ItemFields, error) { return ItemFields{}, &InvalidItemError{Message: msg} }
	if f.Name != nil {
		name, ok := names.Normalize(*f.Name, MaxItemNameLength)
		if !ok {
			return invalid(fmt.Sprintf("Item name must be 1 to %d visible characters", MaxItemNameLength))
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
			return invalid(fmt.Sprintf("note must be at most %d characters", MaxItemNoteLength))
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
	if !utf8.ValidString(note) || utf8.RuneCountInString(note) > MaxItemNoteLength {
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
