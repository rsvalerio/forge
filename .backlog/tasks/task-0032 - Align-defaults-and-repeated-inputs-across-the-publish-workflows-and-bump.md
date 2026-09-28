---
id: TASK-0032
title: 'Align defaults and repeated inputs across the publish workflows and bump'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ci
  - duplication
dependencies: []
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
- [ ] #1 Defaults are consistent (or the difference is documented)
- [ ] #2 The repeated forge checkout is shared or documented as the single pattern
<!-- AC:END -->
