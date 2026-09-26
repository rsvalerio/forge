#!/usr/bin/env bash
# Repackage cargo-dist linux-gnu tarballs into one .deb per architecture. No compile, no
# Docker, no Rust toolchain: unpack, stage with a control file, `dpkg-deb --build`.
#
# Configured through the environment (see action.yml for the meaning of each):
#   ARTIFACTS_DIR | TAG (+ REPOSITORY)   exactly one source of tarballs
#   VERSION  APP  PACKAGE  DESCRIPTION  MAINTAINER  SECTION  DEPENDS  HOMEPAGE
#   TARGETS  INSTALL_PATH  INCLUDE_DOCS  OUTPUT_DIR
#
# Prints the absolute path of every .deb it built on stdout, one per line; everything
# else goes to stderr.
set -euo pipefail
# Intermediate directories (usr/, usr/share/) take their mode from the umask, and a
# group-writable /usr in the package is wrong whatever the runner happens to default to.
umask 022

err() { echo "::error::deb-from-dist: $*" >&2; exit 1; }

ARTIFACTS_DIR="${ARTIFACTS_DIR:-}"
TAG="${TAG:-}"
VERSION="${VERSION:-}"
APP="${APP:-}"
PACKAGE="${PACKAGE:-$APP}"
SECTION="${SECTION:-utils}"
DEPENDS="${DEPENDS:-}"
HOMEPAGE="${HOMEPAGE:-}"
TARGETS="${TARGETS:-}"
INSTALL_PATH="${INSTALL_PATH:-/usr/bin}"
INCLUDE_DOCS="${INCLUDE_DOCS:-true}"
OUTPUT_DIR="${OUTPUT_DIR:?}"

[ -n "$APP" ] || err "'app' is required."
[ -n "${DESCRIPTION//[[:space:]]/}" ] || err "'description' is required."
[ -n "${MAINTAINER//[[:space:]]/}" ] || err "'maintainer' is required."
[[ "$PACKAGE" =~ ^[a-z0-9][a-z0-9+.-]+$ ]] || err "'$PACKAGE' is not a valid Debian package name."
[[ "$INSTALL_PATH" == /* ]] || err "'install-path' must be absolute, got '$INSTALL_PATH'."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- Source -------------------------------------------------------------------------------
if [ -n "$ARTIFACTS_DIR" ] && [ -n "$TAG" ]; then
  err "pass 'artifacts-dir' or 'tag', not both."
elif [ -n "$ARTIFACTS_DIR" ]; then
  [ -d "$ARTIFACTS_DIR" ] || err "artifacts-dir '$ARTIFACTS_DIR' does not exist."
  [ -n "$VERSION" ] || err "'version' is required with 'artifacts-dir'."
  src="$ARTIFACTS_DIR"
elif [ -n "$TAG" ]; then
  : "${REPOSITORY:?}"
  VERSION="${VERSION:-$TAG}"
  src="${work}/download"
  echo "Downloading ${APP} linux-gnu tarballs from ${REPOSITORY}@${TAG}" >&2
  gh release download "$TAG" --repo "$REPOSITORY" --dir "$src" \
    --pattern "${APP}-*-unknown-linux-gnu.tar.gz" \
    --pattern "${APP}-*-unknown-linux-gnu.tar.gz.sha256"
else
  err "pass 'artifacts-dir' (dist publish job) or 'tag' (existing release)."
fi

VERSION="${VERSION#v}"
[[ "$VERSION" =~ ^[0-9][A-Za-z0-9.+~-]*$ ]] || err "'$VERSION' is not a valid Debian version."

# --- Targets ------------------------------------------------------------------------------
targets=()
if [ -n "${TARGETS//[[:space:]]/}" ]; then
  read -r -a targets <<<"${TARGETS//[,$'\n']/ }"
else
  shopt -s nullglob
  for tarball in "${src}/${APP}"-*-unknown-linux-gnu.tar.gz; do
    triple="$(basename "$tarball" .tar.gz)"
    targets+=("${triple#"${APP}-"}")
  done
  shopt -u nullglob
  [ "${#targets[@]}" -gt 0 ] || err "no ${APP}-*-unknown-linux-gnu.tar.gz in ${src}."
fi

deb_arch() {
  # Only glibc linux: the apt repository serves Debian and Ubuntu. Anything else is a
  # caller mistake to surface, not a triple to guess an architecture for.
  case "$1" in
    x86_64-unknown-linux-gnu) echo amd64 ;;
    aarch64-unknown-linux-gnu) echo arm64 ;;
    *) err "cannot map target '$1' to a Debian architecture (supported: x86_64-unknown-linux-gnu, aarch64-unknown-linux-gnu)." ;;
  esac
}

# Map every target before building anything, so a bad triple fails fast and alone.
declare -A arch_of=()
for triple in "${targets[@]}"; do
  arch_of[$triple]="$(deb_arch "$triple")"
done

# Debian's extended description: continuation lines start with a space, blank ones are " .".
control_description() {
  local first=true line
  while IFS= read -r line || [ -n "$line" ]; do
    if $first; then
      printf 'Description: %s\n' "$line"
      first=false
    elif [ -z "${line//[[:space:]]/}" ]; then
      printf ' .\n'
    else
      printf ' %s\n' "$line"
    fi
  done <<<"$DESCRIPTION"
}

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

for triple in "${targets[@]}"; do
  arch="${arch_of[$triple]}"
  tarball="${src}/${APP}-${triple}.tar.gz"
  [ -f "$tarball" ] || err "missing ${tarball}."
  [ -f "${tarball}.sha256" ] || err "missing checksum ${tarball}.sha256."

  expected="$(awk 'NF { print $1; exit }' "${tarball}.sha256")"
  actual="$(sha256sum "$tarball" | awk '{ print $1 }')"
  [ "$expected" = "$actual" ] \
    || err "checksum mismatch for $(basename "$tarball"): expected ${expected}, got ${actual}."

  unpacked="${work}/unpack-${triple}"
  mkdir -p "$unpacked"
  tar -xzf "$tarball" -C "$unpacked"
  root="${unpacked}/${APP}-${triple}"
  [ -f "${root}/${APP}" ] || err "$(basename "$tarball") has no ${APP}-${triple}/${APP} binary."

  stage="${work}/stage-${triple}"
  install -d -m 0755 "$stage" "${stage}/DEBIAN" "${stage}${INSTALL_PATH}"
  install -m 0755 "${root}/${APP}" "${stage}${INSTALL_PATH}/${APP}"

  if [ "$INCLUDE_DOCS" = "true" ]; then
    docs="${stage}/usr/share/doc/${PACKAGE}"
    for f in "${root}"/LICENSE* "${root}"/README*; do
      [ -f "$f" ] || continue
      install -d -m 0755 "$docs"
      install -m 0644 "$f" "${docs}/$(basename "$f")"
    done
  fi

  installed_size="$(du -sk --exclude=DEBIAN "$stage" | awk '{ print $1 }')"
  {
    printf 'Package: %s\n' "$PACKAGE"
    printf 'Version: %s\n' "$VERSION"
    printf 'Architecture: %s\n' "$arch"
    printf 'Maintainer: %s\n' "$MAINTAINER"
    printf 'Installed-Size: %s\n' "$installed_size"
    [ -n "$DEPENDS" ] && printf 'Depends: %s\n' "$DEPENDS"
    printf 'Section: %s\n' "$SECTION"
    printf 'Priority: optional\n'
    [ -n "$HOMEPAGE" ] && printf 'Homepage: %s\n' "$HOMEPAGE"
    control_description
  } >"${stage}/DEBIAN/control"

  deb="${OUTPUT_DIR}/${PACKAGE}_${VERSION}_${arch}.deb"
  dpkg-deb --root-owner-group --build "$stage" "$deb" >&2
  echo "$deb"
done
