---
id: TASK-0024
title: 'Run ops verify in test-self''s lint job instead of mirroring its checks'
status: Triage
assignee: []
created_date: '2026-09-28 10:59'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0023
modified_files:
  - .github/workflows/test-self.yml
  - .ops.toml
  - ci/lint.sh
priority: medium
ordinal: 1000
dedup_key: 'ops-align:test-self-ops-verify'
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml`, `.ops.toml`, `ci/lint.sh`

**What**: the lint job lists each `ci/lint.sh` subcommand and `.ops.toml` lists them again (the comment says 'add a check there and list it both here and in .ops.toml'). `lint-yaml` (`ops check-yaml`) runs locally but never in CI because ops is not installed there.

**Why it matters**: one gate definition, run identically by developers, wave runners and CI.

**Origin**: ops-alignment survey of forge, ops and ai, 2026-09-28.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 test-self's lint job installs ops via setup-ops and runs `ops verify` (or the CI-safe subset), so the check list lives only in .ops.toml
- [ ] #2 check-yaml runs in CI
<!-- AC:END -->
