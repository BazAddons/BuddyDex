#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Says which NPCs to write next.

    python tools/profiles/next.py 30                 the next 30 NPC IDs, one line
    python tools/profiles/next.py --all              how many are left, by zone
    python tools/profiles/next.py --flagged <folder> write skip files for NPCs the digests flag

An NPC is next if tools/profiles/research.py has made its digest, the
digest flags nothing that rules it out, Data/Lore.lua has no entry for it,
docs/npc-skipped.json doesn't list it, and no draft for it is waiting under
the work folder's drafts/. They come in the order players meet them, the
same order the recordings use (tools/voice/lore_order.py).
"""
import argparse
import collections
import importlib.util
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
WORK = Path("C:/Users/brett/BuddyDex-builds/profiles-pending")

spec = importlib.util.spec_from_file_location("lore_order", ROOT / "tools" / "voice" / "lore_order.py")
lore_order = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lore_order)

REASONS = {
    "child": "Child NPC; adults only.",
    "no_voice": "No recorded voice for this NPC's race or model yet. A new voice is the user's choice.",
    "hostile": "Hostile to both factions in Warcraft DB's current data.",
    "not_humanoid": "Not a humanoid.",
    "missing": "Not in Warcraft DB's Forever data.",
}


def main():
    parser = argparse.ArgumentParser(description="Which NPCs to write next.")
    parser.add_argument("count", nargs="?", type=int, default=0)
    parser.add_argument("--all", action="store_true", help="how many are left, by zone")
    parser.add_argument("--flagged", type=Path, help="write skip files for flagged NPCs into this folder")
    args = parser.parse_args()

    lore = (ROOT / "Data" / "Lore.lua").read_text(encoding="utf-8")
    done = {int(n) for n in re.findall(r"^    \[(\d+)\] = \{", lore, re.M)}
    skipped_path = ROOT / "docs" / "npc-skipped.json"
    if skipped_path.exists():
        done |= {row["npc_id"] for row in json.loads(skipped_path.read_text(encoding="utf-8"))["skipped"]}
    drafts = WORK / "drafts"
    waiting = {int(p.name.split(".")[0]) for p in drafts.rglob("*.*") if p.name.split(".")[0].isdigit()} if drafts.exists() else set()

    ready, flagged = [], []
    for path in (WORK / "digest").glob("*.json"):
        digest = json.loads(path.read_text(encoding="utf-8"))
        npc = digest["npc_id"]
        if npc in done or npc in waiting:
            continue
        blocking = [flag for flag in digest["flags"] if flag != "reaction_unknown"]
        if blocking:
            flagged.append((npc, digest, blocking))
        else:
            zone = lore_order.zone_of(digest.get("zone")) or lore_order.UNPLACED
            ready.append((lore_order.rank(zone), zone, npc))
    ready.sort()

    if args.flagged:
        args.flagged.mkdir(parents=True, exist_ok=True)
        for npc, digest, blocking in flagged:
            reason = " ".join(REASONS[flag] for flag in blocking)
            (args.flagged / f"{npc}.skip.json").write_text(json.dumps({"reason": reason}), encoding="utf-8")
        print(f"wrote {len(flagged)} skip files")
    elif args.all:
        zones = collections.Counter(zone for _, zone, _ in ready)
        for zone in sorted(zones, key=lambda z: (lore_order.rank(z), z)):
            print(f"{zone:22} {zones[zone]}")
        print(f"{len(ready)} to write, {len(flagged)} flagged, {len(waiting)} drafts waiting")
    else:
        print(" ".join(str(npc) for _, _, npc in ready[:args.count]))


if __name__ == "__main__":
    main()
