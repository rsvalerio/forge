#!/usr/bin/env bash
# Re-create the working tree's last commit as a GitHub-signed commit on a branch.
#
# GitHub signs a commit only when *it* builds the commit object. Empirically (2026-08-09,
# probed against rsvalerio/ops):
#
#   git push over HTTPS/SSH ........... unsigned, unless the pusher signs locally
#   REST Git Data API (git/commits) ... unsigned
#   REST Contents API (PUT contents) .. unsigned
#   GraphQL createCommitOnBranch ...... SIGNED (committer: GitHub / web-flow)
#
# So GraphQL is the only API path that yields a Verified badge. See docs/verified-bump.md.
#
# The commit's *author* is taken from the calling token's identity, so invoking this with a
# GitHub App installation token attributes the commit to that App's bot.
#
# Usage: signed-commit.sh <owner/repo> <branch> <base-sha>
#
# Replays the diff between <base-sha> and HEAD onto <branch> (which must currently be at
# <base-sha>), reusing HEAD's commit message. Prints the new commit SHA on stdout.
#
# Constraint: the diff is computed LOCALLY, so <base-sha> must be a commit in this clone.
# In the bump flow that is HEAD^, which always satisfies it.
set -euo pipefail

repo="${1:?usage: signed-commit.sh <owner/repo> <branch> <base-sha>}"
branch="${2:?missing branch}"
base="${3:?missing base sha}"

for tool in git jq gh; do
  command -v "$tool" >/dev/null || { echo "signed-commit: $tool not found on PATH" >&2; exit 1; }
done

# GraphQL takes the subject and body as separate fields.
headline="$(git log -1 --format=%s HEAD)"
body="$(git log -1 --format=%b HEAD)"

# base64 -w0 is GNU-only; pipe through tr so this also runs on macOS during local testing.
b64() { base64 <"$1" | tr -d '\n'; }

additions='[]'
deletions='[]'
# -z keeps paths intact regardless of spaces, tabs or newlines in filenames. With
# --no-renames every record is a plain "<status>\0<path>\0" pair.
while IFS= read -r -d '' status && IFS= read -r -d '' path; do
  case "$status" in
    D)
      deletions="$(jq -c --arg p "$path" '. + [{path: $p}]' <<<"$deletions")"
      ;;
    *)
      # A and M both resolve to "this path now has this content".
      additions="$(jq -c --arg p "$path" --arg c "$(b64 "$path")" \
        '. + [{path: $p, contents: $c}]' <<<"$additions")"
      ;;
  esac
done < <(git diff -z --name-status --no-renames "$base" HEAD)

if [ "$additions" = '[]' ] && [ "$deletions" = '[]' ]; then
  echo "signed-commit: no changes between $base and HEAD; nothing to commit" >&2
  exit 1
fi

jq -nc \
  --arg repo "$repo" --arg branch "$branch" --arg base "$base" \
  --arg headline "$headline" --arg body "$body" \
  --argjson additions "$additions" --argjson deletions "$deletions" \
  '{
    query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }",
    variables: {input: {
      branch: {repositoryNameWithOwner: $repo, branchName: $branch},
      message: {headline: $headline, body: $body},
      expectedHeadOid: $base,
      fileChanges: {additions: $additions, deletions: $deletions}
    }}
  }' | gh api graphql --input - --jq '.data.createCommitOnBranch.commit.oid'
