// Package changeseq numbers the changes a sync pull must see (ADR-0001).
//
// Next takes one advisory lock shared by every such change and holds it until
// the transaction ends, then draws the next number. Changes therefore commit in
// number order, so any snapshot sees every number up to some point and none
// after it, and a pull cursor ("everything up to N") never skips a change.
//
// The lock serializes these changes across the whole backend. Take it last in a
// transaction, after any row locks, so it is held briefly and the lock order
// is the same everywhere.
package changeseq

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
)

// lockKey is the advisory lock every numbered change takes.
const lockKey = 7_001

// Next locks out other numbered changes until tx ends and returns the next number.
func Next(ctx context.Context, tx pgx.Tx) (int64, error) {
	if _, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", lockKey); err != nil {
		return 0, fmt.Errorf("changeseq: lock: %w", err)
	}
	var n int64
	if err := tx.QueryRow(ctx, "SELECT nextval('change_seq')").Scan(&n); err != nil {
		return 0, fmt.Errorf("changeseq: next: %w", err)
	}
	return n, nil
}
