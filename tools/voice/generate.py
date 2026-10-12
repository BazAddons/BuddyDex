#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Records buddies' lines with ElevenLabs text to speech.

    .venv/bin/python tools/voice/generate.py poke:1 poke:2 greet:5
    .venv/bin/python tools/voice/generate.py --all          (every Mini Me line)
    .venv/bin/python tools/voice/generate.py --npc --all --voice female
    .venv/bin/python tools/voice/generate.py --lore 9859 --all --voice female

Each argument is a moment and the line's number in its pile (1-based): from
Data/Lines.lua (the Mini Me), or with --npc Data/NpcLines.lua (every friend
who comes along), or with --lore <npcID> that friend's own lines in
Data/Lore.lua. Friends of a race with recorded voices (Core/Voice.lua
RACE_VOICES) speak in the pack's voice for their race and sex, so record a
friend's own lines in that voice: Auctioneer Lympkin is a gnome woman,
--voice female. A line with fill-ins ({name}, {zone}...) can't be recorded as
written: its `say` field in Data/Lines.lua is recorded instead (the same line
without the fill-in; the bubble still shows the full text), and without one
it is skipped. Files land in voice/<voice>/<moment>_<n>.ogg (npc_<moment>_<n>.ogg,
lore<npcID>_<moment>_<n>.ogg) with a
manifest.json beside them that maps each file to its line and model; a file
already recorded with the same model is never recorded again (that would
spend credits twice), one from another model is.

Eleven v3 (the default) takes emotion tags in the text: "[excited] Wheee!".
A line's own tone comes from its `tone` field in Data/Lines.lua (the game
ignores it: the bubble never shows a tag); else its moment's (TONES below).

Clips are mono Ogg Vorbis at 22.05 kHz, about 36 kbps: speech needs no more,
and the voice pack stays small enough to keep growing (the user heard no
difference from 128 kbps MP3). ElevenLabs sends raw
PCM at that rate, encoded once (soundfile, in the project's venv).
--convert turns older MP3 recordings into the same.

The API key comes from the ELEVENLABS_API_KEY environment variable or
~/.config/azerbuddy/elevenlabs-api-key.rtf, and is never printed.
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import zlib

import numpy as np
import soundfile as sf
from lupa.lua51 import LuaRuntime

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KEY_FILE = os.path.expanduser("~/.config/azerbuddy/elevenlabs-api-key.rtf")
# The gnome voices (user, 2026-10-10), for male and female Mini Mes: the male
# from the Voice Library (Grimblewood Thornwhisker), the female designed for
# BuddyDex with Voice Design ("tinkerer 3": high, slightly raspy, British, snarky).
# "male" and "female" are the gnome voices (the Mini Me's, and gnome
# friends'); other races' friends have their own (Core/Voice.lua RACE_VOICES).
VOICES = {
    "male": "ouL9IsyrSnUkCmfnD02u", "female": "syFkX6FF9X5Ae3tA21pD",
    "human-male": "O7V4YABJUNMVqaNkOPe8",      # BuddyDex Human Male (Steady)
    "human-female": "PlKpB8vhnGrFk9fhJGWb",    # BuddyDex Human Female (Guard)
    "dwarf-male": "tNPIWbrnyCsbmVIg3tPK",      # BuddyDex Dwarf Male (Mountaineer)
    "dwarf-female": "aRtvtMA33YE3hteCIrqs",    # BuddyDex Dwarf Female (Barmaid)
    "nightelf-male": "I9kX73xcHhkTOd7JNhet",   # BuddyDex Night Elf Male (Druid)
    "nightelf-female": "XcBDzfqZip1cdcLC3B2W", # BuddyDex Night Elf Female (Priestess)
    "skyborne-male": "8chV49fDd6WKeqeufgPU",   # BuddyDex Skyborne Male (Windshaper)
    "skyborne-female": "lQ79RJ1oEygPMVWvoXTH", # BuddyDex Skyborne Female (Scholar)
}
MODEL = "eleven_v3"
RATE = 22050                 # Hz: ElevenLabs' pcm_22050, kept for the clips
FORMAT = f"pcm_{RATE}"
QUALITY = 1.0                # soundfile's Vorbis compression level: about 36 kbps mono at 22 kHz

# How each moment is delivered when its line names no tone of its own: a
# tag, or a list a line picks from by its text (the same line always gets
# the same tone, the pile gets a mix). Eleven v3 reads these as emotion
# tags; other models would say them aloud, so they are only sent to v3.
TONES = {
    "greet": ["[cheerfully]", "[excited]", "[warmly]"], "greetMorning": ["[cheerfully]", "[yawns]"],
    "greetAfternoon": "[cheerfully]", "greetEvening": "[warmly]", "greetNight": "[softly]",
    "reload": "[confused]", "poke": ["[playfully]", "[annoyed]", "[surprised]", "[giggles]"],
    "pokeMany": ["[exasperated]", "[annoyed]", "[groans]"],
    "idle": ["[curious]", "[thoughtfully]", "[mischievously]", "[cheerfully]"],
    "levelUp": ["[excited]", "[overjoyed]", "[proudly]"], "maxLevel": "[overjoyed]",
    "died": ["[groans]", "[sighs]", "[dramatically]"], "alive": "[relieved]",
    "quest": ["[proudly]", "[cheerfully]", "[excited]"], "questAccepted": "[eagerly]",
    "zone": ["[curious]", "[excited]", "[impressed]"], "gear": "[delighted]",
    "newFriend": "[happily]", "tier": "[delighted]", "buddy": "[overjoyed]",
    "away": "[sleepy]", "back": "[startled]", "rest": "[contentedly]",
    "combatStart": "[shouting]", "combatMid": ["[excited]", "[shouting]"],
    "combatLong": ["[encouragingly]", "[nervously]"], "lowHealth": ["[panicked]", "[nervously]"],
    "combatEnd": ["[triumphantly]", "[relieved]", "[laughs]", "[proudly]"],
    "taxi": "[excited]", "landed": "[relieved]",
    "mount": "[excited]", "loot": "[excited]", "mail": "[excited]", "bagsFull": "[sighs]",
    "group": "[happily]", "dungeon": "[nervously]", "hearth": "[cheerfully]", "seeFriend": "[happily]",
    "learned": "[impressed]", "waveBack": "[cheerfully]", "danceAlong": "[excited]",
    "cheerAlong": "[excited]", "laughAlong": "[laughs]", "thanked": "[warmly]", "hugged": "[warmly]",
    "kissed": "[flustered]", "comforted": "[softly]", "rudeBack": "[indignant]", "sleepToo": "[sleepy]",
    "chickenBack": "[defensively]", "roarBack": "[playfully]",
}


def api_key():
    key = os.environ.get("ELEVENLABS_API_KEY")
    if key:
        return key.strip()
    raw = open(KEY_FILE, encoding="latin-1").read()
    # The key file is RTF: drop its control groups and words, keep the text.
    text = re.sub(r"\{\\\*[^{}]*\}", " ", raw)
    text = re.sub(r"\\[a-zA-Z]+-?\d* ?", " ", text).replace("{", " ").replace("}", " ")
    found = re.findall(r"\bsk_[A-Za-z0-9]{20,}\b", text)
    if len(found) != 1:
        sys.exit("generate: couldn't find exactly one API key in the key file")
    return found[0]


# Where each kind of line lives: the data file, the piles in it (a Lua
# expression on NS), and the prefix of its clips' file names.
SOURCES = {
    "mini": ("Lines.lua", "NS.Lines", ""),
    "npc": ("NpcLines.lua", "NS.NpcLines", "npc_"),
}


def source_of(name):
    """"mini", "npc" or "lore:<npcID>": what to record."""
    if name in SOURCES:
        return SOURCES[name]
    npc_id = int(name.partition(":")[2])
    return ("Lore.lua", f"(NS.Lore[{npc_id}] or {{}}).lines or {{}}", f"lore{npc_id}_")


def load_lines(source="mini"):
    file, piles_expr, _ = source_of(source)
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("NS = {}")
    lua.execute("assert(loadfile([[%s]]))('BuddyDex', NS)" % os.path.join(ROOT, "Data", file))
    piles = {}
    flatten = lua.eval("""function(pile)
        local texts, tones, says = {}, {}, {}
        for i, line in ipairs(pile) do
            texts[i] = type(line) == 'table' and line[1] or line
            tones[i] = type(line) == 'table' and line.tone or false
            says[i] = type(line) == 'table' and line.say or false
        end
        return texts, tones, says
    end""")
    for moment, pile in lua.eval(piles_expr).items():
        texts, tones, says = flatten(pile)
        piles[moment] = [(texts[i], tones[i] or None, says[i] or None) for i in range(1, len(texts) + 1)]
    return piles


def write_ogg(path, samples, rate):
    sf.write(path, samples, rate, format="OGG", subtype="VORBIS", compression_level=QUALITY)
    return os.path.getsize(path)


def record(key, voice_id, text, path, model):
    body = json.dumps({"text": text, "model_id": model}).encode()
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={FORMAT}",
        data=body, method="POST",
        headers={"xi-api-key": key, "Content-Type": "application/json"})
    # Several voices may record at once: too many requests at a time (429)
    # waits and tries again; anything else stops the run.
    for attempt in range(6):
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                pcm = response.read()
            break
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", "replace")[:300]
            if error.code != 429 or attempt == 5:
                sys.exit(f"generate: ElevenLabs said {error.code}: {detail}")
            time.sleep(5 * (attempt + 1))
    # Raw 16-bit little-endian mono PCM.
    samples = np.frombuffer(pcm[: len(pcm) // 2 * 2], dtype="<i2").astype("float32") / 32768
    return write_ogg(path, samples, RATE)


def halve(samples):
    """44.1 kHz to 22.05 kHz: a short low-pass, then every other sample."""
    samples = samples[: len(samples) // 2 * 2]
    kernel = np.array([1, 4, 6, 4, 1], dtype="float32") / 16
    return np.convolve(samples, kernel, mode="same")[::2]


def convert(voice):
    """Turns a voice's MP3 recordings into the same Ogg clips new ones are."""
    folder = os.path.join(ROOT, "voice", voice)
    manifest_path = os.path.join(folder, "manifest.json")
    manifest = json.load(open(manifest_path)) if os.path.exists(manifest_path) else {}
    before = after = count = 0
    for name in sorted(os.listdir(folder)):
        if not name.endswith(".mp3"):
            continue
        source = os.path.join(folder, name)
        data, rate = sf.read(source, dtype="float32", always_2d=True)
        samples = data.mean(axis=1)
        while rate > RATE * 1.5:
            samples, rate = halve(samples), rate // 2
        target = name[:-4] + ".ogg"
        before += os.path.getsize(source)
        after += write_ogg(os.path.join(folder, target), samples, rate)
        if name in manifest:
            manifest[target] = manifest.pop(name)
        os.remove(source)
        count += 1
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
    print(f"{voice}: {count} clips, {before // 1024} KB of MP3 to {after // 1024} KB of Ogg")


def lua_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_lua_manifest():
    """voice/Manifest.lua for the BuddyDex Voice pack: each voice's clips,
    keyed by the line's exact text, so an edited line never plays stale audio."""
    out = [
        "-- SPDX-License-Identifier: GPL-2.0-or-later",
        "-- Generated by tools/voice/generate.py from voice/<voice>/manifest.json. Don't edit.",
        "-- BuddyDex's \"Recorded voice\" (Core/Voice.lua) looks lines up here by their text.",
        "",
        "BuddyDexVoicePack = {",
        "    version = 1,",
        '    path = "Interface\\\\AddOns\\\\BuddyDex_Voice\\\\",',
        "    voices = {",
    ]
    total, stale = 0, 0
    sources = {}

    def current(source, moment, line):
        if source not in sources:
            sources[source] = {(m, i + 1): text for m, pile in load_lines(source).items()
                               for i, (text, _, _) in enumerate(pile)}
        return sources[source].get((moment, line))
    for voice in sorted(VOICES):
        path = os.path.join(ROOT, "voice", voice, "manifest.json")
        if not os.path.exists(path):
            continue
        manifest = json.load(open(path))
        out.append(f"        [{lua_string(voice)}] = {{")
        for name in sorted(manifest, key=lambda n: (manifest[n]["moment"], manifest[n]["line"])):
            if not os.path.exists(os.path.join(ROOT, "voice", voice, name)):
                continue
            entry = manifest[name]
            # A line edited or moved since it was recorded: its clip is out.
            if current(entry.get("source", "mini"), entry["moment"], entry["line"]) != entry["text"]:
                stale += 1
                continue
            out.append(f'            [{lua_string(manifest[name]["text"])}] = "{voice}\\\\{name}",')
            total += 1
        out.append("        },")
    out += ["    },", "}", ""]
    with open(os.path.join(ROOT, "voice", "Manifest.lua"), "w") as f:
        f.write("\n".join(out))
    print(f"voice/Manifest.lua: {total} clips" + (f" ({stale} out of date, left out)" if stale else ""))


def main():
    parser = argparse.ArgumentParser(description="Record buddies' lines with ElevenLabs.")
    parser.add_argument("lines", nargs="*", help="moment:number, e.g. poke:2")
    parser.add_argument("--all", action="store_true", help="every line (fill-ins need a say text)")
    parser.add_argument("--npc", action="store_true", help="the general friend lines (Data/NpcLines.lua)")
    parser.add_argument("--lore", type=int, metavar="NPCID", help="a friend's own lines (Data/Lore.lua)")
    parser.add_argument("--voice", default="male", choices=sorted(VOICES))
    parser.add_argument("--model", default=MODEL, help="ElevenLabs model (default %(default)s)")
    parser.add_argument("--manifest", action="store_true", help="only rewrite voice/Manifest.lua")
    parser.add_argument("--convert", action="store_true", help="turn MP3 recordings into Ogg clips")
    args = parser.parse_args()
    if args.convert:
        for voice in sorted(VOICES):
            if os.path.isdir(os.path.join(ROOT, "voice", voice)):
                convert(voice)
        write_lua_manifest()
        return
    if args.manifest:
        write_lua_manifest()
        return

    source = "npc" if args.npc else f"lore:{args.lore}" if args.lore else "mini"
    prefix = source_of(source)[2]
    piles = load_lines(source)
    wanted = []
    if args.all:
        for moment in sorted(piles):
            wanted += [(moment, i + 1) for i in range(len(piles[moment]))]
    for spec in args.lines:
        moment, _, number = spec.partition(":")
        if moment not in piles or not number.isdigit() or not 1 <= int(number) <= len(piles[moment]):
            sys.exit(f"generate: no line {spec}")
        wanted.append((moment, int(number)))
    if not wanted:
        parser.print_help()
        return

    out_dir = os.path.join(ROOT, "voice", args.voice)
    os.makedirs(out_dir, exist_ok=True)
    manifest_path = os.path.join(out_dir, "manifest.json")
    manifest = json.load(open(manifest_path)) if os.path.exists(manifest_path) else {}
    key = api_key()
    characters = 0
    for moment, number in wanted:
        text, tone, say = piles[moment][number - 1]
        name = f"{prefix}{moment}_{number}.ogg"
        path = os.path.join(out_dir, name)
        spoken = say or text
        if re.search(r"\{\w+\}", spoken):
            print(f"skip   {name}: has a fill-in and no say text")
            continue
        made = manifest.get(name, {})
        if (os.path.exists(path) and made.get("model", "eleven_multilingual_v2") == args.model
                and made.get("text") == text and made.get("say") == say):
            print(f"have   {name}")
            continue
        if args.model == "eleven_v3":
            if not tone:
                tone = TONES.get(moment)
                if isinstance(tone, list):
                    tone = tone[zlib.crc32(text.encode()) % len(tone)]
            if tone:
                spoken = f"{tone} {spoken}"
        size = record(key, VOICES[args.voice], spoken, path, args.model)
        characters += len(spoken)
        manifest[name] = {"source": source, "moment": moment, "line": number, "text": text, "say": say,
                          "spoken": spoken, "model": args.model}
        print(f"made   {name}  {size // 1024} KB  {spoken}")
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2, sort_keys=True)
    print(f"done: {characters} characters sent")
    write_lua_manifest()


if __name__ == "__main__":
    main()
