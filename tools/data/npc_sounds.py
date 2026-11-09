# SPDX-License-Identifier: GPL-2.0-or-later
"""Writes Data/NpcSounds.lua: which in-game voice each creature model uses.

A friend who comes along speaks in the voice the game gives them: every
creature display (CreatureDisplayInfo) names an NPC sound set (NPCSounds),
whose sound kits are the greetings, farewells and annoyed lines heard when
you click an NPC. Friends of a race with a recorded BuddyDex voice speak in
that instead, so the race and sex of those races' displays are kept too
(CreatureDisplayInfoExtra). The client offers no way to look any of this
up, so it is read from the game's DB2 tables, as wago.tools publishes them
for this client's branch, and shipped as data.

    .venv/bin/python -I tools/data/npc_sounds.py [--branch wow_classic_beta]
"""

import argparse
import csv
import io
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "Data" / "NpcSounds.lua"
URL = "https://wago.tools/db2/{table}/csv?branch={branch}"
PER_LINE = 10
# Races whose NPCs have recorded voices (Core/Voice.lua RACE_VOICES), by
# ChrRaces ID: 1 human, 2 orc, 3 dwarf, 4 night elf, 5 Forsaken, 6 Tauren, 7 gnome, 8 troll, 9 goblin, and Forever's
# Skyborne, 95 High Order and 96 Windshaper.
VOICED_RACES = {1, 2, 3, 4, 5, 6, 7, 8, 9, 95, 96}


def table(name, branch, cache_dir=None):
    cached = cache_dir / f"{name}.csv" if cache_dir else None
    if cached and cached.exists():
        return list(csv.DictReader(io.StringIO(cached.read_text(encoding="utf-8-sig"))))
    request = urllib.request.Request(URL.format(table=name, branch=branch),
                                     headers={"User-Agent": "BuddyDex data tool"})
    with urllib.request.urlopen(request, timeout=120) as response:
        text = response.read().decode("utf-8-sig")
    if cached:
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_text(text, encoding="utf-8")
    return list(csv.DictReader(io.StringIO(text)))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--branch", default="wow_classic_beta")
    parser.add_argument("--cache-dir", type=pathlib.Path, help="CSV snapshot directory; preserve it to reproduce this build")
    args = parser.parse_args()

    sets = {}
    for row in table("NPCSounds", args.branch, args.cache_dir):
        kits = [int(row[f"SoundID_{i}"]) for i in range(3)]
        if any(kits):
            sets[int(row["ID"])] = kits
    creatures = table("CreatureDisplayInfo", args.branch, args.cache_dir)
    displays = sorted(
        (int(row["ID"]), int(row["NPCSoundID"]))
        for row in creatures
        if int(row["NPCSoundID"]) in sets
    )
    used = sorted({s for _, s in displays})
    extra = {int(row["ID"]): (int(row["DisplayRaceID"]), int(row["DisplaySexID"]))
             for row in table("CreatureDisplayInfoExtra", args.branch, args.cache_dir)}
    bodies = sorted(
        (int(row["ID"]),) + extra[int(row["ExtendedDisplayInfoID"])]
        for row in creatures
        if extra.get(int(row["ExtendedDisplayInfoID"]), (0, 0))[0] in VOICED_RACES
    )

    pairs = [f"{d}:{s}" for d, s in displays]
    lines = [" " + " ".join(pairs[i:i + PER_LINE]) for i in range(0, len(pairs), PER_LINE)]
    triples = [f"{d}:{r}:{s}" for d, r, s in bodies]
    body_lines = [" " + " ".join(triples[i:i + PER_LINE]) for i in range(0, len(triples), PER_LINE)]
    out = [
        "-- SPDX-License-Identifier: GPL-2.0-or-later",
        "local ADDON_NAME, ns = ...",
        "",
        "-- Data/NpcSounds.lua: the voice the game gives each creature model, so a",
        "-- friend who comes along sounds like themselves (Core/Voice.lua). Made by",
        f"-- tools/data/npc_sounds.py from the {args.branch} DB2 tables: NPCSounds",
        "-- (the sets), CreatureDisplayInfo (which set each display uses) and",
        "-- CreatureDisplayInfoExtra (the race and sex of a character-style display).",
        "-- Generated; don't edit by hand.",
        "",
        "ns.NpcSounds = {",
        "    -- set = { greeting, farewell, annoyed }: sound kits, each a few lines",
        "    -- the game picks from.",
        "    sets = {",
    ]
    out += [f"        [{s}] = {{ {', '.join(map(str, sets[s]))} }}," for s in used]
    out += [
        "    },",
        "    -- \"display:set\" pairs, space-separated: one string, not a table of",
        f"    -- {len(displays)} entries, since only the friend who is out is looked up.",
        "    displays = [[",
        *lines,
        "]],",
        "    -- \"display:race:sex\" (sex 0 male, 1 female) for the displays of races",
        f"    -- with recorded voices ({', '.join(map(str, sorted(VOICED_RACES)))}), so a friend of one speaks in it.",
        "    bodies = [[",
        *body_lines,
        "]],",
        "}",
        "",
    ]
    OUT.write_text("\n".join(out))
    print(f"wrote {OUT.relative_to(ROOT)}: {len(displays)} displays, {len(used)} voice sets, "
          f"{len(bodies)} voiced bodies, "
          f"{OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
