#!/usr/bin/env python3
"""Refresh the authoring backlog from an installed BuddyDex Scout saved file.

python tools/refresh-npc-backlog.py --scout <BuddyDexScout.lua> --as-of YYYY-MM-DD
Only NPC identities and zones are copied; the input saved variables are read-only.
"""
import argparse
import json
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parent.parent
PRIORITY = [
    (6929, "Innkeeper Gryshka", "Orgrimmar"),
    (3310, "Doras", "Orgrimmar"),
    (3626, "Jenn Langston", "Stormwind City"),
    (279, "Morgan Pestle", "Stormwind City"),
]
# Clearly generic roles that the gameplay heuristic does not yet recognize.
# Do not turn them into authored exceptions just to fill the collection.
GENERIC = {14849: "Darkmoon Faire Carnie", 14991: "League of Arathor Emissary"}
FIELDS = ["quote", "likes", "dislikes", "gossip", "bio", "backstory", "secret", "bestFriend", "favorite", "lines"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scout", type=Path, required=True)
    parser.add_argument("--as-of", required=True)
    args = parser.parse_args()
    lua = LuaRuntime(unpack_returned_tuples=True)
    for rel in ["tools/tests/blizzard_api.lua", "tools/tests/mock.lua"]:
        lua.execute((ROOT / rel).read_text(encoding="utf-8"))
    ns = lua.table()
    for rel in ["Core/Namespace.lua", "Data/NpcEligibility.lua", "Data/Lore.lua", "voice/Manifest.lua", "Core/Friendship.lua"]:
        lua.execute((ROOT / rel).read_text(encoding="utf-8"), "BuddyDex", ns)
    lua.execute(args.scout.read_text(encoding="utf-8-sig"))
    roster = lua.globals().BuddyDexScoutDB.roster
    trim_rules_path = ROOT / "docs/catalog/trim-rules.json"
    generic_names = set()
    if trim_rules_path.exists():
        trim_rules = json.loads(trim_rules_path.read_text(encoding="utf-8"))
        generic_names.update(trim_rules.get("generic_names", []))
        generic_names.update(trim_rules.get("local_only_generic_names", []))
    candidates = {}
    excluded = []
    excluded_children = {npc: {"npc_id": npc, "name": name, "reason": "Child NPC; adult friendships only"}
                         for npc, name in ns.NpcEligibility.children.items()}
    for npc, entry in roster.items():
        if ns.NpcEligibility.IsChild(npc, entry.display):
            excluded_children[npc] = {"npc_id": npc, "name": entry.name, "reason": "Child NPC; adult friendships only"}
            continue
        if not (entry.reaction and entry.reaction >= 4 and not entry.attackable and entry.type == "Humanoid"):
            continue
        if npc in GENERIC or entry.name in generic_names or not ns.Friendship.IsSomeone(entry.name, npc):
            excluded.append({"npc_id": npc, "name": entry.name, "reason": "Generic role, not an individual"})
            continue
        candidates[npc] = {"npc_id": npc, "name": entry.name, "zone": entry.zone, "source": "Installed Scout record"}
    for npc, name, zone in PRIORITY:
        candidates.setdefault(npc, {"npc_id": npc, "name": name, "zone": zone, "source": "Agreed priority shortlist"})
    # Reviewed external identities keep their real names and evidence even when
    # the player has not encountered them in the Scout snapshot yet.
    research_roster = ROOT / "docs/npc-research-roster.json"
    if research_roster.exists():
        researched = json.loads(research_roster.read_text(encoding="utf-8"))
        seen = set()
        for row in researched:
            npc = row["npc_id"]
            assert isinstance(npc, int) and npc not in seen, "Duplicate/invalid researched NPC ID"
            seen.add(npc)
            if ns.NpcEligibility.IsChild(npc):
                continue
            assert ns.Friendship.IsSomeone(row["name"], npc), "Generic researched NPC"
            assert (ROOT / row["research_notes"]).is_file(), "Missing research notes"
            if npc in candidates:
                assert candidates[npc]["name"] == row["name"], "Research/Scout identity mismatch"
            else:
                candidates[npc] = dict(row)
    completed = []
    for npc, lore in ns.Lore.items():
        assert not ns.NpcEligibility.IsChild(npc), "Child profile must be removed"
        lines = [line[1] if lua.eval("type")(line) == "table" else line
                 for _, pile in lore.lines.items() for _, line in pile.items()]
        recordings = set()
        for text in lines:
            for _, voice in ns.VoicePack.voices.items():
                rel = voice[text]
                if rel and f"lore{npc}_" in rel and (ROOT / "voice" / rel.replace("\\", "/")).is_file():
                    recordings.add(rel)
        row = candidates.pop(npc, {"npc_id": npc, "source": "Existing authored profile"})
        # Unscouted authored NPC names come from their researched source notes.
        row.setdefault("name", {523: "Thor", 9859: "Auctioneer Lympkin", 352: "Dungar Longdrink", 234: "Gryan Stoutmantle"}.get(npc, str(npc)))
        row.update(written_lines=len(lines), personal_recordings=len(recordings))
        row["status"] = "complete" if all(lore[field] is not None for field in FIELDS) and 12 <= len(lines) <= 20 and len(recordings) >= 3 else "needs_completion"
        completed.append(row)
    priority = {npc: i for i, (npc, _, _) in enumerate(PRIORITY)}
    remaining = sorted(candidates.values(), key=lambda row: (priority.get(row["npc_id"], 999), row.get("zone") or "", row["name"]))
    for row in remaining:
        row["status"] = "pending_identity_and_lore_research"
        if row["npc_id"] in (6929, 3310):
            row["voice_note"] = "Custom race voice auditions requested; user selection pending"
    result = {
        "as_of": args.as_of,
        "scope": "Known priority NPCs, friendly named humanoids from the installed Scout snapshot, and individually reviewed external identities in docs/npc-research-roster.json. Candidate identity, lore and eligibility require research before authoring; public data does not replace live unit checks.",
        "completed_count": sum(row["status"] == "complete" for row in completed),
        "remaining_count": len(remaining) + sum(row["status"] != "complete" for row in completed),
        "completed": sorted(completed, key=lambda row: row["npc_id"]),
        "remaining": remaining,
        "excluded_generic": sorted(excluded, key=lambda row: row["npc_id"]),
        "excluded_children": sorted(excluded_children.values(), key=lambda row: row["npc_id"]),
    }
    catalog_path = ROOT / "docs/catalog/buddydex-candidates.json"
    if catalog_path.exists():
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        result["external_research_catalog"] = {
            "path": "docs/catalog/buddydex-candidates.json",
            "candidate_name_groups": catalog["counts"]["candidate_name_groups"],
            "policy": "Prioritize the local Scout backlog, then research external candidates. This catalog overlaps the backlog; do not add the counts. Verify identity, Forever availability and live eligibility before authoring. Same-name IDs require review, not automatic separate profiles.",
        }
    out = ROOT / "docs/npc-backlog.json"
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Backlog: {result['completed_count']} complete, {result['remaining_count']} remaining; {len(excluded)} generic roles excluded")


if __name__ == "__main__":
    main()
