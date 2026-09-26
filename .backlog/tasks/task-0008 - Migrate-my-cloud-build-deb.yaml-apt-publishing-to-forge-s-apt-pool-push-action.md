---
id: TASK-0008
title: 'Migrate my-cloud build-deb.yaml apt publishing to forge''s apt-pool-push action'
status: Triage
assignee: []
created_date: '2026-09-26 16:34'
labels:
  - deb
  - apt
  - adoption
  - my-cloud
dependencies:
  - TASK-0002
modified_files:
  - docs/consuming.md
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
my-cloud's `.github/workflows/build-deb.yaml` release job pushes packages to the apt repo inline. It mints a token with `actions/create-github-app-token@v3` using a floating tag, not a SHA pin. It runs `git clone https://x-access-token:${TOKEN}@github.com/rsvalerio/apt.git`, which puts the token in the remote URL. It copies the file into `pool/` and commits as `github-actions[bot]`, not the App bot. This is the drift forge exists to remove.

Replace the "Mint apt-scoped token" and "Publish to APT repo" steps with `rsvalerio/forge/actions/apt-pool-push@v1`, passing the path from `just deb-path`. my-cloud keeps its own build, test and GitHub Release steps, because its Docker and systemd test harness is specific to it. So this should use the action, not the whole `publish-deb.yml` workflow.

This also brings pool retention (from the pool growth task) to my-cloud's packages. `my-haproxy` alone has five versions in the pool today.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 my-cloud's release job publishes to the apt pool via apt-pool-push
- [ ] #2 No token appears in a git remote URL; commits are attributed to the App bot
- [ ] #3 A my-* tag release still lands its .deb in rsvalerio/apt and passes just repo-smoke
<!-- AC:END -->
