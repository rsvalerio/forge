#!/usr/bin/env bash
# Keep a moving major tag (`v1`) level with a release, without ever carrying it up across
# a major. The one implementation behind release.yml (forge's own releases) and bump.yml
# (`major-tag:` consumers), so a fix to the guard or the repoint reaches both.
#
# Configured through the environment (see action.yml for the meaning of each):
#   VERSION  MAJOR_TAG  CHECK_ONLY  SHA  GH_TOKEN  REPOSITORY
#
# Writes `move=true|false` to $GITHUB_OUTPUT: whether the tag is (or, under CHECK_ONLY,
# would be) moved. Diagnostics go to stderr as GitHub annotations.
set -euo pipefail

err() { echo "::error::move-major-tag: $*" >&2; exit 1; }

VERSION="${VERSION:-}"
MAJOR_TAG="${MAJOR_TAG:-}"
CHECK_ONLY="${CHECK_ONLY:-false}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

# Never carry the moving tag UP across a major. versioning.md is explicit that a v2
# release must not repoint `v1` — consumers migrate one at a time so a bad major cannot
# take every pipeline down at once. Automation that ignored that would do the one thing
# the policy forbids, silently, on the release where it matters most.
#
# The test is `released > moving`, not `released != moving`, because a moving tag
# legitimately runs ahead of the version line while a project is pre-1.0: forge publishes
# `v1` while its own releases are 0.x, which is the whole point of a moving tag consumers
# can pin before the API is frozen. Equal (the v1.x case) and below (the 0.x case) both
# repoint; only a release that has moved past the tag is refused.
released_major="${VERSION#v}"
released_major="${released_major%%.*}"
moving_major="${MAJOR_TAG#v}"
moving_major="${moving_major%%.*}"
# `-gt` on a non-numeric operand aborts with "integer expression expected", which is a
# baffling way for a release to fail. Say what is actually wrong.
case "${released_major}:${moving_major}" in
  *[!0-9:]* | :* | *: | *::*)
    err "cannot compare majors of version '${VERSION}' and major tag '${MAJOR_TAG}'." \
        "Both must look like vN.N.N / vN."
    ;;
esac

if [ "$released_major" -gt "$moving_major" ]; then
  echo "::notice::${VERSION} is past ${MAJOR_TAG}; leaving ${MAJOR_TAG} where it is." \
       "Publish v${released_major} and migrate consumers deliberately."
  echo "move=false" >>"$GITHUB_OUTPUT"
  exit 0
fi
echo "move=true" >>"$GITHUB_OUTPUT"

if [ "$CHECK_ONLY" = "true" ]; then
  echo "${MAJOR_TAG} would move to ${VERSION} (check-only: nothing written)"
  exit 0
fi

SHA="${SHA:-}"
REPOSITORY="${REPOSITORY:-}"
[ -n "$SHA" ] || err "'sha' is required unless check-only is true."
[ -n "${GH_TOKEN:-}" ] || err "'token' is required unless check-only is true."
[ -n "$REPOSITORY" ] || err "'repository' is empty."

# Lightweight ref, deliberately: `git tag -f` produces a tag *object*, and pointing one
# tag object at another is what versioning.md's `^{}` peel exists to avoid. The API only
# ever creates lightweight refs here, so the shape cannot drift.
#
# PATCH with force moves an existing ref; POST creates it the first time. Try the move
# first and fall back, so this is correct on a repository that has never published the
# tag as well as on every release after that.
if gh api -X PATCH "/repos/${REPOSITORY}/git/refs/tags/${MAJOR_TAG}" \
     -f "sha=${SHA}" -F force=true >/dev/null 2>&1; then
  echo "repointed ${MAJOR_TAG} at ${SHA}"
elif gh api "/repos/${REPOSITORY}/git/refs" \
       -f "ref=refs/tags/${MAJOR_TAG}" -f "sha=${SHA}" >/dev/null; then
  echo "created ${MAJOR_TAG} at ${SHA}"
else
  err "could not point ${MAJOR_TAG} at ${SHA}."
fi
