---
id: TASK-0009
title: 'code-review-plan-wave0'
status: Done
assignee: []
created_date: '2026-09-26 16:49'
updated_date: '2026-09-26 17:08'
labels:
  - code-review-wave
dependencies:
  - TASK-0002
  - TASK-0003
  - TASK-0004
  - TASK-0005
modified_files:
  - actions/apt-pool-push/action.yml
  - .github/workflows/publish-deb.yml
  - actions/deb-from-dist/action.yml
  - .github/workflows/publish-deb-dist.yml
  - docs/consuming.md
  - README.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave0
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
apt publishing from cargo-dist: extract apt-pool-push (0002), add retention to it (0003), add deb-from-dist (0004), then compose both in publish-deb-dist.yml (0005). Implement in that order; 0003 and 0005 depend on earlier members.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: none by file. TASK-0010 (wave1) is scoped to the .github/workflows directory, which contains this wave's publish-deb.yml and publish-deb-dist.yml. Its likely new file (release.yml) is distinct.

Branch: code-review/TASK-0009

<!-- SECTION:NOTES:END -->
