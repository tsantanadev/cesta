package firebase_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"math/big"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/platform/auth/firebase"
	"github.com/tsantanadev/cesta/backend/internal/testkit/fakes"
)

const project = "cesta-dev"

var now = time.Date(2026, time.March, 2, 9, 0, 0, 0, time.UTC)

// keyServer stands in for Google's securetoken JWKS endpoint.
type keyServer struct {
	srv     *httptest.Server
	keys    map[string]*rsa.PrivateKey
	fetches atomic.Int32
	down    atomic.Bool
}

func newKeyServer(t *testing.T, kids ...string) *keyServer {
	t.Helper()
	ks := &keyServer{keys: map[string]*rsa.PrivateKey{}}
	for _, kid := range kids {
		ks.add(t, kid)
	}
	ks.srv = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		ks.fetches.Add(1)
		if ks.down.Load() {
			http.Error(w, "unavailable", http.StatusServiceUnavailable)
			return
		}
		var set struct {
			Keys []map[string]string `json:"keys"`
		}
		for kid, k := range ks.keys {
			set.Keys = append(set.Keys, map[string]string{
				"kty": "RSA", "alg": "RS256", "use": "sig", "kid": kid,
				"n": base64.RawURLEncoding.EncodeToString(k.N.Bytes()),
				"e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(k.E)).Bytes()),
			})
		}
		w.Header().Set("Cache-Control", "public, max-age=3600, must-revalidate")
		_ = json.NewEncoder(w).Encode(set)
	}))
	t.Cleanup(ks.srv.Close)
	return ks
}

func (ks *keyServer) add(t *testing.T, kid string) {
	t.Helper()
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	ks.keys[kid] = k
}

// claims are a valid Firebase ID token for Ana at now, before overrides.
func claims(overrides map[string]any) jwt.MapClaims {
	c := jwt.MapClaims{
		"iss":       "https://securetoken.google.com/" + project,
		"aud":       project,
		"sub":       "uid-ana",
		"user_id":   "uid-ana",
		"email":     "ana@example.com",
		"name":      "Ana Souza",
		"iat":       now.Add(-time.Minute).Unix(),
		"auth_time": now.Add(-time.Minute).Unix(),
		"exp":       now.Add(59 * time.Minute).Unix(),
	}
	for k, v := range overrides {
		if v == nil {
			delete(c, k)
		} else {
			c[k] = v
		}
	}
	return c
}

func (ks *keyServer) sign(t *testing.T, kid string, c jwt.MapClaims) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodRS256, c)
	tok.Header["kid"] = kid
	s, err := tok.SignedString(ks.keys[kid])
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func newVerifier(ks *keyServer, clock *fakes.Clock) *firebase.Verifier {
	return firebase.NewVerifier(project, firebase.WithKeysURL(ks.srv.URL), firebase.WithClock(clock))
}

func TestAValidTokenVerifiesAsItsIdentity(t *testing.T) {
	ks := newKeyServer(t, "k1")
	v := newVerifier(ks, fakes.NewClock(now))

	id, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil)))

	if err != nil {
		t.Fatalf("Verify: %v", err)
	}
	want := auth.Identity{Subject: "uid-ana", Email: "ana@example.com", Name: "Ana Souza"}
	if id != want {
		t.Fatalf("identity = %+v, want %+v", id, want)
	}
}

func TestAnEmailSignUpHasNoName(t *testing.T) {
	ks := newKeyServer(t, "k1")
	v := newVerifier(ks, fakes.NewClock(now))

	id, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(map[string]any{"name": nil})))

	if err != nil || id.Name != "" {
		t.Fatalf("Verify = %+v, %v; want no name and no error", id, err)
	}
}

func TestTokensThatMustNotVerify(t *testing.T) {
	ks := newKeyServer(t, "k1", "k2")
	other := newKeyServer(t, "k1") // same kid, different key: a forged signature
	tooLong := make([]byte, 129)
	for i := range tooLong {
		tooLong[i] = 'a'
	}

	cases := map[string]string{
		"expired":                         ks.sign(t, "k1", claims(map[string]any{"exp": now.Add(-time.Minute).Unix()})),
		"no expiry":                       ks.sign(t, "k1", claims(map[string]any{"exp": nil})),
		"issued in the future":            ks.sign(t, "k1", claims(map[string]any{"iat": now.Add(5 * time.Minute).Unix()})),
		"signed in in the future":         ks.sign(t, "k1", claims(map[string]any{"auth_time": now.Add(5 * time.Minute).Unix()})),
		"no auth_time":                    ks.sign(t, "k1", claims(map[string]any{"auth_time": nil})),
		"other project audience":          ks.sign(t, "k1", claims(map[string]any{"aud": "someone-else"})),
		"other project issuer":            ks.sign(t, "k1", claims(map[string]any{"iss": "https://securetoken.google.com/someone-else"})),
		"no subject":                      ks.sign(t, "k1", claims(map[string]any{"sub": ""})),
		"subject over 128 chars":          ks.sign(t, "k1", claims(map[string]any{"sub": string(tooLong)})),
		"forged signature":                other.sign(t, "k1", claims(nil)),
		"unknown key id":                  signWithUnknownKid(t, ks),
		"no key id":                       signWithoutKid(t, ks),
		"alg none":                        unsignedToken(t),
		"HS256 with public key as secret": hmacToken(t),
		"garbage":                         "not.a.jwt",
		"empty":                           "",
	}
	v := newVerifier(ks, fakes.NewClock(now))
	for name, token := range cases {
		t.Run(name, func(t *testing.T) {
			_, err := v.Verify(context.Background(), token)

			if !errors.Is(err, auth.ErrInvalidToken) {
				t.Fatalf("Verify error = %v, want auth.ErrInvalidToken", err)
			}
		})
	}
}

func TestKeysAreCachedBetweenVerifications(t *testing.T) {
	ks := newKeyServer(t, "k1")
	v := newVerifier(ks, fakes.NewClock(now))

	for range 5 {
		if _, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil))); err != nil {
			t.Fatalf("Verify: %v", err)
		}
	}

	if got := ks.fetches.Load(); got != 1 {
		t.Fatalf("key fetches = %d, want 1", got)
	}
}

func TestKeysAreRefetchedOnceTheCacheExpires(t *testing.T) {
	ks := newKeyServer(t, "k1")
	clock := fakes.NewClock(now)
	v := newVerifier(ks, clock)
	if _, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil))); err != nil {
		t.Fatalf("Verify: %v", err)
	}

	clock.Advance(time.Hour + time.Second)
	later := claims(map[string]any{"exp": clock.Now().Add(time.Hour).Unix()})
	if _, err := v.Verify(context.Background(), ks.sign(t, "k1", later)); err != nil {
		t.Fatalf("Verify after cache expiry: %v", err)
	}

	if got := ks.fetches.Load(); got != 2 {
		t.Fatalf("key fetches = %d, want 2", got)
	}
}

func TestATokenSignedWithANewlyRotatedKeyVerifies(t *testing.T) {
	ks := newKeyServer(t, "k1")
	clock := fakes.NewClock(now)
	v := newVerifier(ks, clock)
	if _, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil))); err != nil {
		t.Fatalf("Verify: %v", err)
	}

	ks.add(t, "k2") // Google publishes a new key before the cache expires
	clock.Advance(2 * time.Minute)
	later := claims(map[string]any{"exp": clock.Now().Add(time.Hour).Unix()})
	_, err := v.Verify(context.Background(), ks.sign(t, "k2", later))

	if err != nil {
		t.Fatalf("Verify with rotated key: %v", err)
	}
}

func TestUnknownKeyIDsDoNotHammerTheKeyEndpoint(t *testing.T) {
	ks := newKeyServer(t, "k1")
	v := newVerifier(ks, fakes.NewClock(now))
	if _, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil))); err != nil {
		t.Fatalf("Verify: %v", err)
	}

	for range 10 {
		_, _ = v.Verify(context.Background(), signWithUnknownKid(t, ks))
	}

	if got := ks.fetches.Load(); got > 2 {
		t.Fatalf("key fetches = %d, want at most 2", got)
	}
}

func TestAnUnreachableKeyEndpointIsNotAnInvalidToken(t *testing.T) {
	ks := newKeyServer(t, "k1")
	ks.down.Store(true)
	v := newVerifier(ks, fakes.NewClock(now))

	_, err := v.Verify(context.Background(), ks.sign(t, "k1", claims(nil)))

	if err == nil || errors.Is(err, auth.ErrInvalidToken) {
		t.Fatalf("Verify error = %v, want a non-ErrInvalidToken error", err)
	}
}

func signWithUnknownKid(t *testing.T, ks *keyServer) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodRS256, claims(nil))
	tok.Header["kid"] = "never-published"
	s, err := tok.SignedString(ks.keys["k1"])
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func signWithoutKid(t *testing.T, ks *keyServer) string {
	t.Helper()
	s, err := jwt.NewWithClaims(jwt.SigningMethodRS256, claims(nil)).SignedString(ks.keys["k1"])
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func unsignedToken(t *testing.T) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodNone, claims(nil))
	tok.Header["kid"] = "k1"
	s, err := tok.SignedString(jwt.UnsafeAllowNoneSignatureType)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func hmacToken(t *testing.T) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims(nil))
	tok.Header["kid"] = "k1"
	s, err := tok.SignedString([]byte("public-key-bytes"))
	if err != nil {
		t.Fatal(err)
	}
	return s
}
