# Cost protection (ADR-0005): an email budget, and a hard-limit budget that publishes
# to Pub/Sub so the kill switch function can detach billing from the project.

resource "google_monitoring_notification_channel" "budget_email" {
  project      = var.project_id
  display_name = "Budget alerts"
  type         = "email"
  labels = {
    email_address = var.alert_email
  }
  depends_on = [google_project_service.apis]
}

resource "google_billing_budget" "monthly" {
  billing_account = var.billing_account_id
  display_name    = "cesta-${var.environment} monthly"

  budget_filter {
    projects        = ["projects/${data.google_project.this.number}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.9, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.budget_email.id]
    disable_default_iam_recipients   = false
  }

  depends_on = [google_project_service.apis]
}

# --- Kill switch --------------------------------------------------------------------

resource "google_pubsub_topic" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  project    = var.project_id
  name       = "billing-kill-switch"
  depends_on = [google_project_service.apis]
}

resource "google_billing_budget" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "cesta-${var.environment} kill switch"

  budget_filter {
    projects        = ["projects/${data.google_project.this.number}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.kill_switch_limit)
    }
  }

  all_updates_rule {
    pubsub_topic                   = google_pubsub_topic.kill_switch[0].id
    schema_version                 = "1.0"
    disable_default_iam_recipients = true
  }
}

resource "google_service_account" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  project      = var.project_id
  account_id   = "cesta-kill-switch"
  display_name = "Billing kill switch (function and its trigger)"
  depends_on   = [google_project_service.apis]
}

resource "google_service_account" "kill_switch_builder" {
  count = var.kill_switch_enabled ? 1 : 0

  project      = var.project_id
  account_id   = "cesta-kill-switch-builder"
  display_name = "Builds the billing kill switch function"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "kill_switch" {
  for_each = var.kill_switch_enabled ? toset([
    "roles/billing.projectManager",            # read and detach the project's billing account
    "roles/eventarc.eventReceiver",            # receive the Pub/Sub trigger
    "roles/serviceusage.serviceUsageConsumer", # Eventarc checks the trigger's account may use the project
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = google_service_account.kill_switch[0].member
}

# billing.projectManager only attaches and detaches billing accounts; reading a project's
# billing info also needs resourcemanager.projects.get.
resource "google_project_iam_custom_role" "kill_switch_project_reader" {
  count = var.kill_switch_enabled ? 1 : 0

  project     = var.project_id
  role_id     = "killSwitchProjectReader"
  title       = "Kill switch project reader"
  permissions = ["resourcemanager.projects.get"]
}

resource "google_project_iam_member" "kill_switch_project_reader" {
  count = var.kill_switch_enabled ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.kill_switch_project_reader[0].id
  member  = google_service_account.kill_switch[0].member
}

resource "google_project_iam_member" "kill_switch_builder" {
  count = var.kill_switch_enabled ? 1 : 0

  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = google_service_account.kill_switch_builder[0].member
}

data "archive_file" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/../../../functions/billing-kill-switch"
  excludes    = ["*_test.go"]
  output_path = "${path.root}/.terraform/tmp/billing-kill-switch.zip"
}

resource "google_storage_bucket" "functions" {
  count = var.kill_switch_enabled ? 1 : 0

  project                     = var.project_id
  name                        = "${var.project_id}-functions"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  depends_on                  = [google_project_service.apis]
}

resource "google_storage_bucket_object" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  bucket = google_storage_bucket.functions[0].name
  name   = "billing-kill-switch-${data.archive_file.kill_switch[0].output_md5}.zip"
  source = data.archive_file.kill_switch[0].output_path
}

resource "google_cloudfunctions2_function" "kill_switch" {
  count = var.kill_switch_enabled ? 1 : 0

  project     = var.project_id
  name        = "billing-kill-switch"
  location    = var.region
  description = "Detaches billing when spend reaches ${var.kill_switch_limit} ${var.budget_currency}."

  build_config {
    runtime         = var.function_runtime
    entry_point     = "DetachBilling"
    service_account = google_service_account.kill_switch_builder[0].id
    source {
      storage_source {
        bucket = google_storage_bucket.functions[0].name
        object = google_storage_bucket_object.kill_switch[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "128Mi"
    timeout_seconds       = 60
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.kill_switch[0].email
    environment_variables = {
      PROJECT_ID = var.project_id
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.kill_switch[0].id
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.kill_switch[0].email
  }

  # Eventarc checks the trigger's roles when the function is created.
  depends_on = [google_project_iam_member.kill_switch_builder, google_project_iam_member.kill_switch]
}

# The trigger's service account must be allowed to invoke the function's service.
resource "google_cloud_run_v2_service_iam_member" "kill_switch_invoker" {
  count = var.kill_switch_enabled ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloudfunctions2_function.kill_switch[0].service_config[0].service
  role     = "roles/run.invoker"
  member   = google_service_account.kill_switch[0].member
}
