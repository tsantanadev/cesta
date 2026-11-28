package api_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/auth"
	"github.com/tsantanadev/cesta/backend/internal/testkit"
)

type invitation struct {
	ID        string    `json:"id"`
	ListID    string    `json:"listId"`
	ListName  string    `json:"listName"`
	Email     string    `json:"email"`
	InvitedBy userRef   `json:"invitedBy"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"createdAt"`
	ExpiresAt time.Time `json:"expiresAt"`
}

func decodeInvitation(t *testing.T, res *testkit.Response) invitation {
	t.Helper()
	var inv invitation
	if err := json.Unmarshal(res.Body, &inv); err != nil {
		t.Fatalf("decode Invitation: %v\nbody: %s", err, res.Body)
	}
	return inv
}

const carlaEmail = "carla@example.com"

var invitationLink = regexp.MustCompile(`https://cesta\.tsantana\.dev/invite/([A-Za-z0-9_-]+)`)

// invite has c invite address to listID in English and returns the Invitation.
func invite(t *testing.T, c *testkit.Client, listID, address string) invitation {
	t.Helper()
	res := c.Post(t, "/api/lists/"+listID+"/invitations", `{"email": "`+address+`", "language": "en"}`)
	res.RequireStatus(t, http.StatusCreated)
	return decodeInvitation(t, res)
}

// inviteToken returns the token in the deep link of the latest Invitation email sent to address.
func inviteToken(t *testing.T, srv *testkit.Server, address string) string {
	t.Helper()
	sent := srv.Emails.SentTo(address)
	if len(sent) == 0 {
		t.Fatalf("no email sent to %s", address)
	}
	m := invitationLink.FindStringSubmatch(sent[len(sent)-1].Text)
	if m == nil {
		t.Fatalf("email to %s has no Invitation link:\n%s", address, sent[len(sent)-1].Text)
	}
	return m[1]
}

func accept(c *testkit.Client, t *testing.T, token string) *testkit.Response {
	t.Helper()
	return c.Post(t, "/api/invitations/accept", `{"token": "`+token+`"}`)
}

func TestAnInvitationSendsOneEmailWithItsDeepLink(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")

	res := ana.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": " Carla@Example.com ", "language": "en"}`)

	res.RequireStatus(t, http.StatusCreated)
	inv := decodeInvitation(t, res)
	if inv.ListID != groceriesID || inv.ListName != "Groceries" || inv.Email != carlaEmail ||
		inv.Status != "pending" || inv.InvitedBy.DisplayName != "Ana Souza" ||
		!inv.CreatedAt.Equal(srv.Clock.Now()) || !inv.ExpiresAt.Equal(srv.Clock.Now().Add(14*24*time.Hour)) {
		t.Fatalf("Invitation = %+v, want pending for %s to Groceries by Ana, expiring in 14 days", inv, carlaEmail)
	}
	sent := srv.Emails.SentTo(carlaEmail)
	if len(sent) != 1 {
		t.Fatalf("sent %d emails to %s, want 1", len(sent), carlaEmail)
	}
	m := sent[0]
	if !strings.Contains(m.Subject, "Ana Souza") || !strings.Contains(m.Subject, "Groceries") {
		t.Fatalf("subject = %q, want it to name Ana Souza and Groceries", m.Subject)
	}
	text := invitationLink.FindStringSubmatch(m.Text)
	if text == nil || len(text[1]) < 43 {
		t.Fatalf("email text has no Invitation link with a high-entropy token:\n%s", m.Text)
	}
	if !strings.Contains(m.HTML, text[0]) {
		t.Fatalf("email HTML lacks the link %s:\n%s", text[0], m.HTML)
	}
}

func TestTheInvitationEmailCanBeInBrazilianPortuguese(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Feira")

	ana.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+carlaEmail+`", "language": "pt-BR"}`).
		RequireStatus(t, http.StatusCreated)

	m := srv.Emails.SentTo(carlaEmail)[0]
	if m.Subject != "Ana Souza convidou você para a lista Feira no Cesta" {
		t.Fatalf("subject = %q, want it in Portuguese", m.Subject)
	}
	if !strings.Contains(m.Text, "expira em 16/03/2026") || !invitationLink.MatchString(m.Text) {
		t.Fatalf("text = %q, want the link and the expiry date in Portuguese", m.Text)
	}
}

func TestAcceptingAnInvitationMakesTheInviteeAnEditorEvenWithADifferentEmail(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	invite(t, ana, groceriesID, carlaEmail)

	res := accept(bruno, t, inviteToken(t, srv, carlaEmail))

	res.RequireStatus(t, http.StatusOK)
	if got := decodeList(t, res); got.ID != groceriesID || got.Role != "editor" || got.MemberCount != 2 {
		t.Fatalf("accepted List = %+v, want Groceries, Bruno an Editor, 2 Members", got)
	}
	if lists := myLists(t, bruno); len(lists) != 1 || lists[0].ID != groceriesID || lists[0].Role != "editor" {
		t.Fatalf("Bruno's Lists = %+v, want Groceries as an Editor", lists)
	}
}

func TestAnInvitationTokenWorksOnce(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	carla := srv.As(carlaIdentity)
	createList(t, ana, groceriesID, "Groceries")
	invite(t, ana, groceriesID, carlaEmail)
	token := inviteToken(t, srv, carlaEmail)
	accept(bruno, t, token).RequireStatus(t, http.StatusOK)

	retry := accept(bruno, t, token)
	other := accept(carla, t, token)

	retry.RequireStatus(t, http.StatusOK)
	other.RequireStatus(t, http.StatusConflict)
	other.RequireErrorCode(t, "invitation_accepted")
	if lists := myLists(t, carla); len(lists) != 0 {
		t.Fatalf("Carla's Lists = %+v, want none", lists)
	}
	if got := myLists(t, ana)[0].MemberCount; got != 2 {
		t.Fatalf("memberCount = %d, want 2 after the retry", got)
	}
}

func TestAnUnknownTokenIsNotFound(t *testing.T) {
	srv := testkit.NewServer(t)

	res := accept(srv.As(testkit.Bruno), t, "not-a-real-token")

	res.RequireStatus(t, http.StatusNotFound)
	res.RequireErrorCode(t, "invitation_not_found")
}

var carlaIdentity = auth.Identity{Subject: "firebase-uid-carla", Email: carlaEmail, Name: "Carla"}

func TestACancelledInvitationCantBeAccepted(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	inv := invite(t, ana, groceriesID, carlaEmail)

	cancel := ana.Delete(t, "/api/lists/"+groceriesID+"/invitations/"+inv.ID)

	cancel.RequireStatus(t, http.StatusOK)
	if got := decodeInvitation(t, cancel); got.Status != "cancelled" {
		t.Fatalf("cancelled Invitation = %+v, want status cancelled", got)
	}
	res := accept(srv.As(testkit.Bruno), t, inviteToken(t, srv, carlaEmail))
	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "invitation_cancelled")
}

func TestADeclinedInvitationCantBeAccepted(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, carla := srv.As(testkit.Ana), srv.As(carlaIdentity)
	createList(t, ana, groceriesID, "Groceries")
	invite(t, ana, groceriesID, carlaEmail)
	token := inviteToken(t, srv, carlaEmail)

	decline := carla.Post(t, "/api/invitations/decline", `{"token": "`+token+`"}`)

	decline.RequireStatus(t, http.StatusOK)
	if got := decodeInvitation(t, decline); got.Status != "declined" {
		t.Fatalf("declined Invitation = %+v, want status declined", got)
	}
	res := accept(carla, t, token)
	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "invitation_declined")
	if lists := myLists(t, carla); len(lists) != 0 {
		t.Fatalf("Carla's Lists = %+v, want none", lists)
	}
}

func TestAnInvitationExpiresFourteenDaysAfterItIsSent(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	createList(t, ana, otherListID, "Hardware")
	invite(t, ana, groceriesID, carlaEmail)
	expiring := inviteToken(t, srv, carlaEmail)
	srv.Clock.Advance(time.Hour)
	invite(t, ana, otherListID, carlaEmail)
	lastMinute := inviteToken(t, srv, carlaEmail)

	srv.Clock.Advance(14*24*time.Hour - time.Hour)

	res := accept(srv.As(testkit.Bruno), t, expiring)
	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "invitation_expired")
	accept(srv.As(testkit.Bruno), t, lastMinute).RequireStatus(t, http.StatusOK)
	looked := srv.As(testkit.Bruno).Post(t, "/api/invitations/lookup", `{"token": "`+expiring+`"}`)
	looked.RequireStatus(t, http.StatusOK)
	if got := decodeInvitation(t, looked); got.Status != "expired" {
		t.Fatalf("looked-up Invitation = %+v, want status expired", got)
	}
}

const otherListID = "0190a3b4-7c5d-7e6f-8a9b-0c1d2e3f4a5c"

func TestEditorsCantInvite(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, bruno := srv.As(testkit.Ana), srv.As(testkit.Bruno)
	createList(t, ana, groceriesID, "Groceries")
	invite(t, ana, groceriesID, testkit.Bruno.Email)
	accept(bruno, t, inviteToken(t, srv, testkit.Bruno.Email)).RequireStatus(t, http.StatusOK)

	res := bruno.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+carlaEmail+`", "language": "en"}`)
	pending := bruno.Get(t, "/api/lists/"+groceriesID+"/invitations")

	res.RequireStatus(t, http.StatusForbidden)
	res.RequireErrorCode(t, "not_list_owner")
	pending.RequireStatus(t, http.StatusForbidden)
	if sent := srv.Emails.SentTo(carlaEmail); len(sent) != 0 {
		t.Fatalf("sent %d emails to Carla, want none", len(sent))
	}
}

func TestOnlyMembersListsCanBeInvitedTo(t *testing.T) {
	srv := testkit.NewServer(t)
	createList(t, srv.As(testkit.Ana), groceriesID, "Groceries")

	res := srv.As(testkit.Bruno).Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+carlaEmail+`", "language": "en"}`)

	res.RequireStatus(t, http.StatusNotFound)
	res.RequireErrorCode(t, "list_not_found")
}

func TestAnInvitationWhoseEmailCantBeSentIsNotMade(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	srv.Emails.FailWith(errors.New("provider down"))

	res := ana.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+carlaEmail+`", "language": "en"}`)

	res.RequireStatus(t, http.StatusInternalServerError)
	if got := pendingInvitations(t, ana, "/api/lists/"+groceriesID+"/invitations"); len(got) != 0 {
		t.Fatalf("pending on the List = %+v, want none when the email wasn't sent", got)
	}
	if got := pendingInvitations(t, srv.As(carlaIdentity), "/api/invitations"); len(got) != 0 {
		t.Fatalf("Carla's pending = %+v, want none when the email wasn't sent", got)
	}
	srv.Emails.FailWith(nil)
	invite(t, ana, groceriesID, carlaEmail)
}

func TestInvitingSomethingThatIsNotAnEmailAddressIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")

	for _, address := range []string{"", "carla", "carla@", "Carla <carla@example.com>", "carla@localhost"} {
		res := ana.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+address+`", "language": "en"}`)
		res.RequireStatus(t, http.StatusBadRequest)
		res.RequireErrorCode(t, "invalid_email")
	}
}

func TestTheTwentyFirstInvitationOfTheDayIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	for i := range 20 {
		invite(t, ana, groceriesID, fmt.Sprintf("friend%d@example.com", i))
		srv.Clock.Advance(time.Minute)
	}

	res := ana.Post(t, "/api/lists/"+groceriesID+"/invitations", `{"email": "`+carlaEmail+`", "language": "en"}`)

	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "limit_exceeded")
	res.RequireJSON(t, `{"code": "limit_exceeded", "limit": 20,
		"message": "the User already sent the limit of 20 Invitations in 24 hours"}`)
	if sent := srv.Emails.SentTo(carlaEmail); len(sent) != 0 {
		t.Fatalf("sent %d emails to Carla, want none", len(sent))
	}
	srv.Clock.Advance(24*time.Hour - 20*time.Minute)
	invite(t, ana, groceriesID, carlaEmail)
}

func TestJoiningAListThatAlreadyHasTwentyMembersIsRejected(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	for i := range 19 {
		address := fmt.Sprintf("friend%d@example.com", i)
		invite(t, ana, groceriesID, address)
		friend := srv.As(auth.Identity{Subject: fmt.Sprintf("firebase-uid-friend%d", i), Email: address})
		accept(friend, t, inviteToken(t, srv, address)).RequireStatus(t, http.StatusOK)
	}
	invite(t, ana, groceriesID, carlaEmail)

	res := accept(srv.As(carlaIdentity), t, inviteToken(t, srv, carlaEmail))

	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "list_full")
	if got := myLists(t, ana)[0].MemberCount; got != 20 {
		t.Fatalf("memberCount = %d, want 20", got)
	}
}

func TestTwoAcceptsRacingForTheLastPlaceLetExactlyOneJoin(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	for i := range 18 {
		address := fmt.Sprintf("friend%d@example.com", i)
		invite(t, ana, groceriesID, address)
		friend := srv.As(auth.Identity{Subject: fmt.Sprintf("firebase-uid-friend%d", i), Email: address})
		accept(friend, t, inviteToken(t, srv, address)).RequireStatus(t, http.StatusOK)
	}
	invite(t, ana, groceriesID, carlaEmail)
	invite(t, ana, groceriesID, testkit.Bruno.Email)
	racers := []*testkit.Client{srv.As(carlaIdentity), srv.As(testkit.Bruno)}
	tokens := []string{inviteToken(t, srv, carlaEmail), inviteToken(t, srv, testkit.Bruno.Email)}
	results := make([]*testkit.Response, len(racers))
	var wg sync.WaitGroup

	for i := range racers {
		wg.Go(func() { results[i] = accept(racers[i], t, tokens[i]) })
	}
	wg.Wait()

	var joined, full int
	for _, res := range results {
		switch {
		case res.Status == http.StatusOK:
			joined++
		case res.Status == http.StatusConflict && strings.Contains(string(res.Body), `"list_full"`):
			full++
		}
	}
	if joined != 1 || full != 1 {
		t.Fatalf("results = %d %s and %d %s, want one joined and one list_full",
			results[0].Status, results[0].Body, results[1].Status, results[1].Body)
	}
	if got := myLists(t, ana)[0].MemberCount; got != 20 {
		t.Fatalf("memberCount = %d, want 20", got)
	}
}

func pendingInvitations(t *testing.T, c *testkit.Client, path string) []invitation {
	t.Helper()
	res := c.Get(t, path)
	res.RequireStatus(t, http.StatusOK)
	var body struct {
		Invitations []invitation `json:"invitations"`
	}
	if err := json.Unmarshal(res.Body, &body); err != nil {
		t.Fatalf("decode Invitations: %v\nbody: %s", err, res.Body)
	}
	return body.Invitations
}

func TestPendingInvitationsShowOnTheListAndForTheInvitedUser(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, carla := srv.As(testkit.Ana), srv.As(carlaIdentity)
	createList(t, ana, groceriesID, "Groceries")
	toCarla := invite(t, ana, groceriesID, carlaEmail)
	srv.Clock.Advance(time.Minute)
	toBruno := invite(t, ana, groceriesID, testkit.Bruno.Email)

	onList := pendingInvitations(t, ana, "/api/lists/"+groceriesID+"/invitations")
	forCarla := pendingInvitations(t, carla, "/api/invitations")

	if len(onList) != 2 || onList[0].ID != toBruno.ID || onList[1].ID != toCarla.ID {
		t.Fatalf("pending on the List = %+v, want Bruno's then Carla's", onList)
	}
	if len(forCarla) != 1 || forCarla[0].ID != toCarla.ID || forCarla[0].ListName != "Groceries" ||
		forCarla[0].InvitedBy.DisplayName != "Ana Souza" {
		t.Fatalf("Carla's pending = %+v, want hers to Groceries from Ana", forCarla)
	}
	accept(carla, t, inviteToken(t, srv, carlaEmail)).RequireStatus(t, http.StatusOK)
	ana.Delete(t, "/api/lists/"+groceriesID+"/invitations/"+toBruno.ID).RequireStatus(t, http.StatusOK)
	if got := pendingInvitations(t, ana, "/api/lists/"+groceriesID+"/invitations"); len(got) != 0 {
		t.Fatalf("pending on the List = %+v, want none after accept and cancel", got)
	}
	if got := pendingInvitations(t, carla, "/api/invitations"); len(got) != 0 {
		t.Fatalf("Carla's pending = %+v, want none after accepting", got)
	}
}

func TestTheInvitedUserCanAcceptFromTheirPendingInvitationsWithoutTheToken(t *testing.T) {
	srv := testkit.NewServer(t)
	ana, carla := srv.As(testkit.Ana), srv.As(carlaIdentity)
	createList(t, ana, groceriesID, "Groceries")
	inv := invite(t, ana, groceriesID, carlaEmail)

	someoneElse := srv.As(testkit.Bruno).Post(t, "/api/invitations/accept", `{"id": "`+inv.ID+`"}`)
	res := carla.Post(t, "/api/invitations/accept", `{"id": "`+inv.ID+`"}`)

	someoneElse.RequireStatus(t, http.StatusNotFound)
	someoneElse.RequireErrorCode(t, "invitation_not_found")
	res.RequireStatus(t, http.StatusOK)
	if got := decodeList(t, res); got.ID != groceriesID || got.Role != "editor" {
		t.Fatalf("accepted List = %+v, want Groceries as an Editor", got)
	}
}

func TestLookingUpATokenShowsTheInvitation(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	inv := invite(t, ana, groceriesID, carlaEmail)

	res := srv.As(testkit.Bruno).Post(t, "/api/invitations/lookup", `{"token": "`+inviteToken(t, srv, carlaEmail)+`"}`)

	res.RequireStatus(t, http.StatusOK)
	if got := decodeInvitation(t, res); got != inv {
		t.Fatalf("looked-up Invitation = %+v, want %+v", got, inv)
	}
}

func TestAnInvitationToADeletedListCantBeAccepted(t *testing.T) {
	srv := testkit.NewServer(t)
	ana := srv.As(testkit.Ana)
	createList(t, ana, groceriesID, "Groceries")
	invite(t, ana, groceriesID, carlaEmail)
	ana.Delete(t, "/api/lists/"+groceriesID).RequireStatus(t, http.StatusOK)

	res := accept(srv.As(carlaIdentity), t, inviteToken(t, srv, carlaEmail))

	res.RequireStatus(t, http.StatusConflict)
	res.RequireErrorCode(t, "list_deleted")
	if got := pendingInvitations(t, srv.As(carlaIdentity), "/api/invitations"); len(got) != 0 {
		t.Fatalf("Carla's pending = %+v, want none on a deleted List", got)
	}
}

func TestAcceptNeedsExactlyOneOfTokenOrID(t *testing.T) {
	srv := testkit.NewServer(t)

	for _, body := range []string{`{}`, `{"token": "x", "id": "` + groceriesID + `"}`} {
		res := srv.As(testkit.Bruno).Post(t, "/api/invitations/accept", body)
		res.RequireStatus(t, http.StatusBadRequest)
		res.RequireErrorCode(t, "invalid_request")
	}
}
