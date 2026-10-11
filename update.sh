#!/bin/sh
# Rebuild and install jlcone-bin if JLCPCB's update feed has a newer version.
# Works from the build folder, or installed as jlcone-update (builds in a cache dir).
# --check: only print the newer version (exit 0), or exit 1 if up to date.
set -eu
src=$(dirname "$(readlink -f "$0")")

feed=$(curl -fsSL -m 5 https://rs.jlcpcb.com/static/APP/app_version/latest-linux.yml)
ver=$(printf '%s\n' "$feed" | sed -n 's/^version: *//p')
sha=$(printf '%s\n' "$feed" | sed -n 's/^sha512: *//p' | base64 -d | od -An -tx1 -v | tr -d ' \n')
cur=$(sed -n 's/^pkgver=//p' "$src/PKGBUILD")

# Guard against a malformed feed before it gets written into the PKGBUILD
printf '%s' "$ver" | grep -Eqx '[0-9]+(\.[0-9]+)*' || { echo "bad version in feed: $ver" >&2; exit 1; }
[ ${#sha} -eq 128 ] || { echo "bad sha512 in feed" >&2; exit 1; }

if [ "$(vercmp "$ver" "$cur")" -le 0 ]; then
  [ "${1:-}" = --check ] || echo "jlcone is up to date ($cur)"
  exit 1
fi
[ "${1:-}" = --check ] && { echo "$ver"; exit 0; }

if [ -w "$src" ]; then
  cd "$src"
else
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
  work=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/jlcone-update.XXXXXX")
  trap 'rm -rf "$work"' EXIT
  cp "$src"/PKGBUILD "$src"/jlcone.sh "$src"/update.sh "$work"
  cd "$work"
fi

echo "Updating jlcone $cur -> $ver"
sed -i -e "s/^pkgver=.*/pkgver=$ver/" -e 's/^pkgrel=.*/pkgrel=1/' \
       -e "s/^sha512sums=('[0-9a-f]*'/sha512sums=('$sha'/" PKGBUILD
makepkg -f --noconfirm
# pkexec rather than sudo so this also works from the launcher, with no terminal
pkexec pacman -U --noconfirm "$(makepkg --packagelist)"
