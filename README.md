# jlcone-arch

Arch Linux and RHEL/Fedora packages for [JLCONE](https://www.jlcpcb.com), the JLCPCB desktop client.

JLCPCB only publishes a Debian `.deb`. The `PKGBUILD` (Arch) and `jlcone.spec` (RHEL/Fedora) download that official `.deb`, check it against the SHA-512 hash from JLCPCB's update feed, and repackage it. The app's own files aren't edited, but the package turns off the app's built-in updater and replaces it with `jlcone-update` (see [How it differs from the `.deb`](#how-it-differs-from-the-deb)). JLCONE is an Electron app that ships its own Electron runtime.

## Install

Download the latest [release](https://github.com/benjaminfenech/jlcone-arch/releases) and extract it, or clone the repo:

```sh
git clone https://github.com/benjaminfenech/jlcone-arch.git
cd jlcone-arch
```

### Arch

You need `base-devel` (for `makepkg`).

```sh
makepkg -si
```

### RHEL, Rocky, Alma (9 and later) and Fedora

You need `rpm-build`.

```sh
sudo dnf install rpm-build
./update.sh --install
```

This downloads the `.deb`, builds the RPM and installs it with `dnf`, asking for your password. Tested on Rocky Linux 9.

Start JLCONE from your app menu (listed under Development) or by running `jlcone`.

## Updating

When you start JLCONE, the launcher checks JLCPCB's update feed. This adds about a second to startup, and is skipped if you're offline or JLCONE is already running. If a newer version is out, it asks whether to update now:

- **Update** downloads the new `.deb`, builds the package in `~/.cache` (about 15 seconds on a fast connection), asks for your password to install it, then starts the new version. If anything fails, it says so and starts the version you have. The log is in `~/.cache/jlcone-update.log`.
- **Later** starts the version you have. You'll be asked again next time.

Installing from the launcher needs a polkit agent to show the password prompt. Desktop environments (GNOME, KDE Plasma, etc.) and many Hyprland/Sway shells include one. On a bare window manager, install one (e.g. `hyprpolkitagent` or `polkit-gnome`), or update with `jlcone-update` in a terminal instead.

The prompt needs `zenity`. Without it you get a desktop notification instead, and can update by running:

```sh
jlcone-update
```

Run it as your normal user, not with `sudo`. It does the same update from a terminal. If you're already on the latest version it does nothing.

From a clone of this repo you can run `./update.sh` instead. It does the same thing, and also updates the version and hash in the `PKGBUILD` and `jlcone.spec` here.

## How it differs from the `.deb`

- **The in-app updater is off.** It installs updates with `pkexec dpkg -i`, which doesn't work on Arch or RHEL. The `jlcone` launcher sets `MAS_BUILD=true`, which makes the app skip its update code as if it were an App Store build. Nothing else in the app reads this variable. This also skips the app's call to JLCPCB's update server, which would otherwise say whether an update is mandatory.
- **No AppArmor profile.** The `.deb` installs one for Ubuntu. It isn't used on Arch or RHEL.
- **`chrome-sandbox` isn't setuid**, because Arch, RHEL 9+ and Fedora kernels support unprivileged user namespaces.
- **The package includes its own build files** (`PKGBUILD` or `jlcone.spec`, plus `jlcone.sh` and `update.sh`) in `/usr/share/jlcone-bin/`. That's what lets `jlcone-update` work without a copy of this repo.

## Files

| File | Purpose |
|------|---------|
| `PKGBUILD` | Downloads the `.deb` and turns it into an Arch package |
| `jlcone.spec` | The same for RHEL/Fedora (RPM) |
| `jlcone.sh` | Launcher, installed as `/usr/bin/jlcone`. Offers updates on startup |
| `update.sh` | Updater, installed as `/usr/bin/jlcone-update`. Uses pacman on Arch and dnf elsewhere. `--install` builds and installs even when there's no update |

## Known issues

- The EasyEDA tab inside JLCONE fails to open. The main JLCPCB login and the rest of the app work.
- `x86_64` only, because that's the only architecture JLCPCB publishes for Linux.

JLCONE is proprietary software by Jialichuang (Hong Kong) Co., Limited. This repo contains only the packaging scripts.
