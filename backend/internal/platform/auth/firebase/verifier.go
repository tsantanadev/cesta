// Package firebase verifies Firebase ID tokens (ADR-0003) without the Admin SDK.
//
// A token verifies when it is an RS256 JWT signed by one of Google's published
// securetoken keys and its claims match Firebase's rules: issuer
// https://securetoken.google.com/<project>, audience <project>, not expired,
// issued and signed in no later than now, and a subject of 1 to 128 characters.
// See https://firebase.google.com/docs/auth/admin/verify-id-tokens.
package firebase

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/clock"
)

// DefaultKeysURL publishes the keys that sign Firebase ID tokens, as a JWK set.
const DefaultKeysURL = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"

const (
	// leeway absorbs clock skew between Google and us.
	leeway = 5 * time.Second
	// refetchCooldown is the shortest gap between key fetches triggered by an
	// unknown key ID, so forged kids can't make us hammer Google.
	refetchCooldown = time.Minute
	// defaultKeysMaxAge applies when the key response has no usable max-age.
	defaultKeysMaxAge = time.Hour
	fetchTimeout      = 5 * time.Second
	maxKeysBytes      = 1 << 20
)

var _ auth.TokenVerifier = (*Verifier)(nil)

// Verifier verifies Firebase ID tokens for one Firebase project.
type Verifier struct {
	projectID string
	keysURL   string
	client    *http.Client
	clock     clock.Clock

	mu        sync.Mutex
	keys      map[string]*rsa.PublicKey
	expires   time.Time
	lastFetch time.Time
}

// Option configures a Verifier.
type Option func(*Verifier)

// WithKeysURL fetches signing keys from url instead of DefaultKeysURL.
func WithKeysURL(url string) Option { return func(v *Verifier) { v.keysURL = url } }

// WithClock uses c as the current time.
func WithClock(c clock.Clock) Option { return func(v *Verifier) { v.clock = c } }

// NewVerifier returns a Verifier for tokens issued to projectID.
func NewVerifier(projectID string, opts ...Option) *Verifier {
	v := &Verifier{
		projectID: projectID,
		keysURL:   DefaultKeysURL,
		client:    &http.Client{Timeout: fetchTimeout},
		clock:     clock.System{},
	}
	for _, opt := range opts {
		opt(v)
	}
	return v
}

type idTokenClaims struct {
	jwt.RegisteredClaims
	AuthTime *jwt.NumericDate `json:"auth_time"`
	Email    string           `json:"email"`
	Name     string           `json:"name"`
}

// keysUnavailableError means the signing keys couldn't be fetched: the token
// may be fine, so it is not an auth.ErrInvalidToken.
type keysUnavailableError struct{ err error }

func (e keysUnavailableError) Error() string {
	return "firebase: signing keys unavailable: " + e.err.Error()
}
func (e keysUnavailableError) Unwrap() error { return e.err }

// Verify returns the identity a valid token was issued to. It returns an error
// wrapping auth.ErrInvalidToken for any token that does not verify, and a
// different error if the signing keys can't be fetched.
func (v *Verifier) Verify(ctx context.Context, token string) (auth.Identity, error) {
	c := &idTokenClaims{}
	_, err := jwt.ParseWithClaims(token, c,
		func(t *jwt.Token) (any, error) {
			kid, _ := t.Header["kid"].(string)
			if kid == "" {
				return nil, errors.New("no key id")
			}
			return v.key(ctx, kid)
		},
		jwt.WithValidMethods([]string{jwt.SigningMethodRS256.Alg()}),
		jwt.WithIssuer("https://securetoken.google.com/"+v.projectID),
		jwt.WithAudience(v.projectID),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
		jwt.WithLeeway(leeway),
		jwt.WithTimeFunc(v.clock.Now),
	)
	if unavailable := (keysUnavailableError{}); errors.As(err, &unavailable) {
		return auth.Identity{}, unavailable
	}
	if err != nil {
		return auth.Identity{}, fmt.Errorf("%w: %w", auth.ErrInvalidToken, err)
	}
	if c.AuthTime == nil || c.AuthTime.After(v.clock.Now().Add(leeway)) {
		return auth.Identity{}, fmt.Errorf("%w: auth_time missing or in the future", auth.ErrInvalidToken)
	}
	if c.Subject == "" || len(c.Subject) > 128 {
		return auth.Identity{}, fmt.Errorf("%w: subject must be 1 to 128 characters", auth.ErrInvalidToken)
	}
	return auth.Identity{Subject: c.Subject, Email: c.Email, Name: c.Name}, nil
}

// key returns the public key for kid, fetching keys when the cache has expired
// or (at most once per refetchCooldown) when kid is unknown, since Google
// rotates keys. If a fetch fails, still-cached keys keep working.
func (v *Verifier) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	now := v.clock.Now()

	k, known := v.keys[kid]
	fresh := v.keys != nil && now.Before(v.expires)
	if known && fresh {
		return k, nil
	}
	if fresh && now.Sub(v.lastFetch) < refetchCooldown {
		return nil, fmt.Errorf("unknown key id %q", kid)
	}

	v.lastFetch = now
	keys, maxAge, err := v.fetch(ctx)
	if err != nil {
		if known {
			return k, nil
		}
		return nil, keysUnavailableError{err}
	}
	v.keys, v.expires = keys, now.Add(maxAge)
	if k, ok := keys[kid]; ok {
		return k, nil
	}
	return nil, fmt.Errorf("unknown key id %q", kid)
}

func (v *Verifier) fetch(ctx context.Context) (map[string]*rsa.PublicKey, time.Duration, error) {
	ctx, cancel := context.WithTimeout(ctx, fetchTimeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, v.keysURL, http.NoBody)
	if err != nil {
		return nil, 0, err
	}
	res, err := v.client.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer func() { _ = res.Body.Close() }()
	if res.StatusCode != http.StatusOK {
		return nil, 0, fmt.Errorf("key endpoint answered %s", res.Status)
	}
	var set struct {
		Keys []struct {
			Kty string `json:"kty"`
			Kid string `json:"kid"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(nil, res.Body, maxKeysBytes)).Decode(&set); err != nil {
		return nil, 0, fmt.Errorf("decode keys: %w", err)
	}
	keys := map[string]*rsa.PublicKey{}
	for _, k := range set.Keys {
		if k.Kty != "RSA" || k.Kid == "" {
			continue
		}
		n, errN := base64.RawURLEncoding.DecodeString(k.N)
		e, errE := base64.RawURLEncoding.DecodeString(k.E)
		if errN != nil || errE != nil || len(e) == 0 || len(e) > 4 {
			continue
		}
		keys[k.Kid] = &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: int(new(big.Int).SetBytes(e).Int64())}
	}
	if len(keys) == 0 {
		return nil, 0, errors.New("key endpoint published no usable RSA keys")
	}
	return keys, maxAge(res.Header.Get("Cache-Control")), nil
}

// maxAge reads max-age from a Cache-Control header.
func maxAge(cacheControl string) time.Duration {
	for d := range strings.SplitSeq(cacheControl, ",") {
		if v, ok := strings.CutPrefix(strings.TrimSpace(d), "max-age="); ok {
			if s, err := strconv.Atoi(v); err == nil && s > 0 {
				return time.Duration(s) * time.Second
			}
		}
	}
	return defaultKeysMaxAge
}
