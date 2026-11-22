// Command cesta runs the Cesta backend.
//
//	cesta serve    run the HTTP API (default)
//	cesta migrate  apply pending database migrations, then exit
//
// Configuration comes from the environment:
//
//	DATABASE_URL                 Postgres URL (required)
//	PORT                         HTTP port (default 8080)
//	LOG_LEVEL                    debug, info, warn or error (default info)
//	OTEL_EXPORTER_OTLP_ENDPOINT  enables OTLP/HTTP export of traces and metrics (off when unset)
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/app"
	"github.com/tsantanadev/cesta/backend/internal/platform/db"
	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
	"github.com/tsantanadev/cesta/backend/migrations"
)

// version is set at build time with -ldflags "-X main.version=...".
var version = "dev"

func main() {
	logger := newLogger(os.Getenv("LOG_LEVEL"))
	slog.SetDefault(logger)

	cmd := "serve"
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}
	if err := run(cmd, logger); err != nil {
		logger.Error("exiting", slog.String("error", err.Error()))
		os.Exit(1)
	}
}

func run(cmd string, logger *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	switch cmd {
	case "serve":
		return serve(ctx, logger)
	case "migrate":
		return migrate(ctx, logger)
	default:
		return fmt.Errorf("unknown command %q (want serve or migrate)", cmd)
	}
}

func newLogger(level string) *slog.Logger {
	var l slog.Level
	if err := l.UnmarshalText([]byte(level)); err != nil {
		l = slog.LevelInfo
	}
	return slog.New(telemetry.LogHandler(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: l}))).
		With(slog.String("service", "cesta"), slog.String("version", version))
}

func databaseURL() (string, error) {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		return "", errors.New("DATABASE_URL is not set")
	}
	return url, nil
}

func migrate(ctx context.Context, logger *slog.Logger) error {
	url, err := databaseURL()
	if err != nil {
		return err
	}
	pool, err := db.Open(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()
	if err := migrations.Up(ctx, pool); err != nil {
		return err
	}
	logger.InfoContext(ctx, "migrations applied")
	return nil
}

func serve(ctx context.Context, logger *slog.Logger) error {
	url, err := databaseURL()
	if err != nil {
		return err
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	shutdownTelemetry, err := telemetry.Setup(ctx, "cesta-backend", version)
	if err != nil {
		return err
	}
	defer func() {
		ctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()
		if err := shutdownTelemetry(ctx); err != nil {
			logger.Warn("telemetry shutdown", slog.String("error", err.Error()))
		}
	}()

	pool, err := db.Open(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()

	srv := &http.Server{
		Addr:              net.JoinHostPort("", port),
		Handler:           app.New(app.Deps{DB: pool, Logger: logger}),
		ReadHeaderTimeout: 10 * time.Second,
	}

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	logger.InfoContext(ctx, "listening", slog.String("addr", srv.Addr), slog.Bool("otlp", telemetry.Enabled()))

	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
	}
	logger.Info("shutting down")
	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}
