#!/usr/bin/env bash
# Runs the app on a plugged-in (or Wi-Fi paired) iPhone against the backend on
# this Mac (`cd backend && make dev`), reached by its Bonjour name.
#
# First run: saves your Apple team to ios/Flutter/Signing.xcconfig (git-ignored),
# read from your "Apple Development" certificate. Sign in to Xcode once
# (Settings → Accounts) so that certificate exists.
#
# Usage: app/tool/run-iphone.sh [extra flutter run args]
set -euo pipefail
cd "$(dirname "$0")/.."

signing=ios/Flutter/Signing.xcconfig
problems=()

if [[ ! -f "$signing" ]]; then
  team=$(security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject -nameopt multiline 2>/dev/null \
    | sed -nE 's/^[[:space:]]*organizationalUnitName[[:space:]]*=[[:space:]]*//p' | head -1 || true)
  if [[ -n "$team" ]]; then
    printf 'DEVELOPMENT_TEAM = %s\n' "$team" > "$signing"
    echo "Signing with team $team (saved to $signing)."
  else
    problems+=("No Apple Development certificate. In Xcode: Settings → Accounts → + → Apple ID. Then open
     ios/Runner.xcworkspace, select Runner → Signing & Capabilities, tick 'Automatically manage signing'
     and pick your team (a free Personal Team works). Xcode creates the certificate.")
  fi
fi

if [[ ! -f ios/Runner/GoogleService-Info.plist ]]; then
  problems+=("No Firebase config (ios/Runner/GoogleService-Info.plist). Run: infra/auth-setup.sh dev")
fi

if ! curl -fsS --max-time 3 http://localhost:8080/health >/dev/null 2>&1; then
  problems+=("The backend isn't answering on :8080. In another terminal: cd backend && make dev")
fi

host="$(scutil --get LocalHostName).local"
device=$(flutter devices --machine 2>/dev/null \
  | python3 -c 'import json,sys; d=[x for x in json.load(sys.stdin) if x.get("targetPlatform")=="ios" and not x.get("emulator")]; print(d[0]["id"] if d else "")')
if [[ -z "$device" ]]; then
  problems+=("No iPhone found. Plug it in, unlock it, tap Trust, and turn on Developer Mode
     (Settings → Privacy & Security → Developer Mode).")
fi

if (( ${#problems[@]} )); then
  echo "Can't run on the iPhone yet:" >&2
  for p in "${problems[@]}"; do printf '  - %s\n' "$p" >&2; done
  exit 1
fi

echo "Backend: http://$host:8080. On the phone, allow Local Network access when asked."
exec flutter run -d "$device" --dart-define=API_BASE_URL="http://$host:8080" "$@"
