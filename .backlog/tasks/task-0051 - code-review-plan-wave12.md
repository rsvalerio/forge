---
id: TASK-0051
title: 'code-review-plan-wave12'
status: To Do
assignee: []
created_date: '2026-09-29 13:37'
updated_date: '2026-09-29 13:37'
labels:
  - code-review-wave
dependencies:
  - TASK-0050
  - TASK-0049
modified_files:
  - mise.toml
  - docs/foundation.md
  - docs/consuming.md
  - .github/workflows/rust-ci.yml
  - .github/workflows/bump.yml
  - .github/workflows/publish-crates.yml
  - .github/workflows/test-self.yml
  - actions/setup-ops/action.yml
  - actions/setup-ops/setup-ops.sh
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave12
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
CI tool installation: TASK-0050 moves every pipeline tool to mise and decides whether setup-ops stays as a fallback (its open design point 2); TASK-0049 exercises setup-ops on Intel macOS, so it lands with or after that decision. TASK-0048 stays in Triage: blocked on dbsec TASK-1131.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: none
<!-- SECTION:NOTES:END -->
