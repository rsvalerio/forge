---
id: TASK-0014
title: 'code-review-plan-wave2'
status: To Do
assignee: []
created_date: '2026-09-26 19:23'
updated_date: '2026-09-26 19:32'
labels:
  - code-review-wave
dependencies:
  - TASK-0006
modified_files:
  - docs/consuming.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave2
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
forge-testbed dry-run gate for publish-deb-dist (0006): must go green before consumers adopt it. Consumer adoption lives in their own backlogs: ops TASK-2302 (blocked on this wave), my-cloud TASK-3, apt TASK-0001. Most of the work is in forge-testbed; the forge-local scope is docs/consuming.md.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: none (docs/consuming.md is not in any other open wave; wave1 TASK-0010 = .github/workflows, docs/versioning.md)

Scope reduced 2026-09-26: TASK-0007 moved to ops (TASK-2302), TASK-0008 to my-cloud (TASK-3), TASK-0011 to apt (TASK-0001). Only the forge-testbed gate TASK-0006 remains.

<!-- SECTION:NOTES:END -->
