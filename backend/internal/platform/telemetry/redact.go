package telemetry

import (
	"context"

	"go.opentelemetry.io/otel/attribute"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

// personalKeys are span attributes that identify a person (IP address, device) or
// may carry sensitive query parameters (tokens, emails). They are dropped before
// export so traces leave the service with no personal data (LGPD, ADR-0005).
var personalKeys = map[attribute.Key]bool{
	"client.address":       true,
	"network.peer.address": true,
	"network.peer.port":    true,
	"url.query":            true,
	"user_agent.original":  true,
}

// RedactingExporter wraps next so that personal span attributes are never exported.
func RedactingExporter(next sdktrace.SpanExporter) sdktrace.SpanExporter {
	return redactingExporter{next}
}

type redactingExporter struct{ sdktrace.SpanExporter }

func (e redactingExporter) ExportSpans(ctx context.Context, spans []sdktrace.ReadOnlySpan) error {
	out := make([]sdktrace.ReadOnlySpan, len(spans))
	for i, s := range spans {
		out[i] = redactedSpan{s}
	}
	return e.SpanExporter.ExportSpans(ctx, out)
}

type redactedSpan struct{ sdktrace.ReadOnlySpan }

func (s redactedSpan) Attributes() []attribute.KeyValue {
	all := s.ReadOnlySpan.Attributes()
	kept := make([]attribute.KeyValue, 0, len(all))
	for _, kv := range all {
		if !personalKeys[kv.Key] {
			kept = append(kept, kv)
		}
	}
	return kept
}
