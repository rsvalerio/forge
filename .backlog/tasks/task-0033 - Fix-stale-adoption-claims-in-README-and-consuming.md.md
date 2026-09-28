---
id: TASK-0033
title: 'Fix stale adoption claims in README and consuming.md'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:56'
labels:
  - docs
dependencies: []
parent_task_id: 'TASK-0037'
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
- [x] #1 README status and consuming.md's consumer list match reality (bump: ops, dbsec; rust-ci: dbsec; publish-deb-dist: ops)

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified consumers by grepping sibling repos' workflows. README Status now lists callers per workflow and v1 (at v0.4.0); dropped stale forge-testbed/adoption/v1 rows; tree comment for publish-crates no longer says unadopted. consuming.md: ops rust-ci row marked not adopted (ops runs its own ci.yml); publish-crates section names dbsec's manual opt-in. dbsec-side comment fix filed as TASK-0038 (Triage, belongs in dbsec).
<!-- SECTION:NOTES:END -->
