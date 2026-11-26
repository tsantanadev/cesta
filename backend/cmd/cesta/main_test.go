package main

import (
	"bytes"
	"encoding/json"
	"testing"
)

func TestNewLoggerEmitsAlignedServiceName(t *testing.T) {
	var buf bytes.Buffer
	logger := newLogger(&buf, "info")
	logger.Info("started")

	var rec map[string]any
	if err := json.Unmarshal(buf.Bytes(), &rec); err != nil {
		t.Fatalf("log line is not JSON: %v\n%s", err, buf.Bytes())
	}
	if rec["service"] != "cesta-backend" {
		t.Errorf("service = %v, want cesta-backend", rec["service"])
	}
}
