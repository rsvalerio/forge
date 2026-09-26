---
id: TASK-0012
title: 'Define an ops verify command in .ops.toml mirroring test-self''s lint job'
status: To Do
assignee: []
created_date: '2026-09-26 17:08'
updated_date: '2026-09-26 19:23'
labels:
  - ci
  - tooling
dependencies: []
parent_task_id: 'TASK-0015'
modified_files:
  - .ops.toml
  - .github/workflows/test-self.yml
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.ops.toml`

**What**: the code-review wave protocol gates every merge on `ops verify`, but this repo's .ops.toml defines no commands, so `ops verify` fails with "unknown command". TASK-0009 ran the equivalent by hand (actionlint, shellcheck over actions/**/*.sh, the executable check, the action.yml shape check via yq, TOML parse, ops check-yaml, actions/apt-pool-push/pool-update.test.sh).

**Why it matters**: without a named gate, each wave has to rebuild the gate by hand, and the checks drift from test-self.yml. The hand-built gate did catch a real invalid-YAML action.yml that actionlint misses.

**Origin**: discovered during TASK-0009 at the pre-merge QA gate.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ops verify runs the same checks as test-self.yml's lint job plus the local shell tests
- [ ] #2 ops verify exits non-zero on an action.yml that is not valid YAML
<!-- AC:END -->
