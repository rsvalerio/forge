---
id: TASK-0001
title: 'Add a workflow_dispatch release workflow that tags vX.Y.Z and repoints v1'
status: In Progress
assignee: []
created_date: '2026-09-26 10:04'
updated_date: '2026-09-26 19:40'
labels:
  - ci
  - release
dependencies: []
parent_task_id: 'TASK-0010'
modified_files:
  - .github/workflows
  - docs/versioning.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Cutting a forge release is manual today. forge has no Bump workflow of its own, so the moving `v1` tag that every consumer pins only moves when someone runs the hand-cut path in `docs/versioning.md#cutting-a-release`:

```bash
git tag -s -m "vX.Y.Z" vX.Y.Z <sha>
git tag -f -s -m "v1 -> vX.Y.Z" v1 'vX.Y.Z^{}' && git push origin vX.Y.Z && git push -f origin v1
```

This was done by hand for v0.3.2 (#11) on 2026-09-26. The docs themselves record what happens when the step is skipped: `v1` sat on v0.1.2 while v0.2.0 shipped.

Add a manually triggered workflow (`workflow_dispatch`) that does this from the Actions tab.

Options to weigh:

1. **Dogfood `bump.yml`.** Add a `cog.toml` to forge and a caller workflow with `on: workflow_dispatch` that calls `./.github/workflows/bump.yml` with `major-tag: v1`. This reuses the existing major-guard and lightweight-ref logic, and forge tests its own release path. It needs the GitHub App installed on forge with `contents: write`, plus a decision on how cog picks the version (auto from conventional commits, or a `version` input).
2. **Standalone release workflow.** `workflow_dispatch` with a required `version` input (`vX.Y.Z`) and an optional `ref` (default `main`). It creates the tag and repoints `v1` through the API with the App token. It must copy `bump.yml`'s rule: refuse to move `v1` past a major bump (a `v2.x` release publishes `v2` instead).

Either way:
- Refuse a version that already exists or that is not greater than the current latest `v0.x`/`v1.x` tag.
- Gate on "Test self" being green on the target commit (docs step 1: testbed green on `main`).
- Tags created through the API are unsigned, unlike today's SSH-signed tags. Decide whether that is acceptable, and note it in `docs/versioning.md`.
- Update `docs/versioning.md#cutting-a-release` so the workflow is the primary path and the hand-cut commands are the fallback.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Running the workflow from the Actions tab with a version creates vX.Y.Z on the chosen ref and moves v1 to it
- [x] #2 A release whose major is above v1's is tagged but does not move v1
- [x] #3 An existing or non-increasing version fails before any ref is written
- [x] #4 docs/versioning.md describes the workflow as the primary release path

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in wave TASK-0010 (commit 0f2d8e8 on code-review/run-20260926): option 2, standalone .github/workflows/release.yml (workflow_dispatch; inputs version, ref=main, dry-run) + docs/versioning.md "Cutting a release" rewritten with the workflow as primary path, hand-cut commands as fallback, and a "Tags are unsigned" section recording why API-created unsigned tags are acceptable.

Design: read-only `check` job on GITHUB_TOKEN (version format, exists, > latest vX.Y.Z via sort -V; ref resolves and is an ancestor of the default branch; a successful `Test self` run exists for the SHA; major guard copied from bump.yml with MAJOR_TAG=v1) -> `release` job (skipped on dry-run) mints the App token, POSTs refs/tags/vX.Y.Z (fails 422 if it appeared since), then PATCH-force/POST v1 only if released major <= 1. concurrency group `release` queues dispatches.

Verification (no live dispatch, per run instructions):
- actionlint (with shellcheck 0.11.0 over run: blocks) clean; test-self lint job checks run locally, clean, pre-merge and on the integration branch.
- AC2: major guard reasoned and mirrors bump.yml's tested logic; v2.x -> move=false, release job still tags, repoint step skipped by `if`.
- AC3: version logic extracted and run locally against the real tag list (+ v0.3.10 case): existing -> refused, v0.3.9 < v0.3.10 -> refused, malformed/pre-release refused, v0.4.0/v1.0.0/v2.0.0 accepted, empty tag list accepted. All refusals are in the `check` job, which has no write token and precedes the `release` job (needs: check). Read-only API calls exercised live: matching-refs/tags/v, commits/<ref> (bad ref -> 422 non-zero), compare/<sha>...main (ahead/identical), test-self runs?head_sha&status=success (1 for v0.3.2's commit, 0 for an unknown SHA).
- AC4: docs/versioning.md updated.

OPEN — AC1 needs a live run and cannot be proven locally: workflow_dispatch only works once release.yml is on the default branch. After the run PR merges to main: dispatch Release with dry-run=true (confirms checks pass on GitHub), then a real release (e.g. next vX.Y.Z), and confirm vX.Y.Z and v1 both point at the chosen commit (`git ls-remote --tags origin`). Then check AC1 and close this task and wave TASK-0010.
<!-- SECTION:NOTES:END -->
