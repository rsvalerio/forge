---
id: TASK-0038
title: 'dbsec ci.yml comment says rust-ci declares no permissions (belongs in dbsec)'
status: Triage
assignee: []
created_date: '2026-09-28 13:56'
labels:
  - docs
  - cross-repo
dependencies: []
modified_files:
  - .github/workflows/rust-ci.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `dbsec/.github/workflows/ci.yml:36` (in the dbsec repository, not forge)

**What**: The comment on dbsec's `rust` job says "forge's `rust-ci.yml` declares no permissions of its own". forge's `.github/workflows/rust-ci.yml` declares a workflow-level `permissions: contents: read`. The fix is a comment edit in dbsec; forge needs no change. Close this task once the dbsec edit lands (or move it to dbsec's backlog).

**Why it matters**: The stale comment misdescribes where dbsec's CI token grant comes from, which misleads anyone narrowing or widening permissions there.

**Origin**: discovered during TASK-0037 while fixing TASK-0033 (the task description flagged it as "fix in dbsec").
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 dbsec's ci.yml comment on the rust job matches rust-ci.yml's declared permissions (contents: read)
<!-- AC:END -->
