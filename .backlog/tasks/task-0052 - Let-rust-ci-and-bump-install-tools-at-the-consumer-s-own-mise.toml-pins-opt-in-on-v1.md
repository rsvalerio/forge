---
id: TASK-0052
title: 'Let rust-ci and bump install tools at the consumer''s own mise.toml pins, opt-in on v1'
status: Triage
assignee: []
created_date: '2026-09-29 16:08'
labels:
  - ops-alignment
  - ci
dependencies: []
modified_files:
  - actions/setup-tools/setup-tools.sh
  - .github/workflows/rust-ci.yml
  - .github/workflows/bump.yml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `actions/setup-tools/`, `.github/workflows/rust-ci.yml`, `.github/workflows/bump.yml`, `docs/foundation.md`

**What**: TASK-0050 kept forge's mise.toml (at `forge-ref`) as the only pin source for the reusable workflows on v1, so a consumer's laptop tools (its own mise.toml) and its CI tools (forge's pins) can differ. The owner decision of 2026-09-28 is that CI installs from the repo's own mise.toml. Add an opt-in input (e.g. `tool-pins: repo`, default `forge`) that resolves each tool's version from the caller's mise.toml, falling back to forge's pin, and installs it through forge's mise config (forge's aliases/backends, never the consumer's hooks or settings). Open points: table-valued pins (cargo-nextest's `version_prefix`), a consumer entry keyed by a different backend name, and whether the next major flips the default.

**Why it matters**: until then the same gate can run different tool versions on a laptop and in CI, the gap TASK-0050 set out to close.

**Origin**: discovered during TASK-0051 while fixing TASK-0050 (open design point 1).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 rust-ci and bump take an opt-in input that installs each tool at the caller's mise.toml pin, falling back to forge's, classified in docs/versioning.md
- [ ] #2 test-self exercises it against a fixture mise.toml
<!-- AC:END -->
