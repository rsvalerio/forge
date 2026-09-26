---
id: TASK-0017
title: 'Align CI shellcheck version with mise.toml''s pin'
status: Triage
assignee: []
created_date: '2026-09-26 19:42'
labels:
  - ci
  - tooling
dependencies: []
modified_files:
  - .github/workflows/test-self.yml
  - mise.toml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml`, `mise.toml`

**What**: `ops verify` runs shellcheck 0.11.0 (mise.toml), while test-self's lint job (and actionlint inside it) uses whatever shellcheck the ubuntu-latest runner image ships. actionlint is pinned to the same version in both places; shellcheck is not.

**Why it matters**: a new shellcheck warning can pass locally and fail in CI, or the reverse, which is the drift the shared ci/lint.sh gate exists to prevent.

**Origin**: discovered during TASK-0015 while fixing TASK-0012.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 test-self's lint job runs the same shellcheck version mise.toml pins, or the doc states why they differ
<!-- AC:END -->
