---
id: TASK-0023
title: 'Add a setup-ops composite action that installs a pinned, checksum-verified ops'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ci
  - ops-alignment
dependencies: []
modified_files:
  - actions/setup-ops/action.yml
  - actions/setup-ops/setup-ops.sh
  - .github/workflows/test-self.yml
  - docs/consuming.md
priority: high
ordinal: 1000
dedup_key: 'ops-align:setup-ops'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `actions/setup-ops/`

**What**: no workflow can call `ops` today: ops is not on crates.io, there is no setup action, and ops's own ci.yml removed an unpinned 'Install ops' step (SEC-37). ops releases (cargo-dist) publish `ops-{x86_64,aarch64}-unknown-linux-gnu.tar.gz` plus `.sha256`; test-self already downloads a pinned ops tarball as a fixture, so the pattern is proven.

**Why it matters**: every ops-based CI change (test-self, rust-ci, ops's own CI, ai) depends on this being the one pinned, verified way to get ops on a runner.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `uses: ./actions/setup-ops` (and `rsvalerio/forge/actions/setup-ops@v1`) with a required `version` input installs that exact ops release for the runner's arch, verifying the published sha256 before extracting
- [ ] #2 Fails loudly on an unknown version, unsupported arch or checksum mismatch; `ops --version` is asserted
- [ ] #3 Exercised in test-self; documented in docs/consuming.md
- [ ] #4 Passes `ci/lint.sh` (executable scripts, well-formed action.yml, pinned actions)
<!-- AC:END -->
