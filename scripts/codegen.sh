#!/usr/bin/env bash
# Run build_runner (freezed, riverpod_generator, ...) across the monorepo.
#
# By default, runs in every package whose pubspec.yaml depends on
# build_runner. Pass one or more package paths to run only in those --
# concurrent agent units must do this, so they don't collide on packages
# they don't own (docs/freezed_riverpod_migration.md §5).
#
# Generated files (*.g.dart, *.freezed.dart) are committed (CLAUDE.md §9),
# so run this after changing any annotated class and commit the output.
#
# Usage:
#   scripts/codegen.sh                                   # every codegen package
#   scripts/codegen.sh packages/shared/daily_metrics_domain
#
# Written against bash 3.2 (macOS's default /bin/bash) on purpose: no
# mapfile, no associative arrays.
set -euo pipefail

case "${1:-}" in
  -h|--help)
    sed -n '2,15p' "$0"
    exit 0
    ;;
esac

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

packages=()

if [[ $# -gt 0 ]]; then
  for pkg in "$@"; do
    pkg="${pkg%/}"
    if [[ ! -f "$pkg/pubspec.yaml" ]]; then
      echo "error: '$pkg' is not a package (no pubspec.yaml)" >&2
      exit 1
    fi
    packages+=("$pkg")
  done
else
  while IFS= read -r pkg; do
    if grep -qE '^  build_runner:' "$pkg/pubspec.yaml"; then
      packages+=("$pkg")
    fi
  done < <(
    find . -name pubspec.yaml -not -path "*/.dart_tool/*" -not -path "*/build/*" -not -path "./.claude/*" \
      | xargs -n1 dirname | sed 's|^\./||' | sort
  )
fi

if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No packages depend on build_runner; nothing to generate."
  exit 0
fi

echo "Generating code in ${#packages[@]} package(s):"
printf '  %s\n' "${packages[@]}"
echo

status=0
for pkg in "${packages[@]}"; do
  echo "── $pkg ──────────────────────────────"

  if ! (cd "$pkg" && flutter pub get >/dev/null); then
    status=1
    echo
    continue
  fi

  start=$SECONDS
  # No --delete-conflicting-outputs: build_runner 2.17 removed it (deleting
  # stale outputs is now the default) and warns if it's passed.
  if ! (cd "$pkg" && dart run build_runner build); then
    status=1
  fi
  echo "($pkg: $((SECONDS - start))s)"
  echo
done

exit $status
