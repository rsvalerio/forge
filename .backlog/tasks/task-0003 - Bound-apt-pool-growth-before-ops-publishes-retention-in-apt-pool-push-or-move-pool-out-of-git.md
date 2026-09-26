---
id: TASK-0003
title: 'Bound apt pool growth before ops publishes (retention in apt-pool-push, or move pool out of git)'
status: Done
assignee: []
created_date: '2026-09-26 16:33'
updated_date: '2026-09-26 17:08'
labels:
  - deb
  - apt
dependencies:
  - TASK-0002
parent_task_id: 'TASK-0009'
modified_files:
  - actions/apt-pool-push/action.yml
  - docs/consuming.md
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The apt repo keeps its `.deb` files in git. `rsvalerio/apt` already has a 92 MB `.git` and a 101 MB `pool/`, and `scripts/squash-history.sh` exists because this has hit a limit before. ops would make it much worse: each release adds about 14 MB (linux-gnu binaries of roughly 7 MB, for amd64 and arm64), and ops has shipped 65 releases. Adopting ops without dealing with this would grow the repo by gigabytes.

This has to be decided and implemented **before** ops adopts apt publishing.

Options to weigh:

1. **Retention in `apt-pool-push` (recommended).** Add a `keep-versions` input (for example 3). In the same commit that adds the new files, `git rm` any `pool/<pkg>_<version>_<arch>.deb` beyond the newest N for that package and arch, comparing versions with `dpkg --compare-versions`. Squash history on a schedule, or document when to run `squash-history.sh`. This is a small change and keeps the current design.
2. **Take the pool out of git.** The apt repo's `publish.yml` would build the pool at index time from GitHub Release assets listed in a manifest file (or discovered through the API). Publishers would commit a manifest line instead of a binary. Git stays small, but it is a larger change across `rsvalerio/apt` and every publisher.

Either way:
- Deleting a version stops `apt install <pkg>=<old>` from working. Document the retention rule in the apt README.
- Package names with a `-` must not over-match (for example `my-haproxy` versus `my-haproxy-sites`). Parse the filename on the `_` boundaries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A decision between retention and moving the pool out of git is recorded in the task notes
- [x] #2 Publishing a new version drops versions of that package+arch older than the newest N in the same commit (if retention is chosen)
- [x] #3 Packages whose names are prefixes of other packages (my-haproxy vs my-haproxy-sites) are pruned independently
- [x] #4 The retention rule is documented for rsvalerio/apt consumers

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: retention in apt-pool-push (option 1), not moving the pool out of git. Retention is a bounded change inside forge that keeps the current apt design. Taking the pool out of git would need a coordinated change across rsvalerio/apt's publish.yml and every publisher, with no benefit until the pool itself is the bottleneck.
Implementation: `keep-versions` input (default 0 = keep all, so publish-deb/oxydraw is unchanged; publish-deb-dist defaults to 3). In the same commit it `git rm`s versions of each published package+arch beyond the newest N, sorted with dpkg --compare-versions. Pool filenames are split on `_`, so my-haproxy and my-haproxy-sites are pruned independently. A backfill older than the newest N warns and pushes nothing.
Tests: actions/apt-pool-push/pool-update.test.sh, run by the new test-self.yml job `apt-pool-push`.
AC4: the retention rule and the `squash-history.sh` guidance are documented in forge docs/consuming.md ("Retention"), including what apt users see (pinned `pkg=<old>` stops resolving). The mirror in rsvalerio/apt's own README is a cross-repo edit and is filed as a Triage follow-up.

apt README mirror filed as TASK-0011.

<!-- SECTION:NOTES:END -->
