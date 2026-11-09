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
