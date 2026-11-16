#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Gathers what the game says about an NPC, for writing its BuddyDex entry.

    python tools/profiles/research.py 289 2918         these NPCs
    python tools/profiles/research.py --todo           every catalog NPC without an entry
    python tools/profiles/research.py --todo --list    only list them

For each NPC it reads Warcraft DB's Forever data (the NPC, the quests it
starts and ends, what it sells and teaches) and, for Classic-era quests,
classicdb.ch's progress and completion text. Raw responses are cached, so
a second run fetches nothing. It then writes two files per NPC under the
work folder (outside the repository, like the earlier research caches):

    digest/<npcID>.json   the facts, for tools/profiles/check.py and merge.py
    digest/<npcID>.md     the same facts as a brief for the writer

The digest also settles what a writer must not guess: the NPC's race and
sex (from its display, Data/NpcSounds.lua), so its recording voice, and
flags for an NPC that shouldn't get an entry as it stands (a child, a race
with no recorded voice, hostile to both factions, not a humanoid).

Public data is evidence, not proof: a friendly listing doesn't show an NPC
can't be attacked, and live eligibility checks in the addon still apply.
"""
import argparse
import html
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
WORK = Path("C:/Users/brett/BuddyDex-builds/profiles-pending")
API = "https://forever.warcraftdb.com/api/data/node"
CLASSIC = "https://classicdb.ch/"
CLASSIC_QUEST_MAX = 10000   # quest IDs below this are Classic-era and on classicdb.ch
QUEST_CAP = 14              # quests read per NPC, the ones it starts first
PAUSE = 0.15                # seconds between requests

# The recording voice for a race (ChrRaces ID) and sex (0 male, 1 female),
# as Core/Voice.lua RACE_VOICES routes them.
RACES = {1: "human", 2: "orc", 3: "dwarf", 4: "nightelf", 5: "forsaken", 6: "tauren",
         7: "", 8: "troll", 9: "goblin", 95: "skyborne", 96: "skyborne"}


def voice_for(race, sex):
    if race not in RACES or sex not in (0, 1):
        return None
    name = "female" if sex else "male"
    return f"{RACES[race]}-{name}" if RACES[race] else name


def fetch(url, path, binary=False):
    """The cached response for a URL, fetching it once. None for a 404."""
    path = Path(path)
    if path.exists():
        data = path.read_bytes()
        return None if data == b"404" else data
    path.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (BuddyDex research)"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=40) as response:
                data = response.read()
            break
        except urllib.error.HTTPError as error:
            if error.code == 404:
                data = b"404"
                break
            if attempt == 3:
                raise
            time.sleep(3 * (attempt + 1))
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            if attempt == 3:
                raise
            time.sleep(3 * (attempt + 1))
    path.write_bytes(data)
    time.sleep(PAUSE)
    return None if data == b"404" else data


def text_of(markup):
    """Plain text from the API's HTML snippets."""
    if not markup:
        return ""
    markup = re.sub(r"<br\s*/?>", "\n", str(markup))
    markup = re.sub(r"<[^>]+>", "", markup)
    return re.sub(r"[ \t]+", " ", html.unescape(markup)).strip()


def bodies():
    """display -> (race, sex), from Data/NpcSounds.lua."""
    source = (ROOT / "Data" / "NpcSounds.lua").read_text(encoding="utf-8")
    packed = re.search(r"bodies\s*=\s*\[\[(.*?)\]\]", source, re.S).group(1)
    return {int(d): (int(r), int(s)) for d, r, s in re.findall(r"(\d+):(\d+):(\d)", packed)}


def children():
    """The NPC IDs and displays Data/NpcEligibility.lua excludes as children."""
    source = (ROOT / "Data" / "NpcEligibility.lua").read_text(encoding="utf-8")
    ids_block = source[source.index("children = {"):source.index("childDisplays")]
    displays_block = source[source.index("childDisplays"):]
    return ({int(n) for n in re.findall(r"\[(\d+)\]\s*=", ids_block)},
            {int(n) for n in re.findall(r"\[(\d+)\]\s*=\s*true", displays_block)})


def written():
    source = (ROOT / "Data" / "Lore.lua").read_text(encoding="utf-8")
    return {int(n) for n in re.findall(r"^    \[(\d+)\] = \{", source, re.M)}


def todo():
    """Catalog NPCs without an entry, as (npcID, name)."""
    catalog = json.loads((ROOT / "docs" / "catalog" / "buddydex-candidates.json").read_text(encoding="utf-8"))
    have = written()
    return [(entry["npc_id"], entry["name"]) for group in catalog["candidates"]
            for entry in group["entries"] if entry["npc_id"] not in have]


def classic_texts(quest_id, raw):
    """A Classic quest's progress and completion text, from classicdb.ch."""
    page = fetch(f"{CLASSIC}?quest={quest_id}", raw / f"quest-{quest_id}-classic.html")
    if not page:
        return "", ""
    page = page.decode("utf-8", "replace")
    found = []
    for part in ("progress", "completion"):
        match = re.search(r'<div id="%s"[^>]*>(.*?)</div>' % part, page, re.S)
        found.append(text_of(match.group(1)) if match else "")
    return tuple(found)


def quest(quest_id, raw):
    data = fetch(f"{API}/quest/{quest_id}", raw / f"quest-{quest_id}.json")
    if not data:
        return None
    fields = json.loads(data)["data"]
    progress, completion = classic_texts(quest_id, raw) if quest_id < CLASSIC_QUEST_MAX else ("", "")
    rewards = fields.get("rewards") or {}
    given = [f"{item.get('quantity') or 1} {item['name']}" for item in rewards.get("items") or [] if item.get("name")]
    choice = [item["name"] for item in rewards.get("choice_items") or [] if item.get("name")]
    return {
        "rewards": given, "reward_choices": choice,
        "id": quest_id, "name": fields.get("name"), "level": fields.get("level"),
        "side": fields.get("side"), "zone": fields.get("zone"),
        "starts": text_of(fields.get("starts")), "ends": text_of(fields.get("ends")),
        "objective": text_of(fields.get("log_description")),
        "description": text_of(fields.get("quest_description")),
        "progress": progress, "completion": completion,
    }


def tab(npc, slug, raw):
    data = fetch(f"{API}/npc/{npc}/tab/{slug}", raw / f"{slug}.json")
    return json.loads(data).get("rows", []) if data else []


def digest(npc, body_of, child_ids, child_displays, learned):
    raw = WORK / "raw" / str(npc)
    data = fetch(f"{API}/npc/{npc}", raw / "npc.json")
    if not data:
        return {"npc_id": npc, "flags": ["missing"], "source_url": f"{API}/npc/{npc}"}
    node = json.loads(data)
    fields, extra = node["data"], node.get("extra") or {}

    race = re.search(r"/data/race/(\d+)\">([^<]+)<", fields.get("race") or "")
    race_id, race_name = (int(race.group(1)), race.group(2)) if race else (None, text_of(fields.get("race")) or None)
    reactions = {side: kind for side, kind in
                 re.findall(r"faction-(alliance|horde)\.webp[^>]*>\s*(\w+)\s*</span>", fields.get("reaction") or "")}
    model = (extra.get("models") or [{}])[0]
    display, m2 = model.get("id"), model.get("m2_file_data_id")
    body = body_of.get(display)
    if body:
        learned.setdefault(m2, body)
    elif m2 in learned and race_id == learned[m2][0]:
        body = learned[m2]     # a display NpcSounds doesn't list, on a model it does
    pins = (extra.get("npc_map") or {}).get("pins") or []
    floors = (extra.get("npc_map") or {}).get("floors") or []
    counts = {t["slug"]: t.get("count", 0) for t in node.get("tabs", [])}

    starts = tab(npc, "starts", raw) if counts.get("starts") else []
    ends = tab(npc, "ends", raw) if counts.get("ends") else []
    order = [row["id"] for row in starts] + [row["id"] for row in ends if row["id"] not in {r["id"] for r in starts}]
    quests = [q for q in (quest(q, raw) for q in order[:QUEST_CAP]) if q]
    sells = [row.get("name") for row in tab(npc, "sells", raw)] if counts.get("sells") else []
    teaches = [row.get("name") for row in tab(npc, "teaches", raw)] if counts.get("teaches") else []

    voice = voice_for(*body) if body else None
    flags = []
    if npc in child_ids or display in child_displays:
        flags.append("child")
    if fields.get("creature_type") != "Humanoid":
        flags.append("not_humanoid")
    if reactions and not any(kind in ("Friendly", "Neutral") for kind in reactions.values()):
        flags.append("hostile")
    if not reactions:
        flags.append("reaction_unknown")
    if not voice:
        flags.append("no_voice")
    return {
        "npc_id": npc, "name": fields.get("name"), "title": fields.get("title"),
        "level": fields.get("level"), "classification": fields.get("classification"),
        "creature_type": fields.get("creature_type"), "services": fields.get("services"),
        "race_id": race_id, "race_name": race_name, "reactions": reactions,
        "zone": floors[0]["name"] if floors else None,
        "pin": [round(pins[0]["u"] * 100, 1), round(pins[0]["v"] * 100, 1)] if pins else None,
        "display": display, "m2": m2, "body": list(body) if body else None,
        "recording_voice": voice, "flags": flags,
        "starts": [row["id"] for row in starts], "ends": [row["id"] for row in ends],
        "quests": quests, "quests_total": len(order), "sells": sells, "sells_total": counts.get("sells", 0),
        "teaches": teaches, "teaches_total": counts.get("teaches", 0),
        "source_url": f"{API}/npc/{npc}",
    }


def brief(d):
    """The digest as a brief for the writer."""
    if "missing" in d["flags"]:
        return f"# {d['npc_id']}: not in Warcraft DB's Forever data\n"
    sex = {0: "male", 1: "female"}.get((d["body"] or [None, None])[1], "sex unknown")
    reaction = ", ".join(f"{side.title()} {kind}" for side, kind in d["reactions"].items()) or "not listed"
    out = [
        f"# {d['npc_id']} {d['name']}" + (f" <{d['title']}>" if d["title"] else ""),
        "",
        f"- Race and sex: {d['race_name'] or 'not listed'}, {sex} (display {d['display']})",
        f"- Level {d['level']}" + (f", {d['classification']}" if d["classification"] else "")
        + (f"; services: {d['services']}" if d["services"] else ""),
        f"- Reaction: {reaction}",
        f"- Map pin: {d['zone'] or 'none'}" + (f" ({d['pin'][0]}, {d['pin'][1]})" if d["pin"] else "")
        + ". A city NPC's pin can fall on the zone around the city; trust quest text over the pin.",
        f"- Recording voice: {d['recording_voice'] or 'NONE'}",
        f"- Flags: {', '.join(d['flags']) or 'none'}",
        f"- Source: {d['source_url']}",
    ]
    for q in d["quests"]:
        role = " and ".join(part for part, on in (("starts", q["id"] in d["starts"]), ("ends", q["id"] in d["ends"])) if on)
        out += ["", f"## Quest {q['id']}: {q['name']} ({role}; level {q['level']}, {q['side']}, {q['zone']})",
                f"Given by {q['starts'] or '?'}, turned in to {q['ends'] or '?'}."]
        for label in ("objective", "description", "progress", "completion"):
            if q[label]:
                out.append(f"{label.title()}: {q[label]}")
        if q.get("rewards") or q.get("reward_choices"):
            parts = [", ".join(q.get("rewards") or [])]
            if q.get("reward_choices"):
                parts.append("a choice of " + ", ".join(q["reward_choices"]))
            out.append("Rewards: " + "; ".join(part for part in parts if part))
    if d["quests_total"] > len(d["quests"]):
        out += ["", f"({d['quests_total'] - len(d['quests'])} more quests not read.)"]
    if d["sells"]:
        out += ["", f"## Sells ({d['sells_total']})", ", ".join(d["sells"])]
    if d["teaches"]:
        out += ["", f"## Teaches ({d['teaches_total']})", ", ".join(d["teaches"])]
    if not (d["quests"] or d["sells"] or d["teaches"]):
        out += ["", "No quests, wares or training listed."]
    return "\n".join(out) + "\n"


def main():
    parser = argparse.ArgumentParser(description="Gather the game's facts about NPCs.")
    parser.add_argument("npcs", nargs="*", type=int, help="NPC IDs")
    parser.add_argument("--todo", action="store_true", help="every catalog NPC without an entry")
    parser.add_argument("--list", action="store_true", help="with --todo: list them and stop")
    args = parser.parse_args()
    npcs = list(args.npcs)
    if args.todo:
        pending = todo()
        if args.list:
            for npc, name in pending:
                print(npc, name)
            return
        npcs += [npc for npc, _ in pending]
    if not npcs:
        parser.print_help()
        return

    body_of = bodies()
    child_ids, child_displays = children()
    learned_path = WORK / "models.json"
    learned = {int(k): tuple(v) for k, v in json.loads(learned_path.read_text()).items()} if learned_path.exists() else {}
    out = WORK / "digest"
    out.mkdir(parents=True, exist_ok=True)
    flagged = 0
    for count, npc in enumerate(npcs, 1):
        try:
            d = digest(npc, body_of, child_ids, child_displays, learned)
        except Exception as error:   # one bad page shouldn't stop a long run
            print(f"{npc}: failed ({type(error).__name__}: {error})", file=sys.stderr, flush=True)
            continue
        (out / f"{npc}.json").write_text(json.dumps(d, indent=1), encoding="utf-8")
        (out / f"{npc}.md").write_text(brief(d), encoding="utf-8")
        blocking = [f for f in d["flags"] if f != "reaction_unknown"]
        flagged += bool(blocking)
        print(f"{count}/{len(npcs)} {npc} {d.get('name')}: {d.get('recording_voice')}"
              + (f"  FLAGS {','.join(d['flags'])}" if d["flags"] else ""), flush=True)
    learned_path.write_text(json.dumps({str(k): list(v) for k, v in learned.items()}))
    print(f"done: {len(npcs)} NPCs, {flagged} flagged")


if __name__ == "__main__":
    main()
