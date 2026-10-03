#!/usr/bin/env bash
# Exercises setup-tools.sh's plan: which version each tool resolves to under `pins: forge`
# and `pins: repo`, against stand-in mise.toml files. Needs no network and no mise: plan
# only reads the files and writes the step outputs.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="${here}/setup-tools.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# A consumer's workspace with forge checked out in .forge, as in bump.yml.
forge="$work/ws/.forge"
mkdir -p "$forge" "$work/ws/backend/crate" "$work/ws/empty" "$work/outside"
cat >"$forge/mise.toml" <<'EOF'
[tool_alias]
ops = "github:rsvalerio/ops"
cargo-nextest = "github:nextest-rs/nextest"
cargo-edit = "cargo:cargo-edit"

[tools]
yq = "4.53.6"
ops = "0.77.0" # a comment
cargo-nextest = { version = "0.9.146", version_prefix = "cargo-nextest-" }
cocogitto = "7.0.0"
cargo-edit = "0.13.13"
EOF

# plan TOOLS PINS PINS_DIRECTORY -> sets $status and $output ($GITHUB_OUTPUT's contents)
plan() {
  : >"$work/out"
  status=0
  TOOLS="$1" PINS="$2" PINS_DIRECTORY="$3" FORGE_ROOT="$forge" \
    GITHUB_WORKSPACE="$work/ws" GITHUB_OUTPUT="$work/out" \
    "$script" plan >"$work/log" 2>&1 || status=$?
  output="$(cat "$work/out")"
}

expect() { # tools pins pins-directory mise-tools ops-version
  plan "$1" "$2" "$3"
  [ "$status" = 0 ] || fail "'$1' ($2, $3) exited $status: $(cat "$work/log")"
  grep -qxF "mise-tools=$4" <<<"$output" || fail "'$1' ($2, $3) wrote: $output"
  grep -qxF "ops-version=$5" <<<"$output" || fail "'$1' ($2, $3) wrote: $output"
}

expect_error() { # tools pins pins-directory message
  plan "$1" "$2" "$3"
  [ "$status" != 0 ] || fail "'$1' ($2, $3) was accepted"
  [ -z "$output" ] || fail "'$1' ($2, $3) failed but still wrote '$output'"
  grep -qF "::error::setup-tools: $4" "$work/log" \
    || fail "'$1' ($2, $3) failed without '$4': $(cat "$work/log")"
}

echo "pins: forge leaves names for mise to resolve from forge's mise.toml"
expect "cocogitto, cargo-nextest,ops" forge . "cocogitto cargo-nextest" 0.77.0
expect "cocogitto@6.3.0 ops@0.70.0" forge . "cocogitto@6.3.0" 0.70.0
expect_error "cocogitto,jq" forge . "'jq' has no version in forge's mise.toml"
expect_error "cocogitto@" forge . "'cocogitto@' names no version"
expect_error "" forge . "'tools' names no tool"

echo "pins: forge never reads the repository's mise.toml"
echo 'not toml at all [' >"$work/ws/mise.toml"
expect cocogitto forge . cocogitto ""

echo "pins: repo takes the repository's pin, and forge's where it has none"
cat >"$work/ws/mise.toml" <<'EOF'
[settings]
experimental = true

[tools]
rust = "1.98.0"
cocogitto = "6.3.0"   # behind forge's
ops = "0.76.0"
"cargo:cargo-edit" = '0.13.0'

[tools.cargo-nextest]
version = "0.9.140"
version_prefix = "ignored-"

[env]
yq = "9.9.9"
EOF
expect "cocogitto,yq,ops" repo . "cocogitto@6.3.0 yq" 0.76.0

echo "a pin keyed by the backend forge aliases the tool to is found"
expect cargo-edit repo . "cargo-edit@0.13.0" ""

echo "a table pin gives its version, as a sub-table or inline"
expect cargo-nextest repo . "cargo-nextest@0.9.140" ""
cat >"$work/ws/backend/mise.toml" <<'EOF'
[tools]
cargo-nextest = { version_prefix = "x-", version = "0.9.141" }
cocogitto = "6.5.0"
EOF
expect cargo-nextest repo backend "cargo-nextest@0.9.141" ""

echo "the nearest mise.toml wins, and the ones above it still count"
expect "cocogitto,cargo-edit" repo backend/crate "cocogitto@6.5.0 cargo-edit@0.13.0" ""
expect cocogitto repo . "cocogitto@6.3.0" ""

echo "name@version beats both"
expect "cocogitto@7.0.0" repo backend "cocogitto@7.0.0" ""

echo "a pin with no single version is an error, not a fall back"
echo 'cocogitto = ["6.3.0", "6.5.0"]' >>"$work/ws/backend/mise.toml"
sed -i.bak '/^cocogitto = "6.5.0"$/d' "$work/ws/backend/mise.toml"
expect_error cocogitto repo backend "'cocogitto' is pinned as [\"6.3.0\", \"6.5.0\"]"

echo "pins: repo needs a mise.toml, inside the workspace"
rm "$work/ws/mise.toml"
expect_error cocogitto repo empty "pins is 'repo' but there is no mise.toml in 'empty'"
expect_error cocogitto repo missing "pins-directory 'missing' is not a directory"
expect_error cocogitto repo ../outside "pins-directory '../outside' is outside the workspace"
expect_error cocogitto mine . "pins is 'mine'"

echo "ok"
