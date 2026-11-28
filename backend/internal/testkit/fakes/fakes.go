// Package fakes holds the only test doubles Seam 1 uses: TokenVerifier,
// EmailSender and Clock. Everything else in Seam 1 tests is real.
package fakes

import (
	"context"
	"sync"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/email"
)

var (
	_ auth.TokenVerifier = (*TokenVerifier)(nil)
	_ email.Sender       = (*EmailSender)(nil)
)

// Clock is a controllable clock. It starts at a fixed instant and only moves when told.
type Clock struct {
	mu  sync.Mutex
	now time.Time
}

// NewClock returns a Clock frozen at start.
func NewClock(start time.Time) *Clock { return &Clock{now: start.UTC()} }

// Now returns the fake current time.
func (c *Clock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

// Advance moves the clock forward by d.
func (c *Clock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}

// TokenVerifier accepts tokens registered with SignIn, so tests act as named Users.
type TokenVerifier struct {
	mu     sync.Mutex
	tokens map[string]auth.Identity
}

// NewTokenVerifier returns a TokenVerifier with no signed-in users.
func NewTokenVerifier() *TokenVerifier {
	return &TokenVerifier{tokens: map[string]auth.Identity{}}
}

// SignIn registers an identity and returns the bearer token that verifies as it.
// The token is "token-" + subject, so it is stable and readable in failures.
func (v *TokenVerifier) SignIn(id auth.Identity) string {
	v.mu.Lock()
	defer v.mu.Unlock()
	token := "token-" + id.Subject
	v.tokens[token] = id
	return token
}

// Verify returns the identity registered for token, or auth.ErrInvalidToken.
func (v *TokenVerifier) Verify(_ context.Context, token string) (auth.Identity, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	id, ok := v.tokens[token]
	if !ok {
		return auth.Identity{}, auth.ErrInvalidToken
	}
	return id, nil
}

// EmailSender captures every message instead of sending it.
type EmailSender struct {
	mu   sync.Mutex
	sent []email.Message
	fail error
}

// Send records msg, or returns the error set with FailWith without recording it.
func (s *EmailSender) Send(_ context.Context, msg email.Message) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.fail != nil {
		return s.fail
	}
	s.sent = append(s.sent, msg)
	return nil
}

// FailWith makes every later Send return err, as if the provider rejected
// it; nil makes Send succeed again.
func (s *EmailSender) FailWith(err error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.fail = err
}

// SentTo returns the messages sent to the given address, oldest first.
func (s *EmailSender) SentTo(address string) []email.Message {
	s.mu.Lock()
	defer s.mu.Unlock()
	var out []email.Message
	for _, m := range s.sent {
		if m.To == address {
			out = append(out, m)
		}
	}
	return out
}
