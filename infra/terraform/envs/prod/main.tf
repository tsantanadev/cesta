# The prod environment. Apply by hand (infra/README.md); CI only deploys images.

terraform {
  required_version = ">= 1.17"

  # bucket comes from backend.hcl: terraform init -backend-config=backend.hcl
  backend "gcs" {
    prefix = "cesta/prod"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.12"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.12"
    }
    neon = {
      source  = "kislerdm/neon"
      version = "0.18.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "budget_currency" {
  description = "The billing account's currency. Budgets must use it."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget that sends email alerts at 50%, 90% and 100%, in budget_currency."
  type        = number
}

variable "kill_switch_limit" {
  description = "Monthly spend at which billing is detached, in budget_currency."
  type        = number
}

variable "alert_email" {
  type = string
}

variable "otel_exporter_otlp_endpoint" {
  type = string
}

provider "google" {
  project               = var.project_id
  region                = "southamerica-east1"
  user_project_override = true # budgets and Firebase bill API quota to this project
  billing_project       = var.project_id
}

provider "google-beta" {
  project               = var.project_id
  region                = "southamerica-east1"
  user_project_override = true
  billing_project       = var.project_id
}

# Hand-created Neon API key, scoped to this environment's Neon project (infra/README.md).
data "google_secret_manager_secret_version" "neon_api_key" {
  project = var.project_id
  secret  = "neon-api-key"
}

provider "neon" {
  api_key = data.google_secret_manager_secret_version.neon_api_key.secret_data
}

# Created in the Neon console; the API key is scoped to this project.
import {
  to = module.environment.neon_project.this
  id = "spring-art-89548276"
}

module "environment" {
  source = "../../modules/environment"

  environment                 = "prod"
  project_id                  = var.project_id
  domain                      = "cesta.tsantana.dev"
  github_repository_id        = "1467899575" # tsantanadev/cesta
  billing_account_id          = var.billing_account_id
  budget_currency             = var.budget_currency
  budget_amount               = var.budget_amount
  kill_switch_limit           = var.kill_switch_limit
  alert_email                 = var.alert_email
  otel_exporter_otlp_endpoint = var.otel_exporter_otlp_endpoint
  kill_switch_enabled         = true # on until public launch (issue #4)
  log_level                   = "info"

}

output "github_variables" {
  description = "Set these on the prod GitHub environment (infra/README.md)."
  value = {
    GCP_PROJECT_ID                 = var.project_id
    GCP_WORKLOAD_IDENTITY_PROVIDER = module.environment.workload_identity_provider
    GCP_DEPLOYER_SA                = module.environment.deployer_service_account
    IMAGE_REPOSITORY               = module.environment.image_repository
  }
}

output "required_dns_updates" {
  value = module.environment.required_dns_updates
}

output "service_url" {
  value = module.environment.service_url
}

output "kill_switch_topic" {
  value = module.environment.kill_switch_topic
}
