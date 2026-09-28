---
id: TASK-0022
title: 'Keep Dependabot major-version bumps out of the weekly github-actions group'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:58'
labels:
  - ci
  - dependabot
dependencies: []
parent_task_id: 'TASK-0034'
modified_files:
  - .github/dependabot.yml
  - README.md
priority: medium
ordinal: 1000
dedup_key: 'ops-align:dependabot-majors'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/dependabot.yml`

**What**: the single `github-actions` group (`patterns: ["*"]`) bundled four major bumps (checkout v7, upload-artifact v7, download-artifact v8, setup-rust-toolchain v2) into one PR (#16) alongside patches; the setup-rust-toolchain major changed consumer behaviour unnoticed.

**Why it matters**: forge's workflows run in every consumer via `@v1`; a major needs its own review.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The group only takes minor and patch updates (`update-types`); each major arrives as its own PR
- [x] #2 README design rule 6 states the policy

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
dependabot.yml group now carries update-types: [minor, patch], so each major arrives as its own PR; README design rule 6 states the policy.
<!-- SECTION:NOTES:END -->
