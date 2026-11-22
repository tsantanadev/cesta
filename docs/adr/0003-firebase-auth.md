# Firebase Auth as the identity provider

We need email + password and Google sign-in without hand-rolling security-critical auth. Firebase Auth is free at our starting scale, has first-class Flutter SDKs and pairs with our GCP hosting. The Go backend only verifies Firebase ID tokens (JWTs) inside a single auth module and keeps its own User record keyed by an internal ID. Switching providers later (e.g. Zitadel or Ory) is therefore contained to that module plus a user migration.

## Considered Options

- **Auth0 / Clerk**: similar developer experience, but costs climb steeply with monthly active users.
- **Self-hosted Zitadel / Ory**: no lock-in, but adds operational burden we don't want at MVP.
