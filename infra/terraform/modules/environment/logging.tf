# LGPD (ADR-0005): Cloud Run request logs record each client's IP address and user agent,
# and the _Default log bucket is global. They are not stored; requests are covered by
# traces, which drop those attributes (backend/internal/platform/telemetry).
resource "google_logging_project_exclusion" "run_request_logs" {
  project     = var.project_id
  name        = "cloud-run-request-logs"
  description = "Client IPs and user agents in Cloud Run request logs must not leave Brazil."
  filter      = "log_id(\"run.googleapis.com/requests\")"
}
