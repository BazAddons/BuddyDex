# Valley of Trials: Hana'zua and Zureetha Fargaze

Reviewed 2026-11-09 for the balanced starter-coverage rotation. Both remain subject to normal live friendly/attackable checks and the adult-only policy. No personal Scout encounter is claimed.

## Identity and current availability

The current Forever definitions cached during the coverage pass identify [Hana'zua 3287](https://forever.warcraftdb.com/api/data/node/npc/3287) as a troll humanoid, adult display 2025, and [Zureetha Fargaze 3145](https://forever.warcraftdb.com/api/data/node/npc/3145) as an orc humanoid, adult display 1875. Cached client DB2 display/extra records resolve these to race 8/sex 0 and race 2/sex 1 respectively. The nodes list two starts/one end and three starts/three ends, but omit location/reaction fields. A fresh API request returned 403; this is not evidence of removal. The public-icon audit therefore keeps reaction unverified rather than inventing an icon.

Current published [Hana'zua](https://www.wowhead.com/forever/npc=3287/hanazua) and [Zureetha](https://www.wowhead.com/forever/npc=3145/zureetha-fargaze) pages place them in Durotar. Current Forever quest pages and the installed English quest corpus independently retain the Classic Valley of Trials stories. Classic Horde quest/identity records provide the friendly starter context; no claim is made that a public page proves the present player's reaction or reputation.

## Hana'zua

Read the full objective, description, progress and completion of [Sarkoth 790](https://classicdb.ch/?quest=790), and the objective, description and completion of its follow-up [804](https://classicdb.ch/?quest=804); the latter has no separate progress passage on that page. [Forever 804](https://www.wowhead.com/forever/quest=804/sarkoth) independently retains the aid request and Gornek's answer. Forever 790 was blocked to the web reader; installed `Spoken_Quests/Data/QuestText.lua` supplies its acceptance/completion text, matching the Classic baseline.

Confirmed: Hana'zua was hunting scorpids, injured Sarkoth's claw, then suffered a caught leg and chest wound. He waits under a tree, worries about his father's low opinion and asks for Sarkoth's claw. The follow-up gives him renewed resolve and sends word to Gornek, who promises aid. A promise to send help does not prove an on-screen cure, an eventual death or a completed recovery. The authored biography leaves the quest open; companion dialogue does not announce that he is healed.

The Forever NPC page has the urgent quest-related call for the player to hurry. No separate Hana'zua gossip entry was found in the installed `SpokenQuestsAudioGossip` NPC-ID or name tables. The wiki's later Canaga referral and renamed Back to the Den progression belong to the Cataclysm version and are excluded. Targeted lore/reference searches established no additional Classic personal novel/comic story; no hunter class, named father or later fate is invented.

Original BuddyDex writing: he watches an ant persist with a crumb while he rests, and finds a little hope in it. The rumor that he is planning another hunt is an authored misunderstanding, not a new quest. The private kindness, friendship thoughts and favorite COMFORT are original. The ant is an ordinary observation, not a named pet, spirit or reward.

## Zureetha Fargaze

Read objective, description, progress and completion of [Vile Familiars 792](https://classicdb.ch/?quest=792) and [Burning Blade Medallion 794](https://classicdb.ch/?quest=794), plus all available stages of [Report to Sen'jin Village 805](https://classicdb.ch/?quest=805). Independently read the corresponding current Forever text for [792](https://www.wowhead.com/forever/quest=792/vile-familiars), [794](https://www.wowhead.com/forever/quest=794/burning-blade-medallion), and [805](https://www.wowhead.com/forever/quest=805/report-to-senjin-village). Installed acceptance/completion text also matches these stories.

Read the related warlock branch: Ruzan's [Vile Familiars 1485](https://www.wowhead.com/forever/quest=1485/vile-familiars), including its progress/completion and imp-summoning context, then [1499](https://www.wowhead.com/forever/quest=1499/vile-familiars), which sends the pupil to Zureetha. Those summoning lessons are Ruzan's, not Zureetha's; her profile grants no spell or trainer access. The installed corpus independently retains both branches.

For the report's downstream context, read [Report to Orgnil 823](https://classicdb.ch/?quest=823), [Dark Storms 806](https://classicdb.ch/?quest=806), [Margoz 828](https://classicdb.ch/?quest=828), [Skull Rock 827](https://classicdb.ch/?quest=827), and [Neeru Fireblade 829](https://classicdb.ch/?quest=829). These show the regional investigation continuing beyond Zureetha. They do not establish that she conducted the other NPCs' research, knows all later revelations, or personally trusts Neeru's claims.

Confirmed: she was sent to guide novices, discovers the Burning Blade threat, uses divination to locate the medallion, and directs a report to Master Gadrin. Her praise after a completed task coexists with concern that the threat is wider. No separate installed NPC-ID/name gossip entry was found. Later retail Tracking a Killer/Dead Peon/Gor'krosh scenes are excluded. No additional Classic personal novel/comic story was established.

Original BuddyDex writing: she occasionally enjoys silly animal shapes in passing clouds. This ordinary amusement is distinct from her actual quest divination; the rumor misinterprets her glance upward. No new omen, prophecy, ritual, relationship or magical item is invented. Favorite NOD and private friendship remarks are authored.

## Production and checks

Each profile contains all ten journal fields and fifteen supported personal companion lines. Four first-line Eleven v4 signatures: Hana'zua greet/idle/befriended/comforted in approved troll male A (`X3ETuf4PfUMURFMpRT73`); Zureetha greet/idle/befriended/quest in approved orc female C (`QooG6jOovlSJWv2vSqN8`). Delivery tags express his weary hope and her rough, firm warmth without appearing in the speech bubbles. Metadata retains exact written/spoken text, model and source identity.

Validation covers journal budgets, supported moments, racial routing, all eight clip mappings and audio format/duration/signal, discovery and daily favorite gains, and the first recorded Buddy welcome. The main and Scout smoke suites and release/install verification also run before shipping.
