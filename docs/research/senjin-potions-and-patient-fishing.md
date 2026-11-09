# Sen'jin: Miao'zan and Lau'Tiki

Researched 2026-11-09. Two named adult Troll profession teachers expand early Durotar coverage. No personal Scout encounter is claimed. Public data and automated mock checks do not establish a live character's reputation or attackability; the ordinary live eligibility gate remains required.

## Identity and access

- **Miao'zan, 3184**: [current Forever node](https://forever.warcraftdb.com/api/data/node/npc/3184) identifies the Journeyman Alchemist, Troll humanoid, display **4071**, Durotar pin about **55.5, 74.0**. Current cached CreatureDisplayInfo resolves extra **2324**, race **8**, sex **0**, an adult male Troll body. The current response lacks reaction evidence, so the coverage audit retains unverified faction access. [Classic identity](https://www.wowhead.com/classic/npc=3184/miaozan) supports Horde service historically; this is not silently upgraded to a current friendly observation.
- **Lau'Tiki, 5941**: [published Forever identity](https://www.wowhead.com/forever/npc=5941/lautiki) identifies a Fisherman in Durotar, Horde reaction and Darkspear affiliation. [Classic model data](https://classicdb.ch/?npc=5941) supplies display **4609**, resolving through the current cached body tables to extra **2866**, race **8**, sex **0**, adult male Troll. Classic coordinates are about **53.25, 81.59**, on the coast south of Sen'jin. His current exact Warcraft DB node returned 404; empty tab responses from that missing node are not evidence of removal or of no quest. Published Forever training/quest identity and installed dialogue agree on 5941. No replacement custom display is asserted.

The previously guessed 3180 was explicitly checked: it is Dark Iron Entrepreneur, not Lau'Tiki. It receives no profile or eligibility exception. Neither reviewed adult model is a child body; no inference is made from level, name or size. Generic guards remain excluded.

## Miao'zan's actual voice and scope

Read all three exact installed English gossip entries in `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`: he has had enough adventure by the trolls' arrival here, now trains others, teaches relaxed stirring, and sends questions beyond his skill to **Yelmak in the Drag, Orgrimmar**. This supports a relaxed, capable beginner teacher, not cowardice, a named battle, personal injuries or a hidden master rank.

Read the Classic training relations. The published Classic list includes beginner alchemy, minor mana/rejuvenation, lesser healing and Weak Troll's Blood recipes. Another Classic database exposes a broader recipe list; no exact current rank progression, unlock level or full stock is promised in the profile. No personal quest chain was established in the consulted relations. Do not turn his trainer service into a vendor inventory.

Checked the apparent camping association against [97899 Camping 101: Alchemy](https://www.wowhead.com/forever/quest=97899/camping-101-alchemy). Read the available objective, description and completion, and compared the installed accept/completion. **Brakk sends the player to Whuut**, not Miao'zan, to learn the Mana Well after gaining alchemy proficiency. That fixture, referral and completion speech are not assigned to Miao'zan. No progress section was exposed for 97899 in the consulted source.

## Lau'Tiki's fishing and camping

Read installed exact 5941 gossip: basic fishing instruction, referral to Old Man Heming's *The Bass and You* once beyond his skill, and the later recommendation to find Nat Pagle in Dustwallow. These are professional recommendations, not proof that he is their personal friend. Classic training lists Apprentice and Journeyman; Forever adds Fish Bowl. Later expansion Expert/Artisan trainer listings are not imported into this entry.

Read the full exposed Forever camping path:

- [96652 The Adventurer](https://www.wowhead.com/forever/quest=96652/the-adventurer): the Lost Journal leads to Brakk near Razor Hill. Objective, description, progress and completion concern his ordinary adventuring/camping journal and offer to teach. Installed completion agrees. The [Lost Journal item](https://www.wowhead.com/forever/item=275022/lost-journal) was previously reviewed in `bloodhoof-druid-and-razor-hill-cook.md`; no extra readable body was exposed. No invented journal passages are treated as canon.
- [96604 The Great Outdoors](https://www.wowhead.com/forever/quest=96604/the-great-outdoors): full objective/description/progress/completion cover sitting at Brakk's campfire, gaining rested benefit and learning tradeskill fixtures. Brakk's ambitions and campsite are his own, not Lau'Tiki's history.
- [96655 Camping 101: Cooking](https://www.wowhead.com/forever/quest=96655/camping-101-cooking): full objective/description/progress/completion send the learner to **Cook Torka** for the campfire foundation, with limited beginner furnishings and further skills. This explains the cooking prerequisite without making Lau'Tiki a cook.
- [97904 Camping 101: Fishing](https://www.wowhead.com/forever/quest=97904/camping-101-fishing): full objective/description/progress/completion send Brakk's learner to **Lau'Tiki near Sen'jin**, require **fishing 20**, teach **Fish Bowl**, and emphasize a little joy at camp. His completion tells the player to camp in the wilderness and learn a campfire from a cook. Installed accept/completion matches. No unconditional recipe access is promised before the actual prerequisites.

For the advanced gossip references, read [Expert Fishing - The Bass and You, 16083](https://classicdb.ch/?item=16083): this is a skill-teaching item, not an exposed narrative book (`new Book` body absent). Read the complete available dialogue of [6607 Nat Pagle, Angler Extreme](https://classicdb.ch/?quest=6607), with its four rare fish, determination theme and advanced instruction, plus [6608 You Too Good!](https://classicdb.ch/?quest=6608) and [6609 I Got Nothin' Left!](https://classicdb.ch/?quest=6609). Those referrals establish Lumak's and Grimnur's friendships with Nat, not Lau'Tiki's. No separate progress section was exposed for the two referral quests. The profile does not attribute their dialogue or catches to him.

Targeted literary searches established no personal book/comic biography for either NPC. Lau'Tiki fan storytelling and player party anecdotes in later comments are not canonical character history. Modern location/title changes and unrelated similarly named Trolls are excluded.

## Original BuddyDex writing

Miao'zan's spare-cork birds, tiny shelf roost, fondness for the roundest one and gift to a close friend are original modest writing. He uses spare corks, without leaving working bottles open. His preference for quieter days and relaxed teaching rests on actual gossip; no specific migration trauma or past expedition is invented.

Lau'Tiki's pebble-skipping pastime, impatience with a sinking stone and hope to share a good throw are original. They give the patient fishing teacher a small contrasting pleasure without claiming magical fish, a famous catch, a named family or ownership of an unverified shore prop. His camping service and concern for camp morale come from Forever's actual quest.

Each profile has all ten fields, fifteen supported personal lines and a twenty-line lore column at wrap width fifty. Favorite NOD acknowledges Miao'zan's quiet instruction; CHEER celebrates Lau'Tiki's little successes. Each receives four Eleven v4 signatures using the approved Troll male voice `X3ETuf4PfUMURFMpRT73`, with hidden delivery directions: greet, idle, befriended, and learned/rest respectively. No new voice design or key storage in the repo is needed.

Research caches stay outside the repository under `C:/Users/brett/BuddyDex-builds/durotar-services-research`. Development packaging remains separate from the preserved handed-off v002 candidate; CurseForge publication is still deferred for the user's evening setup. The wider catalog remains active beyond this shortlist.

## Batch verification

Full TOC loader checks passed for both identities, fifteen supported personal moments, four exact v4 text/tone/source/voice mappings each, and decoded finite non-silent mono 22,050 Hz Ogg files within the 0.5–25 second bounds. Fresh mock sessions rejected attackable and hostile targets, then verified ordinary discovery (25), the separate favorite category (150), and exactly one recorded first-outing welcome. These are automated sessions, not live sightings or visual reviews. The standard 23-file main and 6-file Scout smoke suites passed with zero load errors and failures. Persistent smoke routing includes both displays.

Backlog refreshed to 295 complete and two old Westfall identities pending; the wider catalog still contains 1,490 name groups and is not exhausted. Installed and verified 5,714 release files. The separate development v002 ZIP has 5,686 runtime audio mappings and is 100.37 MiB. The handed-off v002 candidate remains unchanged against its recorded SHA-256.
