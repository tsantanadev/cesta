package app

import (
	"context"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/metric/metricdata"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"

	"github.com/tsantanadev/cesta/backend/internal/httpapi"
)

type okPinger struct{}

func (okPinger) Ping(context.Context) error { return nil }

func setupTestTelemetry(t *testing.T) (*tracetest.InMemoryExporter, *sdkmetric.ManualReader) {
	t.Helper()
	prevTP := otel.GetTracerProvider()
	prevMP := otel.GetMeterProvider()

	mem := tracetest.NewInMemoryExporter()
	tp := sdktrace.NewTracerProvider(sdktrace.WithSyncer(mem))
	reader := sdkmetric.NewManualReader()
	mp := sdkmetric.NewMeterProvider(sdkmetric.WithReader(reader))

	otel.SetTracerProvider(tp)
	otel.SetMeterProvider(mp)
	t.Cleanup(func() {
		otel.SetTracerProvider(prevTP)
		otel.SetMeterProvider(prevMP)
		_ = tp.Shutdown(context.Background())
		_ = mp.Shutdown(context.Background())
	})
	return mem, reader
}

func spanAttrs(span tracetest.SpanStub) map[string]string {
	attrs := make(map[string]string, len(span.Attributes))
	for _, kv := range span.Attributes {
		attrs[string(kv.Key)] = kv.Value.String()
	}
	return attrs
}

func TestInstrumentHTTPNamesSpansAndTagsMatchedRoute(t *testing.T) {
	mem, reader := setupTestTelemetry(t)

	api := &httpapi.Server{DB: okPinger{}, Logger: slog.New(slog.DiscardHandler)}
	h := instrumentHTTP(api.Handler())

	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/health", nil)
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}

	spans := mem.GetSpans()
	if len(spans) != 1 {
		t.Fatalf("got %d spans, want 1", len(spans))
	}
	if spans[0].Name != "GET /health" {
		t.Errorf("span name = %q, want %q", spans[0].Name, "GET /health")
	}
	attrs := spanAttrs(spans[0])
	if attrs["http.route"] != "/health" {
		t.Errorf("http.route = %q, want %q (attrs: %v)", attrs["http.route"], "/health", attrs)
	}

	var rm metricdata.ResourceMetrics
	if err := reader.Collect(t.Context(), &rm); err != nil {
		t.Fatalf("collect metrics: %v", err)
	}
	wantRoute := attribute.String("http.route", "/health")
	foundMetricRoute := false
	for _, sm := range rm.ScopeMetrics {
		for _, m := range sm.Metrics {
			if m.Name != "http.server.request.duration" {
				continue
			}
			hist, ok := m.Data.(metricdata.Histogram[float64])
			if !ok {
				t.Fatalf("unexpected metric data type %T", m.Data)
			}
			for _, dp := range hist.DataPoints {
				if dp.Attributes.HasValue(wantRoute.Key) {
					v, _ := dp.Attributes.Value(wantRoute.Key)
					if v == wantRoute.Value {
						foundMetricRoute = true
					}
				}
			}
		}
	}
	if !foundMetricRoute {
		t.Errorf("http.server.request.duration metric missing %v", wantRoute)
	}
}

func TestInstrumentHTTPUsesRouteTemplateAndSkipsUnmatchedRoutes(t *testing.T) {
	mem, _ := setupTestTelemetry(t)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/lists/{id}", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	h := instrumentHTTP(mux)

	t.Run("parameterized route", func(t *testing.T) {
		mem.Reset()
		rec := httptest.NewRecorder()
		req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/api/lists/abc-123", nil)
		h.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
		}
		spans := mem.GetSpans()
		if len(spans) != 1 {
			t.Fatalf("got %d spans, want 1", len(spans))
		}
		if spans[0].Name != "GET /api/lists/{id}" {
			t.Errorf("span name = %q, want %q", spans[0].Name, "GET /api/lists/{id}")
		}
		if got := spanAttrs(spans[0])["http.route"]; got != "/api/lists/{id}" {
			t.Errorf("http.route = %q, want %q", got, "/api/lists/{id}")
		}
	})

	t.Run("unmatched route", func(t *testing.T) {
		mem.Reset()
		rec := httptest.NewRecorder()
		req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/does-not-exist", nil)
		h.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("status = %d, want %d", rec.Code, http.StatusNotFound)
		}
		spans := mem.GetSpans()
		if len(spans) != 1 {
			t.Fatalf("got %d spans, want 1", len(spans))
		}
		if spans[0].Name != "GET" {
			t.Errorf("span name = %q, want %q", spans[0].Name, "GET")
		}
		if got, ok := spanAttrs(spans[0])["http.route"]; ok {
			t.Errorf("http.route = %q on unmatched 404 route, want omitted", got)
		}
	})
}
