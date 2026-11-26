-- Users (identity module). auth_subject is the identity provider's user ID (the
-- Firebase UID); every other module refers to a User only by id.

-- +goose Up
CREATE TABLE users (
    id                     uuid PRIMARY KEY DEFAULT uuidv7(),
    auth_subject           text NOT NULL UNIQUE,
    email                  text NOT NULL,
    display_name           text NOT NULL,
    display_name_confirmed boolean NOT NULL DEFAULT false,
    created_at             timestamptz NOT NULL,
    updated_at             timestamptz NOT NULL
);

-- +goose Down
DROP TABLE users;
