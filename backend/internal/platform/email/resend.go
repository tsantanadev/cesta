package email

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"
)

// resendURL is Resend's API.
const resendURL = "https://api.resend.com"

// Resend sends email through Resend's HTTP API (https://resend.com/docs/api-reference/emails/send-email).
type Resend struct {
	apiKey string
	from   string
	url    string
	client *http.Client
}

// ResendOption configures a Resend sender.
type ResendOption func(*Resend)

// WithResendURL points the sender at another API base URL (tests).
func WithResendURL(url string) ResendOption { return func(r *Resend) { r.url = url } }

// NewResend returns a Sender that sends from (e.g. "Cesta <convites@cesta.tsantana.dev>")
// with the Resend API key apiKey.
func NewResend(apiKey, from string, opts ...ResendOption) *Resend {
	r := &Resend{apiKey: apiKey, from: from, url: resendURL, client: &http.Client{Timeout: 10 * time.Second}}
	for _, opt := range opts {
		opt(r)
	}
	return r
}

// Send delivers msg, failing on any response other than 2xx.
func (r *Resend) Send(ctx context.Context, msg Message) error {
	body, err := json.Marshal(map[string]any{
		"from": r.from, "to": []string{msg.To}, "subject": msg.Subject, "text": msg.Text, "html": msg.HTML,
	})
	if err != nil {
		return fmt.Errorf("resend: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.url+"/emails", bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("resend: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+r.apiKey)
	req.Header.Set("Content-Type", "application/json")
	res, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("resend: %w", err)
	}
	defer func() { _ = res.Body.Close() }()
	if res.StatusCode/100 != 2 {
		detail, _ := io.ReadAll(io.LimitReader(res.Body, 1<<10))
		return fmt.Errorf("resend: status %d: %s", res.StatusCode, bytes.TrimSpace(detail))
	}
	return nil
}

// Log is a Sender for local development: it logs each message's recipient and
// subject instead of sending it. The body (with any Invitation token) is logged
// only at debug level.
type Log struct {
	Logger *slog.Logger
}

// Send logs msg.
func (l Log) Send(ctx context.Context, msg Message) error {
	l.Logger.InfoContext(ctx, "email not sent (no RESEND_API_KEY)", slog.String("subject", msg.Subject))
	l.Logger.DebugContext(ctx, "email body", slog.String("text", msg.Text))
	return nil
}
