---
id: TASK-0005
title: 'Add publish-deb-dist.yml reusable workflow callable as a cargo-dist custom publish job'
status: Done
assignee: []
created_date: '2026-09-26 16:34'
updated_date: '2026-09-26 17:08'
labels:
  - deb
  - cargo-dist
  - ci
  - release
dependencies:
  - TASK-0002
  - TASK-0004
parent_task_id: 'TASK-0009'
modified_files:
  - .github/workflows/publish-deb-dist.yml
  - docs/consuming.md
  - README.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`forge-testbed/.github/workflows/publish-deb.yml` records the gap: dist custom publish jobs are called with a single `plan` input (the dist manifest JSON), but forge's `publish-deb.yml` expects `package-name` and `version` and builds the package itself. So none of the cargo-dist projects (ops, oxydraw, forge-testbed) can publish to apt from their `release.yml`.

Add a reusable workflow, `.github/workflows/publish-deb-dist.yml`, whose signature is compatible with a dist custom publish job, and which consumers call from a thin local wrapper named in `dist-workspace.toml` `publish-jobs`. The shape is the same as ops's `publish-homebrew.yml`: release.yml, then the local wrapper, then forge, which is three levels of nesting against a limit of four.

Inputs:
- `plan` (required, string): the dist manifest. Take the version from `announcement_tag` and the app names from `releases[].app_name`.
- Everything `deb-from-dist` needs for control metadata (description, maintainer, depends, section, homepage, install-path).
- Everything `apt-pool-push` needs, **including `apt-repository` and `dry-run`** (design rule 1).
- `forge-ref` and `runs-on`, following the other workflows.
- Secret: `GH_APP_PRIVATE_KEY`, declared explicitly (design rule 3).

Job:
1. `actions/download-artifact` with `pattern: artifacts-*` and `merge-multiple: true`. The GitHub Release does not exist yet at this point, because `announce` creates it.
2. `deb-from-dist` with `artifacts-dir`.
3. `apt-pool-push` with every resulting `.deb` in a single commit.
4. Upload the `.deb` files as a workflow artifact, so they can be inspected under dry-run.

Skip prereleases the same way the homebrew job does (`announcement_is_prerelease` / `publish_prereleases`). The caller's `if:` normally does this, but document it.

Consumers must also add the new job to `announce.needs` and to its `if:` guard. The hand-maintained `release.yml` files (`allow-dirty = ["ci"]`) will not get that from dist. Include a copy-paste snippet in `docs/consuming.md`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Workflow accepts dist's plan input and derives version and app name from it
- [x] #2 Packages every linux-gnu target from workflow artifacts (no dependency on the GitHub Release existing)
- [x] #3 All per-arch .debs land in the apt pool in one commit; dry-run and apt-repository override work
- [x] #4 Built .debs are uploaded as a workflow artifact
- [x] #5 docs/consuming.md shows the local wrapper, the publish-jobs line, and the announce needs/if edit

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
.github/workflows/publish-deb-dist.yml: reads the plan (the release with linux-gnu tarballs, `app` input to disambiguate), downloads artifacts-* to RUNNER_TEMP, runs deb-from-dist (artifacts-dir mode), uploads the .debs as `deb-<app>-<version>` before pushing, then runs apt-pool-push (one commit, keep-versions default 3; dry-run/apt-repository/pool-path passed through). A job-level `if:` repeats the prerelease guard.
Deviation: the version comes from the selected release's `app_version`, not `announcement_tag`. In a multi-package workspace the tag is `<app>-v<ver>`, which is not a Debian version. For single-app workspaces the two are identical.
Verification: actionlint clean. The jq selection was checked against the real ops v0.65.0 dist-manifest.json. The components it composes have local and CI tests (pool-update.test.sh and the deb-from-dist test-self job). An end-to-end dist run needs a consumer wiring, which is cross-repo (forge-testbed) and is filed as a Triage follow-up.

End-to-end dist wiring is already tracked by TASK-0006 (forge-testbed).

<!-- SECTION:NOTES:END -->
