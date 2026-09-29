---
id: TASK-0049
title: 'Exercise setup-ops''s x86_64-apple-darwin mapping in test-self'
status: Done
assignee: []
created_date: '2026-09-28 17:05'
updated_date: '2026-09-29 16:11'
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
- [x] #1 test-self installs ops via setup-ops on an X64 macOS runner and asserts ops --version, or the task records why no supported runner exists and the gap is documented in docs/consuming.md

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Took the AC alternative (2026-09-29). setup-ops is unchanged by TASK-0050 (design point 2: it stays, and setup-tools installs ops through it), so its macOS/X64 mapping still matters. No durable Intel macOS GitHub runner exists: actions/runner-images#13045 says x86_64 leaves GitHub Actions in August 2027; the only x86_64 macOS labels (macos-15-intel, macos-26-intel, and the paid -large ones) end then. Adding one would put a job in test-self, the release gate, that fails or queues forever from that date. Checked by hand instead: ops v0.75.0 ops-x86_64-apple-darwin.tar.gz exists, its .sha256 sidecar matches the download (817376a1...29f2), the archive holds ops-x86_64-apple-darwin/ops, and `file` reports Mach-O 64-bit x86_64. Only running it (the ops --version assert) is unexercised. Documented in docs/consuming.md (setup-ops, Platforms) and in the setup-ops-platforms comment in test-self.yml. If the owner wants coverage until the sunset, add macos-26-intel to that matrix with an X64 branch in the arch assert, and remove it before August 2027.
<!-- SECTION:NOTES:END -->
