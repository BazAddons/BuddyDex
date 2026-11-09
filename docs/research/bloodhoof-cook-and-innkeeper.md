# Bloodhoof Village: Pyall Silentstride and Innkeeper Kauth

Reviewed 2026-11-09 against current Forever definitions, published Forever quest text and installed English quest/gossip records. These are individually reviewed research identities, not personal Scout sightings.

## Identity, location and eligibility

| NPC | ID | Current display / extra | Verified model |
| --- | ---: | --- | --- |
| Pyall Silentstride, Cook | 3067 | 3795 / 2049 | Adult male Tauren, race 6 / sex 0 |
| Innkeeper Kauth, Innkeeper | 6747 | 5486 / 3640 | Adult male Tauren, race 6 / sex 0 |

Current definitions: [Pyall](https://forever.warcraftdb.com/api/data/node/npc/3067), [Kauth](https://forever.warcraftdb.com/api/data/node/npc/6747). Cached current CreatureDisplayInfo and CreatureDisplayInfoExtra tables resolve the model identities above. Their current definitions omit reaction icons and map pins. Keep public faction-audit entries unverified; do not infer friendship access from Tauren race. Current Forever quests below explicitly place both in Bloodhoof Village, Mulgore, serving the local starter route. Gameplay still requires a named adult, friendly, non-attackable live unit. No eligibility exception or fake encounter was added.

Both exact current starts/ends API tabs returned empty arrays. This is incomplete relationship data, not evidence that they have no quests: published current quests and installed client dialogue establish the relations below. The current quest-node request for 96661 returned 404; the published Forever quest and installed record are available. Classic Pyall's list contains training rather than quests; Classic Kauth ends 1656.

## Pyall: full camping introduction and training dialogue

Read objectives, descriptions, progress and completion on each published Forever page, corroborated by the installed `Spoken_Quests/Data/QuestText.lua` accept/completion records:

- [96659 The Adventurer](https://www.wowhead.com/forever/quest=96659/the-adventurer): Chief Hawkwind sends a Supply Bundle to Kaga Wildhoof outside Bloodhoof Village, repaying earlier help. Kaga says compensation was unnecessary and offers camping instruction. This establishes Kaga's relationship to Hawkwind, not a personal history for Pyall.
- [96605 The Great Outdoors](https://www.wowhead.com/forever/quest=96605/the-great-outdoors): Kaga teaches resting beside her basic campfire and receiving Boosted Rest. Progress stresses preparation and survival; completion refers pupils to nearby tradeskill trainers for suitable camp fixtures. Do not give Pyall Kaga's adventures or claim he teaches all professions.
- [96661 Camping 101: Cooking](https://www.wowhead.com/forever/quest=96661/camping-101-cooking): Kaga sends learners to Pyall in Bloodhoof Village. Cooking and a campfire are the foundation for camping. Progress reinforces the fire; completion distinguishes basic camps and limited furnishings from later skill-dependent improvements. The profile makes no promise about specific recipes, skill thresholds or furnishings beyond the verified introduction.

Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`, exact NPC 3067, was read in full. Pyall offers to teach cooking and calls it a lifelong shared pursuit. He refers advanced learners to Dirge Quikcleave in Gadgetzan and to Wulan's Expert Cookbook in Shadowprey Village. These are professional referrals, not proof of a friendship, apprenticeship or shared quest history. No Dirge cooking trial is assigned to Pyall. His Classic Cook title is retained rather than importing the later retail title change or scaled level.

The Supply Bundle is a delivery item; this chain contains no personal readable journal or book. The cookbook referral supports continued learning, not a biography for its seller. There is no specific book/comic narrative connection in the consulted primary material requiring another story to be imported.

## Kauth: full delivery dialogue and inn services

Read full objective, description, progress and completion of [1656 A Task Unfinished, Forever](https://www.wowhead.com/forever/quest=1656/a-task-unfinished), compared with [Classic](https://classicdb.ch/?quest=1656) and installed accept/completion text.

Antur Fallow is occupied with his Rite of Strength on the Mesa. His father asked him to deliver furs to the Bloodhoof inn, and he asks the player to carry them instead. Kauth's progress dialogue considers how travelers experience the journey from the Mesa. Completion thanks the helper for an unexpectedly quick delivery, explains that the furs will become guest blankets, welcomes a stay and values a proper night's rest. This is a standalone delivery; Antur's mention of his rite does not make Kauth its instructor or turn it into a linked rite chain. The unnamed father is not identified as Kauth, and no kinship is invented.

Installed exact-NPC gossip was read in full. Kauth welcomes guests, explains comfortable inn rest and improved learning while rested, and offers hearthstone/home services. Holiday text also occurs in the file, including shared leader referrals; it does not establish his romance, current holiday availability or Alliance-friendly access. Those generic seasonal passages are not used as personal biography. No personal readable item, novel or comic connection appears in the consulted primary quest/gossip material.

## Original BuddyDex writing

Pyall's experimental trailcakes, their fragility in a pack and his enjoyment of sharing broken batches are modest original additions. The cooking lesson, professional referrals and location are confirmed; the baking pastime is not a game quest or promised reward. His favorite is THANK, with an appreciation hint. His fifteen personal lines emphasize patient learning and practical food with gentle humor.

Kauth's interest in guests' footsteps, the village rumor that he recognizes them and his admission that he sometimes greets strangers as return visitors are original. They extend his verified hospitality without supernatural recognition or an invented family/history. His favorite is BOW, with a respectful-return-of-welcome hint. His fifteen personal lines emphasize rest, welcome and companionship.

Each profile has all ten fields. The lore columns wrap to 19 and 20 lines at 50 characters respectively, within individual section budgets. Four signature recordings apiece use the approved Tauren male voice `UHjFz97GTxtpwstZu19x` with Eleven v4 and hidden delivery directions: greet, idle, befriended, and learned for Pyall / hearth for Kauth. Validation covers exact voice/text/cache mappings, decoded audio, adult routing, supported moments, discovery and favorite points, and the first recorded companion welcome. Public reaction uncertainty remains recorded rather than bypassed.

The standard addon and Scout smoke suites passed with zero load errors or failures. Installation and the separate development ZIP were verified: 5,666 release files, 5,638 runtime audio mappings, 97.43 MiB. The previously handed-off v002 upload candidate remains untouched; CurseForge publication is deferred to the user's evening setup.
