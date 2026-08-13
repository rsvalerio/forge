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

# File contents never travel through argv. Linux caps a SINGLE argument at
# MAX_ARG_STRLEN — 32 pages, 128 KiB — independently of the much larger total ARG_MAX,
# and base64 inflates by 4/3. ops's CHANGELOG.md is 295 KiB encoded, so passing it as
# `--arg c "$(b64 "$path")"` died with "jq: Argument list too long" (exit 126). Building
# the array up in a shell variable had the same defect one level up: the final
# `--argjson additions` carried every file's payload at once.
#
# So each record is written as one line of JSON to a temp file, contents included via
# --rawfile, and the payload assembled with --slurpfile. Nothing large is ever an
# argument. --slurpfile on an empty file yields [], which is what the mutation wants for
# "no deletions".
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
additions="$work/additions.jsonl"
deletions="$work/deletions.jsonl"
: >"$additions"
: >"$deletions"

# -z keeps paths intact regardless of spaces, tabs or newlines in filenames. With
# --no-renames every record is a plain "<status>\0<path>\0" pair.
while IFS= read -r -d '' status && IFS= read -r -d '' path; do
  case "$status" in
    D)
      jq -nc --arg p "$path" '{path: $p}' >>"$deletions"
      ;;
    *)
      # A and M both resolve to "this path now has this content".
      # base64 -w0 is GNU-only; pipe through tr so this also runs on macOS during
      # local testing. No trailing newline, so --rawfile reads the blob verbatim.
      base64 <"$path" | tr -d '\n' >"$work/blob"
      jq -nc --arg p "$path" --rawfile c "$work/blob" '{path: $p, contents: $c}' >>"$additions"
      ;;
  esac
done < <(git diff -z --name-status --no-renames "$base" HEAD)

if [ ! -s "$additions" ] && [ ! -s "$deletions" ]; then
  echo "signed-commit: no changes between $base and HEAD; nothing to commit" >&2
  exit 1
fi

jq -nc \
  --arg repo "$repo" --arg branch "$branch" --arg base "$base" \
  --arg headline "$headline" --arg body "$body" \
  --slurpfile additions "$additions" --slurpfile deletions "$deletions" \
  '{
    query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }",
    variables: {input: {
      branch: {repositoryNameWithOwner: $repo, branchName: $branch},
      message: {headline: $headline, body: $body},
      expectedHeadOid: $base,
      fileChanges: {additions: $additions, deletions: $deletions}
    }}
  }' | gh api graphql --input - --jq '.data.createCommitOnBranch.commit.oid'
