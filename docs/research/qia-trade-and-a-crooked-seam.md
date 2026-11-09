# Qia: trade goods and a first attempt

Reviewed 2026-11-09. Qia is the first authored Goblin profile in this collection. Her original female B voice is the user's final selection; no new accent design or remix was requested.

## Identity, location and conditional eligibility

Exact [current definition, NPC 11189](https://forever.warcraftdb.com/api/data/node/npc/11189): Qia, Trade Goods Supplies, Goblin humanoid. Current display 10746 resolves through cached CreatureDisplayInfo to extra 7700, race 9 / sex 1, an adult female character model. The [published Forever NPC page](https://www.wowhead.com/forever/npc=11189/qia) explicitly locates her in Winterspring. The licensed [Atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf), PDF page 90, puts her in Everlook's building north of the inn. Player comments about bank corners are not treated as a new pin or a live observation.

The current node omits reaction/map fields; starts, ends and sells API tabs are empty. Preserve her public faction audit as unverified. Everlook being a neutral town does not establish friendly or non-attackable state for every player. Actual eligibility remains conditional on the existing live gate: resolved named adult NPC, reaction at least neutral (4), and UnitCanAttack false, with all other restrictions in force. Hostile or attackable Qia cannot be introduced merely because she has a profile. This authored identity is not a personal Scout sighting or a claim that an in-game target was checked today. Everlook is later travel coverage, not a starter-area milestone or verified shared-faction access count.

The added integration test exercises an authored Qia under attackable-neutral, hostile, and non-attackable-neutral states. It verifies the existing gate rather than adding an ID-specific exception or changing friendship policy.

## Services and research limits

Read the complete [Classic Qia](https://classicdb.ch/?npc=11189) raw stock list: ordinary trade supplies such as thread, dyes, vials, flux, tools, spices and several crafting patterns/formulas. No personal Classic quest list appears. Current starts/ends are also empty and exact NPC 11189 has no entry in installed English `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`. No personal quest chain, quest readable or recovered speech was established; none was invented to fill a biography.

The current published page has many historical player comments about patterns, restock times, prices, jewelcrafting and alleged purchase tricks. Those are not authoritative current Forever stock or character lore. The authored profile promises no particular recipe, timer, price, availability, profit or crafting-training service. Selling a pattern does not mean Qia personally mastered that craft. Her title and trade setting support an original merchant personality, not a universal crafting expert. Targeted literary research found no relevant personal book/comic biography; no later-retail storyline is assigned to her.

## Original BuddyDex details

Qia's crooked, completed practice pouch, modest pride in using it and wish for honest encouragement are original. So are her tastes, conversation and friendship. The pouch is neither an inventory reward nor a recovered canonical artifact. Her ordinary merchant knowledge and her own beginner sewing experience remain distinct. Favorite CHEER encourages a small completed project, with a hint rather than spelling out the emote.

The profile has all ten fields, fifteen supported personal lines, and a twenty-line lore column at width fifty within all section budgets. Four signature moments are greet, idle, befriended and learned. They use the approved original female B voice `GK7FvLcUviYyxNu6jR0D` on Eleven v4 with hidden delivery tags. The approved male B ID is `q4hkgjwgAzNLGZbjuFX9`; no male NPC recording is claimed by this batch.

## Production voice integration

The selected Goblin IDs already existed in the working voice generator. This production batch commits those two approved entries so a future manifest regeneration retains Goblin recordings. Other audition/design/remix work is not included. Core race-to-voice routing now maps race 9 to goblin-male/female. The reproducible NPC-sounds data generator includes race 9 and was run against the existing CSV cache: **446 Goblin body mappings added**, all prior body mappings preserved, native sound sets/display mappings unchanged. Current adult Qia 10746 routes female; Dizzywig 7053 routes male as independently verified, without authoring his unfinished profile.

Full-loader checks validate exact line/tone/source/voice metadata, decoded finite mono 22,050 Hz audio, reasonable duration/level, fifteen supported moments and the first recorded welcome. Persistent smoke coverage includes Qia's signature playback, male Goblin identity routing and live neutral/attackable/hostile restrictions. Installation and separate development packaging follow successful checks. Existing recordings remain intact, and the previously handed-off v002 upload candidate is preserved. CurseForge publication is still deferred to evening setup; the wider catalog goal remains active.

## Verified batch results

Full-loader Qia identity/line/audio/welcome validation passed. The main and Scout smoke suites passed with zero load errors or failures, including the conditional neutral/attackable/hostile case. A pre-existing randomized low-health scenario could trigger an opening cheer and legitimately suppress a second line after half a second. The health-only scenario now disables that competing opening chance and restores it afterward; no gameplay timing or chance changed. The added emote session runs after older randomized scenarios.

Installed and verified 5,694 release files; the separate development v002 ZIP has 5,666 runtime audio mappings and is 99.33 MiB. The handed-off upload candidate was checked against its recorded SHA-256 and remains unchanged. The backlog now records 290 complete profiles, with Dizzywig and the two old Westfall availability cases still pending inside the wider research pool.
