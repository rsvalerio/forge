---
id: TASK-0028
title: 'Reconcile forge config/clippy.toml with rust-make-clippy-pedantic''s lint policy'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:52'
labels:
  - ops-alignment
  - lint
dependencies:
  - TASK-0025
modified_files:
  - config/clippy.toml
priority: low
ordinal: 1000
dedup_key: 'ops-align:clippy-policy'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `config/clippy.toml`

**What**: forge's clippy.toml has no `allow-*-in-tests`, adds `too-many-lines`, `allowed-idents`, `avoid-breaking-exported-api` and omits `msrv` by design; ai's rust-make-clippy-pedantic (apply-config.md) writes `msrv = rust-version`, four `allow-*-in-tests` keys and a `[workspace.lints]` policy that forge ships nowhere.

**Why it matters**: two sources for one engineering practice; repos get a different policy depending on whether they started from forge or from the skill.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One source for clippy.toml keys and the `[workspace.lints]` policy, chosen per the foundation decision; the other side references it
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Per TASK-0025's decision, the single source for clippy.toml and [workspace.lints] is ops's embedded templates (ops TASK-2330); reconcile forge config/clippy.toml into it, then point forge at ops.
<!-- SECTION:NOTES:END -->
