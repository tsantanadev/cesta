# Offline-first sync with a server-authoritative, last-write-wins model

Members shop in supermarkets with poor signal, so the app must let them edit Lists and Items while offline. Each device keeps a local SQLite copy and an outbox of mutations. On reconnect it pushes the outbox to the server and pulls changes since its last cursor. The server is the single source of truth and resolves conflicts **last-write-wins per field**. A delete wins over concurrent edits. We chose this over CRDTs because it is predictable, easy to debug and enough for grocery-list data. Live sync (planned after MVP) only adds a server push of changes it has already applied, so the model doesn't change.

## Considered Options

- **CRDTs (e.g. Automerge/Yjs)**: rejected. Nothing is ever lost, but it brings heavy design and debugging cost and awkward server-side authorization for little user benefit.
- **Online-only**: rejected. Poor signal in stores makes it unusable.
- **Sync-as-a-service (PowerSync, ElectricSQL)**: not chosen for now, to keep the Go backend in control of authorization and avoid another vendor. Worth revisiting if hand-rolled sync becomes a burden.

## Consequences

- Every mutation carries a client-generated ID (for idempotent retries) and a timestamp, and every row carries a version/updated-at for cursoring.
- Authorization is re-checked on every pushed mutation. A device may hold mutations for a List the User was removed from, and those are rejected.

## Notes

- **2026-11-26 (#6):** Lists shipped online-only at first. The app caches the User's Lists so the Lists screen shows them offline, but creating, renaming, deleting and restoring a List need the network. List mutations move to the outbox with #7, which brings the outbox and sync. They already carry client-generated IDs, so creates retry idempotently.
- **2026-11-27 (#7):** Conflicts resolve last-write-wins per field in the order the server receives the mutations. The client timestamp each mutation carries is recorded only for diagnosis and never decides a conflict.
- **2026-11-27 (#7):** List mutations (create, rename, delete, restore) stay online-only for now. Contrary to the note above, #7 put only Item mutations in the outbox; moving List mutations there is left to a later ticket.
