# Thendal sketches and Calmbreeze story endings

Researched 2026-11-09. Identities and original queue: [Ventaari and Donaal](ventaari-and-donaal-queue.md). External caches `C:/Users/brett/BuddyDex-builds/ventaari-donaal-research` and previous pair `next-npc-ID.json`. No live conversation, Scout observation or player quest completion claimed.

## Identity and access

- [Ventaari Brightwish 251487](https://forever.warcraftdb.com/api/data/node/npc/251487), Windshapers, Thendal Village/Zephras Isle 42.7, 24.4. Exact current model 139694 -> installed CreatureDisplayInfo/Extra race 96, sex 1: standard adult female Windshaper Skyborne, runtime `skyborne-female`. Current faction icons explicitly **Horde Friendly, Alliance Hostile**. Published Alliance gossip does not grant friendship access or override hostile reaction. Low level is not age evidence.
- [Donaal Downbreeze 255940](https://forever.warcraftdb.com/api/data/node/npc/255940), Innkeeper/Vendor, Calmbreeze Inn, Valanaar/Zephras Isle 62.2, 72.8. Display 139379 -> race 95, sex 0: standard adult male High Order Skyborne, runtime `skyborne-male`. Current icons explicitly **both factions Friendly**; this does not generalize to every High Order NPC.

Both are individually named, unprofiled adult identities. Normal live reaction/non-attackability and named/adult gates remain. No racial ability, class or quest is a friendship prerequisite.

## Quest and dialogue reading

All eight current own starts/ends/teaches/sells responses read, single-page. Ventaari starts/ends only **92598 The Gift of Skysight**; no stock/training rows. Donaal has no own quest/training rows and 23 stock rows. These are observed relations, not a claim that unavailable source text cannot exist.

Ventaari's exact installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` block has five strings, including a near-duplicate spelling/punctuation variant. Read all: greeting fellow Windshapers; debt/oath to elemental spirits and criticism of High Order control; departed wind spirits, lost magic, unstable island, failed contact with other island provinces; Alliance warning about divisions. Some fear Zephras holds the last surviving shen'dorei; **this is fear, not confirmed extinction**. No speculative Brightwish family relationship imported.

[The Gift of Skysight published full objective/description/completion](https://www.wowhead.com/forever/quest=92598/the-gift-of-skysight) read and compared with current quest API and exact installed `Spoken_Quests/Data/QuestText.lua` accept/complete block. Windshaper learner uses racial Skysight at Elemental Convergence/standing stones northeast of village; its boon is stronger there. Completion stresses practice, spiritual connection and listening for survival. Neither public page nor installed block provides separate progress text; not silently claimed read. Current relation has no follow-up, prerequisite quest or item reward; +100 Windshapers, 180 XP, level 4/minimum 2. No readable item/book is attached. This is racial instruction, not a class trial; BuddyDex grants no ability. Do not import another NPC's quest chain from a search-result adjacency.

Donaal's exact installed gossip block has one welcome/refreshement string. [Published character page](https://warcraft.wiki.gg/wiki/Donaal_Downbreeze) direct fetch 403; indexed text exposes full stock, service greeting and approach scene. Read the full indexed scene: **Sirocca ?Swimmers? Starfeather** tells drunken ghost/forest-wraith stories; **Donaal** objects that they will frighten away his few customers; **Sirocca**, not Donaal, continues the claims about ankle-gnawing spirits and a black-clad wraith. This scene is secondary-published evidence, not a live capture or independently recovered installed event script. Do not present Donaal as the drunk storyteller, eyewitness to ghosts, or proof ghosts are real/imaginary. No personal family relationship established.

All 23 current stock rows read: Cured Ham Steak, Delicious Cave Mold, Dried King Bolete, Forest Mushroom Cap, Gustberry Juice, Gustberry Pie, Haunch of Meat, Hippogryph Flank, Ice Cold Milk, Melon Juice, Moonberry Juice, Morning Glory Dew, Mutton Chop, Pungent Skycheddar, Raw Black Truffle, Red Delicious Stormapple, Red-speckled Mushroom, Refreshing Spring Water, Roasted Quail, Spongy Morel, Sweet Nectar, Tough Jerky, Wild Hog Shank. No readable book/comic or quest-starting item in these rows. Stock supports refreshment, not a claim he cooks each item himself.

Both NPCs are Forever-original. No independently verified prior Classic/retail novel/comic biography found in exact-name research. No prior-expansion history or generic Skyborne history attributed as their personal adventure. No claim to have read an unavailable book/panel. [Ventaari published identity/gossip](https://warcraft.wiki.gg/wiki/Ventaari_Brightwish) cross-check agrees with installed dialogue; surname-based family speculation excluded.

## Original BuddyDex additions

Ventaari's bird drawings, awkward shapes, continued practice, favorite two sketches and honest friend's encouragement are original. They develop attentive practice without turning Skysight into artistic prophecy or inventing a magical bird companion.

Donaal's preferred reassuring supper endings, unsuccessful attempt to improve a tale and private enjoyment of the attentive beginning are original. They develop his explicit concern about frightened customers. The profile does not rewrite the actual Sirocca scene or establish a supernatural explanation.

Ten fields and fifteen supported lines apiece; each lore column wraps to 20 lines (3/5/5/4/3) at width 50. Four signatures each: greet, idle, first-outing welcome, Ventaari `learned` / Donaal `rest`. Approved Skyborne female `lQ79RJ1oEygPMVWvoXTH` / male `8chV49fDd6WKeqeufgPU`, Eleven v4 with hidden delivery tags. Written preflight and main/Scout smoke passed before recording.

## Validation and delivery

- Eight recordings match exact authored text, hidden tone, NPC source, approved voice and Eleven v4 model; runtime mappings resolve. Decoded Ogg mono 22050 Hz, finite/non-silent and 0.5-25 seconds. Automated checks are not human listening approval.
- Fresh Horde session discovers both at reaction 5 through HELLO (25 points), grants separate favorite (150), then plays exactly one recorded first-outing welcome and sets its flag. Both reject attackable/unfriendly targets. Fresh Alliance fixture rejects Ventaari at hostile reaction even if attackable is false, while Donaal supports discovery/favorite/welcome normally. Player fixture initialization corrected before these tests passed; no product behavior changed to accommodate the test. Generic guards excluded; named Guard Thomas eligible.
- Main 23 files and Scout six files: zero load errors/failures, overall PASS. Exact display routes added to persistent smoke coverage. No live-game visual check claimed.
- Backlog 378 complete/four pending, wider catalog 1510 name groups. Faction counts Alliance 198, Horde 90, unverified 97, with seven shared entries overlapping. The four-entry short queue is not the whole remaining scope.
- Installed/hash-verified 6046 release files, ten updated. Separate development `C:/Users/brett/BuddyDex-builds/development/BuddyDex-v002.zip`: verified 6046 files, 6018 runtime audio mappings, 116.91 MiB. No source docs/tools/manifests or character saves packaged.
- Handed-off `C:/Users/brett/BuddyDex-builds/BuddyDex-v002.zip` unchanged: SHA256 `696a680d5baa18c35df523976257fd48b413e2d357b004f9bc9b46ab4403645b`. No CurseForge upload/tag while publication deferred.
- Next individually checked [Borya and Xen'to](borya-and-xento-queue.md), adult male Orc/Troll suppliers, not yet authored or counted complete. Wider backlog remains active.
