#!/usr/bin/env bash
# Copy one or more .debs into an apt repository's pool and record them as ONE commit.
#
# Runs inside a clone of the apt repository whose git identity is already configured.
# Everything is passed through the environment so action.yml stays a thin wrapper:
#
#   DEBS      newline-separated .deb paths (relative to the caller's cwd, or absolute)
#   POOL      pool directory inside the apt repository
#   PACKAGE   package label for the commit message
#   VERSION   version label for the commit message
#   DRY_RUN   "true" stages and prints the diff, then stops before committing
#   APT_DIR   the apt repository clone
#   KEEP_VERSIONS
#             when > 0, keep only the newest N versions of each published package+arch
#             in the pool, removing the rest in the same commit; 0 keeps everything
#
# Writes `changed=` and `pushed=` to $GITHUB_OUTPUT when it is set.
set -euo pipefail

: "${DEBS:?}" "${POOL:?}" "${PACKAGE:?}" "${VERSION:?}" "${APT_DIR:?}"
DRY_RUN="${DRY_RUN:-false}"
KEEP_VERSIONS="${KEEP_VERSIONS:-0}"

if ! [[ "$KEEP_VERSIONS" =~ ^[0-9]+$ ]]; then
  echo "::error::apt-pool-push: 'keep-versions' must be a non-negative integer, got '$KEEP_VERSIONS'." >&2
  exit 1
fi

output() {
  [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1" >>"$GITHUB_OUTPUT"
  return 0
}

debs=()
while IFS= read -r line; do
  # Trim surrounding whitespace so an indented YAML block scalar still parses.
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -n "$line" ] && debs+=("$line")
done <<<"$DEBS"

if [ "${#debs[@]}" -eq 0 ]; then
  echo "::error::apt-pool-push: 'debs' lists no files." >&2
  exit 1
fi

# A caller-exported GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE would redirect every git
# command below away from the apt clone.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR

for i in "${!debs[@]}"; do
  deb="${debs[$i]}"
  if [ ! -f "$deb" ]; then
    echo "::error::apt-pool-push: .deb not found: $deb" >&2
    exit 1
  fi
  # A file that is not a Debian package would reach the pool and break the apt
  # repository's next aptly index run, for every package in it.
  # shellcheck disable=SC2016 # ${Package} etc. are dpkg-deb format fields, not shell.
  if ! fields="$(dpkg-deb --show --showformat='${Package}_${Version}_${Architecture}' "$deb" 2>/dev/null)"; then
    echo "::error::apt-pool-push: not a valid .deb: $deb" >&2
    exit 1
  fi
  # Retention finds versions by filename, so a package named off-convention is never
  # pruned. Epochs are left out of pool filenames by convention.
  expected="${fields}.deb"
  if [[ "$fields" =~ ^([^_]+_)[0-9]+:(.*)$ ]]; then
    expected="${BASH_REMATCH[1]}${BASH_REMATCH[2]}.deb"
  fi
  if [ "$(basename "$deb")" != "$expected" ]; then
    echo "::warning::apt-pool-push: $(basename "$deb") does not match its control fields" \
         "(${expected}); keep-versions cannot prune it." >&2
  fi
  # Absolute, because staging runs inside the apt clone and may run more than once.
  debs[i]="$(cd "$(dirname "$deb")" && pwd)/$(basename "$deb")"
done

cd "$APT_DIR"

# Copy, stage and prune against the current checkout. Rerun from scratch when a push is
# rejected, so retention is decided against the pool that actually gets pushed onto.
pruned=()
stage() {
  mkdir -p "$POOL"
  for deb in "${debs[@]}"; do
    cp "$deb" "${POOL}/"
    git add -- "${POOL}/$(basename "$deb")"
  done

  # Retention. Pool files are named `<package>_<version>_<arch>.deb`, and Debian forbids
  # `_` in both package names and versions, so splitting on `_` is exact: `my-haproxy`
  # never matches `my-haproxy-sites_...`, which a prefix glob would.
  pruned=()
  [ "$KEEP_VERSIONS" -gt 0 ] || return 0

  local -A targets=()
  local deb target pkg arch f base rest v i placed old
  for deb in "${debs[@]}"; do
    targets["$(dpkg-deb -f "$deb" Package)_$(dpkg-deb -f "$deb" Architecture)"]=1
  done

  for target in "${!targets[@]}"; do
    pkg="${target%_*}"
    arch="${target##*_}"
    local versions=() sorted=()
    for f in "${POOL}"/*.deb; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .deb)"
      [ "${base%%_*}" = "$pkg" ] || continue
      [ "${base##*_}" = "$arch" ] || continue
      rest="${base#*_}"
      versions+=("${rest%_*}")
    done

    # Newest first. N is single digits in practice, so an insertion sort over
    # dpkg's comparator beats pulling in anything heavier.
    for v in "${versions[@]}"; do
      placed=false
      for i in "${!sorted[@]}"; do
        if dpkg --compare-versions "$v" gt "${sorted[$i]}"; then
          sorted=("${sorted[@]:0:$i}" "$v" "${sorted[@]:$i}")
          placed=true
          break
        fi
      done
      $placed || sorted+=("$v")
    done

    for v in "${sorted[@]:$KEEP_VERSIONS}"; do
      old="${POOL}/${pkg}_${v}_${arch}.deb"
      # -f: the file may be one this call just staged (a backfill older than the newest N).
      git rm -q -f -- "$old"
      pruned+=("$old")
    done
  done

  for deb in "${debs[@]}"; do
    for old in "${pruned[@]}"; do
      if [ "$old" = "${POOL}/$(basename "$deb")" ]; then
        echo "::warning::apt-pool-push: $(basename "$deb") is older than the newest" \
             "${KEEP_VERSIONS} in the pool, so retention removed it again." >&2
      fi
    done
  done
}

no_changes() {
  echo "No changes to publish (every package already present)."
  output changed=false
  output pushed=false
}

commit() {
  local message=("-m" "${PACKAGE}: add ${VERSION}")
  if [ "${#pruned[@]}" -gt 0 ]; then
    message+=("-m" "Retention (keep-versions=${KEEP_VERSIONS}) removed:
$(printf -- '- %s\n' "${pruned[@]}")")
  fi
  git commit -q "${message[@]}"
  git --no-pager show --stat --format='%h %s' HEAD
}

stage
if git diff --cached --quiet; then
  no_changes
  exit 0
fi
output changed=true

if [ "$DRY_RUN" = "true" ]; then
  echo "::notice::dry-run: ${#debs[@]} .deb(s) staged in ${POOL}/, not committed or pushed."
  git --no-pager diff --cached --stat
  output pushed=false
  exit 0
fi

commit

# Every publisher pushes to the same branch, so a release that lands between our
# checkout and our push rejects it. Rebuild the commit on the new tip and try again.
branch="$(git symbolic-ref --short HEAD)"
attempts=4
for attempt in $(seq 1 "$attempts"); do
  if git push origin HEAD; then
    output pushed=true
    exit 0
  fi
  [ "$attempt" -lt "$attempts" ] || break
  echo "::warning::apt-pool-push: push rejected (attempt ${attempt}/${attempts}); restaging on the new ${branch} tip." >&2
  sleep $((attempt * 2))
  git fetch -q origin "$branch"
  git reset -q --hard FETCH_HEAD
  stage
  if git diff --cached --quiet; then
    no_changes
    exit 0
  fi
  commit
done

echo "::error::apt-pool-push: push to ${branch} failed after ${attempts} attempts." >&2
exit 1
