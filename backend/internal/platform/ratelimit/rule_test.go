package ratelimit_test

import (
	"testing"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
)

func TestParseRule(t *testing.T) {
	got, err := ratelimit.ParseRule("120/250ms")
	if err != nil {
		t.Fatal(err)
	}
	if want := (ratelimit.Rule{Burst: 120, Every: 250 * time.Millisecond}); got != want {
		t.Fatalf("ParseRule = %+v, want %+v", got, want)
	}
}

func TestParseRuleRejectsMalformed(t *testing.T) {
	for _, s := range []string{"", "120", "/1s", "x/1s", "0/1s", "-1/1s", "10/", "10/soon", "10/0s", "10/-1s"} {
		if _, err := ratelimit.ParseRule(s); err == nil {
			t.Errorf("ParseRule(%q) succeeded, want an error", s)
		}
	}
}
