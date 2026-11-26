// Package app wires the modular monolith into one HTTP handler.
//
// main builds Deps from real adapters; Seam 1 tests build them with a real
// Postgres. External services (TokenVerifier, EmailSender, Clock) join Deps
// with the slices that first use them.
package app

import (
	"log/slog"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
	"go.opentelemetry.io/otel/trace"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
	"github.com/tsantanadev/cesta/backend/internal/platform/hosting"
)

// Deps are the external dependencies of the backend.
type Deps struct {
	DB     *pgxpool.Pool
	Logger *slog.Logger
	// PublicHost is the custom domain Firebase Hosting serves the API on. When set,
	// requests that didn't come through it get 404 (see package hosting).
	PublicHost string
}

// New returns the backend's HTTP handler, instrumented with OpenTelemetry.
// Requests rejected by the hosting check are not traced.
func New(d Deps) http.Handler {
	api := &httpapi.Server{DB: d.DB, Logger: d.Logger}
	return hosting.OnlyVia(d.PublicHost, instrumentHTTP(api.Handler()))
}

// instrumentHTTP wraps next with OpenTelemetry tracing and metrics. otelhttp's
// default formatter names spans "{method} {route}" from r.Pattern after ServeMux
// matches; tagMatchedRoute also records http.route on the span itself.
func instrumentHTTP(next http.Handler) http.Handler {
	return otelhttp.NewHandler(tagMatchedRoute(next), "")
}

func tagMatchedRoute(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		span := trace.SpanFromContext(r.Context())
		defer func() {
			if route := routeFromPattern(r.Pattern); route != "" {
				span.SetAttributes(semconv.HTTPRoute(route))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func routeFromPattern(pattern string) string {
	if idx := strings.IndexByte(pattern, '/'); idx >= 0 {
		return pattern[idx:]
	}
	return ""
}
