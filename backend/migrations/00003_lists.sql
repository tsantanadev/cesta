-- Lists (lists module) and their Members (membership module). A List's id is
-- chosen by the client (offline-first, ADR-0001). owner_id never changes; the
-- Owner also has a list_members row with role 'owner', the only one per List.
-- A deleted List keeps deleted_at for 30 days, then the purge job removes it.

-- +goose Up
CREATE TABLE lists (
    id         uuid PRIMARY KEY,
    owner_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       text NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    deleted_at timestamptz
);

-- The Owner's live Lists (limit check) and their deleted ones (Recently deleted).
CREATE INDEX lists_owner_live_idx ON lists (owner_id) WHERE deleted_at IS NULL;
CREATE INDEX lists_owner_deleted_idx ON lists (owner_id, deleted_at) WHERE deleted_at IS NOT NULL;
-- The purge job.
CREATE INDEX lists_deleted_at_idx ON lists (deleted_at) WHERE deleted_at IS NOT NULL;

CREATE TABLE list_members (
    list_id   uuid NOT NULL REFERENCES lists (id) ON DELETE CASCADE,
    user_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role      text NOT NULL CHECK (role IN ('owner', 'editor')),
    joined_at timestamptz NOT NULL,
    PRIMARY KEY (list_id, user_id)
);

-- Exactly one Owner per List.
CREATE UNIQUE INDEX list_members_one_owner_idx ON list_members (list_id) WHERE role = 'owner';
-- "Lists I'm a Member of".
CREATE INDEX list_members_user_idx ON list_members (user_id);

-- +goose Down
DROP TABLE list_members;
DROP TABLE lists;
