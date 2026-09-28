---
id: TASK-0041
title: 'Exercise setup-ops on ARM64 and macOS runners in test-self'
status: Triage
assignee: []
created_date: '2026-09-28 14:01'
labels:
  - code-review-rust
  - ci
dependencies: []
modified_files:
  - .github/workflows/test-self.yml
  - actions/setup-ops/setup-ops.sh
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `actions/setup-ops/setup-ops.sh`, `.github/workflows/test-self.yml`

**What**: setup-ops maps Linux/macOS x X64/ARM64 to ops's four dist targets and falls back to `shasum -a 256` where `sha256sum` is absent (macOS), but test-self only runs it on ubuntu-latest (X64). The aarch64-linux and both darwin paths, and the shasum fallback, were checked only by reasoning plus a local aarch64 download (which verified the checksum but could not execute the binary on x86).

**Why it matters**: a consumer on ubuntu-24.04-arm or macos-latest would be the first to find a broken mapping or checksum fallback.

**Origin**: discovered during TASK-0035 while fixing TASK-0023.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 test-self runs setup-ops (happy path, ops --version asserted) on an ARM64 Linux runner and a macOS runner
<!-- AC:END -->
