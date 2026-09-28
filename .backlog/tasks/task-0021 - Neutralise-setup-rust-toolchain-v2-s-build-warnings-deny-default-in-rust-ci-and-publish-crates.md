---
id: TASK-0021
title: 'Neutralise setup-rust-toolchain v2''s build-warnings=deny default in rust-ci and publish-crates'
status: To Do
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:43'
labels:
  - ci
  - regression
dependencies: []
parent_task_id: 'TASK-0034'
modified_files:
  - .github/workflows/rust-ci.yml
  - .github/workflows/publish-crates.yml
priority: high
ordinal: 1000
dedup_key: 'ops-align:build-warnings'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/rust-ci.yml`, `.github/workflows/publish-crates.yml`

**What**: Dependabot #16 moved setup-rust-toolchain v1.17.0 -> v2.0.0. v2 adds `build-warnings` (default `deny`), exporting `CARGO_BUILD_WARNINGS=deny`, so on cargo 1.97+ every rustc warning fails check, build, test, clippy (bypassing the `clippy-args` policy) and `cargo publish` (which builds, also under `--dry-run`). `rustflags: ""` is now a no-op (v2's default is already empty). publish-crates also omits `cache: false`, so it silently runs rust-cache unlike rust-ci.

**Why it matters**: tightening a gate so a green consumer goes red is breaking under docs/versioning.md. `v1` still points at v0.4.0 (pre-#16), so consumers are safe only until the next release; forge-testbed on @main is already exposed.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every setup-rust-toolchain step in rust-ci and publish-crates passes `build-warnings: ""` (or the workflow sets CARGO_BUILD_WARNINGS), so warnings policy stays with clippy-args
- [ ] #2 The no-op `rustflags: ""` lines and their comment are removed or corrected
- [ ] #3 publish-crates sets `cache: false` consistently with rust-ci
- [ ] #4 Lands before the next forge release repoints v1
<!-- AC:END -->
