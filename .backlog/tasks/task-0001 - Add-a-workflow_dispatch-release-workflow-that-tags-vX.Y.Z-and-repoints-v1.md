---
id: TASK-0001
title: 'Add a workflow_dispatch release workflow that tags vX.Y.Z and repoints v1'
status: To Do
assignee: []
created_date: '2026-09-26 10:04'
updated_date: '2026-09-26 16:50'
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
- [ ] #2 A release whose major is above v1's is tagged but does not move v1
- [ ] #3 An existing or non-increasing version fails before any ref is written
- [ ] #4 docs/versioning.md describes the workflow as the primary release path
<!-- AC:END -->
