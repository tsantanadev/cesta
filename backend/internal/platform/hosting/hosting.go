// Package hosting keeps the backend reachable only through Firebase Hosting.
//
// Cloud Run's default *.run.app URL can't be turned off, because Firebase Hosting
// rewrites go through it (ADR-0005). Firebase Hosting sets X-Forwarded-Host to the
// custom domain it served, so requests without that header came straight to run.app.
// The header can be forged; this stops scanners and casual bypass, not a determined
// client. Firebase App Check is the real gate.
package hosting

import (
	"net/http"
	"strings"
)

// OnlyVia serves only requests that Firebase Hosting forwarded for publicHost and
// answers every other request with 404. An empty publicHost turns the check off,
// for local dev and tests.
func OnlyVia(publicHost string, next http.Handler) http.Handler {
	if publicHost == "" {
		return next
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		host, _, _ := strings.Cut(r.Header.Get("X-Forwarded-Host"), ",")
		if !strings.EqualFold(strings.TrimSpace(host), publicHost) {
			http.NotFound(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}
