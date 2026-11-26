// Package migrations holds the versioned database schema migrations and applies them.
//
// Migrations are goose SQL files named NNNNN_description.sql, embedded in the binary.
// They run via `cesta migrate` as part of every deploy, and in Seam 1 tests.
package migrations

import (
	"context"
	"embed"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/pressly/goose/v3/lock"
)

//go:embed *.sql
var files embed.FS

// Up applies every pending migration to the database behind pool.
//
// It acquires a Postgres session-level advisory lock so overlapping migrate
// executions serialize instead of racing. Callers must connect directly to
// Postgres rather than through a transaction-mode pooler.
func Up(ctx context.Context, pool *pgxpool.Pool) error {
	locker, err := lock.NewPostgresSessionLocker()
	if err != nil {
		return fmt.Errorf("migrations: session locker: %w", err)
	}
	db := stdlib.OpenDBFromPool(pool)
	defer func() { _ = db.Close() }()
	provider, err := goose.NewProvider(
		goose.DialectPostgres,
		db,
		files,
		goose.WithSessionLocker(locker),
		goose.WithDisableGlobalRegistry(true),
	)
	if err != nil {
		return fmt.Errorf("migrations: %w", err)
	}
	if _, err := provider.Up(ctx); err != nil {
		return fmt.Errorf("migrations: up: %w", err)
	}
	return nil
}
