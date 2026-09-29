---
id: TASK-0050
title: 'Install every pipeline and build tool from mise, on CI and laptops alike'
status: In Progress
assignee: []
created_date: '2026-09-28 17:18'
updated_date: '2026-09-29 16:09'
labels:
  - ops-alignment
  - ci
  - decision
dependencies: []
parent_task_id: 'TASK-0051'
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
- [x] #1 docs/foundation.md lists every tool a Rust repo pipeline needs, the gate/workflow that needs it, and its mise.toml entry
- [x] #2 forge's reusable workflows install tools from mise (the consumer's mise.toml, or a documented default) instead of taiki-e/install-action and ad-hoc installs
- [x] #3 ops is pinned in mise.toml and the local and CI versions come from that one entry
- [ ] #4 Follow-up filed in ops for scaffolding/drift-checking mise.toml from the foundation templates

<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented 2026-09-29 (wave12). Most of the install work had landed in wave10 (TASK-0030, TASK-0042): taiki-e/install-action is gone, and rust-ci (deps, every engine: ops job), bump (install-tools) and test-self install through actions/setup-tools at forge mise.toml pins. publish-crates installs nothing beyond the toolchain. This task added: sccache = "0.18.0" in mise.toml, passed by actions/setup-rust to mozilla-actions/sccache-action `version` (was: latest release) through a new `setup-tools.sh pin NAME` subcommand; docs/foundation.md "Pipeline tools" (the tool contract: tool, who needs it, mise.toml entry) and "How the pins reach CI"; consuming.md (setup-rust, setup-tools) and versioning.md (sccache pin not breaking, same rule as the cargo-deny/cocogitto pins; consumer mise.toml not read on v1).

Design points (each the option that changes nothing for an unmodified @v1 caller):
(1) Reusable workflows keep installing from forge mise.toml at forge-ref, the documented default; the consumer mise.toml is not read on v1 (it would silently change tool versions on callers that have one). Opt-in consumer pins filed as forge TASK-0052 (Triage).
(2) setup-ops stays: a published v1 action, and the sha256-verified path setup-tools installs ops through. Locally `mise install` gets the same pin via github:rsvalerio/ops. Retiring it is a next-major question.
(3) Yes: ops templates should ship a mise.toml (follow-up below, AC#4).
(4) github: entries checked 2026-09-29 for Linux/macOS x X64/ARM64 assets: ops (4 dist targets), cargo-nextest (x86_64/aarch64 linux-gnu, universal-apple-darwin), cargo-machete (x86_64 linux-musl, aarch64 linux-gnu, both darwin); cargo-edit compiles via cargo:. Prefer aqua: where it exists (cargo-llvm-cov). mise binary stays pinned in setup-tools (2026.9.14), bumped with mise.toml per README Layout.

Exceptions to "from mise" on CI, documented in foundation.md: the Rust toolchain (rustup / setup-rust-toolchain), sccache (sccache-action at the mise.toml pin, because only a JS action can pass it the Actions cache credentials), and rust-ci frozen engine: cargo jobs, which keep sccache-action default until the default engine flips. gh/jq come from the runner image. AC#2 checked on the "documented default" reading.

AC#4 NOT done: this run may not write to the ops repo. The owner has to file this in ops:
---
Title: Scaffold and drift-check mise.toml from the Rust foundation templates
Labels: foundation
Description: forge TASK-0050 (2026-09-29) made mise the one install method for the tools a Rust repo gates and pipelines run, on CI and laptops; forge docs/foundation.md "Pipeline tools" lists them with their mise.toml entries. Nothing writes or checks a repo mise.toml today, so laptop pins drift from CI. Add a mise.toml template to extensions-rust/foundation/templates/ carrying the gate tools at the versions forge mise.toml pins: [tool_alias] ops = "github:rsvalerio/ops", cargo-nextest = "github:nextest-rs/nextest", cargo-machete = "github:bnjbvr/cargo-machete", cargo-edit = "cargo:cargo-edit"; [tools] ops, cargo-deny, cargo-machete, cargo-nextest (version_prefix = "cargo-nextest-"), cargo-edit, trivy, and "aqua:taiki-e/cargo-llvm-cov". `ops init --rust` writes it when missing; `ops init --rust --check` compares it semantically like the other templates (a tool the template pins must keep its version; tools the repo adds are its own; a deliberate divergence goes under [foundation.waivers]).
AC: (1) the template ships in ops and `ops init --rust` writes mise.toml when missing; (2) `ops init --rust --check` reports a drifted or missing tool pin and honours waivers; (3) ops own mise.toml matches the template; (4) ops docs/foundation.md lists the file.
---
Left In Progress only for AC#4; close it once the ops task exists.
<!-- SECTION:NOTES:END -->
