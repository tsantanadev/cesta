# Infrastructure

Cloud Run + Neon in São Paulo, Firebase in front (ADR-0003, ADR-0005). Two environments, each in its own GCP project:

| | dev | prod |
| --- | --- | --- |
| URL | `https://cesta-dev.tsantana.dev` | `https://cesta.tsantana.dev` |
| Deploys | every push to `main` that passes CI | by hand, with the digest that ran in dev |
| Kill switch | on | on until public launch |

| Path | What |
| --- | --- |
| `terraform/modules/environment/` | Everything one environment needs: Cloud Run service, migrations job and daily purge job (Cloud Scheduler), Neon project, secrets, service accounts, CI identity (OIDC), Firebase Hosting and custom domain, budgets, kill switch. |
| `terraform/envs/{dev,prod}/` | Root modules. `terraform.tfvars` and `backend.hcl` hold the (non-secret) project settings. |
| `functions/billing-kill-switch/` | Cloud Function that detaches billing when spend reaches the hard limit. |
| `../hosting/` | `firebase.json` (rewrites `/api/**` and `/health` to Cloud Run, `/invite/**` to the store fallback page), the `.well-known` deep-link files, and `test/` (`node --test 'hosting/test/*.test.mjs'`). Values marked `REPLACE_ME_` (Apple team ID, Android signing SHA-256, App Store ID) are filled in once the store accounts exist. |
| `../.github/workflows/deploy.yml` | Build, migrate, deploy, smoke test. |

Terraform is applied by a person from a laptop. CI never runs Terraform and never sees a database credential: it authenticates through Workload Identity Federation as `cesta-deployer`, which can only push images, update the migrations and purge jobs and the service, and deploy Hosting.

## Secrets

All secrets live in Secret Manager, replicated only in `southamerica-east1`. Nothing secret is in the repo or in GitHub.

| Secret | Created by | Read by |
| --- | --- | --- |
| `neon-api-key` | hand | Terraform (Neon provider) |
| `otel-exporter-otlp-headers` | hand | backend (Grafana Cloud auth) |
| `resend-api-key` | hand | backend (`RESEND_API_KEY`: sends Invitation emails through Resend) |
| `database-url` | Terraform | backend (Neon pooled endpoint, `pool_max_conns=5`) |
| `database-url-direct` | Terraform | migrations job (goose needs a session-level lock) |

Terraform state holds the Neon credentials, so the state buckets are private, versioned and in São Paulo.

## First-time setup (per environment)

Tools: `gcloud`, Terraform 1.17.2. Replace `$PROJECT` with the environment's project ID. Do dev first, then prod.

1. **Project.** Create the GCP project and link it to the billing account:

   ```sh
   gcloud projects create $PROJECT
   gcloud billing projects link $PROJECT --billing-account=$BILLING_ACCOUNT
   ```

   If you already created the project from the Firebase console, keep it and import the Firebase resources before the first apply (step 5):

   ```sh
   terraform import module.environment.google_firebase_project.this projects/$PROJECT
   terraform import module.environment.google_firebase_hosting_site.default projects/$PROJECT/sites/$PROJECT
   ```

2. **State bucket.**

   ```sh
   gcloud storage buckets create gs://$PROJECT-tfstate --project=$PROJECT \
     --location=southamerica-east1 --uniform-bucket-level-access --public-access-prevention
   gcloud storage buckets update gs://$PROJECT-tfstate --versioning
   ```

3. **Neon project and hand-created secrets.** In the Neon console, create the project `cesta-<env>` in AWS São Paulo (`aws-sa-east-1`), Postgres 18, and a **project-scoped** API key for it. Terraform imports the project (the `import` block in `envs/<env>/main.tf` holds its ID); a project-scoped key can't create projects.

   ```sh
   # The first plan needs these before Terraform can enable the rest.
   gcloud services enable secretmanager.googleapis.com cloudresourcemanager.googleapis.com \
     serviceusage.googleapis.com --project=$PROJECT
   # Neon: the project's Settings → API keys (scoped to this project)
   printf '%s' "$NEON_API_KEY" | gcloud secrets create neon-api-key --project=$PROJECT \
     --replication-policy=user-managed --locations=southamerica-east1 --data-file=-
   # Grafana Cloud: stack → OpenTelemetry → generate a token (write traces, metrics).
   # The value is the OTLP header with the space URL-encoded:
   #   Authorization=Basic%20<base64 of "INSTANCE_ID:TOKEN">
   printf '%s' "$OTLP_HEADERS" | gcloud secrets create otel-exporter-otlp-headers --project=$PROJECT \
     --replication-policy=user-managed --locations=southamerica-east1 --data-file=-
   # Resend: verify the sending domain of EMAIL_FROM (default convites@cesta.tsantana.dev,
   # the module's email_from), then API Keys → create one with "Sending access" for that domain.
   printf '%s' "$RESEND_API_KEY" | gcloud secrets create resend-api-key --project=$PROJECT \
     --replication-policy=user-managed --locations=southamerica-east1 --data-file=-
   ```

   An environment set up before Invitations needs `resend-api-key` created the same way before its next `terraform apply`: the plan fails until it exists.

4. **Settings.** In `terraform/envs/<env>/`, check `terraform.tfvars` and `backend.hcl`, and copy `private.auto.tfvars.example` to `private.auto.tfvars` with the billing account ID and alert email. That file is gitignored because the repo is public. `budget_currency`, `budget_amount` and `kill_switch_limit` are in the billing account's currency (check it with `gcloud billing accounts describe`). Ours bills in BRL. The OTLP endpoint is shown on the same Grafana Cloud page as the token; pick the `sa-east-1` stack.

5. **Apply.** You need Owner on the project and Billing Account Costs Manager (or Administrator) on the billing account, for the budgets.

   ```sh
   gcloud auth application-default login
   cd terraform/envs/<env>
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

6. **DNS.** `terraform output required_dns_updates` lists the records for the custom domain. Create them at the DNS provider for `tsantana.dev`. Firebase verifies them and provisions the certificate; this can take up to a few hours.

7. **Sign-in.** Run `infra/auth-setup.sh <env>`. It adopts anything already made in the Firebase console, registers your Android signing key, applies Terraform (Email/Password sign-in, the Android and iOS apps, `modules/environment/auth.tf`), walks you through enabling **Google** in the console (Terraform can't create its OAuth client), and writes `google-services.json` and `GoogleService-Info.plist` into the app. The app uses dev's config until build flavors arrive. Crashlytics is turned on once the apps are registered.

8. **GitHub.** Settings → Environments: create `dev` and `prod`. Restrict both to the `main` branch, and add yourself as a required reviewer on `prod`. Add the values of `terraform output github_variables` as environment **variables** (they are not secrets). `prod` also needs `DEV_IMAGE_REPOSITORY`, set to dev's `IMAGE_REPOSITORY`.

9. **prod only.** Once prod is applied, set `prod_project_id` in `envs/dev/terraform.tfvars` and apply dev again. This lets prod's deployer copy images from dev.

## Deploying

- **dev:** merge to `main`. When CI passes, `deploy.yml` builds the image, runs `cesta migrate` as the `cesta-migrate` job, deploys `cesta-backend`, points the `cesta-purge` job at the new image, deploys Hosting, and runs `.github/scripts/smoke-test.sh`. The run summary shows the image digest.
- **prod:** Actions → Deploy → Run workflow, with that digest. The image is copied by digest into prod's registry, then prod runs the same steps. The job fails if the copy's digest differs. dev keeps only its 10 newest images, so promote before ten more merges land.

## Checks

- **Bypass:** the smoke test asserts that `<run.app URL>/health` answers 404. Cloud Run's default URL can't be turned off, because Firebase Hosting rewrites use it. Instead, the backend serves only requests whose `X-Forwarded-Host` is `PUBLIC_HOST`, which Firebase Hosting sets. Anyone can forge the header, so this stops scanners and casual bypass. Firebase App Check is the real gate. If the smoke test's first request (through Hosting) gets a 404, Hosting isn't sending the header as expected: check the header the backend received in the request logs.
- **Traces:** in Grafana Cloud → Explore → Tempo, query `{resource.service.name="cesta-backend"}`. The service sets `OTEL_TRACES_SAMPLER=always_on`; without it, Google's front end marks most requests "not sampled" and no spans are exported, with no errors either. Spans have no `client.address`, `network.peer.*` or `user_agent.original` (the backend drops them before export).
  Cloud Run throttles the CPU between requests, so spans are exported during later requests or when the instance shuts down. Expect them to show up a little late on an idle dev, not as each request finishes.
- **Kill switch (dev):** simulate a budget notification over the limit, then confirm billing is detached and re-link it:

  ```sh
  gcloud pubsub topics publish billing-kill-switch --project=$PROJECT \
    --message='{"budgetDisplayName":"simulated","costAmount":201,"budgetAmount":200,"currencyCode":"BRL"}'
  gcloud billing projects describe $PROJECT            # billingEnabled: false
  gcloud logging read 'resource.labels.service_name="billing-kill-switch"' --project=$PROJECT --limit=5
  gcloud billing projects link $PROJECT --billing-account=$BILLING_ACCOUNT
  ```

  Detaching billing stops every paid service in the project. After re-linking, run `terraform plan` to check nothing drifted.

## Cost

Idle, each environment sits inside the free tiers: Cloud Run and the function scale to zero, Neon's free plan has no overage, and Artifact Registry keeps at most 10 images. Two small exceptions: Secret Manager's 6 free secret versions are per billing account (both environments use 10, about US$0.24/month), and Cloud Storage in São Paulo has no free tier (the state and function buckets hold a few KB, so it rounds to $0).

## Known risks

- `database-url` and `database-url-direct` connect as `neondb_owner` to `neondb`, Neon's defaults for a console-created project.
- The `kislerdm/neon` provider was archived on 2026-09-11; v0.18.0 is its last release. It still works, but if the Neon API changes under it, move to Neon's own provider or manage the two projects by hand and keep only the secrets in Terraform.
- Disabling billing (kill switch) also downgrades Firebase to the Spark plan, and Hosting's Cloud Run rewrites stop until billing is re-linked.
