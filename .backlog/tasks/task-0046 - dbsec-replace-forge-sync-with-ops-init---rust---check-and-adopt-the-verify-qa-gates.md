---
id: TASK-0046
title: 'dbsec: replace forge-sync with ops init --rust --check and adopt the verify/qa gates'
status: Triage
assignee: []
created_date: '2026-09-28 17:04'
labels:
  - ops-alignment
  - ci
dependencies: []
modified_files:
  - docs/foundation.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: dbsec `scripts/forge-sync-check.sh`, `.forge-sync/manifest`, `.ops.toml` (`[commands.forge-sync]`, `[commands.pre-release]`)

**What**: per docs/foundation.md, ops is the single source for clippy.toml, deny.toml, rustfmt.toml, .config/nextest.toml and the [workspace.lints] policy (`ops init --rust`, ops >= 0.74.0). dbsec still vendors forge's config/*.toml through its private forge-sync script and runs its own `pre-release` gate instead of the `verify`/`qa` contract. Filed in forge's backlog because this wave cannot write to dbsec's; move or mirror it into dbsec's backlog when picked up.

**Why it matters**: dbsec is the last consumer of forge's config/ mirrors; until it moves, forge cannot delete them and there are two copies of the foundation. The next forge v1 move also changes config/clippy.toml (four allow-*-in-tests keys), which forge-sync will report as drift.

**Origin**: discovered during TASK-0043 while fixing TASK-0025 (AC#2 consumer follow-ups).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 dbsec runs ops init --rust --check (with waivers for deliberate divergences) instead of forge-sync for clippy.toml, deny.toml and rustfmt.toml
- [ ] #2 dbsec's pre-release gate is expressed as verify/qa plus [extend.*] additions, per docs/foundation.md
<!-- AC:END -->
