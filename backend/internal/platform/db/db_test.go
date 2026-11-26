package db_test

import (
	"context"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/tsantanadev/cesta/backend/internal/platform/db"
)

func TestOpenConfiguresPoolForNeonScaleToZero(t *testing.T) {
	pool, err := db.Open(context.Background(), "postgres://cesta:cesta@localhost:5432/cesta")
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	defer pool.Close()

	cfg := pool.Config()
	if cfg.MaxConnIdleTime <= 0 || cfg.MaxConnIdleTime >= 5*time.Minute {
		t.Errorf("MaxConnIdleTime = %s, want positive duration below Neon's 5m suspend window", cfg.MaxConnIdleTime)
	}
	if cfg.MaxConnIdleTime != 3*time.Minute {
		t.Errorf("MaxConnIdleTime = %s, want 3m0s", cfg.MaxConnIdleTime)
	}
	if cfg.ConnConfig.ConnectTimeout <= 0 {
		t.Errorf("ConnectTimeout = %s, want explicit positive duration", cfg.ConnConfig.ConnectTimeout)
	}
	if cfg.ConnConfig.ConnectTimeout != 10*time.Second {
		t.Errorf("ConnectTimeout = %s, want 10s", cfg.ConnConfig.ConnectTimeout)
	}
	if cfg.ConnConfig.DefaultQueryExecMode != pgx.QueryExecModeCacheStatement {
		t.Errorf("DefaultQueryExecMode = %v, want %v", cfg.ConnConfig.DefaultQueryExecMode, pgx.QueryExecModeCacheStatement)
	}
}

func TestOpenRespectsURLConnectTimeoutAndPoolMaxConns(t *testing.T) {
	pool, err := db.Open(
		context.Background(),
		"postgres://cesta:cesta@localhost:5432/cesta?pool_max_conns=5&connect_timeout=7",
	)
	if err != nil {
		t.Fatalf("Open: %v", err)
	}
	defer pool.Close()

	cfg := pool.Config()
	if cfg.MaxConns != 5 {
		t.Errorf("MaxConns = %d, want 5", cfg.MaxConns)
	}
	if cfg.ConnConfig.ConnectTimeout != 7*time.Second {
		t.Errorf("ConnectTimeout = %s, want 7s", cfg.ConnConfig.ConnectTimeout)
	}
}

func TestOpenRejectsInvalidURL(t *testing.T) {
	pool, err := db.Open(context.Background(), "://bad-url")
	if err == nil {
		pool.Close()
		t.Fatal("Open succeeded for invalid URL, want error")
	}
}
