package api_test

import (
	"net/http"
	"testing"

	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

func TestHealthReportsOKWhenDatabaseIsUp(t *testing.T) {
	srv := testkit.NewServer(t)

	res := srv.Get(t, "/healthz")

	res.RequireStatus(t, http.StatusOK)
	res.RequireJSON(t, `{"status":"ok","database":"up"}`)
}

func TestHealthReportsDegradedWhenDatabaseIsUnreachable(t *testing.T) {
	srv := testkit.NewServer(t)
	srv.CutDatabase(t)

	res := srv.Get(t, "/healthz")

	res.RequireStatus(t, http.StatusServiceUnavailable)
	res.RequireJSON(t, `{"status":"degraded","database":"down"}`)
}
