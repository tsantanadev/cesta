// Package db opens the Postgres connection pool.
package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	// defaultMaxConnIdleTime stays below Neon's 5-minute scale-to-zero suspend
	// window so idle connections are closed before compute sleeps.
	defaultMaxConnIdleTime = 3 * time.Minute

	// defaultConnectTimeout bounds dialing and waking a suspended Neon compute,
	// replacing pgxpool's 2-minute fallback when connect_timeout is unset in the URL.
	defaultConnectTimeout = 10 * time.Second
)

// Open creates a connection pool for the given Postgres URL. Connections are
// established lazily, so Open succeeds even if the database is not yet reachable.
//
// Query execution keeps pgx's default protocol-level prepared statement cache
// (QueryExecModeCacheStatement), relying on Neon PgBouncer's protocol-level
// prepared statement support in transaction pooling mode; queries must not issue
// SQL-level PREPARE statements.
func Open(ctx context.Context, url string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("db: parse url: %w", err)
	}
	cfg.MaxConnIdleTime = defaultMaxConnIdleTime
	if cfg.ConnConfig.ConnectTimeout == 0 {
		cfg.ConnConfig.ConnectTimeout = defaultConnectTimeout
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("db: open: %w", err)
	}
	return pool, nil
}
