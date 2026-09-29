# Versioning and release

## Consumers pin a tag, never `main`

A shared CI repository is a single point of failure by construction: one bad commit on
`main` breaks every consumer's release pipeline simultaneously, and it breaks them at the
moment they are trying to ship. Pinning a tag turns that from an outage into a decision.

```yaml
uses: rsvalerio/forge/.github/workflows/bump.yml@v1     # yes
uses: rsvalerio/forge/.github/workflows/bump.yml@main   # no
```

`v1` is a **moving major tag**: it is repointed at each release, so consumers get fixes
without editing anything, and never get a breaking change silently. Note that forge's own
version line is still `0.x` — `v1` is the tag consumers pin *now*, ahead of the version
number catching up, which is the point of publishing one before the API is frozen. The
release workflow repoints it automatically and refuses to carry it past a major (see
[Cutting a release](#cutting-a-release)).

### SHA-pinning takes two refs, not one

SHA-pin instead wherever the consuming repo already SHA-pins its other actions — but a
pin on the `uses:` line alone **is not a pin**:

```yaml
uses: rsvalerio/forge/.github/workflows/bump.yml@<sha>   # pins the workflow file
with:
  forge-ref: <same sha>                                  # ...and the actions it runs
```

The reusable workflows check forge out at `forge-ref` to load their composite actions
(see below), and that input **defaults to `v1`**. Pinning only the `uses:` ref leaves
`mint-app-token`, `app-bot-identity`, `signed-commit`, `move-major-tag`, `setup-tools` and
`setup-rust` floating on `v1` — and with `setup-tools`, the tool versions in forge's
`mise.toml` too. That is exactly what happened in `ops`: it pinned `@v0.2.0` for weeks
while running v0.1.2's actions, including on the job that receives `GH_APP_PRIVATE_KEY`.
Set both refs, or neither. `rust-ci` takes `forge-ref` too: its deps job and every
`engine: ops` job load `setup-tools` this way.

## The one exception: forge-testbed floats on `main`

`forge-testbed` (PLAN.md §7) is deliberately the inverse. It tracks `main` so breakage
surfaces there *before* a tag is cut. That inversion is what makes tag-pinning safe for
everyone else.

```
green testbed on main  →  tag v1.x  →  real consumers pick it up
```

This is why the reusable workflows take a `forge-ref` input. They check forge out into the
workspace to load its composite actions, and the testbed passes `forge-ref: main` so the
actions under test come from `main` too. Without it, a workflow from `main` would silently
load actions from `v1` and the testbed would be testing a mixture.

Real consumers should leave `forge-ref` at its default.

## Why the workflows check forge out instead of `uses:`-ing it directly

A `./`-prefixed `uses:` inside a **reusable workflow** resolves against the *caller's*
workspace, not against the repository the workflow lives in. And `uses:` cannot take an
expression, so `rsvalerio/forge/actions/x@${{ inputs.forge-ref }}` is not valid either.

The way out is to make the *path* static and the *ref* dynamic:

```yaml
- uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
  with:
    repository: rsvalerio/forge
    ref: ${{ inputs.forge-ref }}
    path: .forge
- uses: ./.forge/actions/signed-commit    # static path, ref chosen above
```

This checkout must come **after** the consumer's own checkout, which cleans the workspace
root and would otherwise delete `.forge`.

This step is the single pattern: `bump`, `publish-deb`, `publish-deb-dist`,
`publish-homebrew` and `rust-ci` each carry an identical `Check out forge` step, and a new reusable
workflow that needs a composite action copies it verbatim. It cannot be shared any further.
A composite action that did the checkout would itself have to be loaded from `.forge`, and
a reusable workflow cannot contribute steps to another job.

## Inputs every reusable workflow shares

The workflows that mint an App token or load composite actions repeat the same inputs.
Reusable workflows cannot inherit inputs, so each declares its own copy. They mean the same
thing everywhere, and a new workflow takes them with these names and defaults:

| Input | Default | Meaning |
|---|---|---|
| `owner` | `rsvalerio` | Owner of the repository the App token is scoped to: the bumped repo, the apt repo or the tap. |
| `app-client-id` | `""` | The App's client id. Empty falls back to the caller's `vars.GH_APP_CLIENT_ID`. |
| `forge-ref` | `v1` | Ref to check forge out at for its composite actions (see above). |
| `dry-run` | `false` | Do everything short of the write that publishes. `bump` has none. `publish-crates` defaults to `true` behind a second interlock, because its write cannot be undone. |
| `runs-on` | varies | Runner label. See below. |

Two defaults differ between workflows on purpose, and aligning them would be a breaking
change (see [What counts as a breaking change](#what-counts-as-a-breaking-change)).

- **`runs-on`.** `publish-deb`, `publish-deb-dist` and `publish-homebrew` default to
  `ubuntu-22.04`, carried over from the consumer workflows they were extracted from.
  `bump`, `publish-crates` and `rust-ci` default to `ubuntu-latest`. For `publish-deb`,
  the image is where the consumer's build command compiles the package, so moving it to a
  newer image can raise the glibc the `.deb` needs. A caller that wants the other image passes
  `runs-on`. The next major can align the defaults.
- **Retention.** `publish-deb-dist` defaults `keep-versions` to `3`. `publish-deb` has no
  `keep-versions` input, so it keeps every version in the pool (apt-pool-push's `0`). That
  was the pool's behaviour before retention existed, and pruning without an opt-in would
  delete published packages. See consuming.md,
  [Retention](consuming.md#retention-keep-versions).

## What counts as a breaking change

Requiring a major bump:

- Removing or renaming a workflow input, or making an optional input required.
- Changing a default in a way that changes behaviour on an unmodified caller — for example
  flipping `publish-crates`'s `dry-run` default.
- Removing a composite action, or changing its outputs.
- Tightening a gate such that a previously green consumer goes red. Adding `--check` to
  `cargo fmt` was exactly this; it happened before `v1`, which is the cheap time for it.

Not breaking: adding an optional input with a default that preserves current behaviour,
adding a new workflow or action, or clarifying documentation.

## rust-ci `engine: ops`

Rebuilding `rust-ci` on ops gates changes what it runs: clippy and build gain
`--all-targets`, every cargo command gains `--locked`, tests run under nextest with a
separate doctest step, and `ops verify-check` and `ops sec` add gates `engine: cargo` never
had (consuming.md lists them). Each of those can turn a green consumer red, which makes it
a breaking change by the rules above. So on `v1` it ships **opt-in**:

- `engine` defaults to `cargo`, which runs exactly what it ran before. Adding `engine`,
  `run-sec` (which only `engine: ops` reads) and `run-msrv` (default off) is the "optional
  input with a default that preserves current behaviour" case.
- Consumers opt in one at a time — `dbsec` and `forge-testbed` first — by passing
  `engine: ops`, and fix whatever it surfaces in their own repository.
- The **next major** flips the default to `ops`, and removes the deprecated `cargo-flags`,
  `clippy-args` and `test-args` together with `engine: cargo`'s jobs. No separate major is
  cut for it before then.

Pinning tools is not treated as breaking. `rust-ci`'s cargo-deny and `bump`'s cocogitto and
cargo-edit used to install unversioned, which on the day they were pinned resolved to the
versions `mise.toml` now names. Bumping a pin later is an ordinary forge change, reviewed
like one — a cargo-deny release with a stricter check is exactly the gate tightening above.
The same holds for sccache: rust-ci's `engine: ops` and MSRV jobs (through
`setup-rust`) used to take `sccache-action`'s default, the newest sccache release, and now
pass it the `sccache` pin in `mise.toml`, which on the day it was pinned was that newest
release. The frozen `engine: cargo` jobs keep the default. A caller's own `mise.toml` is
not read on `v1`: reading it would change tool versions on an unmodified caller, so it
can only arrive as an opt-in input (forge TASK-0052).

Two side effects of routing `bump`'s `install-tools` through `setup-tools`, neither of
which reaches a known caller (`ops`, `dbsec` and `forge-testbed` all use the default list):

- A name forge's `mise.toml` does not pin now fails instead of installing the latest, so a
  caller adding a tool of its own passes `name@version`.
- A tool already on a self-hosted runner's `PATH` is no longer skipped. It is installed at
  the pinned version, which is the point: a binary on `PATH` says nothing about which
  version it is.

## Cutting a release

Run the **Release** workflow (`.github/workflows/release.yml`) from the Actions tab, with
the version to cut (`vX.Y.Z`) and optionally the ref to cut it from (default `main`). Tick
`dry-run` to run every check without writing a ref.

It does in one run what used to be a checklist. Every check below runs **before any ref
is written**, so a refusal leaves the repository untouched:

1. **Testbed green on `main`.** The target commit must be on the default branch and have a
   successful `Test self` run. A commit whose run is still in flight is refused; wait and
   dispatch again.
2. **Tag `vX.Y.Z`.** The version must be plain `vMAJOR.MINOR.PATCH` (no leading zeros, no
   pre-release suffix), must not exist, and must be greater than every existing release
   tag. A patch for an older line, cut after a newer release, is therefore refused — cut
   it by hand (below) if that ever becomes necessary.
3. **The moving major tag repoints itself.** `v1` is moved to the release in the same run,
   as a lightweight ref. This step used to be manual, and skipping it once is what put `v1`
   on `v0.1.2` while `v0.2.0` shipped: every consumer following the `@v1` convention
   silently kept running the older workflow, and `ops` worked around it with an exact pin
   that did not pin the composite actions anyway. A convention that tells consumers not to
   edit anything only holds if the tag they pin moves without anyone remembering to move
   it. Consumers releasing through the shared `bump.yml` get the same behaviour by passing
   `major-tag: v1`.
4. **A major bump does not repoint `v1`** — publish `v2` and migrate consumers one at a
   time, so a bad major cannot take every pipeline down at once. The workflow enforces
   this: it compares the major of the version against `MAJOR_TAG` (set at the top of
   `release.yml`) and tags the release but leaves the moving tag in place, with a notice,
   when the release has moved past it. A release *below* the moving tag still repoints,
   which is the `0.x` case forge itself is in today. Moving the release line to `v2` is a
   deliberate edit of `MAJOR_TAG`, made together with publishing `v2`.

   The guard and the repoint live in one composite action, `actions/move-major-tag`, which
   `release.yml` and `bump.yml`'s `major-tag:` both run, so the rule cannot drift between
   them.

Two dispatches never race: runs share a concurrency group and queue. The version tag is
created with a plain create, which fails if the ref already exists, so it can never
overwrite a tag — and a failure there stops the run before `v1` is touched.
The one partial outcome is the reverse: `vX.Y.Z` is created, then repointing `v1` fails.
A re-run is refused (the version now exists), so repoint `v1` by hand with the second
command of the [fallback](#fallback-cutting-a-release-by-hand).

The workflow writes with the GitHub App token (`GH_APP_PRIVATE_KEY`,
`vars.GH_APP_CLIENT_ID`), scoped to this repository; the App needs `contents: write` on
forge, which `Test self`'s `signed-commit` job already relies on. No ruleset covers tags
today — if one is added, the App must be on its bypass list.

### Tags are unsigned

Tags created through the API are lightweight refs with no signature, unlike the SSH-signed
annotated tags cut by hand up to `v0.3.2`. That is accepted: the trust a consumer places
in `@v1` or `@vX.Y.Z` comes from who can write refs to this repository — the App and the
maintainers — not from a tag signature, which GitHub does not show for lightweight refs
and which nothing in a consumer's `uses:` resolution checks. The commit under the tag is
still whatever landed on `main` through its protections. Consumers who need a
cryptographic pin already have one: the commit SHA (see
[SHA-pinning](#sha-pinning-takes-two-refs-not-one)).

### Fallback: cutting a release by hand

If the workflow is unavailable (the App token cannot be minted, Actions is down), the
hand-cut equivalent is:

```bash
git tag -s -m "vX.Y.Z" vX.Y.Z <sha>
git tag -f -s -m "v1 -> vX.Y.Z" v1 'vX.Y.Z^{}' && git push origin vX.Y.Z && git push -f origin v1
```

Run the same checks the workflow would have: `Test self` green on `<sha>`, on `main`, the
version new and greater than every existing release tag, and no `v1` repoint for a major
above it. The one exception is a patch for an older line (step 2 above): it must be
greater than every tag on *its own* line, and you run only the first command. `v1` stays
on the newest release, and repointing it at an older one would roll every consumer back.

Both extras earn their keep. `^{}` peels the annotated release tag to the commit it
points at — without it you create a *tag object pointing at a tag object*, which git
warns about and which consumers resolve inconsistently. `-m` supplies the message that
`tag.gpgsign = true` makes mandatory; without it git drops you into `$EDITOR` mid-release.
Quote the `^{}` — zsh treats both characters as glob syntax. The workflow sidesteps all
of this by creating a lightweight ref through the API, which cannot nest.
