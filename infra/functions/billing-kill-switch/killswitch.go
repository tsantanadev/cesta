// Package killswitch is a Cloud Function that detaches billing from a project once its
// spend reaches a hard limit (ADR-0005). A Cloud Billing budget publishes notifications
// to Pub/Sub; when costAmount reaches budgetAmount, billing is detached and every paid
// service in the project stops. Re-linking billing is a manual step.
package killswitch

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"

	"github.com/cloudevents/sdk-go/v2/event"
)

// Billing reads and detaches a project's billing account.
type Billing interface {
	BillingEnabled(ctx context.Context, projectID string) (bool, error)
	DetachBilling(ctx context.Context, projectID string) error
}

// Handler handles budget notifications for one project.
type Handler struct {
	ProjectID string
	Billing   Billing
	Logger    *slog.Logger
}

// notification is a Cloud Billing budget notification (schema version 1.0).
type notification struct {
	BudgetDisplayName string  `json:"budgetDisplayName"`
	CostAmount        float64 `json:"costAmount"`
	BudgetAmount      float64 `json:"budgetAmount"`
	CurrencyCode      string  `json:"currencyCode"`
}

// pubsubEnvelope is the CloudEvent data Eventarc delivers for a Pub/Sub message.
type pubsubEnvelope struct {
	Message struct {
		Data []byte `json:"data"`
	} `json:"message"`
}

// Handle detaches billing when the notification's cost has reached its budget.
// A message that isn't a budget notification is logged and acknowledged, since
// retrying it can't help; only Billing API failures are returned for Pub/Sub to retry.
func (h Handler) Handle(ctx context.Context, e event.Event) error {
	n, err := decode(e)
	if err != nil {
		h.Logger.ErrorContext(ctx, "ignoring message", slog.String("error", err.Error()))
		return nil
	}

	log := h.Logger.With(slog.String("project", h.ProjectID), slog.String("budget", n.BudgetDisplayName),
		slog.Float64("cost", n.CostAmount), slog.Float64("limit", n.BudgetAmount), slog.String("currency", n.CurrencyCode))
	if n.CostAmount < n.BudgetAmount {
		log.InfoContext(ctx, "cost under limit")
		return nil
	}
	enabled, err := h.Billing.BillingEnabled(ctx, h.ProjectID)
	if err != nil {
		return fmt.Errorf("killswitch: read billing info: %w", err)
	}
	if !enabled {
		log.InfoContext(ctx, "billing already detached")
		return nil
	}
	if err := h.Billing.DetachBilling(ctx, h.ProjectID); err != nil {
		return fmt.Errorf("killswitch: detach billing: %w", err)
	}
	log.WarnContext(ctx, "cost reached limit: billing detached")
	return nil
}

func decode(e event.Event) (notification, error) {
	var env pubsubEnvelope
	if err := e.DataAs(&env); err != nil {
		return notification{}, fmt.Errorf("killswitch: decode pubsub event: %w", err)
	}
	var n notification
	if err := json.Unmarshal(env.Message.Data, &n); err != nil {
		return notification{}, fmt.Errorf("killswitch: decode budget notification: %w", err)
	}
	if n.BudgetAmount <= 0 {
		return notification{}, errors.New("killswitch: budget notification has no budgetAmount")
	}
	return n, nil
}
