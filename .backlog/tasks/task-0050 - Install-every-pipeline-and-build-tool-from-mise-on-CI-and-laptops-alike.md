---
id: TASK-0050
title: 'Install every pipeline and build tool from mise, on CI and laptops alike'
status: Triage
assignee: []
created_date: '2026-09-28 17:18'
labels:
  - ops-alignment
  - ci
  - decision
dependencies: []
modified_files:
  - mise.toml
  - docs/foundation.md
  - .github/workflows/rust-ci.yml
  - .github/workflows/bump.yml
  - .github/workflows/publish-crates.yml
  - actions/setup-ops/action.yml
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `mise.toml`, `docs/foundation.md`, `.github/workflows/rust-ci.yml`, `.github/workflows/bump.yml`, `.github/workflows/publish-crates.yml`, `actions/setup-ops/`

**What**: there is no single list of the tools a pipeline needs, and each place installs them differently: mise.toml (forge's own lint tools), setup-ops (ops), taiki-e/install-action with unversioned tools (rust-ci: cargo-deny; bump: cargo-edit, cocogitto), rustup components, and whatever is on a developer's PATH. The same gate can therefore run with different tool versions on a laptop and in CI (e.g. local ops 0.75.0 vs CI's pinned 0.72.0 on 2026-09-28).

**Decision by the owner, 2026-09-28**: mise is the one install method for project build tools, identical on CI runners and laptops. A repo's `mise.toml` pins every tool its gates and pipelines run; CI installs from it (jdx/mise-action) and developers run `mise install`.

**Inventory (2026-09-28)** — tool, who needs it, mise backend:
- ops — every gate, test-self, release — not in mise registry: `github:rsvalerio/ops`
- actionlint, shellcheck, yq — forge `ops verify` — already in forge mise.toml (aqua)
- cargo-deny — ops `qa` deps, rust-ci deny job — `aqua:EmbarkStudios/cargo-deny`
- cargo-edit (cargo-upgrade, cargo-set-version) — ops `qa` deps, bump.yml — not in registry: `github:`/`cargo:` backend
- cargo-machete (optional) — ops `qa` deps — not in registry: `github:bnjbvr/cargo-machete`
- cargo-nextest — rust-ci test (TASK-0026 ops engine) — not in registry: `github:nextest-rs/nextest`
- cargo-llvm-cov — ops coverage — not in registry: `github:taiki-e/cargo-llvm-cov`
- trivy — ops `qa` sec — `aqua:aquasecurity/trivy`
- cocogitto (cog) — bump.yml — `aqua:cocogitto/cocogitto`
- cargo-dist — release pipelines that build dist artefacts — `aqua:axodotdev/cargo-dist`
- sccache — rust-ci cache — `aqua:mozilla/sccache` (today via mozilla-actions/sccache-action)
- gh, jq — publish/bump/apt-pool scripts — preinstalled on GitHub runners; `aqua:cli/cli`, `aqua:jqlang/jq` for laptops
- Rust toolchain + rustfmt/clippy components — stays with rust-toolchain.toml/rustup (mise `rust` optional), not duplicated
- OS packages (dpkg-deb, tar, sha256sum/shasum, curl) — runner image, out of scope

Sources: `ops explain verify|qa --json` in the ops repo (ops 0.75.0), grep of forge workflows/actions/ci, `mise registry` (mise 2026.9.16).

**Open design points**: (1) consumer-facing reusable workflows (rust-ci, bump, publish-crates) install from the consumer's mise.toml when present, else forge-pinned defaults — or require one; (2) whether setup-ops stays as a thin fallback or is retired once ops is a mise tool; (3) whether ops's foundation templates (ops TASK-2330) ship a mise.toml with the Rust gate tools, so `ops init --rust` scaffolds it and `--check` reports drift; (4) `github:` backend entries need a checked prebuilt asset per OS/arch, and mise's own version pinned in CI.

**Relation**: wave10 (TASK-0044) applies this to forge's own workflows via TASK-0030/TASK-0042; this task covers the tool list as a contract (docs/foundation.md) and the consumer side.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 docs/foundation.md lists every tool a Rust repo pipeline needs, the gate/workflow that needs it, and its mise.toml entry
- [ ] #2 forge's reusable workflows install tools from mise (the consumer's mise.toml, or a documented default) instead of taiki-e/install-action and ad-hoc installs
- [ ] #3 ops is pinned in mise.toml and the local and CI versions come from that one entry
- [ ] #4 Follow-up filed in ops for scaffolding/drift-checking mise.toml from the foundation templates
<!-- AC:END -->
