# cesta

A mobile grocery shopping list app where people build Lists, share them with others, and check Items off while shopping.

| Path | What |
| --- | --- |
| `api/openapi.yaml` | The API contract. Server and client code are generated from it. |
| `backend/` | Go backend (Postgres). Tasks live in `backend/Makefile`. |
| `app/` | Flutter app (Android and iOS). Scripts live in `app/tool/`. |
| `GLOSSARY.md`, `docs/adr/` | Domain language and architecture decisions. |

## Prerequisites

- Go (version from `backend/go.mod`)
- Docker (for `make dev` and the backend tests)
- Flutter 3.50.1

## Backend

Run from `backend/`:

```sh
make dev     # Postgres + migrations + backend on http://localhost:8080 (check /healthz)
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

On a physical device, set `API_BASE_URL` to your machine's LAN address, e.g. `http://192.168.1.10:8080`.

| Task | Command |
| --- | --- |
| Tests, including Seam 2 (the real app with an in-memory database and a fake API client, `test/harness/`) | `flutter test` |
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
- `dependency-scan`: OSV-Scanner over `backend/go.mod` and `app/pubspec.lock`
