#!/bin/sh
# Xcode build phase for the Runner target (after Flutter's "Thin Binary").
#
# 1. Bundles Runner/GoogleService-Info.plist when it exists. infra/auth-setup.sh
#    writes it from Terraform; without it the app builds but Firebase fails at
#    startup. Copying it here keeps it out of the Xcode project file.
# 2. Debug builds only: lets the app reach a backend on your Mac over plain HTTP
#    by its Bonjour name (http://<name>.local:8080). Flutter's HTTP client on iOS
#    only honours NSAllowsArbitraryLoads and NSExceptionDomains, so this adds an
#    exception for the "local" domain. Release and Profile builds are untouched.
set -eu

PLIST="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
BUDDY=/usr/libexec/PlistBuddy
FIREBASE_CONFIG="$SRCROOT/Runner/GoogleService-Info.plist"

if [ -f "$FIREBASE_CONFIG" ]; then
  cp "$FIREBASE_CONFIG" "$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/GoogleService-Info.plist"
else
  echo "warning: Runner/GoogleService-Info.plist is missing; run infra/auth-setup.sh dev. Sign-in won't work."
fi

if [ "$CONFIGURATION" = "Debug" ]; then
  "$BUDDY" -c "Delete :NSAppTransportSecurity:NSExceptionDomains:local" "$PLIST" 2>/dev/null || true
  "$BUDDY" -c "Add :NSAppTransportSecurity dict" "$PLIST" 2>/dev/null || true
  "$BUDDY" -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$PLIST" 2>/dev/null || true
  "$BUDDY" -c "Add :NSAppTransportSecurity:NSExceptionDomains:local dict" \
    -c "Add :NSAppTransportSecurity:NSExceptionDomains:local:NSIncludesSubdomains bool true" \
    -c "Add :NSAppTransportSecurity:NSExceptionDomains:local:NSExceptionAllowsInsecureHTTPLoads bool true" \
    "$PLIST"
fi
