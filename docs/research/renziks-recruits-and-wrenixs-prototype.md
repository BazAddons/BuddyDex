# Renzik's recruits and Wrenix's prototype

Researched November10,2026. Two adult Goblin men from the existing catalog: Renzik6946 in Stormwind and Wrenix7161 in Ratchet. Both written complete with audio pending; no synthesis.

## Current identities and relationships

- [Renzik primary node](https://forever.warcraftdb.com/api/data/node/npc/6946): SI:7 Operative, Goblin Humanoid, level40, explicit Alliance Friendly icon. Adult male character display7613/M2 119376; Stormwind pin78.67,70.89. Current [starts](https://forever.warcraftdb.com/api/data/node/npc/6946/tab/starts?page=1) has2281 Redridge Rendezvous; [ends](https://forever.warcraftdb.com/api/data/node/npc/6946/tab/ends?page=1), [sells](https://forever.warcraftdb.com/api/data/node/npc/6946/tab/sells?page=1), [teaches](https://forever.warcraftdb.com/api/data/node/npc/6946/tab/teaches?page=1) are empty. All fit a single page. Historical incoming referrals remain readable quest nodes but are absent from the current own relationship table; availability is not fabricated from that discrepancy.
- [Wrenix primary node](https://forever.warcraftdb.com/api/data/node/npc/7161): Goblin Humanoid, level20, explicit Horde Neutral icon; adult male character display7154/M2 119376, Ratchet63.06,36.36. Current [starts](https://forever.warcraftdb.com/api/data/node/npc/7161/tab/starts?page=1) has97253 Parts and Pieces, while [ends](https://forever.warcraftdb.com/api/data/node/npc/7161/tab/ends?page=1), [sells](https://forever.warcraftdb.com/api/data/node/npc/7161/tab/sells?page=1), [teaches](https://forever.warcraftdb.com/api/data/node/npc/7161/tab/teaches?page=1) are empty, all single-page. Quest objectives explicitly instruct returning to him despite the empty relationship table. Horde Neutral is not counted as explicit Horde Friendly; no Alliance reaction is inferred from the quest's Both label. Live nonattackable reaction4 eligibility still applies.
- Both names have exactly one retained ID and no same-name review flag in the catalog. Neither is a Scout sighting. Model identity, not height/level/name, supports adult sex assignment. Approved voice is `goblin-male`/`q4hkgjwgAzNLGZbjuFX9` for both; actual installed routing is checked below.
- Installed own gossip block6946 says Shaw saved him after the Venture Company abandoned him in the Barrens. No own7161 gossip block was found. Read `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` by NPC block. The installed `Spoken_Quests/Data/QuestText.lua` supplies full offer/completion for every successful quest node below, including97253.

## Renzik: training, contacts and source boundaries

Read current objective/description, Classic objective/offer/progress/completion, and installed offer/completion for these referrals and their immediate lead-ins and follow-up:

| Quest | Forever | Classic |
| --- | --- | --- |
| 2259 Erion Shadewhisper | [node](https://forever.warcraftdb.com/api/data/node/quest/2259) | [text](https://classicdb.ch/?quest=2259) |
| 2260 Erion's Behest | [node](https://forever.warcraftdb.com/api/data/node/quest/2260) | [text](https://classicdb.ch/?quest=2260) |
| 2299 To Hulfdan! | [node](https://forever.warcraftdb.com/api/data/node/quest/2299) | [text](https://classicdb.ch/?quest=2299) |
| 2298 Kingly Shakedown | [node](https://forever.warcraftdb.com/api/data/node/quest/2298) | [text](https://classicdb.ch/?quest=2298) |
| 2205 Seek out SI:7 | [node](https://forever.warcraftdb.com/api/data/node/quest/2205) | [text](https://classicdb.ch/?quest=2205) |
| 2300 SI:7 | [node](https://forever.warcraftdb.com/api/data/node/quest/2300) | [text](https://classicdb.ch/?quest=2300) |
| 2281 Redridge Rendezvous | [node](https://forever.warcraftdb.com/api/data/node/quest/2281) | [text](https://classicdb.ch/?quest=2281) |
| 2282 Alther's Mill | [node](https://forever.warcraftdb.com/api/data/node/quest/2282) | [text](https://classicdb.ch/?quest=2282) |

The2205 completion is Shaw's, not Renzik's: its suggestion of an inn is not reassigned as his actual dialogue. Keryn's2300 calls Renzik second in command; Hulfdan2298 calls him an old friend; Erion2260 sends a promising rogue from Darnassus. Renzik2281 refuses premature field deployment and sends the novice to Lucius in Lakeshire. Lucius owns the lockbox practice, certificate and insulting assessment in2282. His [Certificate7907](https://forever.warcraftdb.com/api/data/node/item/7907) is a quest item reward, not a BuddyDex friendship reward. No lockpicking skill, class training or admission to SI:7 is granted by friendship.

The Classic2282 page links2358 Horns of Nez'ra. Its full [Classic text](https://classicdb.ch/?quest=2358) and installed offer/completion were also read; current Forever2358 returned404. Arantir's Shadow/Ravenholdt material belongs to that historical branch and is not made into Renzik's present task. These are the relevant training branches, not a claim to have researched every subsequent rogue quest.

Also read all33pages of Blizzard's official [The Tipping Point, Andrew Robinson](https://blz-contentstack-assets.akamaized.net/v3/assets/blt3452e3b114fab0cd/blt49c2308a210d07cf/67b60bb4ab53dff714d2878c/WOW_Renzik_EN.pdf). It recounts a different, more elaborate early encounter with Shaw in Undermine. It is later-published continuity, not evidence that Forever replaced the installed Barrens account. Neither history is spliced into the other. The profile follows installed gossip and Classic-era quests; cartel-origin scenes, the borrowed dagger, family escape and coin are not imported. Likewise exclude later Draenor, Uncrowned, Undermine campaign and death material. Official story publication is not treated as proof of a Forever change.

Renzik's habit of referring to himself by name is visible directly in2281. New dialogue retains it, with a small first-person admission only in the closest friendship writing. The relieved grunt, rehearsed assessment and almost-spoken welcome are original BuddyDex characterization. His concern for novice readiness is established; a particular recruit returning or named historical casualty is not invented. SALUTE acknowledges competence without turning him into a different military role.

## Wrenix: Forever salvage and the historical rogue chain

| Quest | Forever | Classic |
| --- | --- | --- |
| 97253 Parts and Pieces | [node](https://forever.warcraftdb.com/api/data/node/quest/97253) | No Classic entry |
| 2378 Find the Shattered Hand | [node](https://forever.warcraftdb.com/api/data/node/quest/2378) | [text](https://classicdb.ch/?quest=2378) |
| 2380 To Orgrimmar! | [node](https://forever.warcraftdb.com/api/data/node/quest/2380) | [text](https://classicdb.ch/?quest=2380) |
| 2379 Zando'zan | [node](https://forever.warcraftdb.com/api/data/node/quest/2379) | [text](https://classicdb.ch/?quest=2379) |
| 2382 Wrenix of Ratchet | [node](https://forever.warcraftdb.com/api/data/node/quest/2382) | [text](https://classicdb.ch/?quest=2382) |
| 2381 Plundering the Plunderers | [node](https://forever.warcraftdb.com/api/data/node/quest/2381) | [text](https://classicdb.ch/?quest=2381) |

Read all six current full descriptions/objectives, five Classic full offer/progress/completion texts, and all six installed offer/completion texts. The two initial Horde referrals are alternatives, not sequential journeys. Shenthul/Zando'zan's anti-Thrall statements are theirs; do not assign those political intentions to Wrenix merely because they send a rogue to him. Historical2381 sends a thief onto Tide Razor for Southsea Treasure with tools/E.C.A.C. and warns of hostile parrots. It is not in the current own NPC table; retain as historical context, not an advertised current rogue service.

Forever97253 is the current hook: after prior failed attempts he sends a machine against pirates, they dismantle it, and he requests five [Handfuls of Complicated Parts277331](https://forever.warcraftdb.com/api/data/node/item/277331) for reuse. The installed completion names Gagsprocket's metal-cost lectures, his eagerness for another prototype, and his failure to plan a reward. [Scuffed Shipping Crate277332](https://forever.warcraftdb.com/api/data/node/item/277332) is actually a container/bag quest reward, not evidence of a particular empty box or of contents. No claim of an empty reward, sale price, bag size or Companion item grant is made. The [secondary full quest record](https://www.foreverdb.app/en/forever/quests/97253/parts-and-pieces) supplies progress text demanding metal; that line was not exposed in the primary API or installed offer/completion and is attributed accordingly. Its displayed campfire drop listing is not used as proof of actual loot behavior.

Wrenix's unbuilt-machine demonstration, an audience holding an imaginary lever and the secret pleasure of an uninterrupted grand finish are original. They build on his verified prototype enthusiasm while preserving the careless attitude to failed expeditions and rewards; there is no claimed canon reform, working device, actual animation or minigame. APPLAUD is the favorite. Fifteen supported lines/four hidden delivery tags each NPC are queued for later synthesis. No directly relevant readable book was identified for Wrenix; this is not a claim of an exhaustive library survey.

## Other inspected leads

Jubie8678 primary node returned404 although empty relationship endpoints responded; neither availability nor removal is inferred. Blizrik8131 has a current Horde Neutral Goblin gunsmith node and eight goods, no quests/training, but is outside the retained catalog. Neither was authored, added to the reviewed roster or counted. Renzik and Wrenix are the two actual catalog selections.

## Validation and delivery

Main/Scout smoke passes with zero load errors/failures, including all lore/page/line budgets and fresh/existing character storage isolation. Actual-addon harness C:/Users/brett/AppData/Local/Temp/buddydex-renzik-wrenix-718.py passes fresh Alliance Renzik and Horde Wrenix sessions: exact adult displays, approved live/declared Goblin voices, fifteen supported unmapped lines each, favorite validity, attackable/reaction3 rejection without discovery, nonattackable reaction5 Renzik/reaction4 Wrenix acceptance, HELLO25 plus favorite150 yielding175,99/100 and299/300 tier boundaries, companion rejection at299 and text-only welcome at300 without mismatched audio. Generic guards remain excluded. These are actual-addon mocked checks, not live game observations. No runtime or saved-variable changes.

718 fully written profiles / 454 with initial signature recordings / 264 written-complete audio-pending. Renzik6946 and Wrenix7161 add30 personal jobs/4140 tagged input characters in approved goblin-male. Full offline audit12425 missing jobs/895608 tagged input characters: shared3548/personal8877, no MiniMe gaps. Queue `C:/Users/brett/BuddyDex-builds/voice-backfill/profiles-718/queue.json`. Previous queue retained exactly, with only these thirty jobs added. Two uncertain Westfall identities remain unprofiled in the local backlog; Fimbo and five transformed-display Nightclaw candidates remain deferred external leads. Catalog1536 name groups/1549 retained identities unchanged and overlapping the backlog. No synthesis in this batch.

Explicit Friendly304Alliance/281Horde/158unverified, twenty-five shared overlaps, yields718 unique profiles. Goblin coverage46. Renzik is a capital contact, Wrenix a Ratchet early route contact; neither establishes new level-one coverage. Wrenix Neutral is counted unverified for explicit Friendly totals. Developmentv003 installation verified6362files; ZIP6362files/6334audio mappings/138.66MiB. Source, installed and ZIP Lore bytes match; ZIP CRC passes. SHA256 `318161bc04e2b1285703a50f36fd7ea3cb703c600670e30a179e5f02b3ec5134`. Publishedv002 untouched; no tag or CurseForge publication.
