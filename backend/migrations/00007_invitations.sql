-- Invitations (sharing module): an offer, addressed to an email address, to
-- become an Editor of a List. Only the SHA-256 hash of the single-use token in
-- the deep link is stored. An Invitation expires at expires_at (14 days after
-- created_at); expiry is not a stored status. invited_by and responded_by are
-- User ids; responded_by is who accepted or declined it.

-- +goose Up
CREATE TABLE invitations (
    id           uuid PRIMARY KEY DEFAULT uuidv7(),
    list_id      uuid NOT NULL REFERENCES lists (id) ON DELETE CASCADE,
    email        text NOT NULL,
    token_hash   bytea NOT NULL UNIQUE,
    invited_by   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),
    created_at   timestamptz NOT NULL,
    expires_at   timestamptz NOT NULL,
    responded_by uuid REFERENCES users (id) ON DELETE SET NULL,
    responded_at timestamptz
);

-- A List's pending Invitations, and a User's (by email).
CREATE INDEX invitations_list_pending_idx ON invitations (list_id) WHERE status = 'pending';
CREATE INDEX invitations_email_pending_idx ON invitations (email) WHERE status = 'pending';
-- The daily limit: Invitations a User sent recently.
CREATE INDEX invitations_invited_by_idx ON invitations (invited_by, created_at);

-- +goose Down
DROP TABLE invitations;
