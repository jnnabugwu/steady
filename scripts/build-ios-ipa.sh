#!/usr/bin/env bash
# Build a signed, App Store Connect-ready Steady .ipa for TestFlight.
#
# Usage:
#   scripts/build-ios-ipa.sh                  # version + build from app/pubspec.yaml
#   scripts/build-ios-ipa.sh --bump           # build number + 1 (pubspec edited, NOT committed)
#   scripts/build-ios-ipa.sh --build 7        # set the build number explicitly (NOT committed)
#   scripts/build-ios-ipa.sh --check --open   # gates first, open the archive when done
#
# Options:
#   --pull        git pull --ff-only before building
#   --clean       flutter clean first (slower, safest)
#   --bump        increment the +N build number in app/pubspec.yaml (not committed)
#   --build N     set the build number to N (not committed)
#   --check       run scripts/analyze.sh and scripts/test.sh --all first
#   --open        open the archive in Xcode's Organizer when done
#   -h, --help    show this help
#
# Signing is automatic with team UXZV3C926U (bundle com.jmagic.steady), so
# Xcode must be signed in to an Apple ID on that team (Xcode > Settings >
# Accounts). TestFlight rejects a build number that isn't higher than the
# last one uploaded for the same version: use --bump or --build.
#
# Output: app/build/ios/ipa/*.ipa and app/build/ios/archive/Runner.xcarchive.
# The script then checks the signed app with scripts/verify-ios-ipa.sh:
# team, HealthKit, the iCloud container, production push, the encryption
# flag, and iPhone-only.
#
# No flavors, env files or CocoaPods: Steady has no backend, and plugins are
# integrated with Swift Package Manager.
#
# Written against bash 3.2 (macOS's default /bin/bash).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/app"
TEAM_ID="UXZV3C926U"

PULL=0; CLEAN=0; BUMP=0; CHECK=0; OPEN=0; SET_BUILD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --pull)  PULL=1 ;;
    --clean) CLEAN=1 ;;
    --bump)  BUMP=1 ;;
    --build)
      shift; SET_BUILD="${1:?--build needs a number}"
      case "$SET_BUILD" in
        ''|*[!0-9]*) echo "--build needs a whole number, got: $SET_BUILD" >&2; exit 2 ;;
      esac
      ;;
    --check) CHECK=1 ;;
    --open)  OPEN=1 ;;
    -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33mWARNING: %s\033[0m\n' "$1" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

command -v flutter    >/dev/null || die "flutter is not on PATH"
command -v xcodebuild >/dev/null || die "Xcode command line tools not found (xcode-select --install)"

cd "$ROOT"
if [ "$PULL" = 1 ]; then
  step "git pull --ff-only"
  git pull --ff-only
fi
step "Repo state"
git log --oneline -1 || true
[ -z "$(git status --porcelain)" ] || \
  warn "uncommitted changes in the working tree WILL be included in this build"

# --- version / build number (app/pubspec.yaml) ---
cd "$APP_DIR"
VLINE=$(grep -E '^version:[[:space:]]' pubspec.yaml | head -1 | awk '{print $2}')
case "$VLINE" in
  *+*) ;;
  *) die "app/pubspec.yaml version '$VLINE' has no +build number; use the form 1.0.0+1" ;;
esac
VNAME="${VLINE%%+*}"; VNUM="${VLINE##*+}"
case "$VNUM" in
  ''|*[!0-9]*) die "build number '$VNUM' in app/pubspec.yaml isn't a whole number" ;;
esac
if   [ -n "$SET_BUILD" ]; then VNUM="$SET_BUILD"
elif [ "$BUMP" = 1 ];     then VNUM=$((VNUM + 1))
fi
if [ "$VLINE" != "$VNAME+$VNUM" ]; then
  step "app/pubspec.yaml version -> $VNAME+$VNUM (not committed)"
  # The new version goes in through the environment, never into the Perl
  # source, so nothing passed on the command line can run as code.
  STEADY_VERSION="$VNAME+$VNUM" perl -0pi -e 's/^version:.*/version: $ENV{STEADY_VERSION}/m' pubspec.yaml
fi
echo "Building Steady $VNAME ($VNUM), team $TEAM_ID"

if [ "$CHECK" = 1 ]; then
  step "Gates: analyze + tests"
  "$ROOT/scripts/analyze.sh" --all
  "$ROOT/scripts/test.sh" --all
fi

if [ "$CLEAN" = 1 ]; then
  step "flutter clean"
  flutter clean
fi

step "flutter pub get"
flutter pub get

step "flutter build ipa (release, App Store Connect, automatic signing)"
flutter build ipa --release \
  --build-name="$VNAME" \
  --build-number="$VNUM" \
  --export-method=app-store \
  || die "build failed. If it's signing: Xcode > Settings > Accounts must have an Apple ID on team $TEAM_ID, then open app/ios/Runner.xcworkspace > Runner > Signing & Capabilities and fix anything red"

IPA=$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)
[ -n "$IPA" ] || die "no .ipa was exported; check signing in Xcode (see above)"

# --- verify what App Review will see ---
"$ROOT/scripts/verify-ios-ipa.sh" "$IPA" "$VNAME" "$VNUM"

SIZE=$(du -h "$IPA" | awk '{print $1}')
printf '\n\033[1;32mDONE\033[0m  app/%s  (%s)  version %s (%s)\n' "$IPA" "$SIZE" "$VNAME" "$VNUM"
cat <<EOF

Upload to App Store Connect / TestFlight, either:
  - Xcode: open app/build/ios/archive/Runner.xcarchive > Distribute App >
    App Store Connect > Upload
  - Transporter.app: drag in  $APP_DIR/$IPA
Then in App Store Connect > TestFlight, add the build to the external group
and submit it for Beta App Review (docs/testflight.md).
EOF

if [ "$OPEN" = 1 ]; then
  open build/ios/archive/Runner.xcarchive
fi
