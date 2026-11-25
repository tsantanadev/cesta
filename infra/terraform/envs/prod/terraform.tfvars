# Not secret. The billing account and alert email live in the gitignored
# private.auto.tfvars (see private.auto.tfvars.example and infra/README.md).
project_id = "cesta-prod"

# The billing account bills in BRL. About US$10 and US$40.
budget_currency   = "BRL"
budget_amount     = 50
kill_switch_limit = 200

otel_exporter_otlp_endpoint = "https://otlp-gateway-prod-sa-east-1.grafana.net/otlp"
