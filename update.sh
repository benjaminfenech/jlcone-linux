#!/bin/sh
# Rebuild and install jlcone-bin if JLCPCB's update feed has a newer version.
# Arch uses the PKGBUILD, RHEL/Fedora the jlcone.spec. Works from the repo folder,
# or installed as jlcone-update (builds in a cache dir).
# --check: only print the newer version (exit 0), or exit 1 if up to date.
# --install: build and install even if the feed has nothing newer.
# --bump: only rewrite the version and hash in the build files (used by CI).
set -eu
src=$(dirname "$(readlink -f "$0")")
mode=${1:-}
feed_url=https://rs.jlcpcb.com/static/APP/app_version
if command -v pacman >/dev/null; then pkgfile=PKGBUILD; else pkgfile=jlcone.spec; fi
file_ver() { sed -n -e 's/^pkgver=//p' -e 's/^Version: *//p' "$1"; }

feed=$(curl -fsSL -m 5 "$feed_url/latest-linux.yml")
ver=$(printf '%s\n' "$feed" | sed -n 's/^version: *//p')
sha=$(printf '%s\n' "$feed" | sed -n 's/^sha512: *//p' | base64 -d | od -An -tx1 -v | tr -d ' \n')
cur=$(file_ver "$src/$pkgfile")

# Guard against a malformed feed before it gets written into the build files
printf '%s' "$ver" | grep -Eqx '[0-9]+(\.[0-9]+)*' || { echo "bad version in feed: $ver" >&2; exit 1; }
[ ${#sha} -eq 128 ] || { echo "bad sha512 in feed" >&2; exit 1; }

newer=false
[ "$(printf '%s\n' "$ver" "$cur" | sort -V | tail -n1)" != "$cur" ] && newer=true
if ! $newer && [ "$mode" != --install ]; then
  [ "$mode" = --check ] && exit 1
  echo "jlcone is up to date ($cur)"
  exit 0
fi
[ "$mode" = --check ] && { echo "$ver"; exit 0; }

if [ -w "$src" ]; then
  cd "$src"
else
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
  work=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/jlcone-update.XXXXXX")
  trap 'rm -rf "$work"' EXIT
  cp "$src"/* "$work"
  cd "$work"
fi

if $newer; then
  echo "Updating jlcone $cur -> $ver"
  for f in PKGBUILD jlcone.spec; do
    [ -f "$f" ] || continue
    sed -i -e "s/^pkgver=.*/pkgver=$ver/" -e 's/^pkgrel=.*/pkgrel=1/' \
           -e "s/^sha512sums=('[0-9a-f]*'/sha512sums=('$sha'/" \
           -e "s/^Version:\( *\).*/Version:\1$ver/" -e 's/^Release:\( *\).*/Release:\11%{?dist}/' \
           -e "s/^%global deb_sha512 .*/%global deb_sha512 $sha/" "$f"
  done
fi
[ "$mode" = --bump ] && exit 0

# pkexec rather than sudo so this also works from the launcher, with no terminal
if [ "$pkgfile" = PKGBUILD ]; then
  # --nodeps: nothing is compiled; pacman -U installs the runtime deps
  makepkg -f --nodeps --noconfirm
  pkexec pacman -U --noconfirm "$(makepkg --packagelist)"
else
  v=$(file_ver jlcone.spec)
  [ -f "jlcone-$v.deb" ] || curl -fL -o "jlcone-$v.deb" "$feed_url/jlcone-$v.deb"
  rpmbuild -bb --define "_sourcedir $PWD" --define "_rpmdir $PWD/rpms" \
           --define "_build_name_fmt jlcone-bin.rpm" jlcone.spec
  pkexec dnf install -y "$PWD/rpms/jlcone-bin.rpm"
fi
