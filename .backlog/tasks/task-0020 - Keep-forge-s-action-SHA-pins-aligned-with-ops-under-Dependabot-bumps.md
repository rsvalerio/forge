---
id: TASK-0020
title: 'Keep forge''s action SHA pins aligned with ops under Dependabot bumps'
status: Done
assignee: []
created_date: '2026-09-27 13:17'
updated_date: '2026-09-28 17:06'
labels:
  - code-review-rust
  - ci
dependencies: []
parent_task_id: 'TASK-0043'
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
- [x] #1 README design rule 6 no longer requires matching ops's SHAs, and says why

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision by the owner, 2026-09-28: drop 'where ops pins the same action, use the same SHA' from README rule 6. Each repo pins independently and Dependabot moves the pins; once ops CI runs on forge workflows (ops TASK-2329) most of ops's pins are forge's anyway. Remaining work: reword rule 6 (README.md).

TASK-0043: README rule 6 no longer requires matching ops SHAs; it says each repo's Dependabot moves its own pins, so a match rule would be broken by every bump and enforced by nothing, and that ops CI on forge workflows makes most ops pins forge's anyway.

<!-- SECTION:NOTES:END -->
