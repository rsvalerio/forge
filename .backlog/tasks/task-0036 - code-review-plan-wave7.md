---
id: TASK-0036
title: 'code-review-plan-wave7'
status: Done
assignee: []
created_date: '2026-09-28 13:43'
updated_date: '2026-09-28 14:00'
labels:
  - code-review-wave
dependencies:
  - TASK-0031
  - TASK-0032
modified_files:
  - .github/workflows/release.yml
  - .github/workflows/bump.yml
  - .github/workflows/publish-deb.yml
  - .github/workflows/publish-deb-dist.yml
  - .github/workflows/publish-homebrew.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave7
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Rationale: release/publish workflow duplication. Extract the moving-major-tag guard and repoint shared by release.yml and bump.yml (0031) and align defaults and repeated inputs/forge checkout across publish-* and bump (0032); both de-duplicate bump.yml.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: none

Branch: code-review/TASK-0036

<!-- SECTION:NOTES:END -->
