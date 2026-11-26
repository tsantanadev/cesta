# Build context: the backend/ directory. The OpenAPI contract is embedded in the
# generated code (internal/httpapi/openapi.gen.go), so api/ is not needed here.
# Base images are pinned by multi-arch OCI index digest (matching .github/workflows/)
# so local arm64 (`make dev`) and CI linux/amd64 both resolve native images.
FROM golang:1.27-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/cesta ./cmd/cesta

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/cesta /cesta
EXPOSE 8080
ENTRYPOINT ["/cesta"]
CMD ["serve"]
