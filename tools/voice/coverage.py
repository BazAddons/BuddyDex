#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Reports how far each NPC is toward "covered" (goal.md).

    python tools/voice/coverage.py            the summary
    python tools/voice/coverage.py --json F   also write every NPC's status to F

An NPC is covered when it has all four:

  profile   every written part of its Data/Lore.lua entry (quote, likes,
            dislikes, gossip, bio, backstory, secret, bestFriend, favorite)
  lines     personal lines of its own (the entry's `lines`)
  voice     one recording voice (its `recordingVoice`, or the voice its
            existing clips are in)
  recorded  a current clip for every personal line, and for every general
            friend line (Data/NpcLines.lua) in its voice

Reads only; safe to run while tools/voice/backfill.py records.
"""
import argparse
import collections
import importlib.util
import json
import os
from pathlib import Path

spec = importlib.util.spec_from_file_location("voice_generate", Path(__file__).with_name("generate.py"))
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)
ROOT = Path(gen.ROOT)

PARTS = ("quote", "likes", "dislikes", "gossip", "bio", "backstory", "secret", "bestFriend", "favorite")


def clips():
    """voice -> the texts with a clip on disk, and source -> the voices its clips are in."""
    texts, owners = {}, collections.defaultdict(set)
    for voice in gen.VOICES:
        path = ROOT / "voice" / voice / "manifest.json"
        manifest = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
        texts[voice] = set()
        for name, entry in manifest.items():
            if (ROOT / "voice" / voice / name).exists():
                texts[voice].add(entry["text"])
                owners[entry.get("source", "mini")].add(voice)
    return texts, owners


def main():
    parser = argparse.ArgumentParser(description="Report NPC coverage.")
    parser.add_argument("--json", help="write every NPC's status to this file")
    args = parser.parse_args()

    lua = gen.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("NS = {}")
    lua.execute("assert(loadfile([[%s]]))('BuddyDex', NS)" % (ROOT / "Data" / "Lore.lua"))
    lore = lua.eval("NS.Lore")
    texts, owners = clips()
    general = [text for pile in gen.load_lines("npc").values() for text, _, _ in pile]
    general_done = {voice: sum(text in texts[voice] for text in general) for voice in gen.VOICES}

    rows = []
    for npc in sorted(lore.keys()):
        entry = lore[npc]
        missing_parts = [part for part in PARTS if not entry[part]]
        own = [text for pile in gen.load_lines(f"lore:{npc}").values() for text, _, _ in pile]
        voices = {entry.recordingVoice} if entry.recordingVoice else owners.get(f"lore:{npc}", set())
        voice = next(iter(voices)) if len(voices) == 1 else None
        recorded = sum(text in texts[voice] for text in own) if voice else 0
        rows.append({
            "npc": npc, "profile": not missing_parts, "missing_parts": missing_parts,
            "lines": len(own), "voice": voice, "recorded": recorded,
            "general": general_done.get(voice, 0),
            "covered": bool(not missing_parts and own and voice and recorded == len(own)
                            and general_done[voice] == len(general)),
        })

    total = len(rows)
    own_total = sum(r["lines"] for r in rows)
    print(f"{total} NPCs written")
    print(f"  profile complete      {sum(r['profile'] for r in rows):5} / {total}")
    print(f"  has personal lines    {sum(r['lines'] > 0 for r in rows):5} / {total}   ({own_total} lines)")
    print(f"  has a voice           {sum(r['voice'] is not None for r in rows):5} / {total}")
    print(f"  personal lines voiced {sum(r['recorded'] for r in rows):5} / {own_total}")
    print(f"    all of them         {sum(r['lines'] > 0 and r['recorded'] == r['lines'] for r in rows):5} / {total}")
    print(f"    some                {sum(0 < r['recorded'] < r['lines'] for r in rows):5}")
    print(f"    none                {sum(r['recorded'] == 0 for r in rows):5}")
    print(f"  covered               {sum(r['covered'] for r in rows):5} / {total}")
    print(f"general lines ({len(general)} per voice):")
    for voice in sorted(gen.VOICES):
        print(f"  {voice:16} {general_done[voice]:4}")
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(rows, f, indent=1)


if __name__ == "__main__":
    main()
