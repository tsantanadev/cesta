package httpapi

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/lists"
	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
	cestasync "github.com/tsantanadev/cesta/backend/internal/sync"
)

// Pinger reports whether the database is reachable.
type Pinger interface {
	Ping(ctx context.Context) error
}

// healthPingTimeout bounds how long /health waits on the database.
const healthPingTimeout = 2 * time.Second

// Server implements StrictServerInterface. Each operation delegates to the module that owns it.
type Server struct {
	DB       Pinger
	Logger   *slog.Logger
	Identity *identity.Service
	Lists    *lists.Service
	Sync     *cestasync.Service
	PerIP    *ratelimit.Limiter
	// TrustedProxyHops is how many proxies in front of the backend append to
	// X-Forwarded-For (see clientIP).
	TrustedProxyHops int
}

var _ StrictServerInterface = (*Server)(nil)

// GetHealth reports liveness and database readiness.
func (s *Server) GetHealth(ctx context.Context, _ GetHealthRequestObject) (GetHealthResponseObject, error) {
	ctx, cancel := context.WithTimeout(ctx, healthPingTimeout)
	defer cancel()
	if err := s.DB.Ping(ctx); err != nil {
		s.Logger.WarnContext(ctx, "health: database unreachable", slog.String("error", err.Error()))
		return GetHealth503JSONResponse{Status: Degraded, Database: Down}, nil
	}
	return GetHealth200JSONResponse{Status: Ok, Database: Up}, nil
}

// Handler returns the HTTP handler for every operation in the contract, behind
// the per-IP rate limit, the body size cap and authentication.
func (s *Server) Handler() http.Handler {
	strict := NewStrictHandlerWithOptions(s, nil, StrictHTTPServerOptions{
		RequestErrorHandlerFunc:  s.badRequest,
		ResponseErrorHandlerFunc: s.internalError,
	})
	routes := HandlerWithOptions(strict, StdHTTPServerOptions{
		Middlewares:      []MiddlewareFunc{s.authenticate(publicOperations())},
		ErrorHandlerFunc: s.badRequest,
	})
	return s.limitIP(capBody(routes))
}

func (s *Server) badRequest(w http.ResponseWriter, _ *http.Request, err error) {
	if maxErr := (*http.MaxBytesError)(nil); errors.As(err, &maxErr) {
		writeError(w, http.StatusRequestEntityTooLarge, ApiErrorCodeInvalidRequest, "request body is too large")
		return
	}
	writeError(w, http.StatusBadRequest, ApiErrorCodeInvalidRequest, "the request is malformed")
}

func (s *Server) internalError(w http.ResponseWriter, r *http.Request, err error) {
	s.Logger.ErrorContext(r.Context(), "request failed", slog.String("error", err.Error()))
	writeError(w, http.StatusInternalServerError, ApiErrorCodeInternal, "something went wrong")
}
