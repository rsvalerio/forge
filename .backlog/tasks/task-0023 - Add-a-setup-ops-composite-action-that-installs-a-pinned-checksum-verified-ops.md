---
id: TASK-0023
title: 'Add a setup-ops composite action that installs a pinned, checksum-verified ops'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:59'
labels:
  - ci
  - ops-alignment
dependencies: []
parent_task_id: 'TASK-0035'
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
- [x] #1 `uses: ./actions/setup-ops` (and `rsvalerio/forge/actions/setup-ops@v1`) with a required `version` input installs that exact ops release for the runner's arch, verifying the published sha256 before extracting
- [x] #2 Fails loudly on an unknown version, unsupported arch or checksum mismatch; `ops --version` is asserted
- [x] #3 Exercised in test-self; documented in docs/consuming.md
- [x] #4 Passes `ci/lint.sh` (executable scripts, well-formed action.yml, pinned actions)

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
actions/setup-ops (action.yml + setup-ops.sh): exact version input (no latest), Linux/macOS x X64/ARM64 mapped from RUNNER_OS/RUNNER_ARCH, gh release download with token, sidecar sha256 checked before extract plus optional sha256 pin input, ops --version asserted before install. Failure paths (unknown version, checksum mismatch, bad arch, latest) exercised locally against the real v0.72.0 release; test-self gains a setup-ops job asserting unknown-version and mismatch fail and install nothing; lint job uses it for the happy path. Documented in docs/consuming.md#setup-ops.
<!-- SECTION:NOTES:END -->
