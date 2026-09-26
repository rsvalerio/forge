---
id: TASK-0013
title: 'Decide on pinning third-party actions to commit SHAs across forge workflows'
status: Triage
assignee: []
created_date: '2026-09-26 18:31'
labels:
  - ci
  - security
dependencies: []
modified_files:
  - .github/workflows
  - actions
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/*.yml`, `actions/*/action.yml`

**What**: every forge workflow and composite action references actions by mutable major tag (`actions/checkout@v6`, `actions/download-artifact@v7`, `actions/upload-artifact@v6`, `actions/create-github-app-token@v3`, `raven-actions/actionlint@v2`). ops pins the same actions to full commit SHAs (SEC-35/TASK-1661). CodeRabbit flagged the tag references in publish-deb-dist.yml on PR #12. Pinning a single file would leave forge inconsistent, so this needs a repo-wide decision.

**Why it matters**: these workflows handle the App private key and publish release artifacts. A moved tag runs different code with those credentials. forge is also the shared layer every consumer inherits, so its pinning policy is effectively theirs too.

**Origin**: discovered during TASK-0009 review (PR #12, CodeRabbit comment on publish-deb-dist.yml).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A pinning policy for third-party actions is recorded in README design rules
- [ ] #2 Every uses: reference in forge follows that policy, with a version comment beside each SHA if SHAs are chosen
<!-- AC:END -->
