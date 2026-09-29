#!/usr/bin/env bash
# Install tools at the versions forge's mise.toml pins and put them on PATH. `ops` goes
# through actions/setup-ops (sha256-verified); every other tool through mise.
#
#   setup-tools.sh plan     validate TOOLS against mise.toml; write step outputs
#   setup-tools.sh path     after mise installed them: put the tools on PATH, install ops
#   setup-tools.sh pin NAME print NAME's version from mise.toml, for an installer that
#                           takes a version rather than going through mise (setup-rust)
#
# Configured through the environment (see action.yml for the meaning of each):
#   TOOLS  FORGE_ROOT  GH_TOKEN  RUNNER_TEMP  GITHUB_OUTPUT  GITHUB_PATH
#   MISE_TOOLS  OPS_VERSION  (path: the plan's outputs)
set -euo pipefail

err() { echo "::error::setup-tools: $*" >&2; exit 1; }

FORGE_ROOT="$(cd "${FORGE_ROOT:?}" && pwd)"
config="${FORGE_ROOT}/mise.toml"
[ -f "$config" ] || err "no mise.toml in ${FORGE_ROOT}."

# The value of `<name> = ...` in mise.toml's [tools] table, or nothing. A table value
# (`{ version = "1.2.3", ... }`) prints as written; only its presence matters to the
# caller, except for ops, whose pin setup-ops needs as a plain string.
pin() {
  awk -v want="$1" '
    /^[[:space:]]*\[/ { in_tools = ($0 ~ /^[[:space:]]*\[tools\][[:space:]]*(#.*)?$/); next }
    in_tools && /=/ {
      key = $0; sub(/[[:space:]]*=.*/, "", key); gsub(/^[[:space:]]+|"/, "", key)
      if (key == want) { val = $0; sub(/^[^=]*=[[:space:]]*/, "", val); print val; exit }
    }' "$config"
}

# NAME's pin as a plain version: `"0.75.0"`, possibly followed by a comment, prints
# 0.75.0. A missing pin, or one written as a table, fails: the caller needs one string.
version_of() {
  local value
  value="$(pin "$1")"
  [ -n "$value" ] || err "'$1' has no version in forge's mise.toml."
  [[ "$value" == \"* ]] || err "'$1' is pinned as a table in forge's mise.toml; this needs a plain \"version\"."
  sed -E 's/^"([^"]*)".*/\1/' <<<"$value"
}

plan() {
  local entries entry name version ops_version="" mise_tools=()
  # A comma- or whitespace-separated list, newlines included.
  read -ra entries -d '' <<<"$(printf '%s' "${TOOLS:-}" | tr ',' ' ')" || true
  [ ${#entries[@]} -gt 0 ] || err "'tools' names no tool."

  for entry in "${entries[@]}"; do
    name="${entry%%@*}"
    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || err "'${entry}' is not a tool name."
    if [ "$entry" = "$name" ]; then
      # The pin is the point: a tool mise.toml does not list would install at whatever
      # is newest, and drift between runs.
      version="$(pin "$name")"
      [ -n "$version" ] \
        || err "'${name}' has no version in forge's mise.toml; add it there, or pass '${name}@<version>'."
    else
      version="${entry#*@}"
      [[ "$version" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$ ]] || err "'${entry}' names no version."
    fi
    if [ "$name" = ops ]; then
      if [ "$entry" = "$name" ]; then ops_version="$(version_of ops)"; else ops_version="$version"; fi
    else
      mise_tools+=("$entry")
    fi
  done

  {
    echo "mise-tools=${mise_tools[*]}"
    echo "ops-version=${ops_version}"
    echo "root=${FORGE_ROOT}"
    # Where mise stops looking for config: the directory holding the forge checkout,
    # which in a consumer's job is the consumer's own workspace (see action.yml).
    echo "ceiling=$(dirname "$FORGE_ROOT")"
  } >>"${GITHUB_OUTPUT:?}"
  echo "mise installs: ${mise_tools[*]:-(nothing)}; setup-ops installs: ${ops_version:-(nothing)}" >&2
}

put_on_path() {
  local tools bin_paths ops_path
  if [ -n "${MISE_TOOLS:-}" ]; then
    command -v mise >/dev/null || err "mise is not on PATH."
    read -ra tools <<<"$MISE_TOOLS"
    cd "$FORGE_ROOT"
    # Already installed by jdx/mise-action; this is a no-op unless its cache is stale.
    mise install "${tools[@]}" >&2
    bin_paths="$(mise bin-paths "${tools[@]}")"
    [ -n "$bin_paths" ] || err "mise reports no bin path for ${MISE_TOOLS}."
    printf '%s\n' "$bin_paths" >>"${GITHUB_PATH:?}"
    printf 'on PATH: %s\n' "$bin_paths" >&2
  fi

  if [ -n "${OPS_VERSION:-}" ]; then
    ops_path="$(VERSION="$OPS_VERSION" EXPECTED_SHA256="" \
      INSTALL_DIR="${RUNNER_TEMP:?}/setup-tools/ops" \
      "${FORGE_ROOT}/actions/setup-ops/setup-ops.sh")"
    dirname "$ops_path" >>"${GITHUB_PATH:?}"
    printf 'on PATH: %s\n' "$ops_path" >&2
  fi
}

case "${1:-}" in
  plan) plan ;;
  path) put_on_path ;;
  pin) [ $# -eq 2 ] || err "usage: $0 pin NAME"; version_of "$2" ;;
  *) err "usage: $0 plan|path|pin NAME" ;;
esac
