---
id: TASK-0054
title: 'Release v0.7.1 so v1 carries the bump job''s Rust toolchain fix'
status: In Progress
assignee: []
created_date: '2026-10-03 07:55'
updated_date: '2026-10-03 12:00'
labels:
  - release
  - bump
dependencies: []
modified_files:
  - .github/workflows/bump.yml
  - docs/consuming.md
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
- [x] #3 A bump on a self-hosted runner without cargo on PATH passes the tool install step, or docs/consuming.md says what such a runner must provide
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-10-03: the release is v0.8.0, not v0.7.1, by owner decision: main also carries #26 (`tool-pins`, a new optional input) since v0.7.0, and a feature release bumps the minor. The title and criteria #1 and #2 keep the number the task was filed with; read them as v0.8.0.

Criterion #3 is met through the docs: consuming.md, "What the runner must provide (`rust-toolchain`)", lists what a self-hosted runner needs (curl and network for rustup, a C compiler and linker for the cargo-edit build, gh and jq). No self-hosted runner without cargo was available to run a bump on, so that path is documented, not tested.
<!-- SECTION:NOTES:END -->
