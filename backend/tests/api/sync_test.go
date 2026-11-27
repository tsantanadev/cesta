package api_test

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

type userRef struct {
	ID          string `json:"id"`
	DisplayName string `json:"displayName"`
}

type item struct {
	ID        string     `json:"id"`
	ListID    string     `json:"listId"`
	Name      string     `json:"name"`
	Quantity  *string    `json:"quantity"`
	Unit      *string    `json:"unit"`
	Note      *string    `json:"note"`
	AddedBy   userRef    `json:"addedBy"`
	AddedAt   time.Time  `json:"addedAt"`
	CheckedAt *time.Time `json:"checkedAt"`
	CheckedBy *userRef   `json:"checkedBy"`
	UpdatedAt time.Time  `json:"updatedAt"`
}

type tombstone struct {
	Type   string `json:"type"`
	ID     string `json:"id"`
	ListID string `json:"listId,omitempty"`
}

type pulled struct {
	Items      []item      `json:"items"`
	Tombstones []tombstone `json:"tombstones"`
	Cursor     string      `json:"cursor"`
	HasMore    bool        `json:"hasMore"`
}

type mutationResult struct {
	MutationID string `json:"mutationId"`
	Status     string `json:"status"`
	Reason     *struct {
		Code  string `json:"code"`
		Limit *int   `json:"limit"`
	} `json:"reason"`
}

// mutation is one outbox entry; fields is a JSON object literal or "".
type mutation struct {
	id, typ, entity, list, fields string
}

func (m mutation) json() string {
	if m.id == "" {
		m.id = uuid.NewString()
	}
	var b strings.Builder
	b.WriteString(`{"id": "` + m.id + `", "type": "` + m.typ + `", "entityId": "` + m.entity + `"`)
	if m.list != "" {
		b.WriteString(`, "listId": "` + m.list + `"`)
	}
	if m.fields != "" {
		b.WriteString(`, "fields": ` + m.fields)
	}
	b.WriteString(`, "clientTimestamp": "2026-03-02T08:00:00Z"}`)
	return b.String()
}

func createItem(list, id, fields string) mutation {
	return mutation{typ: "item_create", entity: id, list: list, fields: fields}
}

func updateItem(id, fields string) mutation {
	return mutation{typ: "item_update", entity: id, fields: fields}
}

func deleteItem(id string) mutation {
	return mutation{typ: "item_delete", entity: id}
}

func push(t *testing.T, c *testkit.Client, ms ...mutation) []mutationResult {
	t.Helper()
	parts := make([]string, len(ms))
	for i, m := range ms {
		parts[i] = m.json()
	}
	res := c.Post(t, "/api/sync/push", `{"mutations": [`+strings.Join(parts, ", ")+`]}`)
	res.RequireStatus(t, http.StatusOK)
	var body struct {
		Results []mutationResult `json:"results"`
	}
	if err := json.Unmarshal(res.Body, &body); err != nil {
		t.Fatalf("decode push results: %v\nbody: %s", err, res.Body)
	}
	if len(body.Results) != len(ms) {
		t.Fatalf("got %d results for %d mutations\nbody: %s", len(body.Results), len(ms), res.Body)
	}
	return body.Results
}

// pushOK pushes ms and fails t unless every one is applied.
func pushOK(t *testing.T, c *testkit.Client, ms ...mutation) {
	t.Helper()
	for i, r := range push(t, c, ms...) {
		if r.Status != "applied" {
			t.Fatalf("mutation %d (%s) = %+v, want applied", i, ms[i].typ, r)
		}
	}
}

func requireRejected(t *testing.T, r mutationResult, code string) {
	t.Helper()
	if r.Status != "rejected" || r.Reason == nil || r.Reason.Code != code {
		t.Fatalf("result = %+v (reason %+v), want rejected with %s", r, r.Reason, code)
	}
}

func pullPage(t *testing.T, c *testkit.Client, cursor string, limit int) pulled {
	t.Helper()
	q := url.Values{}
	if cursor != "" {
		q.Set("cursor", cursor)
	}
	if limit > 0 {
		q.Set("limit", strconv.Itoa(limit))
	}
	path := "/api/sync/pull"
	if len(q) > 0 {
		path += "?" + q.Encode()
	}
	res := c.Get(t, path)
	res.RequireStatus(t, http.StatusOK)
	var p pulled
	if err := json.Unmarshal(res.Body, &p); err != nil {
		t.Fatalf("decode pull: %v\nbody: %s", err, res.Body)
	}
	return p
}

// pullAll pulls every page since cursor.
func pullAll(t *testing.T, c *testkit.Client, cursor string) pulled {
	t.Helper()
	var all pulled
	for {
		p := pullPage(t, c, cursor, 0)
		all.Items = append(all.Items, p.Items...)
		all.Tombstones = append(all.Tombstones, p.Tombstones...)
		all.Cursor, cursor = p.Cursor, p.Cursor
		if !p.HasMore {
			return all
		}
	}
}

func findItem(t *testing.T, p pulled, id string) item {
	t.Helper()
	for _, it := range p.Items {
		if it.ID == id {
			return it
		}
	}
	t.Fatalf("Item %s not in pull: %+v", id, p.Items)
	return item{}
}

func str(s string) *string { return &s }

const milkID = "0190a3b4-7c5d-7e6f-8a9b-000000000001"

func TestAnAddedItemIsPulledWithItsFields(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")

	pushOK(t, ana, createItem(groceriesID, milkID,
		`{"name": "  Milk ", "quantity": "1.50", "unit": "L", "note": "semi-skimmed"}`))

	p := pullAll(t, ana, "")
	if len(p.Items) != 1 {
		t.Fatalf("pulled Items = %+v, want just Milk", p.Items)
	}
	got := p.Items[0]
	if !got.AddedAt.Equal(srv.Clock.Now()) || !got.UpdatedAt.Equal(srv.Clock.Now()) {
		t.Fatalf("addedAt, updatedAt = %v, %v, want %v", got.AddedAt, got.UpdatedAt, srv.Clock.Now())
	}
	if got.ID != milkID || got.ListID != groceriesID || got.Name != "Milk" ||
		*got.Quantity != "1.5" || *got.Unit != "L" || *got.Note != "semi-skimmed" ||
		got.AddedBy.DisplayName != "Ana Souza" || got.CheckedAt != nil || got.CheckedBy != nil {
		t.Fatalf("pulled Item = %+v", got)
	}
}
