---
id: TASK-0031
title: 'Extract the moving-major-tag repoint shared by release.yml and bump.yml into one action'
status: To Do
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:43'
labels:
  - ci
  - duplication
dependencies: []
parent_task_id: 'TASK-0036'
modified_files:
  - .github/workflows/release.yml
  - .github/workflows/bump.yml
priority: low
ordinal: 1000
dedup_key: 'ops-align:repoint-action'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/release.yml`, `.github/workflows/bump.yml`

**What**: release.yml's major guard and PATCH-then-POST repoint are copied from bump.yml's 'Repoint the moving major tag'. A fix to one silently misses the other.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One composite action (or script) owns the major guard and repoint; both workflows use it
<!-- AC:END -->
