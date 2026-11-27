package testkit

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"

	"github.com/tsantanadev/cesta/backend/internal/platform/db"
	"github.com/tsantanadev/cesta/backend/migrations"
)

// postgresImage should match the version in docker-compose.yaml and production (Neon, infra/terraform).
const postgresImage = "postgres:18-alpine"

const templateDB = "cesta_template"

// cluster is one Postgres container per test binary. The schema is migrated once into a
// template database; each test gets its own copy, so tests are isolated and can run in parallel.
var cluster struct {
	once    sync.Once
	err     error
	admin   *pgxpool.Pool
	baseURL func(dbName string) string
	seq     atomic.Int64
}

func startCluster() error {
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
	// No explicit Terminate: testcontainers' reaper (Ryuk) removes the container
	// when the test binary exits.

	host, err := ctr.Host(ctx)
	if err != nil {
		return err
	}
	port, err := ctr.MappedPort(ctx, "5432/tcp")
	if err != nil {
		return err
	}
	cluster.baseURL = func(name string) string {
		return fmt.Sprintf("postgres://cesta:cesta@%s:%s/%s?sslmode=disable", host, port.Port(), name)
	}

	cluster.admin, err = db.Open(ctx, cluster.baseURL("postgres"))
	if err != nil {
		return err
	}
	if _, err := cluster.admin.Exec(ctx, "CREATE DATABASE "+templateDB); err != nil {
		return fmt.Errorf("create template database: %w", err)
	}
	tpl, err := db.Open(ctx, cluster.baseURL(templateDB))
	if err != nil {
		return err
	}
	defer tpl.Close()
	if err := migrations.Up(ctx, tpl); err != nil {
		return err
	}
	return nil
}

// newDatabase returns a pool for a fresh, fully migrated database owned by t, and its name.
func newDatabase(t testing.TB) (*pgxpool.Pool, string) {
	t.Helper()
	cluster.once.Do(func() { cluster.err = startCluster() })
	if cluster.err != nil {
		t.Fatalf("testkit: postgres: %v", cluster.err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	name := fmt.Sprintf("test_%d", cluster.seq.Add(1))
	ident := pgx.Identifier{name}.Sanitize()
	if _, err := cluster.admin.Exec(ctx, "CREATE DATABASE "+ident+" TEMPLATE "+templateDB); err != nil {
		t.Fatalf("testkit: create database: %v", err)
	}
	// A small pool, like CI runners get by default, so a transaction that
	// needs a second connection deadlocks here too, not only in CI.
	pool, err := db.Open(ctx, cluster.baseURL(name)+"&pool_max_conns=4")
	if err != nil {
		t.Fatalf("testkit: open database: %v", err)
	}
	t.Cleanup(func() {
		pool.Close()
		_, _ = cluster.admin.Exec(context.Background(), "DROP DATABASE IF EXISTS "+ident+" WITH (FORCE)")
	})
	return pool, name
}

// CutDatabase makes this server's database unreachable, as if Postgres went away:
// new connections are refused and open ones are killed. Other tests are unaffected.
func (s *Server) CutDatabase(t testing.TB) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	ident := pgx.Identifier{s.dbName}.Sanitize()
	if _, err := cluster.admin.Exec(ctx, "ALTER DATABASE "+ident+" ALLOW_CONNECTIONS false"); err != nil {
		t.Fatalf("testkit: cut database: %v", err)
	}
	if _, err := cluster.admin.Exec(ctx,
		"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = $1", s.dbName); err != nil {
		t.Fatalf("testkit: cut database: %v", err)
	}
}
