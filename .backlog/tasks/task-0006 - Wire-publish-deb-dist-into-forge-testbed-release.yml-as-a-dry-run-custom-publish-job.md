---
id: TASK-0006
title: 'Wire publish-deb-dist into forge-testbed release.yml as a dry-run custom publish job'
status: Triage
assignee: []
created_date: '2026-09-26 16:34'
labels:
  - deb
  - cargo-dist
  - testbed
dependencies:
  - TASK-0005
modified_files:
  - docs/consuming.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The testbed's `publish-deb.yml` runs daily and on demand, outside `release.yml`, because forge had no workflow that fit the dist custom publish job signature. That means the real path (dist builds the archives, the custom publish job packages them, then the push to the pool) is never exercised end to end.

Once `publish-deb-dist.yml` exists:
- Add a local `.github/workflows/publish-deb.yml` wrapper with `on: workflow_call` and a `plan` input, which calls `rsvalerio/forge/.github/workflows/publish-deb-dist.yml` with `apt-repository: rsvalerio/apt-testbed` and `dry-run: true`.
- Add `./publish-deb` to `publish-jobs` in `dist-workspace.toml`. Add `custom-publish-deb` to `release.yml` next to `custom-publish-homebrew`, and to `announce.needs` and its `if:`.
- Keep a scheduled or dispatch trigger that runs the Makefile-based `publish-deb.yml` path, so both forge workflows stay covered. Rename the file if the names collide.
- Add linux-gnu targets to the testbed's dist config if they are missing, including `aarch64-unknown-linux-gnu`, so the multi-arch path is tested.

This is the gate before any real consumer adopts it: a testbed release must go green and its artifact must contain an installable `testbed-cli_<v>_amd64.deb` and `testbed-cli_<v>_arm64.deb`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A forge-testbed release runs custom-publish-deb after host and before announce
- [ ] #2 The run produces amd64 and arm64 .debs that install with apt-get install ./file.deb
- [ ] #3 dry-run against rsvalerio/apt-testbed stages both files in one diff without pushing
- [ ] #4 announce still waits on and tolerates a skipped custom-publish-deb
<!-- AC:END -->
