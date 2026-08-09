# Verified bump commits

This supersedes `ops/docs/verified-bump/README.md`, and **corrects it**.

## The correction

That spec's Option A is built on the REST Git Data API — `git/blobs` → `git/trees` →
`git/commits` → update ref. That path cannot produce a signed commit. GitHub signs a commit
only when GitHub itself builds the commit object, and the Git Data API builds it from
caller-supplied parts.

Probed directly against `rsvalerio/ops` on 2026-08-09:

| Method | `verification.verified` | `reason` |
|---|---|---|
| `git push` over HTTPS/SSH | `false` | `unsigned` (unless the pusher signs locally) |
| REST Git Data API (`git/commits`) | `false` | `unsigned` |
| REST Contents API (`PUT /contents`) | `false` | `unsigned` |
| **GraphQL `createCommitOnBranch`** | **`true`** | **`valid`** |

GraphQL is the only API path that yields a Verified badge — and it does the job in one call
rather than four.

That spec also claims the App-bot attribution change is "already applied in `bump.yml`,
`publish-deb.yml`, `publish-homebrew.yml`". That was true of **oxydraw** and false of
**ops**, where the spec lives: it was written against the other repo's state. Two copies of
a workflow, two truths, and a document that is correct about neither. Consolidating the
workflows is what removes the possibility.

## How it works

`createCommitOnBranch` sets `committer` to `GitHub / web-flow` — the signing identity — and
takes `author` from the calling token. With an App installation token the result is a
commit **authored by `my-cloud-ci[bot]` and signed by GitHub**, which is exactly the
original spec's stated goal.

The implementation is [`actions/signed-commit`](../actions/signed-commit/). It replays the
last local commit onto a branch: read `HEAD`'s subject and body, diff `base..HEAD`, turn
that into `additions` (base64 contents) and `deletions`, and send one mutation.

`expectedHeadOid: base` makes the mutation a compare-and-swap. If anything else pushed to
the branch in the meantime, it fails rather than clobbering.

## Two constraints

- **The diff is computed locally**, so `base` must be a commit present in the local clone.
  In the bump flow `base` is `HEAD^`, which always satisfies this. Anything reusing the
  action needs to check it.
- **`createCommitOnBranch` only creates commits.** The `vX.Y.Z` tag stays a
  `POST /git/refs` pointing at the new signed commit. The tag ref itself is unsigned, which
  is normal and invisible in the UI, and it still triggers the tag-driven release workflow.

## Interaction with cocogitto

The bump workflow lets `cog bump --auto` do what it is good at — decide the version from
conventional commits, run `cargo set-version`, write the CHANGELOG, commit and tag locally
— and then replaces the *transport*. The local commit is never pushed; it is replayed
through GraphQL, and the tag is recreated against the resulting SHA.

This means cocogitto's `post_bump_hooks` must not contain `git push`. If they do, cog
pushes the unsigned commit first, the branch moves past `expectedHeadOid`, and the mutation
fails with a conflict that does not explain itself. The workflow checks for this up front
and fails with a message that does.

## `[skip ci]`, incidentally

Because the commit message becomes ours to construct, `[skip ci]` can be applied directly.
`cog.toml` in both repos already sets `skip_ci = "[skip ci]"`, but that only *defines* the
marker — cocogitto applies it only when `cog bump` is passed `--skip-ci`, which no existing
workflow did. So every bump commit re-ran the full CI + Bump cycle. The shared workflow
passes `--skip-ci` by default, closing TASK-1659.
