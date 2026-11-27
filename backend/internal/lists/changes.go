package lists

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/tsantanadev/cesta/backend/internal/membership"
)

// ChangeKind says what a Change is.
type ChangeKind int

// The kinds of change.
const (
	// ItemChanged is an Item that was added or changed, or that arrives with
	// its List becoming visible.
	ItemChanged ChangeKind = iota + 1
	// ItemRemoved is an Item that was removed.
	ItemRemoved
	// ListDeleted is a List that was deleted; its Items go with it.
	ListDeleted
)

// Change is one change a Member should see, at a place in the ordered
// stream of changes (package changeseq): its number Seq, then its ID to break
// ties (a List that becomes visible brings all its Items at one number).
type Change struct {
	Kind ChangeKind
	// ID is the Item's, or for ListDeleted the List's.
	ID     uuid.UUID
	ListID uuid.UUID
	Seq    int64
	// Item is set for ItemChanged.
	Item *Item
}

// changesQuery lists, in order, every change past a position ($2, $3) to the
// Lists given by id ($1) with when the User joined each ($4), at most $5:
//   - an Item of a List that is not deleted, at the later of its own change
//     and the List becoming visible to them (joining it, or it being
//     restored), so a newly visible List arrives whole;
//   - a removed Item, at its removal;
//   - a deleted List, at its deletion.
const changesQuery = `
WITH joined AS (
	SELECT j.id, j.joined_seq FROM unnest($1::uuid[], $4::bigint[]) AS j(id, joined_seq)
), vis AS (
	SELECT l.id, l.deleted_at IS NOT NULL AS deleted, l.visible_seq,
		GREATEST(j.joined_seq, l.visible_seq) AS vseq
	FROM lists l JOIN joined j ON j.id = l.id
), changes AS (
	SELECT 'item' AS kind, i.id, i.list_id,
		CASE WHEN i.deleted_at IS NULL THEN GREATEST(i.seq, v.vseq) ELSE i.seq END AS pos
	FROM items i JOIN vis v ON v.id = i.list_id AND NOT v.deleted
	UNION ALL
	SELECT 'list', v.id, v.id, v.visible_seq FROM vis v WHERE v.deleted
)
SELECT c.kind, c.id, c.list_id, c.pos, i.deleted_at IS NOT NULL,
	i.name, trim_scale(i.quantity)::text, i.unit, i.note,
	i.added_by, i.added_at, i.checked_by, i.checked_at, i.updated_at
FROM changes c
LEFT JOIN items i ON c.kind = 'item' AND i.id = c.id
WHERE (c.pos, c.id) > ($2, $3)
ORDER BY c.pos, c.id
LIMIT $5`

// ChangesIn returns, read inside the caller's transaction tx, at most limit
// changes past (afterSeq, afterID) to the Lists the User joined, in order.
// joined comes from package membership.
func (s *Service) ChangesIn(
	ctx context.Context, tx pgx.Tx, joined []membership.Joined, afterSeq int64, afterID uuid.UUID, limit int,
) ([]Change, error) {
	ids := make([]uuid.UUID, 0, len(joined))
	seqs := make([]int64, 0, len(joined))
	for _, j := range joined {
		ids, seqs = append(ids, j.ListID), append(seqs, j.Seq)
	}
	rows, err := tx.Query(ctx, changesQuery, ids, afterSeq, afterID, seqs, limit)
	if err != nil {
		return nil, wrap("changes", err)
	}
	out, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (Change, error) {
		var (
			c                  Change
			kind               string
			removed            *bool
			name               *string
			it                 Item
			addedBy            *uuid.UUID
			addedAt, updatedAt *time.Time
		)
		if err := row.Scan(&kind, &c.ID, &c.ListID, &c.Seq, &removed,
			&name, &it.Quantity, &it.Unit, &it.Note,
			&addedBy, &addedAt, &it.CheckedBy, &it.CheckedAt, &updatedAt); err != nil {
			return Change{}, err
		}
		switch {
		case kind == "list":
			c.Kind = ListDeleted
		case removed != nil && *removed:
			c.Kind = ItemRemoved
		default:
			c.Kind = ItemChanged
			it.ID, it.ListID, it.Name = c.ID, c.ListID, deref(name)
			it.AddedBy, it.AddedAt, it.UpdatedAt = deref(addedBy), deref(addedAt).UTC(), deref(updatedAt).UTC()
			if it.CheckedAt != nil {
				at := it.CheckedAt.UTC()
				it.CheckedAt = &at
			} else {
				it.CheckedBy = nil
			}
			c.Item = &it
		}
		return c, nil
	})
	if err != nil {
		return nil, wrap("changes", err)
	}
	return out, nil
}

func deref[T any](p *T) T {
	var zero T
	if p == nil {
		return zero
	}
	return *p
}
