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
	"github.com/jackc/pgx/v5"

	"github.com/tsantanadev/cesta/backend/internal/lists"
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
	var out Changes
	// One snapshot for the Lists the User sees and their changes.
	err = pgx.BeginTxFunc(ctx, s.db, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly},
		func(tx pgx.Tx) error {
			var err error
			out, err = s.pull(ctx, tx, userID, from, limit)
			return err
		})
	if err != nil {
		return Changes{}, fmt.Errorf("sync: pull: %w", err)
	}
	return out, nil
}

// pull reads, inside tx, the changes past from that userID should see: the
// Lists they joined (package membership), those Lists' changes (package
// lists) and the names of the Users the Items mention (package identity).
func (s *Service) pull(ctx context.Context, tx pgx.Tx, userID uuid.UUID, from position, limit int) (Changes, error) {
	joined, err := s.members.JoinedIn(ctx, tx, userID)
	if err != nil {
		return Changes{}, err
	}
	changes, err := s.lists.ChangesIn(ctx, tx, joined, from.seq, from.id, limit+1)
	if err != nil {
		return Changes{}, err
	}
	out := Changes{Items: []Item{}, Tombstones: []Tombstone{}}
	if len(changes) > limit {
		changes, out.HasMore = changes[:limit], true
	}
	names, err := s.identity.DisplayNamesIn(ctx, tx, mentioned(changes))
	if err != nil {
		return Changes{}, err
	}
	ref := func(id uuid.UUID) UserRef { return UserRef{ID: id, DisplayName: names[id]} }
	last := from
	for _, c := range changes {
		last = position{seq: c.Seq, id: c.ID}
		switch c.Kind {
		case lists.ListDeleted:
			out.Tombstones = append(out.Tombstones, Tombstone{Type: TombstoneList, ID: c.ID})
		case lists.ItemRemoved:
			out.Tombstones = append(out.Tombstones, Tombstone{Type: TombstoneItem, ID: c.ID, ListID: c.ListID})
		case lists.ItemChanged:
			it := c.Item
			item := Item{
				ID: it.ID, ListID: it.ListID, Name: it.Name,
				Quantity: it.Quantity, Unit: it.Unit, Note: it.Note,
				AddedBy: ref(it.AddedBy), AddedAt: it.AddedAt,
				CheckedAt: it.CheckedAt, UpdatedAt: it.UpdatedAt,
			}
			if it.CheckedBy != nil {
				by := ref(*it.CheckedBy)
				item.CheckedBy = &by
			}
			out.Items = append(out.Items, item)
		}
	}
	out.Cursor = last.String()
	return out, nil
}

// mentioned returns the Users who added or checked the Items in changes.
func mentioned(changes []lists.Change) []uuid.UUID {
	seen := map[uuid.UUID]bool{}
	var ids []uuid.UUID
	add := func(id uuid.UUID) {
		if !seen[id] {
			seen[id] = true
			ids = append(ids, id)
		}
	}
	for _, c := range changes {
		if c.Item == nil {
			continue
		}
		add(c.Item.AddedBy)
		if c.Item.CheckedBy != nil {
			add(*c.Item.CheckedBy)
		}
	}
	return ids
}
