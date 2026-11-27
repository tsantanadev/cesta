# Not secret. The billing account and alert email live in the gitignored
# private.auto.tfvars (see private.auto.tfvars.example and infra/README.md).
project_id      = "cesta-dev"
prod_project_id = "cesta-prod"

# The billing account bills in BRL. About US$10 and US$40.
budget_currency   = "BRL"
budget_amount     = 50
kill_switch_limit = 200

otel_exporter_otlp_endpoint = "https://otlp-gateway-prod-sa-east-1.grafana.net/otlp"
android_sha1_hashes         = ["c8d2c832f5295e8b09960fa75557af96c24a50b8"]
android_sha256_hashes       = ["639ce9be9687fcb43ed5dfce080071fe41308c4f38cb08d8cc1636a588168ee3"]
