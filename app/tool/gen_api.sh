#!/usr/bin/env bash
# Regenerates the Dart API client in lib/src/api/generated from ../api/openapi.yaml.
# Usage: tool/gen_api.sh          # regenerate
#        tool/gen_api.sh --check  # exit 1 if the committed client is out of date
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${1:-}" == "--check" ]]; then
  dart run swagger_parser --check -f swagger_parser.yaml
else
  dart run swagger_parser -f swagger_parser.yaml
fi
