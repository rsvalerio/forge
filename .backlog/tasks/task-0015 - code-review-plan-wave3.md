---
id: TASK-0015
title: 'code-review-plan-wave3'
status: Done
assignee: []
created_date: '2026-09-26 19:23'
updated_date: '2026-09-26 19:44'
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

Branch: code-review/TASK-0015

Parked before Step 7: members TASK-0012 and TASK-0013 Done, pre-merge ops verify green, 3 commits on code-review/TASK-0015 (worktree ../.wave-TASK-0015). Merge lock + rebase onto code-review/run-20260926 was denied by the permission classifier; resume with Step 7 (rebase, pin release.yml third-party refs from wave1, integration ops verify, ff-merge).

Landed on code-review/run-20260926 at 3b984c9 (includes pinning wave1 release.yml checkout). Integration ops verify 8/8.

<!-- SECTION:NOTES:END -->
