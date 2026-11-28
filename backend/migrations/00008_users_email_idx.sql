-- Users by email address in the form sharing compares it in (trimmed and
-- lowercased), so inviting checks whether the address is already a Member's
-- without scanning every User.

-- +goose Up
CREATE INDEX users_canonical_email_idx ON users (lower(btrim(email)));

-- +goose Down
DROP INDEX users_canonical_email_idx;
