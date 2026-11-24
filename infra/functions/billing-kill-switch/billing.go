package killswitch

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
)

const cloudBillingAPI = "https://cloudbilling.googleapis.com/v1"

// CloudBilling is the Cloud Billing API, called with an authorised client.
type CloudBilling struct {
	Client *http.Client
}

var _ Billing = CloudBilling{}

// BillingEnabled reports whether the project has a billing account attached.
func (c CloudBilling) BillingEnabled(ctx context.Context, projectID string) (bool, error) {
	var info struct {
		BillingEnabled bool `json:"billingEnabled"`
	}
	err := c.call(ctx, http.MethodGet, projectID, nil, &info)
	return info.BillingEnabled, err
}

// DetachBilling sets the project's billing account to none.
func (c CloudBilling) DetachBilling(ctx context.Context, projectID string) error {
	return c.call(ctx, http.MethodPut, projectID, []byte(`{"billingAccountName":""}`), nil)
}

func (c CloudBilling) call(ctx context.Context, method, projectID string, body []byte, out any) error {
	u := cloudBillingAPI + "/projects/" + url.PathEscape(projectID) + "/billingInfo"
	req, err := http.NewRequestWithContext(ctx, method, u, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	res, err := c.Client.Do(req)
	if err != nil {
		return err
	}
	defer func() { _ = res.Body.Close() }()
	got, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("%s billingInfo: %s: %s", method, res.Status, got)
	}
	if out == nil {
		return nil
	}
	return json.Unmarshal(got, out)
}
