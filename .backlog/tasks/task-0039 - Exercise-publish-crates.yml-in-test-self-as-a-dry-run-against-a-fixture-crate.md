---
id: TASK-0039
title: 'Exercise publish-crates.yml in test-self as a dry run against a fixture crate'
status: To Do
assignee: []
created_date: '2026-09-28 13:58'
updated_date: '2026-09-28 16:59'
labels:
  - ci
  - test
dependencies: []
parent_task_id: 'TASK-0045'
modified_files:
  - .github/workflows/test-self.yml
  - .github/workflows/publish-crates.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml`, `.github/workflows/publish-crates.yml`

**What**: TASK-0027 made test-self call rust-ci.yml against fixture crates in `ci/fixtures/rust-ci/`, but publish-crates.yml is still never run by test-self, although it shares the setup-rust-toolchain step (and the `build-warnings: ""` / `cache: false` opt-outs from TASK-0021). The existing fixtures set `publish = false`, which `cargo publish --dry-run` rejects, and the caller would need job-level `permissions: {contents: read, id-token: write}` because publish-crates declares `id-token: write`.

**Why it matters**: its only caller is forge-testbed on its own triggers, so a toolchain-action or cargo change that breaks `cargo publish --dry-run` merges green here.

**Origin**: discovered during TASK-0034 while fixing TASK-0027.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 test-self calls ./.github/workflows/publish-crates.yml with dry-run: true (auth: none) against a small in-repo fixture crate on every PR
<!-- AC:END -->
