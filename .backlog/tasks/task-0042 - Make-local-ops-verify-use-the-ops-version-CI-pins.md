---
id: TASK-0042
title: 'Make local ops verify use the ops version CI pins'
status: Done
assignee: []
created_date: '2026-09-28 14:01'
updated_date: '2026-09-28 17:25'
labels:
  - code-review-rust
  - ci
dependencies: []
parent_task_id: 'TASK-0044'
modified_files:
  - .github/workflows/test-self.yml
  - mise.toml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/test-self.yml` (setup-ops `version: 0.72.0`), `mise.toml`

**What**: CI now runs `ops verify` with ops 0.72.0 from setup-ops, but developers and wave runners run whatever ops is on their PATH (cargo install, apt, homebrew). Builtins such as `ops check-yaml` can change between ops releases, so the local gate and CI can disagree on the same tree.

**Why it matters**: the point of TASK-0024 was one gate run identically everywhere; the tool version is the remaining gap.

**Origin**: discovered during TASK-0035 while fixing TASK-0024.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Either the local ops version is pinned from the same source CI reads (e.g. a mise github backend entry that setup-ops also reads), or ops verify warns when the running ops differs from CI's pin

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
ops = "0.75.0" pinned in mise.toml ([tool_alias] ops = github:rsvalerio/ops): `mise install` gets it locally (verified), and test-self installs it via setup-tools, which reads the same pin and installs through setup-ops.sh (sha256-verified). CI ops moved 0.72.0 -> 0.75.0 to match local. The setup-ops job asserts action.yml installs the mise.toml pin.
<!-- SECTION:NOTES:END -->
