package killswitch

import (
	"context"
	"log/slog"
	"os"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"golang.org/x/oauth2/google"
)

// init registers the DetachBilling entry point. PROJECT_ID is set by Terraform.
func init() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	functions.CloudEvent("DetachBilling", func(ctx context.Context, e event.Event) error {
		client, err := google.DefaultClient(ctx, "https://www.googleapis.com/auth/cloud-billing")
		if err != nil {
			return err
		}
		h := Handler{ProjectID: os.Getenv("PROJECT_ID"), Billing: CloudBilling{Client: client}, Logger: logger}
		return h.Handle(ctx, e)
	})
}
