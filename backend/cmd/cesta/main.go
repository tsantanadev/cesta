// Command cesta runs the Cesta backend.
//
//	cesta serve    run the HTTP API (default)
//	cesta migrate  apply pending database migrations, then exit
//	cesta purge    remove Lists deleted more than 30 days ago, then exit (run daily)
//
// Configuration comes from the environment:
//
//	DATABASE_URL                 Postgres URL (required)
//	FIREBASE_PROJECT_ID          Firebase project whose ID tokens are accepted (required by serve)
//	TRUSTED_PROXY_HOPS           proxies in front of the backend that append to X-Forwarded-For (default 0)
//	RATE_LIMIT_PER_IP            requests allowed per client IP, as <burst>/<every> (default 120/250ms)
//	RATE_LIMIT_PER_USER          requests allowed per User, as <burst>/<every> (default 60/500ms)
//	MAX_LISTS_PER_USER           live Lists a User can own (default 100)
//	MAX_ITEMS_PER_LIST           Items a List can hold (default 500)
//	PORT                         HTTP port (default 8080)
//	LOG_LEVEL                    debug, info, warn or error (default info)
//	PUBLIC_HOST                  custom domain served by Firebase Hosting; other requests get 404 (off when unset)
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
	"strconv"
	"syscall"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/app"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth/firebase"
	"github.com/tsantanadev/cesta/backend/internal/platform/db"
	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
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
	case "purge":
		return purge(ctx, logger)
	default:
		return fmt.Errorf("unknown command %q (want serve, migrate or purge)", cmd)
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

// rateLimits reads RATE_LIMIT_PER_IP and RATE_LIMIT_PER_USER; an unset one
// keeps its default.
func rateLimits() (app.RateLimits, error) {
	limits := app.DefaultRateLimits
	for name, rule := range map[string]*ratelimit.Rule{
		"RATE_LIMIT_PER_IP":   &limits.PerIP,
		"RATE_LIMIT_PER_USER": &limits.PerUser,
	} {
		if v := os.Getenv(name); v != "" {
			r, err := ratelimit.ParseRule(v)
			if err != nil {
				return app.RateLimits{}, fmt.Errorf("%s: %w", name, err)
			}
			*rule = r
		}
	}
	return limits, nil
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

func purge(ctx context.Context, logger *slog.Logger) error {
	url, err := databaseURL()
	if err != nil {
		return err
	}
	pool, err := db.Open(ctx, url)
	if err != nil {
		return err
	}
	defer pool.Close()
	n, err := app.Purge(ctx, app.Deps{DB: pool, Logger: logger})
	if err != nil {
		return err
	}
	logger.InfoContext(ctx, "purged deleted lists", slog.Int("lists", n))
	return nil
}

func serve(ctx context.Context, logger *slog.Logger) error {
	url, err := databaseURL()
	if err != nil {
		return err
	}
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	if projectID == "" {
		return errors.New("FIREBASE_PROJECT_ID is not set")
	}
	hops := 0
	if v := os.Getenv("TRUSTED_PROXY_HOPS"); v != "" {
		if hops, err = strconv.Atoi(v); err != nil || hops < 0 {
			return fmt.Errorf("TRUSTED_PROXY_HOPS = %q, want a non-negative integer", v)
		}
	}
	limits, err := rateLimits()
	if err != nil {
		return err
	}
	maxLists, err := positiveEnv("MAX_LISTS_PER_USER")
	if err != nil {
		return err
	}
	maxItems, err := positiveEnv("MAX_ITEMS_PER_LIST")
	if err != nil {
		return err
	}
	publicHost := os.Getenv("PUBLIC_HOST")
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
		Addr: net.JoinHostPort("", port),
		Handler: app.New(app.Deps{
			DB:               pool,
			Logger:           logger,
			TokenVerifier:    firebase.NewVerifier(projectID),
			TrustedProxyHops: hops,
			RateLimits:       limits,
			PublicHost:       publicHost,
			MaxListsPerUser:  maxLists,
			MaxItemsPerList:  maxItems,
		}),
		ReadHeaderTimeout: 10 * time.Second,
	}

	errc := make(chan error, 1)
	go func() { errc <- srv.ListenAndServe() }()
	logger.InfoContext(ctx, "listening", slog.String("addr", srv.Addr), slog.Bool("otlp", telemetry.Enabled()),
		slog.String("public_host", publicHost))

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

// positiveEnv returns the positive integer in environment variable name, or 0 when it is unset.
func positiveEnv(name string) (int, error) {
	v := os.Getenv(name)
	if v == "" {
		return 0, nil
	}
	n, err := strconv.Atoi(v)
	if err != nil || n <= 0 {
		return 0, fmt.Errorf("%s = %q, want a positive integer", name, v)
	}
	return n, nil
}
