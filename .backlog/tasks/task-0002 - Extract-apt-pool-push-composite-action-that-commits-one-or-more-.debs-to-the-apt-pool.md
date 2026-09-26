---
id: TASK-0002
title: 'Extract apt-pool-push composite action that commits one or more .debs to the apt pool'
status: Triage
assignee: []
created_date: '2026-09-26 16:33'
labels:
  - deb
  - apt
  - actions
dependencies: []
modified_files:
  - actions/apt-pool-push/action.yml
  - .github/workflows/publish-deb.yml
  - docs/consuming.md
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every `.deb` publisher repeats the same tail: mint a token scoped to the apt repo, check out `rsvalerio/apt`, copy the `.deb` into `pool/`, commit as the App bot and push. `publish-deb.yml` has one copy. my-cloud's `build-deb.yaml` has a second inline copy that does not use forge. A dist-based workflow (see the `publish-deb-dist.yml` task) would add a third.

Extract this into a composite action, `actions/apt-pool-push`, and make `publish-deb.yml` build the package and then call it.

Inputs:
- `debs`: newline-separated list of `.deb` paths. It must accept more than one, because ops publishes `amd64` and `arm64` from a single release.
- `package-name` and `version`: used in the commit message (`<pkg>: add <version>`).
- `apt-repository` (default `rsvalerio/apt`), `pool-path` (default `pool`), `dry-run`, `owner`, `app-client-id`, and the App private key.

Behaviour:
- Put every `.deb` from one call in **one commit and one push**, so the apt repo's aptly/Pages publish runs once per release, not once per arch.
- Keep today's idempotency: if every file is already present with identical contents, exit 0 with "No changes to publish".
- Under dry-run, check out the target and stage the files, print `git diff --cached --stat`, and do not commit.
- Reuse `mint-app-token` (scoped to the apt repo only) and `app-bot-identity`.

`publish-deb.yml`'s inputs and behaviour stay unchanged for oxydraw.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 actions/apt-pool-push pushes N .deb files to the pool in a single commit
- [ ] #2 Re-running with identical files is a no-op that exits 0
- [ ] #3 dry-run stages the files and shows the diff without committing or pushing
- [ ] #4 publish-deb.yml delegates to the action with no change to its inputs
- [ ] #5 docs/consuming.md documents the action
<!-- AC:END -->
