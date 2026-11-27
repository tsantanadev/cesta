package sync

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

// DefaultPullLimit and MaxPullLimit bound how many changes one pull returns.
const (
	DefaultPullLimit = 500
	MaxPullLimit     = 1000
)

// ErrInvalidCursor is returned for a cursor this backend didn't issue.
var ErrInvalidCursor = errors.New("sync: invalid cursor")

// ErrInvalidLimit is returned for a pull limit outside 1..MaxPullLimit.
var ErrInvalidLimit = errors.New("sync: invalid limit")

// UserRef is a User as other Members see them.
type UserRef struct {
	ID          uuid.UUID
	DisplayName string
}

// Item is one thing to buy on a List.
type Item struct {
	ID       uuid.UUID
	ListID   uuid.UUID
	Name     string
	Quantity *string
	Unit     *string
	Note     *string
	AddedBy  UserRef
	AddedAt  time.Time
	// CheckedAt and CheckedBy are set while the Item is checked (in the basket).
	CheckedAt *time.Time
	CheckedBy *UserRef
	UpdatedAt time.Time
}

// TombstoneType says what a Tombstone removes.
type TombstoneType string

// The kinds of tombstone.
const (
	// TombstoneItem is an Item that was removed.
	TombstoneItem TombstoneType = "item"
	// TombstoneList is a List the User can no longer see (it was deleted); the
	// device drops it and all its Items.
	TombstoneList TombstoneType = "list"
)

// Tombstone tells a device to drop something it may hold.
type Tombstone struct {
	Type TombstoneType
	ID   uuid.UUID
	// ListID is set for TombstoneItem.
	ListID uuid.UUID
}

// Changes are what changed since a cursor.
type Changes struct {
	Items      []Item
	Tombstones []Tombstone
	// Cursor is where the next pull continues.
	Cursor string
	// HasMore is true when there are changes past Cursor already.
	HasMore bool
}

// position is a place in the ordered stream of changes: the change number,
// then the id to break ties (a List that becomes visible brings all its Items
// at one number).
type position struct {
	seq int64
	id  uuid.UUID
}

func (p position) String() string {
	return base64.RawURLEncoding.EncodeToString([]byte("v1:" + strconv.FormatInt(p.seq, 10) + ":" + p.id.String()))
}

func parseCursor(c string) (position, error) {
	if c == "" {
		return position{}, nil
	}
	raw, err := base64.RawURLEncoding.DecodeString(c)
	if err != nil {
		return position{}, ErrInvalidCursor
	}
	parts := strings.Split(string(raw), ":")
	if len(parts) != 3 || parts[0] != "v1" {
		return position{}, ErrInvalidCursor
	}
	seq, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil || seq < 0 {
		return position{}, ErrInvalidCursor
	}
	id, err := uuid.Parse(parts[2])
	if err != nil {
		return position{}, ErrInvalidCursor
	}
	return position{seq: seq, id: id}, nil
}

// pullQuery lists, in order, every change past a position that userID ($1)
// should see:
//   - an Item of a List they are a Member of that is not deleted, at the later
//     of its own change and the List becoming visible to them (joining it, or
//     it being restored), so a newly visible List arrives whole;
//   - a removed Item, at its removal;
//   - a deleted List they are a Member of, at its deletion.
const pullQuery = `
WITH vis AS (
	SELECT l.id, l.deleted_at, l.visible_seq, GREATEST(m.seq, l.visible_seq) AS vseq
	FROM list_members m JOIN lists l ON l.id = m.list_id
	WHERE m.user_id = $1
), changes AS (
	SELECT 'item' AS kind, i.id, i.list_id,
		CASE WHEN i.deleted_at IS NULL THEN GREATEST(i.seq, v.vseq) ELSE i.seq END AS pos
	FROM items i JOIN vis v ON v.id = i.list_id AND v.deleted_at IS NULL
	UNION ALL
	SELECT 'list', v.id, v.id, v.visible_seq FROM vis v WHERE v.deleted_at IS NOT NULL
)
SELECT c.kind, c.id, c.list_id, c.pos, i.deleted_at IS NOT NULL,
	i.name, trim_scale(i.quantity)::text, i.unit, i.note,
	i.added_by, a.display_name, i.added_at,
	i.checked_by, b.display_name, i.checked_at, i.updated_at
FROM changes c
LEFT JOIN items i ON c.kind = 'item' AND i.id = c.id
LEFT JOIN users a ON a.id = i.added_by
LEFT JOIN users b ON b.id = i.checked_by
WHERE (c.pos, c.id) > ($2, $3)
ORDER BY c.pos, c.id
LIMIT $4`

// Pull returns the changes past cursor that userID should see, at most limit
// of them (0 means DefaultPullLimit). An empty cursor starts from the beginning.
func (s *Service) Pull(ctx context.Context, userID uuid.UUID, cursor string, limit int) (Changes, error) {
	if limit == 0 {
		limit = DefaultPullLimit
	}
	if limit < 1 || limit > MaxPullLimit {
		return Changes{}, ErrInvalidLimit
	}
	from, err := parseCursor(cursor)
	if err != nil {
		return Changes{}, err
	}
	rows, err := s.db.Query(ctx, pullQuery, userID, from.seq, from.id, limit+1)
	if err != nil {
		return Changes{}, fmt.Errorf("sync: pull: %w", err)
	}
	defer rows.Close()
	out := Changes{Items: []Item{}, Tombstones: []Tombstone{}}
	last, n := from, 0
	for rows.Next() {
		if n == limit {
			out.HasMore = true
			break
		}
		n++
		var (
			kind               string
			id, listID         uuid.UUID
			pos                int64
			removed            *bool
			name               *string
			it                 Item
			addedBy            *uuid.UUID
			addedByName        *string
			addedAt, updatedAt *time.Time
			checkedBy          *uuid.UUID
			checkedByName      *string
		)
		if err := rows.Scan(&kind, &id, &listID, &pos, &removed,
			&name, &it.Quantity, &it.Unit, &it.Note,
			&addedBy, &addedByName, &addedAt,
			&checkedBy, &checkedByName, &it.CheckedAt, &updatedAt); err != nil {
			return Changes{}, fmt.Errorf("sync: pull: %w", err)
		}
		last = position{seq: pos, id: id}
		switch {
		case kind == "list":
			out.Tombstones = append(out.Tombstones, Tombstone{Type: TombstoneList, ID: id})
		case removed != nil && *removed:
			out.Tombstones = append(out.Tombstones, Tombstone{Type: TombstoneItem, ID: id, ListID: listID})
		default:
			it.ID, it.ListID, it.Name = id, listID, deref(name)
			it.AddedBy = UserRef{ID: deref(addedBy), DisplayName: deref(addedByName)}
			it.AddedAt, it.UpdatedAt = deref(addedAt).UTC(), deref(updatedAt).UTC()
			if it.CheckedAt != nil {
				at := it.CheckedAt.UTC()
				it.CheckedAt = &at
				it.CheckedBy = &UserRef{ID: deref(checkedBy), DisplayName: deref(checkedByName)}
			}
			out.Items = append(out.Items, it)
		}
	}
	if err := rows.Err(); err != nil {
		return Changes{}, fmt.Errorf("sync: pull: %w", err)
	}
	out.Cursor = last.String()
	return out, nil
}

func deref[T any](p *T) T {
	var zero T
	if p == nil {
		return zero
	}
	return *p
}
