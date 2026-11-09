# Grosk and Duokna: rest and supplies for early Durotar

Researched 2026-11-09 against current Forever NPC/stock/relationship definitions, published quest text and installed English dialogue. Historical data is distinguished from Forever and later retail. Neither identity is a fabricated Scout encounter.

## Verified adult identities

| NPC | ID | Current display / extra | Model | Location |
| --- | ---: | --- | --- | --- |
| Innkeeper Grosk | 6928 | 5705 / 3760 | Adult male Orc, race 2 / sex 0 | Razor Hill, Durotar, approximately 51.6, 41.7 |
| Duokna | 3158 | 1879 / 571 | Adult female Orc, race 2 / sex 1 | Valley of Trials, Durotar, approximately 42.6, 67.4 |

Current exact nodes: [Grosk](https://forever.warcraftdb.com/api/data/node/npc/6928), [Duokna](https://forever.warcraftdb.com/api/data/node/npc/3158). Current CreatureDisplayInfo and CreatureDisplayInfoExtra resolve the adult identities above. Grosk explicitly exposes Horde-friendly reaction and innkeeper/vendor services. Duokna's node exposes General Goods and a Durotar pin but no reaction icon; her exact-ID current stock confirms a functioning starter merchant definition. Keep her public faction-audit entry unverified rather than guessing an icon from race or stock. Actual friendship still requires a live named adult friendly non-attackable unit.

Duokna's historical location is independently confirmed in the licensed [World of Warcraft Atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf), PDF page 27: General Goods in the Valley of Trials' northwest structure. This agrees with the current pin. [Classic Duokna](https://classicdb.ch/?npc=3158) confirms identity/title/Durotar. The current published Wowhead NPC page timed out twice; its unreturned contents were not assumed. Her omission from the original filtered catalog does not mean she was removed.

## Grosk: food delivery, rest and stories

Current [starts](https://forever.warcraftdb.com/api/data/node/npc/6928/tab/starts) is empty; [ends](https://forever.warcraftdb.com/api/data/node/npc/6928/tab/ends) lists **2161 A Peon's Burden**. The [Classic NPC raw quest list](https://classicdb.ch/?npc=6928) confirms that sole ending and no linked chain. Read full objective, description, progress and completion of [Forever 2161](https://www.wowhead.com/forever/quest=2161/a-peons-burden), compared with installed `Spoken_Quests/Data/QuestText.lua` accept/completion records.

Ukor has carried food to the Valley of Trials unnecessarily and fears taking it back past dangerous wildlife. The player returns it to Grosk in Razor Hill. Grosk welcomes the visitor, puts the food back, offers refreshment and stresses rest. His remark about hungry recruits is humor, not proof of a starvation policy. The text establishes a practical delivery relationship with Ukor, not kinship or an order Grosk personally gave. No personal readable item or further quest follows from the consulted chain.

The complete installed exact-NPC Grosk gossip was read in `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua`. He welcomes battle-weary guests and their stories, explains comfortable inn rest and hearthstones, and provides home-setting services. The file also includes shared holiday token/perfume material and both-faction leader referrals. Those seasonal templates establish neither his romance nor Alliance-friendly access. Installed Razor Hill guard directions corroborate Grosk as the local innkeeper. The current sells API is empty; it does not cancel the explicit vendor service, and no specific unverified menu is written into the profile.

### Literary connection excluded by era

Grosk does have a novel connection, unlike many minor NPCs. [His referenced history](https://warcraft.wiki.gg/wiki/Grosk) identifies **Jaina Proudmoore: Tides of War** and **War Crimes**. Those scenes concern later Theramore/Garrosh-era events, rather than Classic/Forever. They are excluded entirely from his profile: no inn explosion, conspiracy, visitors from that scene, rebuilding, later war campaign or later festival incident is imported. Historical player comments about a temporary NPC-placement bug are likewise not a story about Grosk trying to join the army. The profile stays with the current quest and installed hospitality dialogue.

## Duokna: verified stock without invented quests

Current [starts](https://forever.warcraftdb.com/api/data/node/npc/3158/tab/starts) and [ends](https://forever.warcraftdb.com/api/data/node/npc/3158/tab/ends) are empty. The raw Classic NPC page contains no quest list. No exact 3158 entry appears in the installed English gossip lookup. This records what was found, not an assertion that every possible dialogue is absent. No personal quest chain was established, so none was fabricated.

Read all eleven rows of her [current vendor stock](https://forever.warcraftdb.com/api/data/node/npc/3158/tab/sells): bread, water, arrows, shot, throwing axes/knives, mining pick, skinning knife and the Forever apprentice herb pouch, mining pack and skinning satchel (277113, 277115, 277114). The authored profile refers to provisions, ammunition, tools and apprentice profession bags without promising bag capacity, discounts, proficiency training or free supplies. No quest delivery or crafting role is inferred from selling tools. A mining pick is not a personal weapon or proof that she worked a mine.

Targeted book/novel research did not establish a personal Duokna biography. The Atlas supplies her merchant location, not family, military service or a secret history. No later-retail storyline is imported.

## Original BuddyDex additions

Grosk's mock-grand toasts to routine work, private practice while putting cups away, and friendship toast are original. They extend his verified taste for company and stories without inventing a former military career or connecting him to the later novel plot. Favorite THANK acknowledges his welcome.

Duokna's copper-flipping hobby, imperfect left-hand catch and searches beneath crates are original. They give a practical merchant a small private amusement without theft, gambling, deception about change or a canonical new service. Favorite CHEER encourages her small successes. The copper is her practice object, not a quest item or player payment.

Each profile has all ten fields and fifteen supported companion lines; both lore columns wrap to twenty lines at width fifty. Four signature lines use approved Eleven v4 voices: Grosk `orc-male` / `SsUXUYPOaoD5XMe36mlU` (greet, idle, befriended, hearth), Duokna `orc-female` / `QooG6jOovlSJWv2vSqN8` (greet, idle, befriended, loot). Hidden tone directions do not appear in bubbles. Validate exact text/voice/cache provenance, decoded audio, routing and gameplay discovery/welcome before installing and packaging.

Raw caches are outside the repository in `C:/Users/brett/BuddyDex-builds/durotar-services-research`. New development packaging is separate from the handed-off v002 upload candidate. CurseForge publication remains deferred to the user's evening setup; this batch does not finish the wider catalog goal.

## Batch validation and recording recovery

The full-loader batch checks and standard addon/Scout smoke suites passed with zero load errors or failures. Both profiles have fifteen supported lines and four correctly routed v4 recordings with exact metadata/text/tone matches. Decoded files pass mono 22,050 Hz, finite samples, non-silent level and duration checks. Mock sessions verified ordinary discovery (25), independent favorite points (150), and first recorded welcome, alongside adult/name routing samples. This is automated validation, not a claim of live visual review.

A local native encoding crash interrupted Duokna's welcome after ElevenLabs had saved it. The exact spoken text, selected voice and v4 model were verified against history item N17s9a7VYyzNc85P5LMZ. Its existing mono 22,050 Hz PCM was recovered and encoded with FFmpeg/libvorbis, then decoded and validated (24.4 seconds). No new synthesis was requested for that recovered line; the generator reused the three completed clips and generated only the remaining loot signature. Raw PCM/history stay outside the repository; runtime carries the ordinary Ogg and exact manifest entry.

Installed and verified 5,682 release files. The separate development v002 ZIP contains 5,654 runtime audio mappings and is 98.54 MiB. The handed-off upload candidate was checked against its recorded SHA-256 and remains unchanged.
