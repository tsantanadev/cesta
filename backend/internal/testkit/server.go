// Package testkit is the Seam 1 harness: black-box HTTP tests against the real
// backend and a real, migrated Postgres (testcontainers). The only fakes allowed
// are TokenVerifier, EmailSender and Clock (package fakes); they are exposed on
// Server once the slices that use them are wired into app.Deps.
//
// Every response is checked against api/openapi.yaml, so a handler that drifts
// from the contract fails the test that exercised it.
package testkit

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers"
	"github.com/getkin/kin-openapi/routers/legacy"

	"github.com/tsantanadev/cesta/backend/internal/app"
	"github.com/tsantanadev/cesta/backend/internal/httpapi"
	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
)

// Server is a running backend under test.
type Server struct {
	URL string

	router routers.Router
	dbName string
}

// NewServer starts the backend against a fresh migrated database. It is torn down when t ends.
func NewServer(t testing.TB) *Server {
	t.Helper()
	pool, dbName := newDatabase(t)

	s := &Server{
		router: contractRouter(t),
		dbName: dbName,
	}
	handler := app.New(app.Deps{
		DB:     pool,
		Logger: slog.New(telemetry.LogHandler(slog.NewTextHandler(testWriter{t}, nil))),
	})
	hs := httptest.NewServer(handler)
	t.Cleanup(hs.Close)
	s.URL = hs.URL
	return s
}

// Get sends GET path anonymously.
func (s *Server) Get(t testing.TB, path string) *Response {
	t.Helper()
	return s.do(t, http.MethodGet, path, nil)
}

func (s *Server) do(t testing.TB, method, path string, body []byte) *Response {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, method, s.URL+path, bytes.NewReader(body))
	if err != nil {
		t.Fatalf("testkit: build request: %v", err)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("testkit: %s %s: %v", method, path, err)
	}
	defer func() { _ = res.Body.Close() }()
	got, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("testkit: read body: %v", err)
	}
	s.checkContract(t, req, res, got)
	return &Response{Status: res.StatusCode, Header: res.Header, Body: got}
}

// checkContract fails t if the response does not match api/openapi.yaml.
func (s *Server) checkContract(t testing.TB, req *http.Request, res *http.Response, body []byte) {
	t.Helper()
	route, params, err := s.router.FindRoute(req)
	if err != nil {
		t.Fatalf("testkit: %s %s is not in the API contract: %v", req.Method, req.URL.Path, err)
	}
	in := &openapi3filter.ResponseValidationInput{
		RequestValidationInput: &openapi3filter.RequestValidationInput{
			Request: req, PathParams: params, Route: route,
			Options: &openapi3filter.Options{AuthenticationFunc: openapi3filter.NoopAuthenticationFunc},
		},
		Status: res.StatusCode,
		Header: res.Header,
		Body:   io.NopCloser(bytes.NewReader(body)),
	}
	if err := openapi3filter.ValidateResponse(req.Context(), in); err != nil {
		t.Fatalf("testkit: %s %s response breaks the API contract: %v\nbody: %s", req.Method, req.URL.Path, err, body)
	}
}

func contractRouter(t testing.TB) routers.Router {
	t.Helper()
	spec, err := httpapi.GetSpec()
	if err != nil {
		t.Fatalf("testkit: load API contract: %v", err)
	}
	spec.Servers = openapi3.Servers{} // match any host, i.e. the httptest server
	router, err := legacy.NewRouter(spec)
	if err != nil {
		t.Fatalf("testkit: build contract router: %v", err)
	}
	return router
}

// Response is a fully read HTTP response.
type Response struct {
	Status int
	Header http.Header
	Body   []byte
}

// RequireStatus fails t unless the response has the given status code.
func (r *Response) RequireStatus(t testing.TB, want int) {
	t.Helper()
	if r.Status != want {
		t.Fatalf("status = %d, want %d\nbody: %s", r.Status, want, r.Body)
	}
}

// RequireJSON fails t unless the body is JSON equal to want (key order and spacing ignored).
func (r *Response) RequireJSON(t testing.TB, want string) {
	t.Helper()
	var got, exp any
	if err := json.Unmarshal(r.Body, &got); err != nil {
		t.Fatalf("body is not JSON: %v\nbody: %s", err, r.Body)
	}
	if err := json.Unmarshal([]byte(want), &exp); err != nil {
		t.Fatalf("testkit: want is not JSON: %v", err)
	}
	gotN, err := json.Marshal(got)
	if err != nil {
		t.Fatalf("testkit: normalise body: %v", err)
	}
	expN, err := json.Marshal(exp)
	if err != nil {
		t.Fatalf("testkit: normalise want: %v", err)
	}
	if !bytes.Equal(gotN, expN) {
		t.Fatalf("body = %s, want %s", gotN, expN)
	}
}

// testWriter sends server logs to the test log, so they show only on failure or -v.
type testWriter struct{ t testing.TB }

func (w testWriter) Write(p []byte) (int, error) {
	w.t.Log(string(bytes.TrimRight(p, "\n")))
	return len(p), nil
}
