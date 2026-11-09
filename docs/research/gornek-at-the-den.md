# Gornek: the Den's recruit guide

Reviewed 2026-11-09. Gornek is the fifth completed authored profile on the Durotar starter route, following Gadrin, Mai'ah, Hana'zua and Zureetha. This is a coverage milestone, not completion of the larger catalog. No personal Scout encounter or live quest completion is claimed.

## Identity, access and current evidence

[Current Forever NPC 3143](https://forever.warcraftdb.com/api/data/node/npc/3143) identifies Gornek as an orc humanoid with adult display 1653. Cached client display/extra records resolve that display to race 2 / male sex 0, matching the Classic definition. His current node omits reaction/location fields, so the public-icon coverage audit retains an unverified reaction. His [current published NPC page](https://www.wowhead.com/forever/npc=3143/gornek) places him in Durotar; current quests and installed dialogue explicitly place him in the Den. Classic Horde quest/identity context does not replace the player's live friendly/attackable check.

The current [starts](https://forever.warcraftdb.com/api/data/node/npc/3143/tab/starts) list contains 788, 3085, 789, 98575 and 97279; [ends](https://forever.warcraftdb.com/api/data/node/npc/3143/tab/ends) contains 788, 804, 789 and 4641. These current relation tables are sparse compared with the published/installed class-referral text, not grounds for assuming every omitted quest removed. Sources were cached outside the repository in `BuddyDex-builds/gornek-research`.

## The first trials and the wounded hunter

Read all available objective/description/progress/completion passages in [Your Place In The World 4641](https://classicdb.ch/?quest=4641), [Cutting Teeth 788](https://classicdb.ch/?quest=788), and [Sting of the Scorpid 789](https://classicdb.ch/?quest=789). The [current 4641 page](https://www.wowhead.com/forever/quest=4641/your-place-in-the-world) independently retains Kaltunk's referral and Gornek's stern response. Current 788/789 web pages were blocked, but their current relation rows and installed `Spoken_Quests/Data/QuestText.lua` acceptance/completion match the Classic baseline.

Confirmed: he gives novices a manageable boar trial instead of sending them against much larger prey, warns against overconfidence, and treats scorpids as a lesson in respecting danger regardless of size. His dialogue mentions the camp's antidote supply. BuddyDex neither grants antidote nor claims he is an alchemist or healer.

Read the complete [Sarkoth 790](https://classicdb.ch/?quest=790) and [804](https://www.wowhead.com/forever/quest=804/sarkoth) story, also researched in [Hana'zua's notes](valley-trials-hunter-and-guide.md). Gornek recognizes Sarkoth, promises aid and praises helping a stranger. This supports practical concern beneath his severity, but it does not prove Hana'zua has recovered or that the present player has already done the quest.

Also read [The New Horde 787](https://classicdb.ch/?quest=787). The Classic page supplies Eitrigg's background but no separate completion passage; installed text supplies Gornek's recruit response. Eitrigg's exile, captivity and reconciliation with Thrall are not Gornek's personal history. The similarly titled in-game history book is not this quest, and no personal Gornek book scene was inferred from that title.

## Class messages

Read all available description/progress/completion passages for the eleven Classic referrals:

| Quest | Recipient | Provided readable item inspected |
| --- | --- | --- |
| [2383 Simple Parchment](https://classicdb.ch/?quest=2383) | Frang | [12635](https://classicdb.ch/?item=12635) |
| [3065 Simple Tablet](https://classicdb.ch/?quest=3065) | Frang | [6488](https://classicdb.ch/?item=6488) |
| [3082 Etched Tablet](https://classicdb.ch/?quest=3082) | Jen'shan | [9564](https://classicdb.ch/?item=9564) |
| [3083 Encrypted Tablet](https://classicdb.ch/?quest=3083) | Rwag | [9554](https://classicdb.ch/?item=9554) |
| [3084 Rune-Inscribed Tablet](https://classicdb.ch/?quest=3084) | Shikrik | [9562](https://classicdb.ch/?item=9562) |
| [3085 Hallowed Tablet](https://classicdb.ch/?quest=3085) | Ken'jai | [9561](https://classicdb.ch/?item=9561) |
| [3086 Glyphic Tablet](https://classicdb.ch/?quest=3086) | Mai'ah | [9575](https://classicdb.ch/?item=9575) |
| [3087 Etched Parchment](https://classicdb.ch/?quest=3087) | Jen'shan | [9553](https://classicdb.ch/?item=9553) |
| [3088 Encrypted Parchment](https://classicdb.ch/?quest=3088) | Rwag | [9560](https://classicdb.ch/?item=9560) |
| [3089 Rune-Inscribed Parchment](https://classicdb.ch/?quest=3089) | Shikrik | [9568](https://classicdb.ch/?item=9568), only a truncated greeting exposed |
| [3090 Tainted Parchment](https://classicdb.ch/?quest=3090) | Nartok | [9579](https://classicdb.ch/?item=9579) |

The full exposed embedded book page was inspected for each item except 9568, whose primary source actually contains only the greeting fragment; its missing content was not reconstructed. Some names/wording differ between the quest and its provided item. The profile avoids inventing a resolution. These letters and trainers' claims belong to their actual senders, not Gornek. Passing along a message neither establishes kinship nor makes him a class trainer. In particular, his expressed reluctance to deal with warlocks is not an endorsement of Nartok's claims or a new friendship exclusion.

## Forever additions

- [Wayward Weapons 97279](https://www.wowhead.com/forever/quest=97279/wayward-weapons): read the full objective, description, progress and completion, independently matching installed acceptance/completion and the current starts row. Gornek asks for six abandoned training weapons; Kzan Thornslash repairs them for future recruits. A mismatched name in the progress passage is not used to invent a third participant or relationship. Repair is Kzan's work, not a new Gornek service.
- [Tainted Tablet 98575](https://www.wowhead.com/forever/quest=98575/tainted-tablet): full published text and installed acceptance/completion retain the Nartok referral for troll warlocks. Its [provided item 282346](https://www.wowhead.com/forever/item=282346/tainted-tablet) presented a robot check; no separate tablet text is claimed read.
- [Glyphic Parchment 98576](https://www.wowhead.com/forever/quest=98576/glyphic-parchment): full published text and installed acceptance/completion retain the Mai'ah referral for orc mages. Its [provided item 282380](https://www.wowhead.com/forever/item=282380/glyphic-parchment) likewise presented a robot check. Its omitted relation row does not erase the independently published/installed passage.

## Voice, other eras and original details

Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` supplies Gornek's severe Valley-of-Trials greeting. It helps ground his blunt voice without copying it into the authored lines. Later retail Invaders in Our Home, renamed Back to the Den progression, and Taskmaster Gornek's Axefall/Spires of Arak appearance are excluded. Targeted lore/reference searches established no separate Classic personal novel/comic story to add. No clan, rank, family or past war service is invented.

Original BuddyDex writing: his warnings are such a habit that he privately practices delivering a compliment without appending another one. The rumor mistakes his muttering for further criticism. This does not claim he has never praised a recruit; the actual Sarkoth passage clearly does. The friendship remarks and favorite SALUTE are authored, and do not confer a rank or mark a quest complete.

The profile has all ten journal fields and fifteen supported personal lines. Four Eleven v4 first-line signatures use the approved orc male B voice `SsUXUYPOaoD5XMe36mlU`: greet, idle, befriended and quest. Hidden delivery tags keep him gruff, dry and increasingly warm with friendship. Metadata retains exact text, model, voice and source identity.

Checks cover journal budgets, named/adult identity, voice routing, line counts/moments, exact audio metadata/mappings and valid mono 22.05 kHz Ogg signals, ordinary/favorite friendship gains and first Buddy welcome. Main/Scout smoke tests and release/install verification run before shipping.
