---
id: TASK-0048
title: 'Delete forge''s config/*.toml mirrors once no repo vendors them'
status: In Progress
assignee: []
created_date: '2026-09-28 17:04'
updated_date: '2026-09-29 16:12'
labels:
  - ops-alignment
dependencies: []
modified_files:
  - config/clippy.toml
  - config/deny.toml
  - config/rustfmt.toml
  - ci/lint.sh
  - .ops.toml
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `config/clippy.toml`, `config/deny.toml`, `config/rustfmt.toml`, `ci/lint.sh` (config-toml), `.ops.toml` (lint-config-toml), `README.md` layout, `docs/consuming.md#shared-configuration`

**What**: after TASK-0028, forge's config/*.toml are mirrors of ops's embedded templates, kept only because dbsec's forge-sync vendors them. Once dbsec moves to `ops init --rust --check`, delete them and the lint that checks them, and point the README and consuming.md at docs/foundation.md only.

**Why it matters**: a mirror is a second copy that has to be kept in step with ops by hand; the foundation decision is one source.

**Origin**: discovered during TASK-0043 while fixing TASK-0028.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 config/*.toml and the lint-config-toml check are removed, and docs point only at ops's templates
- [ ] #2 No consumer still reads forge's config/ (dbsec forge-sync retired first)

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Moved 2026-09-29: the blocker, forge TASK-0046, now lives in dbsec as TASK-1131. Pick this up once dbsec TASK-1131 is Done (AC#2).

AC#1 done 2026-09-29 (wave12): config/clippy.toml, deny.toml, rustfmt.toml deleted; ci/lint.sh config-toml and .ops.toml lint-config-toml removed; README layout, consuming.md "Shared configuration" and foundation.md point only at ops templates (docs/foundation.md). templates/ is untouched (dbsec also syncs templates/CONTRIBUTING.md, out of this task scope).

AC#2 NOT met: dbsec origin/main (8f532bc) still runs forge-sync. Its .forge-sync/manifest maps clippy.toml, deny.toml, rustfmt.toml to forge config/*, and scripts/forge-sync-check.sh fetches them from raw.githubusercontent.com at the single ref dbsec workflows pin forge at, which is `v1` (bump.yml, publish-crates.yml and rust-ci.yml all @v1), not main. So deleting on main is safe while v1 stays where it is, but the next release that moves v1 past this commit turns dbsec forge-sync red (could not fetch config/...). CAVEAT FOR THE OWNER: v1 must not move until dbsec TASK-1131 lands (forge-sync retired). The Transition table in docs/foundation.md says the same. No other local repo reads forge config/ (forge-testbed and my-cloud only mention forge-sync in comments). Close AC#2 and this task once dbsec TASK-1131 is Done.

<!-- SECTION:NOTES:END -->
