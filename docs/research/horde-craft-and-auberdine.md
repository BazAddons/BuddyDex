# Wulan, Lah'Mawhani, Hahrana and Laird

Researched November 10, 2026. Two adult Troll vendors in Shadowprey, a female Tauren master leatherworker at Camp Mojache, and Auberdine's Night Elf fish vendor. All four are unique single-ID catalog entries, individually reviewed rather than fabricated Scout sightings. Fifteen personal lines each; approved voices assigned, synthesis deferred until explicit user billing confirmation.

## Identity and access

| NPC | Current primary definition | Adult model / approved voice | Explicit reaction |
| --- | --- | --- | --- |
| Wulan12033 | [API](https://forever.warcraftdb.com/api/data/node/npc/12033), Troll30, Cooking Supplies/Vendor, Desolace26.19,69.75 |12036, race8sex0, M21022938, `troll-male` | Horde Friendly |
| Lah'Mawhani12028 | [API](https://forever.warcraftdb.com/api/data/node/npc/12028), Troll30, Trade Supplies/Vendor, Desolace23.10,71.72 |12042, race8sex1, M21018060, `troll-female` | Horde Friendly |
| Hahrana11098 | [API](https://forever.warcraftdb.com/api/data/node/npc/11098), Tauren55, Master Leatherworker, Feralas74.40,43.06 |10623, race6sex1, M2986648, `tauren-female` | Horde Friendly |
| Laird4200 | [API](https://forever.warcraftdb.com/api/data/node/npc/4200), Night Elf14, Fish Vendor/Vendor, Darkshore36.87,44.27 |9549, race4sex0, M2974343, `nightelf-male` | Alliance Friendly |

Each display's race/sex is independently mapped in `Data/NpcSounds.lua`. Standard adult base models match newly fetched current references Master Gadrin3188, Mishiki3185, Nara Wildmane5770 and Conservator Ilthalaine2079. No age inference from level/height. No child/generic or live-reaction exceptions, class/profession gates, new rewards or account-wide progress. Ordinary named/adult/humanoid/nonplayer/nonpet/reaction/non-attackability checks remain mandatory. These expand geographic/service coverage; Camp Mojache and Shadowprey are not claimed as beginner starting zones.

Complete current own starts/ends/sells/teaches endpoints read, maximum30rows and no unread pagination. All four current own quest relations are empty. Historical/current gaps are not proof of removal. Raw cache outside git: `C:/Users/brett/BuddyDex-builds/horde-craft-and-auberdine`. Mahu3005 was also inspected, but not authored or added to the roster in this batch; his male model was verified rather than inferred from his name. Lah'Mawhani was chosen to improve female Troll coverage.

## Wulan: supplies, books and rhythm

[Classic12033](https://classicdb.ch/?npc=12033), [character reference](https://warcraft.wiki.gg/wiki/Wulan), current Vendor/location and fifteen current stock rows establish Shadowprey cooking supplies. Current stock includes Expert Cookbook, four fish recipes, three spices, water, flour, apple, wood/tinder, Star Wood and Thick Logs. Nine historical stock rows differ from current; retail removal of the cookbook/spices is not imported into Forever, which currently lists them. No exact prices/caps/stacks guaranteed by the journal.

No personal quest chain, teaching rows or installed own gossip found. His cookbook is also a referral destination in previously researched cooking trainers' dialogue. Selling it does not make him its author, a formal cooking trainer, or the originator of every recipe. No personal book/comic history established in consulted sources.

Original hook: tapping small rhythms while arranging supplies, enjoying the friend who remembers a pause is not the end. No official musician role, extra musical item, special buff or cookbook recipe invented. CLAP is accepted. Approved male Troll voice carries the previously selected accent; signature delivery tags add warmth/playfulness without new audition spending or exaggerated phonetic spelling.

## Lah'Mawhani: a debate between useful tools

[Classic12028](https://classicdb.ch/?npc=12028), [character reference](https://warcraft.wiki.gg/wiki/Lah%27Mawhani), current location/Friendly/vendor and all thirty current wares reviewed: dyes, thread, vials, tools, fishing supplies, stocks, flux, coal, spices, salt and rod. Classic has thirty-three stock rows including vial/thread differences, not a guarantee of identical current wares. No own quest/training relation or installed own gossip found. A supplier of several trades is not assumed trained in all those trades, nor related to nearby similarly named NPCs.

Original hook: providing mock voices for hammer/needle debates, letting an empty vial win through a practical kindness. Tools never actually speak; no enchanted object, new named NPC, skill, toy or reward. SMILE is accepted. Use the approved female Troll voice, rather than assigning sex by surname or proximity to Wulan.

## Hahrana: local armor comes first

[Classic11098](https://classicdb.ch/?npc=11098), [character reference](https://warcraft.wiki.gg/wiki/Hahrana_Ironhide), current Master Leatherworker/Friendly/pin and installed own three gossip passages read. Buyers must request her work in person; Orwin asks her to reconsider, but fighters here need her armor. She values advanced pupils willing to travel and refuses to teach basic skills while concerned with the front line. No specific military campaign, rank, Orwin relationship or guaranteed order system is inferred. Do not import later retail title changes.

Fifteen historical training rows read: artisan leatherworking, hide/leather conversions, armor kit, feathered/nightscape/turtle-scale pieces, quiver and ammo pouch. Current own teaching/vendor/quest tabs are empty; they do not establish removal or guaranteed unchanged exact training details. No personal quest chain found. Her source priorities remain intact as friendship grows; she is not rewritten as neglecting local fighters for distant orders.

Original hook: rigorous workmanship paired with deliberately dreadful leatherworking puns, enjoying an honest groan from a friend. No actual alteration/repair command, unusual training, new item or combat benefit. GRIN is accepted. Her humor supplements her resolve instead of inventing a sad personal loss or trivializing the work.

## Laird: observations, hypotheses and tall tales

[Classic4200](https://classicdb.ch/?npc=4200), [character reference](https://warcraft.wiki.gg/wiki/Laird), current fish-vendor/location/Friendly and installed own gossip establish living Auberdine Laird. His coastal-warning gossip acknowledges greater danger than Teldrassil without claiming he personally catches everything he sells. Current six stock rows are five raw fish and Fillet of Frenzy recipe; the historical eight-row table has cooked/other fish differences. No identical stock, prices, catches or stock limits promised by the profile.

Full Classic chain read with available objective/description/progress/completion passages and installed accept/complete for all four:

1. [6344 Nessa Shadowsong](https://classicdb.ch/?quest=6344): Mydrannul refers the courier to his friend Nessa; that friendship is not assigned to Laird.
2. [6341 The Bounty of Teldrassil](https://classicdb.ch/?quest=6341): Nessa sends bones/scales to her colleague Laird via Vesprystus to compare unusually abundant/large Rut'theran fish with the mainland's.
3. [6342 Flight to Auberdine](https://classicdb.ch/?quest=6342): transport instructions and delivery; Laird is surprised by the specimen sizes. No invented prior player delivery or active flight-route guarantee.
4. [6343 Return to Nessa](https://classicdb.ch/?quest=6343): Laird sends observations back, suspects the World Tree affects nearby wildlife, and names Caylais/ferry return options. Nessa explicitly leaves the cause unresolved. His hypothesis is **not confirmed cause**, a cure, a secret experiment or a proven corruption.

All four current WarcraftDB quest nodes returned404 and own relations are sparse, so these passages are historical/installed characterization, not claims of current quest availability or exact rewards. They are consistent with the already authored Nessa relationship. The profile does not claim the mystery solved. Later Cataclysm death, Lor'danel corpse and refugee priestesses are excluded from current living4200. No personal book/comic plot imported.

Original hook: extravagant fish stories rehearsed for empty baskets, clearly separated from honest trade and research. The player may enjoy a deliberately ordinary ending without being misled about actual specimens. WINK is accepted. No magical fish growth, invented famous catch, new quest or stat reward.

## Validation

Main/Scout smoke passes all profile/card/field/favorite/line budgets and fresh/existing character isolation. Laird's gossip was shortened after a first check found one extra wrapped line; subsequent full smoke passed. Actual-addon targeted harness `C:/Users/brett/AppData/Local/Temp/buddydex-shadowprey-auberdine.py` verifies all named adult IDs/displays and declared/live approved voice groups, fifteen missing personal lines per profile and accepted favorites. Fresh Horde sessions for the first three and Alliance for Laird pass normal discovery25/favorite150,99/100and299/300 tier boundaries and text-only Buddy activation/welcome with zero substituted personal audio. Attackable/reaction3 targets are rejected without discovery; early companion activation and generic guards remain rejected. No runtime/storage code changed.

Full offline decoded-audio/exact-text audit:9080missing unique jobs/554568tagged inputcharacters, shared3548/personal5532, no MiniMe gaps. Each new source has exactly15jobs in its approved group; adds60jobs/5239characters. Existing recordings preserved. No synthesis/account/billing requests, credit spending or human listening/live visual check.

Counts495written/454initial signature recordings/41written-complete audio-pending; two Westfall availability candidates still unprofiled. Explicit public Friendly totals214Alliance/158Horde/130unverified, seven shared overlaps. Catalog1536namegroups/1549identities unchanged; no fabricated Scout sightings. Mahu's inspection did not add an authored entry or inflate totals.

Developmentv003 installed/hash-verified6362releasefiles, one runtime source updated. ZIP verifies6362files/6334runtime audio mappings/138.43MiB; source/installed/ZIP Lore bytes match. ZIP SHA256: `480ef55cc6e894d8881c32042b366cb23055a4d6a37eacc1efbefbb284257c81`. Publishedv002 untouched; no tag or CurseForge publication.
