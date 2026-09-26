---
id: TASK-0015
title: 'code-review-plan-wave3'
status: To Do
assignee: []
created_date: '2026-09-26 19:23'
updated_date: '2026-09-26 19:23'
labels:
  - code-review-wave
dependencies:
  - TASK-0012
  - TASK-0013
modified_files:
  - .ops.toml
  - .github/workflows
  - actions
  - README.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave3
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
forge CI hardening: named ops verify gate mirroring test-self lint (0012) and repo-wide SHA pinning policy for third-party actions (0013). Both touch test-self.yml; land 0013 after verify exists so the gate checks the pins.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: TASK-0010 wave1 (.github/workflows). Merge after wave1 so its new release workflow gets pinned too.
<!-- SECTION:NOTES:END -->
