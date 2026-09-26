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
`mint-app-token`, `app-bot-identity` and `signed-commit` floating on `v1` — which is
exactly what happened in `ops`: it pinned `@v0.2.0` for weeks while running v0.1.2's
actions, including on the job that receives `GH_APP_PRIVATE_KEY`. Set both refs, or
neither.

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
