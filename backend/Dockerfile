# Build context: the backend/ directory. The OpenAPI contract is embedded in the
# generated code (internal/httpapi/openapi.gen.go), so api/ is not needed here.
FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/cesta ./cmd/cesta

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/cesta /cesta
EXPOSE 8080
ENTRYPOINT ["/cesta"]
CMD ["serve"]
