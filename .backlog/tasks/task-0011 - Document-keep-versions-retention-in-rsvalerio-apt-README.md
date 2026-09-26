---
id: TASK-0011
title: 'Document keep-versions retention in rsvalerio/apt README'
status: Triage
assignee: []
created_date: '2026-09-26 17:08'
labels:
  - docs
  - apt
dependencies: []
modified_files:
  - docs/consuming.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `rsvalerio/apt:README.md` (forge side: `docs/consuming.md`)

**What**: forge's apt-pool-push now prunes versions beyond the newest N per package+arch (`keep-versions`; publish-deb-dist defaults to 3). The rule is documented in forge docs/consuming.md ("Retention"), but rsvalerio/apt's own README, which is what apt users read, does not say that old versions leave the pool, that `apt install <pkg>=<old>` stops working once they do, or when to run `scripts/squash-history.sh`.

**Why it matters**: users who pin an exact version lose it silently. The README also still says only ops publishes there (TASK-0007 fixes that line; this adds the retention section beside it).

**Origin**: discovered during TASK-0009 while fixing TASK-0003 (AC4 is satisfied in forge's docs; the cross-repo mirror is this task).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 rsvalerio/apt README states the retention window per package+arch and its effect on pinned installs
- [ ] #2 README says when to run scripts/squash-history.sh
<!-- AC:END -->
