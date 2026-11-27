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

// mutation is one outbox entry; fields is a JSON object literal or "", at a
// client timestamp or "" for a fixed one.
type mutation struct {
	id, typ, entity, list, fields, at string
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
	if m.at == "" {
		m.at = "2026-03-02T08:00:00Z"
	}
	b.WriteString(`, "clientTimestamp": "` + m.at + `"}`)
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

func TestPushingTheSameMutationTwiceAppliesItOnce(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	add := createItem(groceriesID, milkID, `{"name": "Milk"}`)
	add.id = uuid.NewString()
	pushOK(t, ana, add)
	pushOK(t, ana, updateItem(milkID, `{"name": "Oat milk"}`))

	again := push(t, ana, add)

	if again[0].Status != "applied" || again[0].MutationID != add.id {
		t.Fatalf("retried create = %+v, want its original result, applied", again[0])
	}
	p := pullAll(t, ana, "")
	if len(p.Items) != 1 || p.Items[0].Name != "Oat milk" {
		t.Fatalf("pulled Items = %+v, want just Oat milk: the retry must not apply again", p.Items)
	}
}

func TestARetriedRejectionReturnsTheSameRejection(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	edit := updateItem(milkID, `{"name": "Oat milk"}`)
	edit.id = uuid.NewString()
	requireRejected(t, push(t, ana, edit)[0], "item_not_found")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))

	requireRejected(t, push(t, ana, edit)[0], "item_not_found")

	if got := findItem(t, pullAll(t, ana, ""), milkID); got.Name != "Milk" {
		t.Fatalf("Item = %+v, want Milk unchanged", got)
	}
}

func TestOfflineEditsToDifferentFieldsOfAnItemBothSurvive(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))

	pushOK(t, ana, updateItem(milkID, `{"quantity": "2", "unit": "L"}`))
	pushOK(t, bruno, updateItem(milkID, `{"note": "lactose-free"}`))

	got := findItem(t, pullAll(t, ana, ""), milkID)
	if got.Name != "Milk" || *got.Quantity != "2" || *got.Unit != "L" || *got.Note != "lactose-free" {
		t.Fatalf("Item = %+v, want both edits kept", got)
	}
}

func TestOfTwoEditsToTheSameFieldTheLaterReceivedWins(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	// Bruno's edit carries an earlier client timestamp but reaches the server last.
	brunos := updateItem(milkID, `{"name": "Whole milk"}`)
	brunos.at = "2026-03-02T07:00:00Z"
	anas := updateItem(milkID, `{"name": "Oat milk"}`)

	pushOK(t, ana, anas)
	pushOK(t, bruno, brunos)

	if got := findItem(t, pullAll(t, ana, ""), milkID); got.Name != "Whole milk" {
		t.Fatalf("name = %q, want Whole milk, the edit received last", got.Name)
	}
}

func TestAnEditToAnItemRemovedConcurrentlyDoesNotBringItBack(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	before := pullAll(t, bruno, "")

	pushOK(t, ana, deleteItem(milkID))
	edit := push(t, bruno, updateItem(milkID, `{"quantity": "2", "checked": true}`))

	requireRejected(t, edit[0], "item_deleted")
	p := pullAll(t, bruno, before.Cursor)
	if len(p.Items) != 0 || len(p.Tombstones) != 1 ||
		p.Tombstones[0] != (tombstone{Type: "item", ID: milkID, ListID: groceriesID}) {
		t.Fatalf("pull = %+v, want only Milk's tombstone", p)
	}
	if full := pullAll(t, ana, ""); len(full.Items) != 0 {
		t.Fatalf("full pull Items = %+v, want none", full.Items)
	}
}

func TestRemovingAnItemTwiceIsApplied(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))

	pushOK(t, ana, deleteItem(milkID), deleteItem(milkID))
}

const breadID = "0190a3b4-7c5d-7e6f-8a9b-000000000002"

func TestAPullReturnsOnlyChangesSinceTheCursor(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	first := pullAll(t, ana, "")

	pushOK(t, ana, createItem(groceriesID, breadID, `{"name": "Bread"}`))

	p := pullAll(t, ana, first.Cursor)
	if len(p.Items) != 1 || p.Items[0].ID != breadID || len(p.Tombstones) != 0 {
		t.Fatalf("pull since cursor = %+v, want just Bread", p)
	}
	if none := pullAll(t, ana, p.Cursor); len(none.Items) != 0 || len(none.Tombstones) != 0 || none.Cursor != p.Cursor {
		t.Fatalf("pull with nothing new = %+v, want empty and the same cursor", none)
	}
}

func TestAPullReturnsOnlyListsTheUserIsAMemberOf(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	brunosList := uuid.NewString()
	createList(t, bruno, brunosList, "Hardware")
	pushOK(t, bruno, createItem(brunosList, breadID, `{"name": "Nails"}`))

	p := pullAll(t, bruno, "")

	if len(p.Items) != 1 || p.Items[0].ID != breadID {
		t.Fatalf("Bruno's pull = %+v, want only his Nails", p.Items)
	}
}

func TestANonMemberCannotChangeItemsOnTheList(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))

	res := push(t, bruno,
		createItem(groceriesID, breadID, `{"name": "Bread"}`),
		updateItem(milkID, `{"name": "Mine"}`),
		deleteItem(milkID))

	requireRejected(t, res[0], "list_not_found")
	requireRejected(t, res[1], "item_not_found")
	requireRejected(t, res[2], "item_not_found")
	p := pullAll(t, ana, "")
	if len(p.Items) != 1 || p.Items[0].Name != "Milk" {
		t.Fatalf("Ana's Items = %+v, want Milk unchanged", p.Items)
	}
}

func TestTheFiveHundredAndFirstItemIsRejected(t *testing.T) {
	srv := testkit.NewServer(t, generousRateLimits())
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	for range 5 {
		batch := make([]mutation, 100)
		for i := range batch {
			batch[i] = createItem(groceriesID, uuid.NewString(), `{"name": "Thing"}`)
		}
		pushOK(t, ana, batch...)
	}

	res := push(t, ana, createItem(groceriesID, uuid.NewString(), `{"name": "One too many"}`))

	requireRejected(t, res[0], "limit_exceeded")
	if res[0].Reason.Limit == nil || *res[0].Reason.Limit != 500 {
		t.Fatalf("reason = %+v, want limit 500", res[0].Reason)
	}
	if p := pullAll(t, ana, ""); len(p.Items) != 500 {
		t.Fatalf("the List has %d Items, want 500", len(p.Items))
	}
}

func TestAUserWhoJoinsAListPullsAllItsItemsSinceTheirCursor(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	brunosList := uuid.NewString()
	createList(t, bruno, brunosList, "Hardware")
	pushOK(t, bruno, createItem(brunosList, uuid.NewString(), `{"name": "Nails"}`))
	before := pullAll(t, bruno, "")

	srv.AddEditor(t, groceriesID, testkit.Bruno)

	p := pullAll(t, bruno, before.Cursor)
	if len(p.Items) != 1 || p.Items[0].ID != milkID {
		t.Fatalf("Bruno's pull after joining = %+v, want Groceries' Milk", p.Items)
	}
}

func TestADeletedListIsPulledAsATombstoneAndComesBackWhole(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))
	before := pullAll(t, bruno, "")

	ana.Delete(t, "/api/lists/"+groceriesID).RequireStatus(t, http.StatusOK)

	deleted := pullAll(t, bruno, before.Cursor)
	if len(deleted.Items) != 0 || len(deleted.Tombstones) != 1 ||
		deleted.Tombstones[0] != (tombstone{Type: "list", ID: groceriesID}) {
		t.Fatalf("pull after delete = %+v, want the List's tombstone", deleted)
	}
	edit := push(t, bruno, updateItem(milkID, `{"checked": true}`), createItem(groceriesID, breadID, `{"name": "Bread"}`))
	requireRejected(t, edit[0], "list_deleted")
	requireRejected(t, edit[1], "list_deleted")

	ana.Post(t, "/api/lists/"+groceriesID+"/restore", "").RequireStatus(t, http.StatusOK)

	restored := pullAll(t, bruno, deleted.Cursor)
	if len(restored.Items) != 1 || restored.Items[0].ID != milkID || restored.Items[0].CheckedAt != nil {
		t.Fatalf("pull after restore = %+v, want Milk back, unchanged", restored)
	}
}

func TestAPullIsPagedInOrderWithoutGapsOrRepeats(t *testing.T) {
	srv := testkit.NewServer(t, generousRateLimits())
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	batch := make([]mutation, 7)
	want := map[string]bool{}
	for i := range batch {
		id := uuid.NewString()
		want[id] = true
		batch[i] = createItem(groceriesID, id, `{"name": "Thing"}`)
	}
	pushOK(t, ana, batch...)
	srv.AddEditor(t, groceriesID, testkit.Bruno) // all 7 become visible to Bruno at once
	bruno := srv.As(testkit.Bruno)

	seen := map[string]bool{}
	cursor, pages := "", 0
	for {
		p := pullPage(t, bruno, cursor, 3)
		pages++
		for _, it := range p.Items {
			if seen[it.ID] {
				t.Fatalf("Item %s pulled twice", it.ID)
			}
			seen[it.ID] = true
		}
		cursor = p.Cursor
		if !p.HasMore {
			break
		}
	}
	if len(seen) != len(want) || pages != 3 {
		t.Fatalf("pulled %d Items in %d pages, want 7 in 3", len(seen), pages)
	}
}

func TestAPullWithABadCursorOrLimitIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)

	for _, q := range []string{"cursor=nonsense", "limit=0", "limit=1001"} {
		res := ana.Get(t, "/api/sync/pull?"+q)
		res.RequireStatus(t, http.StatusBadRequest)
		res.RequireErrorCode(t, "invalid_request")
	}
}

func TestSyncRequiresSigningIn(t *testing.T) {
	srv := testkit.NewServer(t)
	anon := srv.Anonymous()

	anon.Get(t, "/api/sync/pull").RequireStatus(t, http.StatusUnauthorized)
	anon.Post(t, "/api/sync/push", `{"mutations": [`+deleteItem(milkID).json()+`]}`).
		RequireStatus(t, http.StatusUnauthorized)
}

func TestAPushMustCarryOneToAHundredMutations(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	many := make([]string, 101)
	for i := range many {
		many[i] = deleteItem(milkID).json()
	}

	for label, body := range map[string]string{
		"none":     `{"mutations": []}`,
		"too many": `{"mutations": [` + strings.Join(many, ",") + `]}`,
	} {
		t.Run(label, func(t *testing.T) {
			res := ana.Post(t, "/api/sync/push", body)
			res.RequireStatus(t, http.StatusBadRequest)
			res.RequireErrorCode(t, "invalid_request")
		})
	}
}
