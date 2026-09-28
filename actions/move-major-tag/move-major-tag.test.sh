#!/usr/bin/env bash
# Exercises move-major-tag.sh's guard in check-only mode: a release below or equal to the
# moving tag's major repoints it, one above leaves it in place, and a non-numeric major is
# an error rather than a bash arithmetic failure. Needs no network or token: a stub `gh`
# on PATH fails the test if check-only ever reaches the API.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="${here}/move-major-tag.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir "$work/bin"
cat >"$work/bin/gh" <<'EOF'
#!/bin/sh
echo "gh $*" >>"${GH_CALLS:?}"
exit 1
EOF
chmod +x "$work/bin/gh"
export PATH="$work/bin:$PATH" GH_CALLS="$work/gh-calls"
# Deliberately absent: check-only must need none of them.
unset SHA GH_TOKEN REPOSITORY

# check VERSION MAJOR_TAG -> sets $status and $output ($GITHUB_OUTPUT's contents)
check() {
  : >"$work/out"
  status=0
  VERSION="$1" MAJOR_TAG="$2" CHECK_ONLY=true GITHUB_OUTPUT="$work/out" \
    "$script" >"$work/log" 2>&1 || status=$?
  output="$(cat "$work/out")"
}

expect_move() { # version major-tag expected-move
  check "$1" "$2"
  [ "$status" = 0 ] || fail "$1 vs $2 exited $status: $(cat "$work/log")"
  [ "$output" = "move=$3" ] || fail "$1 vs $2 wrote '$output', expected 'move=$3'"
}

expect_error() { # version major-tag
  check "$1" "$2"
  [ "$status" != 0 ] || fail "$1 vs $2 was accepted"
  [ -z "$output" ] || fail "$1 vs $2 failed but still wrote '$output'"
  grep -q '::error::move-major-tag: cannot compare majors' "$work/log" \
    || fail "$1 vs $2 failed without the comparison error: $(cat "$work/log")"
}

echo "below the tag's major repoints (pre-1.0 releases move v1)"
expect_move v0.4.0 v1 true
expect_move 0.4.0 v1 true

echo "equal to the tag's major repoints"
expect_move v1.0.0 v1 true
expect_move v1.12.3 v1 true
expect_move v1.2.3 v1.2.3 true

echo "above the tag's major leaves it in place"
expect_move v2.0.0 v1 false
expect_move v10.0.0 v9 false
grep -q '::notice::v10.0.0 is past v9' "$work/log" || fail "no notice for a refused move"

echo "majors compare as numbers, not strings"
expect_move v9.0.0 v10 true

echo "a non-numeric major is an error, not an arithmetic failure"
expect_error vX.0.0 v1
expect_error v1.0.0 vlatest
expect_error main v1
expect_error "" v1
expect_error v1.0.0 ""
expect_error v-1.0.0 v1

[ ! -e "$GH_CALLS" ] || fail "check-only called the API: $(cat "$GH_CALLS")"

echo "ok"
