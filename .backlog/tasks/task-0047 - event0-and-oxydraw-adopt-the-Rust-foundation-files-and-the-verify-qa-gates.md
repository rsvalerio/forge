---
id: TASK-0047
title: 'event0 and oxydraw: adopt the Rust foundation files and the verify/qa gates'
status: Triage
assignee: []
created_date: '2026-09-28 17:04'
labels:
  - ops-alignment
dependencies: []
modified_files:
  - docs/foundation.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: event0 `.clippy.toml`, `.rustfmt.toml`, `deny.toml`, `.ops.toml`; oxydraw's equivalents

**What**: per docs/foundation.md, every Rust repo scaffolds its shared config with `ops init --rust` (ops >= 0.74.0), keeps it current with `ops init --rust --check`, and exposes `verify`/`qa`. event0 uses the dotted `.clippy.toml`/`.rustfmt.toml` spellings and its own copies; oxydraw has no foundation config from ops. The `--locked` re-declarations in event0 are already tracked separately (ops TASK-2339). Filed in forge's backlog because this wave cannot write to those repos' backlogs; move or mirror it there when picked up.

**Why it matters**: without adoption the foundation decision covers only ops and dbsec, and the consumers keep drifting copies.

**Origin**: discovered during TASK-0043 while fixing TASK-0025 (AC#2 consumer follow-ups).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 event0 and oxydraw pass ops init --rust --check, with any divergence recorded as a waiver with its reason
- [ ] #2 Dotted .clippy.toml/.rustfmt.toml are renamed, not kept alongside the non-dotted files
<!-- AC:END -->
