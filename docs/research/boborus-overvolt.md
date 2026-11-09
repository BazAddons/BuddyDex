# Boborus Overvolt (274917)

Researched 2026-11-08 for Forever. Individually named, friendly male Humanoid in the installed Scout snapshot, not a generic role NPC.

## Identity evidence

- The installed `BuddyDexScout.lua` roster records NPC 274917, Boborus Overvolt, level 53, normal classification, male (unit sex 2), Alliance, reaction 5, type Humanoid/type ID 7, Tinker Town, Ironforge/map 1455. Four sightings; no attackable flag. No profession/title or model display was captured in this record.
- [WarcraftDB NPC page](https://forever.warcraftdb.com/data/npc/274917), using its public [node endpoint](https://forever.warcraftdb.com/api/data/node/npc/274917), supplies name, Humanoid type, race link `/data/race/7` labeled Gnome, and `extra.models[0].id = 147954`. Direct HTTP with a browser user agent returned the JSON; the web text extractor could not open it. No client secret or authenticated account was used.
- The shipped DB2-derived `Data/NpcSounds.lua` independently maps display 147954 to race 7, sex 0 (male), and NPC sound set 44. The actual runtime voice resolver is tested against the selected male gnome voice. Scout supplies current friendliness and location; the appearance endpoint supplies the missing race/display evidence.
- [ONN NPC list](https://oraclenewsnetwork.com/npcs) corroborates name, level, Humanoid and Ironforge. [Daybreak's list](https://daybreakforever.com/npcs) corroborates the ID but explicitly lacks role/placement evidence; it is not used to invent one. A Gnomeregan Exiles faction listing is not independently proof of race.

## Lore and quest search

Targeted exact-name/ID searches found no established personal story, quest chain, named relationship, relevant book or comic. WarcraftDB's node response exposes only screenshots/comments tabs, with zero entries, and no description or quest tabs. That is a lack of available evidence, not proof that no game dialogue exists. The installed Spoken quest text and NPC audio lookup/gossip files were searched for the name and ID; no matching association was found. The historical Classic identity databases do not establish this new Forever ID.

Do not assign the Mage-tastic Gizmonitor, engineering training, Gaxim's operations, or other nearby NPCs' quests to him. No profession, family, flight service, refugee history, invented canonical object or completed player quest is claimed. The profile can be revisited if Scout or in-game interaction supplies new evidence.

## Original BuddyDex additions

His attentive listening, recognition of footsteps, interest in little city sounds, neighbors' amused reactions, love of rain on windows, preferences, quote, history, secret and all fifteen companion lines are original low-stakes character writing. Only the named male gnome's present location is presented as sourced identity. His surname is not evidence that he works with electricity. The favorite is SMILE, an accepted friendly emote, allowing a named NPC without a dialogue window to be befriended normally.

Four signature clips use the established male gnome voice and explicitly directed Eleven v4: greet, idle, first-outing friendship welcome and a new-zone reaction. Automated checks cover layout, eligibility, supported moments, source/text/delivery metadata, file decoding and actual welcome playback. Live in-game visual review and human listening are not claimed.
