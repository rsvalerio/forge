---
id: TASK-0027
title: 'Exercise rust-ci.yml in test-self against a fixture crate'
status: To Do
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:43'
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
- [ ] #1 test-self calls ./.github/workflows/rust-ci.yml against a small in-repo fixture crate on every PR
- [ ] #2 The fixture includes a deliberate warning-free and a warning case so the warnings policy is asserted
<!-- AC:END -->
