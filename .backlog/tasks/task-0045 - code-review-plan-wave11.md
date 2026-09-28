---
id: TASK-0045
title: 'code-review-plan-wave11'
status: Done
assignee: []
created_date: '2026-09-28 16:59'
updated_date: '2026-09-28 17:05'
labels:
  - code-review-wave
dependencies:
  - TASK-0039
  - TASK-0040
  - TASK-0041
modified_files:
  - .github/workflows/test-self.yml
  - .github/workflows/publish-crates.yml
  - actions/move-major-tag/move-major-tag.sh
  - .ops.toml
  - actions/setup-ops/setup-ops.sh
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave11
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
test-self coverage gaps: publish-crates dry run on a fixture (TASK-0039), move-major-tag guard tests (TASK-0040), setup-ops on ARM64/macOS (TASK-0041).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: TASK-0044 wave10 (.github/workflows/test-self.yml)

Branch: code-review/TASK-0045

<!-- SECTION:NOTES:END -->
