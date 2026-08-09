# Consuming forge

Every consumer follows the same shape: a **thin wrapper** in the consuming repo that calls
a reusable workflow here. The wrapper owns the trigger and the repo-specific inputs;
everything else lives in forge.

Pin a **tag**, never `main` — see [versioning.md](versioning.md) for why.

---

## rust-ci

`.github/workflows/ci.yml` in the consumer:

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  rust:
    uses: rsvalerio/forge/.github/workflows/rust-ci.yml@v1
```

Per-repo variants:

| Repo | Wrapper inputs |
|---|---|
| `ops` | `test-args: --ignored`, `env-json: '{"OPS_LOG_LEVEL":"debug"}'` |
| `oxydraw` | `working-directory: backend` (its Cargo workspace is not at the root) |
| `event0` | defaults; expect a backlog of failures on the first run |

oxydraw's `frontend` job stays in its own `ci.yml` as a second job alongside the `uses:`
call — it is Bun/SPA-specific with one consumer.

### Two behaviour changes on adoption

- **`cargo fmt --all --check`.** ops ran `cargo fmt --all` with no `--check`, which
  reformats the tree on the runner and always passes. Expect ops to fail this gate once,
  and fix it with one formatting commit.
- **`event0` has never had CI.** Its first run will surface pre-existing lint and test
  failures. That is a backlog, not a migration bug. Adopt it last.

---

## bump

`.github/workflows/bump.yml` in the consumer:

```yaml
name: Bump
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]

jobs:
  bump:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    uses: rsvalerio/forge/.github/workflows/bump.yml@v1
    with:
      branch: ${{ github.event.workflow_run.head_branch }}
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

Note the explicit `secrets:` block rather than `secrets: inherit` — inherit passes
everything the caller holds, and this workflow needs exactly one secret (PLAN.md §9.3).

### Required cog.toml change

Signed mode pushes the commit and the tag through the API, so cocogitto must **not** push:

```diff
 post_bump_hooks = [
-  "git push",
-  "git push origin v{{version}}",
 ]
```

Leave `pre_bump_hooks` (`cargo set-version`) alone. If the push hooks are still present the
workflow fails at the "Verify cog.toml is compatible with signed mode" step with an
explanation, rather than racing itself into a confusing GraphQL conflict.

To migrate without touching `cog.toml` yet, pass `signed: false`. You then keep unsigned
bump commits, which is the current behaviour in both repos.

### What changes for the consumer

- Bump commits become **Verified** — authored by `my-cloud-ci[bot]`, signed by GitHub.
- Bump commits carry `[skip ci]`, so they no longer re-trigger the full CI + Bump cycle
  (TASK-1659). The `skip_ci` value in `cog.toml` was always defined but never applied,
  because it only takes effect when `cog bump` is passed `--skip-ci`.
- **oxydraw's App token becomes least-privilege.** Its copy omitted `repositories:`, so it
  was minting tokens scoped to every repository in the App installation (SEC-18 /
  TASK-1654). This is the security fix that motivated the consolidation.
- **ops's bump commits change author** from `github-actions[bot]` to the App bot.

---

## publish-homebrew

cargo-dist's `publish-jobs = ["./publish-homebrew"]` resolves a **local** workflow path, so
`.github/workflows/publish-homebrew.yml` must keep existing in the consumer. It shrinks to:

```yaml
name: Publish homebrew formula
on:
  workflow_call:
    inputs:
      plan:
        required: true
        type: string

jobs:
  homebrew:
    uses: rsvalerio/forge/.github/workflows/publish-homebrew.yml@v1
    with:
      plan: ${{ inputs.plan }}
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

This keeps the "survives `dist generate`" property documented in `ops/docs/releasing.md`:
`dist generate` rewrites `release.yml` but never touches this file. It uses 2 of the 4
permitted reusable-workflow nesting levels — do not add a third wrapper.

ops's formula commits change author from `"axo bot" <admin+bot@axo.dev>` to the App bot.

---

## publish-deb

```yaml
jobs:
  deb:
    uses: rsvalerio/forge/.github/workflows/publish-deb.yml@v1
    with:
      package-name: oxydraw
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

Defaults match oxydraw's existing layout (`make build` in `packaging/`,
`make -C packaging deb-path`). Override `build-command`, `deb-path-command` and
`working-directory` for a different layout.

---

## publish-crates

**No real consumer today, deliberately** (PLAN.md §5). The workflow exists so the
capability is proven, but crates.io publication is irreversible — a yanked version stays
visible forever and the crate name is claimed permanently — so activating it is a separate,
per-crate decision.

Two interlocks guard it: `dry-run` defaults to `true`, and setting `dry-run: false`
additionally requires `allow-real-publish: true`.

Before any repo can publish at all:

1. Remove `publish = false` from the crates that should be public — and deliberately keep
   it on the ones that should not (test helpers, `testkit`, extension crates). Currently
   ops has it on 26 of 28 crates, oxydraw 4 of 5, and event0 **27 of 27**.
2. Add a `version` next to every internal `path` dependency. crates.io rejects bare path
   dependencies, and all three workspaces use them
   (`oxydraw-core = { path = "crates/core" }`).
3. Ensure `license`, `description`, `repository` and `readme` resolve on each publishable
   crate — mostly `[workspace.package]` inheritance wiring.
4. Check the crate names are actually available. `ops`, `event0` and `oxydraw` are short
   and plausibly taken.

`cargo publish --workspace` handles inter-crate ordering itself. `cargo-release` and
`release-plz` are deliberately not used: cocogitto already owns the version number, and two
tools must not both own it.

For authentication prefer `auth: trusted` (crates.io Trusted Publishing via OIDC, no stored
secret) over a long-lived `CARGO_REGISTRY_TOKEN` — the same reasoning that retired the
`HOMEBREW_TAP_TOKEN` PAT. **Verify crates.io's current Trusted Publishing setup steps before
relying on it**; setup is per-crate on crates.io and cannot be Terraform-managed today.

---

## Shared configuration

`config/deny.toml`, `config/clippy.toml` and `config/rustfmt.toml` are a **baseline to
extend, not a drop-in replacement**. Vendor them into the consumer and keep repo-specific
additions local:

- `deny.toml` carries no `advisories.ignore` entries. Every existing ignore was justified
  against one repo's dependency tree, and a shared ignore list silently widens everyone
  else's exposure. Keep those in the consuming repo.
- `clippy.toml` carries no `msrv`. It differs per repo (ops 1.80, oxydraw 1.85, event0
  1.92) and belongs next to the `rust-version` it must match.
- `rustfmt.toml` carries no `edition`. `cargo fmt` takes it from each crate's Cargo.toml;
  hardcoding it would format a 2024-edition crate under 2021 rules.

**Rename on adoption.** ops uses `clippy.toml`, event0 uses `.clippy.toml` and
`.rustfmt.toml`. The non-dotted spelling is what Cargo documents and what forge
standardises on. Do not keep both — each tool reads only one, and two files are exactly how
the spellings silently disagree.
