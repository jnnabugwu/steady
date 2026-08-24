#!/usr/bin/env bash
# Run `flutter analyze` across the monorepo's packages.
#
# By default, only analyzes packages that have changes relative to a base
# ref (uncommitted/staged changes and untracked files count as "changed"
# too, so this works as a pre-commit-style check locally). Pass --all to
# analyze every package regardless of what changed.
#
# Usage:
#   scripts/analyze.sh                 # packages changed vs. local `main`
#   scripts/analyze.sh --base origin/main
#   scripts/analyze.sh --all           # every package in the repo
#
# Written against bash 3.2 (macOS's default /bin/bash) on purpose: no
# mapfile, no associative arrays.
set -euo pipefail

BASE_REF="main"
RUN_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) RUN_ALL=true; shift ;;
    --base) BASE_REF="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

all_packages=()
while IFS= read -r pkg; do
  all_packages+=("$pkg")
done < <(
  find . -name pubspec.yaml -not -path "*/.dart_tool/*" -not -path "*/build/*" \
    | xargs -n1 dirname | sed 's|^\./||' | sort
)

packages=()

if $RUN_ALL; then
  packages=("${all_packages[@]}")
else
  if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
    if git rev-parse --verify --quiet "origin/$BASE_REF" >/dev/null; then
      BASE_REF="origin/$BASE_REF"
    else
      echo "error: base ref '$BASE_REF' not found (tried '$BASE_REF' and 'origin/$BASE_REF')" >&2
      echo "hint: pass --base <ref> or fetch it first" >&2
      exit 1
    fi
  fi

  merge_base="$(git merge-base HEAD "$BASE_REF")"

  changed_files="$(
    {
      git diff --name-only "$merge_base" HEAD
      git diff --name-only HEAD
      git ls-files --others --exclude-standard
    } | sort -u
  )"

  if [[ -z "$changed_files" ]]; then
    echo "No changes vs $BASE_REF; nothing to analyze."
    exit 0
  fi

  changed_packages_raw=""
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    dir="$(dirname "$file")"
    while [[ "$dir" != "." && "$dir" != "/" ]]; do
      if [[ -f "$dir/pubspec.yaml" ]]; then
        changed_packages_raw="$changed_packages_raw
$dir"
        break
      fi
      dir="$(dirname "$dir")"
    done
  done <<< "$changed_files"

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    packages+=("$pkg")
  done < <(printf '%s\n' "$changed_packages_raw" | sort -u)

  if [[ ${#packages[@]} -eq 0 ]]; then
    echo "Changed files don't touch any package; nothing to analyze."
    exit 0
  fi
fi

echo "Analyzing ${#packages[@]} package(s):"
printf '  %s\n' "${packages[@]}"
echo

status=0
for pkg in "${packages[@]}"; do
  echo "── $pkg ──────────────────────────────"

  if ! (cd "$pkg" && flutter pub get); then
    status=1
    echo
    continue
  fi

  # `flutter analyze` exits non-zero on any issue, infos included. We only
  # want to fail the build on warnings/errors -- infos still print above.
  analyze_output="$(cd "$pkg" && flutter analyze 2>&1)" || true
  echo "$analyze_output"
  if echo "$analyze_output" | grep -qE '(warning|error) •'; then
    status=1
  fi
  echo
done

exit $status
