---
id: TASK-0054
title: 'Release v0.7.1 so v1 carries the bump job''s Rust toolchain fix'
status: Triage
assignee: []
created_date: '2026-10-03 07:55'
labels:
  - release
  - bump
dependencies: []
modified_files:
  - .github/workflows/bump.yml
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/release.yml` (run it), `.github/workflows/bump.yml` (what ships)

**What**: #22 (`2efd133`, `fix(bump): install a Rust toolchain before setup-tools`) is on `main`, but `v1` still points at v0.7.0 (`e63b91a`). Callers pin `bump.yml@v1`, and the workflow checks forge out at `forge-ref: v1`, so none of them has the fix. Without it, a bump on a runner whose job PATH has no `cargo` fails at `Install cargo-edit,cocogitto` in milliseconds: mise compiles `cargo-edit` with `cargo install`, and since bump moved from `taiki-e/install-action` to `setup-tools` nothing puts cargo on PATH. GitHub-hosted runners ship cargo and hide it.

**Why it matters**: it cost dbsec every bump from 2026-09-29 until it moved back to hosted runners (dbsec runs 36593915271, 36607221017). Any caller on a self-hosted runner is still broken, and the failure is silent: bump runs on `workflow_run`, so no PR goes red.

**Origin**: forge #22, found while releasing dbsec v0.13.2, 2026-10-03.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 v0.7.1 is cut from a main commit that includes 2efd133, with the Release workflow
- [ ] #2 v1 points at v0.7.1
- [ ] #3 A bump on a self-hosted runner without cargo on PATH passes the tool install step, or docs/consuming.md says what such a runner must provide
<!-- AC:END -->
