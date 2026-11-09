# Innkeeper Gryshka and Doras

Researched November 8, 2026 for Classic-era / Forever profiles. NPCs 6929 and 3310. Both are named Horde service NPCs; eligible for Horde characters under the normal friendly-reaction checks. Neither is present in the current Alliance Scout snapshot, so no local encounter is claimed.

## Identity and continuity

- [Gryshka](https://warcraft.wiki.gg/wiki/Innkeeper_Gryshka) is a female orc innkeeper at the Broken Tusk in Orgrimmar's Valley of Strength. [Classic ID 6929](https://www.wowhead.com/classic/npc=6929/innkeeper-gryshka) identifies the same service NPC.
- [Doras](https://warcraft.wiki.gg/wiki/Doras) is a **male orc**, not a troll. [Classic ID 3310](https://www.wowhead.com/classic/npc=3310/doras) is the wind rider master. Use his pre-Cataclysm Valley of Strength tower location, not the later Skyway.
- Wiki pages were accessible through indexed full-page search extracts; direct opens returned 403. Wowhead Classic identity pages opened successfully. No relevant book/comic history appeared in the consulted NPC articles or targeted searches; no claim of exhaustive bibliography is made.

## Full Classic courier chain

1. [Meats to Orgrimmar, 6365](https://warcraft.wiki.gg/wiki/Meats_to_Orgrimmar_(Classic)): Zargh describes Gryshka as a friend and entrusts the player with meat. Devrak's progress and completion explain speedy transport for a fare.
2. [Ride to Orgrimmar, 6384](https://warcraft.wiki.gg/wiki/Ride_to_Orgrimmar_(Classic)): Devrak directs the rider to her inn near the landing. Her progress notices the smell; her completion praises the cuts and explicitly prefers rare meat.
3. [Doras the Wind Rider Master, 6385](https://warcraft.wiki.gg/wiki/Doras_the_Wind_Rider_Master_(Classic)): Gryshka sends Zargh written thanks. Doras asks about transport and confirms he can carry the courier back to the Crossroads.
4. [Return to the Crossroads, 6386](https://www.wowhead.com/classic/quest=6386/return-to-the-crossroads): Doras explains that riders must know the destination flight master. Zargh asks whether she liked the gift, then jokes that the courier might receive a wedding invitation. That is hopeful teasing, not proof of an engagement or marriage.

Objectives, descriptions, progress and completion were reviewed for all four steps. [Forever quest listing](https://www.60.tools/quests/6386-return-to-the-crossroads) reports the Classic route but explicitly sources text from the Classic database; it does not independently prove every Forever dialogue line. No live Horde quest verification was available.

Do not substitute the modern Grimtak/Burok/Razor Hill route. No Wrath refugees, Siege of Orgrimmar, Vol'jin funeral or Arcantina events are imported. The entry never assumes the player completed this chain.

## Original BuddyDex additions

Gryshka's quiet broth service, notes tucked between recipes, personal preferences beyond rare meat, and dialogue are original writing. Doras's patient first-flight coaching, private ledger of returning riders and personal dialogue are original writing. Neither character receives invented family, military service or romance outcomes. Favorite emotes are THANK and WAVE.

Fifteen written lines each. Four signature recordings per NPC use the user-selected custom orc voice. The user approved **Eleven v4** for new recordings after hearing a same-voice comparison; previous clips remain unchanged. Each chosen line has an explicit delivery tag without displaying the tag in its bubble.

## Model identity and validation

ClassicDB model-viewer data identifies Doras display `1311` and Gryshka display `5706` ([Doras](https://classicdb.ch/?npc=3310), [Gryshka](https://classicdb.ch/?npc=6929)). Wago `wow_classic_beta` CreatureDisplayInfo and CreatureDisplayInfoExtra CSV tables confirm race 2 with sex 0 and 1. Added all orc display identities while preserving every preexisting identity, and enabled runtime orc routing. Smoke checks play each NPC's real greeting through that display mapping. All eight clips decode as finite, nonsilent mono 22050 Hz Ogg Vorbis, match exact source text, tags and selected voice IDs, and are recorded with `eleven_v4`. In-game playback/visual review remains for the player; no listening or live-game QA is claimed.
