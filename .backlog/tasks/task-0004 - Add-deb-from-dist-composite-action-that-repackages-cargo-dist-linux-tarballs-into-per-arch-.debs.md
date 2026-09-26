---
id: TASK-0004
title: 'Add deb-from-dist composite action that repackages cargo-dist linux tarballs into per-arch .debs'
status: Triage
assignee: []
created_date: '2026-09-26 16:33'
labels:
  - deb
  - cargo-dist
  - actions
dependencies: []
modified_files:
  - actions/deb-from-dist/action.yml
  - docs/consuming.md
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
cargo-dist releases already contain finished linux-gnu binaries (`<app>-x86_64-unknown-linux-gnu.tar.gz` and `<app>-aarch64-unknown-linux-gnu.tar.gz`). Wrapping a single binary in a `.deb` does not need another compile, Docker or a Rust toolchain. It only needs the tarball unpacked into a staging tree with a control file, followed by `dpkg-deb --root-owner-group --build`, which is what my-cloud's `deb/Makefile`s already do by hand.

Add a composite action, `actions/deb-from-dist`.

Inputs:
- The source of the tarballs, either:
  - `artifacts-dir` (primary): a directory the caller has already filled with `actions/download-artifact` (`pattern: artifacts-*`, `merge-multiple: true`). **This is the mode dist custom publish jobs need.** They run after `host` and before `announce`, and `announce` runs `gh release create`, so the GitHub Release does not exist yet when they execute.
  - `tag` (fallback): download from an existing GitHub Release with `gh release download`. Use this to backfill old versions or for manual runs.
- `version`: required with `artifacts-dir`, where the caller takes it from the plan's `announcement_tag`. With `tag`, it comes from the tag.
- `app`: the binary and archive name (for example `ops`), and `package-name` (defaults to `app`).
- Control metadata: `description`, `maintainer`, `section` (default `utils`), `depends` (default empty), `homepage`.
- `targets`: which dist triples to package. Default: every `*-unknown-linux-gnu` asset in the release.
- `install-path`: default `/usr/bin`.

Behaviour:
- Find the tarballs in `artifacts-dir`, or download them in `tag` mode, and check each against its `.sha256` sidecar.
- Map triples to Debian arches: `x86_64` to `amd64`, `aarch64` to `arm64`. Fail on any triple it cannot map instead of guessing.
- Strip any leading `v` from the version. Produce `<pkg>_<version>_<arch>.deb`.
- Output the paths as a newline-separated list, so the result feeds straight into `apt-pool-push`.
- Optionally include the LICENSE and README from the archive under `/usr/share/doc/<pkg>/`.

musl targets are out of scope. ops ships none, and the apt repo serves Debian and Ubuntu (glibc).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Given a dist artifacts directory (or a release tag), produces one .deb per linux-gnu target with the correct Debian arch
- [ ] #2 Tarball checksums are verified against the release .sha256 files before packaging
- [ ] #3 An unmappable target triple fails the step
- [ ] #4 Built .debs pass dpkg-deb --info / --contents and install cleanly with apt-get install ./pkg.deb
- [ ] #5 Output paths are consumable by apt-pool-push without transformation
<!-- AC:END -->
