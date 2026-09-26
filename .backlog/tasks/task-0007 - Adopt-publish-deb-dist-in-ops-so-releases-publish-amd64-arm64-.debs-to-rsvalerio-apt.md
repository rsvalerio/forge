---
id: TASK-0007
title: 'Adopt publish-deb-dist in ops so releases publish amd64/arm64 .debs to rsvalerio/apt'
status: Triage
assignee: []
created_date: '2026-09-26 16:34'
labels:
  - deb
  - apt
  - adoption
  - ops
dependencies:
  - TASK-0003
  - TASK-0005
  - TASK-0006
modified_files:
  - docs/consuming.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ops currently ships Linux binaries through the GitHub Release tarballs, the `ops-installer.sh` curl installer (into `~/.cargo/bin`, with `install-updater = false`) and Linuxbrew. An apt package would give Debian and Ubuntu machines, including the arm64 Raspberry Pis, `apt install ops` and upgrades through `apt upgrade`, which none of the current Linux options offer.

Adopt `publish-deb-dist.yml` in `rsvalerio/ops`. This task is tracked in forge because it is forge's first consumer of the workflow.

Changes in ops:
- `.github/workflows/publish-deb.yml`: a local wrapper (same shape as `publish-homebrew.yml`) calling `rsvalerio/forge/.github/workflows/publish-deb-dist.yml@v1` with `description: "Batteries-included task runner for any stack"`, the maintainer, and the homepage. Pass `GH_APP_PRIVATE_KEY` explicitly, never `secrets: inherit`, because ops's `workflow-guard` enforces this.
- `dist-workspace.toml`: set `publish-jobs = ["./publish-homebrew", "./publish-deb"]`.
- `.github/workflows/release.yml`: add `custom-publish-deb` (with SHA pins and an explicit `secrets:` block), and add it to `announce.needs` and its `if:` guard.
- Check that the my-cloud-ci GitHub App installation covers `rsvalerio/apt` for ops's credentials. my-cloud and oxydraw already push there.
- README "Installing": add an apt section (add the key and source, then `apt install ops`).

Changes in `rsvalerio/apt`:
- Fix the README's "pushed here by `rsvalerio/ops` on release" line, which is wrong today. List the actual publishers: my-cloud, oxydraw and ops.

Rollout: run the first release with `dry-run: true`, then switch it off. Don't release ops to apt until the pool growth task is done.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An ops release adds ops_<v>_amd64.deb and ops_<v>_arm64.deb to rsvalerio/apt pool in one commit
- [ ] #2 sudo apt install ops works on an amd64 host and an arm64 Raspberry Pi after adding the repo
- [ ] #3 ops workflow-guard still passes (SHA pins, explicit secrets)
- [ ] #4 ops README documents apt installation; apt README lists the real publishers
<!-- AC:END -->
