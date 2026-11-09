# Nyalah Brightfire

Reviewed 2026-11-09. First completed Zephras Isle profile. Her independently verified friendly listing for both factions makes her useful to either Skyborne path; her High Order race alone would not prove that. No personal Scout encounter, in-game quest completion or live playtest is claimed.

## Identity and eligibility

[Current NPC definition 257006](https://forever.warcraftdb.com/api/data/node/npc/257006): Nyalah Brightfire, Cook, humanoid, High Order Skyborne race 95, level 10, Trainer/Vendor, explicit Alliance-friendly and Horde-friendly icons. The pin is at approximately 60.6, 72.7 in Valanaar, Zephras Isle (current map 2521; the published Wowhead zone URL uses 16593). [Published current NPC page](https://www.wowhead.com/forever/npc=257006/nyalah-brightfire) confirms her cook title and zone. A player comment about a blue-roofed building is supplementary, not a substitute for current map data.

Current model 140040, file 7478494, resolves through cached CreatureDisplayInfo to extra record 163348: race 95, female sex 1. This is an adult Skyborne character model; no age inference from level or size. Installed SpokenQuestsAudioGossip independently maps this exact NPC to the female Skyborne body. The BuddyDex body map already routes display 140040 to skyborne-female. Normal live named/adult/reaction/attackability checks remain in force.

## Full primary quest and dialogue review

Her current [starts](https://forever.warcraftdb.com/api/data/node/npc/257006/tab/starts) and [ends](https://forever.warcraftdb.com/api/data/node/npc/257006/tab/ends) lists each contain only Crab Season 93317. The [current quest definition](https://forever.warcraftdb.com/api/data/node/quest/93317) supplies objectives, description, both-faction access, rewards and her start/end relation. There is no linked follow-up chain in the consulted definition. [Published quest text including progress and completion](https://www.foreverdb.app/en/forever/quests/93317/crab-season) was read in full; installed Spoken_Quests/Data/QuestText.lua independently agrees on accept/completion. Wowhead's quest page returned 403 and is not claimed as read.

- She needs six Windsong Crawler Meat. The harvest lasts only a few weeks, and cult activity has prevented her from collecting it herself. She warns that the crabs are dangerous despite appearances.
- Progress dialogue remembers the meat being prized on Anvilas and Siroccas and her journeys to Shen'dramar and New Eldre'naar before the skystreams closed. She has been unable to visit for a long time. This establishes past travel and nostalgia; it does not establish a lost relative, destroyed city or future reunion.
- Completion expresses delight and thanks. Rewards include Pincer Bites and their recipe. Do not invent another quest stage or an exact annual calendar date.

Installed English NPC-keyed gossip in SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua was read in full for 257006. She offers cooking training and explains how she enjoys adapting ancestral Kaldorei recipes when traditional ingredients are unavailable in their dwindling home. She hopes the food will remind travelers of home. The garbled language variant adds no independently interpreted biography.

Current [vendor stock](https://forever.warcraftdb.com/api/data/node/npc/257006/tab/sells) includes apples, water, mild spices and three fish recipes; the [training list](https://forever.warcraftdb.com/api/data/node/npc/257006/tab/teaches) includes cooking ranks, campfire and dishes. Training requirements are not flattened into a promise that any beginner can learn every recipe immediately. No individual book/comic biography was found in targeted searches. No later-retail biography is imported into this Forever-original character.

## Original BuddyDex details

The recipe-margin faces, saved failed attempts, her private reason for keeping them, personal preferences and friendship speech are modest original writing. They build on her established pleasure in adapting recipes and teaching. They add no named relationships, powers or faction allegiance beyond the source identity. The profile does not claim that cult interference is resolved, the skystreams are restored or her old destinations can currently be reached.

THANK is the favorite, with a clue about appreciation for a meal. Fifteen personal lines cover greeting, idle, first outing, pokes, rest, errands, ingredients, bags, learning, growth and home. Four signatures (greet, idle, befriended, rest) use the approved female Skyborne voice lQ79RJ1oEygPMVWvoXTH and Eleven v4 with hidden emotional direction. Layout, exact text/voice mapping, decoded audio and simulated friendship/welcome behavior are checked with the standard main/Scout smoke suites before packaging.
