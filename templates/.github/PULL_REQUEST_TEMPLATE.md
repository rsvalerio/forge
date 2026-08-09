<!--
Keep the title in Conventional Commits form — it becomes the squashed commit message, and
that message is the sole input to the next version number and changelog entry.

  feat(collab): relay user-follow viewport events
  fix(server): strip port from bracketed IPv6 Host headers
-->

## What and why

<!-- What changes, and the reason. Link the issue with "Closes #123" if there is one. -->

## How it was verified

<!-- Tests added, or the manual check performed. "CI is green" is not verification of new
     behavior — say what would have failed before this change. -->

## Checklist

- [ ] Title follows Conventional Commits (`feat:`, `fix:`, `docs:`, …)
- [ ] `cargo fmt --all --check`, `cargo clippy --all --all-features -- -D warnings` and
      `cargo test --all --all-features` pass locally
- [ ] `cargo deny check` passes, if dependencies changed
- [ ] Tests added or updated for behavior changes
- [ ] Docs updated for behavior or configuration changes
- [ ] Breaking changes are marked with `!` or a `BREAKING CHANGE:` footer
