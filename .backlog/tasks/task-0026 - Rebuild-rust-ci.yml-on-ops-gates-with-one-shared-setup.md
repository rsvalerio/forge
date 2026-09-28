---
id: TASK-0026
title: 'Rebuild rust-ci.yml on ops gates with one shared setup'
status: In Progress
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 17:25'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0023
  - TASK-0021
  - TASK-0025
parent_task_id: 'TASK-0044'
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
- [x] #1 The toolchain/cache/setup-ops/tool-install block exists once (a composite action) instead of per job
- [x] #2 Each job runs an `ops <gate>` command per the foundation contract; `cargo-flags`/`clippy-args`/`test-args` are deprecated in favour of `.ops.toml`
- [x] #3 The behaviour change (--all-targets, --locked, nextest) is classified under docs/versioning.md and shipped opt-in or behind a new major
- [ ] #4 dbsec and forge-testbed stay green (or migrate) - checked before v1 moves

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision by the owner, 2026-09-28: ship behind an opt-in input on v1 (e.g. engine: ops, default cargo). dbsec and forge-testbed opt in one at a time; the default flips at a later major. No v2 tag.

Implemented in wave10 (TASK-0044): rust-ci engine input (default cargo, unchanged gates; unknown value fails), engine: ops jobs (ops verify-check / ops test = next + test-doc / ops deps --check / ops sec) sharing actions/setup-rust (toolchain, compile cache, setup-tools), OPS__CARGO__LOCKED=true, cargo-flags/clippy-args/test-args deprecated (warning under ops), classified in docs/versioning.md "rust-ci engine: ops". The engine: cargo jobs keep their per-job blocks as the frozen legacy engine removed when the default flips. test-self rust-ci-ops exercises it. AC#4 left open: it is a release gate (dbsec on v1, forge-testbed on main must stay green or migrate before v1 moves), which cannot be checked inside this wave; close it when that check is done at the next release.

<!-- SECTION:NOTES:END -->
