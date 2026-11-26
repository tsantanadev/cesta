package api_test

import (
	"net/http"
	"testing"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

func TestAUserOverTheirRateLimitIsRejectedUntilItRefills(t *testing.T) {
	srv := testkit.NewServer(t, testkit.WithRateLimits(
		ratelimit.Rule{Burst: 100, Every: time.Second},
		ratelimit.Rule{Burst: 3, Every: 10 * time.Second},
	))
	ana := srv.As(testkit.Ana)
	for range 3 {
		ana.Get(t, "/api/me").RequireStatus(t, http.StatusOK)
	}

	over := ana.Get(t, "/api/me")

	over.RequireStatus(t, http.StatusTooManyRequests)
	over.RequireErrorCode(t, "rate_limited")
	if got := over.Header.Get("Retry-After"); got != "10" {
		t.Fatalf("Retry-After = %q, want %q", got, "10")
	}

	srv.Clock.Advance(10 * time.Second)
	ana.Get(t, "/api/me").RequireStatus(t, http.StatusOK)
}

func TestOneUserOverTheLimitDoesNotAffectAnother(t *testing.T) {
	srv := testkit.NewServer(t, testkit.WithRateLimits(
		ratelimit.Rule{Burst: 100, Every: time.Second},
		ratelimit.Rule{Burst: 2, Every: time.Minute},
	))
	ana := srv.As(testkit.Ana)
	for range 3 {
		ana.Get(t, "/api/me")
	}

	srv.As(testkit.Bruno).Get(t, "/api/me").RequireStatus(t, http.StatusOK)
}

func TestAUserLimitFollowsTheUserAcrossIPAddresses(t *testing.T) {
	srv := testkit.NewServer(t, testkit.WithRateLimits(
		ratelimit.Rule{Burst: 100, Every: time.Second},
		ratelimit.Rule{Burst: 2, Every: time.Minute},
	))
	srv.As(testkit.Ana).FromIP("203.0.113.1").Get(t, "/api/me")
	srv.As(testkit.Ana).FromIP("203.0.113.2").Get(t, "/api/me")

	res := srv.As(testkit.Ana).FromIP("203.0.113.3").Get(t, "/api/me")

	res.RequireStatus(t, http.StatusTooManyRequests)
}

func TestAnIPAddressOverItsRateLimitIsRejectedEvenWithoutAToken(t *testing.T) {
	srv := testkit.NewServer(t, testkit.WithRateLimits(
		ratelimit.Rule{Burst: 2, Every: time.Minute},
		ratelimit.Rule{Burst: 100, Every: time.Second},
	))
	flood := srv.WithToken("forged-token").FromIP("198.51.100.7")
	flood.Get(t, "/api/me")
	flood.Get(t, "/api/me")

	over := flood.Get(t, "/api/me")

	over.RequireStatus(t, http.StatusTooManyRequests)
	over.RequireErrorCode(t, "rate_limited")
	if got := over.Header.Get("Retry-After"); got != "60" {
		t.Fatalf("Retry-After = %q, want %q", got, "60")
	}
	srv.Anonymous().FromIP("198.51.100.7").Get(t, "/health").RequireStatus(t, http.StatusTooManyRequests)
	srv.As(testkit.Ana).FromIP("198.51.100.8").Get(t, "/api/me").RequireStatus(t, http.StatusOK)
}
