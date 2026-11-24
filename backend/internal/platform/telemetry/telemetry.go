// Package telemetry configures OpenTelemetry traces and metrics.
//
// Export is off by default (no-op providers), so local runs and tests need no collector.
// Setting OTEL_EXPORTER_OTLP_ENDPOINT (e.g. Grafana Cloud's OTLP gateway) turns on
// OTLP/HTTP export of both traces and metrics. The exporters read the standard OTEL_*
// variables themselves (OTEL_EXPORTER_OTLP_HEADERS, OTEL_SERVICE_NAME, ...).
package telemetry

import (
	"context"
	"errors"
	"fmt"
	"os"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

// Shutdown flushes and stops telemetry export.
type Shutdown func(context.Context) error

// Enabled reports whether OTLP export is configured in the environment.
func Enabled() bool {
	return os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT") != "" ||
		os.Getenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT") != "" ||
		os.Getenv("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT") != ""
}

// Setup installs the global propagator and, when Enabled, OTLP trace and metric providers.
// The propagator is always W3C Trace Context so trace context sent by the app is honoured.
func Setup(ctx context.Context, serviceName, version string) (Shutdown, error) {
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{}, propagation.Baggage{},
	))
	if !Enabled() {
		return func(context.Context) error { return nil }, nil
	}

	// Schemaless so it merges with the SDK default resource whatever semconv version that uses.
	// resource.Default also applies OTEL_SERVICE_NAME and OTEL_RESOURCE_ATTRIBUTES, which win.
	res, err := resource.Merge(resource.NewSchemaless(
		semconv.ServiceName(serviceName),
		semconv.ServiceVersion(version),
	), resource.Default())
	if err != nil {
		return nil, fmt.Errorf("telemetry: resource: %w", err)
	}

	traceExp, err := otlptracehttp.New(ctx)
	if err != nil {
		return nil, fmt.Errorf("telemetry: trace exporter: %w", err)
	}
	tp := sdktrace.NewTracerProvider(sdktrace.WithBatcher(traceExp), sdktrace.WithResource(res))

	metricExp, err := otlpmetrichttp.New(ctx)
	if err != nil {
		return nil, errors.Join(fmt.Errorf("telemetry: metric exporter: %w", err), tp.Shutdown(ctx))
	}
	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricExp)),
		sdkmetric.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	otel.SetMeterProvider(mp)
	return func(ctx context.Context) error {
		return errors.Join(tp.Shutdown(ctx), mp.Shutdown(ctx))
	}, nil
}
