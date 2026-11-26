package api_test

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"

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
