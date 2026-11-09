#!/usr/bin/env python3
"""Trim the preserved Warcraft DB list and reconcile the local Scout/backlog.

python tools/build-npc-catalog.py --scout <BuddyDexScout.lua>
No network calls, game changes, automatic lore, or deletion of source records.
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs/catalog"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scout", type=Path, required=True)
    args = parser.parse_args()
    source_file = CATALOG / "warcraftdb-nonhostile-humanoids-2026-11-08.json"
    source = read(source_file)
    assert len(source["rows"]) == source["expected_rows"] == 1587
    assert len({r["npc_id"] for r in source["rows"]}) == 1587
    rules = read(CATALOG / "trim-rules.json")
    backlog = read(ROOT / "docs/npc-backlog.json")
    local = {r["npc_id"]: r for r in backlog["completed"] + backlog["remaining"]}
    lua = LuaRuntime(unpack_returned_tuples=True)
    for rel in ("tools/tests/blizzard_api.lua", "tools/tests/mock.lua"):
        lua.execute((ROOT / rel).read_text(encoding="utf-8"))
    ns = lua.table()
    for rel in ("Core/Namespace.lua", "Data/NpcEligibility.lua", "Data/Lore.lua", "Core/Friendship.lua"):
        lua.execute((ROOT / rel).read_text(encoding="utf-8"), "BuddyDex", ns)
    lua.execute(args.scout.read_text(encoding="utf-8-sig"))
    scout = lua.globals().BuddyDexScoutDB.roster
    excluded, review, retained, children = [], [], [], []
    source_ids = {r["npc_id"] for r in source["rows"]}
    seen_rule_names = set()
    for original in source["rows"]:
        row = dict(original)
        npc, name = row["npc_id"], row["name"]
        row["source"] = "Warcraft DB listing; availability and attackability unverified"
        observed = scout[npc]
        if ns.NpcEligibility.IsChild(npc, observed and observed.display):
            row["reason"] = "Child NPC; adult friendships only"
            children.append(row)
            continue
        exception = rules["named_exceptions"].get(str(npc))
        if exception:
            assert name == exception["name"]
            row["gameplay_filter_note"] = exception["reason"]
        elif name in rules["generic_names"] or not ns.Friendship.IsSomeone(name, npc):
            row["reason"] = "Generic role, unnamed creature or non-person prop"
            excluded.append(row)
            seen_rule_names.add(name)
            continue
        if name in rules["review_names"]:
            row["reason"] = rules["review_names"][name]
            review.append(row)
            continue
        retained.append(row)
    assert set(rules["generic_names"]) <= seen_rule_names, "Stale/unmatched manual exclusion"
    missing = []
    for npc, entry in local.items():
        if npc not in source_ids:
            row = {"npc_id": npc, "name": entry["name"], "source": "Existing local backlog; absent from source filter"}
            retained.append(row)
            missing.append(row)
    groups = defaultdict(list)
    for row in retained:
        npc = row["npc_id"]
        observed = scout[npc]
        if observed:
            row["scout_observed"] = True
            row["scout_name"] = observed.name
            row["zone"] = observed.zone
            row["scout_reaction"] = observed.reaction
            row["scout_attackable"] = bool(observed.attackable)
            row["name"] = observed.name
        else:
            row["scout_observed"] = False
        row["profile_status"] = local.get(npc, {}).get("status", "unresearched_external_candidate")
        groups[row["name"].casefold()].append(row)
    candidates = []
    for rows in groups.values():
        ids = sorted(r["npc_id"] for r in rows)
        candidates.append({"name": rows[0]["name"], "npc_ids": ids,
                           "same_name_variants_need_review": len(ids) > 1,
                           "scout_observed_ids": sorted(r["npc_id"] for r in rows if r["scout_observed"]),
                           "entries": rows})
    candidates.sort(key=lambda r: r["name"].casefold())
    counts = {"source_rows": len(source["rows"]), "excluded_generic_rows": len(excluded),
              "excluded_child_rows": len(children),
              "ambiguous_rows_for_review": len(review),
              "retained_source_entries": len(retained) - len(missing),
              "local_backlog_entries_missing_from_source": len(missing),
              "combined_retained_entries": len(retained), "candidate_name_groups": len(candidates),
              "same_name_groups_requiring_id_review": sum(r["same_name_variants_need_review"] for r in candidates)}
    assert counts["source_rows"] == len(excluded) + len(children) + len(review) + counts["retained_source_entries"]
    assert len({r["npc_id"] for r in retained + excluded + review + children}) == len(retained + excluded + review + children)
    assert all(npc in {r["npc_id"] for r in retained} for npc in local), "Dropped local backlog NPC"
    result = {"as_of": source["as_of"], "source_url": source["source_url"],
              "scope": "Research candidates, not a confirmed count of befriending-compatible Forever NPCs. Same-name groups are not proven duplicate people. Keep Scout profiles first.",
              "counts": counts, "candidates": candidates, "ambiguous_review": review,
              "excluded_generic": excluded, "excluded_children": children, "local_entries_missing_from_source": missing}
    (CATALOG / "buddydex-candidates.json").write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    report = ["# BuddyDex candidate catalog", "", f"Snapshot: {source['as_of']}. [Warcraft DB filtered source]({source['source_url']}).", "",
              "This is a trimmed research list, not a verified eligibility census. Neutral targets may still be attackable, faction/reputation matters, and database availability can be incomplete. Existing Scout/backlog entries remain the authoring priority.", "",
              "| Stage | Count |", "| --- | ---: |"]
    report += [f"| {key.replace('_', ' ').capitalize()} | {value:,} |" for key, value in counts.items()]
    report += ["", "The original exports are preserved. Exclusions and ambiguous identities are retained in the JSON with reasons. Multiple IDs for one name are grouped for review; no ID was silently selected or discarded.", "",
               "The external filter misses known local entries, including Jenn Langston. Their local evidence is preserved and they are added to this catalog. Two clearly personal names (Aetheen of the Gales and Lolo the Lookout) are retained with warnings about the current gameplay name heuristic; this task does not change that heuristic.", "",
               "Child NPCs are excluded from friendship and authoring. Verified identities and models are recorded in [child-exclusions-source.json](child-exclusions-source.json); small stature and low level do not imply childhood.", "",
               "## Candidate names", "", "An asterisk means multiple NPC IDs need identity/version review. Scout denotes at least one locally observed ID.", ""]
    for row in candidates:
        links = ", ".join(f"[{npc}](https://forever.warcraftdb.com/data/npc/{npc})" for npc in row["npc_ids"])
        flags = (" *" if row["same_name_variants_need_review"] else "") + (" — Scout" if row["scout_observed_ids"] else "")
        report.append(f"- **{row['name']}**{flags}: {links}")
    report += ["", "## Ambiguous identities", ""]
    report += [f"- {r['name']} ({r['npc_id']}): {r['reason']}" for r in review]
    report += ["", "## Rebuild", "", "Run `python tools/build-npc-catalog.py --scout <installed BuddyDexScout.lua>` after refreshing the local backlog. The preserved web snapshots and explicit trim rules make this pass reproducible. These research files are excluded from the addon ZIP.", ""]
    (CATALOG / "README.md").write_text("\n".join(report), encoding="utf-8")
    print(json.dumps(counts, indent=2))


if __name__ == "__main__":
    main()
