// Package app wires the modular monolith into one HTTP handler.
//
// main builds Deps from real adapters; Seam 1 tests build them with fakes
// (TokenVerifier, EmailSender, Clock) and a real Postgres.
package app

import (
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
	"github.com/tsantanadev/cesta/backend/internal/platform/email"
)

// Deps are the external dependencies of the backend.
type Deps struct {
	DB            *pgxpool.Pool
	Logger        *slog.Logger
	TokenVerifier auth.TokenVerifier
	EmailSender   email.Sender
	Clock         clock.Clock
}

// New returns the backend's HTTP handler, instrumented with OpenTelemetry.
func New(d Deps) http.Handler {
	api := &httpapi.Server{DB: d.DB, Logger: d.Logger}
	return otelhttp.NewHandler(api.Handler(), "http.server")
}
