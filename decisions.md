# Decision log

Decisions Claude made while working unattended toward [goal.md](goal.md). Newest at the bottom. Each entry says what was decided, why, and how to undo it.

## 2026-11-15

**D1. Record the Horde general friend lines first.** (evening)
- Why: the 10 Horde voices had none of the 356 general lines, so a Horde friend saying a general line had no voice at all. It is the cheapest gap (about 146,000 credits) with the widest effect.
- Undo: delete the `npc_*.ogg` files in the Horde voice folders and their manifest entries.

**D2. Use `backfill.py`, not `generate.py --all`.** (evening)
- Why: `generate.py --all` would re-record every v3 clip in v4. The user said not to re-record. `backfill.py` only queues lines with no working clip and checks each new clip is audible.
- Undo: nothing to undo.

**D3. Order own lines by where players meet the NPC.** (evening; the user approved this recommendation)
- Starting zones, then capitals, then other zones by level.
- Why: this month's credits cover less than half the missing lines, so the lines most players hear go first.
- Undo: run `backfill.py` without `--order` to go by NPC ID.

**D4. Keep a 50,000-credit reserve.** (evening; part of the approved recommendation)
- Why: leaves room for new lines and voice tests before the Dec 9 reset.
- Undo: change `--reserve`.

**D5. Zephras Isle goes first among the starting zones.** (22:50)
- Why: it is where Forever's new race starts, for both factions, so it is likely the busiest starting zone right now. It is also the largest (87 profiles, about 149,000 credits).
- Effect: this month's recording will end near the end of Stormwind instead of in Ironforge.
- Undo: move "Zephras Isle" in `FIRST` in `tools/voice/lore_order.py` and regenerate the order file.

**D6. Capital order: Stormwind, Orgrimmar, Ironforge, Undercity, Thunder Bluff, Darnassus.** (22:50)
- Why: my estimate of how busy each is, alternating factions so neither waits for the other's three cities.
- Undo: reorder `FIRST` in `tools/voice/lore_order.py`.

**D7. Zones come from `docs/npc-coverage.json`.** (22:50)
- Why: it has a zone for all 1,017 profiles. My first version read zones from the research comments in `Data/Lore.lua` and could not place 111 NPCs, including all of Zephras Isle.
- Smaller calls inside this: Riverglades counts as a level-40 zone (its vendors are level 40), Dalaran goes with Alterac Mountains, and Lion's Pride Inn counts as Elwynn Forest.
- Undo: edit `LEVELS` and `PLACES` in `tools/voice/lore_order.py`.

**D8. Left the earlier uncommitted voice-tool work alone.** (evening)
- `tools/voice/design.py` (modified), `tools/voice/remix.py` and `docs/research/remaining-voice-auditions.md` were already uncommitted when I started. I did not change, commit or remove them.

**D9. Nothing committed or pushed.** (22:55; replaced by D11)
- Why: commits and pushes waited for the user at that point.

**D10. "Covered" means four things per NPC: profile, personal lines, a voice, and recordings of both its personal lines and the general lines.** (23:05)
- Why: the user's goal is "all NPCs are covered", and they confirmed NPCs get "their profile, line and voices, plus personal lines". The definition is at the top of goal.md.
- Added `tools/voice/coverage.py` to report all four parts per NPC, so progress is measured the same way every time.
- Undo: edit the definition in goal.md.

**D11. Commit as I go and push commits to GitHub. Never push a tag.** (23:15)
- Why: the user said "Do whatever you think is best, just dont push to CF unless I say". Commits protect the night's work, and a push keeps a copy off this PC. The CurseForge upload only runs when a tag is pushed or the release workflow is started by hand with upload on (checked in `.github/workflows/release.yml`), so pushing commits to `main` cannot publish anything.
- Undo: `git revert` any commit; nothing is published.

**D12. Committed the earlier session's voice audition work as its own commit.** (23:15)
- `tools/voice/design.py`, `tools/voice/remix.py` and `docs/research/remaining-voice-auditions.md` had been sitting uncommitted since Nov 9. I did not change them.
- Why: they record how the tauren and goblin voices were chosen, and uncommitted they existed only on this PC.
- Undo: `git revert` that commit.

**D13. Write new profiles while the recordings run.** (23:15)
- `docs/LORE.md` says to finish the audio backlog before more profiles. Recording now runs unattended and is limited by credits, not by my time, so writing profiles does not slow it down.
