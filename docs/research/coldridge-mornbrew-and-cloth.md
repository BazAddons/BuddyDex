# Coldridge: Nori Pridedrift and Durnan Furcutter

Reviewed 2026-11-09. These begin the five-profile shared dwarf/gnome starter milestone. They are two dwarf profiles; the gnome candidates remain in the queue and are not counted complete. No personal Scout encounter or current player quest completion is claimed. Normal adult/named/friendly/attackability rules remain authoritative.

## Identities and evidence limits

| NPC | ID | Adult display | Cached current DB2 identity | Role / route |
| --- | ---: | ---: | --- | --- |
| Nori Pridedrift | 12738 | 12967 | Dwarf race 3 / male sex 0 | Mornbrew deliveries, Coldridge Valley |
| Durnan Furcutter | 836 | 3406 | Dwarf race 3 / male sex 0 | Cloth/leather armor merchant, Anvilmar |

Current [Nori node](https://forever.warcraftdb.com/api/data/node/npc/12738) supplies his name, race, humanoid type and adult model, but no reaction/location/quest relation rows. Current [Durnan node](https://forever.warcraftdb.com/api/data/node/npc/836) explicitly supplies the armor-merchant title, Alliance-friendly icon, Repair/Vendor services, adult model and twelve sale entries. Cached client display/extra tables resolve both to adult male dwarf models. Durnan is 836; the unrelated 698 identity is not used.

Current Wowhead NPC pages presented robot checks and are not claimed read beyond that. Current published quest pages and installed acceptance/completion text independently retain the delivery story and locate Nori in Coldridge and Durnan in Anvilmar. Classic Alliance quest context supports Nori's baseline access; his current missing reaction icon remains unverified in the public-icon audit. No race-based friendliness inference overrides runtime checks.

The [licensed Atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf), relevant Dun Morogh entries only, places Nori at a Coldridge camp and Durnan in Anvilmar. Historical grids and quest text are not a personal live sighting or a verified roaming path. Source snapshots are outside the repository in `BuddyDex-builds/coldridge-brew-research` and the coverage cache.

## Complete linked quest story

Read objective, description, progress and completion for [Scalding Mornbrew Delivery 3364](https://classicdb.ch/?quest=3364) and [Bring Back the Mug 3365](https://classicdb.ch/?quest=3365). Read the corresponding full current Forever passages for [3364](https://www.wowhead.com/forever/quest=3364/scalding-mornbrew-delivery) and [3365](https://www.wowhead.com/forever/quest=3365/bring-back-the-mug). Installed `Spoken_Quests/Data/QuestText.lua` acceptance/completion matches each stage.

Confirmed: a delivery to Grelin has delayed Nori's delivery to Durnan. He asks a courier to get the drink to Anvilmar before it cools, with a five-minute limit. Durnan takes a break to enjoy the hot drink and asks for the empty mug to be returned. Nori is grateful for the return and notes how often couriers forget it. The time limit belongs to the hot delivery; the mug return is not described as timed. Neither profile changes quest rewards or marks the delivery completed for the current player.

The story supports a practical, brisk and humorous Nori, and Durnan's appreciation of warmth alongside his merchant role. It establishes named acquaintances/customers, not a new family relationship, exclusive partnership or tavern. Mornbrew is retained as its own named drink rather than asserted to be alcoholic or assigned an invented recipe. Nori's quoted importance of mugs is not a new collection mechanic.

## Nori: confirmed and original

No Nori NPC-ID gossip entry was found in the installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`. The current public definition is sparse, so neither a vendor window nor a precise roaming route is invented. References list Adlin as a relative, but the primary quest passages inspected do not establish that relationship or its degree. The authored profile omits kinship rather than inferring it from their surname.

Original BuddyDex detail: he enjoys looking back at the neat row of his bootprints in fresh snow. This modest pleasure fits his deliveries without making him a tracker, adding a special route, or claiming that he delays urgent work. The rumor mistakes his glance backward for concern about a missing mug. The private story, friendship remarks and favorite THANK are authored.

## Durnan: confirmed and original

His current definition explicitly verifies cloth/leather sales and repairs. Installed gossip boasts about that stock. The research does not infer a tailoring or leatherworking trainer profession from his name or inventory. No fixed prices, special discounts or new goods are added by the profile.

Original BuddyDex detail: he sets aside a faded scarf for himself because use has made it comfortably soft. It is not rare stock, an enchanted heirloom, a named game item or a reward. Its past owner/family/crafter is not invented. His affection for familiar comfort supports the warm merchant dialogue without contradicting his interest in useful new goods. Favorite NOD is authored.

## Books, other eras and recordings

Targeted lore/reference searches found the Atlas location entries and the original quest story, but no additional personal Classic novel/comic scene to incorporate. Later Cataclysm removal of Nori/the quests is not applied to Forever's retained story. The separate Radiant Echoes projections in Searing Gorge are later retail event versions and are excluded; they do not establish either NPC's current location, death or powers.

Each profile has all ten journal fields and fifteen supported personal lines. Four Eleven v4 first-line signatures each in the established male dwarf voice `tNPIWbrnyCsbmVIg3tPK`: Nori greet/idle/befriended/quest; Durnan greet/idle/befriended/gear. Hidden delivery directions distinguish Nori's brisk energy from Durnan's comfortable warmth. Voice metadata retains exact written/spoken text, model, selected voice and lore identity.

Checks cover journal budgets, named/adult identities, supported moments, dwarf voice routing, all eight mappings and source metadata, valid mono 22.05 kHz Ogg audio signals/durations, ordinary/favorite emote gains and recorded first Buddy greetings. Main/Scout smoke suites and package/install verification run before shipping.
