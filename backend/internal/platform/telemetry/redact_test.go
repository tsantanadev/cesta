package telemetry_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"

	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
)

func TestRedactingExporterDropsPersonalDataFromHTTPServerSpans(t *testing.T) {
	mem := tracetest.NewInMemoryExporter()
	tp := sdktrace.NewTracerProvider(sdktrace.WithSyncer(telemetry.RedactingExporter(mem)))
	t.Cleanup(func() { _ = tp.Shutdown(context.Background()) })
	h := otelhttp.NewHandler(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}), "http.server",
		otelhttp.WithTracerProvider(tp))

	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/health", nil)
	req.RemoteAddr = "203.0.113.7:51234"
	req.Header.Set("X-Forwarded-For", "198.51.100.23")
	req.Header.Set("User-Agent", "Cesta/1.0 (iPhone; iOS 26.1)")
	h.ServeHTTP(httptest.NewRecorder(), req)

	spans := mem.GetSpans()
	if len(spans) != 1 {
		t.Fatalf("got %d spans, want 1", len(spans))
	}
	attrs := map[string]string{}
	for _, kv := range spans[0].Attributes {
		attrs[string(kv.Key)] = kv.Value.String()
	}
	for _, key := range []string{"client.address", "network.peer.address", "network.peer.port", "user_agent.original"} {
		if v, ok := attrs[key]; ok {
			t.Errorf("%s = %q was exported, want it dropped", key, v)
		}
	}
	if attrs["http.request.method"] != "GET" || attrs["url.path"] != "/health" {
		t.Errorf("non-personal attributes must survive, got %v", attrs)
	}
}
