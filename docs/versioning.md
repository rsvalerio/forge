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
- uses: actions/checkout@v6
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

1. Testbed green on `main`.
2. Tag `vX.Y.Z`.
3. **The moving major tag repoints itself.** Callers of the shared `bump.yml` pass
   `major-tag: v1` and the workflow points it at the release it just cut, as a
   lightweight ref, in the same job that created the version tag.

   This step used to be manual, and skipping it once is what put `v1` on `v0.1.2` while
   `v0.2.0` shipped: every consumer following the `@v1` convention silently kept running
   the older workflow, and `ops` worked around it with an exact pin that did not pin the
   composite actions anyway. A convention that tells consumers not to edit anything only
   holds if the tag they pin moves without anyone remembering to move it.

   For a release cut by hand, the equivalent is:
   ```bash
   git tag -f -m "v1 -> vX.Y.Z" v1 'vX.Y.Z^{}' && git push -f origin v1
   ```
   Both extras earn their keep. `^{}` peels the annotated release tag to the commit it
   points at — without it you create a *tag object pointing at a tag object*, which git
   warns about and which consumers resolve inconsistently. `-m` supplies the message that
   `tag.gpgsign = true` makes mandatory; without it git drops you into `$EDITOR` mid-release.
   Quote the `^{}` — zsh treats both characters as glob syntax. The workflow sidesteps all
   of this by creating a lightweight ref through the API, which cannot nest.
4. For a major bump, do **not** repoint `v1` — publish `v2` and migrate consumers one at a
   time, so a bad major cannot take every pipeline down at once. The workflow enforces
   this: it compares the major of the tag it just cut against `major-tag` and skips the
   repoint with a notice when the release has moved past it. A release *below* the moving
   tag still repoints, which is the `0.x` case forge itself is in today.
