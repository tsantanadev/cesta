# Not secret. See infra/README.md.
project_id         = "cesta-prod"
billing_account_id = "01931C-8270EA-B0DBDB"
alert_email        = "thiago91098@gmail.com"

# The billing account bills in BRL. About US$10 and US$40.
budget_currency   = "BRL"
budget_amount     = 50
kill_switch_limit = 200

otel_exporter_otlp_endpoint = "https://otlp-gateway-prod-sa-east-1.grafana.net/otlp"
