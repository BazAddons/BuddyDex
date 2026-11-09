#!/usr/bin/env python3
"""Build child-NPC exclusions from current model evidence, without age guesses."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import csv
import json
from pathlib import Path
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
CHILD_FILES = {124495, 124456}  # Human boy/girl, CreatureModelData 79/80.
KNOWN = {247: "Billy Maclure", 395: "Markus", 795: "Mark", 796: "Joshua",
         797: "Bo", 1366: "Adam", 1367: "Billy", 1429: "Thurman Schneider",
         4982: "Thomas", 11996: "Ashley Bridenbecker"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache-dir", type=Path, required=True)
    parser.add_argument("--db2-dir", type=Path, required=True)
    parser.add_argument("--as-of", required=True)
    args = parser.parse_args()
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    catalog = json.loads((ROOT / "docs/catalog/buddydex-candidates.json").read_text())
    wanted = {npc for group in catalog["candidates"] for npc in group["npc_ids"]}
    wanted.update(KNOWN)
    previous = ROOT / "docs/catalog/child-exclusions-source.json"
    if previous.exists():
        wanted.update(row["npc_id"] for row in json.loads(previous.read_text())["children"])
    # Pamela's child ghost uses a child model but is outside the humanoid filter.
    wanted.add(10926)

    def fetch(npc):
        path = args.cache_dir / f"{npc}.json"
        if path.exists():
            return json.loads(path.read_text())
        url = f"https://forever.warcraftdb.com/api/data/node/npc/{npc}"
        for attempt in range(2):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=25) as response:
                    node = json.load(response)
                row = {"npc_id": npc, "name": node.get("data", {}).get("name"),
                       "models": [{"display_id": m["id"], "file_id": m.get("m2_file_data_id")}
                                  for m in node.get("extra", {}).get("models", [])]}
                path.write_text(json.dumps(row) + "\n")
                return row
            except urllib.error.HTTPError as err:
                if err.code == 404:
                    return {"npc_id": npc, "error": "HTTP 404; availability/model unverified"}
                failure = f"HTTP {err.code}"
            except (OSError, ValueError, KeyError) as err:
                failure = type(err).__name__
            if not attempt:
                time.sleep(1)
        return {"npc_id": npc, "error": failure}

    rows = []
    with ThreadPoolExecutor(max_workers=4) as pool:
        jobs = {pool.submit(fetch, npc): npc for npc in sorted(wanted)}
        for future in as_completed(jobs):
            rows.append(future.result())
            if len(rows) % 200 == 0:
                print(f"Checked {len(rows)}/{len(wanted)} candidate identities", flush=True)
    displays = set()
    with (args.db2_dir / "CreatureModelData.csv").open(encoding="utf-8-sig", newline="") as f:
        child_models = {int(r["ID"]) for r in csv.DictReader(f) if int(r["FileDataID"]) in CHILD_FILES}
    assert {79, 80} <= child_models
    with (args.db2_dir / "CreatureDisplayInfo.csv").open(encoding="utf-8-sig", newline="") as f:
        displays.update(int(r["ID"]) for r in csv.DictReader(f) if int(r["ModelID"]) in child_models)
    children = {}
    for row in rows:
        matched = [m for m in row.get("models", []) if m["file_id"] in CHILD_FILES]
        if matched:
            assert row.get("name"), row
            children[row["npc_id"]] = {"npc_id": row["npc_id"], "name": row["name"],
                                        "models": matched}
            displays.update(m["display_id"] for m in matched)
    assert KNOWN.keys() <= children.keys(), "Previously verified child missing model evidence"
    for npc, name in KNOWN.items():
        assert children[npc]["name"] == name
    # Quest text establishes Pamela's childhood even while her current node is unavailable.
    children[10926] = {"npc_id": 10926, "name": "Pamela Redpath", "models": [],
                       "evidence": "Sister Pamela (5601), completion text; child ghost",
                       "source_url": "https://classicdb.ch/?quest=5601"}
    errors = [r for r in rows if "error" in r]
    evidence = {"as_of": args.as_of,
                "source": "Current Forever NPC nodes; wow_classic_beta CreatureModelData/CreatureDisplayInfo; cited Classic quest text",
                "child_model_files": sorted(CHILD_FILES), "scanned_ids": len(wanted),
                "scope": "Preserved candidate catalog plus verified children and Pamela Redpath; no level/name/height age guesses",
                "children": sorted(children.values(), key=lambda r: r["npc_id"]),
                "unverified": sorted(errors, key=lambda r: r["npc_id"])}
    (ROOT / "docs/catalog/child-exclusions-source.json").write_text(json.dumps(evidence, indent=2) + "\n")
    lua = ["-- SPDX-License-Identifier: GPL-2.0-or-later", "local ADDON_NAME, ns = ...", "",
           "-- Generated by tools/data/npc_eligibility.py; see docs/catalog/child-exclusions-source.json.",
           "-- Child identities/models only. Level, short stature and personal names do not establish age.",
           "local Policy = { children = {"]
    lua.extend(f"    [{npc}] = {json.dumps(row['name'])}," for npc, row in sorted(children.items()))
    lua += ["}, childDisplays = {", *[f"    [{display}] = true," for display in sorted(displays)], "} }",
            "ns.NpcEligibility = Policy", "",
            "function Policy.IsChild(npcID, display)",
            "    local plain = ns.Util.Plain",
            "    npcID, display = tonumber(plain(npcID)), tonumber(plain(display))",
            "    local archived = ns.db and ns.db.excludedChildren",
            "    return (npcID and (Policy.children[npcID] ~= nil or (archived and archived[npcID] ~= nil)))",
            "        or (display and Policy.childDisplays[display]) or false", "end", ""]
    text = "\n".join(lua)
    for path in [ROOT / "Data/NpcEligibility.lua", ROOT / "tools/BuddyDexScout/Data/NpcEligibility.lua"]:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    print(f"Verified {len(children)} child NPC IDs and {len(displays)} child displays; {len(errors)} unresolved nodes", flush=True)


if __name__ == "__main__":
    main()
