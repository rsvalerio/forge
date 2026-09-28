---
id: TASK-0030
title: 'Use one pinned tool-install method across forge workflows'
status: To Do
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 16:59'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0025
parent_task_id: 'TASK-0044'
modified_files:
  - .github/workflows/rust-ci.yml
  - .github/workflows/bump.yml
priority: low
ordinal: 1000
dedup_key: 'ops-align:tool-install'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/rust-ci.yml`, `.github/workflows/bump.yml`

**What**: four methods coexist: taiki-e/install-action with unversioned `cargo-deny` (rust-ci), taiki behind a hand-rolled PATH-check wrapper (bump), mise from mise.toml (test-self), taiki at another SHA (ops ci). Unversioned tools drift between runs.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Every tool a forge workflow installs has a pinned version from one declared source
- [ ] #2 bump.yml's PATH-check wrapper is replaced by that method
<!-- AC:END -->
