// Package notify tells people about things by email: for now, that they were
// sent an Invitation. It writes each message in the language the sender chose
// (the Owner's app language: English or Brazilian Portuguese), since the
// recipient may not have the app yet, and hands it to an email.Sender (Resend
// in production, a fake in tests).
package notify

import (
	"bytes"
	"context"
	"fmt"
	"html/template"
	"time"

	"github.com/tsantanadev/cesta/backend/internal/platform/email"
)

// InvitationLinkBase is where an Invitation's deep link points; the token follows it.
// The app opens these links (iOS Associated Domains, Android App Links), and
// Firebase Hosting serves a fallback page for a browser without the app.
const InvitationLinkBase = "https://cesta.tsantana.dev/invite/"

// InvitationLink returns the deep link for an Invitation's token.
func InvitationLink(token string) string { return InvitationLinkBase + token }

// Language is a language an email can be written in.
type Language string

// The languages emails are written in.
const (
	English    Language = "en"
	Portuguese Language = "pt-BR"
)

// Invitation is what the email about an Invitation says.
type Invitation struct {
	To          string
	InviterName string
	ListName    string
	Token       string
	ExpiresAt   time.Time
	Language    Language
}

// Notifier sends notification emails.
type Notifier struct {
	sender email.Sender
}

// New returns a Notifier that sends through sender.
func New(sender email.Sender) *Notifier { return &Notifier{sender: sender} }

// Invited emails inv.To the Invitation's deep link.
func (n *Notifier) Invited(ctx context.Context, inv Invitation) error {
	msg, err := invitationMessage(inv)
	if err != nil {
		return err
	}
	if err := n.sender.Send(ctx, msg); err != nil {
		return fmt.Errorf("notify: send invitation: %w", err)
	}
	return nil
}

type invitationCopy struct {
	subject, intro, open, expiry, ignore, dateLayout string
}

var invitationCopies = map[Language]invitationCopy{
	English: {
		subject:    "%s invited you to the List %s on Cesta",
		intro:      "%s invited you to shop together from the List “%s” on Cesta.",
		open:       "Open the Invitation in the app",
		expiry:     "The link works once and expires on %s.",
		ignore:     "If you weren't expecting this, you can ignore this email.",
		dateLayout: "2 January 2006",
	},
	Portuguese: {
		subject:    "%s convidou você para a lista %s no Cesta",
		intro:      "%s convidou você para fazer compras juntos com a lista “%s” no Cesta.",
		open:       "Abra o convite no app",
		expiry:     "O link funciona uma vez e expira em %s.",
		ignore:     "Se você não esperava este convite, pode ignorar este e-mail.",
		dateLayout: "02/01/2006",
	},
}

var invitationHTML = template.Must(template.New("invitation").Parse(`<!doctype html>
<html lang="{{.Lang}}"><body style="font-family: sans-serif; line-height: 1.5">
<p>{{.Intro}}</p>
<p><a href="{{.Link}}">{{.Open}}</a></p>
<p style="color: #666">{{.Expiry}}<br>{{.Ignore}}</p>
<p style="color: #666; font-size: 12px">{{.Link}}</p>
</body></html>
`))

func invitationMessage(inv Invitation) (email.Message, error) {
	c, ok := invitationCopies[inv.Language]
	if !ok {
		return email.Message{}, fmt.Errorf("notify: no copy in language %q", inv.Language)
	}
	link := InvitationLink(inv.Token)
	intro := fmt.Sprintf(c.intro, inv.InviterName, inv.ListName)
	expiry := fmt.Sprintf(c.expiry, inv.ExpiresAt.UTC().Format(c.dateLayout))
	var html bytes.Buffer
	if err := invitationHTML.Execute(&html, map[string]string{
		"Lang": string(inv.Language), "Intro": intro, "Link": link, "Open": c.open,
		"Expiry": expiry, "Ignore": c.ignore,
	}); err != nil {
		return email.Message{}, fmt.Errorf("notify: render invitation: %w", err)
	}
	return email.Message{
		To:      inv.To,
		Subject: fmt.Sprintf(c.subject, inv.InviterName, inv.ListName),
		Text:    intro + "\n\n" + c.open + ":\n" + link + "\n\n" + expiry + "\n" + c.ignore + "\n",
		HTML:    html.String(),
	}, nil
}
