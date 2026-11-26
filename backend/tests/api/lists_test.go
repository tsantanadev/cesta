package api_test

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

type listSummary struct {
	ID                 string    `json:"id"`
	Name               string    `json:"name"`
	Role               string    `json:"role"`
	UncheckedItemCount int       `json:"uncheckedItemCount"`
	MemberCount        int       `json:"memberCount"`
	CreatedAt          time.Time `json:"createdAt"`
}

func decodeList(t *testing.T, res *testkit.Response) listSummary {
	t.Helper()
	var l listSummary
	if err := json.Unmarshal(res.Body, &l); err != nil {
		t.Fatalf("decode List: %v\nbody: %s", err, res.Body)
	}
	return l
}

func myLists(t *testing.T, c *testkit.Client) []listSummary {
	t.Helper()
	res := c.Get(t, "/api/lists")
	res.RequireStatus(t, http.StatusOK)
	var body struct {
		Lists []listSummary `json:"lists"`
	}
	if err := json.Unmarshal(res.Body, &body); err != nil {
		t.Fatalf("decode Lists: %v\nbody: %s", err, res.Body)
	}
	return body.Lists
}

const groceriesID = "0190a3b4-7c5d-7e6f-8a9b-0c1d2e3f4a5b"

func TestCreatingAListMakesTheCreatorItsOwner(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)

	res := ana.Post(t, "/api/lists", `{"id": "`+groceriesID+`", "name": "  Groceries "}`)

	res.RequireStatus(t, http.StatusCreated)
	created := decodeList(t, res)
	if !created.CreatedAt.Equal(srv.Clock.Now()) {
		t.Fatalf("createdAt = %v, want %v", created.CreatedAt, srv.Clock.Now())
	}
	created.CreatedAt = time.Time{}
	want := listSummary{ID: groceriesID, Name: "Groceries", Role: "owner", UncheckedItemCount: 0, MemberCount: 1}
	if created != want {
		t.Fatalf("created List = %+v, want %+v", created, want)
	}
	lists := myLists(t, ana)
	if len(lists) != 1 || lists[0].ID != groceriesID || lists[0].Name != "Groceries" || lists[0].Role != "owner" ||
		lists[0].MemberCount != 1 {
		t.Fatalf("Ana's Lists = %+v, want just Groceries, owned by her", lists)
	}
}

func createList(t *testing.T, c *testkit.Client, id, name string) listSummary {
	t.Helper()
	res := c.Post(t, "/api/lists", `{"id": "`+id+`", "name": "`+name+`"}`)
	res.RequireStatus(t, http.StatusCreated)
	return decodeList(t, res)
}

func TestRetryingACreateReturnsTheSameListWithoutMakingAnother(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")

	res := ana.Post(t, "/api/lists", `{"id": "`+groceriesID+`", "name": "Something else"}`)

	res.RequireStatus(t, http.StatusOK)
	if got := decodeList(t, res); got.ID != groceriesID || got.Name != "Groceries" {
		t.Fatalf("retried create = %+v, want the original Groceries", got)
	}
	if lists := myLists(t, ana); len(lists) != 1 {
		t.Fatalf("Ana has %d Lists, want 1", len(lists))
	}
}

func TestCreatingAListWithAnotherUsersListIDIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	createList(t, srv.As(testkit.Ana), groceriesID, "Groceries")
	bruno := srv.As(testkit.Bruno)

	res := bruno.Post(t, "/api/lists", `{"id": "`+groceriesID+`", "name": "Mine now"}`)

	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "list_id_taken")
	if lists := myLists(t, bruno); len(lists) != 0 {
		t.Fatalf("Bruno's Lists = %+v, want none", lists)
	}
}

func TestTheOwnerCanRenameAList(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")

	res := ana.Patch(t, "/api/lists/"+groceriesID, `{"name": " Feira de sábado "}`)

	res.RequireStatus(t, http.StatusOK)
	if got := decodeList(t, res); got.Name != "Feira de sábado" || got.Role != "owner" {
		t.Fatalf("renamed List = %+v, want name Feira de sábado, role owner", got)
	}
	if lists := myLists(t, ana); len(lists) != 1 || lists[0].Name != "Feira de sábado" {
		t.Fatalf("Ana's Lists = %+v, want the renamed List", lists)
	}
}

func TestListNamesMustBeOneToSixtyVisibleCharacters(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	invalid := map[string]string{
		"empty":           ``,
		"only spaces":     `   `,
		"control char":    `Feira\u0007`,
		"sixty-one runes": strings.Repeat("é", 61),
	}

	for label, name := range invalid {
		t.Run(label, func(t *testing.T) {
			create := ana.Post(t, "/api/lists", `{"id": "`+uuid.NewString()+`", "name": "`+name+`"}`)
			rename := ana.Patch(t, "/api/lists/"+groceriesID, `{"name": "`+name+`"}`)

			create.RequireStatus(t, http.StatusBadRequest)
			create.RequireErrorCode(t, "invalid_list_name")
			rename.RequireStatus(t, http.StatusBadRequest)
			rename.RequireErrorCode(t, "invalid_list_name")
		})
	}
	sixty := strings.Repeat("é", 60)
	if got := decodeList(t, ana.Patch(t, "/api/lists/"+groceriesID, `{"name": "`+sixty+`"}`)); got.Name != sixty {
		t.Fatalf("name = %q, want 60 accented characters accepted", got.Name)
	}
	if lists := myLists(t, ana); len(lists) != 1 {
		t.Fatalf("Ana has %d Lists, want 1 (no invalid create succeeded)", len(lists))
	}
}
