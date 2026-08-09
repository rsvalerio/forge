# forge

Shared CI, release and lint machinery for `ops`, `oxydraw`, `event0` and `my-cloud`.

A software forge is the build-and-release layer, which is what this is: reusable workflows,
composite actions, canonical lint configuration and community templates, in one place
instead of copy-pasted into every repository.

## Why

The copies had already drifted, and the drift was never intentional configuration — it was
fixes that landed in one repo and silently did not land in the other:

- **oxydraw's `bump.yml` omitted `repositories:`** on the App-token mint, so it minted
  tokens scoped to *every repository in the App installation*. The least-privilege fix
  (SEC-18 / TASK-1654) existed in ops only.
- **ops lacked the App-bot attribution** oxydraw had, and still committed as
  `github-actions[bot]`; its Homebrew job still committed as `"axo bot"`.
- **ops's `docs/verified-bump/README.md` described oxydraw's state**, not its own — and its
  central recommendation was wrong anyway (see [docs/verified-bump.md](docs/verified-bump.md)).
- **`event0` has no `.github` directory at all**: a 26-crate workspace with encryption and
  key-custody crates and zero automated verification.

Consolidating is not cleanup. It is the fix for a class of bug that has already bitten
three times.

## Layout

```
actions/                      # composite actions — step-level, run inside the caller's job
  signed-commit/              #   GitHub-signed commits via GraphQL createCommitOnBranch
  mint-app-token/             #   App tokens with mandatory least-privilege scoping
  app-bot-identity/           #   resolve ${APP_SLUG}[bot] and configure git
.github/workflows/            # reusable workflows — job-level, own runner
  rust-ci.yml                 #   fmt / check / clippy / build / test / deny
  bump.yml                    #   cocogitto version bump, signed commit + tag
  publish-homebrew.yml
  publish-deb.yml
  publish-crates.yml          #   built, proven, and deliberately unadopted (PLAN.md §5)
  test-self.yml               #   forge's own CI
config/                       # canonical deny.toml / clippy.toml / rustfmt.toml
templates/                    # SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, issue + PR templates
docs/
plans/                        # design docs
```

Composite actions and reusable workflows are not interchangeable: an action is a *step*
inside the caller's job; a reusable workflow is a whole *job* with its own runner.

## Using it

See **[docs/consuming.md](docs/consuming.md)** for a wrapper per capability, and
**[docs/versioning.md](docs/versioning.md)** for the pinning rules.

The short version — pin a tag, never `main`:

```yaml
jobs:
  rust:
    uses: rsvalerio/forge/.github/workflows/rust-ci.yml@v1
```

## Design rules

1. **Every publishing workflow takes `dry-run` and a target override.** A hardcoded
   `rsvalerio/homebrew-tap` or `rsvalerio/apt` makes the capability untestable without
   polluting production. This is the cheapest design mistake to avoid and the most likely
   one to make.
2. **`publish-crates` never really publishes from a fixture.** crates.io publication is
   irreversible, so it carries two independent interlocks and defaults to `--dry-run`.
3. **Prefer explicit `secrets:` blocks over `secrets: inherit`**, which passes everything
   the caller holds.
4. **Migrate fixes *as* you extract.** Extracting either repo's copy verbatim would freeze
   that repo's regression into the shared version.
5. **Reusable workflow nesting is capped at 4 levels.** The wrapper-calls-shared pattern
   uses 2. Do not stack further.

## Status

Everything in [plans/PLAN.md](plans/PLAN.md) that lives *inside this repository* is
implemented: the three composite actions, the five reusable workflows, `test-self.yml`,
the shared configs, the templates and the docs.

Deliberately not done yet:

| | |
|---|---|
| `forge-testbed` (phase 2) | Separate repository. Until it exists, the publishing workflows' `dry-run` paths are unexercised end-to-end. |
| `terraform/github/forge.tf` in `my-cloud` | Repo, ruleset and App credentials are still manual. |
| Consumer adoption (`ops`, `oxydraw`, `event0`) | No repo calls these workflows yet. |
| A `v1` tag | Nothing to pin until the testbed proves it. |
| crates.io prerequisites | Explicitly out of scope (PLAN.md §5) — irreversible, so it waits for a deliberate per-crate decision. |
