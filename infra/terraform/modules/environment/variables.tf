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

variable "rate_limit_per_ip" {
  description = "Backend RATE_LIMIT_PER_IP, as <burst>/<every>."
  type        = string
  default     = "120/250ms"
}

variable "rate_limit_per_user" {
  description = "Backend RATE_LIMIT_PER_USER, as <burst>/<every>."
  type        = string
  default     = "60/500ms"
}

variable "max_lists_per_user" {
  description = "Backend MAX_LISTS_PER_USER: live Lists a User can own."
  type        = number
  default     = 100
  validation {
    condition     = var.max_lists_per_user > 0 && floor(var.max_lists_per_user) == var.max_lists_per_user
    error_message = "max_lists_per_user must be a positive integer."
  }
}

variable "max_items_per_list" {
  description = "Backend MAX_ITEMS_PER_LIST: Items a List can hold."
  type        = number
  default     = 500
  validation {
    condition     = var.max_items_per_list > 0 && floor(var.max_items_per_list) == var.max_items_per_list
    error_message = "max_items_per_list must be a positive integer."
  }
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

variable "app_id" {
  description = "Android application ID and iOS bundle ID of the Cesta app."
  type        = string
  default     = "dev.tsantana.cesta"
}

variable "android_sha1_hashes" {
  description = "SHA-1 fingerprints of the keys that sign Android builds (debug and release). Needed for Google sign-in."
  type        = list(string)
  default     = []
}

variable "android_sha256_hashes" {
  description = "SHA-256 fingerprints of the keys that sign Android builds. Needed for App Links later."
  type        = list(string)
  default     = []
}

variable "apple_team_id" {
  description = "Apple Developer team ID that signs iOS builds. Optional until App Links / Universal Links."
  type        = string
  default     = null
}
