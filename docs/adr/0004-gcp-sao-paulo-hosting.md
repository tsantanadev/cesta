# Host on GCP in southamerica-east1

Superseded by ADR-0005.

The Go backend runs as a container on Cloud Run, backed by Cloud SQL for PostgreSQL. Everything lives in `southamerica-east1` (São Paulo). Cloud Run scales to zero, which keeps costs low while we start small, and GCP pairs with Firebase Auth (ADR-0003). The São Paulo region keeps personal data in Brazil for LGPD and keeps latency low for our primary users. All infrastructure is defined in Terraform across dev, staging and prod.

## Consequences

- Observability is OpenTelemetry-based and vendor-neutral (exported to Grafana Cloud), deliberately not tied to Cloud Monitoring, so the telemetry pipeline survives a hosting move.
- Any new data store or third-party processor of personal data has to be checked against the region and LGPD constraint.
