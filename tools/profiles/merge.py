#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Moves checked drafts into the addon and its records.

    python tools/profiles/merge.py <folder> --name <batch>

<folder> holds drafts as tools/profiles/check.py expects them. Every draft
that passes goes in; the rest stay where they are, with the reason printed.
<batch> names the research note, docs/research/<batch>.md.

For each draft that passes, this:

  - adds the entry at the top of Data/Lore.lua, with a "Research:" line
    under its facts comment (the file is rewritten in one step, and only
    after the new text loads as Lua, so the recorder never sees half a file)
  - adds its research note to docs/research/<batch>.md
  - records it in docs/npc-backlog.json, npc-coverage.json,
    npc-research-roster.json and npc-profile-priorities.json
  - moves the draft files to <folder>/../merged/<batch>/

NPCs with a skip file are recorded in docs/npc-skipped.json with the reason
and moved the same way. CHANGELOG.md gets one line for the batch. Then
tools/tests/smoke.py runs; if it fails, every file is put back as it was.
"""
import argparse
import datetime
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

spec = importlib.util.spec_from_file_location("profile_check", Path(__file__).with_name("check.py"))
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)
ROOT = check.ROOT
CRLF = "\r\n"

RECORDS = {name: ROOT / "docs" / f"npc-{name}.json"
           for name in ("backlog", "coverage", "research-roster", "profile-priorities", "skipped")}
AUDIO_NOTE = "Profile text complete; approved voice assigned; recording queued behind earlier profiles."


def read_json(path, default=None):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def write(path, text):
    """Replaces a file in one step, with the repository's CRLF line endings."""
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(text.replace(CRLF, "\n").replace("\n", CRLF).encode("utf-8"))
    os.replace(temporary, path)


def write_json(path, data):
    write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def reaction(digest):
    """(friendly sides, the evidence line) from the digest's reactions."""
    sides = digest.get("reactions") or {}
    friendly = [side for side in ("alliance", "horde") if sides.get(side) == "Friendly"]
    if friendly:
        names = " and ".join(side.title() for side in friendly)
        return friendly, f"Current {names} Friendly icon" + ("s" if len(friendly) > 1 else "")
    neutral = [side for side in ("alliance", "horde") if sides.get(side) == "Neutral"]
    if neutral:
        return [], "Current " + " and ".join(side.title() for side in neutral) + " Neutral icon" + ("s" if len(neutral) > 1 else "")
    return [], ""


def with_research_line(source, batch):
    """A draft's text with the Research line under its facts comment."""
    lines = source.replace(CRLF, "\n").strip("\n").split("\n")
    at = next(i for i, line in enumerate(lines) if not line.startswith("    --"))
    lines.insert(at, f"    -- Research: docs/research/{batch}.md")
    return "\n".join(lines) + "\n\n"


def main():
    parser = argparse.ArgumentParser(description="Merge checked drafts into the addon.")
    parser.add_argument("folder", type=Path)
    parser.add_argument("--name", required=True, help="the batch: names docs/research/<name>.md")
    parser.add_argument("--as-of", default=datetime.date.today().isoformat())
    args = parser.parse_args()
    folder = args.folder
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", args.name):
        sys.exit("merge: the batch name is lowercase letters, digits and hyphens")

    known = {"emotes": check.emotes(), "moments": check.moments(), "written": check.written()}
    npcs = sorted({int(p.name.split(".")[0]) for p in folder.iterdir() if p.name.split(".")[0].isdigit()})
    ready, skips = [], []
    for npc in npcs:
        errors = check.check(folder, npc, known)
        if errors:
            print(f"{npc}: left out ({errors[0]})")
        elif (folder / f"{npc}.skip.json").exists():
            skips.append(npc)
        else:
            ready.append(npc)
    if not ready and not skips:
        sys.exit("merge: nothing ready")

    touched = [ROOT / "Data" / "Lore.lua", ROOT / "CHANGELOG.md", ROOT / "docs" / "research" / f"{args.name}.md",
               *RECORDS.values()]
    before = {path: path.read_bytes() if path.exists() else None for path in touched}

    digests = {npc: json.loads((check.DIGESTS / f"{npc}.json").read_text(encoding="utf-8")) for npc in ready + skips}
    metas = {npc: json.loads((folder / f"{npc}.meta.json").read_text(encoding="utf-8")) for npc in ready}
    entries = {npc: check.load(folder / f"{npc}.lua", npc) for npc in ready}
    research = f"docs/research/{args.name}.md"

    if ready:
        # Data/Lore.lua: new entries go first, as the file has always grown.
        lore_path = ROOT / "Data" / "Lore.lua"
        lore = lore_path.read_text(encoding="utf-8").replace(CRLF, "\n")
        marker = "ns.Lore = {\n"
        at = lore.index(marker) + len(marker)
        added = "".join(with_research_line(entries[npc][1], args.name) for npc in ready)
        lore = lore[:at] + added + lore[at:]
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute("NS = {}")
        lua.execute("local f = assert(loadstring(...)); f('BuddyDex', NS)", lore)
        loaded = lua.eval("NS.Lore")
        missing = [npc for npc in ready if not loaded[npc]]
        if missing:
            sys.exit(f"merge: entries did not load: {missing}")
        write(lore_path, lore)

        # The research note.
        note_path = ROOT / research
        note = note_path.read_text(encoding="utf-8").replace(CRLF, "\n") if note_path.exists() else (
            f"# Profiles: {args.name}\n\n"
            f"Written {args.as_of} from the digests tools/profiles/research.py makes: each NPC's Warcraft DB "
            "record, the quests it starts and ends, its wares and training, and classicdb.ch's progress and "
            "completion text for Classic-era quests. Each section says what the game establishes and what is "
            "original BuddyDex writing. Public data is evidence, not proof of live eligibility.\n")
        for npc in ready:
            note += "\n" + (folder / f"{npc}.md").read_text(encoding="utf-8").replace(CRLF, "\n").strip("\n") + "\n"
        write(note_path, note)

        backlog, coverage = read_json(RECORDS["backlog"]), read_json(RECORDS["coverage"])
        roster, priorities = read_json(RECORDS["research-roster"]), read_json(RECORDS["profile-priorities"])
        for npc in ready:
            digest, meta, (entry, _) = digests[npc], metas[npc], entries[npc]
            friendly, evidence = reaction(digest)
            side = " and ".join(friendly) if friendly else "unverified-faction"
            source = f"Reviewed adult {side} identity; {meta['summary'].rstrip('.')}; no Scout sighting claimed"
            lines = sum(len(pile) for pile in entry["lines"].values())
            backlog["completed"].append({
                "npc_id": npc, "name": digest["name"], "zone": meta["zone"], "source": source,
                "research_notes": research, "written_lines": lines, "personal_recordings": 0,
                "status": "written_complete_audio_pending", "recording_voice": digest["recording_voice"],
                "audio_note": AUDIO_NOTE,
            })
            for key in ("authored_count", "written_complete_count", "awaiting_signature_audio_count", "remaining_count"):
                backlog[key] += 1
            pending = [row for row in backlog["remaining"] if row.get("npc_id") == npc]
            if pending:
                backlog["remaining"] = [row for row in backlog["remaining"] if row.get("npc_id") != npc]
                backlog["unprofiled_count"] -= 1
                backlog["remaining_count"] -= 1
            coverage["entries"].append({
                "npc_id": npc, "name": digest["name"], "zone": meta["zone"], "race_ids": [digest["race_id"]],
                "public_friendly_factions": friendly, "reaction_evidence": evidence, "source_url": digest["source_url"],
            })
            for name in friendly or ["unverified"]:
                coverage["faction_counts"][name] = coverage["faction_counts"].get(name, 0) + 1
            race = str(digest["race_id"])
            coverage["npc_race_counts"][race] = coverage["npc_race_counts"].get(race, 0) + 1
            coverage["zone_counts"][meta["zone"]] = coverage["zone_counts"].get(meta["zone"], 0) + 1
            coverage["authored_profiles"] += 1
            coverage["awaiting_signature_audio_profiles"] += 1
            roster.append({"npc_id": npc, "name": digest["name"], "zone": meta["zone"], "source": source,
                           "research_notes": research})
            priorities["priorities"].append({"npc_id": npc, "name": digest["name"], "zone": meta["zone"],
                                             "route": meta["route"], "reason": meta["summary"]})
        backlog["as_of"] = coverage["as_of"] = args.as_of
        write_json(RECORDS["backlog"], backlog)
        write_json(RECORDS["coverage"], coverage)
        write_json(RECORDS["research-roster"], roster)
        write_json(RECORDS["profile-priorities"], priorities)

        names = [digests[npc]["name"] for npc in ready]
        zones = sorted({metas[npc]["zone"] for npc in ready})
        listed = ", ".join(names[:8]) + (f" and {len(names) - 8} more" if len(names) > 8 else "")
        line = (f"- Add {len(ready)} profiles ({', '.join(zones[:6])}{' and more' if len(zones) > 6 else ''}): "
                f"{listed}. Their lines are queued for recording. Research: {research}.")
        log_path = ROOT / "CHANGELOG.md"
        log = log_path.read_text(encoding="utf-8").replace(CRLF, "\n")
        head = "# Unreleased\n\n"
        write(log_path, log.replace(head, head + line + "\n\n", 1) if head in log else head + line + "\n\n" + log)

    if skips:
        skipped = read_json(RECORDS["skipped"], {
            "scope": "Catalog NPCs reviewed and left without an entry, with the reason. A skip is not permanent: "
                     "a new recorded voice or new evidence can bring an NPC back.", "skipped": []})
        have = {row["npc_id"] for row in skipped["skipped"]}
        for npc in skips:
            if npc not in have:
                reason = json.loads((folder / f"{npc}.skip.json").read_text(encoding="utf-8"))["reason"]
                skipped["skipped"].append({"npc_id": npc, "name": digests[npc].get("name"),
                                           "race": digests[npc].get("race_name"), "flags": digests[npc].get("flags", []),
                                           "reason": reason, "as_of": args.as_of})
        write_json(RECORDS["skipped"], skipped)

    tests = subprocess.run([sys.executable, str(ROOT / "tools" / "tests" / "smoke.py")], capture_output=True, text=True)
    if tests.returncode != 0 or "PASS" not in tests.stdout:
        for path, data in before.items():
            if data is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(data)
        print(tests.stdout[-1500:], tests.stderr[-1500:])
        sys.exit("merge: the smoke tests failed; every file was put back")

    done = folder.parent / "merged" / args.name
    done.mkdir(parents=True, exist_ok=True)
    for npc in ready + skips:
        for path in folder.glob(f"{npc}.*"):
            shutil.move(str(path), str(done / path.name))
    print(f"merged {len(ready)} profiles, recorded {len(skips)} skips; smoke tests pass")


if __name__ == "__main__":
    main()
