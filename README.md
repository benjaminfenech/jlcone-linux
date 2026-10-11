# jlcone-linux

Arch Linux package for [JLCONE](https://www.jlcpcb.com), the JLCPCB desktop client.

JLCPCB only publishes a Debian `.deb`. This PKGBUILD downloads that official `.deb`, checks it against the SHA-512 hash from JLCPCB's update feed, and repackages it for Arch. The app's own files aren't edited, but the package turns off the app's built-in updater and replaces it with `jlcone-update` (see [How it differs from the `.deb`](#how-it-differs-from-the-deb)). JLCONE is an Electron app that ships its own Electron runtime.

## Install

You need `base-devel` (for `makepkg`).

```sh
git clone <this repo>
cd jlcone-linux
makepkg -si
```

Start JLCONE from your app menu (listed under Development) or by running `jlcone`.

## Updating

```sh
jlcone-update
```

Run it as your normal user, not with `sudo`. It reads JLCPCB's update feed, and if there's a newer version it builds the new package in `~/.cache` and installs it, asking for your sudo password at that point. If you're already on the latest version it does nothing.

The app won't tell you when a new version is out, so run `jlcone-update` now and then.

From a clone of this repo you can run `./update.sh` instead. It does the same thing, and also updates the version and hash in the `PKGBUILD` here.

## How it differs from the `.deb`

- **The in-app updater is off.** It installs updates with `pkexec dpkg -i`, which doesn't work on Arch. The `jlcone` launcher sets `MAS_BUILD=true`, which makes the app skip its update code as if it were an App Store build. Nothing else in the app reads this variable. This also skips the app's call to JLCPCB's update server, which would otherwise say whether an update is mandatory.
- **No AppArmor profile.** The `.deb` installs one for Ubuntu. It isn't used on Arch.
- **`chrome-sandbox` isn't setuid**, because Arch kernels support unprivileged user namespaces.
- **The package includes its own build files** (`PKGBUILD`, `jlcone.sh`, `update.sh`) in `/usr/share/jlcone-bin/`. That's what lets `jlcone-update` work without a copy of this repo.

## Files

| File | Purpose |
|------|---------|
| `PKGBUILD` | Downloads the `.deb` and turns it into an Arch package |
| `jlcone.sh` | Launcher, installed as `/usr/bin/jlcone` |
| `update.sh` | Updater, installed as `/usr/bin/jlcone-update` |

## Known issues

- The EasyEDA tab inside JLCONE fails to open. The main JLCPCB login and the rest of the app work.
- `x86_64` only, because that's the only architecture JLCPCB publishes for Linux.

JLCONE is proprietary software by Jialichuang (Hong Kong) Co., Limited. This repo contains only the packaging scripts.
