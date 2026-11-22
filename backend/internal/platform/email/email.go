// Package email defines how the backend sends transactional email.
package email

import "context"

// Message is a transactional email.
type Message struct {
	To      string
	Subject string
	Text    string
	HTML    string
}

// Sender delivers transactional email (Resend in production).
type Sender interface {
	Send(ctx context.Context, msg Message) error
}
