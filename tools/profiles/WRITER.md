# Writing a BuddyDex entry from a digest

This is the brief for whoever drafts new entries, person or model. `docs/LORE.md` is the writing guide and wins any disagreement; read it first, all of it. Then read two entries in `Data/Lore.lua` as the standard for tone: Thor `[523]` and Auctioneer Lympkin `[9859]`. They are short, warm and a little funny, and each is built on one hook.

## What you get

For each NPC, a digest at `C:/Users/brett/BuddyDex-builds/profiles-pending/digest/<npcID>.md`: who they are, where, their race and sex, what they sell or teach, and the text of the quests they give and take. That is what the game says. Everything else in the entry is yours to invent, as long as nothing contradicts it.

The digest can be thin, and for a city NPC its map pin can land on the zone around the city. When you need more (where exactly they stand, their gossip, who works beside them), look them up on warcraft.wiki.gg or wowhead.com/forever. Use those pages for facts, never for wording. No quest found is a research result, not a reason to invent one.

## What you write

Three files per NPC, in the folder you were given:

**`<npcID>.lua`** is the entry exactly as it will sit in `Data/Lore.lua`: four-space indent, the facts comment first, one field per line.

```lua
    -- Name <Title>, Subzone, Zone. Race, sex.
    -- Facts: what the game says about them and where it says it (quests by
    -- name, wares, the people beside them). End with what is ours: "That he
    -- has never flown is ours."
    [npcID] = {
        quote = "...",
        likes = { "...", "...", "..." },
        dislikes = { "...", "...", "..." },
        gossip = "...",
        bio = "...",
        backstory = "...",
        secret = "...",
        bestFriend = "...",
        favorite = { emote = "WAVE", hint = "..." },
        recordingVoice = "human-male",
        lines = {
            greet = { { "...", tone = "[warm]" }, "..." },
            idle = { { "...", tone = "[dry]" }, "...", "..." },
            befriended = { { "...", tone = "[pleased]" } },
            poke = { "...", "..." },
            -- seven more on the moments their job touches
        },
    },
```

**`<npcID>.meta.json`**:

```json
{"zone": "Duskwood", "route": "Hermit west of Raven Hill", "summary": "Five quests read (Ghoulish Effigy to Note to the Mayor); the hook and secret are ours."}
```

`zone` is where a player finds them, a city's own name if they are in a city. `route` is a few words on who they are and where. `summary` is one sentence on what was read and what is original.

**`<npcID>.md`** is the research note: a `## Name (npcID)` heading, then a short paragraph on what the game establishes with links to each source you used, and a short paragraph on what is original BuddyDex writing. Six to ten lines. Later writers use it to check nothing contradicts the game.

If an NPC should not have an entry, write only **`<npcID>.skip.json`** with `{"reason": "..."}`. Skip when the digest flags it (a child, no recording voice, hostile, not a humanoid), when you find it is a child or not a person, or when it has no place a player can meet it. Do not skip because the digest is thin: most NPCs have almost nothing, and that is the job.

## How to write it

1. **Find the hook.** One detail of this NPC that no other has: their name, a quest line, an odd item on their shelf, where they stand, who they stand beside. Build the whole entry on it. The gossip hints at it, the story grounds it, the backstory explains it, the secret pays it off. If your hook would fit any vendor in any town, it is not a hook yet.
2. **Keep it light.** Warm, dry, a little funny. Not earnest, not wise, not a life lesson. These people complain about the weather and their neighbors. A reader should smile once per entry.
3. **Let them sound like someone.** A gruff smith, a fussy clerk and a bored guard should not share a voice. Read the NPC's own quest text for how they talk, then write new words in that voice.
4. **Stay inside the facts.** Use the people and places the quests put near them. Invent small, personal things (a habit, a fear, a hobby), never family, deaths, wars or anything a quest could contradict. Classic-era setting plus Forever's own additions; nothing from later expansions.
5. **Short lines.** A line shows in a chat bubble and is read aloud. Most should be under 80 characters; 140 is the limit. One thought each.
6. **Fifteen lines.** Two `greet`, three `idle`, one `befriended`, two `poke`, and seven spent where their job shines: a banker on `loot`, `mail` and `bagsFull`, a flight master on `taxi` and `landed`, a trainer on `levelUp` and `learned`. Any moment in `Data/Lines.lua` works.
7. **Tones.** Give the first `greet`, the first `idle`, the `befriended` line and one job line a `tone`: one or two delivery tags in square brackets, such as `"[gruff] [amused]"`. The voice recording reads them; the bubble never shows them.
8. **Fill-ins.** `{name}`, `{zone}`, `{level}` and `{item}` are filled in for the bubble. A line that uses one needs a `say` text that reads well without it, for the recording. Use at most two per entry.
9. **Favorite emote.** Pick the one this person would actually enjoy, from the tokens `tools/profiles/check.py` lists. The hint is a clue to it, not the answer.
10. **Plain ASCII, US English**, no tabs. Straight quotes and apostrophes only; a quote inside a string is `\"`.

Things that have been done too often across the existing entries; find something else:

- a secret that they are bad at, or afraid of, the very thing they sell or teach
- "more than a customer", "more than a job" and other lines about valuing the person over the task
- advice about listening, patience, honesty or remembering names
- the word "friend" in most lines

## Check your work

```bash
python tools/profiles/check.py <your folder>
```

It tests the page budget, line count, emote, voice, fill-ins and spelling, and says what to fix. Fix until every NPC reads `ok` or `skip`. The budget is tight on purpose: the Lore column must show the whole entry without scrolling. When a field runs long, cut a sentence; do not shorten words.
