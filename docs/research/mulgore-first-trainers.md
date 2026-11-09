# Mulgore first trainers: Lanka Farshot and Meela Dawnstrider

Reviewed 2026-11-09. This batch brings authored Mulgore starter profiles to five: Chief Hawkwind, Grull Hawkwind, Seer Graytongue, Lanka and Meela. It does not establish the same coverage in other starting areas. No personal Scout sighting or live reaction is claimed, and normal adult/named/friendly/attackable eligibility checks remain authoritative.

## Identities and source limits

| NPC | ID | Adult display | Current cached DB2 identity | Role / route |
| --- | ---: | ---: | --- | --- |
| Lanka Farshot | 3061 | 3810 | Tauren race 6 / male sex 0 | Hunter trainer, Camp Narache |
| Meela Dawnstrider | 3062 | 10180 | Tauren race 6 / female sex 1 | Shaman trainer, Camp Narache |

Current [Lanka node](https://forever.warcraftdb.com/api/data/node/npc/3061) and [Meela node](https://forever.warcraftdb.com/api/data/node/npc/3062) explicitly supply names, trainer titles, Tauren/humanoid identity and these model IDs. Classic definitions use the same displays. Neither current node exposes a reaction or quest tabs, so both remain unverified in the public-icon audit. This is not evidence of removal or neutrality. Current published Forever quest text and installed class-specific greetings independently retain their Narache roles; Classic Horde quest records supply baseline access context without overriding live checks.

The current [Lanka page](https://www.wowhead.com/forever/npc=3061/lanka-farshot) independently identifies his Mulgore trainer role. Meela's current NPC page presents a robot check; it is not claimed read beyond that. The [official licensed Atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf), relevant Mulgore entries only, independently places both trainers in Narache's northern main tent. Its historical grid is not a current live coordinate measurement.

Raw snapshots are outside the repository in `BuddyDex-builds/mulgore-trainers-research`. Current cached display/extra tables establish race/sex and adult character models; age is not inferred from level, stature or name.

## Lanka Farshot

Read objective, description, progress and completion text in [Classic Etched Note 3092](https://classicdb.ch/?quest=3092) and [Forever 3092](https://www.wowhead.com/forever/quest=3092/etched-note), plus the complete embedded page of [Etched Note 9565](https://classicdb.ch/?item=9565). Grull passes the letter; Lanka's writing places hunters in service to their people, combining guidance and protection. He prepares pupils to know Mulgore before unfamiliar lands. The profile does not turn that general teaching into a new racial power or claim that friendship confers training.

Read [The Hunter's Path 6066](https://classicdb.ch/?quest=6066), its [current Forever text](https://www.wowhead.com/forever/quest=6066/the-hunters-path), and the entire linked pet-training sequence: [6061](https://classicdb.ch/?quest=6061), [6087](https://classicdb.ch/?quest=6087), [6088](https://classicdb.ch/?quest=6088), [6089](https://classicdb.ch/?quest=6089). All available objective/description/progress/completion passages were inspected. The final 6089 primary page exposes no separate progress/completion speech, so none is invented. Lanka refers the hunter to Yaw Sharpmane; Yaw's plainstrider, prairie stalker and swoop lessons then lead to Holt Thunderhorn in Thunder Bluff. Those later lessons/rewards are not transferred to Lanka or BuddyDex.

Installed `Spoken_Quests/Data/QuestText.lua` independently matches acceptance/completion for 3092 and 6066. Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` includes Lanka's guns-or-bows greeting, other-class refusal and the shared retraining explanation. Retraining text is not a unique biographical trauma. Non-hunters may be friends through eligible emotes; friendship does not bypass trainer class restrictions.

Later retail Steady Shot/training-dummy quests with a similar Hunter's Path title are excluded. The reference wiki's possible *Looking For Group* comic allusion and shared surname with Mixie Farshot do not establish kinship, adoption or a canonical personal comic story. No such relationship is added. No additional Classic personal novel/comic history was established.

Original writing: Lanka practices an imperfect bird whistle and enjoys being answered, without knowing whether the bird approves. This is an ordinary pastime, not a new pet, spell, race trait or hunting ability. His warmth toward a fellow learner, rumor, private history and favorite NOD are authored.

## Meela Dawnstrider

Read objective, description, progress and completion in [Classic Rune-Inscribed Note 3093](https://classicdb.ch/?quest=3093) and [Forever 3093](https://www.wowhead.com/forever/quest=3093/rune-inscribed-note), and the complete embedded page of [Rune-Inscribed Note 9552](https://classicdb.ch/?item=9552). Meela describes understanding the elements and ancestral spirits, invites pupils to return, and hopes each meeting leaves them better prepared. Her actual spiritual teaching is retained without inventing a prophecy or a new elemental ceremony. Grull's related [The Hunt Begins 747](https://classicdb.ch/?quest=747) context and his provision chain were reviewed in the preceding [Grull research](mulgore-hunter-and-seer.md).

Installed quest acceptance/completion independently matches 3093. Her installed gossip includes a shaman welcome, a well-wishing greeting for other classes, and shared talent retraining text. Neither current nor Classic NPC definitions reviewed establish another personal Classic quest chain. Other shamans' elemental-initiation quests are not reassigned to her.

Later retail Primal Strike is excluded. A reference points to the Dawnstrider tribe in *The Shattering*, chapter 4; that later-era reference is not a personal Meela scene or evidence of named family relationships, and the novel was not represented as read. No additional Classic personal novel/comic story was established. Enchanting services of other Dawnstriders are not Meela's profession merely because they share a surname.

Original writing: she taps her foot along with rain on the tent, loses the changing beat and starts again with a laugh. This ordinary private enjoyment is explicitly distinct from a spirit conversation, weather control or a ritual. The rumor, friendship remarks and favorite BOW are authored.

## Voice and checks

Each has all ten journal fields and fifteen supported personal lines. Four Eleven v4 first-line signatures each: greet, idle, befriended and learned. Lanka uses approved Tauren male C `UHjFz97GTxtpwstZu19x`; Meela uses approved Tauren female B `HriwExkmKzil2cQ4bGmf`, independently retrieved under its saved BuddyDex Tauren Female (Earthy) name before recording. This is the first bundled female Tauren signature group. Unrecorded lines in these groups remain speech bubbles.

Validation covers journal budgets, line counts/moments, named/adult identity, race/sex routing, exact source/voice/model/delivery metadata, all eight mappings and audio format/duration/signal, ordinary/favorite friendship gains, recorded first Buddy welcomes, and the main/Scout smoke suites. The release ZIP and installed files are verified before shipping.
