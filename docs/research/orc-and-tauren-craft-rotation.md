# Shimra, Kulwia, Sura and Shoma

Researched November 10, 2026. Four single-ID catalog identities, three adult Horde women and one adult Orc man. Current definitions determined race/sex/role before writing: Kulwia is a Tauren supplier, Shoma an Orc male weapon vendor and Sura a harness vendor, not a presumed warrior trainer. No Scout sightings fabricated. Full written profiles and fifteen personal lines each; synthesis deferred until user billing confirmation.

## Identity and adult models

| NPC | Current primary definition | Adult display / voice | Explicit access |
| --- | --- | --- | --- |
| Shimra5817 | [API](https://forever.warcraftdb.com/api/data/node/npc/5817), Orc30, General Trade Goods Merchant/Vendor, Orgrimmar48.08,80.27 |4356, race2sex1, M2949470, `orc-female` | Horde Friendly |
| Kulwia12043 | [API](https://forever.warcraftdb.com/api/data/node/npc/12043), Tauren32, Trade Supplies/Vendor, Stonetalon45.42,59.38 |12059, race6sex1, M2986648, `tauren-female` | Horde Friendly |
| Sura3023 | [API](https://forever.warcraftdb.com/api/data/node/npc/3023), Tauren30, War Harness Vendor/Repair, Thunder Bluff51.80,54.18 |2125, race6sex1, M2986648, `tauren-female` | Horde Friendly |
| Shoma3361 | [API](https://forever.warcraftdb.com/api/data/node/npc/3361), Orc30, Weapon Vendor/Repair, Orgrimmar81.66,19.23 |1383, race2sex0, M2917116, `orc-male` | Horde Friendly |

`Data/NpcSounds.lua` independently maps every display's race/sex. Newly fetched verified adult references Shikrik3157, Nara Wildmane5770 and Frang3153 match those standard character bodies. No age inference from level/height/name. No duplicate identity, generic-role or child exception. Every authored entry still requires normal named/adult/humanoid/nonplayer/nonpet/reaction>=4 and non-attackability checks; icons are not runtime overrides. No account-wide progress, extra skill/service, equipment benefit or quest completion introduced.

Complete current own starts/ends/sells/teaches tabs read. All starts/ends/teaches empty; current vendor rows36/19/4/19, each fully on page1. Classic own tables contain only vendor relations too, so no personal quest chain or installed NPC-keyed gossip was found for these four. No unrelated nearby quest assigned to them merely from proximity. Consulted character references provide no individual book/comic narrative used here. Raw current definitions/tabs, Classic HTML and adult-reference responses cached outside git at `C:/Users/brett/BuddyDex-builds/orc-and-tauren-craft-rotation`.

## Shimra: supplies and a challenging little game

[Classic5817](https://classicdb.ch/?npc=5817), current thirty-six wares and [character reference](https://warcraft.wiki.gg/wiki/Shimra) corroborate Orgrimmar General Store in the Valley of Strength. Current wares include three apprentice gathering bags, tools, fishing supplies, thread/dyes, vials, spices, flux, coal, stocks and a red apple. Classic thirty-five-row inventory includes later-removed/currently absent vial/thread variants; exact historical inventory/costs are not copied into a guarantee. Supplier does not mean profession trainer or actual creator of every item sold.

Her later Siege of Orgrimmar captivity, Mojka march and post-Broken Shore conversation are excluded. The character reference's old torch is appearance context, not a personal plot or a new BuddyDex equipment effect. No wartime trauma or former army rank invented.

Original hook: a small bottle-cap/chalk-square game during breaks, enjoying an honest difficult match and disliking courtesy losses. No racial intelligence joke, wagering, actual minigame UI, challenge command, reward or new item. GRIN is accepted. Approved female Orc signatures retain gravelly confidence and playfulness.

## Kulwia: supplies and imperfect drawings

[Classic12043](https://classicdb.ch/?npc=12043), current nineteen wares and [character reference](https://warcraft.wiki.gg/wiki/Kulwia) establish Sun Rock Retreat trade supplies. Full nineteen historical rows read, including both enchant formulas missed by a common-item-only name parser: Cloak Minor Agility and Bracer Lesser Strength. Current stock corroborates those formulas, plus tools, fishing supplies, thread, spices, flux, vials, salt and rod. Selling formulas does not make her an enchanting trainer or an Orc; both identity errors were avoided before authoring. No invented family or prior journey.

Original hook: charcoal mountain sketches that turn into less convincing kodo when she attempts animals. Her enjoyment does not depend on pretending mastery. No new portrait generator, cartography skill, illustrated quest book, magical drawing or charcoal inventory stock. SMILE is accepted. A proposed portrait in personal dialogue is character fiction, not an addon feature or item grant.

## Sura: a comfortable turn

[Classic3023](https://classicdb.ch/?npc=3023), current Repair/Vendor and four matching harness rows establish her role on Thunder Bluff's High Rise: Buckled, Studded Leather, Grunt's and Battle Harness. [Character reference](https://warcraft.wiki.gg/wiki/Sura_Wildmane) corroborates placement and repair service. She is not converted into a warrior trainer, armor crafter or exceptional military leader from a vendor title. Exact prices/stock/equipment effects remain game data, not friendship rewards.

Exclude the later Highmountain feast, Sunn Ragetotem conversation and Void entrapment. No personal relationship with Nara, Kym or other Wildmane NPCs is inferred from a shared clan surname. Generic clan lore is not an individual biography.

Original hook: enjoying a simple dance turn, initially while thinking about comfortable movement, then for its own sake and shared company. It is not a player fitting system, combat technique or change to model/armor movement. No implication that size determines grace. DANCE is accepted; her patient humor stays distinct from Kulwia's sketching and Shimra's competitive game.

## Shoma: suitable weapons without invented legends

[Classic3361](https://classicdb.ch/?npc=3361), current nineteen weapons/Repair service and [character reference](https://warcraft.wiki.gg/wiki/Shoma) corroborate a male Orc vendor in the Valley of Honor. [Arms of Legend](https://warcraft.wiki.gg/wiki/Arms_of_Legend) is his Classic/Forever shop context; current pin is recorded separately, not replaced with historical shop coordinates. The nineteen current and historical rows include swords, daggers and right/left fist weapons. No later retail deletion of left-handed stock or modern replacement stock imported over the current response.

Later Cataclysm relocation to improvised tents is excluded. No new battlefield service, kill count, warrior training, celebrity customer or named family history invented. The shop's title is not evidence that a particular sword was owned by a hero.

Original hook: shaping a plain wooden practice grip and enjoying useful work without a dramatic provenance. No new weapon recipe, item, training action or guarantee of extra repair services. NOD is accepted. His interest is practical/quiet rather than a manufactured war tragedy or a need to prove strength to a friend.

## Validation

Main/Scout smoke passes all lore/card/field/favorite/line budgets and fresh/existing character roster isolation. Actual-addon targeted harness `C:/Users/brett/AppData/Local/Temp/buddydex-craft-505.py` verifies all four unique adult IDs/displays, approved declared/live voice routing, fifteen missing personal lines per profile and accepted favorites. Four fresh Horde sessions reject attackable/reaction3 targets, grant25ordinary/150favorite points, pass99/100and299/300 boundaries, reject early companion activation and allow text-only Buddy welcome with zero substituted personal audio. Generic guards remain excluded. No runtime/storage code changed.

Full offline decoded-audio/exact-text audit:9230missing jobs/567982tagged inputcharacters, shared3548/personal5682, no MiniMe gaps. Exactly15new jobs per source in its approved group; adds60jobs/5333characters. Existing recordings retained. No synthesis/account/billing requests, credit spending or human listening/live visual check.

505written/454initial signature recordings/51written-complete audio-pending. Two uncertain Westfall candidates remain unprofiled. Explicit public Friendly totals218Alliance/166Horde/130unverified, nine shared overlaps. Catalog1536namegroups/1549identities unchanged; no fabricated Scout observations. These service additions deepen Horde race/sex coverage without claiming a new first-zone starter milestone.

Developmentv003 installed/hash-verified6362releasefiles, one runtime source updated. ZIP verifies6362files/6334runtime audio mappings/138.44MiB; source/installed/ZIP Lore bytes match. ZIP SHA256: `7c7db2dbf7bdd850c2b8be93829a5e7ed9c547d517457033a9d69d518582e9a4`. Publishedv002 untouched; no tag or CurseForge publication.
