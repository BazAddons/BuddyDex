#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Checks drafted BuddyDex entries before they go into Data/Lore.lua.

    python tools/profiles/check.py <folder>            every draft in the folder
    python tools/profiles/check.py <folder> 289 2918   these NPCs

A draft is three files in the folder (tools/profiles/WRITER.md):

    <npcID>.lua         the entry as it will sit in Data/Lore.lua, facts comment first
    <npcID>.meta.json   {"zone", "route", "summary"}: where they are and what the entry rests on
    <npcID>.md          the research note: sources, what is fact, what is ours

or one file, <npcID>.skip.json {"reason"}, for an NPC that shouldn't have an
entry. The checks are docs/LORE.md's rules that a program can test, the same
ones tools/tests/smoke.py runs on the finished file, plus what the recorder
needs (tools/voice/backfill.py stops on a profile without an approved voice
or on a fill-in with no say text). Exits 1 if any draft fails.
"""
import json
import re
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parent.parent.parent
DIGESTS = Path("C:/Users/brett/BuddyDex-builds/profiles-pending/digest")

WRAP = 50
BUDGET = (("gossip", 3), ("bio", 6), ("backstory", 6), ("secret", 4), ("bestFriend", 3))
COLUMN = 21
FILL_INS = {"name", "zone", "level", "class", "race", "friend", "tier", "friends", "item"}
NEEDED = {"greet": 2, "idle": 2, "befriended": 1, "poke": 2}
LINE_MAX = 140
BRITISH = re.compile(r"\b(colour\w*|favour\w*|grey|armour\w*|travell\w+|honour\w*|centre|"
                     r"neighbour\w*|theatre|jewell\w+)\b")


def wrapped(text):
    """How many lines the Dex's Lore column needs, as smoke.py counts them."""
    lines, width = 1, 0
    for word in text.split():
        if width == 0:
            width = len(word)
        elif width + 1 + len(word) <= WRAP:
            width += 1 + len(word)
        else:
            lines, width = lines + 1, len(word)
    return lines if text else 0


def emotes():
    source = (ROOT / "Core" / "Friendship.lua").read_text(encoding="utf-8")
    block = source[source.index("local FRIENDLY_EMOTES = {"):source.index("local RUDE_EMOTES")]
    return set(re.findall(r"([A-Z]+) = true", block))


def moments():
    found = {"befriended"}
    for file in ("Lines.lua", "NpcLines.lua"):
        source = (ROOT / "Data" / file).read_text(encoding="utf-8")
        found |= set(re.findall(r"^    (\w+) = \{", source, re.M))
    return found


def written():
    source = (ROOT / "Data" / "Lore.lua").read_text(encoding="utf-8")
    return {int(n) for n in re.findall(r"^    \[(\d+)\] = \{", source, re.M)}


def spoken():
    """Every line already written, for anyone: a new friend shouldn't repeat one."""
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("NS = {}")
    for file in ("Lore.lua", "Lines.lua", "NpcLines.lua"):
        lua.execute("assert(loadfile(...))('BuddyDex', NS)", str(ROOT / "Data" / file))
    collect = lua.eval("""function(ns)
        local seen = {}
        local function add(piles)
            for _, pile in pairs(piles or {}) do
                for _, line in ipairs(pile) do seen[type(line) == 'table' and line[1] or line] = true end
            end
        end
        add(ns.Lines) add(ns.NpcLines)
        for _, entry in pairs(ns.Lore) do add(entry.lines) end
        return seen
    end""")
    return set(collect(lua.eval("NS")).keys())


def words(text):
    """A line's words, for telling near-copies apart from new lines."""
    return frozenset(re.findall(r"[a-z']+", text.lower()))


def near_copy(text, known):
    """An existing line that shares most of this one's words, or None."""
    mine = words(text)
    if len(mine) < 5:
        return None
    for other, theirs in known["word_sets"].items():
        if len(mine & theirs) / len(mine | theirs) >= 0.7:
            return other
    return None


def plain(value):
    """A Lua value as Python: tables with only 1..n keys become lists."""
    if hasattr(value, "items"):
        items = {k: plain(v) for k, v in value.items()}
        if items and all(isinstance(k, int) for k in items) and sorted(items) == list(range(1, len(items) + 1)):
            return [items[i] for i in range(1, len(items) + 1)]
        return items
    return value


def load(path, npc):
    """The entry in a draft .lua file, or raises ValueError saying what's wrong."""
    source = path.read_text(encoding="utf-8")
    if "\t" in source:
        raise ValueError("tabs: indent with four spaces")
    if not source.lstrip("\n").startswith("    -- "):
        raise ValueError("must open with the facts comment, indented four spaces: '    -- Name <Title>, ...'")
    lua = LuaRuntime(unpack_returned_tuples=True)
    try:
        table = lua.execute("return {\n" + source + "\n}")
    except Exception as error:
        raise ValueError(f"not valid Lua: {error}") from None
    keys = list(table.keys())
    if keys != [npc]:
        raise ValueError(f"must hold exactly one entry, [{npc}]; found {keys}")
    return plain(table[npc]), source


def context():
    """What every check needs to know about the addon as it stands."""
    lines = spoken()
    return {"emotes": emotes(), "moments": moments(), "written": written(), "spoken": lines,
            "word_sets": {text: words(text) for text in lines if len(words(text)) >= 5}}


def check(folder, npc, known):
    """A list of what's wrong with one draft; empty if it's ready."""
    errors = []
    skip = folder / f"{npc}.skip.json"
    if skip.exists():
        try:
            if not json.loads(skip.read_text(encoding="utf-8")).get("reason"):
                errors.append("skip file needs a reason")
        except json.JSONDecodeError as error:
            errors.append(f"skip file is not JSON: {error}")
        return errors

    digest_path = DIGESTS / f"{npc}.json"
    if not digest_path.exists():
        return [f"no digest for {npc}: run tools/profiles/research.py {npc}"]
    digest = json.loads(digest_path.read_text(encoding="utf-8"))
    if npc in known["written"]:
        errors.append("Data/Lore.lua already has this NPC")
    blocking = [flag for flag in digest["flags"] if flag != "reaction_unknown"]
    if blocking:
        errors.append(f"the digest flags this NPC ({', '.join(blocking)}): write {npc}.skip.json instead")

    for suffix in (".lua", ".meta.json", ".md"):
        if not (folder / f"{npc}{suffix}").exists():
            errors.append(f"missing {npc}{suffix}")
    if errors:
        return errors

    try:
        meta = json.loads((folder / f"{npc}.meta.json").read_text(encoding="utf-8"))
        for key in ("zone", "route", "summary"):
            if not isinstance(meta.get(key), str) or not meta[key].strip():
                errors.append(f"meta.json needs a {key}")
    except json.JSONDecodeError as error:
        errors.append(f"meta.json is not JSON: {error}")
    note = (folder / f"{npc}.md").read_text(encoding="utf-8")
    if not note.startswith("## ") or "http" not in note:
        errors.append("the research note must start with '## Name (npcID)' and link its sources")

    try:
        entry, source = load(folder / f"{npc}.lua", npc)
    except ValueError as error:
        return errors + [str(error)]
    if not source.isascii():
        bad = sorted({c for c in source if ord(c) > 127})
        errors.append(f"plain ASCII only; found {' '.join(bad)}")
    first = source.lstrip("\n").split("\n")[0]
    if (digest.get("name") or "") not in first:
        errors.append(f"the facts comment must open with the NPC's name, {digest.get('name')}")
    british = BRITISH.search(re.sub(r"^\s*--.*$", "", source, flags=re.M))
    if british:
        errors.append(f"US English: {british.group(0)}")

    for key in ("quote", "gossip", "bio", "backstory", "secret", "bestFriend"):
        if not isinstance(entry.get(key), str) or not entry[key].strip():
            errors.append(f"{key} is missing")
    if errors:
        return errors
    column = 0
    for key, most in BUDGET:
        text = '"' + entry[key] + '"' if key == "bestFriend" else entry[key]
        lines = wrapped(text)
        column += lines
        if lines > most:
            errors.append(f"{key} runs {lines} lines of {WRAP} characters, {most} at most ({len(entry[key])} characters now)")
    if column > COLUMN:
        errors.append(f"gossip, bio, backstory, secret and bestFriend run {column} lines together, {COLUMN} at most")
    if len(entry["quote"]) > 200:
        errors.append(f"quote is {len(entry['quote'])} characters, 200 at most")
    for key in ("likes", "dislikes"):
        items = entry.get(key)
        if not isinstance(items, list) or not 2 <= len(items) <= 3:
            errors.append(f"{key} needs two or three items")
            continue
        for item in items:
            if not isinstance(item, str) or len(item) > 45:
                errors.append(f"{key} item over 45 characters: {item}")

    favorite = entry.get("favorite")
    if not isinstance(favorite, dict) or favorite.get("emote") not in known["emotes"]:
        errors.append(f"favorite.emote must be one of {' '.join(sorted(known['emotes']))}")
    elif not isinstance(favorite.get("hint"), str) or not 10 <= len(favorite["hint"]) <= 110:
        errors.append("favorite.hint must be a clue of 10 to 110 characters")
    if entry.get("recordingVoice") != digest["recording_voice"]:
        errors.append(f"recordingVoice must be \"{digest['recording_voice']}\"")

    piles = entry.get("lines")
    if not isinstance(piles, dict):
        return errors + ["lines is missing"]
    count, toned = 0, 0
    for moment, pile in piles.items():
        if moment not in known["moments"]:
            errors.append(f"lines.{moment} is not a moment the addon has")
            continue
        if not isinstance(pile, list) or not pile:
            errors.append(f"lines.{moment} must be a list of lines")
            continue
        for line in pile:
            count += 1
            text = line if isinstance(line, str) else (line.get(1) if isinstance(line, dict) else None)
            if not isinstance(text, str) or not text.strip():
                errors.append(f"lines.{moment}: a line needs its text first")
                continue
            if text in known.get("spoken", ()):
                errors.append(f"lines.{moment}: someone already says this exact line: {text[:60]}")
            elif "word_sets" in known:
                twin = near_copy(text, known)
                if twin:
                    errors.append(f"lines.{moment}: too close to a line someone already says (\"{twin[:60]}\"): {text[:60]}")
            if len(text) > LINE_MAX:
                errors.append(f"lines.{moment}: {len(text)} characters, {LINE_MAX} at most: {text[:50]}...")
            fills = set(re.findall(r"\{(\w+)\}", text))
            if fills - FILL_INS:
                errors.append(f"lines.{moment}: unknown fill-in {fills - FILL_INS}")
            say = line.get("say") if isinstance(line, dict) else None
            if fills and not (isinstance(say, str) and say.strip() and not re.search(r"\{\w+\}", say)):
                errors.append(f"lines.{moment}: a line with a fill-in needs a say text without one: {text[:50]}")
            tone = line.get("tone") if isinstance(line, dict) else None
            if tone is not None:
                toned += 1
                if not re.fullmatch(r"(\[[a-z][a-z ,'-]*\] ?){1,3}", tone):
                    errors.append(f"lines.{moment}: tone must be one to three tags like \"[warm] [amused]\": {tone}")
            if isinstance(line, dict):
                extra = set(line) - {1, "tone", "say", "anim", "time", "zone", "class", "min", "max", "after"}
                if extra:
                    errors.append(f"lines.{moment}: unknown fields {extra}")
    for moment, least in NEEDED.items():
        if len(piles.get(moment) or []) < least:
            errors.append(f"lines.{moment} needs at least {least}")
    if count != 15:
        errors.append(f"{count} lines of their own; write exactly 15")
    if toned < 3:
        errors.append("give at least the first greet, the first idle and the befriended line a tone")
    if not errors and "spoken" in known:
        for pile in piles.values():
            for line in pile:
                text = line if isinstance(line, str) else line.get(1)
                known["spoken"].add(text)
                known.setdefault("word_sets", {})[text] = words(text)
    return errors


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    folder = Path(sys.argv[1])
    npcs = [int(n) for n in sys.argv[2:]] or sorted(
        {int(p.name.split(".")[0]) for p in folder.iterdir() if p.name.split(".")[0].isdigit()})
    known = context()
    failed = 0
    for npc in npcs:
        errors = check(folder, npc, known)
        failed += bool(errors)
        skipped = (folder / f"{npc}.skip.json").exists() and not errors
        print(f"{npc}: {'skip' if skipped else 'ok' if not errors else 'FAIL'}")
        for error in errors:
            print(f"    {error}")
    print(f"{len(npcs) - failed} of {len(npcs)} ready")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
