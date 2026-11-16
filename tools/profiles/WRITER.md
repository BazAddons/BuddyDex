# Writing a BuddyDex entry from a digest

This is the brief for whoever drafts new entries, person or model. `docs/LORE.md` is the writing guide and wins any disagreement; read it first, all of it. Then read two entries in `Data/Lore.lua` as the standard for tone: Thor `[523]` and Auctioneer Lympkin `[9859]`. They are short, warm and a little funny, and each is built on one hook. Match their tone, not their sentences.

## What you get

For each NPC, a digest at `C:/Users/brett/BuddyDex-builds/profiles-pending/digest/<npcID>.md`: who they are, where, their race and sex, what they sell or teach, and the text and rewards of the quests they give and take. That is what the game says. Everything else in the entry is yours to invent, as long as nothing contradicts it.

The digest is your main source. Look elsewhere (warcraft.wiki.gg, wowhead.com/forever) only for what it lacks and you need: where exactly they stand, who works beside them, their greeting. One or two lookups per NPC is usually enough. Use those pages for facts, never for wording. Whatever you take from outside the digest, link it in the research note; a fact you cannot link stays out. No quest found is a research result, not a reason to invent one.

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

**`<npcID>.md`** is the research note: a `## Name (npcID)` heading, then a short paragraph on what the game establishes with a link to each source you used, and a short paragraph on what is original BuddyDex writing. Six to ten lines. Later writers use it to check nothing contradicts the game.

If an NPC should not have an entry, write only **`<npcID>.skip.json`** with `{"reason": "..."}`. Skip when the digest flags it (a child, no recording voice, hostile, not a humanoid), when you find it is a child or not a person, or when it has no place a player can meet it. Do not skip because the digest is thin: most NPCs have almost nothing, and that is the job.

## The hook

Find one detail of this NPC that no other has, and build the whole entry on it.

- **When the quests give you a character,** the hook is in how they talk and what they want. A hermit who insists he is feeble while handing you something heavy.
- **When the game gives you almost nothing,** the hook is the name, the title, the wares or the spot. Thor, a gryphon master named for the god of thunder, is afraid of storms. A butcher named Coldcleave gets saluted by recruits who take the name for a soldier's, and has stopped correcting them. Read the name aloud and ask what a stranger would assume about this person. Look at the one odd item on the shelf. Look at who stands next to them.

If your hook would fit any vendor in any town (the smith who loves a good edge, the innkeeper who has seen it all), it is not a hook yet.

## The entry as a set

The five Lore parts are read in order as a friendship grows, so they work like a short story with a turn in it:

- `gossip` is what the neighbors say, and it can be half wrong. It sets up the secret.
- `bio` grounds them: the job, the place, the real people and quests around them.
- `backstory` explains how they got here.
- `secret` pays off the gossip. Harmless and charming, even for a sinister NPC: a wink, never anything grim, cruel or criminal.
- `bestFriend` is theirs to say to the player, and lands the hook one last time.

The `quote` is seen first, at the lowest tier. It must sound like them without giving the secret away. State each fact or joke once: if the dust is in the dislikes, it is not also in the bio and an idle line.

## Staying inside the game

- **Other real NPCs.** You may name the people the game puts near them and what the game shows those people doing, and your NPC may have opinions about them ("Chef Jessen would still rather cook turtle"). Do not invent events between them: no shared past, no job one gave the other, no offers, favors, feuds, kinship or secrets kept together.
- **What the game only hints at stays a hint.** If a quest implies something and the NPC asks to keep it quiet, the entry keeps it quiet too.
- **Leave the world as the game shows it.** Do not resolve a quest, repair what is broken, move anyone, or assume the player has done a quest. An entry must read true to a player who has just met them and to one who finished the chain.
- **No looks.** Their race and sex are known; hair, whiskers, scars, clothes and build are not, and the model may contradict you.
- **Small inventions only.** A habit, a fear, a hobby, an opinion, how they came by the job. Never family, deaths, wars, crimes or anything a quest could contradict. Classic-era setting plus Forever's own additions; nothing from later expansions.

## The lines

They speak these while walking with the player as a companion, away from their post. A line shows in a chat bubble and is read aloud by a recorded voice.

1. **Exactly fifteen.** Two `greet`, three `idle`, one `befriended`, two `poke`, and seven spent where their job shines: a banker on `loot`, `mail` and `bagsFull`, a flight master on `taxi` and `landed`, a trainer on `levelUp` and `learned`, a guard on `combatStart` and `saluteBack`. Any moment in `Data/Lines.lua` works.
2. **Short.** Most under 80 characters; 140 is the limit. One thought each.
3. **In their voice.** A gruff smith, a fussy clerk and a bored guard should not sound alike. Read the NPC's own quest text for how they talk, then write new words in that voice. Every line should be one only this person would say; "Done? Good. There's always another job." could be anyone.
4. **One joke, three lines at most.** A running gag or verbal tic (the slip and hasty correction, the same complaint) can appear in three of the fifteen lines, no more. Find a second and third note for the rest.
5. **No stock shapes.** Skip the first phrasing that comes to mind, because it came to mind for the last writer too: "Poke the ham, not the butcher", "Shop's shut", "Clean work", "Somewhere a ... I can feel it". The checker rejects a line another NPC already says.
6. **Tones.** Give the first `greet`, the first `idle`, the `befriended` line and one job line a `tone`: one or two delivery tags in square brackets, such as `"[gruff] [amused]"`. The voice recording reads them; the bubble never shows them.
7. **Fill-ins.** `{name}`, `{zone}`, `{level}` and `{item}` are filled in for the bubble. A line that uses one needs a `say` text that reads well without it, for the recording. Use at most two per entry.

## The rest

- **Keep it light.** Warm, dry, a little funny. Not earnest, not wise, not a life lesson. These people complain about the weather and their neighbors. A reader should smile at least once per entry.
- **Favorite emote.** Pick the one this person would actually enjoy, from the tokens `tools/profiles/check.py` lists. The hint is a clue to it, not the answer.
- **Plain ASCII, US English**, no tabs. Straight quotes and apostrophes only; a quote inside a string is `\"`.

Done too often across the existing entries; find something else:

- a secret that they are bad at, or afraid of, the very thing they sell or teach
- "more than a customer", "more than a job" and other lines about valuing the person over the task
- advice about listening, patience, honesty or remembering names
- the word "friend" in most lines

## Check your work

```bash
python tools/profiles/check.py <your folder>
```

It tests the page budget, line count, emote, voice, fill-ins, spelling and repeated lines, and says what to fix. Fix until every NPC reads `ok` or `skip`. The budget is tight on purpose: the Lore column must show the whole entry without scrolling. When a field runs long, cut a sentence; do not shorten words.

Then read each entry once more against this page before you finish. The checker cannot tell whether the quote gives away the secret, whether a joke is in six lines, or whether you invented a past between two real people. You can.
