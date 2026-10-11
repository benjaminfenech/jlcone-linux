#!/bin/sh
# MAS_BUILD=true makes the app treat itself as an App Store build, which skips its
# electron-updater/dpkg updater entirely. Updates come from update.sh instead.
MAS_BUILD=true exec /opt/JLCONE/jlcone "$@"
