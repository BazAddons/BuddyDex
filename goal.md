# BuddyDex goal

## The goal

**All NPCs are covered** (set by the user, 2026-11-15).

Every NPC gets four things, and is covered when it has all of them:

1. **A profile.** Its entry in `Data/Lore.lua`, following `docs/LORE.md`: quote, likes, dislikes, gossip, story, backstory, secret, best-friend line and favorite emote.
2. **Personal lines.** Lines of its own in that entry (`lines`), about 15 per NPC.
3. **A voice.** The recording voice for its race and sex.
4. **Recordings.** Every personal line recorded in that voice, and all 356 general friend lines (`Data/NpcLines.lua`) recorded in that voice.

"All NPCs" means every eligible NPC: named adults a player can befriend. The working list is `docs/catalog/buddydex-candidates.json` plus anything the Scout logs later. Children and generic-role NPCs stay excluded, as already decided.

`python tools/voice/coverage.py` reports all four parts for every written NPC.

## Where things stand

Last updated 2026-11-15 23:05 EST, from `tools/voice/coverage.py`.

| Part | Done | Left |
|---|---|---|
| Profile written | 1,017 NPCs, every part filled in | 534 catalog NPCs (532 unresearched, 2 pending identity research: Daphne Stilwell 6182, Kriggon Talsone 4305) |
| Personal lines written | 1,017 NPCs, 15,259 lines | the same 534 NPCs |
| Voice assigned | 1,017 NPCs | the same 534 NPCs |
| Personal lines recorded | 1,882 of 15,259. 6 NPCs have all of theirs, 448 have some, 563 have none | about 13,400 lines, about 1,355,000 credits |
| General lines recorded | 12 of 20 voices complete | goblin, orc and troll (both sexes) and tauren female: about 100,000 credits, recording now |
| **Fully covered** | **6 NPCs** | 1,011 written NPCs, then the 534 unwritten |

Also done: the Mini Me's 441 lines in both gnome voices. Latest release: v003 on CurseForge (project 1793016); new recordings ship in the next release.

Voices: 20, one male and one female each for gnome, human, dwarf, night elf, Skyborne, Forsaken, tauren, goblin, orc and troll.

## Credits

- ElevenLabs Pro: 768,162 credits a month, resets Dec 9, 2026. Eleven v4 costs 1 credit per character.
- 746,787 credits left at 22:55 on Nov 15.
- **Reserve: 50,000.** Recording stops before it would dip into this.
- The whole goal needs roughly 2.2 million credits: about 1.5 million for the recordings still missing above, plus about 700,000 for the personal lines of the 534 profiles still to write. At this plan's rate that is about three months of credits, so the goal finishes around February unless credits are added.

## Recording order

Recordings run from `tools/voice/backfill.py`. It only records lines with no working clip, always in Eleven v4, and checks each clip is real audio before saving it.

1. General friend lines for the 10 Horde voices.
2. Friends' own lines, in the order players meet them (`tools/voice/lore_order.py`):
   1. Zephras Isle, then Elwynn Forest, Dun Morogh, Teldrassil, Durotar, Mulgore, Tirisfal Glades
   2. Stormwind, Orgrimmar, Ironforge, Undercity, Thunder Bluff, Darnassus
   3. Every other zone by the level players reach it

This month's credits should reach about the end of Stormwind. The rest continues after Dec 9 with the same command:

```bash
python tools/voice/backfill.py --record --order C:/Users/brett/BuddyDex-builds/voice-backfill/current/lore-order.json --reserve 50000 --state-dir C:/Users/brett/BuddyDex-builds/voice-backfill/current
```

## Standing rules

From the user:

- New recordings use Eleven v4. Existing v3 clips are never re-recorded.
- Voices ship inside the BuddyDex addon.
- Adults only. No child NPCs, profiles or voices.
- The user picks voices by ear. A new or replaced voice waits for them.

- **Never publish to CurseForge unless the user says so** (2026-11-15: "Do whatever you think is best, just dont push to CF unless I say"). A pushed git tag triggers the CurseForge upload, and so does running the release workflow with upload on. So: no tags, no release workflow runs.

While working unattended, I decide everything else and log it in [decisions.md](decisions.md). That includes committing as I go and pushing commits (never tags) to GitHub as a backup. I still hold back on these, because they can't be undone or they cost money:

- Spending into the reserve, or anything that costs money beyond the plan's credits
- Deleting recordings or profiles
- Choosing or replacing a voice, which is the user's call by ear

## Next steps

1. Finish the Horde general lines (running).
2. Record own lines in the order above until the reserve (queued, starts automatically).
3. Write profiles for the 534 unwritten catalog NPCs, starting zones first, following `docs/LORE.md` and the research-note pattern in `docs/research/`.
4. After Dec 9: resume recording.
