# Anvilmar gnome profiles: Alamar Grimm and Wren Darkspring

Reviewed 2026-11-09. These add male and female gnomes to the shared Coldridge/Anvilmar starter selection. With Nori and Durnan there are four completed profiles; Sten remains outstanding for the initial five-profile milestone. No personal Scout sighting or completed player quest is claimed. Adult/named/reaction/attackability checks remain authoritative.

## Identity and current evidence

| NPC | ID | Adult display | Cached current DB2 identity | Role |
| --- | ---: | ---: | --- | --- |
| Alamar Grimm | 460 | 1930 | Gnome race 7 / male sex 0 | Warlock trainer |
| Wren Darkspring | 6376 | 5093 | Gnome race 7 / female sex 1 | Demon trainer |

Current [Alamar](https://forever.warcraftdb.com/api/data/node/npc/460) and [Wren](https://forever.warcraftdb.com/api/data/node/npc/6376) definitions supply their exact names, trainer titles, gnome/humanoid identities and these adult displays. Cached current client display/extra records independently resolve race/sex. Both current nodes omit reaction, location and service/quest relation details; both therefore remain unverified in the public-icon audit. No assumption that a gnome is automatically friendly overrides live checks.

The published current [Alamar](https://www.wowhead.com/forever/npc=460/alamar-grimm) and [Wren](https://www.wowhead.com/forever/npc=6376/wren-darkspring) NPC pages identify Dun Morogh; Wren's comment describes Anvilmar but is treated as a historical player observation. Current primary quest text explicitly locates Alamar inside Anvilmar. Installed class-specific dialogue independently retains both training roles. The [licensed Atlas regional index](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/connected/wowatlas/RegionalIndices_lr.pdf), relevant Coldridge entries only, places both in Anvilmar. Historical context and Classic Alliance records support starter access, without claiming a personal current sighting or live reaction measurement.

Wren is 6376, not Cylina Darkheart 6374. Adult gnome models, not stature or level, establish the relevant model check. Raw snapshots are outside the repository in `BuddyDex-builds/anvilmar-gnome-research`.

## Alamar Grimm

Read full available objective, description, progress and completion of [Tainted Memorandum 3115](https://classicdb.ch/?quest=3115), [Beginnings 1599](https://classicdb.ch/?quest=1599), and the preceding [Dwarven Outfitters 179](https://classicdb.ch/?quest=179). Independently checked current Forever [3115](https://www.wowhead.com/forever/quest=3115/tainted-memorandum), [1599](https://www.wowhead.com/forever/quest=1599/beginnings), [179](https://www.wowhead.com/forever/quest=179/dwarven-outfitters); installed acceptance/completion matches Alamar's two quests.

Read the complete embedded page of [Tainted Memorandum item 9577](https://classicdb.ch/?item=9577). Sten passes his cautious message, and Alamar invites discreet instruction at the back of Anvilmar. Sten's meat-for-gloves arrangement belongs to Sten, not Alamar. No separate continuation was linked from Beginnings on the reviewed NPC/quest definitions.

Confirmed: Alamar is resentful of Gnomeregan's loss and feels gnomes are treated as second-class guests. His accusations about other magic, tinkerers and the dwarves are his expressed opinions, not independent proof that the dwarves caused the loss or refuse all aid. He prefers research, asks for three Frostmane feather charms to test a novice before teaching imp summoning, and cautions that size does not make an imp harmless. His interest in the charms is documented; no discovery of their exact powers is invented.

Installed `SpokenQuestsAudioGossip/generated/npc_gossip_file_lookups.lua` includes the darkness-quotient refusal, caution about corruption/keeping up training, and shared talent retraining. These keep his authored voice sharp and skeptical. Shared retraining dialogue is not a unique traumatic biography. Other classes can earn friendship through eligible emotes without bypassing class restrictions or receiving warlock spells.

Later retail relocation to New Tinkertown, Future of Gnomeregan, Meet the High Tinker and Power of a Warlock are excluded. The possible Heroes of Might and Magic name allusion is not a canonical personal history. Targeted lore/reference searches established no additional Classic personal novel/comic story.

Original detail: a bright yellow ribbon marks his reading place because it is easy to find after interruptions. It is explicitly ordinary and unenchanted, not a new spell, cursed object or game reward. Private friendship remarks soften his reserve as trust grows without erasing his bitterness. Favorite BOW is authored.

## Wren Darkspring

The Classic NPC definition exposes no personal quest starts/ends, and none is invented. Its full eighteen-item inventory was inspected: ranks of Firebolt, Blood Pact and Fire Shield, plus Phase Shift and Soothing Kiss grimoires. These define the historical demon-training stock; the sparse current node does not independently verify each exact item, rank, price or quantity in a live window. The public profile therefore describes her verified role and pricing attitude without promising particular current stock.

Installed dialogue explicitly offers to make warlocks' demons stronger at a cost and briskly refuses non-warlocks. That supports a practical, impatient voice. It does not make Wren the giver of Alamar's quests, confer player-class spell instruction, or establish a romantic/family/apprentice relationship between the two merely because they work near each other.

Later removal of grimoire vendors and Wren in retail is not applied to the current Forever identity. No later location, death or family is inferred. The Atlas entry supplies historical Anvilmar placement, not a separate personal narrative; no additional Classic novel/comic story was established.

Original detail: she enjoys the crisp corner of ordinary toast and dislikes having it mistaken for a sinister ingredient. It is neither a reagent nor a ritual, food-vendor service or reward. Earned friendship gives her room for dry humor and candid affection while she remains brisk about the business. Favorite NOD is authored.

## Recordings and verification

Both profiles contain all ten journal fields and fifteen supported personal lines. Four Eleven v4 first-line signatures each: greet, idle, befriended and learned. Alamar uses the established male gnome voice, Grimblewood Thornwhisker (`ouL9IsyrSnUkCmfnD02u`, runtime group `male`); Wren uses the established custom female gnome voice (`syFkX6FF9X5Ae3tA21pD`, group `female`). Existing race-7 routing is reused, without cloning a voice or changing the Mini Me's existing recordings. Hidden line directions preserve their dry, guarded personalities. Metadata retains exact text/delivery, model, voice and lore source identity.

Validation covers journal budgets, named/adult identities, supported moments, both gnome voice routes, all eight exact clip mappings and source metadata, valid mono 22.05 kHz Ogg signals/durations, ordinary/favorite gains and recorded first Buddy welcomes. Main/Scout smoke suites and package/install verification run before shipping.
