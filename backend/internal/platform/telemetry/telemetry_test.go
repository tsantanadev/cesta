package telemetry_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/baggage"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	"go.opentelemetry.io/otel/trace"

	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
)

func TestSetupPropagatesTraceContextAndIgnoresBaggage(t *testing.T) {
	t.Setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")
	t.Setenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", "")
	t.Setenv("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT", "")

	prevProp := otel.GetTextMapPropagator()
	t.Cleanup(func() { otel.SetTextMapPropagator(prevProp) })

	shutdown, err := telemetry.Setup(t.Context(), "cesta-backend", "test")
	if err != nil {
		t.Fatalf("Setup: %v", err)
	}
	t.Cleanup(func() { _ = shutdown(context.Background()) })

	mem := tracetest.NewInMemoryExporter()
	tp := sdktrace.NewTracerProvider(sdktrace.WithSyncer(mem))
	t.Cleanup(func() { _ = tp.Shutdown(context.Background()) })

	var gotBaggage baggage.Baggage
	var gotSpanCtx trace.SpanContext
	h := otelhttp.NewHandler(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotBaggage = baggage.FromContext(r.Context())
		gotSpanCtx = trace.SpanContextFromContext(r.Context())
		w.WriteHeader(http.StatusOK)
	}), "", otelhttp.WithTracerProvider(tp))

	const (
		wantTraceID      = "4bf92f3577b34da6a3ce929d0e0e4736"
		wantParentSpanID = "00f067aa0ba902b7"
	)
	req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/health", nil)
	req.Header.Set("Traceparent", "00-"+wantTraceID+"-"+wantParentSpanID+"-01")
	req.Header.Set("Baggage", "user_id=attacker,admin=true")

	h.ServeHTTP(httptest.NewRecorder(), req)

	if !gotSpanCtx.IsValid() {
		t.Fatal("handler context has no valid span context")
	}
	if got := gotSpanCtx.TraceID().String(); got != wantTraceID {
		t.Errorf("trace_id = %q, want %q", got, wantTraceID)
	}
	if gotBaggage.Len() != 0 {
		t.Errorf("baggage = %q was propagated from untrusted header, want empty", gotBaggage.String())
	}

	spans := mem.GetSpans()
	if len(spans) != 1 {
		t.Fatalf("got %d spans, want 1", len(spans))
	}
	if got := spans[0].Parent.SpanID().String(); got != wantParentSpanID {
		t.Errorf("parent span_id = %q, want %q", got, wantParentSpanID)
	}
}
