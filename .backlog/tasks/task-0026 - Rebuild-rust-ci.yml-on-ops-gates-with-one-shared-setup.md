---
id: TASK-0026
title: 'Rebuild rust-ci.yml on ops gates with one shared setup'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0023
  - TASK-0021
  - TASK-0025
modified_files:
  - .github/workflows/rust-ci.yml
  - docs/consuming.md
  - docs/versioning.md
priority: medium
ordinal: 1000
dedup_key: 'ops-align:rust-ci-on-ops'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/rust-ci.yml`, `docs/consuming.md`, `docs/versioning.md`

**What**: six jobs each repeat checkout + setup-rust-toolchain + sccache/rust-cache, then run cargo with flags that disagree with the ops stack (`--all --all-features`, no `--all-targets` so test code is never linted, no `--locked`, `cargo test` rather than nextest + test-doc, a redundant `check` job). Consumers' `.ops.toml` cannot change what CI runs, so local gates and CI drift.

**Why it matters**: CI should run the same `ops` gates developers and wave runners run, with flags from the ops stack plus the consumer's `.ops.toml`.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The toolchain/cache/setup-ops/tool-install block exists once (a composite action) instead of per job
- [ ] #2 Each job runs an `ops <gate>` command per the foundation contract; `cargo-flags`/`clippy-args`/`test-args` are deprecated in favour of `.ops.toml`
- [ ] #3 The behaviour change (--all-targets, --locked, nextest) is classified under docs/versioning.md and shipped opt-in or behind a new major
- [ ] #4 dbsec and forge-testbed stay green (or migrate) - checked before v1 moves
<!-- AC:END -->
