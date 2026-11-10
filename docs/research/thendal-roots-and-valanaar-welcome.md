# Thendal roots and Valanaar welcome

Reviewed November 10, 2026. Two catalog identities, not fabricated Scout sightings. Written-complete/audio-pending under the billing hold.

## Identity, access and current sources

| NPC | Identity evidence | Location and access |
| --- | --- | --- |
| [Tai'ree Farsight251376](https://forever.warcraftdb.com/api/data/node/npc/251376) | Hunter Trainer, High Order Skyborne race95; adult character display136976/M2 7478494; installed display map95:1, female | Thendal Grove, Zephras Isle42.50,23.73; explicit Alliance and Horde Friendly |
| [Xy'aaria Streamrunner252478](https://forever.warcraftdb.com/api/data/node/npc/252478) | Imports, High Order Skyborne race95; adult character display137339/M2 7478494; installed display map95:1, female | Valanaar, Zephras Isle63.14,77.40; explicit Alliance and Horde Friendly |

The catalog has one retained identity per name, with no ambiguous same-name variant. Race95 is High Order, not Windshaper96. Both use approved skyborne-female lQ79RJ1oEygPMVWvoXTH, checked against live display routing. Public reactions are research evidence, not permission to bypass actual attackability or reaction checks.

Primary node and all four starts/ends/sells/teaches tables cached at `C:/Users/brett/BuddyDex-builds/skyborne-leads-732`. API URLs use `/api/data/node/npc/ID` and the corresponding table endpoints preserved in the cache fetch script. Tai'ree starts0, ends1, sells0, teaches5; Xy'aaria all four0. The Imports title does not prove current inventory or a transport feature. Secondary [Xy'aaria listing](https://pullcall.com/db/forever/npc/252478-xyaaria-streamrunner) corroborates both Friendly and the Valanaar location; two historical pins do not establish a movement route. Melasa257007 and Vela277067 were reviewed as leads but are not authored or counted here.

## Tai'ree: full referral and own dialogue

Read primary descriptions, objectives and installed `Spoken_Quests/Data/QuestText.lua` acceptance/completion for the immediate branch:

- [92460 Coming of Age](https://forever.warcraftdb.com/api/data/node/quest/92460): Ailee welcomes the newly of-age initiate and sends them to Rorian; his completion explains the inherited relic and its eventual passing. A captured player name is not a named relative.
- [92461 Harmony in Balance](https://forever.warcraftdb.com/api/data/node/quest/92461): Rorian orders eight juvenile vuldren culled to correct the population imbalance. He treats them as part of the ecosystem and attributes dangerous behavior to disturbed wind magic. These actions belong to Rorian and the player.
- [92482 The Way of the Hunter](https://forever.warcraftdb.com/api/data/node/quest/92482): Rorian passes Tai'ree's note after the vuldren task; the player reads it and meets her in Thendal Grove. Her completion emphasizes keen senses and reflexes, recalls standing before her own unnamed mentor years ago, believes in the novice's potential while leaving the outcome to their effort, and offers further training. No named mentor, first pet or guaranteed success is supplied. [Secondary quest page](https://bindonforever.com/quest/92482) links Harmony as prerequisite; ClassicDB92482 exposes no usable Classic-era text for this Forever quest.

Read [Scribbled Note282421](https://forever.warcraftdb.com/api/data/node/item/282421): the current item node exposes no readable body. Installed Compendium has no matching ID or title; do not invent its contents. Quest acceptance/completion still establish the referral. Full branch reviewed previously in [Thendal's first guides](thendal-first-guides.md), reread for this batch.

Installed own gossip has three near-identical captured variants: harsh winds, fading sustaining magic and more dangerous wilds make hunters/rangers important to protecting the people; she offers training to an apt hunter. These are variants of one greeting, not three separate conversations or proof the crisis is solved. No unrelated NPC's speech is attributed to her.

Read all five current taught spell nodes and effects: [Arcane Shot3044](https://forever.warcraftdb.com/api/data/node/spell/3044), [Aspect of the Monkey13163](https://forever.warcraftdb.com/api/data/node/spell/13163), [Hunter's Mark1130](https://forever.warcraftdb.com/api/data/node/spell/1130), [Serpent Sting1978](https://forever.warcraftdb.com/api/data/node/spell/1978), [Track Beasts1494](https://forever.warcraftdb.com/api/data/node/spell/1494). Damage, dodge, marking and tracking support attentive hunter instruction, not invented pet-training rewards. No numeric lesson cap is promised. A secondary search mentioned Ryff, but no primary pet relationship/species was verified, so omitted. No relevant book or comic established an additional personal history.

## Xy'aaria: interrupted imports, uncertain horizon

Her own installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` block says skycutters and ferries have not operated in years. She does not know whether other islands remain to provide imports, but stays in place in case they return. This uncertainty is central: no confirmed destruction of other islands, resumed shipping, active foreign stock, named ship or transport service is invented. Current quest and service tables expose no own quest chain or readable book. No family relationship with nearby Belann is assumed.

## Established facts versus original BuddyDex writing

Tai'ree's trainer identity, location, harsh-wind concerns, hunter referral and remembered apprenticeship are established. The novice's distant-bird/nearby-root stumble, telling it kindly to another learner and forgetting the bird's species are original small-scale writing. They are not a recorded event or a claim about her mentor. Her favorite NOD rewards accepting a lesson without false confidence.

Xy'aaria's imports title, location, long interruption and uncertainty are established. Rehearsing questions and deciding to welcome passengers before asking them is original writing, not an actual returning ferry or a new world event. Friend visits give that welcome a present use. WELCOME is her supported favorite; no invented welcomeBack moment is used.

Both profiles supply quote, likes/dislikes, all five lore pages, favorite hint and fifteen personal lines each. Eight lines carry hidden delivery tags. Friendship unlocks these pages and companion dialogue through existing tiers; it grants no spells, items, passage, quest credit or altered world state. Approved voice metadata only queues future recording. No synthesis or API credit use.

## Validation and artifacts

Main/Scout smoke passes with zero load errors/failures, including all lore/page/line budgets and fresh/existing character storage isolation. Actual-addon harness `C:/Users/brett/AppData/Local/Temp/buddydex-tairee-xyaaria-732.py` passes four fresh sessions: both NPCs in Alliance and Horde contexts. Exact adult displays, approved live/declared voice, fifteen supported unmapped lines each, favorite validity, attackable/reaction3 rejection without discovery, nonattackable reaction5 acceptance, HELLO25 plus favorite150 yielding175,99/100 and299/300 tier boundaries, companion rejection at299 and text-only welcome at300 without mismatched audio all pass. Generic guards remain excluded. These are actual-addon mocked checks, not live game sightings. No runtime or saved-variable changes.

732 fully written profiles / 454 with initial signature recordings / 278 written-complete audio-pending. Tai'ree251376 and Xy'aaria252478 add30 personal jobs/2900 tagged input characters in approved skyborne-female. Full offline audit12635 missing jobs/922649 tagged input characters: shared3548/personal9087, no MiniMe gaps. Queue `C:/Users/brett/BuddyDex-builds/voice-backfill/profiles-732/queue.json`. Previous queue retained exactly, with only these thirty jobs added. Two uncertain Westfall identities remain unprofiled in the local backlog. Fimbo, five transformed-display Nightclaw candidates and Shaeldryn the dryad remain deferred external leads. Catalog1536 name groups/1549 retained identities unchanged and overlapping the backlog. No synthesis in this batch.

Explicit Friendly311Alliance/290Horde/159unverified, twenty-eight shared overlaps, yields732 unique profiles. High Order coverage28. These additions extend Thendal and Valanaar routes, not an assertion every starter milestone is complete. Developmentv003 installation verified6362files; ZIP6362files/6334audio mappings/138.68MiB. Source, installed and ZIP Lore bytes match; ZIP CRC passes. SHA256 `53c005ab50b13063520cd6afbe88c9d234fb4cba26e43eea1d515cc4e7c3dffc`. Publishedv002 untouched; no tag or CurseForge publication.
