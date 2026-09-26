#!/usr/bin/env bash
# forge's static checks, one per subcommand. test-self.yml's lint job and `ops verify`
# both call this script, so the local gate and CI run the same checks and cannot drift.
#
#   ci/lint.sh shellcheck | executable | action-yml | config-toml | pinned-actions
#
# Run from the repository root. Errors go to stderr (ops shows a failing step's stderr)
# as GitHub `::error` annotations, which the runner parses on either stream and
# which read fine in a terminal too.
set -euo pipefail
shopt -s globstar nullglob

# Every shell script forge ships or runs itself.
scripts() {
  local s=(actions/**/*.sh ci/*.sh)
  [ ${#s[@]} -eq 0 ] || printf '%s\n' "${s[@]}"
}

check_shellcheck() {
  local files
  mapfile -t files < <(scripts)
  printf 'checking %s\n' "${files[@]}"
  shellcheck "${files[@]}" >&2
}

check_executable() {
  local f status=0
  while IFS= read -r f; do
    [ -x "$f" ] || { echo "::error file=$f::not executable (chmod +x)" >&2; status=1; }
  done < <(scripts)
  return $status
}

# yq fails on a file that is not valid YAML, so an unparseable action.yml fails here as
# "missing required key" rather than slipping through. actionlint only reads an
# action.yml through a workflow's local `uses: ./actions/...`, so it is not a substitute.
check_action_yml() {
  local dir f key status=0
  for dir in actions/*/; do
    f="${dir}action.yml"
    if [ ! -f "$f" ]; then
      echo "::error::${dir} has no action.yml" >&2; status=1; continue
    fi
    for key in name description runs; do
      yq -e ".${key}" "$f" >/dev/null 2>&1 \
        || { echo "::error file=$f::missing required key '${key}' (or not valid YAML)" >&2; status=1; }
    done
    [ "$(yq -r '.runs.using' "$f" 2>/dev/null)" = "composite" ] \
      || { echo "::error file=$f::runs.using must be 'composite'" >&2; status=1; }
  done
  return $status
}

check_config_toml() {
  local f
  for f in config/*.toml; do
    yq -p toml -o json "$f" >/dev/null || { echo "::error file=$f::invalid TOML" >&2; return 1; }
    echo "ok: $f"
  done
}

# README design rule: a third-party action is pinned to a full commit SHA with its
# version tag in a comment. Local (`./`) and forge's own (`rsvalerio/forge/`) refs are
# exempt; forge's own follow docs/versioning.md.
check_pinned_actions() {
  local f line ref status=0
  local pinned='^[^@[:space:]]+@[0-9a-f]{40}[[:space:]]+#[[:space:]]*v[0-9][^[:space:]]*'
  for f in .github/workflows/*.yml .github/workflows/*.yaml actions/*/action.yml; do
    while IFS= read -r line; do
      ref="${line#*uses:}"
      ref="${ref#"${ref%%[![:space:]]*}"}"   # trim leading whitespace
      ref="${ref//[\"\']/}"                  # drop quotes
      case "$ref" in ./* | rsvalerio/forge/*) continue ;; esac
      [[ "$ref" =~ $pinned ]] || {
        echo "::error file=$f::not SHA-pinned with a version comment: ${ref}" >&2
        status=1
      }
    done < <(grep -E '^[[:space:]]*(-[[:space:]]+)?uses:' "$f")
  done
  return $status
}

case "${1:-}" in
  shellcheck) check_shellcheck ;;
  executable) check_executable ;;
  action-yml) check_action_yml ;;
  config-toml) check_config_toml ;;
  pinned-actions) check_pinned_actions ;;
  *)
    echo "usage: $0 shellcheck|executable|action-yml|config-toml|pinned-actions" >&2
    exit 2
    ;;
esac
