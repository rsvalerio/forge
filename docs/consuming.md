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
| `dbsec` | `runs-on: blacksmith-4vcpu-ubuntu-2404`, `use-sccache: false`, `run-tests: false` |

### Runners that accelerate the Actions cache

`use-sccache: false` is for a runner whose provider proxies the Actions cache to
something colocated. Blacksmith does that for `actions/cache` and the language
`setup-*` actions, and documents sccache as one of the two exceptions that still
reach GitHub's own servers — so on those runners sccache is the one step paying
full latency while everything around it does not. With the input off the jobs
drop `RUSTC_WRAPPER` and cache `target/` with `Swatinem/rust-cache`, which is an
`actions/cache` consumer and so is accelerated like the rest. `fmt` gets neither,
because it compiles nothing.

Leave it on (the default) for GitHub-hosted runners, where sccache's cache is as
near as any other.

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

### Prerequisites

Three things must be true before the first bump can push, and only the first two are
obvious:

1. The **App is installed** on the repository (`my-cloud-ci`, or whichever App the
   private key belongs to), with `contents: write` — it writes the bump commit and the
   version tag.
2. `secrets.GH_APP_PRIVATE_KEY` and `vars.GH_APP_CLIENT_ID` are set on the repository (or
   inherited from the organisation, and *visible* to this workflow).
3. The **App bypasses every ruleset on the target branch that would block a direct
   push**. The bump is a direct push to `main` by design — there is no PR to merge it
   through — so a `pull_request` rule stops it, and so does anything else evaluated on
   the push, such as required status checks. Bypass is granted per ruleset: an App
   listed on one ruleset is still subject to every other ruleset the branch has.

#### The ruleset bypass

Without the bypass, every Bump fails at `Push the bump as a signed commit`. This is
`dbsec`'s failure verbatim; the first two lines are what to search for, and the last
reflects that repository's own check count:

```text
gh: Repository rule violations found
Changes must be made through a pull request.
9 of 9 required status checks are expected.
```

Nothing about that error says "ruleset", and three things conspire to make it read like
something else:

- **It looks like a token problem.** Minting succeeds and the token gets as far as
  ruleset evaluation, so the failure lands on the push. A grant the token genuinely
  lacked fails on the same call but says something else — `Resource not accessible by
  integration` — so the wording, not the timing, is what tells the two apart.
- **`cog bump --auto` is green.** Version computation, the `cog.toml` check and token
  minting all succeed; only the last step fails, so the run looks nearly working.
- **Nobody is watching.** Bump runs on `workflow_run` after CI on the default branch, so
  it is attached to no pull request and can be a required check on none. Nothing red
  appears in front of any change. The only symptom is a release that never happens.

`dbsec` adopted `bump.yml`, added a `main-protection` ruleset without the bypass, and
went nine days and 293 commits with `Cargo.toml` frozen at `0.6.0` before anyone opened
the Actions tab.

Bypass is not free, and it is worth knowing exactly what it gives up. It applies to
**every rule in the ruleset it is granted on**, not only the one blocking the push — so
put in that ruleset the rules the bump must be allowed past (`pull_request`, required
status checks) and keep anything that must hold for the App in a separate ruleset it is
not listed on.

Two of the usual worries do not apply here:

- `required_signatures` loses nothing. The commit is created through
  `createCommitOnBranch`, so GitHub signs it and it lands **Verified** — a stricter
  result than the rule asks for.
- The content is machine-generated: a CHANGELOG entry and a version number, written by
  cocogitto from commits that were already reviewed.

One does. **Nothing has tested the bump commit at the moment it lands** — the run that
triggered the bump tested its parent, and the push happens before any check on the new
commit could run. What follows depends on `skip-ci`:

- **`skip-ci: true` (the default)** — it is never tested at all. The input passes
  `--skip-ci` to `cog bump`, which writes `[skip ci]` into the commit message, and that
  marker is what stops CI running on it.
- **`skip-ci: false`** — CI runs on the bump commit afterwards, so a problem surfaces,
  but after the fact rather than in front of the push.

Either way the ruleset is not what is holding the line here. If that matters for your
repository, validate out of band rather than assuming the green tick upstream covers it.

Where rulesets are Terraform-managed, add a `bypass_actors` block rather than clicking it
into the UI; the API/UI route drifts and the next `apply` reverts it:

```hcl
resource "github_repository_ruleset" "main_protection" {
  # ...

  bypass_actors {
    actor_id    = 1234567 # the App's id, not the installation id
    actor_type  = "Integration"
    bypass_mode = "always"
  }
}
```

Repeat the block on each ruleset that would block the push; one grant does not carry to
the others.

`bypass_mode = "always"` is the mode to use. `pull_request` will not do: it grants the
bypass only within a pull request the actor opened, and the whole difficulty here is that
the bump has no pull request. `exempt`, where your GitHub and provider versions offer it,
also unblocks the push — it skips evaluating the ruleset for that actor entirely — but
prefer `always`: it still evaluates and records the bypass, and that audit entry is what
makes an automated direct push to the default branch reviewable after the fact.

`actor_id` is the **App id**, which the installation endpoint reports (the installation's
own `.id` is a different number and will not match anything):

```shell
gh api /repos/OWNER/REPO/installation --jq .app_id
```

### A failed bump reports itself

Bump is the one workflow nothing watches. It triggers on `workflow_run` after CI on the
default branch, so it runs on no pull request and can be a required check on none — the
branch keeps merging green while the version quietly stops moving, and the only way to
notice is to open the Actions tab. GitHub's default failure email goes to the actor and,
in practice, did not help: `dbsec` went nine days that way.

So on failure the workflow opens an issue in the repository — the failed step by name, a
link to the run, and the three causes worth checking first. Further failures comment on
that same issue rather than opening another, and the next successful bump closes it.

It finds that issue again by a hidden marker it writes into the body, keyed on the branch,
not by the label alone. So bumping two branches gives each its own issue, and an issue you
label by hand is never closed or commented on by the workflow.

This needs the App to hold **Issues: Write**. Without that grant the notify job fails with
an explanation; the bump itself is never failed over a notification, so the close-on-
success step only warns.

Two inputs, both with working defaults:

```yaml
    with:
      branch: ${{ github.event.workflow_run.head_branch }}
      notify-on-failure: false   # default true
      notify-label: bump-failure # created if missing; narrows the search, and is
                                 # there for humans to filter on
```

Turn it off in consumers that already watch their Actions.

### If your release is triggered by the tag push, you need `release-workflow`

`skip-ci` and a tag-triggered release cannot both work. GitHub evaluates `[skip ci]`
against the head commit of a **push event**, and a tag push is a push event — so the
marker that stops the bump commit from re-running CI also stops the release that the
version tag was supposed to trigger. The tag lands, and nothing builds.

This is not hypothetical: it silently swallowed ops's `v0.36.0`.

Pick one:

- **Dispatch the release** (preferred). Set dist's `dispatch-releases = true`, run
  `dist generate`, and point forge at the resulting workflow:

  ```yaml
      with:
        branch: ${{ github.event.workflow_run.head_branch }}
        release-workflow: release.yml
  ```

  `release.yml` then triggers on `workflow_dispatch` with a `tag` input, and the bump job
  calls it once the tag exists. `[skip ci]` keeps doing its job for CI.

- **Turn the marker off** with `skip-ci: false`. The tag push triggers the release as
  before, at the cost of one redundant CI + Bump cycle per release — the bump commit
  re-runs CI, Bump fires again, and cocogitto no-ops because there is nothing to release.

Consumers with no tag-triggered release need neither, and the defaults are already right.

### If you publish a moving major tag, you need `major-tag`

Repos that ask their own consumers to pin a moving tag (`@v1`) must repoint it at every
release, or that tag quietly becomes a pin to an old version. Hand it to the bump
workflow instead of remembering:

```yaml
    with:
      branch: ${{ github.event.workflow_run.head_branch }}
      major-tag: v1
```

The tag is repointed as a **lightweight ref**, in the same job that created the version
tag and immediately after it. Two behaviours worth knowing:

- It creates the tag if it does not exist yet, so the first release with this input set
  needs no manual bootstrap.
- It **refuses to carry the tag past a major**. If the release just cut is `v2.0.0` and
  `major-tag` is `v1`, the step logs a notice and leaves `v1` alone — publishing `v2` and
  migrating consumers one at a time is a deliberate act, not a side effect of a release.
  A release *below* the moving tag (a `0.x` line under an already-published `v1`) still
  repoints, which is the case forge itself is in.

Leave the input unset — the default — if you do not publish a moving tag. Most consumers
do not: this is for repos that are themselves depended on by tag.

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

The pool commit itself is [`apt-pool-push`](#apt-pool-push); `publish-deb` builds the
package and hands it over.

---

## apt-pool-push

A composite action, for a job that already has its `.deb` files and only needs them in
the apt pool. `publish-deb` and `publish-deb-dist` both end with it.

```yaml
      - uses: rsvalerio/forge/actions/apt-pool-push@v1
        with:
          debs: |
            out/ops_0.65.0_amd64.deb
            out/ops_0.65.0_arm64.deb
          package-name: ops
          version: 0.65.0
          app-client-id: ${{ vars.GH_APP_CLIENT_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

- **One call, one commit.** Every file in `debs` lands in a single commit and push, so the
  apt repository's aptly/Pages publish runs once per release rather than once per arch.
- **Idempotent.** If every file is already in the pool with identical contents, the step
  prints `No changes to publish` and exits 0.
- **`dry-run: true`** still mints the token and checks out the apt repository, stages the
  files and prints `git diff --cached --stat`, then stops before committing.
- `apt-repository` (default `rsvalerio/apt`) and `pool-path` (default `pool`) are the
  target override from design rule 1; `owner` sets the App token's owner.
- The token is minted with `mint-app-token`, scoped to the apt repository alone, and the
  commit is authored by the App bot via `app-bot-identity`.
- Outputs: `changed` (the pool differed from what was staged) and `pushed` (a commit was
  pushed).

The action checks the apt repository out under `.apt-pool-push/` in the workspace.

### Retention (`keep-versions`)

`rsvalerio/apt` keeps its `.deb` files in git, so every release grows the repository for
good. That is tolerable for a few small packages a year, and not for ops, which adds about
14 MB per release (amd64 plus arm64) and has shipped 65 of them.

`keep-versions: N` bounds it. In the same commit that adds the new files, the action
removes every version of each published *package and architecture* beyond the newest N,
ordered by `dpkg --compare-versions` (so `1.10.0` sorts above `1.2.0`, and `2.0.0~rc1`
below `2.0.0`).

- It defaults to `0`, which keeps everything: `publish-deb` does not change behaviour.
  `publish-deb-dist` defaults to `3`.
- Only the package and architecture being published are pruned. Other packages, and other
  architectures of the same package (including `Architecture: all`), are left alone.
- Pool filenames are split on `_`, which Debian forbids in both package names and
  versions. So `my-haproxy` and `my-haproxy-sites` are pruned independently, which a
  prefix glob would get wrong.
- Publishing a version older than the newest N (a backfill) adds it and removes it again
  in the same step. The step logs a warning and pushes nothing.

**What apt users see.** Once a version leaves the pool, the next index publish drops it,
and `apt install <pkg>=<old-version>` stops working. Anything that pins an exact version
has to move forward within the retention window. Installs from before the prune are not
touched.

**Retention bounds the pool, not the history.** A removed `.deb` stays in git history
until that history is rewritten. Run `rsvalerio/apt`'s `scripts/squash-history.sh` when
`.git` outgrows the pool it serves. With `keep-versions` set, the pool is the floor that
squash can get back down to.

---

## deb-from-dist

A composite action that turns cargo-dist's `<app>-<triple>.tar.gz` release tarballs into
`<package>_<version>_<arch>.deb`, one per linux-gnu target. It needs no compile, Docker or
Rust toolchain. Most consumers reach it through
[`publish-deb-dist`](#publish-deb-dist) rather than directly.

```yaml
      # Backfill an old version from its existing GitHub Release.
      - id: deb
        uses: rsvalerio/forge/actions/deb-from-dist@v1
        with:
          tag: v0.64.0
          app: ops
          description: Batteries-included task runner
          maintainer: Rodrigo Valeri <rsvalerio@users.noreply.github.com>
      - uses: rsvalerio/forge/actions/apt-pool-push@v1
        with:
          debs: ${{ steps.deb.outputs.debs }}
          package-name: ops
          version: ${{ steps.deb.outputs.version }}
          app-client-id: ${{ vars.GH_APP_CLIENT_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

- **Source.** Pass `artifacts-dir` or `tag`, never both. `artifacts-dir` is a directory
  that `actions/download-artifact` filled (`pattern: artifacts-*`, `merge-multiple: true`).
  It is the only mode a dist publish job can use, because the GitHub Release does not
  exist until `announce` runs. `tag` downloads from a release that already exists, from
  `repository` (default: the calling repository).
- **Version.** Required with `artifacts-dir`. With `tag` it comes from the tag. A
  leading `v` is stripped either way.
- **Checksums.** Every tarball is checked against its `.sha256` sidecar before it is
  unpacked. A missing sidecar or a mismatch fails the step.
- **Targets.** By default, every `<app>-*-unknown-linux-gnu.tar.gz` present.
  `x86_64` maps to `amd64` and `aarch64` to `arm64`. Any other triple, including musl and
  darwin, fails the step instead of getting a guessed architecture.
- **Contents.** The binary goes to `install-path`/`<app>` (default `/usr/bin`), and the
  archive's `LICENSE*` and `README*` go to `/usr/share/doc/<package>/`
  (`include-docs: false` skips them). `description`, `maintainer`, `section` (default
  `utils`), `depends` and `homepage` fill the control file. The first line of
  `description` is the synopsis, and any further lines become the extended description.
- **Outputs.** `debs` holds the built files' absolute paths, one per line, which is exactly
  what `apt-pool-push`'s `debs` takes. `version` is the package version.

---

## publish-deb-dist

The apt counterpart of `publish-homebrew`, for cargo-dist projects (ops, oxydraw,
forge-testbed). dist calls a custom publish job with just the `plan`, so the job takes the
app name and version from the plan, repackages the linux-gnu tarballs dist already built,
and commits every arch to the apt pool in one commit.

Wiring it up takes three edits in the consumer.

**1. A local wrapper**, `.github/workflows/publish-deb-dist.yml`. As with homebrew,
`publish-jobs` resolves a local path, and `dist generate` never touches this file:

```yaml
name: Publish .deb
on:
  workflow_call:
    inputs:
      plan:
        required: true
        type: string
    secrets:
      GH_APP_PRIVATE_KEY:
        required: true

jobs:
  deb:
    uses: rsvalerio/forge/.github/workflows/publish-deb-dist.yml@v1
    with:
      plan: ${{ inputs.plan }}
      description: Batteries-included task runner
      maintainer: Rodrigo Valeri <rsvalerio@users.noreply.github.com>
      homepage: https://github.com/rsvalerio/ops
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

The chain is `release.yml` → wrapper → forge, which is 3 of the 4 permitted nesting
levels. Name the wrapper `publish-deb-dist`, not `publish-deb`: oxydraw already has a
`publish-deb.yml` that builds its own package.

**2. The `publish-jobs` line** in `dist-workspace.toml`:

```toml
publish-jobs = ["./publish-homebrew", "./publish-deb-dist"]
```

**3. `release.yml`: the job, plus the `announce` edit.** Repos that set
`allow-dirty = ["ci"]` (ops) maintain `release.yml` by hand, so dist will not add either
one for them. Add the job next to `custom-publish-homebrew`, with an explicit `secrets:`
block (design rule 3):

```yaml
  custom-publish-deb-dist:
    needs:
      - plan
      - host
    if: ${{ !fromJson(needs.plan.outputs.val).announcement_is_prerelease || fromJson(needs.plan.outputs.val).publish_prereleases }}
    uses: ./.github/workflows/publish-deb-dist.yml
    with:
      plan: ${{ needs.plan.outputs.val }}
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
    permissions:
      "id-token": "write"
      "packages": "write"
```

Then make `announce` wait for it, and still run when it skips itself on a prerelease:

```diff
   announce:
     needs:
       - plan
       - host
       - custom-publish-homebrew
+      - custom-publish-deb-dist
-    if: ${{ always() && needs.host.result == 'success' && (needs.custom-publish-homebrew.result == 'skipped' || needs.custom-publish-homebrew.result == 'success') }}
+    if: ${{ always() && needs.host.result == 'success' && (needs.custom-publish-homebrew.result == 'skipped' || needs.custom-publish-homebrew.result == 'success') && (needs.custom-publish-deb-dist.result == 'skipped' || needs.custom-publish-deb-dist.result == 'success') }}
```

What the job does:

1. Picks the release in the plan that shipped `*-unknown-linux-gnu.tar.gz` artifacts and
   reads its `app_name` and `app_version`. If more than one release qualifies, pass `app`
   to choose.
2. Downloads this run's `artifacts-*` workflow artifacts. The GitHub Release does not
   exist yet, because `announce` creates it after every publish job.
3. Runs [`deb-from-dist`](#deb-from-dist) on them, which gives one `.deb` per linux-gnu
   target.
4. Uploads the `.debs` as the workflow artifact `deb-<app>-<version>`, so they can be
   inspected under `dry-run`. The name deliberately avoids `artifacts-*`, which
   `announce` would attach to the release.
5. Runs [`apt-pool-push`](#apt-pool-push), putting every arch in one commit, with
   `keep-versions` defaulting to **3**. See [Retention](#retention-keep-versions) before
   you change it.

**Prereleases are skipped** the way the homebrew job skips them: when
`announcement_is_prerelease` is true and `publish_prereleases` is not. The caller's `if:`
above does this, and the forge job repeats the guard, so a caller that omits it still
does not ship a prerelease to apt users.

`dry-run`, `apt-repository` and `pool-path` behave as in `apt-pool-push`. The control
metadata inputs (`description`, `maintainer`, `section`, `depends`, `homepage`,
`install-path`, `include-docs`) and `targets` are passed through to `deb-from-dist`.

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
