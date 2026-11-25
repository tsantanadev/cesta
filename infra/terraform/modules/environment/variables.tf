variable "environment" {
  description = "Environment name: dev or prod."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "project_id" {
  description = "GCP project for this environment. Created by hand, with billing linked."
  type        = string
}

variable "region" {
  description = "GCP region for everything regional (ADR-0005)."
  type        = string
  default     = "southamerica-east1"
}

variable "domain" {
  description = "Custom domain Firebase Hosting serves the API on, e.g. cesta-dev.tsantana.dev."
  type        = string
}

variable "github_repository_id" {
  description = "Numeric GitHub repository ID allowed to deploy through OIDC (survives renames, can't be reused)."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account the budgets are created on, e.g. 0X0X0X-0X0X0X-0X0X0X."
  type        = string
}

variable "budget_currency" {
  description = "Currency of the billing account. Budgets must use it."
  type        = string
  default     = "USD"
}

variable "budget_amount" {
  description = "Monthly budget that sends email alerts at 50%, 90% and 100%."
  type        = number
  default     = 5
}

variable "alert_email" {
  description = "Email address that receives budget alerts."
  type        = string
}

variable "kill_switch_enabled" {
  description = "Detach billing from the project when spend reaches kill_switch_limit."
  type        = bool
}

variable "kill_switch_limit" {
  description = "Monthly spend at which the kill switch detaches billing."
  type        = number
  default     = 20
}

variable "otel_exporter_otlp_endpoint" {
  description = "Grafana Cloud OTLP gateway, e.g. https://otlp-gateway-prod-sa-east-1.grafana.net/otlp."
  type        = string
}

variable "log_level" {
  description = "Backend LOG_LEVEL."
  type        = string
  default     = "info"
}

variable "image_reader_members" {
  description = "Extra principals allowed to pull from this environment's image repository (prod's deployer, on dev)."
  type        = list(string)
  default     = []
}

variable "function_runtime" {
  description = "Cloud Functions runtime for the kill switch. Keep in step with its go.mod."
  type        = string
  default     = "go126"
}
