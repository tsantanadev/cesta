package httpapi

import (
	"context"
	"log/slog"
	"net/http"
	"time"
)

// Pinger reports whether the database is reachable.
type Pinger interface {
	Ping(ctx context.Context) error
}

// healthPingTimeout bounds how long /health waits on the database, leaving room
// for a cold Neon compute wake while still failing fast when Postgres is unreachable.
const healthPingTimeout = 5 * time.Second

// Server implements StrictServerInterface. Each operation delegates to the module that owns it.
type Server struct {
	DB     Pinger
	Logger *slog.Logger
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

// Handler returns the HTTP handler for every operation in the contract.
func (s *Server) Handler() http.Handler {
	return Handler(NewStrictHandler(s, nil))
}
