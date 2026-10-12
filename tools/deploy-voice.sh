#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copies the BuddyDex Voice pack (voice/) into the game's AddOns folder:
# the TOC, the generated Manifest.lua and the recorded clips, nothing else
# (the manifests the generator keeps stay behind, and anything else in the
# AddOns copy, old formats included, is removed). Clips removed from the
# repository are removed from the AddOns copy too.
#
#   tools/deploy-voice.sh                       the WoW: Forever client
#   tools/deploy-voice.sh <AddOns/BuddyDex_Voice>  somewhere else
#
# A new addon, or new files in its TOC, need a client restart.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/BuddyDex_Voice}"
DEST="${DEST%/}"

# Refuse anything that is not an AddOns/BuddyDex_Voice folder, because
# --delete empties whatever it is pointed at.
case "$DEST" in
    */Interface/AddOns/BuddyDex_Voice) ;;
    *) echo "deploy-voice: refusing '$DEST' - expected .../Interface/AddOns/BuddyDex_Voice" >&2; exit 1 ;;
esac
[ -d "$(dirname "$DEST")" ] || { echo "deploy-voice: no AddOns folder at $(dirname "$DEST")" >&2; exit 1; }
[ -f "$ROOT/voice/Manifest.lua" ] || { echo "deploy-voice: no voice/Manifest.lua - run tools/voice/generate.py --manifest" >&2; exit 1; }

mkdir -p "$DEST"
rsync -a --delete --delete-excluded --prune-empty-dirs \
    --include 'BuddyDex_Voice.toc' --include 'Manifest.lua' \
    --include '*/' --include '*/*.ogg' \
    --exclude '*' \
    "$ROOT/voice/" "$DEST/"
echo "deployed BuddyDex Voice ($(find "$DEST" -name '*.ogg' | wc -l | tr -d ' ') clips, $(du -sh "$DEST" | cut -f1)) to $DEST"
