---
id: TASK-0057
title: 'Replace ci/lint.sh pinned-actions with ops lint-actions'
status: In Progress
assignee: []
created_date: '2026-11-01 12:26'
updated_date: '2026-11-01 12:27'
labels:
  - ci
  - ops-alignment
dependencies: []
modified_files: []
priority: low
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The workflow pin policy is implemented in forge and in ops. ops now has the built-in `ops lint-actions`, which covers workflows and composite action manifests, so forge can drop its own copy. Other half of rsvalerio/ops TASK-2328 AC#2.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 mise.toml pins an ops release with composite-action scanning
- [x] #2 `[lint_actions] allow` exempts forge own refs and lint-pinned-actions runs ops lint-actions
- [x] #3 check_pinned_actions is gone from ci/lint.sh and the README and dependabot comments name the new check
- [x] #4 ops verify and ops qa pass

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
ops lint-actions and the old check both passed the same 16 files before the swap, and a tag-pinned action fails ops verify with the file and line. The rust-ci fixture moved to the same pin; its ops verify passes locally. Gates ran on the local ops build, not the pinned 0.90.1, so test-self is the first run on the release.
<!-- SECTION:NOTES:END -->
