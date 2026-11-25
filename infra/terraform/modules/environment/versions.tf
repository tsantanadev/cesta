terraform {
  required_version = ">= 1.17"

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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}
