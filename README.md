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
  apt-pool-push/              #   commit .debs to the apt pool in one commit, with retention
  deb-from-dist/              #   repackage cargo-dist linux-gnu tarballs into per-arch .debs
  move-major-tag/             #   repoint the moving major tag (v1), never across a major
  setup-ops/                  #   install a pinned, sha256-verified ops release
.github/workflows/            # reusable workflows — job-level, own runner
  rust-ci.yml                 #   fmt / check / clippy / build / test / deny
  bump.yml                    #   cocogitto version bump, signed commit + tag
  publish-homebrew.yml
  publish-deb.yml             #   build a .deb with the consumer's command, then apt-pool-push
  publish-deb-dist.yml        #   dist custom publish job: deb-from-dist, then apt-pool-push
  publish-crates.yml          #   real publish is a per-crate opt-in (PLAN.md §5)
  test-self.yml               #   forge's own CI
ci/lint.sh                    # static checks that `ops verify` runs
ci/fixtures/rust-ci/           # crates test-self runs rust-ci.yml against
config/                       # canonical deny.toml / clippy.toml / rustfmt.toml
templates/                    # SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, issue + PR templates
docs/
plans/                        # design docs
```

`ops verify` is the gate: run it before you push, and test-self's lint job runs the same
command, so its check list lives only in `.ops.toml`. The tools it needs are pinned in
`mise.toml` (`mise install`), which test-self's lint job installs from too, so both run the
same actionlint and shellcheck; CI installs ops itself with `actions/setup-ops`.

Those pins move by hand: Dependabot bumps `jdx/mise-action`'s SHA but reads neither
`mise.toml` nor the mise binary version that test-self's lint job passes the action
(`version:`). Bump all of them together, in one PR, whenever a Dependabot PR moves
`jdx/mise-action` and at least once a month otherwise: `mise latest <tool>` for each tool
in `mise.toml`, and the newest [jdx/mise release](https://github.com/jdx/mise/releases)
for `version:`. Then `mise install` and `ops verify` before pushing, so a new actionlint
or shellcheck check lands together with its fixes.

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
6. **Third-party actions are pinned to a full commit SHA, with the version in a comment**
   (`uses: actions/checkout@<40-hex sha> # v6.1.0`). These workflows hold the App private
   key and publish releases, and every consumer inherits them, so a moved tag would run
   unreviewed code with those credentials everywhere at once. Where ops pins the same
   action, use the same SHA. Local `./` refs and forge's own refs are exempt (the latter
   follow [docs/versioning.md](docs/versioning.md)). `ci/lint.sh pinned-actions` enforces
   this in test-self and `ops verify`. Dependabot (`.github/dependabot.yml`) proposes
   bumps weekly, for workflows and every composite action, moving the SHA and its version
   comment together: minor and patch bumps as one grouped PR, and each major version as
   its own PR, because a major can change what every consumer runs and needs its own
   review. A hand bump resolves the new tag's commit.

## Status

Everything in [plans/PLAN.md](plans/PLAN.md) that lives *inside this repository* is
implemented: the five composite actions, the six reusable workflows, `test-self.yml`,
the shared configs, the templates and the docs.

`v1` is published (currently at `v0.4.0`), and these repos call forge today:

| Workflow | Callers |
|---|---|
| `bump.yml` | `ops@v1`, `dbsec@v1`, `forge-testbed@main` |
| `rust-ci.yml` | `dbsec@v1`, `forge-testbed@main` (`ops` still runs its own `ci.yml`) |
| `publish-crates.yml` | `dbsec@v1` (real publish behind a manual opt-in), `forge-testbed@main` |
| `publish-deb-dist.yml` | `ops@v1` |
| `publish-deb.yml`, `publish-homebrew.yml` | `forge-testbed@main` only |

Deliberately not done yet:

| | |
|---|---|
| `terraform/github/forge.tf` in `my-cloud` | Repo, ruleset and App credentials are still manual. |
| Consumer adoption (`oxydraw`, `event0`) | Neither calls these workflows yet. |
| crates.io prerequisites | Explicitly out of scope (PLAN.md §5) — irreversible, so it waits for a deliberate per-crate decision. |
