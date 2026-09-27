---
id: TASK-0020
title: 'Keep forge''s action SHA pins aligned with ops under Dependabot bumps'
status: Triage
assignee: []
created_date: '2026-09-27 13:17'
labels:
  - code-review-rust
  - ci
dependencies: []
modified_files:
  - README.md
  - .github/dependabot.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `README.md:88`, `.github/dependabot.yml`

**What**: README design rule 6 says "Where ops pins the same action, use the same SHA". TASK-0016 added weekly Dependabot bumps in forge, which will move forge's pins independently of ops', so the two repos drift unless ops runs the same cadence or the rule is relaxed.

**Why it matters**: the rule becomes silently unenforced; consumers see two SHAs for the same action.

**Origin**: discovered during TASK-0018 while fixing TASK-0016.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Rule 6's same-SHA-as-ops clause is either reconciled with automated bumps (ops runs an equivalent Dependabot config, or the rule is reworded) and documented
<!-- AC:END -->
