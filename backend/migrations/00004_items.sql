-- Items (lists module) and their offline sync (sync module, ADR-0001).
--
-- Every change a pull must see takes a number from change_seq, under one
-- transaction-scoped advisory lock held until commit (package changeseq), so
-- changes commit in number order and a pull's cursor never skips one:
--   items.seq                  an Item was created, edited or removed
--   lists.visible_seq          a List was deleted or restored
--   list_members.seq           a User became a Member of a List
-- Existing rows start at 0, before any cursor.

-- +goose Up
CREATE SEQUENCE change_seq;

ALTER TABLE lists ADD COLUMN visible_seq bigint NOT NULL DEFAULT 0;
ALTER TABLE list_members ADD COLUMN seq bigint NOT NULL DEFAULT 0;

-- An Item's id is chosen by the client (offline-first). A removed Item keeps
-- its row, with deleted_at, so pulls can send a tombstone and later edits are
-- rejected (a delete wins). added_by and checked_by are User ids.
CREATE TABLE items (
    id         uuid PRIMARY KEY,
    list_id    uuid NOT NULL REFERENCES lists (id) ON DELETE CASCADE,
    name       text NOT NULL,
    quantity   numeric(9, 3) CHECK (quantity > 0),
    unit       text CHECK (unit IN ('un', 'kg', 'g', 'L', 'ml', 'pack')),
    note       text,
    added_by   uuid NOT NULL,
    added_at   timestamptz NOT NULL,
    checked_by uuid,
    checked_at timestamptz,
    updated_at timestamptz NOT NULL,
    deleted_at timestamptz,
    seq        bigint NOT NULL
);

-- Pulls (a List's changes in order) and the per-List limit and counts.
CREATE INDEX items_list_seq_idx ON items (list_id, seq);
CREATE INDEX items_list_live_idx ON items (list_id) WHERE deleted_at IS NULL;

-- The result of every pushed mutation, so a retry returns it unchanged.
CREATE TABLE sync_mutations (
    user_id     uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    id          uuid NOT NULL,
    applied     boolean NOT NULL,
    reason_code text,
    reason      text,
    reason_limit integer,
    received_at timestamptz NOT NULL,
    PRIMARY KEY (user_id, id)
);

-- +goose Down
DROP TABLE sync_mutations;
DROP TABLE items;
ALTER TABLE list_members DROP COLUMN seq;
ALTER TABLE lists DROP COLUMN visible_seq;
DROP SEQUENCE change_seq;
