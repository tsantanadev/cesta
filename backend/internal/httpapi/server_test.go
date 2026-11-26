package httpapi_test

import (
	"context"
	"log/slog"
	"testing"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
)

type deadlineCapturePinger struct {
	deadline time.Time
	hasDL    bool
}

func (p *deadlineCapturePinger) Ping(ctx context.Context) error {
	p.deadline, p.hasDL = ctx.Deadline()
	return nil
}

func TestGetHealthAllowsTimeForColdDatabaseWake(t *testing.T) {
	pinger := &deadlineCapturePinger{}
	srv := &httpapi.Server{
		DB:     pinger,
		Logger: slog.New(slog.DiscardHandler),
	}

	start := time.Now()
	res, err := srv.GetHealth(context.Background(), httpapi.GetHealthRequestObject{})
	if err != nil {
		t.Fatalf("GetHealth: %v", err)
	}
	if _, ok := res.(httpapi.GetHealth200JSONResponse); !ok {
		t.Fatalf("response type = %T, want GetHealth200JSONResponse", res)
	}
	if !pinger.hasDL {
		t.Fatal("Ping context has no deadline, want bounded timeout")
	}
	if got := pinger.deadline.Sub(start); got < 5*time.Second {
		t.Errorf("health ping timeout = %s, want >= 5s for cold Neon wake", got)
	}
}
