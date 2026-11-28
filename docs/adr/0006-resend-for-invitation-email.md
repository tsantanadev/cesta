# Send Invitation email through Resend

The backend sends transactional email, so far only Invitations (#9), through Resend's HTTP API (package `platform/email`). ADR-0005 says any new third-party processor of personal data has to be checked against the region and LGPD constraint. This ADR records that check.

## What Resend processes

Each Invitation email gives Resend:

- the invited email address, which may belong to someone who has no Cesta account yet;
- the inviter's display name and the List's name, in the subject and body;
- the Invitation link, whose token can accept the Invitation until it expires 14 days later, or until it is accepted, declined or cancelled.

Nothing else about the inviter, the invitee or the List leaves the backend.

## Region and residency

Resend sends from one region per domain: North Virginia, Ireland, São Paulo (`sa-east-1`) or Tokyo. The sending domain (`cesta.tsantana.dev`) is added in São Paulo (infra/README.md), so the mail goes out from Brazil. **But Resend stores all account data in the United States whatever the sending region, including email metadata and logs.** So like Firebase Auth (ADR-0005), Resend is a known exception to keeping personal data in Brazil.

## Decision

Accept the exception, and keep what Resend holds small and short-lived:

- Send only the data listed above. Never put an Invitation's token in a URL query string, header or tag that Resend indexes; it appears only in the email body.
- Never log an email's body on our side (the token is in it). Without a key (local dev only), `platform/email` logs the subject, which names the inviter and the List, and never the body.
- A leaked token stops working after 14 days at most, and as soon as the Invitation is accepted, declined or cancelled.
- The backend refuses to start without `RESEND_API_KEY` unless `EMAIL_LOG_ONLY=true` (local dev only), so a deployment can't seem to send Invitations that never left.

## Considered Options

- **Amazon SES in `sa-east-1`**: SES stores its data in the region it runs in, so it would keep email data in Brazil. Rejected for now: it needs an AWS account alongside GCP, IAM and sandbox approval before it can email anyone, and bounce handling built by hand. Revisit if Resend's US storage becomes a problem at launch.
- **Gmail or Google Workspace SMTP**: rejected. Workspace costs a fee per user, consumer Gmail limits daily sends and its terms don't cover app email, and neither keeps data in Brazil.

## Consequences

- The privacy notice has to list Resend as a processor whose data is stored in the United States, and state the basis for that transfer (LGPD art. 33), alongside Firebase Auth. **Not yet written: needs a decision before public launch.**
- If the domain has to move to another sending region, it has to be deleted from Resend and added again with new DNS records.
- On a plan where São Paulo isn't available, send from the closest region that is and record that here. Resend's docs disagree on whether the free plan can use it.
