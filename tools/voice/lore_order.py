#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Orders friends' own lines for recording by how soon players meet them.

    python tools/voice/lore_order.py <order.json> [--queue <queue.json>]

Writes a JSON list of NPC IDs for tools/voice/backfill.py --order: starting
zones first (the first friends every new character makes), then the
capitals, busiest first, then every other zone by the level players arrive
at it, and NPCs this can't place last. Within a zone, NPC IDs go in order.

Each profile's zone comes from docs/npc-coverage.json, the audit of written
profiles. For a profile it doesn't cover yet, the research comment that
opens its Data/Lore.lua entry (or its group's) names where the NPC stands:
a zone ("Westfall") or a place in one ("Thelsamar"); the earliest such name
wins, since the location follows the NPC's name and later mentions are
quest references. The candidate catalog's scouted zone is the last resort.

With --queue (a backfill queue.json), it also prints what each zone's
missing lines cost, so a month's credits can be planned.
"""
import argparse
import collections
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Starting zones (Zephras Isle, where Forever's Skyborne of both factions
# begin, leads), then capitals by how busy they are.
FIRST = [
    "Zephras Isle",
    "Elwynn Forest", "Dun Morogh", "Teldrassil", "Durotar", "Mulgore", "Tirisfal Glades",
    "Stormwind City", "Orgrimmar", "Ironforge", "Undercity", "Thunder Bluff", "Darnassus",
    "Deeprun Tram",
]
# Every other zone by the level players arrive at it.
LEVELS = {
    "Westfall": 10, "Loch Modan": 10, "Darkshore": 10, "The Barrens": 10,
    "Silverpine Forest": 10, "Redridge Mountains": 15, "Stonetalon Mountains": 15,
    "Ashenvale": 18, "Duskwood": 18, "Wetlands": 20, "Hillsbrad Foothills": 20,
    "Thousand Needles": 25, "Alterac Mountains": 30, "Arathi Highlands": 30,
    "Desolace": 30, "Stranglethorn Vale": 30, "Badlands": 35, "Swamp of Sorrows": 35,
    "Dustwallow Marsh": 35, "Feralas": 40, "The Hinterlands": 40, "Tanaris": 40,
    "Riverglades": 40,
    "Searing Gorge": 43, "Azshara": 45, "Blasted Lands": 45, "Un'Goro Crater": 48,
    "Felwood": 48, "Moonglade": 48, "Burning Steppes": 50, "Western Plaguelands": 51,
    "Eastern Plaguelands": 53, "Winterspring": 53, "Deadwind Pass": 55, "Silithus": 55,
}
# Places the research comments name, by zone.
PLACES = {
    "Stormwind City": ["Stormwind", "Trade District", "Cathedral Square", "Mage Quarter",
                       "Dwarven District", "Old Town", "Valley of Heroes", "Stockade"],
    "Ironforge": ["Great Forge", "Hall of Explorers", "Tinker Town", "Military Ward", "Mystic Ward"],
    "Orgrimmar": ["Valley of Honor", "Valley of Strength", "Valley of Wisdom", "Valley of Spirits",
                  "Cleft of Shadow", "The Drag", "Nogg's Machine Shop", "Yelmak's", "Kodohide"],
    "Darnassus": ["Temple of the Moon", "Cenarion Enclave", "Craftsmen's Terrace", "Tradesmen's Terrace"],
    "Elwynn Forest": ["Elwynn", "Northshire", "Goldshire", "Lion's Pride", "Eastvale", "Brackwell",
                      "Maclure", "Stonefield"],
    "Dun Morogh": ["Kharanos", "Anvilmar", "Coldridge", "Gnomeregan", "Brewnall", "Thunderbrew",
                   "Gol'Bolar", "GolBolar"],
    "Teldrassil": ["Dolanaar", "Aldrassil", "Shadowglen", "Rut'theran"],
    "Durotar": ["Razor Hill", "Sen'jin", "Valley of Trials"],
    "Mulgore": ["Bloodhoof", "Narache"],
    "Tirisfal Glades": ["Tirisfal", "Brill", "Deathknell"],
    "Westfall": ["Sentinel Hill", "Moonbrook", "Saldean", "Furlbrow"],
    "Loch Modan": ["Thelsamar", "Stonewrought", "Algaz"],
    "Darkshore": ["Auberdine"],
    "The Barrens": ["Barrens", "Crossroads", "Ratchet", "Camp Taurajo", "Mor'shan"],
    "Silverpine Forest": ["Silverpine", "Sepulcher"],
    "Redridge Mountains": ["Redridge", "Lakeshire"],
    "Stonetalon Mountains": ["Stonetalon", "Sun Rock", "Malaka'jin", "Windshear"],
    "Ashenvale": ["Astranaar"],
    "Duskwood": ["Darkshire"],
    "Wetlands": ["Menethil"],
    "Hillsbrad Foothills": ["Hillsbrad", "Southshore", "Tarren Mill"],
    "Arathi Highlands": ["Refuge Pointe", "Hammerfall"],
    "Alterac Mountains": ["Dalaran"],
    "Zephras Isle": ["Valanaar"],
    "Riverglades": ["Powderfuse"],
    "Thousand Needles": ["Freewind", "Mirage Raceway"],
    "Desolace": ["Nijel", "Ghost Walker", "Shadowprey"],
    "Stranglethorn Vale": ["Stranglethorn", "Booty Bay", "Grom'gol", "Salty Sailor"],
    "Dustwallow Marsh": ["Theramore"],
    "Feralas": ["Feathermoon", "Camp Mojache"],
    "The Hinterlands": ["Aerie Peak"],
    "Tanaris": ["Gadgetzan", "Steamwheedle"],
    "Searing Gorge": ["Thorium Point"],
    "Un'Goro Crater": ["Marshal's Refuge", "Marshals Refuge", "UnGoro"],
    "Winterspring": ["Everlook"],
    "Eastern Plaguelands": ["Light's Hope"],
    "Western Plaguelands": ["Chillwind"],
    "Silithus": ["Cenarion Hold"],
    "Blasted Lands": ["Nethergarde"],
    "Badlands": ["Kargath"],
    "Swamp of Sorrows": ["Stonard"],
}
NAMES = {zone: zone for zone in FIRST + list(LEVELS)}
for zone, places in PLACES.items():
    NAMES.update({place: zone for place in places})
PATTERN = re.compile(r"\b(?:%s)\b" % "|".join(re.escape(n) for n in sorted(NAMES, key=len, reverse=True)))
UNPLACED = "(unplaced)"


def rank(zone):
    if zone in FIRST:
        return (FIRST.index(zone), 0)
    return (len(FIRST), LEVELS.get(zone, 999))


def research_comments():
    """npcID -> the comment that introduces its entry, or its group's."""
    comments, block, current = {}, [], ""
    with open(os.path.join(ROOT, "Data", "Lore.lua"), encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("    --"):
                block.append(line.strip()[3:])
                continue
            match = re.match(r"^    \[(\d+)\] = \{", line)
            if match:
                if block:
                    current = " ".join(block)
                comments[int(match.group(1))] = current
            if line.strip() and not line.startswith("        "):
                block = []
    return comments


def coverage_zones():
    with open(os.path.join(ROOT, "docs", "npc-coverage.json"), encoding="utf-8") as f:
        coverage = json.load(f)
    return {entry["npc_id"]: entry["zone"] for entry in coverage["entries"] if entry.get("zone")}


def scouted_zones():
    with open(os.path.join(ROOT, "docs", "catalog", "buddydex-candidates.json"), encoding="utf-8") as f:
        catalog = json.load(f)
    return {entry["npc_id"]: entry["zone"] for group in catalog["candidates"]
            for entry in group["entries"] if entry.get("zone")}


def zone_of(text):
    match = PATTERN.search(text or "")
    return NAMES[match.group(0)] if match else None


def main():
    parser = argparse.ArgumentParser(description="Order friends' lines for recording.")
    parser.add_argument("order", help="where to write the JSON list of NPC IDs")
    parser.add_argument("--queue", help="a backfill queue.json, to print each zone's cost")
    args = parser.parse_args()

    comments, covered, scouted = research_comments(), coverage_zones(), scouted_zones()
    zones = {npc: zone_of(covered.get(npc)) or zone_of(text) or zone_of(scouted.get(npc)) or UNPLACED
             for npc, text in comments.items()}
    order = sorted(zones, key=lambda npc: (rank(zones[npc]), zones[npc], npc))
    with open(args.order, "w", encoding="utf-8") as f:
        json.dump(order, f)
    print(f"{args.order}: {len(order)} NPCs, {sum(z == UNPLACED for z in zones.values())} unplaced")

    if args.queue:
        with open(args.queue, encoding="utf-8") as f:
            queue = json.load(f)
        cost = collections.defaultdict(lambda: [0, 0])
        for job in queue:
            if job["source"].startswith("lore:"):
                zone = zones.get(int(job["source"].split(":")[1]), UNPLACED)
                cost[zone][0] += 1
                cost[zone][1] += len(job["spoken"])
        total = 0
        for zone in sorted(cost, key=lambda z: (rank(z), z)):
            clips, chars = cost[zone]
            total += chars
            print(f"  {zone:22} {clips:5} clips {chars:8,} credits  (running total {total:,})")


if __name__ == "__main__":
    main()
