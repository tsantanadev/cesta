package telemetry_test

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"testing"

	sdktrace "go.opentelemetry.io/otel/sdk/trace"

	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
)

func logLine(ctx context.Context, t *testing.T) map[string]any {
	t.Helper()
	var buf bytes.Buffer
	logger := slog.New(telemetry.LogHandler(slog.NewJSONHandler(&buf, nil))).With(slog.String("service", "cesta"))
	logger.InfoContext(ctx, "hello")
	var rec map[string]any
	if err := json.Unmarshal(buf.Bytes(), &rec); err != nil {
		t.Fatalf("log line is not JSON: %v\n%s", err, buf.Bytes())
	}
	return rec
}

func TestLogHandlerAddsTraceAndSpanIDsFromContext(t *testing.T) {
	tp := sdktrace.NewTracerProvider()
	t.Cleanup(func() { _ = tp.Shutdown(context.Background()) })
	ctx, span := tp.Tracer("test").Start(context.Background(), "op")
	defer span.End()

	rec := logLine(ctx, t)

	sc := span.SpanContext()
	if rec["trace_id"] != sc.TraceID().String() {
		t.Errorf("trace_id = %v, want %s", rec["trace_id"], sc.TraceID())
	}
	if rec["span_id"] != sc.SpanID().String() {
		t.Errorf("span_id = %v, want %s", rec["span_id"], sc.SpanID())
	}
	if rec["service"] != "cesta" {
		t.Errorf("service = %v, want cesta (attributes from With must survive)", rec["service"])
	}
}

func TestLogHandlerLeavesRecordsWithoutASpanAlone(t *testing.T) {
	rec := logLine(context.Background(), t)

	if _, ok := rec["trace_id"]; ok {
		t.Errorf("trace_id present without a span: %v", rec)
	}
	if _, ok := rec["span_id"]; ok {
		t.Errorf("span_id present without a span: %v", rec)
	}
}
