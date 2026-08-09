# Shared CI/release repository — plan

Status: **proposed**, 2026-08-09. Nothing implemented yet.

A single repository holding the CI, release and lint machinery that `ops`, `oxydraw` and
`event0` currently duplicate (or, in event0's case, lack entirely) — plus the crates.io
publishing flow none of them have yet.

---

## 1. Name

`actions` is too narrow: this will hold reusable **workflows**, shared **lint/deny configs**,
issue and PR **templates**, and possibly repo **scaffolding** — composite actions are only one
of five things in it.

**Recommendation: `forge`.**

- Short, and already means "where things are built" in this exact domain (a "software forge"
  is the standard term for the CI/VCS layer).
- Says nothing about *what kind* of artifact lives inside, so adding lint configs or templates
  later never makes the name a lie.
- Sits well beside the existing vocabulary: `my-cloud` (infrastructure), `ops` (developer CLI),
  `forge` (build & release).

Alternatives, roughly in order:

| Name | Read |
|---|---|
| `platform` | Accurate "internal developer platform"; slightly corporate, and vague about scope |
| `toolkit` | Friendly, inclusive; a little generic |
| `ci-kit` | Explicit; re-narrows toward CI, the trap `actions` already falls into |
| `common` / `shared` | Maximally inclusive and maximally uninformative |
| `.github` | Special-cased by GitHub for defaults; too magic, and not a natural home for actions |

The rest of this document says `forge`. Renaming is a `git mv` plus a find/replace on `uses:`
lines, so this is cheap to change *before* the first consumer is pinned, and annoying after.

---

## 2. Why — the evidence

### 2.1 Duplication is already causing divergence

Measured 2026-08-09, `ops` vs `oxydraw`:

| Workflow | Shared | Diverged |
|---|---|---|
| `publish-homebrew.yml` | ~90% | 11 lines |
| `bump.yml` | ~80% | 22 lines |
| `ci.yml` | ~55% | 58 lines |

None of the divergence is intentional per-repo configuration. All of it is a fix that landed
in one repo and silently did not land in the other:

- **oxydraw's `bump.yml` omits `repositories:`** on the App-token mint — the SEC-18 /
  TASK-1654 least-privilege fix. oxydraw currently mints tokens scoped to *every repository
  in the App installation*.
- **ops lacks the App-bot attribution** oxydraw has. ops still writes `github-actions[bot]`;
  oxydraw resolves `${APP_SLUG}[bot]` and looks up the bot's numeric id for the noreply email.
- **ops's `publish-homebrew.yml` still commits as `"axo bot"`**; oxydraw uses the App bot.

This also produced a documentation bug: `ops/docs/verified-bump/README.md` claims the
attribution change is "already applied in `bump.yml`, `publish-deb.yml`,
`publish-homebrew.yml`". True of oxydraw, false of ops — the spec was written against the
other repo's state. Two copies, two truths.

**Consolidating is not cleanup. It is the fix for a class of bug that has already bitten
three times.**

### 2.2 event0 has no CI at all

`event0` has **no `.github` directory**. No fmt, check, clippy, build, test, deny; no bump, no
release, no publish. It is a 26-crate workspace with encryption and key-custody crates and
zero automated verification. It is the single largest beneficiary of this work, and it is
cheapest to onboard *after* the shared workflows exist rather than by copying two other repos'
drifted YAML into a third place.

### 2.3 Lint/dependency config is diverging too

| File | ops | oxydraw | event0 |
|---|---|---|---|
| `deny.toml` | ✅ | — | ✅ |
| `clippy.toml` | ✅ | — | — |
| `.clippy.toml` | — | — | ✅ |
| `.rustfmt.toml` | — | — | ✅ |
| `.tool-versions` | — | — | ✅ |

Note ops uses `clippy.toml` and event0 uses `.clippy.toml` — same intent, two spellings, no
shared content.

---

## 3. Scope — what goes in `forge`

Split by granularity. Composite actions and reusable workflows are **not** interchangeable:
a composite action is a *step* that runs inside the caller's job; a reusable workflow is a
whole *job* with its own runner and `secrets: inherit`.

### 3.1 Composite actions (step-level)

| Action | Purpose |
|---|---|
| `signed-commit` | Create a GitHub-**signed** commit via GraphQL `createCommitOnBranch`. See §6. |
| `mint-app-token` | Wrap `actions/create-github-app-token` with `client-id` and mandatory `repositories:` scoping, so the least-privilege fix cannot drift again. |
| `app-bot-identity` | Resolve `${APP_SLUG}[bot]` + numeric id and configure `git user.name`/`user.email`. |

### 3.2 Reusable workflows (job-level)

| Workflow | Consumers |
|---|---|
| `rust-ci` | ops, oxydraw (backend), event0 |
| `bump` | ops, oxydraw, event0 |
| `publish-homebrew` | ops, oxydraw |
| `publish-deb` | oxydraw, my-cloud |
| `publish-crates` | **no real consumer yet** — built and exercised against the testbed only; see §5 |

### 3.3 Shared configuration

`deny.toml`, `clippy.toml`, `rustfmt.toml` as a canonical baseline. Consumers either vendor
them via a sync job or fetch them in CI. Standardise on the **non-dotted** spellings
(`clippy.toml`, `rustfmt.toml`) since that is what ops already uses and what Cargo documents.

### 3.4 Templates

Issue/PR templates, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CONTRIBUTING.md`. oxydraw already
has all four; ops and event0 have none.

---

## 4. Repository layout

```
forge/
  actions/                          # nothing at root; each action is a subdirectory
    signed-commit/action.yml
    mint-app-token/action.yml
    app-bot-identity/action.yml
  .github/workflows/
    rust-ci.yml                     # on: workflow_call
    bump.yml
    publish-crates.yml
    publish-homebrew.yml
    publish-deb.yml
    test-self.yml                   # forge's own CI: lint the YAML, exercise the actions
  config/
    deny.toml
    clippy.toml
    rustfmt.toml
  templates/
    SECURITY.md
    CONTRIBUTING.md
    .github/ISSUE_TEMPLATE/
  plans/                            # design docs; this file
  docs/
    consuming.md
    versioning.md
```

Current on-disk state (not yet a git repository):

```
forge/
  plans/PLAN.md
  scripts/signed-commit.sh          # -> becomes actions/signed-commit/ in phase 3
```

**Public repository.** Action definitions contain no secrets, and public sidesteps the
cross-repository access configuration that private action sharing otherwise needs.

Managed in Terraform alongside the others: add `terraform/github/forge.tf` to `my-cloud`,
mirroring the existing repo resources (ruleset, App credentials, `allow_rebase_merge = false`).

---

## 5. crates.io publishing — built now, adopted later

**Decision (2026-08-09): do not activate crates.io publishing for `ops`, `oxydraw` or `event0`
in this round.** Build the `publish-crates` workflow so the capability exists and is proven,
but ship it with **no real consumer** — the testbed (§7) is its only caller until publishing a
given crate becomes a deliberate, separate decision.

This keeps the one irreversible step (§9.5) behind an explicit future choice, while ensuring
the workflow is not written from scratch under time pressure on the day it is wanted.

The rest of this section is therefore **preparatory**. It records what each repo would need, so
the workflow is designed against the real constraints rather than a guess — which is the whole
point of building it before it is needed.

### 5.1 Current state: nothing is publishable

| Repo | Cargo.toml files with `publish = false` |
|---|---|
| `ops` | 26 of 28 |
| `event0` | **27 of 27** |
| `oxydraw` | 4 of 5 |

event0 currently cannot publish a single crate. All three also use bare path dependencies
(`oxydraw-core = { path = "crates/core" }`), which crates.io rejects — a published crate's
path dependency **must** also carry a `version`.

### 5.2 Per-repo prerequisites (not shareable)

For every crate intended to be public:

1. Remove `publish = false` — and deliberately **keep** it on crates that should stay private
   (internal test helpers, `testkit`, extension crates). This is a decision per crate, not a
   sweep.
2. Add `version` alongside every internal `path` dependency.
3. Ensure `license`, `description`, `repository`, `readme` and ideally `keywords` /
   `categories` resolve on each publishable crate. All three workspaces already set most of
   these via `[workspace.package]`, so this is mostly inheritance wiring.
4. Decide the public API surface. event0's 26 crates almost certainly should not all be
   published; publishing is a permanent commitment (crates.io forbids deletion, only yanking).

### 5.3 Ordering

A workspace must publish in dependency order, and crates.io needs each dependency to be live
before its dependents. Options:

- **`cargo publish --workspace`** — handles ordering itself. Requires a recent toolchain; CI
  runs latest stable so this is fine, independent of each crate's `rust-version` MSRV
  (`ops` 1.80, `oxydraw` 1.85).
- **`cargo-release` / `release-plz`** — heavier, and overlaps significantly with cocogitto,
  which already owns version bumping here. Avoid; do not run two tools that both want to own
  the version number.

Prefer `cargo publish --workspace`, invoked from the shared `publish-crates` workflow, keeping
cocogitto as the single source of version truth.

### 5.4 Authentication — prefer Trusted Publishing

crates.io supports **Trusted Publishing** via GitHub Actions OIDC: the workflow exchanges a
short-lived OIDC token for a scoped publish token, with no long-lived secret stored anywhere.

This matches the direction already taken in these repos — the `HOMEBREW_TAP_TOKEN` PAT was
deliberately retired in favour of App-minted short-lived tokens. A static
`CARGO_REGISTRY_TOKEN` would reintroduce exactly the thing that was removed.

**Verify current crates.io Trusted Publishing setup steps before relying on this**, and fall
back to `CARGO_REGISTRY_TOKEN` as a stored secret only if trusted publishing cannot be
configured. Setup is per-crate on crates.io and cannot be Terraform-managed today.

### 5.5 Where it hooks in

crates.io publishing belongs on the **tag**, next to cargo-dist's binary release — not in the
bump job. Sequence per release:

```
bump (signed commit + tag)
  └─> release.yml (cargo-dist: binaries, installers, GitHub release)
  └─> publish-crates.yml (cargo publish --workspace)
```

Run them in parallel off the tag. A crates.io failure should not block the binary release, and
vice versa; both are idempotent-ish and separately re-runnable.

---

## 6. Verified bump commits

Resolved during investigation on 2026-08-09, and it **corrects the existing spec** at
`ops/docs/verified-bump/README.md`.

That spec's Option A is built on the REST Git Data API (`git/blobs` → `git/trees` →
`git/commits`). **That path produces unsigned commits.** Probed directly against `rsvalerio/ops`:

| Method | Result |
|---|---|
| `git push` over HTTPS/SSH | unsigned unless the pusher signs locally |
| REST Git Data API | ❌ `verified=false, reason=unsigned` |
| REST Contents API | ❌ `verified=false, reason=unsigned` |
| **GraphQL `createCommitOnBranch`** | ✅ `verified=true, reason=valid` |

GraphQL sets `committer` to `GitHub / web-flow` (the signing identity) and takes `author` from
the calling token — so with an App installation token the commit is **authored by
`my-cloud-ci[bot]` and signed by GitHub**, which is exactly the spec's stated goal, in one API
call rather than four.

A working implementation exists and was validated end-to-end against real branches (signed;
headline/body preserved; add, modify and delete all applied). It now lives at
`forge/scripts/signed-commit.sh` — moved out of `ops`, where it was never committed — and
should become `forge/actions/signed-commit/`, wrapped in an `action.yml` so consumers `uses:`
it rather than copying the script.

Two constraints to carry over:

- It diffs **locally**, so the base must be a local commit. In the bump flow base is `HEAD^`,
  which satisfies this; document it for any other reuse.
- `createCommitOnBranch` only creates commits. The `vX.Y.Z` tag remains a `POST /git/refs`
  pointing at the new signed commit. That still triggers `release.yml`; the tag ref itself is
  unsigned, which is normal and invisible in the UI.

Fold in `--skip-ci` while touching this: because the message becomes ours to construct, the
`[skip ci]` marker can be applied directly, closing **TASK-1659** (cocogitto's `skip_ci`
config only defines the string; it is applied only when `cog bump` is passed `--skip-ci`,
which no current workflow does — so every bump commit re-runs the full CI + Bump cycle).

---

## 7. Acceptance testing — the `forge-testbed` repo

A dedicated repository that **consumes every capability `forge` offers**, so each one is
exercised end-to-end before a real project adopts it. It is simultaneously the acceptance-test
suite, the integration environment, and living documentation of the consumption pattern.

Suggested name: **`forge-testbed`**. (`forge-canary` if the pre-flight role matters more than
the demo role; `forge-demo` reads as sample code rather than as a gate.)

### 7.1 Shape

A **real but minimal multi-crate Rust workspace** — deliberately multi-crate so it exercises
workspace publish ordering and inter-crate `path` + `version` dependencies, which a
single-crate fixture would silently skip.

```
forge-testbed/
  Cargo.toml              # workspace: crates/*
  crates/
    testbed-core/         # no internal deps
    testbed-util/         # depends on core  -> exercises publish ordering
    testbed-cli/          # binary           -> exercises cargo-dist, homebrew, deb
  cog.toml
  dist-workspace.toml
  .github/workflows/      # thin wrappers, one per forge capability
```

### 7.2 Capability matrix

| Capability | How the testbed proves it | Real side effect? |
|---|---|---|
| `rust-ci` | fmt/check/clippy/build/test/deny on a tiny workspace | none |
| `signed-commit` | assert the resulting commit is `verified=true` | commit in testbed only |
| `mint-app-token` | assert token scope is this repo only | none |
| `app-bot-identity` | assert author is `[bot]`, not a human | none |
| `bump` | conventional commit → version, tag, CHANGELOG | real tag in testbed |
| `publish-homebrew` | formula rendered and pushed | **needs a test tap** |
| `publish-deb` | `.deb` built and uploaded | **needs a test apt path** |
| `publish-crates` | `cargo publish --workspace --dry-run` | **must stay dry-run** |

### 7.3 This changes the shared workflow interfaces

The three rows above with real side effects are the reason to design the testbed *now* rather
than after the workflows are written. Each publishing workflow needs, from day one:

- a **`dry_run`** input, and
- a **target override** (`tap_repository`, `apt_repository`, registry) rather than a hardcoded
  destination.

Without those, the testbed cannot exercise publishing without polluting the real
`rsvalerio/homebrew-tap` and `rsvalerio/apt`. And `publish-crates` must **never** do a real
publish from the testbed: crates.io publication is irreversible, so the testbed asserts on
`--dry-run` only, permanently.

Hardcoded destinations are the single most likely design mistake here, and the cheapest to
avoid before the first workflow is written.

### 7.4 It floats on `main` — deliberately the inverse of real consumers

Real repos pin a tag (§8). The testbed tracks `forge`'s `main`, so breakage surfaces there
*before* a `v1` tag is cut. That inversion is the point: the testbed is what makes tag-pinning
safe for everyone else.

Promotion gate: **green testbed on `main` → tag `v1.x` → real consumers pick it up.**

---

## 8. Versioning and consumption

- Consumers pin a **tag**, never `main`. A shared repo means one bad commit can break every
  release pipeline simultaneously.
- Publish `v1` as a moving major tag; SHA-pin where the existing repos already SHA-pin, for
  consistency with their current posture.
- `forge` gets its own CI (`test-self.yml`) that lints the workflow YAML and exercises each
  composite action against a scratch branch. The `signed-commit` probe method in §6 is a
  ready-made integration test.

---

## 9. Known gotchas

1. **cargo-dist's `publish-jobs = ["./publish-homebrew"]` resolves a *local* workflow path.**
   `publish-homebrew.yml` must therefore stay in each consumer repo — but it can shrink to a
   thin wrapper that `uses:` the shared reusable workflow with `secrets: inherit`. This
   preserves the "survives `dist generate`" property already documented in
   `ops/docs/releasing.md`.
2. **Migrate fixes *as* you extract, not after.** The shared `bump` must be ops's
   least-privilege `repositories:` scoping **plus** oxydraw's bot attribution. Extracting
   either repo's copy verbatim freezes that repo's regression into the shared version.
3. **`secrets: inherit`** passes everything the caller holds. Prefer explicit `secrets:` blocks
   on workflows that only need `GH_APP_PRIVATE_KEY`.
4. **Reusable workflow nesting is capped** (4 levels). The wrapper-calls-shared pattern in
   gotcha 1 uses two; fine, but do not stack further.
5. **crates.io publication is irreversible.** Yanking hides a version; it never deletes it, and
   the crate *name* is claimed permanently. Decide the public surface before the first publish.
6. **event0 has no remote CI history**, so its first `rust-ci` run will likely surface a backlog
   of pre-existing lint/test failures. Budget for that; do not treat it as a migration bug.
7. **Acceptance tests must not reach real distribution channels.** The testbed exercises
   publishing paths, so every publish workflow needs `dry_run` + target override (§7.3). A
   hardcoded `rsvalerio/homebrew-tap` or `rsvalerio/apt` makes the capability untestable
   without polluting production, and a real crates.io publish from a fixture is permanent.

---

## 10. Phasing

Ordered by risk-adjusted value — each phase is independently useful and independently
revertible.

| # | Phase | Why here |
|---|---|---|
| 1 | Create `forge`, Terraform resource, `test-self.yml` | Foundation; no consumers at risk |
| 2 | Create `forge-testbed` skeleton (§7) | Every later phase is validated here first; build the harness before the things it tests |
| 3 | `signed-commit` action + testbed assertion | Net-new, nothing to migrate, unblocks verified bumps |
| 4 | `bump` reusable workflow (with §6 + `--skip-ci` + both drift fixes) | Highest-value consolidation; fixes a live security gap in oxydraw |
| 5 | `publish-homebrew` via thin wrappers, `dry_run` + tap override | Highest overlap (~90%), lowest risk |
| 6 | `rust-ci`, adopt in testbed → ops → oxydraw → **event0 last** | event0 will surface real failures; adopt once proven elsewhere |
| 7 | Shared `deny.toml` / `clippy.toml` / `rustfmt.toml` | Cheap once CI is centralised |
| 8 | `publish-crates` workflow, **testbed-only, `--dry-run`** | Capability exists and is proven; no real consumer (§5) |
| — | *(deferred)* crates.io prerequisites per repo (§5.2) + Trusted Publishing | Explicitly out of scope this round; irreversible, so it waits for a deliberate decision |

---

## 11. Open questions

1. **Which crates go public?** Especially event0's 26. Needs a deliberate pass, not a sweep.
2. **Are the crate names available on crates.io?** `ops`, `event0`, `oxydraw` are short and
   plausibly taken. Check before committing to names — this may force a rename or a prefix.
3. **Does `my-cloud` join the CI consolidation**, or only `publish-deb`? It is Terraform and
   packaging rather than Rust, so `rust-ci` does not apply.
4. **Does oxydraw's frontend need shared Node CI**, or stay repo-local?
5. **`.tool-versions` / mise vs `rust-toolchain.toml`** — only event0 pins a toolchain today.
   Worth standardising as part of phase 6.
