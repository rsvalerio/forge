---
id: TASK-0029
title: 'Add an MSRV gate to rust-ci'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0026
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
- [ ] #1 rust-ci can check the workspace against `rust-version`, preferably via an ops msrv command so the logic is not duplicated
<!-- AC:END -->
