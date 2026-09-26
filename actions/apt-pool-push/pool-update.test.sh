#!/usr/bin/env bash
# Exercises pool-update.sh against a throwaway bare repository standing in for the apt
# repo: multi-file commits, idempotency, dry-run, and retention. Needs git and dpkg-deb.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="${here}/pool-update.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work"

fail() { echo "FAIL: $*" >&2; exit 1; }
commits() { git -C remote.git rev-list --count HEAD; }
pool() { find apt/pool -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort | tr '\n' ' '; }

mkdeb() { # package version arch
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/DEBIAN"
  printf 'Package: %s\nVersion: %s\nArchitecture: %s\nMaintainer: t <t@t>\nDescription: t\n' \
    "$1" "$2" "$3" >"$d/DEBIAN/control"
  chmod 0755 "$d"
  dpkg-deb --root-owner-group --build "$d" "debs/$1_$2_$3.deb" >/dev/null
  rm -rf "$d"
}

mkdir debs
git init -q --bare remote.git
git clone -q remote.git apt 2>/dev/null
git -C apt config user.name test
git -C apt config user.email test@example.invalid
mkdir apt/pool
touch apt/pool/.keep
git -C apt add -A
git -C apt commit -q -m seed
git -C apt push -q origin HEAD 2>/dev/null

export POOL=pool APT_DIR=apt PACKAGE=my-haproxy
run() { "$script" >/dev/null 2>&1; }

echo "one commit for several .debs"
mkdeb my-haproxy 1.0.0 amd64
mkdeb my-haproxy 1.0.0 arm64
VERSION=1.0.0 DEBS=$'  debs/my-haproxy_1.0.0_amd64.deb\n  debs/my-haproxy_1.0.0_arm64.deb\n' run
[ "$(commits)" = 2 ] || fail "expected one new commit, got $(($(commits) - 1))"

echo "identical rerun is a no-op"
VERSION=1.0.0 DEBS=$'debs/my-haproxy_1.0.0_amd64.deb\ndebs/my-haproxy_1.0.0_arm64.deb' run \
  || fail "rerun exited non-zero"
[ "$(commits)" = 2 ] || fail "rerun created a commit"

echo "dry-run stages but does not commit"
mkdeb my-haproxy 1.1.0 amd64
VERSION=1.1.0 DRY_RUN=true DEBS=debs/my-haproxy_1.1.0_amd64.deb run
[ "$(commits)" = 2 ] || fail "dry-run pushed a commit"
git -C apt diff --cached --quiet && fail "dry-run staged nothing"
git -C apt reset -q --hard

echo "a missing .deb fails"
VERSION=9 DEBS=debs/nope.deb run && fail "missing .deb did not fail"

echo "retention prunes per package+arch, and never across name prefixes"
for v in 1.1.0 1.2.0 1.2.0~rc1 1.10.0; do mkdeb my-haproxy "$v" amd64; done
for v in 1.0.0 1.1.0; do mkdeb my-haproxy-sites "$v" amd64; done
cp debs/my-haproxy_1.1.0_amd64.deb debs/my-haproxy_1.2.0~rc1_amd64.deb \
  debs/my-haproxy_1.2.0_amd64.deb debs/my-haproxy-sites_*.deb apt/pool/
git -C apt add -A
git -C apt commit -q -m "more seed"
git -C apt push -q origin HEAD 2>/dev/null

KEEP_VERSIONS=2 VERSION=1.10.0 DEBS=debs/my-haproxy_1.10.0_amd64.deb run
expected=".keep my-haproxy-sites_1.0.0_amd64.deb my-haproxy-sites_1.1.0_amd64.deb my-haproxy_1.0.0_arm64.deb my-haproxy_1.10.0_amd64.deb my-haproxy_1.2.0_amd64.deb "
[ "$(pool)" = "$expected" ] || fail "pool after retention: $(pool)"
git -C remote.git log -1 --format=%B | grep -q 'my-haproxy_1.1.0_amd64.deb' \
  || fail "commit message does not list the pruned files"

echo "a backfill older than the newest N changes nothing"
before="$(commits)"
KEEP_VERSIONS=2 VERSION=1.1.0 DEBS=debs/my-haproxy_1.1.0_amd64.deb run \
  || fail "backfill exited non-zero"
[ "$(commits)" = "$before" ] || fail "backfill created a commit"

echo "keep-versions must be numeric"
KEEP_VERSIONS=x VERSION=1 DEBS=debs/my-haproxy_1.10.0_amd64.deb run \
  && fail "non-numeric keep-versions accepted"

echo "a file that is not a .deb is rejected"
echo "not a package" >debs/fake_1.0_amd64.deb
VERSION=1 DEBS=debs/fake_1.0_amd64.deb run && fail "invalid .deb accepted"
[ -e apt/pool/fake_1.0_amd64.deb ] && fail "invalid .deb reached the pool"

echo "an exported GIT_DIR does not redirect the pool commit"
mkdeb gitdir-probe 1.0 all
before="$(commits)"
GIT_DIR="$work/nowhere" VERSION=1.0 DEBS=debs/gitdir-probe_1.0_all.deb run \
  || fail "run with GIT_DIR exported failed"
[ "$(commits)" = $((before + 1)) ] || fail "GIT_DIR run did not land in the apt repo"

echo "a push rejected by a concurrent publisher is restaged and retried"
git clone -q remote.git other 2>/dev/null
git -C other config user.name other
git -C other config user.email other@example.invalid
mkdeb other 1.0 all
cp debs/other_1.0_all.deb other/pool/
git -C other add -A
git -C other commit -q -m "other: add 1.0"
git -C other push -q origin HEAD 2>/dev/null
# apt/ has not fetched, so its first push is rejected.
mkdeb my-haproxy 3.0.0 amd64
before="$(commits)"
KEEP_VERSIONS=2 VERSION=3.0.0 DEBS=debs/my-haproxy_3.0.0_amd64.deb run || fail "retry did not recover"
[ "$(commits)" = $((before + 1)) ] || fail "expected exactly one new commit after the retry"
tree="$(git -C remote.git ls-tree --name-only HEAD pool/)"
grep -q 'pool/other_1.0_all.deb' <<<"$tree" || fail "retry dropped the concurrent publisher's file"
grep -q 'pool/my-haproxy_3.0.0_amd64.deb' <<<"$tree" || fail "retry did not publish"
grep -q 'pool/my-haproxy_1.2.0_amd64.deb' <<<"$tree" && fail "retention not reapplied on retry"

echo "ok"
