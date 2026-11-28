#!/usr/bin/env bash
# Smoke test after a deploy: the API answers through Firebase Hosting, and the
# default run.app URL, which bypasses Hosting, does not reach the backend.
# Usage: smoke-test.sh https://cesta-dev.tsantana.dev   (needs gcloud, authenticated)
set -euo pipefail

public_url=$1
region=${REGION:-southamerica-east1}

echo "GET ${public_url}/health"
curl --fail --silent --show-error --retry 5 --retry-delay 5 --retry-all-errors "${public_url}/health"
echo

# Deep links (#41): the .well-known files are JSON, and /invite/<token> serves the fallback page.
expect_type() {
  local url=$1 want=$2 got
  got=$(curl --fail --silent --show-error --output /dev/null --write-out '%{content_type}' "$url")
  echo "GET ${url} -> ${got}"
  if [[ "$got" != "$want"* ]]; then
    echo "::error::${url} served ${got}, want ${want}"
    exit 1
  fi
}
expect_type "${public_url}/.well-known/apple-app-site-association" application/json
expect_type "${public_url}/.well-known/assetlinks.json" application/json
expect_type "${public_url}/invite/smoke-test" text/html

run_url=$(gcloud run services describe cesta-backend --region "$region" --format 'value(status.url)')
status=$(curl --silent --output /dev/null --write-out '%{http_code}' "${run_url}/health")
echo "GET ${run_url}/health -> ${status}"
if [[ "$status" != "404" ]]; then
  echo "::error::the run.app URL answered ${status}; requests that bypass Firebase Hosting must get 404"
  exit 1
fi
