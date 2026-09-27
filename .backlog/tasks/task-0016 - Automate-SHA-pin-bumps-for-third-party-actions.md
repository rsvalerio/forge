---
id: TASK-0016
title: 'Automate SHA-pin bumps for third-party actions'
status: Done
assignee: []
created_date: '2026-09-26 19:42'
updated_date: '2026-09-27 13:17'
labels:
  - ci
  - security
dependencies: []
parent_task_id: 'TASK-0018'
modified_files:
  - .github/dependabot.yml
  - README.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/*.yml`, `actions/*/action.yml`

**What**: every third-party action is now pinned to a commit SHA (README design rule 6), but nothing proposes bumps. forge has no Dependabot/Renovate config for the `github-actions` ecosystem, so pins only move when someone resolves a new tag by hand.

**Why it matters**: frozen pins silently miss security fixes in actions that handle the App private key and publish releases, and every consumer inherits forge's pins.

**Origin**: discovered during TASK-0015 while fixing TASK-0013.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 SHA pins for github-actions are bumped by an automated PR (e.g. Dependabot github-actions ecosystem) that keeps the version comment in sync

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added .github/dependabot.yml (github-actions ecosystem, directories "/" + "/actions/*", weekly, single group). Verified against dependabot-core github_actions FileFetcher: "/" scans .github/workflows plus root action.yml; any other directory scans its own *.yml, so /actions/* covers each composite action.yml. Dependabot updater rewrites the version comment (VersionCommenter). README rule 6 documents it.
<!-- SECTION:NOTES:END -->
