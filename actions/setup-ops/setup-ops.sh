#!/usr/bin/env bash
# Install one pinned ops release (github.com/rsvalerio/ops, cargo-dist) for the runner's
# platform. The tarball is checked against the release's .sha256 sidecar, and against
# EXPECTED_SHA256 when one is given, before anything is extracted.
#
# Configured through the environment (see action.yml for the meaning of each):
#   VERSION  EXPECTED_SHA256  INSTALL_DIR  GH_TOKEN  RUNNER_OS  RUNNER_ARCH
#
# Prints the installed binary's absolute path on stdout; everything else goes to stderr.
set -euo pipefail
umask 022

err() { echo "::error::setup-ops: $*" >&2; exit 1; }

REPOSITORY="rsvalerio/ops"
VERSION="${VERSION:-}"
EXPECTED_SHA256="${EXPECTED_SHA256:-}"
INSTALL_DIR="${INSTALL_DIR:?}"

# --- Version ------------------------------------------------------------------------------
# An exact release only: `latest` or a range would make the gate move without a commit.
VERSION="${VERSION#v}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] \
  || err "'version' must be an exact ops release such as 0.72.0, got '${VERSION}'."
tag="v${VERSION}"

if [ -n "$EXPECTED_SHA256" ]; then
  EXPECTED_SHA256="$(tr '[:upper:]' '[:lower:]' <<<"$EXPECTED_SHA256")"
  [[ "$EXPECTED_SHA256" =~ ^[0-9a-f]{64}$ ]] \
    || err "'sha256' must be 64 hex characters, got '${EXPECTED_SHA256}'."
fi

# --- Platform -----------------------------------------------------------------------------
# Only the targets ops actually publishes. Anything else fails here rather than 404ing on
# a guessed asset name.
case "${RUNNER_OS:-}/${RUNNER_ARCH:-}" in
  Linux/X64) triple=x86_64-unknown-linux-gnu ;;
  Linux/ARM64) triple=aarch64-unknown-linux-gnu ;;
  macOS/X64) triple=x86_64-apple-darwin ;;
  macOS/ARM64) triple=aarch64-apple-darwin ;;
  *) err "no ops release for ${RUNNER_OS:-unknown OS}/${RUNNER_ARCH:-unknown arch} (supported: Linux and macOS, X64 and ARM64)." ;;
esac

sha256() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{ print $1 }'
  else
    shasum -a 256 "$1" | awk '{ print $1 }'
  fi
}

command -v gh >/dev/null || err "the GitHub CLI (gh) is required to download the release."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- Download and verify ------------------------------------------------------------------
asset="ops-${triple}.tar.gz"
echo "Downloading ${asset} from ${REPOSITORY}@${tag}" >&2
gh release download "$tag" --repo "$REPOSITORY" --dir "$work" \
  --pattern "$asset" --pattern "${asset}.sha256" >&2 \
  || err "could not download ${asset} from ${REPOSITORY} release ${tag} (unknown version?)."
[ -f "${work}/${asset}" ] || err "release ${tag} has no ${asset}."
[ -f "${work}/${asset}.sha256" ] || err "release ${tag} has no ${asset}.sha256."

published="$(awk 'NF { print tolower($1); exit }' "${work}/${asset}.sha256")"
actual="$(sha256 "${work}/${asset}")"
[ "$published" = "$actual" ] \
  || err "checksum mismatch for ${asset}: the release publishes ${published}, the download is ${actual}."
if [ -n "$EXPECTED_SHA256" ]; then
  [ "$EXPECTED_SHA256" = "$actual" ] \
    || err "checksum mismatch for ${asset}: 'sha256' pins ${EXPECTED_SHA256}, the download is ${actual}."
fi
echo "sha256 ok: ${actual}" >&2

# --- Extract ------------------------------------------------------------------------------
tar -xzf "${work}/${asset}" -C "$work"
binary="${work}/ops-${triple}/ops"
# A symlink here would install whatever runner file it points at; dist archives hold none.
[ -f "$binary" ] && [ ! -L "$binary" ] || err "${asset} has no regular ops-${triple}/ops binary."

# --- Assert, then install -----------------------------------------------------------------
# Checked before it is copied, so a binary that does not run never lands on PATH.
reported="$("$binary" --version)" || err "the downloaded ops does not run on ${triple}."
[ "$reported" = "ops ${VERSION}" ] \
  || err "downloaded ops reports '${reported}', expected 'ops ${VERSION}'."
echo "$reported" >&2

mkdir -p "$INSTALL_DIR"
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"
install -m 0755 "$binary" "${INSTALL_DIR}/ops"

echo "${INSTALL_DIR}/ops"
