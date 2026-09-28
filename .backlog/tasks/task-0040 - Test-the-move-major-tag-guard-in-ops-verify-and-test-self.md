---
id: TASK-0040
title: 'Test the move-major-tag guard in ops verify and test-self'
status: Done
assignee: []
created_date: '2026-09-28 13:59'
updated_date: '2026-09-28 17:03'
labels:
  - ci
  - test
dependencies: []
parent_task_id: 'TASK-0045'
modified_files:
  - actions/move-major-tag/move-major-tag.sh
  - .ops.toml
  - .github/workflows/test-self.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `actions/move-major-tag/move-major-tag.sh`

**What**: The major guard (released > moving refuses; equal and below repoint; non-numeric majors error) now lives in one script shared by release.yml and bump.yml, but nothing exercises it. Its check-only mode needs no network or token, so a `move-major-tag.test.sh` can cover every case locally, like `pool-update.test.sh`. Not added in-wave because wiring it in needs `.ops.toml` and `.github/workflows/test-self.yml`, which concurrent waves 5/6 own.

**Why it matters**: A regression in the guard either carries `v1` across a major (the one thing versioning.md forbids) or fails every release; both only show up on a real release.

**Origin**: discovered during TASK-0036 while fixing TASK-0031.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A move-major-tag.test.sh covers below/equal/above/non-numeric cases in check-only mode
- [x] #2 It runs in ops verify and in test-self.yml

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
move-major-tag.test.sh wired as [commands.test-move-major-tag] in .ops.toml verify; test-self.yml runs it through its lint job (`ops verify`), which is how pool-update.test.sh runs there too and what .ops.toml requires (a check added anywhere else runs nowhere). Four mutants of the guard (-ge, -ne, check-only bypass, weakened non-numeric case) all fail the test.
<!-- SECTION:NOTES:END -->
