---
id: TASK-0048
title: 'Delete forge''s config/*.toml mirrors once no repo vendors them'
status: Triage
assignee: []
created_date: '2026-09-28 17:04'
updated_date: '2026-09-28 17:05'
labels:
  - ops-alignment
dependencies:
  - TASK-0046
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
- [ ] #1 config/*.toml and the lint-config-toml check are removed, and docs point only at ops's templates
- [ ] #2 No consumer still reads forge's config/ (dbsec forge-sync retired first)
<!-- AC:END -->
