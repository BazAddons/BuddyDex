# Orgrimmar questions and common remedies

Research and authoring, 2026-11-09: Kardris Dreamseeker (3344), Sian'tsu (3403), Yelmak (3347). No personal Scout encounter or live UI inspection is claimed. The normal named/adult/reaction/non-attackability gate remains required; authoring never bypasses it.

## Identity and access

- [Kardris current node](https://forever.warcraftdb.com/api/data/node/npc/3344): Orc Shaman Trainer, level 60, Horde-icon **Neutral**, Orgrimmar about 39.0, 36.7. Display 1360 resolves to race 2, sex 1 (female).
- [Sian'tsu current node](https://forever.warcraftdb.com/api/data/node/npc/3403): Troll Shaman Trainer, display 4231, race 8, sex 1 (female). Level/reaction/pin are omitted. [Published Forever identity](https://www.wowhead.com/forever/npc=3403/siantsu) corroborates Orgrimmar; level 40 is a public reference, not a missing-field inference.
- [Yelmak current node](https://forever.warcraftdb.com/api/data/node/npc/3347): Orc Expert Alchemist, display 1368, race 2, sex 0 (male), Orgrimmar about 56.4, 33.6. Level/reaction are omitted; [published identity](https://www.wowhead.com/forever/de/npc=3347/yelmak) corroborates the city. Level 35/Horde public references do not supply a missing current reaction icon.

Body identities were checked against cached CreatureDisplayInfo/CreatureDisplayInfoExtra tables. All are adult standard bodies, with no child exclusion. Access coverage conservatively leaves all three **unverified**: neutral is conditional and absent icons are not friendly proof. Mock reaction 4 tests permissible neutral encounters without claiming an actual encounter. No faction-specific exception is added. Caches are external at `C:/Users/brett/BuddyDex-builds/orgrimmar-spirit-and-alchemy-research`.

## Shaman training and complete referral chain

Exact Classic NPC pages [3344](https://classicdb.ch/?npc=3344) and [3403](https://classicdb.ch/?npc=3403) both list [Elemental Mastery 8410](https://classicdb.ch/?quest=8410). Read all available objectives, descriptions, progress and completion for that quest and [Spirit Totem 8412](https://classicdb.ch/?quest=8412), then [Da Voodoo 8413](https://classicdb.ch/?quest=8413). The installed Spoken_Quests QuestText entries corroborate the chain.

The trainers send an experienced shaman with four elemental samples to Bath'rah the Windwatcher near Tarren Mill. Bath'rah wants protection from displeased spirits: first a totem made with spider eyes and bear/carrion claws from the Western Plaguelands, then feathers from the six named Sunken Temple trolls. The final exchange concerns Bath'rah's own protection and rest. These are **his** rituals and predicament, not evidence that either trainer is corrupted, personally performed them or has killed those characters. Quest items are not presented as a readable lore book. No extra lower-level class referral is assigned from another trainer's listing.

All four current API tabs (`starts`, `ends`, `teaches`, `sells`) returned zero rows for each of this batch's three NPCs; this sparse response does not negate installed/published service or quest evidence. Current quest node 8410 was unavailable. Classic relationships are documented as Classic, not newly observed Forever quest flags.

Exact installed English gossip in `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` gives Kardris a spirit-guided welcome and blessing; Sian'tsu recognizes the spirits in shaman visitors and blesses others. Both have talent-retraining dialogue. Their personal writing does not require the player to be a shaman or to have completed a quest.

## Yelmak: Forever's actual teaching story

Read complete published objective/description/progress/completion text for [Yelmak's Medley 97242](https://www.wowhead.com/forever/quest=97242/yelmaks-medley) and [Whuut's the Rush 97275](https://www.wowhead.com/forever/quest=97275/whuuts-the-rush), alongside exact installed accept/completion passages. [Current 97242 node](https://forever.warcraftdb.com/api/data/node/quest/97242) confirms Kor'geld's involvement. Current node 97275 was unavailable; its published/installed text remains the source, not an invented API record.

Kor'geld arranges collection of two handfuls of cattails and four speargrass cuttings around Valley of Honor water. Yelmak wants to reach an apprentice reluctant to ask for help. Kor'geld explains local herbs' potency and generational experimentation. Yelmak explicitly considers Whuut gifted but too quick to consume rare materials before mastering technique. His ordinary-herb tonic persuades Whuut to reconsider. Whuut's progress line anticipates expensive herbs; his completion acknowledges room to learn and offers earlier brews. A captured player name in the installed completion is not an NPC or canonical participant.

The published series widget mixes unrelated errands. Read [Meal Appeal 97246](https://www.wowhead.com/forever/quest=97246/meal-appeal), [Favorite Food 97249](https://www.wowhead.com/forever/quest=97249/favorite-food), [Philmor's Favor 97220](https://www.wowhead.com/forever/quest=97220/philmors-favor), and [Gatehouse Goods 97222](https://www.wowhead.com/forever/quest=97222/gatehouse-goods), including available progress/completion (no separate progress exposed for Meal Appeal). The first pair concerns Thatog, Borstan and Migi's lunch; the second concerns a Stormwind shipment and Elaine Trias. They do not establish Yelmak as a parent, cook or Gatehouse contact. The series display alone does not prove a linear cross-faction prerequisite chain. No child profile is created.

A player comment suggests [Need for a Cure 812](https://www.wowhead.com/forever/quest=812/need-for-a-cure) as a prerequisite. Its full text concerns Rhinag, Kor'ghan and venomtail antidote. It does not name Yelmak; do not turn the comment into a confirmed relationship or prerequisite. Whuut's Camping 101 alchemy/Mana Well lesson is likewise not assigned to Yelmak.

All four exact installed Yelmak gossip passages were reviewed: he is busy and gruff, refers novices to Whuut, and directs sufficiently advanced learners to Doctor Herbert Halsey in the Undercity Apothecarium. Miao'zan's installed advanced-training referral names Yelmak in the Drag; that is professional contact, not family or an invented close friendship. No Classic quest was exposed on the consulted Yelmak NPC page.

## Era and literary limits

Targeted book/comic searches did not identify an individual narrative to import. A historical official atlas index names the Orgrimmar training/shop locations; it is geographical context, not a personal biography. Later-history checks via [Kardris](https://warcraft.wiki.gg/wiki/Kardris_Dreamseeker), [Sian'tsu](https://warcraft.wiki.gg/wiki/Sian%27tsu), and [Yelmak](https://warcraft.wiki.gg/wiki/Yelmak) were used only to avoid chronology mistakes. Kardris's later Dark Shaman identity, Siege outcome and wolf are omitted. Sian'tsu's funeral appearance and Vision of Orgrimmar corruption/pet are omitted. Yelmak's later funeral, Vision corpse/notes and expanded master specializations are omitted. No age, ancestry, family or war service is invented.

## Original BuddyDex writing and recordings

Kardris's habit of leaving time for shy questions and admitting her own uncertainty, Sian'tsu's unfinished humming tune and wish for a second voice, and Yelmak's privately rehearsed compliments are modest **original fiction**. Preferences, secrets, friendship messages and personal companion dialogue are also original; none is a quotation or a gameplay reward claim. Yelmak's teaching tonic and recognition of Whuut's talent are confirmed facts around that fiction.

Each profile has all ten fields and fifteen personal lines. Four signature selections each: greeting, idle, first friendship welcome, learned. Approved voices are Orc female C `QooG6jOovlSJWv2vSqN8`, Troll female C `0xQXygLnre17fk87G6Kt`, Orc male B `SsUXUYPOaoD5XMe36mlU`, using **Eleven v4** and hidden character delivery tags. No paid regeneration of existing profiles is requested.

## Validation and delivery

All section wrapping budgets (50-character approximation), quote/list limits and fifteen-line totals pass. The exact full-TOC Lua check verifies adult/named eligibility, standard model voice routing, all twelve recordings' exact visible/spoken text, hidden tone, v4 model and approved voice ID, runtime mappings and decoded mono 22.05 kHz finite/non-silent audio. All clips are between 0.5 and 25 seconds. Fresh-session checks reject attackable and reaction-3 units, then award 25 daily greeting points and 150 independent favorite points at mock neutral reaction 4. The first companion outing plays exactly one mapped recorded welcome. Generic guards stay excluded. This is automated verification, not an in-game visual or live access claim.

BuddyDex smoke: 23 files, zero load errors/failures. Scout smoke: six files, zero load errors/failures. Installed and hash-verified **5,782 release files**, with **5,754 runtime audio mappings**. The separate development v002 ZIP passes packaging checks at **103.07 MiB**. Development now has **312 complete profiles**; the old short list has two unresolved Westfall candidates, while the broader 1,493-name pool remains open. The handed-off upload candidate's SHA256 remains `696a680d5baa18c35df523976257fd48b413e2d357b004f9bc9b46ab4403645b`. No publish tag or CurseForge upload was performed.
