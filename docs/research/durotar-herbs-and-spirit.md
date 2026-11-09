# Mishiki and Tai'jin: herbs and priestly teaching

Researched 2026-11-09. Current definitions, published Forever quests and installed English records were compared with Classic relations. These are reviewed external identities, not personal Scout sightings.

## Verified identities and access

| NPC | ID | Current display / extra | Adult model | Current location |
| --- | ---: | --- | --- | --- |
| Mishiki, Herbalist | 3185 | 4085 / 2338 | Troll 8 / female 1 | Sen'jin Village, Durotar, approximately 55.4, 75.1 |
| Tai'jin, Priest Trainer | 3706 | 1897 / 2341 | Troll 8 / female 1 | Razor Hill, Durotar, approximately 54.2, 43.0 |

Exact current nodes: [Mishiki](https://forever.warcraftdb.com/api/data/node/npc/3185), [Tai'jin](https://forever.warcraftdb.com/api/data/node/npc/3706). Both explicitly expose Horde-friendly icons, Durotar pins and the adult displays above. Cached current CreatureDisplayInfo / Extra records confirm race and sex. No live faction, attackability, generic-name or child gate is bypassed by authoring either profile.

Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`, Razor Hill Grunt 5953, independently directs gatherers to Mishiki's Sen'jin hut and priests to Tai'jin in the east barracks. The guard's directions establish roles/locations, not a personal friendship with either trainer. The historical identity review remains in [the queue note](durotar-troll-trainers-queue.md).

## Mishiki: sparse personal lore

Checked current [starts](https://forever.warcraftdb.com/api/data/node/npc/3185/tab/starts), [ends](https://forever.warcraftdb.com/api/data/node/npc/3185/tab/ends) and [teaches](https://forever.warcraftdb.com/api/data/node/npc/3185/tab/teaches): all returned empty arrays. This is sparse data, not proof that she offers no training. The [Classic NPC](https://classicdb.ch/?npc=3185) raw training list contains Apprentice, Journeyman, Expert and Artisan Herbalist, with no quest lists. The current [published Forever NPC](https://www.wowhead.com/forever/npc=3185/mishiki) showed a robot check, so no hidden page contents were assumed. Her exact ID has no installed gossip entry. The current definition and installed guard directions corroborate her continuing profession/location without invented dialogue or quest relations.

Checked the tempting Forever camping association rather than assigning a profession-wide quest to her. [97905 Camping 101: Herbalism](https://www.wowhead.com/forever/quest=97905/camping-101-herbalism) sends Brakk's learners to **Jandi in Orgrimmar**, not Mishiki. Its available objective, description and completion were read: it concerns skill proficiency, an incense candle and camping prerequisites. It does not establish Mishiki's personal role in the chain. Her profile does not promise camping recipes, ranks at a particular level, a delivery errand or a personal alchemist relationship.

No personal readable item or individual book/comic connection was established. Targeted literary searches yielded no relevant biography; no later-retail history or shared tribal backstory is imported as something she personally did.

## Tai'jin: full available quest dialogue and referrals

Current [starts](https://forever.warcraftdb.com/api/data/node/npc/3706/tab/starts) exposes 5648 and 5654; [ends](https://forever.warcraftdb.com/api/data/node/npc/3706/tab/ends) exposes 5648 and 5649. The [Classic raw NPC list](https://classicdb.ch/?npc=3706) instead has starts 5648, 5655 and 5660, with the same two endings. The published Forever NPC reports three starts. This difference is preserved, not silently resolved by guessing. All relevant variants were read; the authored profile uses the corroborated relationships without asserting an exact current referral ID or adding quests to the addon.

- **5649 In Favor of Spirituality â†’ 5648 Garments of Spirituality.** [Classic 5649](https://classicdb.ch/?quest=5649) confirms Ken'jai's referral. Its full installed accept/completion records describe Horde loyalty alongside retained traditions and Tai'jin's teaching about adaptation. The published Forever 5649 page returned 403, and no additional progress speech was exposed by the consulted sources. The complete [Forever 5648](https://www.wowhead.com/forever/quest=5648/garments-of-spirituality) objective, description, progress and completion were read and compared with installed accept/completion. Tai'jin tests a learner by healing and fortifying injured Grunt Kor'ja south of town. The dialogue connects healing, protection and wisdom in combat; completion rewards and praises the pupil. Do not invent a specific personal war record from her fondness for wise combatants or make Kor'ja her relative.
- **Hex of Weakness referral variants [5654](https://www.wowhead.com/forever/quest=5654/hex-of-weakness) and [5655](https://www.wowhead.com/forever/quest=5655/hex-of-weakness).** Both full available objectives, descriptions and completions were read, plus installed records. They send troll priests to Ur'kyo in Orgrimmar's Valley of Spirits. Installed completion emphasizes the lesson and later tests; current published completion is a shorter welcome. This is a professional referral, not evidence of family or a private apprenticeship.
- **[5660 Touch of Weakness](https://www.wowhead.com/forever/quest=5660/touch-of-weakness).** Full available objective, description and completion were read and compared with installed records. Tai'jin directs a Forsaken learner back to Aelthalyste in the Undercity War Quarter for their own teaching. This corroborates the missing third historical/published referral without pretending the current API lists it. It does not make Tai'jin Forsaken or establish a friendship with Aelthalyste. No separate progress passage or linked follow-up was exposed in that page.

The complete exact-NPC installed Tai'jin gossip was read: respect for her people's ways, priest instruction, and rigorous talent retraining. Generic shared trainer wording is not a personal threat against the player or proof of an invented feud. No personal quest-readable book, comic or novel connection was found that would add a biography; broader troll history is not assigned to her as witnessed experience. Later-retail trainer changes are excluded.

## Original writing and recording plan

Mishiki's gathering-place nicknames, scratched-elbow mishap and stories of ordinary walks are original. Her distinction between correct plant names and playful place names keeps the herbalist competent. She does not speak for plants, discover a new species or gain a magical secret. Favorite NOD rewards attentive listening.

Tai'jin's knotted cord is an original pastime. Students' speculation sets up her admission that it is a puzzle she made herself, not an ancestral charm. The friendship payoff lets the player help without undermining her real expertise. Favorite BOW reflects her verified emphasis on respect. Her personal speech is newly written, with the selected voice providing the accent rather than heavy phonetic spelling.

Each has all ten fields and fifteen supported personal lines. At width 50 their lore columns occupy 20 and 21 lines, within all section budgets. Four signatures apiece use approved female troll voice `0xQXygLnre17fk87G6Kt` and Eleven v4: greet, idle, befriended and learned. Hidden tone fields guide delivery without appearing in bubbles. Exact routing, recorded text/provenance, decoded audio, daily discovery/favorite points and recorded first welcome are validated before install/package/commit.

Raw source caches are outside the repository at `C:/Users/brett/BuddyDex-builds/durotar-services-research`. The old handed-off v002 ZIP is preserved; new development packaging stays in the separate development directory. CurseForge publication remains deferred until the user's evening setup.

## Batch validation

The full-loader profile checks and standard addon/Scout smoke suites passed with zero load errors or failures. Both profiles have fifteen supported lines and four correctly routed v4 clips with matching text/tone/provenance. Decoded audio is finite mono 22,050 Hz and within the duration/level checks. Mock sessions verified HELLO discovery (25), the independent daily favorite (150), and the first recorded companion welcome. The named/adult routing samples were added to the persistent smoke suite. These are automated checks, not a claim of a live in-game visual review.

Installed and verified 5,674 release files; the separate development v002 ZIP has 5,646 runtime audio mappings and is 97.96 MiB. The previous handed-off upload candidate was checked against its recorded SHA-256 and remains unchanged.
