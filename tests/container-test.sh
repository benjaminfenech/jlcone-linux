#!/bin/sh
# Builds and installs jlcone-bin with update.sh --install, then smoke-tests it.
# Runs as root in a fresh Arch, Rocky/RHEL or Fedora container, from a writable
# copy of the repo. Used by CI; also works locally under podman/docker.
set -eu
cd "$(dirname "$0")/.."
fail() { echo "FAIL: $*" >&2; exit 1; }

# No polkit agent in a container, so stand in for pkexec
if command -v pacman >/dev/null; then
  # pacman's download sandbox doesn't work in unprivileged containers
  grep -q '^DisableSandbox' /etc/pacman.conf || sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
  pacman -Syu --noconfirm --needed base-devel
  useradd -m builder
  echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
  printf '#!/bin/sh\nexec sudo "$@"\n' > /usr/local/bin/pkexec
  chmod +x /usr/local/bin/pkexec
  # makepkg refuses to run as root
  chown -R builder .
  su builder -c './update.sh --install'
else
  dnf install -y rpm-build binutils tar xz procps-ng
  printf '#!/bin/sh\nexec "$@"\n' > /usr/local/bin/pkexec
  chmod +x /usr/local/bin/pkexec
  ./update.sh --install
fi

echo "### smoke test"
missing=$(ldd /opt/JLCONE/jlcone | grep 'not found' || true)
[ -z "$missing" ] || fail "missing libraries: $missing"

# Exit 1 means up to date, 0 means the feed has a newer version; anything else is an error
rc=0; newer=$(jlcone-update --check) || rc=$?
case $rc in
  0) echo "note: feed has a newer version ($newer)" ;;
  1) ;;
  *) fail "jlcone-update --check exited $rc" ;;
esac

# --no-sandbox: containers don't allow Chromium's sandbox. Headless: RHEL 10 has no Xvfb
log=$(mktemp)
timeout 30 jlcone --no-sandbox --ozone-platform=headless >"$log" 2>&1 || true
grep -q 'Single instance lock acquired' "$log" || { cat "$log"; fail "app didn't start"; }
grep -q 'App Store version detected' "$log" || { cat "$log"; fail "built-in updater wasn't turned off"; }
echo "### smoke test passed"
