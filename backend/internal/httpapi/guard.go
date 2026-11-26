package httpapi

import (
	"encoding/json"
	"errors"
	"log/slog"
	"math"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/identity"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
)

// maxBodyBytes caps request bodies, so oversized payloads are rejected before decoding.
const maxBodyBytes = 64 << 10

// limitIP rejects requests from a client IP address that is over its rate limit.
// It runs before routing and authentication, so floods never reach token
// verification or the database.
func (s *Server) limitIP(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ok, wait := s.PerIP.Allow(clientIP(r, s.TrustedProxyHops)); !ok {
			writeRateLimited(w, wait)
			return
		}
		r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)
		next.ServeHTTP(w, r)
	})
}

// authenticate verifies the bearer token on every operation the contract does
// not mark public, applies the per-User rate limit and puts the User in the
// request context. Operations it doesn't know are treated as protected.
func (s *Server) authenticate(public map[string]bool) MiddlewareFunc {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if public[r.Pattern] {
				next.ServeHTTP(w, r)
				return
			}
			ctx := r.Context()
			token, ok := bearerToken(r)
			if !ok {
				writeError(w, http.StatusUnauthorized, ApiErrorCodeUnauthenticated, "a bearer token is required")
				return
			}
			id, err := s.Verifier.Verify(ctx, token)
			if errors.Is(err, auth.ErrInvalidToken) {
				writeError(w, http.StatusUnauthorized, ApiErrorCodeUnauthenticated, "the bearer token is not valid")
				return
			}
			if err != nil {
				s.Logger.ErrorContext(ctx, "authenticate: verify token", slog.String("error", err.Error()))
				writeError(w, http.StatusInternalServerError, ApiErrorCodeInternal, "could not verify the token")
				return
			}
			// Keyed by the provider's subject, which maps 1:1 to a User, so a
			// User over the limit is rejected before any database work. This is
			// the one place outside identity that sees the subject (ADR-0003); it
			// never leaves this middleware.
			if ok, wait := s.PerUser.Allow(id.Subject); !ok {
				writeRateLimited(w, wait)
				return
			}
			u, err := s.Identity.Resolve(ctx, id)
			if err != nil {
				s.Logger.ErrorContext(ctx, "authenticate: resolve user", slog.String("error", err.Error()))
				writeError(w, http.StatusInternalServerError, ApiErrorCodeInternal, "could not load the User")
				return
			}
			next.ServeHTTP(w, r.WithContext(identity.WithUser(ctx, u)))
		})
	}
}

// publicOperations returns the mux patterns ("GET /health") of operations the
// contract marks as needing no authentication (security: []).
func publicOperations() map[string]bool {
	spec, err := GetSpec()
	if err != nil {
		panic("httpapi: embedded API contract does not load: " + err.Error())
	}
	public := map[string]bool{}
	for path, item := range spec.Paths.Map() {
		for method, op := range item.Operations() {
			sec := spec.Security
			if op.Security != nil {
				sec = *op.Security
			}
			open := len(sec) == 0
			for _, req := range sec {
				if len(req) == 0 {
					open = true
				}
			}
			if open {
				public[method+" "+path] = true
			}
		}
	}
	return public
}

func bearerToken(r *http.Request) (string, bool) {
	scheme, token, ok := strings.Cut(r.Header.Get("Authorization"), " ")
	token = strings.TrimSpace(token)
	if !ok || !strings.EqualFold(scheme, "Bearer") || token == "" {
		return "", false
	}
	return token, true
}

// clientIP returns the caller's IP address. Behind hops trusted proxies, each
// of which appends the address it received the request from to
// X-Forwarded-For, the client is the hops-th entry from the right; entries
// further left are client-supplied and can't be trusted. With no trusted
// proxies (or too few entries) it is the connection's remote address.
func clientIP(r *http.Request, hops int) string {
	if hops > 0 {
		var parts []string
		for _, v := range r.Header.Values("X-Forwarded-For") {
			for p := range strings.SplitSeq(v, ",") {
				parts = append(parts, strings.TrimSpace(p))
			}
		}
		if len(parts) >= hops {
			if ip := parts[len(parts)-hops]; ip != "" {
				return ip
			}
		}
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func writeRateLimited(w http.ResponseWriter, wait time.Duration) {
	w.Header().Set("Retry-After", strconv.Itoa(max(1, int(math.Ceil(wait.Seconds())))))
	writeError(w, http.StatusTooManyRequests, ApiErrorCodeRateLimited, "too many requests; retry later")
}

func writeError(w http.ResponseWriter, status int, code ApiErrorCode, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(ApiError{Code: code, Message: message})
}
