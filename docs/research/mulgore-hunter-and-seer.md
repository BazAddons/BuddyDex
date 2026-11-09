# Mulgore starter coverage: Grull Hawkwind and Seer Graytongue

Reviewed 2026-11-09. These profiles continue the coverage rotation after Chief Hawkwind. No personal Scout encounter, universal friendly reaction or live quest completion is claimed. Normal per-character progress, adult exclusions and live reaction/attackability checks remain in force.

## Identity and current evidence

| NPC | ID | Adult display | Cached DB2 identity | Route |
| --- | ---: | ---: | --- | --- |
| Grull Hawkwind | 2980 | 3808 | Tauren, race 6 / male sex 0 | Camp Narache, Red Cloud Mesa |
| Seer Graytongue | 2982 | 3813 | Tauren, race 6 / male sex 0 | Hills south of Camp Narache |

Current [Grull node](https://forever.warcraftdb.com/api/data/node/npc/2980) explicitly reports a Horde-friendly icon; [Graytongue's node](https://forever.warcraftdb.com/api/data/node/npc/2982) supplies name, race, humanoid type and model but no reaction. Both model IDs match their Classic definitions and resolve through current cached client display/extra tables to adult male Tauren models. The published current Forever pages independently identify [Grull in Mulgore](https://www.wowhead.com/forever/npc=2980/grull-hawkwind) and [Graytongue in Mulgore](https://www.wowhead.com/forever/npc=2982/seer-graytongue).

The public current relation tabs are incomplete: [Grull's starts tab](https://forever.warcraftdb.com/api/data/node/npc/2980/tab/starts) only lists 747, while Graytongue has no quest tabs. Their existing published Forever quest text and installed dialogue retain the wider stories. Missing relation rows do not prove those quests removed; neither do they prove a personal in-game sighting. Graytongue remains reaction-unverified in the public-icon audit. Classic quest context and current published/installed quest text supply his starter role, while live eligibility remains authoritative.

External raw source snapshots are kept outside the repository in `BuddyDex-builds/mulgore-pair-research`; the research facts and source links are retained here.

## Grull Hawkwind

Read objective, description, progress and completion text for the complete hunting sequence, both [Classic 747](https://classicdb.ch/?quest=747), [750](https://classicdb.ch/?quest=750), [780](https://classicdb.ch/?quest=780) and current [Forever 747](https://www.wowhead.com/forever/quest=747/the-hunt-begins), [750](https://www.wowhead.com/forever/quest=750/the-hunt-continues), [780](https://www.wowhead.com/forever/quest=780/the-battleboars). Installed `Spoken_Quests/Data/QuestText.lua` independently matches all three acceptance/completion passages.

Confirmed: he helps supply Narache, asks for plainstrider meat/feathers and cougar pelts, and targets Bristleback-trained battleboars encroaching on the hunting grounds. Supplies mean food, clothing and tent repairs, not just trophies. Chief Hawkwind is explicitly his father. The Chief/Greatmother primary Humble Task sequence also establishes Greatmother as Grull's grandmother; the profile adds no named relatives. Hunting is a demonstrated role, not a claimed player-class/trainer service.

Read all available stages of the four class referrals: [Simple Note 3091](https://classicdb.ch/?quest=3091), [Etched Note 3092](https://classicdb.ch/?quest=3092), [Rune-Inscribed Note 3093](https://classicdb.ch/?quest=3093), [Verdant Note 3094](https://classicdb.ch/?quest=3094). Also read the complete embedded book pages for items [9547](https://classicdb.ch/?item=9547), [9565](https://classicdb.ch/?item=9565), [9552](https://classicdb.ch/?item=9552), [9581](https://classicdb.ch/?item=9581). Grull passes the notes along; the teaching and personal claims in the letters belong to Harutt, Lanka, Meela and Gart respectively. No spell, training or acceptance into Thunder Bluff is granted through BuddyDex.

Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` includes Grull's welcoming Camp Narache greeting. The later Cataclysm revenge dialogue, Greatmother's death, captive-rescue quests and succession predictions are excluded. Targeted reference searches established no separate Classic personal novel/comic history to incorporate.

Original writing: he enjoys the rich last spoonful left in the stew pot and makes hopeful inspections after meals. This modest habit builds on the provision/stew quests without claiming that he is a cooking trainer, vendor or the sole camp cook. The rumor, private history, friendship remarks and favorite THANK are original BuddyDex details.

## Seer Graytongue

Read all available objective, description, progress and completion text for [755](https://classicdb.ch/?quest=755) and [757](https://classicdb.ch/?quest=757), plus the corresponding current [Forever 755](https://www.wowhead.com/forever/quest=755/rites-of-the-earthmother) and [757](https://www.wowhead.com/forever/quest=757/rite-of-strength). Installed acceptance/completion text independently retains those passages.

Confirmed: Chief Hawkwind sends initiates to the seer's abode south of Narache. Graytongue introduces the Rite of Strength against the Bristlebacks threatening village and hunting parties. The Chief receives the belts and awards completion. The profile does not transfer that role or all the later rites to Graytongue. It invents no prophecy, ritual, blessing or companion spell.

Reviewed the full related rites context using the previously cached primary quest text: [752](https://classicdb.ch/?quest=752), [753](https://classicdb.ch/?quest=753), [763](https://classicdb.ch/?quest=763), [767](https://classicdb.ch/?quest=767), [771](https://classicdb.ch/?quest=771), [772](https://classicdb.ch/?quest=772), [773](https://classicdb.ch/?quest=773), [775](https://classicdb.ch/?quest=775), [776](https://classicdb.ch/?quest=776). The vision-water preparation belongs to Zarlman Two-Moons, the next seer is Wiserunner, the ancestral blessing belongs to the Ancestral Spirit, and the final hunting commission belongs to Cairne. None becomes a Graytongue companion power or a claim that the player has completed those quests.

No Graytongue NPC-ID gossip entry was found in the installed corpus. Later Cataclysm burned-hut/bones/quilboar scenes and presumed death are excluded. Reference search found the licensed tabletop RPG [*Lands of Mystery*](https://public.ds003.info/wcbooks/rpg/WORLD%20OF%20WARCRAFT%20%20-%20Lands%20of%20Mystery%20By%20Azamor.pdf): its Camp Narache paragraph names him as a spiritual leader sending initiates on rites. That paragraph was inspected, but its noncanonical setting details, population numbers and adventure suggestions are not used as Forever facts. No separate Classic novel/comic history was established.

Original writing: he privately enjoys making ridiculous rhymes, including the intentionally poor Bristleback/whistle-back pairing. The muttered words are not a spirit message or a new religious practice. His small pleasure and friendship behavior do not alter the seriousness of the actual rite. Favorite GRIN is authored.

## Audio and validation

Each has all ten journal fields and fifteen personal lines using supported companion moments. Four Eleven v4 first-line signatures each: Grull greet/idle/befriended/quest; Graytongue greet/idle/befriended/learned. Both use the selected Tauren male C voice `UHjFz97GTxtpwstZu19x`, with distinct per-line directions for Grull's hearty warmth and Graytongue's composed humor. Per-voice metadata retains exact text, spoken delivery, model and source identity.

Checks cover journal budgets, line counts/moments, adult/named identity, model-to-voice routing, all eight clip mappings and audio format/duration/signal, first discovery and favorite-emote points, and recorded Buddy welcomes. The BuddyDex and Scout smoke suites and release/install verification run before shipping.
