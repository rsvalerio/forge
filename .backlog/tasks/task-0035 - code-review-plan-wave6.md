---
id: TASK-0035
title: 'code-review-plan-wave6'
status: To Do
assignee: []
created_date: '2026-09-28 13:43'
updated_date: '2026-09-28 13:43'
labels:
  - code-review-wave
dependencies:
  - TASK-0023
  - TASK-0024
modified_files:
  - actions/setup-ops/action.yml
  - actions/setup-ops/setup-ops.sh
  - .github/workflows/test-self.yml
  - docs/consuming.md
  - .ops.toml
  - ci/lint.sh
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave6
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Rationale: get ops onto runners. Add the pinned, sha256-verified setup-ops composite action (0023), then use it in test-self lint to run ops verify so the check list lives only in .ops.toml and check-yaml runs in CI (0024, depends on 0023; lands coherently in the same run).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: TASK-0034/wave5 (.github/workflows/test-self.yml), TASK-0037/wave8 (docs/consuming.md).
<!-- SECTION:NOTES:END -->
