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
