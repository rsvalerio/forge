---
id: TASK-0033
title: 'Fix stale adoption claims in README and consuming.md'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - docs
dependencies: []
modified_files:
  - README.md
  - docs/consuming.md
priority: low
ordinal: 1000
dedup_key: 'ops-align:docs-drift'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `README.md`, `docs/consuming.md`

**What**: README still says there is no consumer adoption and no v1 tag; consuming.md lists ops as a rust-ci consumer, but ops runs its own ci.yml. (dbsec's ci.yml also says rust-ci declares no permissions; it declares `contents: read` - fix in dbsec.)

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 README status and consuming.md's consumer list match reality (bump: ops, dbsec; rust-ci: dbsec; publish-deb-dist: ops)
<!-- AC:END -->
