-- Item history (lists module): the Items bought on a List, one entry per
-- Item cleared after being checked (Clear checked). The entry copies what the
-- Item was when cleared and never changes; the Item itself keeps a tombstone.
-- seq is its number in the stream of changes a pull must see (package
-- changeseq). cleared_by is a User id.

-- +goose Up
CREATE TABLE item_history (
    item_id    uuid PRIMARY KEY,
    list_id    uuid NOT NULL REFERENCES lists (id) ON DELETE CASCADE,
    name       text NOT NULL,
    quantity   numeric(9, 3),
    unit       text,
    note       text,
    cleared_by uuid NOT NULL,
    cleared_at timestamptz NOT NULL,
    seq        bigint NOT NULL
);

-- Pulls (a List's history in order).
CREATE INDEX item_history_list_seq_idx ON item_history (list_id, seq);

-- +goose Down
DROP TABLE item_history;
