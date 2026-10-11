#!/bin/sh
# MAS_BUILD=true makes the app treat itself as an App Store build, which skips its
# electron-updater/dpkg updater entirely. Updates are offered here instead.
update=/usr/share/jlcone-bin/update.sh

# Only check on a plain launch: not for jlcone:// links, and not while the app is
# running (pacman would replace its files underneath it).
if [ $# -eq 0 ] && ! pgrep -f '^/opt/JLCONE/jlcone( |$)' >/dev/null &&
   ver=$("$update" --check 2>/dev/null); then
  if command -v zenity >/dev/null; then
    if zenity --question --title=JLCONE --text="JLCONE $ver is available. Update now?" \
              --ok-label=Update --cancel-label=Later 2>/dev/null; then
      log=${XDG_CACHE_HOME:-$HOME/.cache}/jlcone-update.log
      mkdir -p "${log%/*}"
      { "$update" >"$log" 2>&1; echo $? >"$log.rc"; } |
        zenity --progress --pulsate --auto-close --no-cancel --title=JLCONE \
               --text="Updating JLCONE to $ver..." 2>/dev/null
      [ "$(cat "$log.rc")" = 0 ] ||
        zenity --error --title=JLCONE --text="Update failed, starting the current version. Details: $log" 2>/dev/null
      rm -f "$log.rc"
    fi
  else
    notify-send JLCONE "Version $ver is available. Run jlcone-update to install it." || true
  fi
fi

MAS_BUILD=true exec /opt/JLCONE/jlcone "$@"
