---
id: TASK-0052
title: 'Let bump install tools at the consumer''s own mise.toml pins, opt-in on v1'
status: Done
assignee: []
created_date: '2026-09-29 16:08'
updated_date: '2026-10-03 11:00'
labels:
  - ops-alignment
  - ci
dependencies: []
modified_files:
  - actions/setup-tools/setup-tools.sh
  - .github/workflows/rust-ci.yml
  - .github/workflows/bump.yml
  - .github/workflows/test-self.yml
  - actions/setup-tools/action.yml
  - actions/setup-tools/setup-tools.test.sh
  - ci/fixtures/setup-tools/mise.toml
  - .ops.toml
  - docs/consuming.md
  - docs/foundation.md
  - docs/versioning.md
  - README.md
  - mise.toml
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
- [x] #1 rust-ci and bump take an opt-in input that installs each tool at the caller's mise.toml pin, falling back to forge's, classified in docs/versioning.md
- [x] #2 test-self exercises it against a fixture mise.toml
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-09-29: rust-ci already moved to the caller's mise.toml on #21 (not opt-in; shipped as a breaking change on v1 by owner decision). This task now covers bump only.

2026-10-03: implemented on branch task-0052-bump-repo-pins. bump takes `tool-pins` (`forge` default, `repo`), passed to setup-tools as `pins` with `pins-directory` = bump's `working-directory`. setup-tools.sh reads each tool's version out of the caller's mise.toml as text and hands mise `name@version`, so mise still loads only forge's config. The open points, as settled:
- Table pins: the caller's `version` is taken (inline table or `[tools.<name>]`), its other options are ignored. forge's own options still apply: `mise install cargo-nextest@0.9.140` under forge's mise.toml used forge's `version_prefix` (checked with mise 2026.10.0).
- A different backend name: the pin is found under the tool's name or under the backend forge's `[tool_alias]` gives it (`"cargo:cargo-edit"`). Any other backend key is not found and forge's pin is used; the step log names each version's source.
- Next major: versioning.md classifies the input as non-breaking and the default flip to `repo` as breaking, left for the next major. Not decided here.
Also: nearest mise.toml wins, walking up from `working-directory` to the workspace root; only the name `mise.toml` is read; `repo` with no mise.toml, or a pin with no single version (an array), fails the step.
Tests: `ops qa` runs actions/setup-tools/setup-tools.test.sh (resolution rules, no network); test-self's `setup-tools-repo-pins` job installs against ci/fixtures/setup-tools/mise.toml. `ops verify` and `ops qa` pass locally.

Closed 2026-10-03: merged as #26, Test self green on the PR and on main (run 37117533694), `setup-tools-repo-pins` included. forge-testbed #8 passes `tool-pins: repo` and pins cocogitto in its mise.toml; its Bump run 37117822693 succeeded and logged `cargo-edit 0.13.13 (the repository's mise.toml)` and `cocogitto 7.0.0 (the repository's mise.toml)`. It was a no-op bump (a `ci:` commit), so the install ran and nothing was released.
<!-- SECTION:NOTES:END -->
