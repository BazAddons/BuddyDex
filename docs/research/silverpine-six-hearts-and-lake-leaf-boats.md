# Renferrel and Denalan: six hearts and leaf boats

Researched 2026-11-09. This completes the research begun in [the queue](renferrel-and-denalan-queue.md). No new Scout sighting or live in-game conversation is claimed. External cache: `C:/Users/brett/BuddyDex-builds/renferrel-denalan-research`; Classic quest pages also cached in `crossroads-research`.

## Identity and access

- [Apothecary Renferrel 1937](https://forever.warcraftdb.com/api/data/node/npc/1937): named humanoid, Royal Apothecary Society title, Undead, level 14; current Horde-icon Friendly. Silverpine Forest map 1421, about 42.9, 40.9, the Sepulcher. Current display 1661 -> installed DB2 extended display race 5, sex 0: standard adult male Forsaken. Runtime routes `forsaken-male`, approved voice `xNLT6f0TsMKlsUoMALsm`.
- [Denalan 2080](https://forever.warcraftdb.com/api/data/node/npc/2080): named humanoid Night Elf, level 11; current Alliance-icon Friendly. Teldrassil map 1438, about 60.9, 68.5, east shore of Lake Al'Ameth. Display 2484 -> DB2 race 4, sex 0: standard adult male. Runtime routes `nightelf-male`, approved voice `I9kX73xcHhkTOd7JNhet`. His level does not imply age. His botanical work does not alone establish a player class.

Neither a profile nor a public friendly icon bypasses the live named/adult/reaction/non-attackability checks. No quest or profession prerequisite added. No blanket friendship for generic guards, mobs or children.

## Relations and dialogue reviewed

Read both complete Classic NPC relation lists and all eight current `/tab/starts`, `/ends`, `/teaches`, `/sells` responses. Current lists each fit one page; both have no teacher/vendor rows.

- Renferrel current starts 447, 451, 493, 448, 430, 91921, 444; ends 450, 445, 443, 446, 91920, 429. Classic starts 430, 444, 447, 448, 451, 493, 1359; ends 429, 443, 445, 446, 450, 3221.
- Denalan current starts 2499; ends 2499, 2498, 931. Classic starts 918, 919, 922, 941, 2499; ends 918, 919, 927, 930, 931, 997, 2498, 2499. Sparse current relations do not prove all omitted historical quests removed or presently offered.

Read exact installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` entries: Renferrel's Society challenge against Arthas, Denalan's concern for balance following Teldrassil's creation. Read installed `Spoken_Quests/Data/QuestText.lua` name matches and exact connected quest blocks; these are installed dialogue data, not captured player speech. Player names/encoding artifacts in those files are not character lore.

### Renferrel: healing, toxins and the Society

Read all available objectives, description, progress and completion on the linked Classic pages, plus installed counterparts:

- [428 Lost Deathstalkers](https://classicdb.ch/?quest=428), [429 Wild Hearts](https://classicdb.ch/?quest=429), [430 Return to Quinn](https://classicdb.ch/?quest=430), [425 Ivar the Foul](https://classicdb.ch/?quest=425): Hadrec sends the search; Rane Yorick requests aid for her brother Quinn after Ivar mauls him. Renferrel provides potion and recipe while impatient to resume important work. Classic 429 requires six hearts and Classic 430 reports success.
- Forever [429](https://www.wowhead.com/forever/quest=429/wild-hearts) instead requires three hearts. Read full [91920 Wild Eyes](https://www.wowhead.com/forever/quest=91920/wild-eyes) and [91921 Return to Quinn (Again)](https://www.wowhead.com/forever/quest=91921/return-to-quinn-again), including progress and completion, against installed text. Quinn reports the first treatment ineffective and suggests murloc eyes despite fearing Renferrel's reaction. Renferrel points out the six-heart recipe/three-heart delivery, considers the new material and contributes hearts from his stock. A second potion then works. His reference to his own hearts does not establish extra anatomical organs. Do not claim Classic's first-potion success is the whole Forever sequence.
- [435 Escorting Erland](https://classicdb.ch/?quest=435), [449 The Deathstalkers' Report](https://classicdb.ch/?quest=449), [3221 Speak with Renferrel](https://classicdb.ch/?quest=3221), [1359 Zinge's Delivery](https://classicdb.ch/?quest=1359), [1358 Sample for Helbrim](https://classicdb.ch/?quest=1358): Erland reaches Rane; the report goes to Hadrec. Renferrel notices unusual toxicity in the wolf hearts and sends samples to Zinge. Zinge sends a sample onward to Helbrim at the Crossroads. Distinguish each speaker's research; this does not make Renferrel a Crossroads resident.
- [437 The Dead Fields](https://classicdb.ch/?quest=437), [438 The Decrepit Ferry](https://classicdb.ch/?quest=438), [439 Rot Hide Clues](https://classicdb.ch/?quest=439), [443 Rot Hide Ichor](https://classicdb.ch/?quest=443), [444 Rot Hide Origins](https://classicdb.ch/?quest=444), [446 Thule Ravenclaw](https://classicdb.ch/?quest=446), [448 Report to Hadrec](https://classicdb.ch/?quest=448), [442 Assault on Fenris Isle](https://classicdb.ch/?quest=442): Hadrec's investigations expose corpse transport and the Rot Hides. Renferrel separates ichor components, recognizes magical origins, and seeks Bethor's expertise. Thule was **Bethor's** former colleague, not an invented old friend of Renferrel. Bethor's scroll supports a protective potion; Renferrel admits this use of magic is new to him. Hadrec orders the assault. Its completion reports Renferrel sensing the released energies at the Sepulcher; he does not personally kill Thule.
- Read the related ring branch [440](https://classicdb.ch/?quest=440), [441](https://classicdb.ch/?quest=441), [530](https://classicdb.ch/?quest=530) completely. Deliah's stolen corpse leads through Sevren to Raleigh's revenge against Valdred. Raleigh's professed lack of grief is his own dialogue, not a universal rule for all Forsaken or a relationship belonging to Renferrel.
- [493 Journey to Hillsbrad Foothills](https://classicdb.ch/?quest=493): Renferrel shares findings under pressure to develop the New Plague; Lydon respects his work. This referral does not assign Lydon's entire later campaign to Renferrel.

[The preceding Johaan research](brill-last-words-and-unnecessary-questions.md) already reads full 445 delivery and 447 -> 450 -> 451 Recipe For Death, installed counterparts and all three embedded pages of Berard's Journal 3255. Preserve that evidence: Johaan's findings, Berard's lake/plague observations and Faranell's role belong to those individuals. Renferrel's aid to Quinn is real, alongside his Society weapons research. Neither a purely kindly healer nor an invented redemption arc fits the evidence.

### Denalan: a grower's hope and limits

Read the full available Classic quest text and installed counterparts:

- [997 Denalan's Earth](https://classicdb.ch/?quest=997): a colleague's delayed rare-earth shipment arrives via Dolanaar; Denalan is eager to receive it. Location and plant experiments are explicit. Do not invent a readable scientific treatise inside the package.
- [918 Timberling Seeds](https://classicdb.ch/?quest=918), [919 Timberling Sprouts](https://classicdb.ch/?quest=919): timberlings reflect Teldrassil's natural order. He suspects soil and prepares special growing conditions, but also requests removal of sprouts he considers beyond help. These are hopes and judgments, not a proven universal cure.
- [922 Rellian Greenspyre](https://classicdb.ch/?quest=922), [923 Tumors](https://classicdb.ch/?quest=923), [2498 Return to Denalan](https://classicdb.ch/?quest=2498), [2499 Oakenscowl](https://classicdb.ch/?quest=2499): Denalan explicitly calls Rellian his friend. Rellian cannot repair tainted seeds, requests destruction of severely corrupted timberlings and burns their tumors. Denalan then identifies Oakenscowl as a source of local corruption, requests his death/tumor for study, and regrets the former leader's condition. Do not write Denalan as refusing all killing, solving all corruption or proving that nobility prevents disease.
- [927 The Moss-twined Heart](https://classicdb.ch/?quest=927), [941 Planting the Heart](https://classicdb.ch/?quest=941): Blackmoss's still-beating heart is investigated; removing moss is insufficient. Denalan's planter successfully cleanses **that heart**. The quest does not prove all timberlings cured.
- [930 The Glowing Fruit](https://classicdb.ch/?quest=930): he finds its interaction with Teldrassil soil unusual and speculates about a distant seed origin. The suggested origin is not an established fact.
- [931 The Shimmering Frond](https://classicdb.ch/?quest=931): explicitly remembers a Swamp of Sorrows visit decades earlier and marvels at the plant's size on Teldrassil. This supports the one past journey without inventing family, birthplace or a migration narrative.
- [2399 The Sprouted Fronds](https://classicdb.ch/?quest=2399): short garden-object completion reports successful growth/harvest. No longer description/progress exists on the inspected page. The wordless object reward is not a new speech by Denalan.

## Items, literature and era boundaries

Inspected complete Classic item pages: wolf samples [10283](https://classicdb.ch/?item=10283)/[6016](https://classicdb.ch/?item=6016), ichor [3237](https://classicdb.ch/?item=3237), Bethor's Scroll [3250](https://classicdb.ch/?item=3250), findings [3468](https://classicdb.ch/?item=3468), earth [5391](https://classicdb.ch/?item=5391), tainted/cleansed hearts [5217](https://classicdb.ch/?item=5217)/[5218](https://classicdb.ch/?item=5218). No embedded readable Book bodies on these inspected pages. Findings are sealed. The cleansed heart summons a protective timberling temporarily; do not turn that item mechanic into a universal cure or a permanently acquired named NPC. Berard's actual readable journal was reviewed in the linked preceding note.

Searched exact names for book/comic/novel evidence. Found a [BradyGames atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf) listing Renferrel at the Sepulcher, not additional narrative history. No verified additional relevant narrative found. Warcraft Wiki's Denalan page/raw access returned 403; do not claim that page read. The [Classic Denalan page](https://www.wowhead.com/classic/npc=2080/denalan) corroborates gossip and lists observed speech, but player comments/duplicated personalized utterances do not establish extra ancestry. No verified dwarven ancestry, novel/comic appearance or later-retail biography used. No later catastrophe, move, death or New Plague outcome projected onto Forever.

## Original BuddyDex writing

Renferrel's coin-toss dispute, prediction excuses and private enjoyment of chance are modest original writing. They contrast his scientific precision without rewriting his allegiance, healing work or impatience. Denalan's fallen-leaf boats, deliberately slower choice and willingness to extend a conversation are original, grounded in his lakeside setting. Only the frond recollection in his backstory is established history. Gossip, secrets, favorite-emote hints and personal companion exchanges are authored for BuddyDex, not game quotes.

Ten fields, fifteen personal lines and four signatures per profile. Explicit hidden delivery tags; approved Forsaken/Night Elf male voices with Eleven v4.

## Validation and delivery

- Full-TOC preflight verifies named/adult identity, exact display voice routes, fifteen supported personal lines each, quote/preference limits and wrapped lore budgets. Renferrel uses 21 lore lines, Denalan 20; every section fits its limit.
- All eight generated clips match the authored text, hidden tone, exact approved voice ID, `eleven_v4` model, source ID and runtime mapping. Decoded mono 22050 Hz Ogg audio is finite, non-silent, and between 0.5 and 25 seconds. This is automated audio validation, not a claim of human listening approval.
- Fresh-session checks reject attackable/unfriendly targets; eligible HELLO adds 25 points, the favorite adds its independent 150, and first outing plays exactly one correct recorded welcome and records its flag. Generic Dwarf Guard/Stormwind Guard remain excluded; Guard Thomas remains eligible.
- Full BuddyDex smoke: 23 files, zero load errors/failures. Scout: six files, zero load errors/failures. SavedVariables globals reported as informational checks, final PASS. No live-game visual QA claimed.
- Backlog refreshed: **364 complete, four queued**, alongside the wider **1510 name-group** catalog; the four are not the total remaining world scope. Public friendly access: Alliance 195, Horde 79, unverified 96, with six shared entries overlapping.
- Installed and hash-verified **5990 release files**, ten updated. Separate development `C:/Users/brett/BuddyDex-builds/development/BuddyDex-v002.zip` verified: **5990 files, 5962 audio mappings, 113.43 MiB**. No docs, tools, source manifests or character saves included in the release.
- Original handed-off candidate preserved with SHA256 `696a680d5baa18c35df523976257fd48b413e2d357b004f9bc9b46ab4403645b`. No CurseForge tag/upload; publication remains deferred.
- Next individually reviewed pair: [Dalar and Syral](dalar-and-syral-queue.md), with Dalar's neutral public access explicitly distinguished from a friendly-access claim.
