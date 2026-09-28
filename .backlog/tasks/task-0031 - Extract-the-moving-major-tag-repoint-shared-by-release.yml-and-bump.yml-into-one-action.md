---
id: TASK-0031
title: 'Extract the moving-major-tag repoint shared by release.yml and bump.yml into one action'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:59'
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
- [x] #1 One composite action (or script) owns the major guard and repoint; both workflows use it

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
New composite action actions/move-major-tag (move-major-tag.sh) owns the major guard and the PATCH-then-POST lightweight repoint. release.yml runs it check-only in the read-only check job (checkout added after the dispatch-branch guard) and for the repoint in the release job; bump.yml runs it from ./.forge at forge-ref. No inputs added/removed on bump.yml; the moving-tag summary line moved into bump Summarise via the action output.
<!-- SECTION:NOTES:END -->
