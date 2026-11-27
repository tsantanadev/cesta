-- The time the device said it made each pushed change, kept only for
-- diagnosis: receipt order decides conflicts (ADR-0001).

-- +goose Up
ALTER TABLE sync_mutations ADD COLUMN client_timestamp timestamptz;

-- +goose Down
ALTER TABLE sync_mutations DROP COLUMN client_timestamp;
