# Backend tasks. CI calls test, lint, vuln and generate-check.
GOLANGCI_LINT_VERSION := v2.15.0
GOLANGCI_LINT := go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

.PHONY: dev down build test lint vuln generate generate-check

## dev: build and run Postgres, migrations and the backend (http://localhost:8080/health)
dev:
	docker compose up --build

## down: stop local dev and delete its database volume
down:
	docker compose down -v

build:
	go build ./...

## test: run all tests, including Seam 1 (needs Docker for testcontainers)
test:
	go test -race -count=1 ./...

lint:
	$(GOLANGCI_LINT) run ./...

vuln:
	go tool govulncheck ./...

## generate: regenerate server code from ../api/openapi.yaml
generate:
	go generate ./...

## generate-check: fail if generated code is out of date with the API contract
generate-check: generate
	git diff --exit-code -- internal/httpapi/openapi.gen.go
