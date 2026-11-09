-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Data/Lore.lua: the BuddyDex entries (ns.Lore), keyed by NPC ID. Most NPCs
-- have little or no official story, so these are written for BuddyDex:
-- built on the few facts the game gives (who they are, where, the quests
-- they are part of, what they say) and never contradicting them. The
-- writing guide is docs/LORE.md.
--
-- An entry unlocks with friendship, like rewards on a reputation track:
--
--   quote      Acquaintance  one line in their own voice, shown in quotes
--   likes      Buddy         two or three short items
--   dislikes   Buddy         two or three short items
--   gossip     Buddy         Word Around Town: what people say about them
--   bio        Friend        Story: who they are now
--   backstory  Friend        Backstory: how they got here
--   secret     Good Friend   something only close friends hear
--   bestFriend Best Friend   what they say to their best friend
--
-- The Lore column fits all five without scrolling only within its budget:
-- 3, 6, 6, 4 and 3 lines of about 50 characters, 21 in all (docs/LORE.md;
-- the tests check it).
--
-- and two things that work from the first meeting:
--
--   favorite   { emote = "WAVE", hint = "..." }: their favorite emote (the
--              token DoEmote takes) and the hint the Dex shows until the
--              player finds it. Without it, the title decides (Friendship.lua).
--   lines      what they say when they come along as the player's buddy:
--              greet (when brought along), idle (now and then), befriended
--              (the moment they become a Buddy), and any other moment from
--              Data/Lines.lua (poke, levelUp, zone, quest, died...). Each is
--              a list; one is picked. Moments they have no lines for use
--              the general NPC lines (ns.NpcLines). About 15 in all: the
--              general lines carry most of the talking, and these make
--              them sound like themselves.
--
-- Every field is optional. Above each entry, a comment lists the real-game
-- facts it rests on, so a later writer can check nothing contradicts them.
-- US English throughout.

ns.Lore = {

    -- Remy "Two Times", Goldshire, Elwynn Forest. NPC 241, male human.
    -- Classic: merchant from Redridge; repeats phrases; gold dust quest 47
    -- and murloc warning 40. Forever: Jason Mathers's chain 99127-99131
    -- gives him a bait-making role. No named criminal associates inferred.
    -- Apples, hospitality and personal lines are BuddyDex fiction.
    -- Sources and limits: docs/research/remy-two-times.md.
    [241] = {
        quote = "A fair price and a little conversation. That's good business, friend. Good business.",
        likes = { "A deal both sides leave smiling", "Someone taking his warning seriously", "An extra apple for the road" },
        dislikes = { "Murlocs near honest people's work", "Being dismissed before he's finished", "Dust spilled out of an open pouch" },
        gossip = "Remy always seems to buy an extra apple. Goldshire can't decide whether he's found a bargain or forgotten his first purchase.",
        bio = "Remy came from Redridge to do business in Goldshire. He buys gold dust and warns Dughan about murlocs. When Jason Mathers needs a way to protect his fishing, Remy has a plan for bait. He repeats himself, but his concerns are real.",
        backstory = "Trading taught him to leave room for another offer. Traveling taught him to leave room for another person. He started packing a little more food than he needed, just in case a promising conversation lasted past lunch.",
        secret = "The second apple is for company he hasn't found yet. A buyer might only want a price, but someone sharing lunch might stay long enough to become a friend.",
        bestFriend = "Here, take the other apple. No price, no favor. I was hoping you'd come along. Hoping you'd come along.",
        favorite = { emote = "NOD", hint = "A small sign that you heard him matters more than hearing himself twice." },
        lines = {
            greet = { { "A traveling partner! Now that's a good start. A good start.", tone = "[genial merchant voice, warmly pleased]" },
                "Off we go. I've packed enough for two, enough for two." },
            idle = { { "Gold dust is worth counting. So are the people who stop to listen.", tone = "[thoughtful, warm voice, unhurried]" },
                "If Jason brings fish, make sure he hasn't brought the bait as well.",
                "Redridge is east. I still look that way now and then, now and then." },
            befriended = { { "Funny thing. You came back when there wasn't a deal waiting. I'm glad you did.", tone = "[slightly surprised, sincerely touched voice]" } },
            poke = { "You only need to ask once. I'm the one who does the repeating.", "Steady! That's lunch in that pocket, lunch in that pocket." },
            loot = { "Worth a closer look, that. A closer look." },
            bagsFull = { "Tie that pouch before we lose the dust. Before we lose it." },
            quest = { { "They listened? Good. Some warnings need more than a merchant behind them.", tone = "[relieved voice, restrained concern]" } },
            rest = { "Lunch? I've an apple to spare. An apple to spare." },
            levelUp = { "Doing well for yourself! Doing well for yourself." },
            combatEnd = { "Still here? Good. That's the important part, the important part." },
            hearth = { "Back to familiar faces. Worth the journey, worth the journey." },
        },
    },

    -- Innkeeper Allison, Gilded Rose, Trade District, Stormwind.
    -- NPC 6740, female human. Classic: Staghelm referral 3790, New Year
    -- supplies 8860, Hallow's End flex/nougat 8356, fragrance source
    -- dialogue 9026-9027. No later Lorewalker/Legion history used.
    -- Paper roses, preferences and companion lines are original writing.
    -- Sources and continuity: docs/research/innkeeper-allison.md.
    [6740] = {
        quote = "Yes, there's room for you. Even if all you brought was a tired pair of feet and a story.",
        likes = { "A guest who's a good sport", "A celebration everyone can join", "Something made by hand" },
        dislikes = { "Leaving the quiet guest out", "Everyone wearing the same perfume", "Boots muddying freshly swept floors" },
        gossip = "Allison keeps a rose where the guests can see it. Regulars say it never wilts, though nobody has caught her buying a fresh one.",
        bio = "Allison runs the Gilded Rose in Stormwind's Trade District. She welcomes tired travelers, helps provision New Year revelers and makes Hallow's End visitors earn their nougat with a playful show of strength.",
        backstory = "A busy room taught her how easily a small kindness gets lost in the noise. During quieter hours, she learned to fold spare paper into flowers. One at a table could make a plain supper feel like an occasion.",
        secret = "The rose is paper. She kept the first one she folded, crooked petal and all. She likes a welcome that doesn't have to be perfect to mean something.",
        bestFriend = "Come as you are. I'll leave the room to its noise for a moment. This time, I'd like to hear just you.",
        favorite = { emote = "FLEX", hint = "She enjoys a good-natured show of strength, especially when treats are involved." },
        lines = {
            greet = { { "Well, look who's here! Ready to give those feet a new story?", tone = "[bright, welcoming voice, playful warmth]" },
                "A little time outside. I almost forgot I could do that." },
            idle = { { "A crooked paper flower still tells someone you made the effort.", tone = "[warm, reflective voice, quietly pleased]" },
                "Everyone wearing the same fragrance. Where's the fun in that?",
                "You'd be surprised how seriously people take earning a piece of nougat." },
            befriended = { { "You know, I look for you before I look to see whether you need a room.", tone = "[sincerely fond voice, gentle amusement]" } },
            poke = { "Yes? No need to ring twice; I'm right here.", "Showing off again? That had better be your best trick." },
            rest = { { "There. Let the busy people hurry past for a little while.", tone = "[gentle, soothing voice, relaxed pace]" } },
            hearth = { "A place to come back to. That's half the magic of a hearthstone." },
            quest = { "A helping hand? Lovely. I hope they remembered to thank you." },
            levelUp = { "Very impressive! Now, can you do that with a paper crown on?" },
            combatEnd = { "Steady now. Take a breath before you tell me you're all right." },
            bagsFull = { "Some of that could stay in your room, surely." },
            taxi = { "Oh, what a view! The guests never mention this part enough." },
        },
    },

    -- Keldric Boucher <Arcane Goods Vendor>, Pestle's Apothecary,
    -- Trade District, Stormwind. NPC 1257, male human. Classic stock
    -- includes vials and reagents. Works with Kyra and Morgan. No direct
    -- quest chain found; later retail events are excluded. Bottle music,
    -- preferences and dialogue are original. See docs/research/bouchers.md.
    [1257] = {
        quote = "An empty vial is a promise. Preferably a promise that won't leak all over your other promises.",
        likes = { "Glass without a chip in the rim", "A cork that fits the first time", "The little chime of empty bottles" },
        dislikes = { "Loose glass at the bottom of a pack", "Buying the vial after mixing the potion", "A crate marked fragile upside down" },
        gossip = "Customers hear a curious chiming after Keldric closes up. Morgan's shelves look perfectly orderly the next morning, so nobody asks too loudly.",
        bio = "Keldric sells arcane goods in Pestle's Apothecary, alongside Kyra Boucher and Morgan Pestle. Empty vials share the business with magical supplies. For all the impressive ingredients, the glass still needs carrying carefully.",
        backstory = "Checking a shipment, he noticed how differently empty bottles rang against one another. Sorting them became a small pleasure at the end of a long day. He began putting a few aside before wrapping the rest.",
        secret = "He arranges empty vials by their notes and taps out little tunes after closing. He can't sing them very well. The bottles have never complained.",
        bestFriend = "Come by after the shutters close. I found a bottle with just the note I was missing. You get the first performance.",
        favorite = { emote = "CLAP", hint = "A little applause would mean more to him than a ringing sale." },
        lines = {
            greet = { { "Ready to go? One moment. I can hear something loose in that pack.", tone = "[genial, attentive voice, mild concern]" },
                "A change of scenery! The shelves will manage without me." },
            idle = { { "That bottle has a lovely note. Shame it's full of something expensive.", tone = "[quiet, amused voice, appreciative wonder]" },
                "Funny how an empty thing can have such a clear voice.",
                "Kyra would tell you exactly which shelf I put that on." },
            befriended = { { "You stayed for the whole tune. That means more than you might think.", tone = "[warm, slightly bashful voice, sincere gratitude]" } },
            poke = { "Gently! I ring less pleasantly than the bottles.", "If you're looking for the cork, try the other pocket." },
            bagsFull = { { "We need a little space around the glass. Trust me on this.", tone = "[calm, practical voice, gently firm]" } },
            loot = { "A sound rim, at least. Let's see whether the rest is useful." },
            quest = { "Arrived in one piece? Then that's a delivery done well." },
            rest = { "Listen a moment. Every place has its own little sounds." },
            levelUp = { "A fine achievement! I ought to find a brighter note for that." },
            combatEnd = { "All limbs accounted for? Good. Now I can worry about the glass." },
            hearth = { "Home before the shutters close. I might have time for a tune." },
        },
    },

    -- Kyra Boucher <Reagent Vendor>, Pestle's Apothecary, Trade District,
    -- Stormwind. NPC 1275, female human. Stocks magical reagents; Classic
    -- lists candles, runes and seeds. Works with Keldric and Morgan; no
    -- precise family relationship or magical class is asserted. No direct
    -- quest chain found. Paperweight and dialogue are original writing.
    -- Sources and continuity: docs/research/bouchers.md.
    [1275] = {
        quote = "Tell me the whole list before you leave. The one thing you forget is always the thing you need furthest from home.",
        likes = { "A shopping list read to the end", "Small things in their proper places", "A plain answer to a simple question" },
        dislikes = { "Remembering the candles at the door", "Spilled powder in a seed drawer", "Calling everything a magical artifact" },
        gossip = "Kyra keeps an unimpressive little stone near the runes. Customers who notice it lower their voices before asking how powerful it is.",
        bio = "Kyra sells reagents in Pestle's Apothecary in Stormwind's Trade District. Keldric Boucher and Morgan Pestle work in the same shop. Candles, runes and seeds help keep a busy city's spellcasters supplied.",
        backstory = "Restocking small drawers taught her that an important thing needn't look impressive. She began reading orders back before wrapping them. It saves a customer the long walk home to discover what was missing.",
        secret = "The stone has no magic at all. She found it outside and uses it to hold down lists when the door opens. Its greatest feat is keeping Tuesday's order off the floor.",
        bestFriend = "Leave the list a moment. How are you? I know what you came to buy; I'd like to know how you've been.",
        favorite = { emote = "THANK", hint = "Remembering the person who checked your supplies goes a long way." },
        lines = {
            greet = { { "Everything on the list? Good. Now we can enjoy the walk.", tone = "[clear, warm voice, quietly satisfied]" },
                "There you are. I was hoping this visit wasn't just for candles." },
            idle = { { "That stone? Entirely ordinary. It's very good at staying where I put it.", tone = "[dryly amused, matter-of-fact voice]" },
                "A small thing in the right place can save a very long journey.",
                "If you remember something now, we can still turn back." },
            befriended = { { "It's nice to be remembered when nobody needs anything from the shelves.", tone = "[warm, sincerely touched voice]" } },
            poke = { "Yes? Did you remember the rest of the list?", "Careful. There's powder on that sleeve." },
            bagsFull = { { "Keep the powder closed and the seeds dry. We can sort the rest slowly.", tone = "[steady, practical voice, reassuring patience]" } },
            loot = { "One useful little thing. Make room for it properly." },
            quest = { "All handed over? Good. A checked list is a lovely sight." },
            rest = { "You can put the pack down. I'll tell you if anything rolls away." },
            levelUp = { "Well done! Remember me when your spells need more supplies." },
            combatEnd = { "Take a breath. Being ready for the next thing can wait a moment." },
            hearth = { "Home. Where the thing you forgot is usually waiting." },
        },
    },

    -- Jenn Langston, Old Town, Stormwind. NPC 3626, female human.
    -- Facts: named wanderer; the Langston family is associated with the
    -- Pig and Whistle. Responds to several social emotes, including waves
    -- and dances. Not a vendor despite her welcoming dialogue. No quest
    -- chain found. No relation to Karramyn Langston is established.
    -- Greeting practice, little milestones and personal lines are ours.
    -- Sources and limits: docs/research/jenn-langston.md.
    [3626] = {
        quote = "Hello there! You can spare a moment, surely. The cobblestones aren't going anywhere.",
        likes = { "A wave returned across the street", "Dancing without an audience", "Someone remembering her name" },
        dislikes = { "Being treated like street furniture", "Boasting instead of saying hello", "Goodbyes shouted over a shoulder" },
        gossip = "Old Town says Jenn knows everyone. She certainly waves as though she does, even when the other person looks surprised.",
        bio = "Jenn Langston walks the streets of Stormwind's Old Town. Her family is tied to the Pig and Whistle, and she has a greeting ready for passersby. A wave or a few dance steps can get more of a response than rushing past.",
        backstory = "On familiar streets, she learned how easily people can pass one another without a word. She began leaving a little pause after every hello. Sometimes a hurried stranger uses it to tell her something worth hearing.",
        secret = "On a quiet round, she counts how many strangers wave back. One is enough to make the street feel less empty. She starts counting again the next morning.",
        bestFriend = "There you are. I was hoping our paths would cross. Walk with me a little; I want to hear how your day really went.",
        favorite = { emote = "WAVE", hint = "A familiar hand raised across the street can make her whole round." },
        lines = {
            greet = { { "Oh, good! A walk with company. Tell me where we're going.", tone = "[bright, friendly voice, pleased surprise]" },
                "Hello again! I was beginning to think you'd forgotten how." },
            idle = { { "You'd be amazed how much you hear if you leave a little room after hello.", tone = "[warm conversational voice, thoughtful amusement]" },
                "That step nearly counted as dancing. Shall we try the other foot?",
                "A familiar street still has new faces." },
            befriended = { { "I used to hope you'd wave back. Now I look forward to the conversation.", tone = "[gentle, sincerely affectionate voice]" } },
            poke = { "Yes? A hello would have worked, you know.", "I do notice things besides fingers in my shoulder." },
            zone = { "New streets. Let's see who says hello." },
            rest = { { "No need to fill every quiet moment. I'm happy to sit here with you.", tone = "[calm, warm voice, quietly reassuring]" } },
            quest = { "Did you stop long enough to hear their thanks?" },
            levelUp = { "Look at you! I shall have to wave higher to get your attention." },
            combatEnd = { "All right? Take a moment. I'm staying right here." },
            hearth = { "Home again. I like knowing there's someone to come back to." },
            taxi = { "If you see anyone below, give them a wave for me!" },
        },
    },

    -- Morgan Pestle, Pestle's Apothecary, Trade District, Stormwind.
    -- NPC 279, male human. William's brother; receives his candle shipment
    -- in Classic quest 61. Seasonal quests 9024-9025 show initial skepticism
    -- followed by evidence-based revision after examining fragrances.
    -- Later retail versions/events and an unverified holiday outcome are
    -- excluded. The practice sign and personal dialogue are our fiction.
    -- Sources and limits: docs/research/morgan-pestle.md.
    [279] = {
        quote = "Come in, come in. Tell me what you need before I tell you what I have. Saves us both a little trouble.",
        likes = { "A delivery from William", "A question worth investigating", "A clearly labeled bottle" },
        dislikes = { "Buying a cure before asking questions", "A cork in the wrong bottle", "Certainty without a closer look" },
        gossip = "Morgan can turn a delivery into a tour of the shelves. The curious part is how pleased he looks when someone stays just to ask questions.",
        bio = "Morgan Pestle runs Pestle's Apothecary in Stormwind's Trade District. His brother William sends candles from Goldshire, and Morgan pays the courier before inviting a look around. An alchemist's work gives him plenty to explain.",
        backstory = "Practicing his welcome, he tried to sound as impressive as the bottles looked. The words kept coming out wrong. Asking what brought a visitor in worked better. A good question gave him somewhere honest to begin.",
        secret = "He kept his first crooked shop sign under the counter. It only says to come in. On days when nothing seems to work, that small invitation still feels right.",
        bestFriend = "Stay a little. You don't need an errand or an empty bottle to visit me. I was hoping for your company.",
        favorite = { emote = "NOD", hint = "Sometimes an explanation deserves a little sign that you followed it." },
        lines = {
            greet = { { "There you are! No counter between us today. What shall we investigate?", tone = "[welcoming, lively voice, friendly curiosity]" },
                "A little fresh air should clear the smell of reagents." },
            idle = { { "I do enjoy a good question. Especially one that changes my answer.", tone = "[thoughtful, lightly amused voice]" },
                "I hope William remembered to pack those candles tightly.",
                "Labels facing outward. I know we're outdoors. It's a habit." },
            befriended = { { "You've stayed long enough to know me beyond the shop. I'm glad of that.", tone = "[warm, sincere voice, quietly pleased]" } },
            poke = { "Yes? Something you wanted explained?", "Steady hands, please. Some of these pockets contain glass." },
            quest = { { "Delivered safely? Splendid. Was there any news from William?", tone = "[bright, appreciative voice, affectionate curiosity]" } },
            loot = { "Interesting. Let's find out what it is before deciding what it's worth." },
            bagsFull = { "We could start by separating bottles from things that break bottles." },
            rest = { "A moment to think. Often the most useful part of the work." },
            levelUp = { "Excellent progress! What question are you going to ask next?" },
            combatEnd = { "Everyone intact? Good. The bottles can wait." },
            hearth = { "Back to familiar shelves. Perhaps a familiar face, too." },
        },
    },

    -- Innkeeper Gryshka <Innkeeper>, Broken Tusk, Valley of Strength,
    -- Orgrimmar. NPC 6929, female orc. Classic quests 6365, 6384-6386:
    -- Zargh sends meat via Devrak; she likes rare cuts and sends thanks
    -- back through Doras. Zargh jokes about a wedding; no marriage is
    -- established. No later Grimtak/Arcantina/retail events used here.
    -- Recipe notes, broth, private keepsakes and dialogue are our fiction.
    -- Sources and limitations: docs/research/gryshka-and-doras.md.
    [6929] = {
        quote = "A good cut needs a hot fire and someone who knows when to take it off. Sit. I'll handle both.",
        likes = { "Steak with a red center", "A delivery from Zargh", "Guests who arrive hungry" },
        dislikes = { "Good meat cooked to leather", "Fights beside the cooking fire", "Skipping supper to look tough" },
        gossip = "Gryshka guards her recipe notes like battle plans. Her regulars suspect the margins are more interesting than the recipes.",
        bio = "Gryshka keeps the Broken Tusk in Orgrimmar's Valley of Strength. Zargh sends choice meat from the Crossroads; she prefers it rare. A letter of thanks goes back by wind rider, with Doras arranging the journey.",
        backstory = "Keeping an inn taught her that guests ask for food more easily than comfort. She began keeping broth ready beside the grill. Someone nursing an untouched bowl might need a quiet seat more than another question.",
        secret = "She tucks kind notes between her recipes. The meat is long gone, but she likes remembering that someone thought of her before sending it.",
        bestFriend = "I saved a good cut for you. No errands, no hurry. Tell me how you are while the fire gets ready.",
        favorite = { emote = "THANK", hint = "She knows a little appreciation is worth putting into words." },
        lines = {
            greet = { { "There you are. Tell me you packed something better than dry bread.", tone = "[low, gravelly voice, warmly teasing]" },
                "Out for a while, then. Someone had better mind that grill." },
            idle = { { "A red center. A little salt. Why do people insist on making supper difficult?", tone = "[gravelly voice, dry amusement]" },
                "Wonder whether Zargh has anything good set aside today.",
                "The quiet ones need a seat by the fire, too." },
            befriended = { { "You can stop calling yourself a customer. I'll put another bowl out.", tone = "[low, rough voice, warmly sincere]" } },
            poke = { "Careful. I turn steaks with that hand.", "What? Have I got flour on my nose?" },
            rest = { { "Sit down. You don't have to earn every moment of rest.", tone = "[gravelly voice, gently firm]" } },
            hearth = { "Home before the coals go cold. Sensible." },
            loot = { "If that's food, keep it away from the old boots." },
            bagsFull = { "If you can't fit supper in there, you've packed wrong." },
            quest = { "You delivered it? Good. A little thanks travels a long way." },
            levelUp = { "Stronger already! That calls for a better cut." },
            combatEnd = { "Still standing? Good. Take a breath before you claim you're fine." },
        },
    },

    -- Doras <Wind Rider Master>, Valley of Strength tower, Orgrimmar.
    -- NPC 3310, male ORC, not troll. Classic quests 6385-6386 receive
    -- Gryshka's letter, explain known flight routes and send it to Zargh
    -- at the Crossroads through Devrak. No later Skyway/Razor Hill chain.
    -- Patient first-flight coaching and the milestone ledger are fiction.
    -- Sources and limitations: docs/research/gryshka-and-doras.md.
    [3310] = {
        quote = "The first flight always feels longest before you leave the tower. Come on. I'll check the straps.",
        likes = { "A rider's first clear view", "Well-kept saddle straps", "Letters that reach their owners" },
        dislikes = { "Loose packs near the landing", "Blaming a wind rider for nerves", "Pretending to know the route" },
        gossip = "Doras keeps a ledger beside the saddles. Couriers say he's counting fares. Funny how he never seems to count the same way twice.",
        bio = "Doras tends Orgrimmar's wind riders above the Valley of Strength. Gryshka sends her letter for Zargh to him; he directs the courier back to Devrak at the Crossroads. He makes a long road into a short flight.",
        backstory = "After enough first flights, he learned to explain the journey before tightening the straps. Knowing where you're going helps. Being allowed to admit you're nervous helps more. He leaves time for both.",
        secret = "The little marks in his ledger count first-time riders who come back smiling. He likes knowing the sky has become a welcome place for someone else.",
        bestFriend = "No need to prove you're brave up here. I know you. Take the long look before we go; I'll keep a place beside you.",
        favorite = { emote = "WAVE", hint = "He watches every departure long enough to return a farewell." },
        lines = {
            greet = { { "Ready? There's a whole world beyond the edge of that tower.", tone = "[deep gravelly voice, welcoming confidence]" },
                "Traveling together today? Good. Let me check those straps." },
            idle = { { "Some riders count the coins. I watch for the smile when they come back.", tone = "[low resonant voice, quietly pleased]" },
                "Nothing wrong with being nervous. Say so before we take off.",
                "A letter weighs almost nothing. Still matters if it gets there." },
            befriended = { { "You're more than a fare and a destination to me, friend.", tone = "[deep gravelly voice, warmly sincere]" } },
            poke = { "Checking whether I'm strapped in?", "Easy. I'm not the saddle." },
            taxi = { { "Hands steady. Pack secure. Now look out there... that's yours to see.", tone = "[steady reassuring voice, growing wonder]" } },
            landed = { "There we are. Take your time getting your feet back." },
            mount = { "A fine mount. Doesn't give you quite the same view, though." },
            zone = { "Always worth learning another place on the map." },
            quest = { "Delivered safely? Good. Someone was waiting for that." },
            levelUp = { "Look how far you've come. Remember your first journey?" },
            hearth = { "Straight home, then. Even I can see the appeal." },
        },
    },

    -- Thor <Gryphon Master>, Sentinel Hill, Westfall. Human.
    -- Facts: runs the Sentinel Hill gryphon roost. Greets travelers by asking
    -- where they are going and promising the fastest way there. In Classic,
    -- Quartermaster Lewis's "A Swift Message" goes to him, and his "Continue
    -- to Stormwind" sends the player flying to Dungar Longdrink, Stormwind's
    -- gryphon master, with an urgent message ("Return to Lewis" follows). His
    -- name nods to the Norse god of thunder and to Blizzard's Thor Biafore.
    [523] = {
        quote = "Where to, friend? Wherever it is, my birds will get you there before the gossip does.",
        likes = { "Well-fed gryphons", "Clear skies over the Dagger Hills", "Riders who say thank you" },
        dislikes = { "Thunderstorms (yes, really)", "Harvest golems wandering onto the landing pad",
            "Couriers who blame the bird" },
        gossip = "The militia swears Thor has flown every route in the kingdom twice. Funny thing: nobody "
            .. "remembers ever seeing him take off.",
        bio = "Thor keeps the gryphon roost on Sentinel Hill, and he knows every bird by name and every route by "
            .. "heart. When Quartermaster Lewis needs a message in Stormwind by supper, Thor's fastest bird carries "
            .. "it, and Dungar Longdrink grumbles at the other end.",
        backstory = "Thor fed gryphons in Stormwind for anyone who would pay. When the farmers raised a tower on "
            .. "Sentinel Hill, they needed a roost keeper, and he was the only one willing to live that far from a "
            .. "tavern. Named for the god of thunder, he grounds every flight at the first rumble.",
        secret = "He has never ridden a gryphon himself. Someone, he says, has to stay on the ground and wave.",
        bestFriend = "You've flown with me more than anyone in Westfall. I'm naming the next hatchling after you. "
            .. "Don't tell Dungar, he'll want one too.",
        favorite = { emote = "WAVE", hint = "Sees every rider off with the same gesture." },
        lines = {
            greet = { "Need a lift? You came to the right hill.", "Wind's from the south today. Good flying weather." },
            idle = { "Easy, Skyfeather. They're just tourists.", "Somewhere a courier is late, and I will hear about it.",
                "If you see a storm cloud, don't tell the birds." },
            befriended = { "A friend of mine flies at the front of the line. Well. Near the front." },
            poke = { "Careful, these pockets are full of gryphon feed.", "Need a ride? Oh, right. We're walking." },
            levelUp = { "Another level! The birds will want to hear about this." },
            zone = { { "{zone}! I know the flight path from here.",
                say = "I know the flight path from here!" } },
            taxi = { "A flight! I hope they're feeding that bird properly." },
            landed = { "Not bad. I'd have landed it softer, but not bad." },
            mount = { "A mount? Fine. A gryphon would be faster, but fine." },
            hearth = { "A hearthstone. Faster than a gryphon, I'll admit. Barely." },
            quest = { "Another errand run! Lewis would be proud." },
        },
    },

    -- Gryan Stoutmantle <The People's Militia>, Sentinel Hill, Westfall.
    -- Human, male; NPC 234. Facts: paladin leading the local militia.
    -- The People's Militia (12/13/14) defends Westfall's farms; its last
    -- completion recalls his return from Lordaeron. The Defias investigation
    -- follows evidence through Wiley and Shaw; quest 166 explicitly regrets
    -- condemning VanCleef. No later promotion, Northrend or Vanessa events.
    -- The wheat-seed pouch and personal dialogue are BuddyDex fiction.
    -- Sources and chronology: docs/research/gryan-stoutmantle.md.
    [234] = {
        quote = "A field belongs to the people who tend it. Until they can work in peace, our duty here is not finished.",
        likes = { "A field ready for sowing", "Volunteers who keep their word", "Supplies reaching Sentinel Hill" },
        dislikes = { "Abandoned farmhouses", "Reinforcements that never arrive", "Treating a death sentence lightly" },
        gossip = "The militia jokes that Gryan guards one little belt pouch more closely than the battle plans. No one's seen a coin come out of it.",
        bio = "Gryan Stoutmantle leads the People's Militia from Sentinel Hill. The paladin rallies volunteers "
            .. "against the Defias and seeks evidence of their plans. His cause is the people of Westfall and the farms they should be free to tend.",
        backstory = "He returned from the battlefields of Lordaeron to find his homeland overrun. Rather than wait "
            .. "for an army that never came, he gathered a militia. War had followed him home, but this time he could put a name to every field he defended.",
        secret = "The pouch holds wheat seed. He carries it to remember what victory is for. He doesn't know whether it will still sprout. He keeps it dry anyway.",
        bestFriend = "When the fields are safe, help me plant a row. No banners, no speeches. I'd like to see something grow for a change.",
        favorite = { emote = "PRAY", hint = "Finds strength in a quiet moment with the Light." },
        lines = {
            greet = { { "Come. Let us see what help we can offer beyond the hill.", tone = "[steady]" },
                "A little company on the road. I would welcome that." },
            idle = { { "One day, the loudest thing in these fields will be a harvest wagon.", tone = "[thoughtfully]" },
                "A militia is only as strong as the neighbors willing to stand together.",
                "Keep that pouch dry. There is something in it I hope to need someday." },
            befriended = { { "You have my trust. That means more to me than another name on a muster roll.", tone = "[warmly]" } },
            poke = { "I am listening, friend. You need not test the armor.", "At ease. We can speak without a summons." },
            quest = { { "Useful work. Let us hope it brings someone a little closer to home.", tone = "[thoughtfully]" } },
            combatStart = { "Stand together. Leave no one isolated." },
            combatEnd = { "See to the wounded. The rest can wait." },
            levelUp = { "Strength well earned. May you find worthy use for it." },
            zone = { "Someone calls this place home. Remember that as we pass through." },
            loot = { "Take what is useful. There are people counting on these supplies." },
            hearth = { "A roof and a little rest. We should be grateful for both." },
        },
    },

    -- William Pestle, Lion's Pride Inn, Goldshire. Human, male; NPC 253.
    -- Facts: runs Pestle's Apothecary with his brother Morgan in Stormwind;
    -- gathers kobold candle wax and sends Morgan a shipment (60 -> 61).
    -- Gramma Stonefield is his old friend Mildred (Note to William, 107).
    -- He remembers young love and brews invisibility liquor from crystal
    -- kelp to help Maybell visit Tommy Joe (112 -> 114). No later marriage
    -- outcome, identity for William's old love, or extra relatives invented.
    -- Poetry, notebook habits and companion lines are BuddyDex fiction.
    -- Sources and quest-text notes: docs/research/william-pestle.md.
    [253] = {
        quote = "Some troubles need a careful mixture. Others need someone willing to carry a letter. I keep supplies for both.",
        likes = { "Correctly labeled bottles", "A letter sealed with care", "Young love with a sensible plan" },
        dislikes = { "Drinking before reading the label", "Wax spilled over the accounts", "A family feud nobody will explain" },
        gossip = "William guards his recipe book as if it holds the kingdom's secrets. Morgan says some pages don't contain a single measurement.",
        bio = "William gathers candle wax in Goldshire for the apothecary he runs with Morgan in Stormwind. "
            .. "An old friend of Mildred Stonefield, he puts his alchemy to work helping Maybell and Tommy Joe find a way around their families' feud.",
        backstory = "Apothecary work taught William that ordinary things deserve care: a sound cork, clean wax, a "
            .. "legible note. He still remembers being young and in love. When Mildred asks for help, he sees a problem worth more than another sale.",
        secret = "Between the recipes are his attempts at love poetry. He labels them experimental formulas. So far, every rhyme for kelp has required considerable help.",
        bestFriend = "You can read the notebook. Even the dreadful verses. A friend who carries your secrets deserves to hear a few of mine.",
        favorite = { emote = "LOVE", hint = "A hopeless romantic beneath all those ingredient lists." },
        lines = {
            greet = { { "Ah, my traveling associate! Clean hands, I trust?", tone = "[warmly]" },
                "A little fieldwork! Keep the stoppers in while we're walking." },
            idle = { { "If only family feuds dissolved as easily as candle wax.", tone = "[thoughtfully]" },
                "Kelp, help... no. Still a dreadful rhyme.",
                "Morgan would call this a business trip. Saves explaining the notebook." },
            befriended = { { "A trusted friend! Someone I can hand a sealed letter without a second thought.", tone = "[warmly]" } },
            poke = { "Careful! That's the pocket with the glassware.", "Yes? If you've brought kelp, please say so." },
            quest = { { "A useful day's work. I hope we've made someone's life a little easier.", tone = "[pleased]" } },
            loot = { "A specimen? Wrap it separately from the lunch, please." },
            mail = { "A letter! Check the seal before you get carried away." },
            bagsFull = { "Labels facing out. You'll find more room than you think." },
            levelUp = { "Progress! And without setting anything on fire. Splendid." },
            combatEnd = { "Everyone in one piece? Good. Check the bottles next." },
            hearth = { "Back to the inn? I ought to check on that batch." },
        },
    },

    -- Dungar Longdrink <Gryphon Master>, Stormwind. Human, male; NPC 352.
    -- Facts: Stormwind flight master; Classic courier chain 6181 -> 6281
    -- -> 6261 -> 6285 links Lewis, Thor, Osric and Dungar. His progress
    -- dialogue recommends flying over running; he explains route training.
    -- Singing, handling habits and personal dialogue are BuddyDex fiction.
    -- Excludes the later Goldshire/Argus rewrite, Lunarfall and Hearthstone
    -- characterization. Sources: docs/research/dungar-longdrink.md.
    [352] = {
        quote = "The gryphon knows the way. Your job is to hold on and enjoy having somewhere to sit for a change.",
        likes = { "A confident first-time flyer", "Secure straps and balanced parcels", "A clean landing at Sentinel Hill" },
        dislikes = { "Loose buckles", "Couriers running past the roost", "Being interrupted during feeding" },
        gossip = "Some riders swear they've heard singing from Dungar's roost after dark. He blames a squeaky saddle every time.",
        bio = "Dungar Longdrink runs Stormwind's gryphon roost. Osric Strang sends couriers to him with armor for "
            .. "Quartermaster Lewis. Dungar arranges the flight to Thor at Sentinel Hill and explains how the trained routes work.",
        backstory = "Talking over hungry gryphons taught Dungar to keep instructions short. A nervous rider needs a "
            .. "steady voice, a checked buckle and a clear destination. He saves his longer speeches for people who insist that walking will be quicker.",
        secret = "He sings to restless hatchlings. He can't hold a tune, but they settle down anyway. He suspects they do it to make him stop; he keeps singing just in case.",
        bestFriend = "Stay a while after the last flight. You can help settle the little ones. If Thor asks about the singing, you heard nothing.",
        favorite = { emote = "CHEER", hint = "Thinks conquering your first flight jitters deserves a celebration." },
        lines = {
            greet = { "A journey on foot? I'll try to remember how those work.", "Right, then. Who's watching the gryphons?" },
            idle = { "You can tell a hungry gryphon from a cross one. Usually.",
                "Thor will say his birds are faster. Ask him which way the wind was blowing.",
                "No, I wasn't humming. That was my boot." },
            befriended = { "A familiar face at the roost. Makes the whole day easier." },
            poke = { "That's where a gryphon would nip you back.", "Easy. I'm not a saddle that needs adjusting." },
            taxi = { "Straps first. Admire the view once we're clear." },
            landed = { "There! A proper landing. Give the bird a little credit." },
            quest = { "A delivery? Osric's crates would look light beside that lot." },
            bagsFull = { "Pack it evenly. One side shouldn't weigh more than the rider." },
            mount = { "Perfectly respectable. Bit short on wings, though." },
            levelUp = { "Look at you now! Hard to believe you ever needed directions." },
            hearth = { "Neat trick. Doesn't give you much of a view, mind." },
        },
    },

    -- Marshal Dughan, Goldshire, Elwynn Forest. Human, male; NPC 240.
    -- Facts: Stormwind marshal responsible for Goldshire and nearby roads.
    -- Fargodeep/Jasperlode scouting text asks for confirmed kobold reports.
    -- A Fishy Peril initially requires a military report; Thomas's later
    -- report shows the cost of the murloc threat and stretched defenses.
    -- Forever's Book Return/Rare Books concern Brother Paxton's stolen books.
    -- Marginal notes, the private list and personal dialogue are BuddyDex
    -- fiction. No invented rank history, family or completed-quest state.
    -- Sources and chronology limits: docs/research/marshal-dughan.md.
    [240] = {
        quote = "Good news? Start with that. Bad news? Start at the beginning. I'll need the details.",
        likes = { "Scouts who come back safely", "A clear, firsthand report", "A road with nothing to report" },
        dislikes = { "Rumors passed off as orders", "Kobolds finding another mine", "Sending a patrol out shorthanded" },
        gossip = "Dughan always asks for good news. Goldshire wagers he'd demand a written report if anyone actually brought him some.",
        bio = "Marshal Dughan keeps watch over Goldshire with too few troops and plenty of reports. He sends scouts "
            .. "to Fargodeep and Jasperlode, checks threats with Guard Thomas, and helps recover Brother Paxton's stolen books.",
        backstory = "Dughan once tried to keep every concern on a neat patrol map. New reports filled its margins. "
            .. "He learned to leave space for corrections, and to ask where a scout had been before deciding where to send the next one.",
        secret = "Beside the patrol figures, he keeps a small list of people who returned safely. He calls it a check on the numbers. It's the part he reads before going home.",
        bestFriend = "No report today. I just wanted to know how you were. Sit down a moment; Goldshire can spare us that much.",
        favorite = { emote = "SALUTE", hint = "Appreciates someone who remembers a little discipline." },
        lines = {
            greet = { "I'll have a look at these roads myself, then.", "Right. Show me what you've been dealing with." },
            idle = { "One quiet afternoon. That's all I'm asking.",
                "If a kobold's carrying a book, I'd rather know the title.",
                "A blank report can be excellent news, provided someone actually checked." },
            befriended = { "You've earned my trust. Try not to make me put that in triplicate." },
            poke = { "Yes? You can give the report without prodding me.", "I'm listening. At ease." },
            quest = { "Good work. Tell me what you saw, while it's fresh." },
            loot = { "Anything that explains what they were doing out here?" },
            combatStart = { "Keep your footing. Watch each other's backs." },
            combatEnd = { "Check on everyone before we move on." },
            levelUp = { "You've come a long way since your first report." },
            bagsFull = { "Leave room for supplies. You may need the walk home." },
            zone = { "Different roads, same rule: know where your people are." },
        },
    },

    -- Innkeeper Farley, Lion's Pride Inn, Goldshire. Human, male; NPC 295.
    -- Facts: Falkhaan Isenstrider's best friend; accepts Rest and Relaxation
    -- (2158), offering a seat by the fire and refreshments. In the Classic
    -- Legend of Stalvan chain (69/70), remembers a messenger who fled into
    -- a storm and left letters upstairs; sends the player to retrieve one.
    -- Before the Storm records the family's longstanding inn business, but
    -- its later events and his brother's reunion are not part of this entry.
    -- The lost-property habits and secret below are original BuddyDex writing.
    -- Sources and quest-text notes: docs/research/innkeeper-farley.md.
    [295] = {
        quote = "Hang your cloak up first. Whatever's chasing you can wait until you've had a seat.",
        likes = { "Boots drying beside the fire", "Familiar faces at the door", "A quiet last round" },
        dislikes = { "Wet cloaks left on the beds", "Brawls that break the furniture", "A guest leaving without a goodbye" },
        gossip = "Goldshire says Farley keeps every lost button. Ask for yours and he'll want to know which visit, which coat, and how you've been.",
        bio = "Farley runs the Lion's Pride Inn in Goldshire. His friend Falkhaan sends tired adventurers his way. "
            .. "He welcomes them with food, drink and a place to rest, and remembers enough of his guests to help those asking after Stalvan.",
        backstory = "His family kept the Lion's Pride long before today's young adventurers arrived. Farley learned "
            .. "the trade among its tables. A messenger once fled into a storm, leaving letters behind; Farley kept them when the man never came back.",
        secret = "He remembers who left each lost trinket better than he remembers their unpaid tabs. Returning one gives him an excuse to ask whether they got home safely.",
        bestFriend = "No need to tell me who sent you anymore. I know your knock. Come in, put your feet up, and tell me how you've been.",
        favorite = { emote = "THANK", hint = "A word of appreciation lasts longer than a tip." },
        lines = {
            greet = { "Well! Someone else can mind the counter for a bit.", "Out we go. Did you remember your cloak?" },
            idle = { "I ought to be polishing something. Old habit.",
                "Amazing how far a lost glove can travel without its owner.",
                "Wonder who's sitting in your usual chair tonight." },
            befriended = { "Next time Falkhaan sends someone, I'll tell them to look for you, too." },
            poke = { "Yes, yes, I heard you. There's no counter between us now.", "That isn't how you ring for service!" },
            hearth = { "Home for a spell? Good. Even heroes need somewhere to leave their boots." },
            rest = { "There we are. Sit before your knees make the decision for you." },
            quest = { "Another favor done. I hope they offered you a seat." },
            combatEnd = { "Everyone still here? Good. Take a breath." },
            bagsFull = { "That's a lot to leave under a bed by mistake." },
            levelUp = { "Look how far you've come! I'll still remember you before all that fancy armor." },
            died = { "Oh, my friend. I wish a warm room could fix everything." },
        },
    },

    -- Kira Songshine <Traveling Baker>, Elwynn Forest. Human, female.
    -- Facts: NPC 3937; sells breads, cherry pie and drinks around Goldshire.
    -- Classic references describe her traveling Elwynn's roads.
    -- Warcraft: Legends vol. 4, "Bloodsail Buccaneer", also connects her
    -- with James "Jimmy" Blackridge, who tells her his adventures. Do not
    -- invent a marriage, separation or other outcome for that relationship.
    -- No quest chain found in the consulted sources. Baking preferences,
    -- the end-slice hook and companion dialogue below are BuddyDex fiction.
    -- Sources and continuity notes: docs/research/kira-songshine.md.
    [3937] = {
        quote = "A loaf for the road? You can tell me where you're going while I wrap it.",
        likes = { "The heel of a fresh loaf", "A good story over lunch", "Customers who stop to say hello" },
        dislikes = { "Rain getting into the bread basket", "Wasted food", "Being hurried through a story" },
        gossip = "Her regulars say Kira never sells the end slices. Nobody can agree whether she eats them all or hides them.",
        bio = "Kira Songshine sells bread, pie and drinks in Elwynn Forest. Around Goldshire, her basket is a welcome "
            .. "sight to travelers who packed a sword but forgot their lunch. She has time for a customer and a story.",
        backstory = "On her rounds, Kira learned that a short walk can take all morning when everyone has news. "
            .. "She began leaving room between deliveries for conversation. Bread travels better when nobody sits on the basket to hurry her.",
        secret = "The heels are her favorite. She saves them for hungry travelers, then calls them leftovers so nobody has to feel they're asking for charity.",
        bestFriend = "I saved you the best end of the loaf. Sit a moment. This time, I want the whole story, not just the exciting bits.",
        favorite = { emote = "THANK", hint = "A little gratitude makes the whole morning worthwhile." },
        lines = {
            greet = { "There you are! Have you eaten?", "Mind the basket. The pie doesn't have armor." },
            idle = { "Listen to that crust. That's a good loaf.",
                "Everyone remembers a sword. Nobody remembers lunch.",
                "A story's better when nobody has to tell it on an empty stomach." },
            befriended = { "A friend for the road! I'll pack a little extra." },
            poke = { "Checking if I've risen?", "Gently! I'm carrying the soft bread." },
            levelUp = { "Look at you! We'll need a bigger lunch to celebrate." },
            quest = { "Errands done. Now, when did you last eat?" },
            loot = { "Anything edible? No? Well, someone might buy it." },
            bagsFull = { "Don't squash the bread to make room!" },
            zone = { "New customers, perhaps. I hope someone knows a good oven." },
            taxi = { "Keep the basket level! There are pies in here!" },
            landed = { "Feet on the ground. Pastry still in one piece. Lovely." },
        },
    },

    -- Auctioneer Lympkin, the Commons, Ironforge. Gnome, female. Level 50 in
    -- Forever. Facts: one of Ironforge's three auctioneers, with Auctioneer
    -- Buckler and Auctioneer Redmuse, both dwarves. No gossip or quests: she
    -- opens the auction house. Sales and returned lots arrive by mail. The
    -- Great Forge burns at the city's heart; Tinker Town is its gnome quarter.
    -- That she was born in Ironforge and never lived anywhere else is ours.
    [9859] = {
        quote = "Going once, going twice... just browsing? That's fine. Everyone's just browsing until they aren't.",
        likes = { "A bidding war in the last minute", "The roar of the Great Forge", "Buyers who read the listing" },
        dislikes = { "Undercuts of a single copper", "Being asked if she's lost from Tinker Town",
            "Offers that start with \"how about half\"" },
        gossip = "Ask anyone in the Commons: Lympkin can price anything at a glance, down to the copper. "
            .. "Gnomish gadgets too, supposedly.",
        bio = "Lympkin keeps the Ironforge auction house with Auctioneer Buckler and Auctioneer Redmuse. She can "
            .. "name the going price of linen cloth, copper ore and light leather without looking up, and she can "
            .. "call a sale faster than any dwarf can shout a bid.",
        backstory = "Lympkin was born in Ironforge and never left. She grew up in the Commons with the Great "
            .. "Forge roaring at her back, counting the coins traders dropped. Tinker Town calls her more dwarf "
            .. "than gnome, the dwarves call her the loudest gnome they've met, and she takes both as compliments.",
        secret = "She can't tinker at all. Every gnomish gadget that crosses her counter is sold as is, because "
            .. "she has no idea what it does.",
        bestFriend = "You're my best customer and my best friend. I say the first part to everyone. "
            .. "Only you get the second.",
        favorite = { emote = "APPLAUD", hint = "Thinks every sale deserves an ovation." },
        lines = {
            greet = { "Out of the auction house! So this is what daylight looks like.",
                "Lot number one: me. Sold, to the adventurer!" },
            idle = { "Linen cloth is up again. I can feel it.",
                "Buckler had better not touch my ledger while I'm gone.",
                "Somewhere, someone just undercut by one copper." },
            befriended = { "Off the market! I'm your buddy now. No refunds." },
            poke = { "Bids go on the counter, not in my ribs!", "Going once... going twice... stop poking!" },
            loot = { "Ooh! I know a buyer for that.", "Don't sell that to a vendor! Bring it to me." },
            mail = { "Mail! Is it a sale? Tell me it's a sale.",
                "That's the sound of a sold auction. I'd know it anywhere." },
            bagsFull = { "Full bags? I know a place where those turn into gold." },
            levelUp = { "Up a level! Your price just went up too." },
            zone = { { "{zone}! I've sold plenty from here. Never been, though.",
                say = "I've sold plenty from here. Never been, though." } },
        },
    },
}
