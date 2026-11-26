# cesta

A mobile grocery shopping list app where people build Lists, share them with others, and check Items off while shopping.

| Path | What |
| --- | --- |
| `api/openapi.yaml` | The API contract. Server and client code are generated from it. |
| `backend/` | Go backend (Postgres). Tasks live in `backend/Makefile`. |
| `app/` | Flutter app (Android and iOS). Scripts live in `app/tool/`. |
| `infra/`, `hosting/` | Terraform for dev and prod, the billing kill switch, Firebase Hosting config. See `infra/README.md`. |
| `GLOSSARY.md`, `docs/adr/` | Domain language and architecture decisions. |

## Prerequisites

- Go (version from `backend/go.mod`)
- Docker (for `make dev` and the backend tests)
- Flutter 3.50.1

## Backend

Run from `backend/`:

```sh
make dev     # Postgres + migrations + backend on http://localhost:8080 (check /health)
make down    # stop and delete the local database volume
```

| Task | Command |
| --- | --- |
| Tests, including Seam 1 (HTTP API against a real Postgres via testcontainers, needs Docker) | `make test` |
| Lint (golangci-lint) | `make lint` |
| Known vulnerabilities (govulncheck) | `make vuln` |
| Regenerate server code from `api/openapi.yaml` | `make generate` |
| Check generated code is up to date | `make generate-check` |

## App

Run from `app/`:

```sh
flutter pub get
flutter run                                                      # iOS simulator / desktop: backend at http://localhost:8080
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080      # Android emulator (10.0.2.2 is the host machine)
```

On a physical Android device, run `adb reverse tcp:8080 tcp:8080` and the default URL works over USB. On an iPhone, run `tool/run-iphone.sh`: it sets up signing with your Apple team, finds the phone and points the app at `http://<your Mac>.local:8080`. Debug builds allow plain HTTP to `*.local` hosts (`ios/scripts/cesta_build_phase.sh`); release builds don't.

Sign-in needs the Firebase config files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`), which `infra/auth-setup.sh dev` writes. Without them the app builds but stops at startup. The local backend (`make dev`) accepts ID tokens from the `cesta-dev` Firebase project.

| Task | Command |
| --- | --- |
| Tests, including Seam 2 (the real app with an in-memory database, a fake API client and a fake identity provider, `test/harness/`) | `flutter test` |
| Of those, `test/api_*_test.dart` cover the API transport (trace context, ID tokens and the refresh-and-retry on 401) against a fake HTTP adapter, since Seam 2 replaces the client it runs in | `flutter test test/api_*` |
| Analyze (lint) | `flutter analyze` |
| Format | `dart format .` |
| Regenerate the Dart API client, localizations and Drift code | `tool/codegen.sh` |
| Check generated code is up to date | `tool/codegen.sh --check` |

## Changing the API

1. Edit `api/openapi.yaml`.
2. In `backend/`, run `make generate`; in `app/`, run `tool/codegen.sh`.
3. Commit the regenerated code. CI fails if either side is out of date.

## CI

`.github/workflows/ci.yml` runs on every pull request and on pushes to `main`:

- `backend`: `make generate-check`, `make lint`, `make vuln`, `make test`
- `app`: `tool/codegen.sh --check`, `dart format` check, `flutter analyze`, `flutter test`
- `kill-switch`: lint and test `infra/functions/billing-kill-switch`
- `terraform`: `terraform fmt -check` and `terraform validate` for dev and prod
- `dependency-scan`: OSV-Scanner over the Go modules and `app/pubspec.lock`

`.github/workflows/deploy.yml` deploys to dev after CI passes on `main`, and to prod by hand. See `infra/README.md`.
