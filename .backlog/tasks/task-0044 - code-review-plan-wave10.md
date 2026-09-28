---
id: TASK-0044
title: 'code-review-plan-wave10'
status: In Progress
assignee: []
created_date: '2026-09-28 16:59'
updated_date: '2026-09-28 17:26'
labels:
  - code-review-wave
dependencies:
  - TASK-0026
  - TASK-0029
  - TASK-0030
  - TASK-0042
modified_files:
  - .github/workflows/rust-ci.yml
  - docs/consuming.md
  - docs/versioning.md
  - .github/workflows/bump.yml
  - .github/workflows/test-self.yml
  - mise.toml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave10
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
CI on ops gates with pinned tooling: rebuild rust-ci.yml on ops gates behind an opt-in input with one shared setup (TASK-0026), add MSRV gate (TASK-0029), one pinned tool-install source (TASK-0030), pin local ops version to CI (TASK-0042).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: TASK-0045 wave11 (.github/workflows/test-self.yml). Merge after wave9 (foundation doc defines the gate contract this wave implements).

Branch: code-review/TASK-0044

Code landed on code-review/run-20260928-2 (65ab9dc..a0e74a1). TASK-0029, TASK-0030, TASK-0042 Done. TASK-0026 left In Progress: AC#1-3 done, AC#4 (dbsec and forge-testbed stay green or migrate, checked before v1 moves) is a release-time check that cannot run inside the wave. Close TASK-0026 and this wave after that check at the next v1 move. Consumer-side mise.toml use is TASK-0050. Worktree ../.wave-TASK-0044 / branch code-review/TASK-0044 left in place (fully merged).

<!-- SECTION:NOTES:END -->
