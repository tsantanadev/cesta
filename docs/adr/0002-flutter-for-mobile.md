# Flutter for the mobile app

Cesta is mobile-only (iOS + Android) with a Go backend, so no option shares code with the server. We chose Flutter for one UI codebase with consistent rendering on both platforms, mature barcode scanning (needed for the future Shopping mode) and solid typed SQLite (Drift) for offline-first storage.

## Considered Options

- **React Native (TypeScript)**: the biggest ecosystem, but its offline-storage options are more fragmented, and the team has no existing React investment to reuse.
- **Kotlin Multiplatform**: native feel and shared logic, but iOS UI with Compose Multiplatform is less mature and demands more platform-specific work.
