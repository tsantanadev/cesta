#!/usr/bin/env bash
# Regenerates every piece of generated code in the app, then formats it:
#   - Dart API client from ../api/openapi.yaml (tool/gen_api.sh)
#   - localizations from lib/l10n/*.arb (flutter gen-l10n)
#   - Drift database code (build_runner)
# Usage: tool/codegen.sh          # regenerate
#        tool/codegen.sh --check  # regenerate, then exit 1 if anything differs from git
set -euo pipefail
cd "$(dirname "$0")/.."

tool/gen_api.sh
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format . >/dev/null

if [[ "${1:-}" == "--check" ]]; then
  if ! git diff --exit-code -- . || [[ -n "$(git ls-files --others --exclude-standard -- .)" ]]; then
    echo "Generated code is out of date. Run app/tool/codegen.sh and commit the result." >&2
    exit 1
  fi
  echo "Generated code is up to date."
fi
