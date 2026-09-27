---
id: TASK-0019
title: 'Automate bumps for mise.toml tool pins and the mise version in test-self'
status: Triage
assignee: []
created_date: '2026-09-27 13:17'
labels:
  - code-review-rust
  - ci
dependencies: []
modified_files:
  - mise.toml
  - .github/workflows/test-self.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `mise.toml:7`, `.github/workflows/test-self.yml:31`

**What**: TASK-0017 made mise.toml the single source of truth for actionlint/shellcheck/yq in both `ops verify` and test-self's lint job, and pins the mise binary itself via jdx/mise-action's `version: 2026.9.14`. Dependabot's github-actions ecosystem (TASK-0016) bumps the mise-action SHA but neither the tool versions in mise.toml nor the `version:` input, so those only move by hand.

**Why it matters**: lint tools freeze and miss new checks/fixes; the pinned mise binary drifts behind the action.

**Origin**: discovered during TASK-0018 while fixing TASK-0017.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 mise.toml tool versions and test-self's mise version are bumped by an automated PR (e.g. Renovate's mise manager) or the README documents the manual bump cadence
<!-- AC:END -->
