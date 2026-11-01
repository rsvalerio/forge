---
id: TASK-0056
title: 'Private git dependencies in the other workflows that run cargo'
status: To Do
assignee: []
created_date: '2026-10-25 16:13'
labels:
  - ci
dependencies:
  - TASK-0055
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/bump.yml`, `.github/workflows/publish-deb.yml`, `docs/consuming.md`

**What**: once TASK-0055 gives rust-ci a way to fetch private git dependencies, the other reusable workflows that make cargo resolve the workspace still cannot. `bump.yml` runs `cargo set-version`, which loads the workspace metadata and fetches git dependencies that are not yet in the local cache. `publish-deb.yml` runs the consumer's `build-command`, which compiles. A private-dependency repository that passes CI would still fail to bump or package.

Out of scope: `publish-homebrew.yml` and `publish-deb-dist.yml` repackage cargo-dist artifacts and do not compile. `publish-crates.yml`: crates.io rejects git dependencies without a registry version, so a crate with a private git dependency cannot be published there. Say that in the docs rather than wiring the action in.

**Why it matters**: private repositories should get the whole forge pipeline, not only its CI half.

**Origin**: split from TASK-0055, 2026-10-25.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bump.yml and publish-deb.yml accept the same private-dependency input and secret as rust-ci.yml and run the TASK-0055 action before any cargo step
- [ ] #2 A bump of a workspace with a private git dependency succeeds
- [ ] #3 docs/consuming.md covers the input for both workflows and states why publish-homebrew, publish-deb-dist and publish-crates do not take it
<!-- AC:END -->
