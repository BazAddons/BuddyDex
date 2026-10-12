#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copies the working tree into the game's AddOns folder, as the packager
# would ship it: everything .pkgmeta ignores is left out, so what you test
# is what CurseForge gets. Files that were removed from the repository are
# removed from the AddOns copy too.
#
#   tools/deploy-scout.sh           the WoW: Forever client
#   tools/deploy-scout.sh <AddOns/BuddyDexScout>  somewhere else
#
# Saved variables live under WTF/, not in the addon folder, and are never
# touched. A new texture or font needs a client restart; Lua and TOC edits
# need /reload (TOC changes only on a restart).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/BuddyDexScout" && pwd)"
DEST="${1:-/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/BuddyDexScout}"
DEST="${DEST%/}"

# Refuse anything that is not an AddOns/BuddyDexScout folder, because --delete
# empties whatever it is pointed at.
case "$DEST" in
    */Interface/AddOns/BuddyDexScout) ;;
    *) echo "deploy: refusing '$DEST' - expected .../Interface/AddOns/BuddyDexScout" >&2; exit 1 ;;
esac
[ -d "$(dirname "$DEST")" ] || { echo "deploy: no AddOns folder at $(dirname "$DEST")" >&2; exit 1; }

# The ignore list from .pkgmeta, one "  - path" per line.
EXCLUDES=()
while IFS= read -r path; do
    EXCLUDES+=(--exclude "/$path")
done < <(sed -n '/^ignore:/,/^[^ ]/s/^  - //p' "$ROOT/.pkgmeta")
EXCLUDES+=(--exclude ".DS_Store")

rsync -a --delete "${EXCLUDES[@]}" "$ROOT/" "$DEST/"

VERSION="$(sed -n 's/^## Version: *//p' "$ROOT/BuddyDexScout.toc" | tr -d '\r')"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"
DIRTY="$(git -C "$ROOT" status --porcelain 2>/dev/null | head -1)"
echo "deployed BuddyDex Scout $VERSION ($COMMIT${DIRTY:+ + uncommitted changes}) to $DEST"
