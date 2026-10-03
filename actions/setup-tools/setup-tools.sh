#!/usr/bin/env bash
# Install tools at pinned versions and put them on PATH. `ops` goes through
# actions/setup-ops (sha256-verified); every other tool through mise, always under forge's
# mise.toml (its aliases and backends). The versions are forge's mise.toml pins, or with
# PINS=repo the caller's own mise.toml pins where it has one for the tool.
#
#   setup-tools.sh plan     resolve TOOLS to versions; write step outputs
#   setup-tools.sh path     after mise installed them: put the tools on PATH, install ops
#
# Configured through the environment (see action.yml for the meaning of each):
#   TOOLS  PINS  PINS_DIRECTORY  FORGE_ROOT  GITHUB_WORKSPACE  GH_TOKEN  RUNNER_TEMP
#   GITHUB_OUTPUT  GITHUB_PATH
#   MISE_TOOLS  OPS_VERSION  (path: the plan's outputs)
set -euo pipefail

err() { echo "::error::setup-tools: $*" >&2; exit 1; }

FORGE_ROOT="$(cd "${FORGE_ROOT:?}" && pwd)"
config="${FORGE_ROOT}/mise.toml"
[ -f "$config" ] || err "no mise.toml in ${FORGE_ROOT}."

version_re='^[A-Za-z0-9][A-Za-z0-9._+-]*$'

# The value of `<key> = ...` in FILE's [TABLE] table, as written, or nothing. For the
# tools table, a `[tools.<key>]` sub-table prints as the inline table it stands for.
pin_in() { # file table key
  awk -v table="$2" -v want="$3" '
    /^[[:space:]]*\[/ {
      header = $0; sub(/#.*/, "", header); gsub(/[[:space:]"\047]/, "", header)
      in_table = (header == "[" table "]")
      in_own = (table == "tools" && header == "[tools." want "]")
      next
    }
    in_table && /=/ {
      key = $0; sub(/[[:space:]]*=.*/, "", key); gsub(/^[[:space:]]+|["\047]/, "", key)
      if (key == want) { val = $0; sub(/^[^=]*=[[:space:]]*/, "", val); print val; exit }
    }
    in_own && /^[[:space:]]*version[[:space:]]*=/ {
      val = $0; sub(/^[^=]*=[[:space:]]*/, "", val); print "{ version = " val " }"; exit
    }' "$1"
}

# The version in a pin as pin_in prints it: `"1.2.3"` and `{ version = "1.2.3", ... }`
# both print 1.2.3, in either TOML quote. Anything else (an array, a table with no
# version) prints nothing.
version_in() {
  local q="[\"']" unq="[^\"']*"
  local plain="^${q}(${unq})${q}"
  local table="^\{(.*[,[:space:]])?version[[:space:]]*=[[:space:]]*${q}(${unq})${q}"
  if [[ "$1" =~ $plain ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$1" =~ $table ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
  fi
}

# The caller's mise.toml files, nearest first: PINS_DIRECTORY's, then each directory's
# above it up to the workspace root, the order mise itself gives them. Only mise.toml is
# looked for, not mise's other config names.
caller_configs() {
  local workspace dir found=0
  workspace="$(cd "${GITHUB_WORKSPACE:?}" && pwd -P)"
  dir="$(cd "$workspace" && cd "${PINS_DIRECTORY:-.}" 2>/dev/null && pwd -P)" \
    || err "pins-directory '${PINS_DIRECTORY:-.}' is not a directory."
  case "${dir}/" in
    "${workspace}/"*) ;;
    *) err "pins-directory '${PINS_DIRECTORY:-.}' is outside the workspace." ;;
  esac
  while :; do
    if [ -f "${dir}/mise.toml" ]; then printf '%s\n' "${dir}/mise.toml"; found=1; fi
    [ "$dir" != "$workspace" ] || break
    dir="$(dirname "$dir")"
  done
  # Asked for and absent is a wrong directory or a missing file, not a reason to fall
  # back to forge's pins without saying so.
  [ "$found" = 1 ] \
    || err "pins is 'repo' but there is no mise.toml in '${PINS_DIRECTORY:-.}' or above it."
}

# NAME's version in the caller's mise.toml files, or nothing. The entry is found under
# NAME or under the backend forge's [tool_alias] gives NAME (`"cargo:cargo-edit"`). Only
# the version is taken: the install still runs under forge's mise.toml, so the caller's
# own aliases, tool options, hooks and settings never reach it.
caller_version() {
  local name="$1" backend file value version
  backend="$(version_in "$(pin_in "$config" tool_alias "$name")")"
  for file in "${caller_files[@]}"; do
    value="$(pin_in "$file" tools "$name")"
    if [ -z "$value" ] && [ -n "$backend" ]; then value="$(pin_in "$file" tools "$backend")"; fi
    [ -n "$value" ] || continue
    version="$(version_in "$value")"
    [[ "$version" =~ $version_re ]] \
      || err "'${name}' is pinned as ${value} in ${file}; this needs one plain \"version\"."
    printf '%s\n' "$version"
    return
  done
}

plan() {
  local entries entry name version source found file ops_version="" mise_tools=() caller_files=()
  # A comma- or whitespace-separated list, newlines included.
  read -ra entries -d '' <<<"$(printf '%s' "${TOOLS:-}" | tr ',' ' ')" || true
  [ ${#entries[@]} -gt 0 ] || err "'tools' names no tool."

  case "${PINS:-forge}" in
    forge) ;;
    repo)
      found="$(caller_configs)"
      while IFS= read -r file; do caller_files+=("$file"); done <<<"$found"
      ;;
    *) err "pins is '${PINS}'; it is 'forge' or 'repo'." ;;
  esac

  for entry in "${entries[@]}"; do
    name="${entry%%@*}"
    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || err "'${entry}' is not a tool name."
    if [ "$entry" != "$name" ]; then
      version="${entry#*@}"
      [[ "$version" =~ $version_re ]] || err "'${entry}' names no version."
      source="given"
    else
      version=""
      if [ ${#caller_files[@]} -gt 0 ]; then version="$(caller_version "$name")"; fi
      if [ -n "$version" ]; then
        entry="${name}@${version}"
        source="the repository's mise.toml"
      else
        # The pin is the point: a tool mise.toml does not list would install at whatever
        # is newest, and drift between runs.
        version="$(version_in "$(pin_in "$config" tools "$name")")"
        [ -n "$version" ] \
          || err "'${name}' has no version in forge's mise.toml; add it there, or pass '${name}@<version>'."
        source="forge's mise.toml"
      fi
    fi
    echo "${name} ${version} (${source})" >&2
    if [ "$name" = ops ]; then ops_version="$version"; else mise_tools+=("$entry"); fi
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
  *) err "usage: $0 plan|path" ;;
esac
