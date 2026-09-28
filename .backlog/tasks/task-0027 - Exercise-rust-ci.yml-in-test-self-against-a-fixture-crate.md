---
id: TASK-0027
title: 'Exercise rust-ci.yml in test-self against a fixture crate'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:58'
labels:
  - ci
  - test
dependencies: []
parent_task_id: 'TASK-0034'
modified_files:
  - .github/workflows/test-self.yml
priority: medium
ordinal: 1000
dedup_key: 'ops-align:test-self-rust-ci'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml`

**What**: test-self never runs `rust-ci.yml` (or publish-crates), so #16's setup-rust-toolchain v2 behaviour change merged green. forge-testbed runs it only on its own triggers.

**Why it matters**: rust-ci is the most-consumed workflow and is about to be rebuilt on ops.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 test-self calls ./.github/workflows/rust-ci.yml against a small in-repo fixture crate on every PR
- [x] #2 The fixture includes a deliberate warning-free and a warning case so the warnings policy is asserted

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
test-self.yml gains rust-ci-clean and rust-ci-warning, both `uses: ./.github/workflows/rust-ci.yml` on every PR, against self-contained fixture crates in ci/fixtures/rust-ci/{clean,warning} (each its own [workspace] root, publish = false, no deps; run-deny: false). clean runs default clippy-args (-D warnings); warning carries one deliberate unused_variables warning and runs clippy-args "" so every job must pass, which fails if CARGO_BUILD_WARNINGS=deny comes back (verified locally: CARGO_BUILD_WARNINGS=deny cargo check fails on it, plain check passes). The two calls also cover use-sccache true/false.
<!-- SECTION:NOTES:END -->
