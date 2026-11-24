// Package app wires the modular monolith into one HTTP handler.
//
// main builds Deps from real adapters; Seam 1 tests build them with a real
// Postgres. External services (TokenVerifier, EmailSender, Clock) join Deps
// with the slices that first use them.
package app

import (
	"log/slog"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
)

// Deps are the external dependencies of the backend.
type Deps struct {
	DB     *pgxpool.Pool
	Logger *slog.Logger
}

// New returns the backend's HTTP handler, instrumented with OpenTelemetry.
func New(d Deps) http.Handler {
	api := &httpapi.Server{DB: d.DB, Logger: d.Logger}
	return otelhttp.NewHandler(api.Handler(), "http.server")
}
