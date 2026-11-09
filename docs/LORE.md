# Writing BuddyDex entries

Most of the NPCs a player can befriend have no official story. Some have a single quest or line of gossip, and many have nothing at all. BuddyDex writes their stories: short, warm, a little funny, built on the few facts the game gives and never contradicting them. Entries live in `Data/Lore.lua`, keyed by NPC ID. Thor, the gryphon master at Sentinel Hill, is the worked example below.

## Who needs an entry

Named friendly NPCs can be befriended through conversations, trading, training, services, quests or friendly emotes. A named wanderer with no interaction window can join the Dex when the player targets them and uses an accepted friendly emote, so they can have a full authored entry too. Ordinary friendly emotes grant 25 points once per NPC per day, and their favorite grants 150 once per day in a separate category. Generic role NPCs such as Stormwind City Guard, Ironforge Mountaineer and Protector of the People remain excluded, including when someone writes lore for them. A named guard such as Guard Thomas is eligible. No NPC-specific exception is required for a named wanderer.

BuddyDex Scout (`tools/BuddyDexScout`, `/bdscout`) logs the NPCs you pass with name, title, zone and NPC ID, which is the list to write from.

## What an entry holds

Friendship unlocks an entry one part at a time, like the rewards on a reputation track. The Dex shows each part from its tier on, in two cards: **Personality** under the model (quote, likes, dislikes) and the **Lore** column on the right (Word Around Town, Story, Backstory, Secret, Just Between Friends). Until a part opens, its place says what it takes ("Reach Friend with Thor to hear his story."), and a footer counts the pages unlocked.

| Field | Section | Unlocks at | Budget | Notes |
| --- | --- | --- | --- | --- |
| `quote` | Personality | Acquaintance | 2 lines (200 characters) | In their own voice. Shown in quotes, centered, at the top of the Personality card. |
| `likes` | Personality | Buddy | 2 or 3 items, 45 characters each | Short phrases, capitalized like list items, one per line with a bullet. |
| `dislikes` | Personality | Buddy | same | Beside the likes. |
| `gossip` | Word Around Town | Buddy | 3 lines (about 130 characters) | What the neighbors say about them, in the third person. It can be half wrong: the best gossip sets up the secret. |
| `bio` | Story | Friend | 6 lines (about 260 characters) | Who they are now: their job, their place, the real people and quests around them. |
| `backstory` | Backstory | Friend | 6 lines (about 260 characters) | How they got here, and the hook. Invented, so keep it clear of anything the game could contradict. |
| `secret` | Secret | Good Friend | 4 lines (about 170 characters) | Something only close friends hear. Keep it harmless and charming. |
| `bestFriend` | Just Between Friends | Best Friend | 3 lines (about 130 characters) | What they say to the player, in their own voice. |
| `favorite` | Details | from the start | `{ emote, hint }` | Their favorite emote, the token `DoEmote` takes (`"WAVE"`, `"BOW"`, `"SALUTE"`). The hint shows in Details until the player finds it, so make it a clue, not the answer. Without one, their title picks it (`Core/Friendship.lua`). |
| `lines` | the buddy on screen | Buddy | about 15 lines | What they say when they come along: `greet` (brought along), `idle`, `befriended`, `poke`, and any moment from `Data/Lines.lua` (`levelUp`, `zone`, `loot`, `mail`, `taxi`...). One is picked from each list. |

**The budget.** The Lore column is about 52 characters wide and fits 23 lines of text under five section headers. An entry gets 21 of them (3 + 6 + 6 + 3 + 3, with the secret allowed a fourth line if something else is shorter), so the whole entry shows at Best Friend without scrolling, with room to spare. The tests (`every lore entry fits its pages`) wrap each part at 50 characters, a little narrower than the game, and fail any part over its budget, a column over 21 lines, a quote past 200 characters, a like or dislike past 45, or a friend with fewer than 12 or more than 20 lines of their own.

**About 15 lines.** There are far too many NPCs to give each one a big script, so the 356 general friend lines (`Data/NpcLines.lua`) do most of the talking, and a friend's own lines are what make them sound like themselves. Spend them on the moments their job touches: an auctioneer on `loot`, `mail` and `bagsFull`, a flight master on `taxi` and `landed`. Two or three for `greet`, `idle` and `poke`, one for `befriended`, the rest where they shine. A line with a fill-in (`{zone}`, `{item}`) needs a `say` text without it if the friend has a recorded voice.

Every field is optional. A missing part is skipped, and the gray line moves on to the next part that exists.

## Rules

1. **Never contradict the game.** Above each entry, a comment lists the facts it rests on: race, title, place, quests, gossip. A later writer can check them, and so can you when a patch changes something.
2. **Write it fresh.** Use the wikis for facts, never for wording. Don't copy wiki text, quest text or gossip. Echo a line of the NPC's real gossip in their quote if it fits, but in new words.
3. **Use Forever's setting.** Start with Classic-era facts, quests and places, then check for verified Forever additions or changed quest text. Do not assume a modern wiki's retail quest version is the Classic version. Retail-only events (Thor was at the Legion invasions in retail) don't happen here. Record the source and client version when using Forever-specific additions.
4. **Find the hook.** Look for one detail to build the entry on: a job, a name, a quest, where they stand. Thor's: a gryphon master named after the god of thunder. So he is afraid of storms.
5. **Stay near home.** Mention other NPCs only when they are real and close by, and don't invent family or feuds the game could contradict later. Thor knows Quartermaster Lewis and Dungar Longdrink because the quests put them together.
6. **Fit the budget** above. Write the Lore sections as a set: the gossip hints, the story grounds them, the backstory explains, the secret pays it off, and the best-friend line is theirs to say. Don't repeat a fact from one section in the next.
7. **US English** everywhere: favorite, color, gray, armor, traveled.

## Workflow

1. **Pick the NPC** from the Scout list or in game, and note the NPC ID (the Scout shows it, and so does `BuddyDexDB.friends` in the saved variables).
2. **Research** the NPC's page on [warcraft.wiki.gg](https://warcraft.wiki.gg), the zone's NPC list, and each quest they give or take. Talk to them in game for their gossip.
   Follow the full Classic-era quest chains: read objectives, descriptions, progress dialogue and completion text, including related quests from other NPCs. Note what those passages reveal about the character's voice, priorities and relationships. Check relevant books and comics too, while keeping later-expansion events out of the Forever entry. Record source links and separate confirmed facts from original BuddyDex additions; if a detail is uncertain, omit it rather than inventing a resolution. No quest found is a research result, not a reason to invent one.
3. **Write the facts comment**, then the entry, in `Data/Lore.lua` using the template below.
4. **Check it in game:** `/reload`, open the BuddyDex (`/bd`), pick the NPC, and type `/bd lore`. The lore preview shows every part whatever the friendship, so you can read the whole entry and see how it fits the card. `/bd lore` again, or a reload, turns it off. It isn't in `/bd help` on purpose. To see the parts open one tier at a time the way a player will, use `/bd give <tier>` (for example `/bd give buddy`) on the NPC instead.
5. **Run the tests:** `.venv/bin/python tools/tests/smoke.py`.
6. **Give the profile a voice.** Start with 3-5 signature recordings: a greeting, an idle remark, a friendship line and one or two reactions tied to the NPC's role. Keep the roughly 15 written lines; the existing general recordings cover other moments, and unrecorded personal lines still appear in speech bubbles. Use the established voice for the NPC's race and sex (Grimblewood Thornwhisker is the male gnome; the other recorded Alliance voices use the project's custom voices). Give signature lines explicit, character-appropriate audio delivery tags in `tone`; they are sent to v4 but never shown in bubbles. The generator cache includes the spoken delivery, so editing a tag regenerates that requested line. Preserve existing recordings unless a refresh is requested. Expand the recording selection when requested. Keep API keys outside the repository and never print them.
7. **Update the backlog.** `docs/npc-backlog.json` tracks completed entries and known candidates. Refresh it with `python tools/refresh-npc-backlog.py --scout <installed BuddyDexScout.lua> --as-of YYYY-MM-DD`. It is a candidate list, not proof of an NPC's identity or lore. Research each candidate before authoring and explicitly exclude generic roles.

## Template

```lua
    -- Name <Title>, Subzone, Zone. Race.
    -- Facts: what the game says about them, and where (quests, gossip, place).
    [npcID] = {
        quote = "",
        likes = { "", "", "" },
        dislikes = { "", "", "" },
        gossip = "",       -- 3 lines
        bio = "",          -- 6 lines
        backstory = "",    -- 6 lines
        secret = "",       -- 3 or 4 lines
        bestFriend = "",   -- 3 lines
        favorite = { emote = "WAVE", hint = "" },
        lines = {          -- about 15 in all
            greet = { "", "" },
            idle = { "", "", "" },
            befriended = { "" },
            poke = { "", "" },
            -- and the moments their job touches
        },
    },
```

## Worked example: Thor (NPC 523)

**What the game gives us** (from [warcraft.wiki.gg/wiki/Thor](https://warcraft.wiki.gg/wiki/Thor), [Return to Lewis](https://warcraft.wiki.gg/wiki/Return_to_Lewis) and [Westfall NPCs](https://warcraft.wiki.gg/wiki/Westfall_NPCs), checked in game):

- A human <Gryphon Master> at Sentinel Hill, Westfall. Level 55 elite in Forever.
- His gossip asks where you're headed and promises the fastest way there.
- Classic quests: Quartermaster Lewis's "A Swift Message" goes to him, and his "Continue to Stormwind" sends the player flying to Dungar Longdrink, Stormwind's gryphon master. "Return to Lewis" follows, and its text names Thor as Westfall's gryphon master.
- His name nods to the Norse god of thunder (and to Blizzard's Thor Biafore).

That's all. No family, no history, no personality. Everything else is ours.

**The hook:** a man named after the god of thunder who grounds every flight at the first rumble. Thunderstorms top his dislikes, and his bio ends on it.

**Field by field:**

- `quote`: his real gossip (where to, fastest way there), in new words with a joke about gossip.
- `likes` and `dislikes`: the job (gryphons, sky, riders), the place (the Dagger Hills, Westfall's harvest golems) and the quests (couriers).
- `gossip`: the militia's tall tale (he has flown every route twice), with the crack in it: nobody has seen him take off. It sets up the secret.
- `bio`: who he is now: the roost on Sentinel Hill, every bird and route, and the quest chain (Lewis's message, Dungar at the other end).
- `backstory`: how he got there (feeding gryphons in Stormwind, the only volunteer willing to live that far from a tavern) and the hook: named for the god of thunder, he grounds every flight at the first rumble.
- `secret`: a gryphon master who has never flown. It's harmless and a little sad, and it pays off the gossip.
- `bestFriend`: pays off the player's flights with him and Dungar again.
- `favorite`: `/wave`, since he waves riders off all day. Flight masters default to `/wave` anyway; Thor names it to set his own hint.
- `lines`: 15, spent where a flight master shines: `taxi` and `landed`, a `mount` jab (a gryphon would be faster), a grudging `hearth`, plus a gryphon with a name (Skyfeather) and the late couriers again.

Auctioneer Lympkin (`[9859]`) is the second example: an Ironforge-born gnome (the user's idea) whose gossip (she can price anything, gadgets too) is paid off by her secret (she can't tinker, so gadgets go "as is").

The full entry is `[523]` in `Data/Lore.lua`.
