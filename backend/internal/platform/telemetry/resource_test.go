package telemetry_test

import (
	"context"
	"testing"

	"github.com/tsantanadev/cesta/backend/internal/platform/telemetry"
)

func resourceAttrs(t *testing.T) map[string]string {
	t.Helper()
	res, err := telemetry.NewResource(context.Background(), "cesta-backend", "abc123")
	if err != nil {
		t.Fatalf("NewResource: %v", err)
	}
	attrs := map[string]string{}
	for _, kv := range res.Attributes() {
		attrs[string(kv.Key)] = kv.Value.String()
	}
	return attrs
}

func TestResourceNamesTheServiceAndVersion(t *testing.T) {
	t.Setenv("OTEL_SERVICE_NAME", "")
	t.Setenv("OTEL_RESOURCE_ATTRIBUTES", "deployment.environment.name=dev")

	attrs := resourceAttrs(t)

	if attrs["service.name"] != "cesta-backend" {
		t.Errorf("service.name = %q, want cesta-backend", attrs["service.name"])
	}
	if attrs["service.version"] != "abc123" {
		t.Errorf("service.version = %q, want abc123", attrs["service.version"])
	}
	if attrs["deployment.environment.name"] != "dev" {
		t.Errorf("deployment.environment.name = %q, want dev (from OTEL_RESOURCE_ATTRIBUTES)", attrs["deployment.environment.name"])
	}
}

func TestResourceLetsTheEnvironmentOverrideTheServiceName(t *testing.T) {
	t.Setenv("OTEL_SERVICE_NAME", "cesta-backend-canary")

	attrs := resourceAttrs(t)

	if attrs["service.name"] != "cesta-backend-canary" {
		t.Errorf("service.name = %q, want cesta-backend-canary (OTEL_SERVICE_NAME wins)", attrs["service.name"])
	}
}
