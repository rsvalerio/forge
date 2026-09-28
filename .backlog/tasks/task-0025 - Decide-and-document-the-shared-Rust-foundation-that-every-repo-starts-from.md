---
id: TASK-0025
title: 'Decide and document the shared Rust foundation that every repo starts from'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ops-alignment
  - decision
dependencies: []
modified_files:
  - docs/foundation.md
  - config
  - README.md
priority: medium
ordinal: 1000
dedup_key: 'ops-align:foundation'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `docs/foundation.md` (new), `config/`, `README.md`

**What**: there is no shared foundation config. Each Rust repo re-declares its own gates: event0 re-declares 9 ops built-ins only to add `--locked`; the 'run what CI runs' gate is `run-before-push` (ops), `qa` (event0) and `pre-release` (dbsec), each different; forge's `config/*` (clippy.toml, deny.toml, ...) is vendored and synced by a dbsec-only `forge-sync` script; the ai skills write their own templates (clippy lint policy, nextest.toml, `.ops.toml` gates). The ai skills already assume `ops verify` is the QA gate.

**Decide**: (1) the gate contract - which ops commands every Rust repo exposes and what each means (e.g. `verify` = fast pre-commit, `qa` = full; CI runs both), (2) where defaults live - ops stack built-ins vs a forge-shipped `.ops.d/` fragment vs vendored files, and how repos pick up updates (replacing dbsec's forge-sync), (3) which config files are shared (clippy.toml, deny.toml, rustfmt, nextest.toml, `[workspace.lints]`, test profile) and their single source.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/foundation.md records the gate contract, where each default lives and how a repo adopts and updates it
- [ ] #2 Follow-up tasks are filed in ops/ai/consumer backlogs for every change the decision requires
<!-- AC:END -->
