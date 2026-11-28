package api_test

import (
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

type historyEntry struct {
	ItemID    string    `json:"itemId"`
	ListID    string    `json:"listId"`
	Name      string    `json:"name"`
	Quantity  *string   `json:"quantity"`
	Unit      *string   `json:"unit"`
	Note      *string   `json:"note"`
	ClearedAt time.Time `json:"clearedAt"`
	ClearedBy userRef   `json:"clearedBy"`
}

func clearItem(id string) mutation {
	return mutation{typ: "item_clear", entity: id}
}

func TestClearingACheckedItemMovesItFromTheListToItemHistory(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	bruno.Patch(t, "/api/me", `{"displayName": "Bruno"}`).RequireStatus(t, http.StatusOK)
	pushOK(t, ana,
		createItem(groceriesID, milkID, `{"name": "Milk", "quantity": "2", "unit": "L", "note": "cold", "checked": true}`),
		createItem(groceriesID, breadID, `{"name": "Bread"}`))
	srv.Clock.Advance(time.Hour)

	pushOK(t, bruno, clearItem(milkID))

	p := pullAll(t, ana, "")
	if len(p.Items) != 1 || p.Items[0].ID != breadID {
		t.Fatalf("Items = %+v, want just Bread", p.Items)
	}
	if len(p.History) != 1 {
		t.Fatalf("history = %+v, want Milk", p.History)
	}
	got := p.History[0]
	if got.ItemID != milkID || got.ListID != groceriesID || got.Name != "Milk" ||
		got.Quantity == nil || *got.Quantity != "2" || got.Unit == nil || *got.Unit != "L" ||
		got.Note == nil || *got.Note != "cold" || !got.ClearedAt.Equal(srv.Clock.Now()) ||
		got.ClearedBy.DisplayName != "Bruno" {
		t.Fatalf("history entry = %+v, want Milk cleared by Bruno now", got)
	}
}

func TestClearingAnItemThatIsNotCheckedIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk"}`))

	requireRejected(t, push(t, ana, clearItem(milkID))[0], "item_not_checked")

	p := pullAll(t, ana, "")
	if len(p.Items) != 1 || p.Items[0].ID != milkID || len(p.History) != 0 {
		t.Fatalf("pull = %+v, want Milk still on the List and no history", p)
	}
}

func TestClearingTheSameItemTwiceRecordsOneHistoryEntry(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	srv.AddEditor(t, groceriesID, testkit.Bruno)
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk", "checked": true}`))
	once := clearItem(milkID)
	once.id = "0190a3b4-7c5d-7e6f-8a9b-00000000c1ea"

	pushOK(t, ana, once, once)
	pushOK(t, bruno, clearItem(milkID)) // Bruno saw it checked too, and cleared it offline

	if p := pullAll(t, ana, ""); len(p.History) != 1 || p.History[0].ItemID != milkID || len(p.Items) != 0 {
		t.Fatalf("pull = %+v, want one history entry for Milk and no Items", p)
	}
}

func TestAPullReturnsItemHistoryOnlyForListsTheUserIsAMemberOfSinceTheCursor(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk", "checked": true}`), clearItem(milkID))
	brunosList := uuid.NewString()
	createList(t, bruno, brunosList, "Hardware")
	nails := uuid.NewString()
	pushOK(t, bruno, createItem(brunosList, nails, `{"name": "Nails", "checked": true}`), clearItem(nails))
	before := pullAll(t, ana, "")
	if len(before.History) != 1 || before.History[0].ItemID != milkID {
		t.Fatalf("Ana's history = %+v, want only her Milk", before.History)
	}

	pushOK(t, ana, createItem(groceriesID, breadID, `{"name": "Bread", "checked": true}`), clearItem(breadID))

	p := pullAll(t, ana, before.Cursor)
	if len(p.History) != 1 || p.History[0].ItemID != breadID {
		t.Fatalf("Ana's history since the cursor = %+v, want just Bread", p.History)
	}
}

func TestAUserWhoJoinsAListPullsItsItemHistory(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk", "checked": true}`), clearItem(milkID))
	before := pullAll(t, bruno, "")

	srv.AddEditor(t, groceriesID, testkit.Bruno)

	p := pullAll(t, bruno, before.Cursor)
	if len(p.History) != 1 || p.History[0].ItemID != milkID || p.History[0].ClearedBy.DisplayName != "Ana Souza" {
		t.Fatalf("Bruno's history after joining = %+v, want Milk cleared by Ana", p.History)
	}
}

func TestAPullPagedOneChangeAtATimeGetsBothTheClearedItemsTombstoneAndItsHistory(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk", "checked": true}`))
	before := pullAll(t, ana, "")
	pushOK(t, ana, clearItem(milkID))

	var got pulled
	cursor := before.Cursor
	for {
		p := pullPage(t, ana, cursor, 1)
		got.Tombstones = append(got.Tombstones, p.Tombstones...)
		got.History = append(got.History, p.History...)
		cursor = p.Cursor
		if !p.HasMore {
			break
		}
	}
	if len(got.Tombstones) != 1 || got.Tombstones[0].ID != milkID || len(got.History) != 1 || got.History[0].ItemID != milkID {
		t.Fatalf("paged pull = %+v, want Milk's tombstone and its history entry", got)
	}
}

func TestARemovedItemCannotBeCleared(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	pushOK(t, ana, createItem(groceriesID, milkID, `{"name": "Milk", "checked": true}`), deleteItem(milkID))

	requireRejected(t, push(t, ana, clearItem(milkID))[0], "item_deleted")

	if p := pullAll(t, ana, ""); len(p.History) != 0 {
		t.Fatalf("history = %+v, want none", p.History)
	}
}
