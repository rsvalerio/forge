---
id: TASK-0053
title: 'forge-testbed: go green on ops-only rust-ci and merge its forge-ref: main PR'
status: Triage
assignee: []
created_date: '2026-09-29 19:01'
updated_date: '2026-09-29 19:42'
labels:
  - ci
  - cross-repo
dependencies: []
modified_files:
  - .github/workflows/test-self.yml
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: forge-testbed `.github/workflows/ci.yml` (and `.ops.toml` if it needs one). forge-testbed has no backlog of its own.

**What**: forge-testbed calls `rust-ci.yml@main`, so it gets the ops-only rust-ci (commit 2cb0dcf) the moment it merges, before any tag. Its `ci.yml` on main passes no inputs. The `forge-ref: main` fix is still an open PR (forge-testbed#5), so main loads the composite actions from `v1`. It has no `.ops.toml`, so the ops Rust stack defaults apply: `--all-targets`, `--locked`, nextest plus doctests, doc, deps --check and sec. Any of these can surface failures its cargo-engine runs never did.

**Why it matters**: versioning.md makes a green testbed on main the gate for cutting a release, so this has to be green before v0.7.0 moves v1.

**Origin**: forge rust-ci ops-only change, 2026-09-29.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 forge-testbed PR #5 (forge-ref: main) is merged, so its rust-ci call loads main's actions, not v1's
- [ ] #2 forge-testbed's rust-ci run on forge main is green under the ops jobs (verify-check, test, deps, sec), with any repo-side fixes or an .ops.toml it needs
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-09-29: rust-ci now also installs from the caller's own mise.toml (no forge-ref/toolchain/use-sccache). forge-testbed therefore needs a mise.toml pinning at least ops >= 0.77.0, cargo-nextest, cargo-deny, cargo-machete and trivy (and rust, recommended); see docs/consuming.md 'rust-ci'. forge-testbed#5 (forge-ref: main) becomes moot for rust-ci, since rust-ci no longer loads forge actions; close it or keep it for other workflows.

Update (1366e08): check names are verify, test, deps, sec, msrv; no ops floor guard, so pin ops >= 0.77.0 in forge-testbed's mise.toml.

<!-- SECTION:NOTES:END -->
