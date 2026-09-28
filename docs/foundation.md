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

forge is not a source of defaults. It ships the CI that runs the gates
([rust-ci.yml](../.github/workflows/rust-ci.yml)) and the action that installs a pinned
ops ([setup-ops](consuming.md#setup-ops)). forge's own `config/*.toml` files are mirrors of
the ops templates, kept only for repos that still vendor them (see
[Transition](#transition)).

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
| dbsec replaces `forge-sync` with `ops init --rust --check` and adopts `verify`/`qa` | dbsec | forge TASK-0046 |
| event0 and oxydraw adopt the foundation files and gates | event0, oxydraw | forge TASK-0047 |
| forge deletes its `config/*.toml` mirrors once no repo vendors them | forge | forge TASK-0048 |

Already done: the ops built-ins for check-only fmt, `--locked` and a CI-safe `deps`
(ops TASK-2322, TASK-2323, TASK-2324), the embedded templates and `ops init --rust`
(ops TASK-2330), and the ai skills' templates derived from ops (ai TASK-0008).
