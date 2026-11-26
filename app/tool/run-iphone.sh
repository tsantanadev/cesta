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
if [[ ! -f "$signing" ]]; then
  team=$(security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject -nameopt multiline 2>/dev/null \
    | sed -nE 's/^[[:space:]]*organizationalUnitName[[:space:]]*=[[:space:]]*//p' | head -1)
  if [[ -z "$team" ]]; then
    echo "No Apple Development certificate found. In Xcode: Settings → Accounts → add your Apple ID," >&2
    echo "then open ios/Runner.xcworkspace, select Runner → Signing & Capabilities once, and run this again." >&2
    exit 1
  fi
  printf 'DEVELOPMENT_TEAM = %s\n' "$team" > "$signing"
  echo "Signing with team $team (saved to $signing)."
fi

if [[ ! -f ios/Runner/GoogleService-Info.plist ]]; then
  echo "ios/Runner/GoogleService-Info.plist is missing: run infra/auth-setup.sh dev first." >&2
  exit 1
fi

if ! curl -fsS --max-time 3 http://localhost:8080/health >/dev/null; then
  echo "The backend isn't answering on :8080. Start it in another terminal: cd backend && make dev" >&2
  exit 1
fi

host="$(scutil --get LocalHostName).local"
device=$(flutter devices --machine 2>/dev/null \
  | python3 -c 'import json,sys; d=[x for x in json.load(sys.stdin) if x.get("targetPlatform")=="ios" and not x.get("emulator")]; print(d[0]["id"] if d else "")')
if [[ -z "$device" ]]; then
  echo "No iPhone found. Plug it in, unlock it, tap Trust, and turn on Developer Mode" >&2
  echo "(Settings → Privacy & Security → Developer Mode)." >&2
  exit 1
fi

echo "Backend: http://$host:8080. On the phone, allow Local Network access when asked."
exec flutter run -d "$device" --dart-define=API_BASE_URL="http://$host:8080" "$@"
