// Package app wires the modular monolith into one HTTP handler.
//
// main builds Deps from real adapters; Seam 1 tests build them with a real
// Postgres and the fakes in package testkit/fakes.
package app

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
	"github.com/tsantanadev/cesta/backend/internal/platform/hosting"
	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
)

// Deps are the external dependencies of the backend.
type Deps struct {
	DB            *pgxpool.Pool
	Logger        *slog.Logger
	TokenVerifier auth.TokenVerifier
	// Clock defaults to the system clock.
	Clock clock.Clock
	// RateLimits default to DefaultRateLimits.
	RateLimits RateLimits
	// TrustedProxyHops is how many proxies in front of the backend append the
	// client address to X-Forwarded-For. 0 uses the connection's address.
	TrustedProxyHops int
	// PublicHost is the custom domain Firebase Hosting serves the API on. When set,
	// requests that didn't come through it get 404 (see package hosting).
	PublicHost string
}

// RateLimits are the per-client-IP and per-User request limits.
type RateLimits struct {
	PerIP   ratelimit.Rule
	PerUser ratelimit.Rule
}

// DefaultRateLimits allow short bursts (a sync after reconnecting) and a steady
// 240 requests a minute per IP address and 120 per User.
var DefaultRateLimits = RateLimits{
	PerIP:   ratelimit.Rule{Burst: 120, Every: 250 * time.Millisecond},
	PerUser: ratelimit.Rule{Burst: 60, Every: 500 * time.Millisecond},
}

// New returns the backend's HTTP handler, instrumented with OpenTelemetry.
// Requests rejected by the hosting check are not traced.
func New(d Deps) http.Handler {
	c := d.Clock
	if c == nil {
		c = clock.System{}
	}
	limits := d.RateLimits
	if limits == (RateLimits{}) {
		limits = DefaultRateLimits
	}
	api := &httpapi.Server{
		DB:               d.DB,
		Logger:           d.Logger,
		Verifier:         d.TokenVerifier,
		Identity:         identity.NewService(d.DB, c),
		PerIP:            ratelimit.New(limits.PerIP, c),
		PerUser:          ratelimit.New(limits.PerUser, c),
		TrustedProxyHops: d.TrustedProxyHops,
	}
	return hosting.OnlyVia(d.PublicHost, otelhttp.NewHandler(api.Handler(), "http.server"))
}
