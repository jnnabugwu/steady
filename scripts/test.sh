#!/usr/bin/env bash
# Run `flutter test` across the monorepo's packages that have a test/ dir.
#
# By default, tests packages that changed relative to a base ref, PLUS every
# package that depends on a changed package through a path dependency
# (dependencies, dev_dependencies or dependency_overrides, transitively).
# A change to packages/shared/daily_metrics_domain re-tests everything built
# on it. Uncommitted/staged changes and untracked files count as changed, as
# in analyze.sh. A change to this script or to a workflow tests everything.
# Pass --all to test every package regardless of what changed.
#
# Usage:
#   scripts/test.sh                    # changed packages + dependents vs. `main`
#   scripts/test.sh --base origin/main
#   scripts/test.sh --all              # every package with a test/ dir
#   scripts/test.sh --all --coverage   # also merge lcov into coverage/lcov.info
#   scripts/test.sh --list             # print the selection and why; run nothing
#
# --coverage runs `flutter test --coverage`, merges every package's lcov into
# coverage/lcov.info (paths made repo-relative; generated *.g.dart and
# *.freezed.dart dropped) and writes a per-package table to
# coverage/summary.md.
#
# Exits non-zero if any package fails (pub get, a test, or a load error).
# Prints a per-package pass/skip/fail summary, with each skip's reason.
#
# Written against bash 3.2 (macOS's default /bin/bash) on purpose: no
# mapfile, no associative arrays.
set -euo pipefail

BASE_REF="main"
RUN_ALL=false
all_reason="--all"
COVERAGE=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) RUN_ALL=true; shift ;;
    --base) BASE_REF="$2"; shift 2 ;;
    --coverage) COVERAGE=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
    -h|--help)
      sed -n '2,28p' "$0"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

repo_root="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)"
cd "$repo_root"

all_packages=()
while IFS= read -r pkg; do
  all_packages+=("$pkg")
done < <(
  find . -name pubspec.yaml -not -path "*/.dart_tool/*" -not -path "*/build/*" -not -path "./.claude/*" \
    | xargs -n1 dirname | sed 's|^\./||' | sort
)

# Edges "<dependency>\t<dependent>", one per local path dependency. Any
# `path:` line in a pubspec counts (dependencies, dev_dependencies and
# dependency_overrides alike): a dev dependency can break a package's tests
# just as well. Paths are resolved to repo-relative package dirs.
edges=""
for pkg in "${all_packages[@]}"; do
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ ! -f "$pkg/$rel/pubspec.yaml" ]]; then
      echo "error: $pkg/pubspec.yaml has path dependency '$rel' with no pubspec.yaml" >&2
      exit 1
    fi
    dep="$(cd "$pkg/$rel" && pwd -P)"
    dep="${dep#"$repo_root"/}"
    edges="$edges
$dep	$pkg"
  done < <(
    sed -n -E 's/^[[:space:]]+path:[[:space:]]*["'\'']?([^"'\''#[:space:]]+)["'\'']?[[:space:]]*(#.*)?$/\1/p' \
      "$pkg/pubspec.yaml"
  )
done

selected=()
why=""

if $RUN_ALL; then
  selected=("${all_packages[@]}")
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
    echo "No changes vs $BASE_REF; nothing to test."
    exit 0
  fi

  # The test harness itself changed: its selection logic can't be trusted
  # to pick its own scope, so test everything.
  if echo "$changed_files" | grep -qE '^(scripts/test\.sh|\.github/workflows/)'; then
    echo "scripts/test.sh or a workflow changed; testing every package."
    RUN_ALL=true
    all_reason="test harness changed"
    selected=("${all_packages[@]}")
  else
    frontier=""
    # "<pkg>\t<reason>" lines: why each package was selected.
    why=""
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      dir="$(dirname "$file")"
      while [[ "$dir" != "." && "$dir" != "/" ]]; do
        if [[ -f "$dir/pubspec.yaml" ]]; then
          frontier="$frontier
$dir"
          why="$why
$dir	changed"
          break
        fi
        dir="$(dirname "$dir")"
      done
    done <<< "$changed_files"

    # Transitive closure over reverse path-dependency edges.
    closure="$(printf '%s\n' "$frontier" | sed '/^$/d' | sort -u)"
    while [[ -n "$frontier" ]]; do
      next=""
      while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        dependents="$(printf '%s\n' "$edges" | awk -F'\t' -v d="$pkg" '$1 == d { print $2 }')"
        while IFS= read -r dependent; do
          [[ -z "$dependent" ]] && continue
          if ! printf '%s\n' "$closure" | grep -qxF "$dependent"; then
            closure="$closure
$dependent"
            next="$next
$dependent"
            why="$why
$dependent	dependent of $pkg"
          fi
        done <<< "$dependents"
      done <<< "$frontier"
      frontier="$(printf '%s\n' "$next" | sed '/^$/d')"
    done

    while IFS= read -r pkg; do
      [[ -z "$pkg" ]] && continue
      selected+=("$pkg")
    done < <(printf '%s\n' "$closure" | sed '/^$/d' | sort -u)
  fi
fi

packages=()
for pkg in ${selected[@]+"${selected[@]}"}; do
  if [[ -d "$pkg/test" ]]; then
    packages+=("$pkg")
  fi
done

if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No changed package (or dependent) has a test/ dir; nothing to test."
  exit 0
fi

echo "Testing ${#packages[@]} package(s) (TZ=${TZ:-<unset>}):"
for pkg in "${packages[@]}"; do
  if $RUN_ALL; then
    reason="$all_reason"
  else
    reason="$(printf '%s\n' "$why" | awk -F'\t' -v p="$pkg" '$1 == p { print $2; exit }')"
  fi
  printf '  %-48s (%s)\n' "$pkg" "$reason"
done
if ! $RUN_ALL; then
  skipped_no_tests="$(for pkg in ${selected[@]+"${selected[@]}"}; do [[ -d "$pkg/test" ]] || echo "$pkg"; done)"
  if [[ -n "$skipped_no_tests" ]]; then
    echo "Selected but no test/ dir (dependents still followed):"
    printf '  %s\n' $skipped_no_tests
  fi
fi
echo

if $LIST_ONLY; then
  exit 0
fi

reports_dir="$(mktemp -d)"
trap 'rm -rf "$reports_dir"' EXIT

if $COVERAGE; then
  rm -rf coverage
  mkdir -p coverage
  : > coverage/lcov.info
fi

# Counts from a `--file-reporter json:` file. Hidden tests are the runner's
# own "loading <file>" entries; a load failure surfaces as an error on one.
count_results() {
  local report="$1"
  local pass=0 skip=0 fail=0
  if [[ -f "$report" ]]; then
    pass="$(grep '"type":"testDone"' "$report" | grep '"hidden":false' \
      | grep '"skipped":false' | grep -c '"result":"success"' || true)"
    skip="$(grep '"type":"testDone"' "$report" | grep -c '"skipped":true' || true)"
    fail="$(grep '"type":"testDone"' "$report" \
      | grep -cE '"result":"(failure|error)"' || true)"
  fi
  echo "$pass $skip $fail"
}

status=0
summary=""
skip_lines=""
total_pass=0
total_skip=0
total_fail=0
for pkg in "${packages[@]}"; do
  echo "── $pkg ──────────────────────────────"
  slug="$(echo "$pkg" | tr '/' '_')"
  report="$reports_dir/$slug.json"

  if ! (cd "$pkg" && flutter pub get); then
    status=1
    summary="$summary
$(printf '%-48s %s' "$pkg" 'FAILED (pub get)')"
    echo
    continue
  fi

  args=(--reporter expanded --file-reporter "json:$report")
  if $COVERAGE; then
    args+=(--coverage)
  fi

  start=$SECONDS
  pkg_status=0
  (cd "$pkg" && flutter test "${args[@]}") || pkg_status=$?
  elapsed=$((SECONDS - start))

  read -r pass skip fail <<< "$(count_results "$report")"
  total_pass=$((total_pass + pass))
  total_skip=$((total_skip + skip))
  total_fail=$((total_fail + fail))

  if [[ $pkg_status -ne 0 ]]; then
    status=1
    verdict="FAIL"
  else
    verdict="ok"
  fi
  summary="$summary
$(printf '%-48s %-4s %4s pass %3s skip %3s fail  %4ss' "$pkg" "$verdict" "$pass" "$skip" "$fail" "$elapsed")"

  # Skip reasons, from the json reporter's "Skip: <reason>" print events,
  # paired with the name of the test they belong to.
  if [[ -f "$report" ]] && [[ "$skip" -gt 0 ]]; then
    reasons="$(awk '
      /"type":"testStart"/ {
        id = $0; sub(/.*"test":\{"id":/, "", id); sub(/,.*/, "", id)
        name = $0; sub(/.*"name":"/, "", name); sub(/","suiteID".*/, "", name)
        names[id] = name
      }
      /"type":"print"/ && /"messageType":"skip"/ {
        id = $0; sub(/.*"testID":/, "", id); sub(/,.*/, "", id)
        msg = $0; sub(/.*"message":"/, "", msg); sub(/".*/, "", msg)
        print "    " names[id] " -- " msg
      }
    ' "$report")"
    skip_lines="$skip_lines
  $pkg:
$reasons"
  fi

  if $COVERAGE && [[ -f "$pkg/coverage/lcov.info" ]]; then
    # Repo-relative SF paths; drop generated files. A record runs from SF:
    # to end_of_record.
    awk -v prefix="$pkg/" -v abs="$repo_root/$pkg/" '
      /^SF:/ {
        path = substr($0, 4)
        if (index(path, abs) == 1) path = substr(path, length(abs) + 1)
        keep = (path !~ /\.(g|freezed)\.dart$/)
        if (keep) print "SF:" prefix path
        next
      }
      keep { print }
    ' "$pkg/coverage/lcov.info" >> coverage/lcov.info
  fi
  echo
done

echo "══ Summary ═══════════════════════════════════"
printf '%s\n' "$summary" | sed '/^$/d'
echo
echo "Total: $total_pass passed, $total_skip skipped, $total_fail failed across ${#packages[@]} package(s)"
if [[ -n "$skip_lines" ]]; then
  echo
  echo "Skipped tests:"
  printf '%s\n' "$skip_lines" | sed '/^$/d'
fi

if $COVERAGE; then
  # Per-package line coverage from the merged lcov (LF = lines found,
  # LH = lines hit). Only files the tests loaded appear in lcov.
  printf '%s\n' "${packages[@]}" > "$reports_dir/packages.txt"
  # First file: the package list (BSD awk rejects newlines in -v values).
  awk '
    NR == FNR { list[++n] = $0; next }
    /^SF:/ {
      path = substr($0, 4); cur = ""
      for (i = 1; i <= n; i++) {
        p = list[i] "/"
        if (index(path, p) == 1 && length(p) > length(cur)) cur = list[i]
      }
    }
    /^LF:/ { lf[cur] += substr($0, 4) }
    /^LH:/ { lh[cur] += substr($0, 4) }
    END {
      print "| Package | Lines hit / total | Coverage |"
      print "|---|---:|---:|"
      for (i = 1; i <= n; i++) {
        p = list[i]
        if (lf[p] > 0) {
          printf "| `%s` | %d / %d | %.1f%% |\n", p, lh[p], lf[p], 100 * lh[p] / lf[p]
          tf += lf[p]; th += lh[p]
        } else {
          printf "| `%s` | 0 / 0 | n/a |\n", p
        }
      }
      if (tf > 0) printf "| **Total** | **%d / %d** | **%.1f%%** |\n", th, tf, 100 * th / tf
    }
  ' "$reports_dir/packages.txt" coverage/lcov.info > coverage/summary.md
  echo
  echo "Coverage (generated *.g.dart / *.freezed.dart excluded):"
  cat coverage/summary.md
  echo
  echo "Merged lcov: coverage/lcov.info"
fi

exit $status
