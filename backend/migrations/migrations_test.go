package migrations_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pressly/goose/v3/lock"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"

	"github.com/tsantanadev/cesta/backend/internal/platform/db"
	"github.com/tsantanadev/cesta/backend/migrations"
)

// postgresImage should match backend/internal/testkit/postgres.go and production (Neon).
const postgresImage = "postgres:18-alpine"

var pgCluster struct {
	once    sync.Once
	err     error
	admin   *pgxpool.Pool
	baseURL func(dbName string) string
	seq     atomic.Int64
}

func startPostgres() error {
	ctx := context.Background()
	ctr, err := tcpostgres.Run(ctx, postgresImage,
		tcpostgres.WithDatabase("postgres"),
		tcpostgres.WithUsername("cesta"),
		tcpostgres.WithPassword("cesta"),
		tcpostgres.BasicWaitStrategies(),
	)
	if err != nil {
		return fmt.Errorf("start postgres container: %w", err)
	}
	host, err := ctr.Host(ctx)
	if err != nil {
		return err
	}
	port, err := ctr.MappedPort(ctx, "5432/tcp")
	if err != nil {
		return err
	}
	pgCluster.baseURL = func(name string) string {
		return fmt.Sprintf("postgres://cesta:cesta@%s:%s/%s?sslmode=disable", host, port.Port(), name)
	}
	pgCluster.admin, err = db.Open(ctx, pgCluster.baseURL("postgres"))
	return err
}

func newEmptyDatabaseURL(t *testing.T) string {
	t.Helper()
	pgCluster.once.Do(func() { pgCluster.err = startPostgres() })
	if pgCluster.err != nil {
		t.Fatalf("postgres: %v", pgCluster.err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	name := fmt.Sprintf("mig_test_%d", pgCluster.seq.Add(1))
	ident := pgx.Identifier{name}.Sanitize()
	if _, err := pgCluster.admin.Exec(ctx, "CREATE DATABASE "+ident); err != nil {
		t.Fatalf("create database: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pgCluster.admin.Exec(context.Background(), "DROP DATABASE IF EXISTS "+ident+" WITH (FORCE)")
	})
	return pgCluster.baseURL(name)
}

func TestUpSerializesConcurrentCalls(t *testing.T) {
	url := newEmptyDatabaseURL(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	poolA, err := db.Open(ctx, url)
	if err != nil {
		t.Fatalf("open pool A: %v", err)
	}
	defer poolA.Close()

	poolB, err := db.Open(ctx, url)
	if err != nil {
		t.Fatalf("open pool B: %v", err)
	}
	defer poolB.Close()

	start := make(chan struct{})
	errs := make([]error, 2)
	var wg sync.WaitGroup
	for i, pool := range []*pgxpool.Pool{poolA, poolB} {
		wg.Add(1)
		go func(idx int, p *pgxpool.Pool) {
			defer wg.Done()
			<-start
			errs[idx] = migrations.Up(ctx, p)
		}(i, pool)
	}
	close(start)
	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("concurrent Up[%d] failed: %v", i, err)
		}
	}

	var appliedCount int
	if err := poolA.QueryRow(ctx, "SELECT COUNT(*) FROM goose_db_version WHERE version_id = 1 AND is_applied").Scan(&appliedCount); err != nil {
		t.Fatalf("query goose_db_version: %v", err)
	}
	if appliedCount != 1 {
		t.Errorf("applied baseline count = %d, want 1", appliedCount)
	}
}

func TestUpAcquiresPostgresAdvisorySessionLock(t *testing.T) {
	url := newEmptyDatabaseURL(t)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Hold goose's Postgres session advisory lock on a dedicated connection.
	lockConn, err := pgx.Connect(ctx, url)
	if err != nil {
		t.Fatalf("connect lock holder: %v", err)
	}
	defer func() { _ = lockConn.Close(context.Background()) }()

	if _, err := lockConn.Exec(ctx, "SELECT pg_advisory_lock($1)", lock.DefaultLockID); err != nil {
		t.Fatalf("acquire advisory lock: %v", err)
	}

	pool, err := db.Open(ctx, url)
	if err != nil {
		t.Fatalf("open pool: %v", err)
	}
	defer pool.Close()

	// While the advisory lock is held, migrations.Up must block until context expires.
	blockedCtx, blockedCancel := context.WithTimeout(ctx, 200*time.Millisecond)
	defer blockedCancel()
	if err := migrations.Up(blockedCtx, pool); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("Up while lock held = %v, want context.DeadlineExceeded", err)
	}

	// Releasing the advisory lock lets migrations.Up succeed.
	if _, err := lockConn.Exec(ctx, "SELECT pg_advisory_unlock($1)", lock.DefaultLockID); err != nil {
		t.Fatalf("release advisory lock: %v", err)
	}
	if err := migrations.Up(ctx, pool); err != nil {
		t.Fatalf("Up after lock released: %v", err)
	}
}
