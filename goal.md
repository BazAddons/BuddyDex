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

Last updated 2026-11-15 23:45 EST. Run `python tools/voice/coverage.py` for the live numbers.

| Part | Done | Left |
|---|---|---|
| Profile written | 1,017 NPCs, every part filled in | 505 catalog NPCs that can be written now, plus 29 waiting on a voice (below) |
| Personal lines written | 1,017 NPCs, 15,259 lines | the same 505 NPCs |
| Voice assigned | 1,017 NPCs | the same 505 NPCs |
| Personal lines recorded | 1,882 of 15,259 when the night began; recording now | about 13,400 lines, running overnight |
| General lines recorded | all 20 voices, 356 lines each | none |
| **Fully covered** | 6 NPCs when the night began | rises as the overnight run finishes each NPC |

Also done: the Mini Me's 441 lines in both gnome voices. Latest release: v003 on CurseForge (project 1793016); new recordings ship in the next release.

Voices: 20, one male and one female each for gnome, human, dwarf, night elf, Skyborne, Forsaken, tauren, goblin, orc and troll.

**Waiting on a voice: 29 NPCs** (`docs/npc-skipped.json`). Three are Blood Elves, a race with no recorded voice. The other 26 use models the addon cannot match to a race and sex, so it could not play a recorded voice for them even if one were made. Both need the user: a new voice to pick by ear, or a decision to map those models by hand.

## Credits

- ElevenLabs Pro: 768,162 credits a month, resets Dec 9, 2026.
- **Eleven v4 costs about 0.48 credits per character sent**, measured on tonight's runs (3,548 Horde clips: 145,992 characters for 70,177 credits). The first plan assumed 1 credit per character, so everything costs about half what it estimated.
- 686,935 credits left at 23:44 on Nov 15.
- **Reserve: 50,000.** Recording stops before it would dip into this.
- What is left to record:
  - Personal lines of the 1,017 written NPCs: about 1,355,000 characters, about 650,000 credits. This month's credits cover nearly all of it.
  - Personal lines of the 505 NPCs still to write: about 550,000 characters at the shorter line length the new brief asks for, about 265,000 credits. That fits in December's credits.
- So the goal can finish in December, not February, as long as the 0.48 rate holds.

## Recording order

Recordings run from `tools/voice/backfill.py`. It only records lines with no working clip, always in Eleven v4, and checks each clip is real audio before saving it.

1. General friend lines for the 10 Horde voices. Done Nov 15.
2. Friends' own lines, in the order players meet them (`tools/voice/lore_order.py`). Running since 23:38 on Nov 15, about 38 clips a minute, so about six hours for all of them:
   1. Zephras Isle, then Elwynn Forest, Dun Morogh, Teldrassil, Durotar, Mulgore, Tirisfal Glades
   2. Stormwind, Orgrimmar, Ironforge, Undercity, Thunder Bluff, Darnassus
   3. Every other zone by the level players reach it
3. After Dec 9: the new profiles' lines. Regenerate the order file first so they are included:

```bash
python tools/voice/lore_order.py C:/Users/brett/BuddyDex-builds/voice-backfill/current/lore-order.json
python tools/voice/backfill.py --record --order C:/Users/brett/BuddyDex-builds/voice-backfill/current/lore-order.json --reserve 50000 --state-dir C:/Users/brett/BuddyDex-builds/voice-backfill/current
```

## Writing the new profiles

- `tools/profiles/research.py` has gathered the game's facts for all 534 unwritten catalog NPCs into digests.
- Fable 5.2 writes them, chosen by a blind test against Opus 5.5 (11 votes to 4; `docs/research/writer-comparison-2026-11-15/`).
- `tools/profiles/WRITER.md` is the brief. `tools/profiles/check.py` tests every draft. `tools/profiles/merge.py` adds passing drafts to `Data/Lore.lua` and the tracking files. `tools/profiles/next.py` says who is next.
- Order: the same as the recordings, starting zones first.

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

1. Record personal lines until the reserve (running overnight).
2. Test the tuned writing brief: old drafts against new, judged blind (running).
3. Write the 505 profiles in batches; check, merge, commit and push each batch.
4. After Dec 9: record the new profiles' lines.
5. With the user: voices or model mapping for the 29 skipped NPCs, then a release.
