package killswitch_test

import (
	"context"
	"log/slog"
	"testing"

	"github.com/cloudevents/sdk-go/v2/event"

	killswitch "github.com/tsantanadev/cesta/infra/functions/billing-kill-switch"
)

// fakeBilling records which projects had billing detached.
type fakeBilling struct {
	enabled  bool
	detached []string
}

func (f *fakeBilling) BillingEnabled(context.Context, string) (bool, error) { return f.enabled, nil }

func (f *fakeBilling) DetachBilling(_ context.Context, project string) error {
	f.detached = append(f.detached, project)
	f.enabled = false
	return nil
}

// budgetEvent is a Pub/Sub CloudEvent as Eventarc delivers it, carrying a Cloud Billing
// budget notification (schema 1.0). Pub/Sub message data is base64 in the envelope.
func budgetEvent(t *testing.T, notification string) event.Event {
	t.Helper()
	e := event.New()
	e.SetID("1")
	e.SetSource("//pubsub.googleapis.com/projects/cesta-dev/topics/billing-kill-switch")
	e.SetType("google.cloud.pubsub.topic.v1.messagePublished")
	envelope := map[string]any{"message": map[string]any{"data": []byte(notification)}}
	if err := e.SetData(event.ApplicationJSON, envelope); err != nil {
		t.Fatal(err)
	}
	return e
}

func newHandler(b killswitch.Billing) killswitch.Handler {
	return killswitch.Handler{ProjectID: "cesta-dev", Billing: b, Logger: slog.New(slog.DiscardHandler)}
}

func TestDetachesBillingWhenCostReachesTheLimit(t *testing.T) {
	b := &fakeBilling{enabled: true}
	h := newHandler(b)

	err := h.Handle(context.Background(), budgetEvent(t,
		`{"budgetDisplayName":"cesta-dev kill switch","costAmount":20.01,"budgetAmount":20,"currencyCode":"USD"}`))
	if err != nil {
		t.Fatalf("Handle: %v", err)
	}

	if len(b.detached) != 1 || b.detached[0] != "cesta-dev" {
		t.Errorf("detached = %v, want [cesta-dev]", b.detached)
	}
}

func TestLeavesBillingAloneWhileCostIsUnderTheLimit(t *testing.T) {
	b := &fakeBilling{enabled: true}
	h := newHandler(b)

	err := h.Handle(context.Background(), budgetEvent(t,
		`{"budgetDisplayName":"cesta-dev kill switch","costAmount":19.99,"budgetAmount":20,"currencyCode":"USD"}`))
	if err != nil {
		t.Fatalf("Handle: %v", err)
	}

	if len(b.detached) != 0 {
		t.Errorf("detached = %v, want none", b.detached)
	}
}

func TestDoesNothingWhenBillingIsAlreadyDetached(t *testing.T) {
	b := &fakeBilling{enabled: false}
	h := newHandler(b)

	err := h.Handle(context.Background(), budgetEvent(t,
		`{"budgetDisplayName":"cesta-dev kill switch","costAmount":50,"budgetAmount":20,"currencyCode":"USD"}`))
	if err != nil {
		t.Fatalf("Handle: %v", err)
	}

	if len(b.detached) != 0 {
		t.Errorf("detached = %v, want none", b.detached)
	}
}

func TestRejectsAMessageThatIsNotABudgetNotification(t *testing.T) {
	b := &fakeBilling{enabled: true}
	h := newHandler(b)

	for _, data := range []string{`not json`, `{"costAmount":50}`} {
		if err := h.Handle(context.Background(), budgetEvent(t, data)); err == nil {
			t.Errorf("Handle(%s) = nil, want error", data)
		}
	}
	if len(b.detached) != 0 {
		t.Errorf("detached = %v, want none", b.detached)
	}
}
