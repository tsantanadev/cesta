// Package testkit is the Seam 1 harness: black-box HTTP tests against the real
// backend and a real, migrated Postgres (testcontainers). The only fakes allowed
// are TokenVerifier, EmailSender and Clock (package fakes). Tests act as named
// Users (Ana, Bruno) through Server.As and move time with Server.Clock.
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
	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/ratelimit"
	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
	"github.com/tsantanadev/cesta/backend/internal/testkit/fakes"
)

// Named Users for tests. Ana signed up with Google, so the provider knows her
// name; Bruno signed up with email + password, so it doesn't.
var (
	Ana   = auth.Identity{Subject: "firebase-uid-ana", Email: "ana@example.com", Name: "Ana Souza"}
	Bruno = auth.Identity{Subject: "firebase-uid-bruno", Email: "bruno.lima@example.com"}
)

// Server is a running backend under test.
type Server struct {
	URL string
	// Clock is the backend's clock; tests advance it to move time.
	Clock *fakes.Clock

	tokens *fakes.TokenVerifier
	router routers.Router
	dbName string
	deps   app.Deps
}

// Option configures a test server.
type Option func(*app.Deps)

// WithRateLimits sets the per-IP and per-User rate limits.
func WithRateLimits(perIP, perUser ratelimit.Rule) Option {
	return func(d *app.Deps) { d.RateLimits = app.RateLimits{PerIP: perIP, PerUser: perUser} }
}

// WithMaxListsPerUser sets how many live Lists a User can own.
func WithMaxListsPerUser(n int) Option {
	return func(d *app.Deps) { d.MaxListsPerUser = n }
}

// NewServer starts the backend against a fresh migrated database. It is torn down when t ends.
//
// The server trusts one proxy hop, so Client.FromIP can pose as different
// client IP addresses through X-Forwarded-For.
func NewServer(t testing.TB, opts ...Option) *Server {
	t.Helper()
	pool, dbName := newDatabase(t)

	s := &Server{
		Clock:  fakes.NewClock(time.Date(2026, time.March, 2, 9, 0, 0, 0, time.UTC)),
		tokens: fakes.NewTokenVerifier(),
		router: contractRouter(t),
		dbName: dbName,
	}
	deps := app.Deps{
		DB:               pool,
		Logger:           slog.New(telemetry.LogHandler(slog.NewTextHandler(testWriter{t}, nil))),
		TokenVerifier:    s.tokens,
		Clock:            s.Clock,
		TrustedProxyHops: 1,
	}
	for _, opt := range opts {
		opt(&deps)
	}
	s.deps = deps
	hs := httptest.NewServer(app.New(deps))
	t.Cleanup(hs.Close)
	s.URL = hs.URL
	return s
}

// RunPurge runs the scheduled purge of deleted Lists now, by the server's
// Clock, the same way `cesta purge` does in production. It returns how many
// Lists it removed.
func (s *Server) RunPurge(t testing.TB) int {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	n, err := app.Purge(ctx, s.deps)
	if err != nil {
		t.Fatalf("testkit: purge: %v", err)
	}
	return n
}

// Get sends GET path anonymously.
func (s *Server) Get(t testing.TB, path string) *Response {
	t.Helper()
	return s.Anonymous().Get(t, path)
}

// Anonymous returns a client that sends no token.
func (s *Server) Anonymous() *Client { return &Client{srv: s} }

// As returns a client signed in as id: its token verifies as id.
func (s *Server) As(id auth.Identity) *Client {
	return &Client{srv: s, token: s.tokens.SignIn(id)}
}

// WithToken returns a client that sends token as is (it need not verify).
// An empty token sends an empty bearer credential.
func (s *Server) WithToken(token string) *Client {
	return &Client{srv: s, token: token, sendEmpty: true}
}

// Client sends requests to a Server, optionally with a bearer token and a client IP.
type Client struct {
	srv       *Server
	token     string
	sendEmpty bool
	ip        string
}

// FromIP returns a copy of the client whose requests come from ip.
func (c *Client) FromIP(ip string) *Client {
	cp := *c
	cp.ip = ip
	return &cp
}

// Get sends GET path.
func (c *Client) Get(t testing.TB, path string) *Response {
	t.Helper()
	return c.srv.do(t, c, http.MethodGet, path, nil)
}

// Patch sends PATCH path with a JSON body.
func (c *Client) Patch(t testing.TB, path, body string) *Response {
	t.Helper()
	return c.srv.do(t, c, http.MethodPatch, path, []byte(body))
}

// Post sends POST path with a JSON body, or with no body when body is "".
func (c *Client) Post(t testing.TB, path, body string) *Response {
	t.Helper()
	var b []byte
	if body != "" {
		b = []byte(body)
	}
	return c.srv.do(t, c, http.MethodPost, path, b)
}

// Delete sends DELETE path.
func (c *Client) Delete(t testing.TB, path string) *Response {
	t.Helper()
	return c.srv.do(t, c, http.MethodDelete, path, nil)
}

func (s *Server) do(t testing.TB, c *Client, method, path string, body []byte) *Response {
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
	if c.token != "" || c.sendEmpty {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}
	if c.ip != "" {
		req.Header.Set("X-Forwarded-For", c.ip)
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

// RequireErrorCode fails t unless the body is an API Error with the given code.
func (r *Response) RequireErrorCode(t testing.TB, want string) {
	t.Helper()
	var e struct {
		Code string `json:"code"`
	}
	if err := json.Unmarshal(r.Body, &e); err != nil {
		t.Fatalf("body is not an API error: %v\nbody: %s", err, r.Body)
	}
	if e.Code != want {
		t.Fatalf("error code = %q, want %q\nbody: %s", e.Code, want, r.Body)
	}
}

// testWriter sends server logs to the test log, so they show only on failure or -v.
type testWriter struct{ t testing.TB }

func (w testWriter) Write(p []byte) (int, error) {
	w.t.Log(string(bytes.TrimRight(p, "\n")))
	return len(p), nil
}
