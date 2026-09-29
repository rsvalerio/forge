# Rust foundation

Every Rust repo (ops, dbsec, event0, oxydraw, forge-testbed) starts from the same
foundation: one set of gate commands with the same meaning everywhere, and one set of
shared config files. This page records where each part lives and how a repo adopts it and
keeps it current. The decisions were made on 2026-09-28 (forge TASK-0025).

Before this, each repo declared its own gates and carried its own config. event0
re-declared nine ops built-ins only to add `--locked`. The gate that runs "what CI runs"
was `run-before-push` in ops, `qa` in event0 and `pre-release` in dbsec, and each ran
something different. forge's `config/*` reached dbsec through a dbsec-only `forge-sync`
script, and the ai skills wrote their own clippy, nextest and `.ops.toml` templates. The
copies drifted.

## Where the defaults live

**In ops.** The ops binary is the single source for both the gates and the config files:

| Part | Source | How a repo gets updates |
|---|---|---|
| Gate commands (`verify`, `qa`, their CI forms) | ops's Rust stack built-ins | Upgrade ops |
| `--locked` on cargo commands | `[cargo] locked = true` in `.ops.toml`, or `OPS__CARGO__LOCKED=true` | Upgrade ops |
| `clippy.toml`, `deny.toml`, `rustfmt.toml`, `.config/nextest.toml`, the `[workspace.lints]` policy | Templates embedded in ops (`extensions-rust/foundation/templates/` in the ops repo) | Upgrade ops, then `ops init --rust --check` |

A repo's `.ops.toml` holds **only its exceptions**: extra commands, `[extend.<name>]`
additions and `[foundation.waivers]`. It does not re-declare a built-in to change a flag.
Updates ship with ops releases, so there are no vendored copies to sync.

forge is not a source of gate or config defaults. It ships the CI that runs the gates
([rust-ci.yml](../.github/workflows/rust-ci.yml)), the action that installs a pinned
ops ([setup-ops](consuming.md#setup-ops)), and the tool versions its workflows install
([Pipeline tools](#pipeline-tools)). It carries no copy of the config files: its old
`config/*.toml` mirrors of the ops templates were deleted (forge TASK-0048).

## The gate contract

Every Rust repo exposes two gates, and they mean the same thing in every repo:

| Gate | What it runs | Who runs it |
|---|---|---|
| `verify` | The fast static gate: fmt, clippy, build, doc (plus the whitespace, JSON and YAML checks) | The pre-commit hook, code-review wave runners, developers before a push |
| `qa` | The full gate: deps, tests (including doctests) and security | Developers before a release, CI |

**CI runs both, in check-only mode.** `verify` rewrites files (fmt, whitespace fixers), so
CI runs `ops verify-check`, which swaps each rewriter for its check and writes nothing. CI
also sets `OPS__CARGO__LOCKED=true`, so every cargo command builds against the committed
`Cargo.lock`. forge's `rust-ci.yml` does exactly this with `engine: ops`, which is opt-in
on v1; its default engine still runs raw cargo steps until the next major flips it (see
[consuming.md](consuming.md#engine-ops)).

`ops explain verify` and `ops explain qa` print exactly what each gate runs in a given repo.
A repo that needs more adds to a gate with `[extend.verify]` or `[extend.qa]` rather than
by renaming it or declaring a gate of its own.

## Shared config files

ops embeds the templates, writes them into a repo and reports drift from them. It needs
ops 0.74.0 or later.

```bash
ops init --rust           # write the foundation files that are missing
ops init --rust --check   # compare them with this ops version's templates; exit 1 on drift
```

The check is semantic: every key a template sets must keep its value, and keys a repo adds
(an `advisories.ignore` entry, a tighter threshold, an extra lint) are its own. A deliberate
divergence is recorded with its reason under `[foundation.waivers]` in `.ops.toml`.

What the files carry, and the full check and waiver rules, are documented in ops's
[docs/foundation.md](https://github.com/rsvalerio/ops/blob/main/docs/foundation.md).
Two points matter for adoption:

- **`msrv` is the repo's own value.** `ops init --rust` sets it in `clippy.toml` from the
  root's `rust-version`. It is not part of the baseline.
- **Non-dotted file names.** A repo with `.clippy.toml` or `.rustfmt.toml` renames them on
  adoption. Each tool reads only one spelling, and keeping both is how two copies silently
  disagree.

## Pipeline tools

Decided by the owner on 2026-09-28 (forge TASK-0050): mise is the one install method for
the tools a repo's gates and pipelines run, identical on CI runners and laptops. A repo's
`mise.toml` pins every such tool. Developers run `mise install`; forge's workflows install
through [setup-tools](consuming.md#setup-tools), which reads the same kind of file. The
Rust toolchain is the exception: it stays with `rust-toolchain.toml` and rustup, and is not
duplicated in `mise.toml`.

| Tool | Needed by | `mise.toml` entry (forge's pin) |
|---|---|---|
| ops | every gate; rust-ci `engine: ops` and MSRV jobs | `ops = "0.75.0"`, with `[tool_alias] ops = "github:rsvalerio/ops"` |
| cargo-deny | `ops deps`; rust-ci's deps jobs (both engines) | `cargo-deny = "0.20.2"` (aqua) |
| cargo-machete | `ops deps` (a warning: it is heuristic); rust-ci `ops deps` | `cargo-machete = "0.9.2"`, with `[tool_alias] cargo-machete = "github:bnjbvr/cargo-machete"` |
| cargo-nextest | `ops next`; rust-ci `ops test` | `cargo-nextest = { version = "0.9.146", version_prefix = "cargo-nextest-" }`, with `[tool_alias] cargo-nextest = "github:nextest-rs/nextest"` |
| cargo-edit (`cargo upgrade`, `cargo set-version`) | `ops deps` without `--check`; bump.yml | `cargo-edit = "0.13.13"`, with `[tool_alias] cargo-edit = "cargo:cargo-edit"` (compiled: no release binaries) |
| cargo-llvm-cov | `ops coverage` | `"aqua:taiki-e/cargo-llvm-cov" = "<version>"`; no forge workflow runs it, so forge pins none |
| trivy | `ops sec`; rust-ci `ops sec` | `trivy = "0.70.0"` (aqua) |
| cocogitto (`cog`) | bump.yml | `cocogitto = "7.0.0"` (aqua) |
| cargo-dist (`dist`) | a repo's dist-generated release workflow | `cargo-dist = "<version>"` (aqua), equal to `cargo-dist-version` in `dist-workspace.toml`, which is what dist's own workflow installs; forge pins none |
| sccache | rust-ci's compile cache | `sccache = "0.18.0"` (aqua); on CI installed by `mozilla-actions/sccache-action` at this pin (below) |
| gh, jq | bump, publish-\*, apt-pool-push scripts | preinstalled on GitHub runners; `gh` and `jq` (aqua) for laptops |
| actionlint, shellcheck, yq | forge's own `ops verify` | `actionlint = "1.7.12"`, `shellcheck = "0.11.0"`, `yq = "4.53.6"` (aqua); forge only |
| Rust toolchain, rustfmt, clippy | every cargo gate | not in `mise.toml`: `rust-toolchain.toml` and rustup locally, `setup-rust-toolchain` on CI |
| dpkg-deb, tar, sha256sum or shasum, curl | publish-deb\*, setup-ops | the runner image; out of scope |

forge's [`mise.toml`](../mise.toml) is the authority for the versions in the right-hand
column: bump them there, and copy the entries a repo needs into its own `mise.toml`.

### How the pins reach CI

The rollout keeps every consumer on `@v1` working. Four points were open when the decision
was made. Each took the option that changes nothing for an unmodified caller:

1. **Whose `mise.toml` a reusable workflow reads.** forge's, at `forge-ref`, as it has since
   forge's workflows moved to setup-tools. That is the documented default. A consumer's own
   `mise.toml` is not read on `v1`: a caller that has one would silently get other tool
   versions, and one that has none would gain nothing. Until an opt-in to the caller's pins
   exists (forge TASK-0052), a repo keeps its laptop pins equal to forge's by copying the
   entries above.
2. **setup-ops stays.** It is a published `v1` action, so retiring it would break its
   callers, and setup-tools installs ops through it: an exact version, the release's
   `.sha256` checked before extraction, `ops --version` asserted. Locally, `mise install`
   fetches the same pin through `github:rsvalerio/ops`. Whether setup-ops becomes an
   internal detail of setup-tools is for the next major.
3. **ops scaffolds `mise.toml`.** ops's foundation templates should ship a `mise.toml` with
   the Rust gate tools, so `ops init --rust` writes it and `ops init --rust --check` reports
   a pin that drifted. That is ops's change to make; see [Transition](#transition).
4. **`github:` entries and mise's own version.** An entry mise's registry does not carry
   needs a prebuilt asset for every runner a workflow uses: Linux and macOS, X64 and ARM64.
   Checked on 2026-09-29: ops publishes all four dist targets; cargo-nextest publishes
   x86_64 and aarch64 Linux and a universal macOS build; cargo-machete publishes x86_64
   Linux (musl), aarch64 Linux and both macOS targets. cargo-edit publishes none and
   compiles through `cargo:`. Check a new `github:` entry the same way before adding it, and
   prefer an `aqua:` entry where one exists (`aqua:taiki-e/cargo-llvm-cov`): mise verifies
   an aqua download against the checksum the aqua registry records for it, where it records
   one. The mise binary CI runs is pinned by setup-tools
   (`version:` on `jdx/mise-action`) and bumped with `mise.toml` (README, "Layout").

Two tools are pinned in `mise.toml` but installed on CI by something else. sccache comes
from `mozilla-actions/sccache-action`, which also hands sccache the Actions cache
credentials that only a JavaScript action can read; setup-rust passes it the `mise.toml`
pin. rust-ci's frozen `engine: cargo` jobs still take the action's default, the latest
sccache release, until the default engine flips. The Rust toolchain comes from
`setup-rust-toolchain` on CI and rustup locally, both reading the repo's toolchain.

## Adopting the foundation

In a Rust repo, with ops 0.74.0 or later:

1. Run `ops init --rust`. It writes the missing files and the lint policy. Existing files
   are kept and reported as `kept`.
2. Run `ops init --rust --check` and resolve each drift it reports: take the template's
   value, or record a waiver with its reason.
3. Remove every `.ops.toml` command that only re-declares a built-in to add a flag. Use
   `[cargo] locked = true` or `[extend.<name>]` instead.
4. Make `verify` and `qa` the repo's gates. A gate of the repo's own (dbsec's
   `pre-release`) becomes an `[extend.*]` of one of them, or is removed. Git hook commands
   (ops's `run-before-commit` and `run-before-push`) compose `verify` and `qa` rather than
   listing checks of their own.
5. Call forge's `rust-ci.yml` with `engine: ops` for CI, so CI runs the same gates.

## Updating

Upgrade ops, then run `ops init --rust --check`. A template change in the new release
shows up as drift. Take it, or waive it with a reason. A waiver that no longer matches any
drift is reported as `unused`, so it can be deleted before it hides something.

## Transition

The decisions are made. These pieces of the rollout are still open, each tracked in a
backlog:

| Change | Repo | Tracked in |
|---|---|---|
| CI runs `ops` gates instead of raw cargo | forge | forge TASK-0026 |
| ops's own CI moves onto forge's `rust-ci.yml` and `setup-ops` | ops | ops TASK-2329 |
| event0 drops its re-declared cargo built-ins for `[cargo] locked = true` | event0 | ops TASK-2339 |
| dbsec replaces `forge-sync` with `ops init --rust --check` and adopts `verify`/`qa`. Until it does, forge's `v1` must not move past the deletion of `config/*.toml`: dbsec's `forge-sync` reads them at `v1` | dbsec | dbsec TASK-1131 (was forge TASK-0046) |
| event0 and oxydraw adopt the foundation files and gates | event0, oxydraw | forge TASK-0047 |
| `ops init --rust` scaffolds `mise.toml` with the gate tools and `--check` reports pin drift | ops | to be filed in ops (forge TASK-0050) |
| rust-ci and bump install at the caller's own `mise.toml` pins, opt-in on `v1` | forge | forge TASK-0052 |

Already done: the ops built-ins for check-only fmt, `--locked` and a CI-safe `deps`
(ops TASK-2322, TASK-2323, TASK-2324), the embedded templates and `ops init --rust`
(ops TASK-2330), the ai skills' templates derived from ops (ai TASK-0008), and the
deletion of forge's `config/*.toml` mirrors (forge TASK-0048).
