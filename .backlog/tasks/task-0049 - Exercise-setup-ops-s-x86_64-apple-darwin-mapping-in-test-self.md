---
id: TASK-0049
title: 'Exercise setup-ops''s x86_64-apple-darwin mapping in test-self'
status: To Do
assignee: []
created_date: '2026-09-28 17:05'
updated_date: '2026-09-29 13:37'
labels:
  - ci
  - test
dependencies: []
parent_task_id: 'TASK-0051'
modified_files:
  - .github/workflows/test-self.yml
  - actions/setup-ops/setup-ops.sh
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml`, `actions/setup-ops/setup-ops.sh`

**What**: TASK-0041 added `setup-ops-platforms` (ubuntu-24.04-arm, macos-latest), which covers aarch64-unknown-linux-gnu, aarch64-apple-darwin and the `shasum -a 256` fallback. The `macOS/X64 -> x86_64-apple-darwin` mapping is still never executed: macos-latest is ARM64 and the job asserts ARM64. GitHub's Intel macOS images (macos-13 retired, macos-15-intel slated for retirement) make a durable runner choice non-obvious, so it was not added in-wave.

**Why it matters**: an Intel-Mac self-hosted or legacy-image consumer would be the first to hit a broken mapping for that target.

**Origin**: discovered during TASK-0045 while fixing TASK-0041.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 test-self installs ops via setup-ops on an X64 macOS runner and asserts ops --version, or the task records why no supported runner exists and the gap is documented in docs/consuming.md
<!-- AC:END -->
