---
id: TASK-0034
title: 'code-review-plan-wave5'
status: To Do
assignee: []
created_date: '2026-09-28 13:43'
updated_date: '2026-09-28 13:43'
labels:
  - code-review-wave
dependencies:
  - TASK-0021
  - TASK-0022
  - TASK-0027
  - TASK-0019
modified_files:
  - .github/workflows/rust-ci.yml
  - .github/workflows/publish-crates.yml
  - .github/dependabot.yml
  - README.md
  - .github/workflows/test-self.yml
  - mise.toml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
code-review-plan-wave5
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->

<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Rationale: fallout of Dependabot #16 and tool-bump hygiene. Fix setup-rust-toolchain v2 build-warnings=deny regression (0021, must land before next v1 repoint), assert the warnings policy by exercising rust-ci.yml in test-self against a fixture crate (0027), keep majors out of the weekly group (0022), and automate/document mise.toml tool bumps (0019).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Overlaps: TASK-0035/wave6 (.github/workflows/test-self.yml), TASK-0037/wave8 (README.md). Note: 0027 also adds a new in-repo fixture crate (path chosen by the implementer); 0021 AC#4 requires this wave land before the next release repoints v1.
<!-- SECTION:NOTES:END -->
