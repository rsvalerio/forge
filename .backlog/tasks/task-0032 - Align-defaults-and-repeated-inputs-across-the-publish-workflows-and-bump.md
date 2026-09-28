---
id: TASK-0032
title: 'Align defaults and repeated inputs across the publish workflows and bump'
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
  - .github/workflows/publish-deb.yml
  - .github/workflows/publish-deb-dist.yml
  - .github/workflows/publish-homebrew.yml
  - .github/workflows/bump.yml
priority: low
ordinal: 1000
dedup_key: 'ops-align:publish-defaults'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/publish-*.yml`, `.github/workflows/bump.yml`

**What**: `runs-on` defaults to ubuntu-22.04 in the publish workflows but ubuntu-latest elsewhere; `keep-versions` is 3 in publish-deb-dist but publish-deb falls back to apt-pool-push's 0 (keep all); `owner`/`app-client-id`/`forge-ref`/`dry-run` and the 'Check out forge' step are repeated in four workflows.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Defaults are consistent (or the difference is documented)
- [x] #2 The repeated forge checkout is shared or documented as the single pattern

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Defaults NOT changed (changing runs-on or keep-versions would change behaviour for unmodified @v1 callers = breaking under docs/versioning.md). Documented instead: new docs/versioning.md section "Inputs every reusable workflow shares" (shared input table, why runs-on 22.04 vs latest and keep-versions 3 vs 0 differ); descriptions added to owner/app-client-id/forge-ref/runs-on in publish-deb, publish-deb-dist, publish-homebrew and bump runs-on; the Check out forge step is documented as the single pattern (cannot be factored: a composite action doing it would itself load from .forge) with a pointer comment on each copy.
<!-- SECTION:NOTES:END -->
