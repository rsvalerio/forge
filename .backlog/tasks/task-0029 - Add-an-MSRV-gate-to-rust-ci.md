---
id: TASK-0029
title: 'Add an MSRV gate to rust-ci'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 17:25'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0026
parent_task_id: 'TASK-0044'
modified_files:
  - .github/workflows/rust-ci.yml
priority: low
ordinal: 1000
dedup_key: 'ops-align:msrv'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/rust-ci.yml`

**What**: rust-ci only runs `toolchain: stable`; ops's own ci.yml hand-rolls an MSRV job (reads `rust-version`, installs that toolchain) and the clippy-pedantic skill requires clippy `msrv` to equal `rust-version`. Nothing checks it for other consumers.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 rust-ci can check the workspace against `rust-version`, preferably via an ops msrv command so the logic is not duplicated

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
rust-ci run-msrv (default false, either engine) adds an MSRV job running `ops msrv --install` through actions/setup-rust, so the rust-version/clippy msrv logic lives only in ops. test-self rust-ci-ops runs it against ci/fixtures/rust-ci/ops (rust-version 1.85 + clippy.toml msrv).
<!-- SECTION:NOTES:END -->
