---
id: TASK-0024
title: 'Run ops verify in test-self''s lint job instead of mirroring its checks'
status: Done
assignee: []
created_date: '2026-09-28 10:59'
updated_date: '2026-09-28 13:59'
labels:
  - ci
  - ops-alignment
dependencies:
  - TASK-0023
parent_task_id: 'TASK-0035'
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
- [x] #1 test-self's lint job installs ops via setup-ops and runs `ops verify` (or the CI-safe subset), so the check list lives only in .ops.toml
- [x] #2 check-yaml runs in CI

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
test-self lint job (now named "ops verify") installs ops 0.72.0 via ./actions/setup-ops and runs `ops verify`; the per-check steps are gone, so .ops.toml [commands.verify] is the only check list (comments in .ops.toml, ci/lint.sh, mise.toml, README updated). check-yaml (lint-yaml) now runs in CI. The separate apt-pool-push job was dropped because ops verify already runs pool-update.test.sh (main ruleset requires no status checks, verified read-only). CI ops version is pinned on that setup-ops step.
<!-- SECTION:NOTES:END -->
