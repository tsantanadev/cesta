// Package auth defines how the backend verifies who is calling it.
package auth

import (
	"context"
	"errors"
)

// ErrInvalidToken is returned when a token is missing, malformed, expired or not trusted.
var ErrInvalidToken = errors.New("invalid token")

// Identity is the verified caller as seen by the identity provider (Firebase).
// Only the identity module maps it to an internal User ID; other modules never see it.
type Identity struct {
	// Subject is the provider's stable user identifier (the Firebase UID).
	Subject string
	Email   string
	// Name is the name the provider knows the person by (e.g. from their Google
	// account). It is empty for email + password sign-ups.
	Name string
}

// TokenVerifier turns a bearer token (a Firebase ID token) into a verified Identity.
type TokenVerifier interface {
	Verify(ctx context.Context, token string) (Identity, error)
}
