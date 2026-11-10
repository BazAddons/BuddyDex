# Sheal, Hesuwa, Daelyshia and Shindrell

Researched November 10, 2026. Four individually reviewed catalog identities, not Scout sightings: two Tauren in Thunder Bluff and two Night Elf women in Astranaar. All four names have one retained catalog ID and no same-name ambiguity. Full text profiles and fifteen personal lines each; recording deferred until the user confirms ElevenLabs billing is fixed.

## Identity and access

| NPC | Current definition | Adult model and voice | Public access |
| --- | --- | --- | --- |
| Sheal Runetotem3034 | [API](https://forever.warcraftdb.com/api/data/node/npc/3034), Druid Trainer60, Thunder Bluff76.90,27.31 |2121, race6sex1, M2986648, `tauren-female` | Horde Friendly |
| Hesuwa Thunderhorn10086 | [API](https://forever.warcraftdb.com/api/data/node/npc/10086), Pet Trainer40, Thunder Bluff54.48,83.35 |9337, race6sex0, M2968705, `tauren-male` | Horde Friendly |
| Daelyshia4267 | [API](https://forever.warcraftdb.com/api/data/node/npc/4267), Hippogryph Master55 **Elite**, Ashenvale34.40,48.00 |2313, race4sex1, M2921844, `nightelf-female` | Alliance Friendly |
| Shindrell Swiftfire3845 | [API](https://forever.warcraftdb.com/api/data/node/npc/3845), Night Elf25, Ashenvale34.65,48.83 |4126, race4sex1, M2921844, `nightelf-female` | Alliance **Neutral**, conditional |

All displays are independently mapped in `Data/NpcSounds.lua` and use the same adult character base models as verified Nara Wildmane, Karn Stonehoof and Nessa Shadowsong respectively. Age is not inferred from height or level. No generic/child exceptions. Shindrell's Neutral label is not Friendly evidence or proof of non-attackability; ordinary live reaction>=4 and non-attackability remain mandatory for her and every other NPC. Faction totals count only explicit Friendly icons. Daelyshia keeps normal Elite friendship scaling, not an NPC-specific threshold override. Profiles do not grant class, training, quest, route or faction privileges.

Primary raw responses, complete own starts/ends/sells/teaches endpoints, Classic NPC pages and full quest HTML are cached outside git in `C:/Users/brett/BuddyDex-builds/tauren-and-ashenvale-rotation`. All current own service tabs are sparse/empty except Shindrell's three starts1008/1134/4581 and two ends1008/1134. This does not prove historical services or Journey to Astranaar removed. Current quest-node requests returned404/500, so Classic text and the installed `Spoken_Quests/Data/QuestText.lua` corpus are explicitly historical/corroborating evidence, not newly verified current quest objectives. No exact costs, ranks, rewards or mandatory quest prerequisites are promised in the profiles.

## Sheal: teaching and being a beginner

[Classic3034](https://classicdb.ch/?npc=3034), [character reference](https://warcraft.wiki.gg/wiki/Sheal_Runetotem), and installed own gossip establish the druid trainer on Elder Rise, teaching through the Earth Mother and blessing non-druids. Retraining gossip describes starting instruction anew, not a new BuddyDex respec service. No invented Runetotem parentage, player class restriction, garrison incarnation or modern Moonglade quest imported.

Full Classic chain read in order: [9063 Torwa Pathfinder](https://classicdb.ch/?quest=9063) -> [9052 Bloodpetal Poison](https://classicdb.ch/?quest=9052) -> [9051 Toxic Test](https://classicdb.ch/?quest=9051) -> [9053 A Better Ingredient](https://classicdb.ch/?quest=9053), including available objectives/progress/completion and installed accept/complete text. Sheal is one possible referring trainer, not the toxin's maker. Torwa requests druid aid/respect for nature, mushrooms/stings, a nonlethal devilsaur test, then the Sunken Temple guardian's vine when the first toxin is weak. The final thanks does not establish another successful devilsaur test. None of Torwa's later actions are assigned to Sheal, and current sparse quest tabs prevent assuming this referral is currently offered.

Original BuddyDex hook: failing to whistle along with the wind and remembering the beginner's experience. No special spell, nature response, magical note or canonical event. SMILE is an accepted favorite; four signature moments carry explicit delivery tags.

## Hesuwa: a trainer takes his own advice

[Classic10086](https://classicdb.ch/?npc=10086), current Pet Trainer/Trainer flag and installed own gossip distinguish training hunters to pass learning to their pets from a stable service. Hunter Rise placement is corroborated by the [official Classic city tour](https://worldofwarcraft.blizzard.com/en-gb/news/23178672/wow-classic-city-tour-thunder-bluff), which also places Sheal on Elder Rise. No personal quest starts/ends found in current or Classic own tables. Historical training tables are not a guarantee of current exact abilities, ranks or prices. No individual Thunderhorn family relationship is inferred from the surname; no book/comic personal narrative established by consulted sources.

Original hook: sitting down before his own lunch after teaching others patience. Stomach objections and shared food are character fiction, not a feeding buff, free item, pet command or extra service. NOD is accepted. Approved male Tauren delivery stays deep and patient, rather than an invented tribal accent.

## Daelyshia: the pleasure of being on foot

[Classic4267](https://classicdb.ch/?npc=4267), current flight-master service and own installed destination prompt establish her Astranaar role. No own quest chain found. The [character reference](https://warcraft.wiki.gg/wiki/Daelyshia) separately describes her later War of the Thorns poisoning/death and Amirdrassil wisp: **both excluded** from living Forever4267. Modern flight connections and level changes are not current route evidence. Current definition explicitly says Elite55, retained in targeted tests.

Original hook: enjoying the sound of dry leaves under her boots on an unhurried walk. She is not afraid to fly and has no secret incapacity; no named hippogryph, invented route, transport discount or departure mechanic. WAVE is accepted. Her role lines concern care at departure/arrival rather than asserting a specific destination.

## Shindrell: defense without delight in destruction

[Classic3845](https://classicdb.ch/?npc=3845), installed own long-history gossip, full Classic objectives/descriptions/progress/completions and installed accept/complete passages read for:

- [1008 The Zoram Strand](https://classicdb.ch/?quest=1008) -> [1134 Pridewings of Stonetalon](https://classicdb.ch/?quest=1134). Naga motives remain unknown; the pridewing-venom intelligence from hidden Theramore sources is explicitly conditional. She regrets killing creatures that may not willingly aid an enemy. Do not turn that report into certain proven assassinations, general pacifism or delight in hunting.
- [1132 Fiora Longears](https://classicdb.ch/?quest=1132) -> [1133 Journey to Astranaar](https://classicdb.ch/?quest=1133). Red Jack sends the traveler to Fiora; Fiora recommends Shindrell but says Shindrell does not know her. No invented friendship or direct correspondence between those women.
- [4581 Kayneth Stillwind](https://classicdb.ch/?quest=4581) -> [1011 Forsaken Diseases](https://classicdb.ch/?quest=1011) -> [1012 Insane Druids](https://classicdb.ch/?quest=1012). Shindrell supplies her report; Kayneth calls her a brave, keen sentinel. The testing, vision, named dead druids and later barrow task belong to Kayneth/player, not her past deeds or proof the player completed anything. The separate Bathran/Pelturas chain is not this chain.

[Character reference](https://warcraft.wiki.gg/wiki/Shindrell_Swiftfire) distinguishes later relocation to Blackfathom Camp and later Elite status. Neither imported: current3845 remains Astranaar/normal25. Her current Neutral icon is not rewritten to Friendly. Original hook: allowing a healthy crooked fern to grow around a stone, giving her a quiet reminder of life beyond duty. It is not a cure for Ashenvale, a new quest plant, magical intervention or resolution of the corruption. COMFORT is accepted. No child profiles are created by references in adjacent quest material.

## Validation

Main and Scout smoke checks pass, including all lore/card/field/line budgets and fresh/existing character roster isolation. Temporary targeted harness `C:/Users/brett/AppData/Local/Temp/buddydex-tauren-ashenvale.py` verifies all four named adult displays, approved declared/live voice routing, fifteen personal lines and accepted favorites. Fresh Horde scenarios for both Tauren and Alliance scenarios for the Night Elves reject attackable/reaction3 units normally. Shindrell succeeds only with reaction4/non-attackable; no Friendly override. Each gets25ordinary/150favorite points. Normal99/100and299/300 boundaries pass; Daelyshia's actual Elite149/150and449/450 boundaries pass, including companion rejection below Buddy. Text-only activation and welcome succeed without substituted personal audio. Generic Dwarf/Stormwind Guards remain rejected; normal runtime/storage code unchanged.

Complete offline decoded-audio/exact-text audit:8900missing jobs/538972tagged inputcharacters, shared3548/personal5352, no MiniMe gaps. Each of the four sources has exactly15missing jobs assigned to its approved group; adds60jobs/4640characters. Existing6336OGG files/6334unique runtime mappings preserved. No ElevenLabs synthesis, account/billing calls, credit spending or human listening/live visual check.

Backlog and coverage:483fully written/454with initial signature recordings/29written-complete audio-pending; two Westfall availability candidates remain unprofiled. Current public Friendly-icon totals211Alliance/151Horde/128unverified, seven overlaps. Shindrell's Neutral icon stays unverified. Catalog1536namegroups/1549identities unchanged, no fabricated Scout observations.

Developmentv003 installed/hash-verified6362releasefiles, one runtime source updated. ZIP verified6362files/6334runtime audio mappings/138.41MiB; installed and ZIP Lore bytes equal the repository. SHA256: `8b6d760a58f12b379fd272d8e76743834978ef5cb650d1f00dad7cfbb6104a9c`. Publishedv002 untouched. No tag or CurseForge publication.
