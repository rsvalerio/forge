---
id: TASK-0010
title: 'code-review-plan-wave1'
status: In Progress
assignee: []
created_date: '2026-09-26 16:49'
updated_date: '2026-09-26 19:40'
labels:
  - code-review-wave
dependencies:
  - TASK-0001
modified_files:
  - .github/workflows
  - docs/versioning.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave1
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Release automation: workflow_dispatch release that tags vX.Y.Z and repoints v1.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: none by file. The directory scope .github/workflows contains TASK-0009 (wave0) files publish-deb.yml and publish-deb-dist.yml. This wave should only add a new workflow file.

Branch: code-review/TASK-0010

Landed on code-review/run-20260926 (0f2d8e8). Parked open: TASK-0001 AC1 needs a live workflow_dispatch of Release after the run PR merges to main (see TASK-0001 notes). Worktree ../.wave-TASK-0010 and branch code-review/TASK-0010 left in place per protocol (branch fully merged; nothing uncommitted).

<!-- SECTION:NOTES:END -->
