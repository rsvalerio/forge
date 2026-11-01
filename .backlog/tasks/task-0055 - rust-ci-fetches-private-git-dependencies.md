---
id: TASK-0055
title: 'rust-ci fetches private git dependencies'
status: To Do
assignee: []
created_date: '2026-10-25 16:13'
labels:
  - ci
  - security
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**File**: `.github/workflows/rust-ci.yml`, a new composite action under `actions/`, `docs/consuming.md`, `.github/workflows/test-self.yml`

**What**: a workspace whose `Cargo.toml` has a git dependency on a private repository cannot use `rust-ci.yml`. The runner has no credential that can read that repository, and the workflow takes no secret to give it one, so every job (`verify`, `qa`, `msrv`) fails at the dependency fetch before any gate runs. Building against private repositories is a basic need for a Rust forge, not an edge case: event0 and dbsec are private, and anything that depends on them inherits the problem.

**Shape to start from** (open to change):
- A composite action, e.g. `actions/private-git-deps`, that mints a read-only App token through `mint-app-token` (scoped with `repositories:` to exactly the dependency repos, `contents: read`), writes `url.<https-with-token>.insteadOf` for both the `ssh://git@github.com/<owner>/` and `git@github.com:<owner>/` forms, and sets `CARGO_NET_GIT_FETCH_WITH_CLI=true` so cargo uses git and so the rewrite applies whatever the consumer's `.cargo/config.toml` says.
- `rust-ci.yml` gains an optional input listing the private repositories (`owner/name`) and optional secrets (`GH_APP_PRIVATE_KEY`, client id as a var or input). With neither set, nothing changes for existing callers.
- Every compiling job runs the action after checkout and before `mise install`/the gates.

**Questions the task has to settle**:
- Cross-owner: `mint-app-token` takes a single `owner` (default `rsvalerio`), but the dependencies live under `valycorp`. An App installation token covers one owner, so either one token per owner or a documented constraint.
- Token exposure: the rewrite puts the token in global git config for the rest of the job. Decide whether that is acceptable (short-lived, read-only, scoped) or whether to use a credential helper, and make sure no later step (cache save, artifact upload, `ops qa`'s trivy) can persist it.
- The cache: `Swatinem/rust-cache` will save `~/.cargo/git` with private sources in it. The Actions cache is scoped to the repository, so this is probably fine, but say so in the docs.
- Deploy-key (SSH) alternative: document why the App token was chosen, or support both.

**Why it matters**: today a private repo's only options are no CI or a hand-rolled `ci.yml` that copies forge's jobs, which is the drift forge exists to prevent (README, "Why"). First consumer: `valycorp/valysec-spike`, which depends on event0 (`branch = "main"`) and dbsec-core over `ssh://`.

**Origin**: asked while adding CI to valysec-spike, 2026-10-25.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A caller of rust-ci.yml whose workspace has a git dependency on a private repository passes `verify`, `qa` and (when on) `msrv`, given only a repository list and the App secret
- [ ] #2 Both `ssh://git@github.com/...` and `https://github.com/...` dependency URLs resolve, with and without `net.git-fetch-with-cli` in the consumer's cargo config
- [ ] #3 The token is minted with `repositories:` limited to the listed dependencies and `contents: read`; dependencies under more than one owner either work or fail with a message that names the constraint
- [ ] #4 Existing callers that pass no new input or secret see no change in behaviour
- [ ] #5 test-self exercises the path against a private fixture repository and fails if the fetch does
- [ ] #6 docs/consuming.md has a rust-ci section on private dependencies: the input, the secret, the App's required installation and permissions, and what is cached
<!-- AC:END -->
