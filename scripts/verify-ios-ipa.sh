#!/usr/bin/env bash
# Check a signed Steady .ipa for what App Review sees, before it's uploaded.
#
# Usage:
#   scripts/verify-ios-ipa.sh <path/to/Steady.ipa> <version> <build>
#   scripts/verify-ios-ipa.sh app/build/ios/ipa/steady.ipa 1.0.0 4
#
# Checks the signed app's entitlements and Info.plist: team, bundle ID,
# version, HealthKit, the iCloud container, production push, production App
# Attest, the encryption flag, iPhone-only, and that the coach proxy's
# address (scripts/coach-proxy-url) is compiled in. Exits non-zero if anything
# doesn't match, so a bad build never reaches App Store Connect. Used by
# scripts/build-ios-ipa.sh (local builds) and the fastlane `beta` lane
# (GitHub Actions).
#
# macOS only (codesign, PlistBuddy, security). Written against bash 3.2.
set -euo pipefail

TEAM_ID="UXZV3C926U"
BUNDLE_ID="com.jmagic.steady"
ICLOUD_CONTAINER="iCloud.com.jmagic.steady"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COACH_PROXY_URL="${COACH_PROXY_URL:-$(tr -d '[:space:]' < "$ROOT/scripts/coach-proxy-url")}"

case "${1:-}" in
  -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
esac
[ $# -eq 3 ] || { echo "usage: $0 <ipa> <version> <build> (see --help)" >&2; exit 2; }
IPA="$1"; VNAME="$2"; VNUM="$3"
[ -f "$IPA" ] || { echo "no such file: $IPA" >&2; exit 2; }

die() { printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

printf '\n\033[1;36m==> %s\033[0m\n' "Verify $IPA"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
unzip -q "$IPA" -d "$TMP"
APP="$TMP/Payload/$(ls "$TMP/Payload" | head -1)"
codesign -d --entitlements :- "$APP" > "$TMP/ent.plist" 2>/dev/null || die "couldn't read entitlements"
PLIST="$APP/Info.plist"

FAILED=0
check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  \033[32m✓\033[0m %s: %s\n' "$1" "$3"
  else
    printf '  \033[31m✗\033[0m %s: expected %s, got %s\n' "$1" "$2" "${3:-<missing>}"
    FAILED=1
  fi
}
ent()  { /usr/libexec/PlistBuddy -c "Print :$1" "$TMP/ent.plist" 2>/dev/null || true; }
info() { /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null || true; }

check "Team"                 "$TEAM_ID" "$(ent com.apple.developer.team-identifier)"
check "Bundle ID"            "$BUNDLE_ID" "$(info CFBundleIdentifier)"
check "Version"              "$VNAME ($VNUM)" "$(info CFBundleShortVersionString) ($(info CFBundleVersion))"
check "Push environment"     "production" "$(ent aps-environment)"
# Release builds attest against Apple's production App Attest service (#150).
check "App Attest environment" "production" "$(ent com.apple.developer.devicecheck.appattest-environment)"
check "HealthKit"            "true" "$(ent com.apple.developer.healthkit)"
check "iCloud container"     "$ICLOUD_CONTAINER" "$(ent com.apple.developer.icloud-container-identifiers:0)"
check "iCloud service"       "CloudKit" "$(ent com.apple.developer.icloud-services:0)"
check "Non-exempt encryption" "false" "$(info ITSAppUsesNonExemptEncryption)"
# The whole array, so an iPhone+iPad build ([1,2]) can't pass.
check "Device family"        "[1]" "$(plutil -extract UIDeviceFamily json -o - "$PLIST" 2>/dev/null || true)"
check "iCloud sync enabled"  "true" "$(info SteadyCloudKitEnabled)"
# App Store Connect rejects a HealthKit app missing either purpose string,
# even one that never writes to Apple Health (ITMS-90683).
for key in NSHealthShareUsageDescription NSHealthUpdateUsageDescription; do
  [ -n "$(info "$key")" ] \
    && printf '  \033[32m✓\033[0m %s present\n' "$key" \
    || { printf '  \033[31m✗\033[0m %s missing\n' "$key"; FAILED=1; }
done
# Release builds get the proxy address only from --dart-define (#151); without
# it every tester's coach says it's off.
# Byte-wise: in a UTF-8 locale macOS grep stops matching inside binary data.
LC_ALL=C grep -a -q -F "$COACH_PROXY_URL" "$APP/Frameworks/App.framework/App" 2>/dev/null \
  && printf '  \033[32m✓\033[0m Coach proxy URL: %s\n' "$COACH_PROXY_URL" \
  || { printf '  \033[31m✗\033[0m Coach proxy URL %s not compiled in (--dart-define=COACH_PROXY_URL)\n' "$COACH_PROXY_URL"; FAILED=1; }
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E 'Authority=Apple Distribution' | sed 's/^/  /' || true
PROFILE=$(security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null \
          | plutil -extract Name raw -o - - 2>/dev/null || echo '?')
echo "  Provisioning profile: $PROFILE"

[ "$FAILED" = 0 ] || die "the IPA doesn't match what Steady ships; don't upload it (see ✗ above)"
