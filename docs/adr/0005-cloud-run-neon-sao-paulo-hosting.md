# Host on Cloud Run with Neon Postgres in São Paulo

Supersedes ADR-0004.

The Go backend runs as a container on Cloud Run in `southamerica-east1` (São Paulo), backed by Neon serverless Postgres in `aws-sa-east-1` (São Paulo). Both scale to zero and sit inside their free tiers at our starting scale, so hosting costs nothing until we have real traffic. Cloud SQL, the choice in ADR-0004, was the only fixed cost in that plan (about US$14/month per instance, with no free tier). Keeping both halves in São Paulo keeps personal data in Brazil for LGPD and keeps latency low for our primary users, at no extra cost. There are two environments, dev and prod, both defined in Terraform. Firebase Hosting sits in front of Cloud Run to serve the custom domains (`cesta.tsantana.dev` for prod, `cesta-dev.tsantana.dev` for dev) over HTTPS at no cost, along with the static `.well-known` files for app links.

## Considered Options

- **Cloud SQL for PostgreSQL**: rejected for now. It costs about US$14/month per instance in São Paulo, has no free tier, and the shared-core sizes have no SLA. It is still a straightforward move later, because only the connection string changes.
- **GKE (Kubernetes)**: rejected. The cluster fee plus always-on nodes or pods rule out a $0 bill, and it brings node, ingress and certificate operations we don't need for one stateless service. Cloud Run runs plain containers, so moving later means writing a Deployment for the same image. Revisit when we run several services, when steady traffic makes always-on compute cheaper, or when we need something Cloud Run can't do.
- **Supabase**: rejected. It is in `sa-east-1`, but the free plan pauses projects after 7 days of inactivity and allows only two of them, and the next tier is US$25/month. Its compute is TypeScript Edge Functions only, which can't run our Go backend.
- **Fly.io**: rejected. It has a São Paulo region (`gru`), but would also move compute off GCP for little saving, and its free allowance is small.
- **Hosting outside Brazil**: rejected. The platforms that only exist outside Brazil aren't cheaper than $0, and we'd pay later with a database migration and added latency.
- **Global HTTPS load balancer for the custom domain**: rejected. The forwarding rule alone costs about US$18/month. Firebase Hosting rewrites do the same job for free.

## Consequences

- **Data residency:** Firebase Auth stores account data in the US no matter what we choose. It is the one known exception to keeping personal data in Brazil. Any new data store or third-party processor of personal data still has to be checked against the region and LGPD constraint.
- **Cold starts:** the Neon free plan always sleeps compute after 5 minutes idle, so the first query after idle takes about 0.5–1 s longer. Offline-first sync (ADR-0001) hides this from users. Before public launch, review prod's plan: Neon pay-as-you-go with always-on compute, or Cloud SQL.
- **Connection strings:** each environment has two secrets in Secret Manager, `database-url` (Neon's pooled endpoint, used by the service) and `database-url-direct` (used for migrations, because goose holds a session-level lock).
- **Migrations:** `cesta migrate` runs as a Cloud Run Job on the same image before each service deploy. CI authenticates to GCP through OIDC and never holds database credentials.
- **Deploys:** merging to main deploys to dev. Prod is promoted manually with the same image digest that ran in dev.
- **Terraform:** it manages GCP, the Neon projects (via the `kislerdm/neon` provider), Firebase Hosting and a US$5/month billing budget alert. The Neon API key and the Grafana Cloud OTLP auth header are the only hand-created secrets, and both live in Secret Manager.
- **Limits:** Cloud Run runs with `min-instances=0` and `max-instances=2`, and the app's connection pool is capped at about 5, so a spike can't exceed the free tiers or Neon's connection limits. Raise these at launch.
- **DDoS and cost protection:** at our scale the main risk is the bill, not downtime. Firebase Hosting's edge absorbs network-level floods. `max-instances` caps compute, and the Neon free plan has no paid overage. Firebase App Check and early auth, size and rate limits in the backend reject bad requests before they reach the database. A budget-triggered kill switch detaches billing past a hard limit. Requests that bypass Firebase Hosting through the default `*.run.app` URL are blocked by the backend, which serves only requests whose `X-Forwarded-Host` is the custom domain. The default URL can't be disabled because Firebase Hosting rewrites go through it, and the header can be forged, so App Check is the real gate. Cloud Armor (which needs the paid load balancer) and Cloudflare (a new global processor, which needs an LGPD check) are deferred until we're actually attacked.
- **Observability:** it stays OpenTelemetry-based and vendor-neutral, exported to Grafana Cloud.
