-- Baseline: establishes migration versioning. Domain tables arrive with the slices that need them.

-- +goose Up
SELECT 1;

-- +goose Down
SELECT 1;
