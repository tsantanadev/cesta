package api_test

import (
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"testing"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

type user struct {
	ID                   string `json:"id"`
	Email                string `json:"email"`
	DisplayName          string `json:"displayName"`
	DisplayNameConfirmed bool   `json:"displayNameConfirmed"`
}

func decodeUser(t *testing.T, res *testkit.Response) user {
	t.Helper()
	var u user
	if err := json.Unmarshal(res.Body, &u); err != nil {
		t.Fatalf("decode user: %v\nbody: %s", err, res.Body)
	}
	return u
}

func TestMeRejectsARequestWithoutAToken(t *testing.T) {
	srv := testkit.NewServer(t)

	res := srv.Get(t, "/api/me")

	res.RequireStatus(t, http.StatusUnauthorized)
	res.RequireErrorCode(t, "unauthenticated")
}

func TestMeRejectsATokenThatDoesNotVerify(t *testing.T) {
	srv := testkit.NewServer(t)

	res := srv.WithToken("forged-token").Get(t, "/api/me")

	res.RequireStatus(t, http.StatusUnauthorized)
	res.RequireErrorCode(t, "unauthenticated")
}

func TestFirstRequestCreatesTheUserWithTheNameFromTheIdentityProvider(t *testing.T) {
	srv := testkit.NewServer(t)

	res := srv.As(testkit.Ana).Get(t, "/api/me")

	res.RequireStatus(t, http.StatusOK)
	got := decodeUser(t, res)
	if got.ID == "" {
		t.Fatal("new User has no id")
	}
	if got.Email != "ana@example.com" || got.DisplayName != "Ana Souza" || got.DisplayNameConfirmed {
		t.Fatalf("new User = %+v, want email ana@example.com, display name Ana Souza, not confirmed", got)
	}
}

func TestANewUserWithoutANameGetsTheStartOfTheirEmailAsDisplayName(t *testing.T) {
	srv := testkit.NewServer(t)

	got := decodeUser(t, srv.As(testkit.Bruno).Get(t, "/api/me"))

	if got.DisplayName != "bruno.lima" {
		t.Fatalf("display name = %q, want %q", got.DisplayName, "bruno.lima")
	}
}

func TestLaterRequestsMapToTheSameUser(t *testing.T) {
	srv := testkit.NewServer(t)
	first := decodeUser(t, srv.As(testkit.Ana).Get(t, "/api/me"))

	again := decodeUser(t, srv.As(testkit.Ana).Get(t, "/api/me"))

	if again.ID != first.ID {
		t.Fatalf("second request got User %s, want the same User %s", again.ID, first.ID)
	}
}

func TestConcurrentFirstRequestsCreateOneUser(t *testing.T) {
	srv := testkit.NewServer(t)
	const n = 8
	ids := make([]string, n)
	var wg sync.WaitGroup
	for i := range n {
		wg.Go(func() {
			res := srv.As(testkit.Ana).Get(t, "/api/me")
			if res.Status == http.StatusOK {
				ids[i] = decodeUser(t, res).ID
			}
		})
	}
	wg.Wait()

	for i, id := range ids {
		if id == "" || id != ids[0] {
			t.Fatalf("request %d got User %q, want every request to get %q", i, id, ids[0])
		}
	}
}

func TestDifferentIdentitiesAreDifferentUsers(t *testing.T) {
	srv := testkit.NewServer(t)

	ana := decodeUser(t, srv.As(testkit.Ana).Get(t, "/api/me"))
	bruno := decodeUser(t, srv.As(testkit.Bruno).Get(t, "/api/me"))

	if ana.ID == bruno.ID {
		t.Fatalf("Ana and Bruno share User %s", ana.ID)
	}
}

func TestAChangedEmailAtTheIdentityProviderIsPickedUp(t *testing.T) {
	srv := testkit.NewServer(t)
	before := decodeUser(t, srv.As(testkit.Ana).Get(t, "/api/me"))
	moved := testkit.Ana
	moved.Email = "ana.souza@example.com"

	after := decodeUser(t, srv.As(moved).Get(t, "/api/me"))

	if after.ID != before.ID || after.Email != "ana.souza@example.com" {
		t.Fatalf("after email change = %+v, want User %s with email ana.souza@example.com", after, before.ID)
	}
}

func TestDisplayNameCanBeSetAndReadBack(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)

	set := ana.Patch(t, "/api/me", `{"displayName":"  Aninha  "}`)

	set.RequireStatus(t, http.StatusOK)
	got := decodeUser(t, ana.Get(t, "/api/me"))
	if got.DisplayName != "Aninha" || !got.DisplayNameConfirmed {
		t.Fatalf("after setting = %+v, want display name Aninha, confirmed", got)
	}
}

func TestConfirmingTheSuggestedDisplayNameMarksItConfirmed(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)

	got := decodeUser(t, ana.Patch(t, "/api/me", `{"displayName":"Ana Souza"}`))

	if got.DisplayName != "Ana Souza" || !got.DisplayNameConfirmed {
		t.Fatalf("after confirming = %+v, want Ana Souza, confirmed", got)
	}
}

func TestDisplayNameMustHaveVisibleCharactersAndFitFiftyCharacters(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)

	for name, body := range map[string]string{
		"empty":         `{"displayName":""}`,
		"only spaces":   `{"displayName":"   "}`,
		"control chars": `{"displayName":"Ana\u0000"}`,
		"51 characters": `{"displayName":"` + strings.Repeat("a", 51) + `"}`,
		"51 accented":   `{"displayName":"` + strings.Repeat("ã", 51) + `"}`,
		"missing field": `{}`,
	} {
		t.Run(name, func(t *testing.T) {
			res := ana.Patch(t, "/api/me", body)

			res.RequireStatus(t, http.StatusBadRequest)
			res.RequireErrorCode(t, "invalid_display_name")
		})
	}

	got := decodeUser(t, ana.Get(t, "/api/me"))
	if got.DisplayName != "Ana Souza" || got.DisplayNameConfirmed {
		t.Fatalf("after rejected updates = %+v, want the suggested name, unconfirmed", got)
	}
}

func TestFiftyAccentedCharactersAreAValidDisplayName(t *testing.T) {
	srv := testkit.NewServer(t)
	name := strings.Repeat("ã", 50)

	got := decodeUser(t, srv.As(testkit.Ana).Patch(t, "/api/me", `{"displayName":"`+name+`"}`))

	if got.DisplayName != name {
		t.Fatalf("display name = %q, want %q", got.DisplayName, name)
	}
}

func TestAMalformedBodyIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)

	for name, body := range map[string]string{
		"truncated":    `{"displayName":`,
		"not a string": `{"displayName":42}`,
	} {
		t.Run(name, func(t *testing.T) {
			res := srv.As(testkit.Ana).Patch(t, "/api/me", body)

			res.RequireStatus(t, http.StatusBadRequest)
			res.RequireErrorCode(t, "invalid_request")
		})
	}
}

func TestUpdatingDisplayNameNeedsAToken(t *testing.T) {
	srv := testkit.NewServer(t)

	res := srv.WithToken("").Patch(t, "/api/me", `{"displayName":"Ana"}`)

	res.RequireStatus(t, http.StatusUnauthorized)
}

// Compile-time check that the named test Users are identities.
var _ = []auth.Identity{testkit.Ana, testkit.Bruno}
