---
id: TASK-0044
title: 'code-review-plan-wave10'
status: To Do
assignee: []
created_date: '2026-09-28 16:59'
updated_date: '2026-09-28 16:59'
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
<!-- SECTION:NOTES:END -->
