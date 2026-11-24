package hosting_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/tsantanadev/cesta/backend/internal/platform/hosting"
)

var okHandler = http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })

func status(h http.Handler, forwardedHost string) int {
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "https://cesta-backend-abc123-rj.a.run.app/health", nil)
	if forwardedHost != "" {
		req.Header.Set("X-Forwarded-Host", forwardedHost)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec.Code
}

func TestOnlyViaServesRequestsForwardedForThePublicHost(t *testing.T) {
	h := hosting.OnlyVia("cesta-dev.tsantana.dev", okHandler)

	if got := status(h, "cesta-dev.tsantana.dev"); got != http.StatusOK {
		t.Errorf("status = %d, want 200", got)
	}
}

func TestOnlyViaRejectsDirectRequestsToTheRunAppURL(t *testing.T) {
	h := hosting.OnlyVia("cesta-dev.tsantana.dev", okHandler)

	if got := status(h, ""); got != http.StatusNotFound {
		t.Errorf("status = %d, want 404", got)
	}
}

func TestOnlyViaRejectsRequestsForwardedForAnotherHost(t *testing.T) {
	h := hosting.OnlyVia("cesta-dev.tsantana.dev", okHandler)

	for _, host := range []string{"cesta-dev.web.app", "evil.example", "cesta-dev.tsantana.dev.evil.example"} {
		if got := status(h, host); got != http.StatusNotFound {
			t.Errorf("X-Forwarded-Host %q: status = %d, want 404", host, got)
		}
	}
}

func TestOnlyViaUsesTheFirstForwardedHostWhenThereAreSeveral(t *testing.T) {
	h := hosting.OnlyVia("cesta-dev.tsantana.dev", okHandler)

	if got := status(h, "CESTA-dev.tsantana.dev, proxy.internal"); got != http.StatusOK {
		t.Errorf("status = %d, want 200", got)
	}
}

func TestOnlyViaWithoutAPublicHostServesEverything(t *testing.T) {
	h := hosting.OnlyVia("", okHandler)

	if got := status(h, ""); got != http.StatusOK {
		t.Errorf("status = %d, want 200 (local dev and tests set no public host)", got)
	}
}
