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

    -- Erma 6749 (female human, Goldshire stable master), Joshua Maclure
    -- 258 (male human, vineyard vintner), Lyria Du Lac 913 (female human,
    -- warrior trainer behind Goldshire's smithy, Classic referral 1638).
    -- No modern stable services, precise Maclure kinship or invented war
    -- service. Original hooks: docs/research/goldshire-stable-vintner-warrior.md.
    [6749] = {
        quote = "Give a nervous creature a little room. Being somewhere unfamiliar is easier when nobody insists you be comfortable all at once.",
        likes = { "A companion greeted by name", "A quiet approach", "An owner who remembers feeding time" },
        dislikes = { "Sudden hands near a nervous animal", "Companions treated as replaceable", "A latch left unsecured" },
        gossip = "Erma hums while she works. The hunters aren't sure whether the tune is for their animals or for her.",
        bio = "Erma is Goldshire's stable master in Elwynn Forest. Hunters visiting the village can entrust their animal companions to her care while arranging their travels.",
        backstory = "Working around unfamiliar animals taught her not to hurry an introduction. She began humming softly while she worked, offering a small familiar sound without asking anything in return.",
        secret = "She remembers little tunes by the animals that seemed to like them. Asked to sing for people, she suddenly finds a great deal that needs doing.",
        bestFriend = "You heard that tune? You needn't make a fuss. Walk with me a while, and perhaps I'll remember the next bit.",
        favorite = { emote = "THANK", hint = "A little gratitude for looking after a traveling companion will mean a great deal." },
        lines = {
            greet = { { "A walk? Yes, I'd like that. Everything here is settled for the moment.", tone = "[gentle, grounded voice, easy welcome]" }, "Ready when you are. Let's start without startling everyone." },
            idle = { { "You can make a new place less frightening simply by being patient in it.", tone = "[calm, thoughtful voice, quiet kindness]" }, "A familiar voice can do a surprising amount of good.", "Was I humming? Oh. I suppose I was." },
            befriended = { { "You make room for me to be quiet without thinking something's wrong. That's a lovely thing.", tone = "[soft, grateful voice, sincere warmth]" } },
            poke = { "Yes? Give me a moment to turn around.", "I'm here. There's no need to startle me." },
            loot = { "Mind where you put that. A curious nose may find it before you do." },
            bagsFull = { "Have you left room for your companion's things as well as your own?" },
            quest = { "A job finished, and someone a little easier in their mind. Good." },
            rest = { { "A quiet stop. I'll try to remember that tune while we sit.", tone = "[relaxed, lightly bashful voice, contentment]" } },
            combatEnd = { "All together still? Let's give everyone a moment to settle." },
            levelUp = { "Well done. You're growing more sure of yourself." },
            hearth = { "Back to Goldshire. I wonder who's waiting to greet us." },
        },
    },
    [258] = {
        quote = "Tell me what you enjoy. There's no sense choosing a drink to impress someone else's tongue.",
        likes = { "An honest opinion", "Bottles set down with care", "A toast everyone can join" },
        dislikes = { "A fine label used to excuse a poor drink", "Pressuring someone to have another", "Corks left rolling underfoot" },
        gossip = "Joshua has long descriptions ready for his drinks. His own favorites are often described with one satisfied word.",
        bio = "Joshua Maclure is the vintner and drink vendor at the Maclure Vineyards in Elwynn Forest. He works outside the farmhouse near Pa Maclure, selling refreshments to visitors.",
        backstory = "Talking with customers gave him plenty of practice describing a drink. It also taught him that different people enjoy different things. He became more interested in a person's answer than in proving his own taste superior.",
        secret = "He rehearses elaborate descriptions when nobody is about. Handed something he really enjoys, he usually forgets them all and just says it's good.",
        bestFriend = "I had a splendid description ready for this. Forgotten it. Shall we try it and agree that liking a thing is enough?",
        favorite = { emote = "GRIN", hint = "An honest grin says more about an enjoyable drink than a polished speech." },
        lines = {
            greet = { { "Good to see you! Something for the road before we set off?", tone = "[genial, conversational voice, friendly welcome]" }, "A change of scenery. Let me settle these bottles, and I'm with you." },
            idle = { { "You needn't use a grand word for something you like. Good will do nicely.", tone = "[wryly amused voice, relaxed warmth]" }, "Not everyone wants the same thing. That's what makes asking worthwhile.", "A little water is as welcome in a toast as anything else, if that's what you enjoy." },
            befriended = { { "You tell me what you think, even when we disagree. I like knowing where I stand with a friend.", tone = "[warm, sincerely appreciative voice]" } },
            poke = { "Yes? Thought of the word I was looking for?", "Careful with the bottles. They'll answer much more loudly than I will." },
            loot = { "A fine label. Now, what have we actually found?" },
            bagsFull = { "Something soft between the bottles, if you please." },
            quest = { "Well done! A moment to mark the occasion wouldn't hurt." },
            rest = { { "Sit down, have a drink, tell me what you think. No grand description required.", tone = "[easygoing, hospitable voice, playful assurance]" } },
            combatEnd = { "Everyone safe? Good. Nothing else needs celebrating quite as much." },
            levelUp = { "Here's to that! Whatever you've got in your cup." },
            hearth = { "Home to the vineyard. I wonder who's come by while we've been out." },
        },
    },
    [913] = {
        quote = "Strength helps. So does listening when someone tells you where your feet ought to be. Start there, and we'll see what you've got.",
        likes = { "A correction put into practice", "Gear checked before a lesson", "Effort that survives a bruised ego" },
        dislikes = { "A boast in place of practice", "A blade waved near bystanders", "Calling every mistake bad luck" },
        gossip = "Lyria remembers a pupil's first good stance longer than their loudest victory. She isn't likely to say so during practice.",
        bio = "Lyria Du Lac trains warriors behind the blacksmith building in Goldshire. When a pupil is ready for further training, she directs them to the veteran Harry Burlguard at Stormwind's Pig and Whistle.",
        backstory = "Watching learners repeat the same mistake made her direct about corrections. Watching them finally get it right kept her teaching. She judges a lesson by what someone can do afterward, rather than how impressive the demonstration looked.",
        secret = "She remembers the pupils who needed the most tries. Hearing that one of them has done well can put her in a good mood for the rest of the day.",
        bestFriend = "You kept at it. I noticed. There, you've had your praise; now stop looking so surprised and walk with me.",
        favorite = { emote = "SALUTE", hint = "A disciplined acknowledgment suits someone who values readiness over boasting." },
        lines = {
            greet = { { "Ready? Good. Check your footing, and let's see where the road takes us.", tone = "[firm, confident voice, brisk readiness]" }, "A walk, then. Try not to make every conversation a demonstration." },
            idle = { { "A mistake you notice can teach you something. A mistake you blame on luck tends to return.", tone = "[direct, measured voice, dry authority]" }, "Keep enough room around you to move without hitting your own company.", "No, I haven't forgotten your first attempt. You've improved." },
            befriended = { { "I trust you to listen, and to tell me when I'm wrong. That's worth having beside me.", tone = "[firm, sincere voice, earned respect]" } },
            poke = { "Yes? Use your words.", "Was that meant to improve my attention?" },
            loot = { "Useful gear. Learn its weight before trusting it in a fight." },
            bagsFull = { "You can't carry every answer. Choose what you'll actually use." },
            quest = { { "Good work. Remember what helped, and practice what didn't.", tone = "[brisk, approving voice, restrained pride]" } },
            rest = { "Rest properly. Sloppy practice from exhaustion helps nobody." },
            combatEnd = { "Check everyone, then check the gear. Lessons can wait until we're ready." },
            levelUp = { "That's progress. You earned it. Keep going." },
            hearth = { "Back to Goldshire. Someone's bound to need their stance correcting." },
        },
    },

    -- Remaining Lion's Pride staff: Melika 6778, Michelle 2329 and Josetta
    -- 377 are female humans; Zaldimar 328 is male human. Michelle's local
    -- title is Physician, not retail Bandage Trainer. Josetta's travel wish
    -- is Classic quest dialogue. Zaldimar's Stormrage betrayal is a later
    -- nightmare, not proof of necromancy. Sources/original additions:
    -- docs/research/goldshire-upstairs-and-melika.md.
    [6778] = {
        quote = "Come in, come in. You can work out where you're going next once you've stopped standing in the doorway.",
        likes = { "A greeting returned by name", "Blankets folded with care", "Guests leaving room for one another" },
        dislikes = { "Mud worked into clean bedding", "A visitor made to feel unwelcome", "Furniture moved without asking" },
        gossip = "Melika checks the corners when she folds a blanket. The regulars say she notices one loose thread before anyone else does.",
        bio = "Melika Isenstrider is the assistant innkeeper at the Lion's Pride Inn in Goldshire. She works in the main room, where travelers stop between Elwynn's roads and their next errand.",
        backstory = "Looking after a busy room made small repairs part of her day. A loose thread became a tidy stitch, and occasionally a tiny pattern. She grew fond of leaving something cheerful in places people seldom thought to look.",
        secret = "Some of the blankets she mends have a little stitched star tucked into a corner. She wonders how far those stars travel in people's dreams.",
        bestFriend = "Found the little star, did you? I thought you might. It's nice when someone notices a thing I made just for the pleasure of it.",
        favorite = { emote = "WAVE", hint = "A familiar greeting across a busy room is a lovely way to catch her attention." },
        lines = {
            greet = { { "There you are! A walk sounds lovely. Give me a moment to put this folding down.", tone = "[bright, welcoming voice, easy warmth]" }, "Ready when you are. I've left things tidy enough to come back to." },
            idle = { { "A little stitch in the corner. Most people never notice, but I know it's there.", tone = "[softly pleased voice, playful secrecy]" }, "There's a knack to making a place feel ready for someone.", "You can learn a great deal about a journey from the mud on a pair of boots." },
            befriended = { { "You know my name, not just what you need from me. That's a welcome all of its own.", tone = "[warm, touched voice, sincere affection]" } },
            poke = { "Yes? Something you couldn't find?", "One moment. Let me finish this corner." },
            loot = { "A little keepsake for the journey? Wrap it well." },
            bagsFull = { "Perhaps fold the spare clothes before asking the bag to grow." },
            quest = { "Another errand finished. Have you left yourself a little time to enjoy the day?" },
            rest = { { "Settle yourself. You don't have to be on your way every moment of the day.", tone = "[gentle, reassuring voice, unhurried welcome]" } },
            levelUp = { "Look at you! Coming along nicely, aren't you?" },
            combatEnd = { "All safe? Good. Take a moment before we move on." },
            hearth = { "Back to the Lion's Pride. I hope we've brought most of the mud home on our boots." },
        },
    },
    [2329] = {
        quote = "Take your time with the lesson. A steady pair of hands is worth more than a hurried demonstration.",
        likes = { "Clean bandages kept within reach", "A learner asking to try again", "Someone saying when they need help" },
        dislikes = { "Supplies used up without replacing them", "Bravery confused with hiding an injury", "A lesson rushed to impress someone" },
        gossip = "Michelle's practice bandages are always neatly rolled. One rather crooked bundle never seems to leave her things.",
        bio = "Michelle Belle teaches first aid upstairs in the Lion's Pride Inn, near Priestess Josetta. In Forever, she also teaches the First Aid Kit camping lesson to students sent by Sam Sarsaparilla.",
        backstory = "Teaching beginners reminded her that a simple-looking task can feel awkward the first time. She began keeping a practice roll nearby, ready to demonstrate again without making anyone feel foolish for asking.",
        secret = "The crooked practice roll is one of her own early attempts. She keeps it to remember how much patience a beginner needs, especially on a frustrating day.",
        bestFriend = "That untidy roll? Mine. An early attempt. You may smile; I do. It's good having someone I needn't look accomplished in front of.",
        favorite = { emote = "THANK", hint = "An honest thank-you matters to someone teaching care for others." },
        lines = {
            greet = { { "A little time outside? Yes, I'd like that. I've got my supplies together.", tone = "[calm, capable voice, friendly readiness]" }, "Good to see you. We can walk at a sensible pace for once." },
            idle = { { "Everyone's hands are awkward at first. That's what practice is for.", tone = "[patient, reassuring voice, matter-of-fact kindness]" }, "Keep a little room for supplies you hope you won't need.", "You needn't pretend a lesson was easy. Asking again is allowed." },
            befriended = { { "You make it easy to admit when I need a little patience myself. Thank you for that.", tone = "[quiet, grateful voice, personal warmth]" } },
            poke = { "Yes? Tell me what you need.", "One moment. There's no prize for rushing." },
            loot = { "Keep that apart from the clean supplies, please." },
            bagsFull = { "If you can't reach the things you need, it's time to repack." },
            quest = { "Useful work, done with care. That's something to be pleased about." },
            rest = { { "A sensible stop. You don't have to wait until you're exhausted to take one.", tone = "[steady, gently approving voice]" } },
            combatEnd = { "A moment, please. Is everyone ready before we go on?" },
            levelUp = { "There you are. Practice begins to feel like confidence." },
            hearth = { "Home again. I'll check what needs replacing before the next lesson." },
        },
    },
    [377] = {
        quote = "The Light's gifts are meant to be used with care. Sometimes the first thing you can offer is the courage to stop and help.",
        likes = { "A student helping without being asked", "News from a distant road", "Encouragement offered without pressure" },
        dislikes = { "Healing dismissed as a lesser calling", "A frightened learner being mocked", "Kind intentions never put into practice" },
        gossip = "Josetta always has one more question about a traveler's route. She says it helps her give better directions.",
        bio = "Priestess Josetta trains priests upstairs in Goldshire's Lion's Pride Inn. Her early lesson sends a student to heal and strengthen Guard Roberts. She also directs promising pupils toward further training.",
        backstory = "She once wished she had found the courage to travel the world. Meeting young travelers brings that wish back, even as her teaching helps them prepare to leave. She can encourage another person's first step more easily than her own.",
        secret = "She has chosen a small outing for herself, with no pupil to escort and no errand to justify it. She hasn't settled on the day. Being asked along would help.",
        bestFriend = "I'd like to come with you today. No lesson planned, no errand. Just a little of the world, and someone I'm glad to see it with.",
        favorite = { emote = "CHEER", hint = "A little encouragement might help a teacher take a first step of her own." },
        lines = {
            greet = { { "A journey together? Yes. I think I'd like to say yes this time.", tone = "[gentle, hesitant voice, growing resolve]" }, "Lead on. I've spent enough afternoons asking where other people have been." },
            idle = { { "I used to imagine distant roads. It's a pleasure to have a real one beneath my feet.", tone = "[quietly wondering voice, peaceful delight]" }, "A gift becomes useful when you notice who needs it.", "You needn't know the whole journey to take the next step." },
            befriended = { { "You encourage me with the same patience I try to give my pupils. I treasure that.", tone = "[warm, sincerely moved voice]" } },
            poke = { "Yes? Is there something on your mind?", "I'm here. You can ask without hurrying." },
            quest = { { "Someone is safer for the care you took. Remember that part, too.", tone = "[gentle, earnest voice, warm approval]" } },
            zone = { "So this is what the travelers meant. I'd like a moment to look." },
            rest = { "A little quiet. There's room for that in a journey." },
            combatEnd = { "We're together still. Let us take a breath before going on." },
            levelUp = { "May you use what you've learned wisely, and find joy in learning more." },
            taxi = { "Quite a view from here. I shall have questions when we land." },
            hearth = { "Home, with something new to remember. I'm glad I came." },
        },
    },
    [328] = {
        quote = "Curiosity is an excellent beginning. Knowing when to ask a second question before casting is an even better one.",
        likes = { "A question asked before an experiment", "Careful observations", "Light through an ordinary glass" },
        dislikes = { "Power mistaken for understanding", "A warning dismissed as dull", "A lesson interrupted by showing off" },
        gossip = "Zaldimar sometimes studies an empty bottle by the window. His students suspect a spell. The bottle remains stubbornly ordinary.",
        bio = "Zaldimar Wefhellt teaches mages upstairs at the Lion's Pride Inn. He warns travelers to respect unfamiliar magic and sends developing pupils to Jennea Cannon at Stormwind's Wizard's Sanctum.",
        backstory = "Teaching made him attentive to what people notice and what they merely assume. A question asked at the right moment can spare a great deal of confusion. Outside lessons, he enjoys observations that need no spell to be interesting.",
        secret = "He likes the patterns sunlight makes through colored glass. He could spend a whole quiet afternoon watching them move and never feel the need to explain them.",
        bestFriend = "Look at the light there. No spell, no hidden test. I simply thought you'd enjoy seeing it with me.",
        favorite = { emote = "NOD", hint = "An attentive sign you've understood is more welcome than a flashy demonstration." },
        lines = {
            greet = { { "Good. A walk gives us time to observe things without setting any of them alight.", tone = "[composed, precise voice, dry amusement]" }, "Ready when you are. There is quite enough to study outside a book." },
            idle = { { "A thing needn't be enchanted to deserve a closer look.", tone = "[thoughtful, quietly delighted voice]" }, "Observation first. Explanation afterward. It saves crossing out a great deal.", "Look at the light through that glass. An ordinary pleasure, and a very good one." },
            befriended = { { "You ask what interests me when there isn't a lesson to be had. I appreciate that more than I expected.", tone = "[reserved, sincere voice, gentle warmth]" } },
            poke = { "Yes? Was there a question attached?", "One moment. I should like to finish this thought." },
            loot = { "Interesting. Let us establish what it is before deciding what to do with it." },
            bagsFull = { "Perhaps a little organization would be more useful than another experiment in capacity." },
            quest = { { "Well done. Tell me what you observed, not only what you expected to find.", tone = "[measured, approving voice, curious invitation]" } },
            zone = { "New surroundings. A fine opportunity to question a familiar assumption." },
            rest = { "A quiet interval. We needn't fill it with instruction." },
            levelUp = { "Progress indeed. Take your growing abilities seriously." },
            combatEnd = { "Safe? Good. We can consider the finer points once everyone is ready." },
            hearth = { "Back to Goldshire. I wonder where the afternoon light has reached." },
        },
    },

    -- Lion's Pride staff, all male humans: Dobbins 465 (bartender, sells
    -- the sweet rum used in Classic Dry Times 116), Brog 151 (supplies),
    -- Toddrick 3935 (butcher), Tomas 1430 (cooking trainer and Forever
    -- Camping 101: Cooking 96626 recipient). No later Washburn anecdote
    -- imported. Original personalities: docs/research/lions-pride-staff.md.
    [465] = {
        quote = "Something to drink, something to eat, and a story if you've brought one. Start wherever you like; I'll catch up.",
        likes = { "A tale with a proper ending", "A glass set down on its base", "Customers making room for each other" },
        dislikes = { "A quarrel spilling across the bar", "Fingers snapped to get his attention", "Cheese left uncovered" },
        gossip = "Dobbins hears the start of every story in Goldshire. The regulars reckon he invents the endings while washing up.",
        bio = "Dobbins tends the bar at the Lion's Pride Inn in Goldshire, selling drinks and cheese. His sweet rum is among the supplies adventurers collect for Barkeep Daniels in Lakeshire.",
        backstory = "A busy bar rarely lets him hear a story straight through. He learned to remember the point where a traveler was interrupted, so a return visit could begin with a question instead of the whole tale again.",
        secret = "He does imagine endings to unfinished stories. He's usually wrong, and finding out how much better the real ending was is his favorite part.",
        bestFriend = "There you are! Now, what happened after you opened the door? I've been wondering, and I'm off the bar long enough to listen.",
        favorite = { emote = "GRIN", hint = "An appreciative grin is a fine response to a bartender's cheerful curiosity." },
        lines = {
            greet = { { "Ah, there you are! Tell me the rest of that story while we walk.", tone = "[genial, lively voice, eager curiosity]" }, "A turn outside? Good. Someone else can mind the glasses for a bit." },
            idle = { { "Every tale gets to the interesting bit just as someone wants another drink.", tone = "[wryly amused voice, conversational warmth]" }, "You learn to listen over a busy room. Quiet roads make a pleasant change.", "If a story ends with everyone getting supper, I'm inclined to like it." },
            befriended = { { "You remember to ask how my day's been. It's a pleasure having someone listen back.", tone = "[warm, sincerely appreciative voice]" } },
            poke = { "Yes? I haven't missed the interesting part, have I?", "One moment. I'm trying to remember where you left off." },
            loot = { "Now there's a find with a story attached." },
            bagsFull = { "You brought half a storeroom and left no space for lunch." },
            quest = { "A happy ending to that errand, then. Good to hear." },
            rest = { { "Sit a while. No orders to fill here; I've time to hear the whole thing.", tone = "[relaxed, attentive voice, friendly invitation]" } },
            levelUp = { "Well done! That's another chapter worth telling." },
            combatEnd = { "Everyone all right? That's the part of the story I needed first." },
            hearth = { "Back to the Lion's Pride. I wonder who's arrived while we've been out." },
        },
    },
    [151] = {
        quote = "Before you buy another thing, check what you've already packed. A bit of cord in the right place can save a great deal of trouble.",
        likes = { "A knot that holds and comes undone", "Supplies checked before departure", "A parcel that travels intact" },
        dislikes = { "A good strap cut for no reason", "Packages opened by tearing blindly", "Finding the rope under everything else" },
        gossip = "Brog can tie a parcel while talking to three customers. Ask about the knot, though, and all three get a lesson.",
        bio = "Brog Hamfist sells general supplies inside the Lion's Pride Inn in Goldshire. Travelers can stock up before taking Elwynn's roads onward.",
        backstory = "Watching supplies disappear into overfilled packs made him interested in how things were carried. A neat bundle became a small challenge: secure enough for a journey, simple enough to open without a knife.",
        secret = "He practices decorative knots with spare cord. Most serve no useful purpose at all. He enjoys making them anyway, which is harder for him to explain than the knot.",
        bestFriend = "Here, look at this one. No, it doesn't hold anything better. I just like the shape. Thought you might, too.",
        favorite = { emote = "NOD", hint = "A quiet sign you've followed the explanation will please this practical supplier." },
        lines = {
            greet = { { "Ready for the road? Give those straps a check, and I'll come along.", tone = "[steady, practical voice, friendly assurance]" }, "A little cord, a sound pack, good company. That ought to see us started." },
            idle = { { "The clever bit isn't tying a knot. It's making one you can undo when your fingers are cold.", tone = "[patient, matter-of-fact voice, quiet enthusiasm]" }, "Keep what you'll need first somewhere you can reach it.", "This knot? Just practicing. Nothing needs tying at the moment." },
            befriended = { { "You ask because you're interested, not because something's broken. That's a pleasant change.", tone = "[reserved, warmly pleased voice]" } },
            poke = { "Yes? Loose strap?", "Mind the cord. I've nearly got this one." },
            loot = { "Wrap the sharp edge before it goes in your pack." },
            bagsFull = { { "Set the pack down. Sometimes you need better packing, not another bag.", tone = "[practical, reassuring voice, calm instruction]" } },
            quest = { "Useful work, finished properly. Good." },
            rest = { "Loosen the straps while you sit. Your shoulders will thank you." },
            levelUp = { "Well done. You're getting the hang of the journey." },
            combatEnd = { "Check yourself first, then check your gear." },
            hearth = { "Home again. I'll put the supplies back where I can find them." },
        },
    },
    [3935] = {
        quote = "Tell me how far you're going and how many mouths you're feeding. We can work out a sensible parcel from there.",
        likes = { "A clean work surface", "Provisions portioned for the journey", "A sharp tool put away safely" },
        dislikes = { "Good food left to spoil", "Armor dragged across the counter", "Guessing how much a whole party needs" },
        gossip = "Toddrick wraps a parcel so neatly you'd think it was a gift. He says grease on your spare shirt is nobody's present.",
        bio = "Toddrick is the butcher and meat vendor in Goldshire's Lion's Pride Inn. He works in the back room near Tomas, where travelers can buy food before setting out.",
        backstory = "Selling provisions taught him that the journey matters as much as the appetite. He began asking how far people were traveling, then took pride in sending them out with a parcel that suited the answer.",
        secret = "With clean scraps of wrapping paper, he folds tiny birds. He leaves the best ones standing on the counter and pretends he hasn't noticed when somebody admires them.",
        bestFriend = "That paper bird? Take it, if you like. Keep it above the provisions. Took me three tries to get those wings even.",
        favorite = { emote = "APPLAUD", hint = "A little appreciation for tidy handwork may reveal an unexpected point of pride." },
        lines = {
            greet = { { "How far today? Tell me while I wrap something for the road.", tone = "[grounded, businesslike voice, kindly interest]" }, "A walk will do nicely. Let me leave the counter clean first." },
            idle = { { "Pack for the journey you're taking, not the appetite you had before breakfast.", tone = "[dryly amused, practical voice]" }, "Clean tools, clean hands. Worth the extra moment.", "This paper folds better than it looks. Watch the corner here." },
            befriended = { { "You notice the care that goes into things. It's good having a friend who does.", tone = "[quiet, sincere voice, appreciative warmth]" } },
            poke = { "Yes? Give me room to turn, would you?", "Another parcel? Or just checking I'm still here?" },
            loot = { "Wrap it separately if it's going near the food." },
            bagsFull = { { "Keep the provisions together, away from anything that leaks. Your spare shirt will thank you.", tone = "[practical, wry voice, gentle instruction]" } },
            quest = { "A fair day's effort. Hope you stopped to eat somewhere in it." },
            rest = { "Good place to open a parcel. Let's see how it traveled." },
            levelUp = { "Well done. You look pleased, and rightly so." },
            combatEnd = { "All safe? Good. Everything else can wait." },
            hearth = { "Back to the inn. There's a counter needs seeing to." },
        },
    },
    [1430] = {
        quote = "You don't have to make a feast your first time. Make something you can eat, notice what worked, and try again tomorrow.",
        likes = { "A beginner asking another question", "A steady cooking fire", "Someone offering him a taste" },
        dislikes = { "Mocking a learner's first meal", "More heat offered as every answer", "A pot abandoned on the fire" },
        gossip = "Tomas can find something encouraging to say about almost any first attempt. The kitchen keeps plenty of water nearby.",
        bio = "Tomas teaches cooking at the Lion's Pride Inn in Goldshire. In Forever, Sam Sarsaparilla sends new campers to him to learn cooking and the campfire basics that support a wilderness camp.",
        backstory = "Teaching showed him how much courage can go into offering someone a first attempt. He learned to start with what worked, then give one useful thing to try differently. A willing cook matters more to him than a perfect first plate.",
        secret = "He's surprisingly nervous when a former pupil offers to cook for him. He wants to enjoy their meal without turning the whole supper into another lesson.",
        bestFriend = "You're cooking? I'd like that. I'll sit down, keep my advice to myself, and be very glad someone thought to feed me.",
        favorite = { emote = "THANK", hint = "An honest bit of gratitude is a fine way to finish a patient lesson." },
        lines = {
            greet = { { "Off we go, then. If we stop for a meal, perhaps you can show me what you've learned.", tone = "[warm, encouraging voice, friendly curiosity]" }, "A little time outside the kitchen. Yes, I'd enjoy that." },
            idle = { { "Taste it before adding anything else. Sometimes the next thing a dish needs is nothing.", tone = "[patient, thoughtful voice, gentle instruction]" }, "Everyone starts with something simple. No shame in making it well.", "A good fire and a little patience can improve a long day." },
            befriended = { { "You don't have to call me over only when a pot's in trouble. I'm glad to be here for myself.", tone = "[warm, touched voice, easy affection]" } },
            poke = { "Yes? Something caught on the bottom?", "One moment. I was wondering what we'd have for supper." },
            loot = { "An interesting ingredient? Best find out before putting it in the pot." },
            bagsFull = { "You've room for three spare weapons and no room for dinner?" },
            quest = { "There you are. Something learned and a job finished." },
            rest = { { "A good moment for a meal. If you're cooking, I'll try very hard to stay out of your way.", tone = "[warm, lightly self-conscious voice, amused restraint]" } },
            levelUp = { "Well done! Practice is showing, isn't it?" },
            combatEnd = { "Take a breath. No need to hurry straight into the next thing." },
            hearth = { "Back to the inn. I wonder what the kitchen smells like today." },
        },
    },

    -- Elwynn farmers: Pa Maclure 250 (male human, vineyard patriarch),
    -- Ma Stonefield 244 (female human, Classic quest 88), Gerard Tiller
    -- 255 (male human, repeatable apple/water trade 16), Homer Stonefield
    -- 894 (male human, fruit seller). No resolved feud, exact Stonefield
    -- kinship or later Draenor employment imported. Personal hooks and
    -- lines are original: docs/research/elwynn-farmers.md.
    [250] = {
        quote = "A field doesn't stay in order because you wish it so. Come along. I'll show you what a day's care can do.",
        likes = { "A vine tied without bruising it", "Tools returned before sundown", "A promise followed by honest work" },
        dislikes = { "Stonefield meddling", "Boots trampling a planted row", "Being told to forget an old grievance" },
        gossip = "Pa can spot a crooked vine support across the yard. He claims a man ought to take the same care with his own fence.",
        bio = "Pa Maclure heads the Maclure family at their Elwynn vineyard. His feud with the Stonefields keeps his daughter Maybell from openly courting Tommy Joe Stonefield.",
        backstory = "The vineyard gives him something tangible to put right: a loose tie, a leaning support, a tool left out. He brings that same stubborn certainty to family matters, where the answers aren't nearly as simple.",
        secret = "He has a vine that refuses to grow straight. He adjusts its support instead of pulling it out. He's rather proud of how well it's doing, though he rarely points it out.",
        bestFriend = "Come look at this vine. Crooked as ever, but growing well. I thought you might appreciate it. Mind where you step.",
        favorite = { emote = "NOD", hint = "A quiet sign that you're listening may get further than another argument." },
        lines = {
            greet = { { "Ready? Good. There's daylight yet, and no sense wasting all of it talking.", tone = "[firm, weathered voice, restrained welcome]" }, "A walk, then. I've left the tools where I can find them." },
            idle = { { "Tie a vine too tightly and you'll harm the very thing you're trying to support.", tone = "[practical, thoughtful voice, measured certainty]" }, "A straight row is a fine sight after a long morning.", "You can tell a good tool by how often you reach for it." },
            befriended = { { "You do what you say you'll do. I've learned I can count on that.", tone = "[reserved, sincere voice, hard-earned respect]" } },
            poke = { "Yes? I'm listening. Once will do.", "Is there something needs seeing to?" },
            loot = { "Useful? Keep it dry, then. Useful things deserve looking after." },
            bagsFull = { "Stop stuffing things in and lay them out properly. You'll find room." },
            quest = { { "Work finished properly. That's worth more than a grand promise.", tone = "[firm, approving voice, plainspoken pride]" } },
            rest = { "A short rest. A tired hand makes careless work." },
            levelUp = { "Well done. Take pride in it, then see what you can do next." },
            combatEnd = { "Everyone sound? Check before we move on." },
            hearth = { "Back to the vineyard. I'll have a look at the supports before supper." },
        },
    },
    [244] = {
        quote = "That's a crop out there, not a free supper for every pig in Elwynn. Someone has to mind what we've worked for.",
        likes = { "Seedlings left with room to grow", "A gate properly latched", "A problem dealt with promptly" },
        dislikes = { "Princess eating her vegetables", "Advice from outside the fence", "A day's work undone before breakfast" },
        gossip = "Ma can hear a gate swinging from inside the house. A visitor who remembers the latch gets a much warmer welcome.",
        bio = "Ma Stonefield lives at the Stonefield Farm in Elwynn. The Brackwells' enormous prize pig, Princess, eats her vegetables. Ma asks adventurers to stop the sow and bring back her brass collar as proof.",
        backstory = "Tending a crop taught her to notice small warnings before they become large problems. A loose latch or fresh damage earns immediate attention. She has little patience for anyone who calls the work easy.",
        secret = "She checks the first new seedlings before the rest of the patch. Nothing needs doing quite yet; she just likes seeing that something small has made it through the night.",
        bestFriend = "Come see what's coming up. You needn't fix anything today. Just mind the row, and close the gate behind you.",
        favorite = { emote = "CHEER", hint = "A little encouragement for the person defending the vegetable patch wouldn't go amiss." },
        lines = {
            greet = { { "There you are. Gate's shut, patch is checked. Right, let's get going.", tone = "[brisk, sturdy voice, practical good humor]" }, "A walk will do me good. If a pig comes past, you'll understand why I'm staring." },
            idle = { { "They call it a prize pig. I can tell you whose vegetables helped it win.", tone = "[dry, indignant voice, pointed humor]" }, "Leave room around a seedling. Growing things need space, too.", "One good latch can save a whole morning's work." },
            befriended = { { "You take the trouble seriously. That's a kindness, and I haven't missed it.", tone = "[warm, forthright voice, sincere appreciation]" } },
            poke = { "Yes? Speak up, then.", "Something got through the fence? No? Good." },
            loot = { "Useful bit, that. Keep it where you can find it." },
            bagsFull = { "You can't pack a basket by throwing everything on top." },
            quest = { { "Good! A problem settled before it grows into another one.", tone = "[brisk, relieved voice, hearty approval]" } },
            rest = { "Sit a spell. The work goes better when your legs stop aching." },
            combatEnd = { "Whole and standing? That's what I wanted to hear." },
            levelUp = { "Look at you! Stronger than when we set out." },
            hearth = { "Home. Let's see whether the gate's still latched." },
        },
    },
    [255] = {
        quote = "A little water makes a long afternoon easier. If you've a skin to spare, I've an apple worth stopping for.",
        likes = { "Cool spring water", "A fair little trade", "Finishing a row before the shade moves" },
        dislikes = { "An empty waterskin at midday", "An apple wasted for a small bruise", "Being hurried through his break" },
        gossip = "Gerard measures a hot day in empty waterskins. He says it is more useful than knowing the hour.",
        bio = "Gerard Tiller farms at the Maclure Vineyards in Elwynn Forest. Thirsty from his work, he offers travelers an apple in exchange for refreshing spring water, and welcomes another trade later.",
        backstory = "Work outside made him appreciate small comforts that can be carried in one hand. A drink and something crisp to eat won't finish the rows for him, but they make starting the next one a good deal easier.",
        secret = "He has an excellent excuse ready for every extra minute of a break. His favorite is that the shade hasn't quite reached the right place yet.",
        bestFriend = "No trade needed this time. Take an apple and rest your feet. I'm waiting for the shade to move. Could take a while.",
        favorite = { emote = "THANK", hint = "A simple bit of gratitude suits a simple, fair exchange." },
        lines = {
            greet = { { "A walk? Gladly. Let me fill my waterskin before we start.", tone = "[easygoing, friendly voice, unhurried warmth]" }, "Good day for a change of scenery. Mind you, most days are." },
            idle = { { "An apple and cool water. You can make an afternoon better without making it complicated.", tone = "[relaxed, contented voice, conversational warmth]" }, "That shade looks promising. Worth keeping in mind for later.", "A row always seems longer when you've forgotten your drink." },
            befriended = { { "You come by even when there's nothing to trade. I like that very much.", tone = "[warm, quietly delighted voice]" } },
            poke = { "Hm? Sorry, I was considering a break.", "Yes? I hope that's a full waterskin you're holding." },
            loot = { "A useful find. A cool drink would be another." },
            bagsFull = { "Have you left room for something to eat and drink?" },
            quest = { "That's one job finished. Feels good, doesn't it?" },
            rest = { { "Fine bit of shade. We ought to give it a proper try before moving on.", tone = "[playfully persuasive voice, relaxed good humor]" } },
            combatEnd = { "Phew. I could use a drink after that." },
            levelUp = { "Well done! You've earned the good apple." },
            hearth = { "Home again. Time to put my feet up for a little while." },
        },
    },
    [894] = {
        quote = "Pick one that suits you. The biggest apple isn't always the one you'll enjoy most.",
        likes = { "A basket packed with care", "Someone finding a new favorite", "Fruit enjoyed before it spoils" },
        dislikes = { "Squeezing every apple in the basket", "Good food judged by its looks alone", "Heavy gear dropped on the produce" },
        gossip = "Homer takes his time arranging the fruit. The apple he chooses for himself is rarely the prettiest one.",
        bio = "Homer Stonefield sells fruit outside the barn at the Stonefield Farm in Elwynn Forest. Travelers can stop there for provisions before setting out again.",
        backstory = "Selling fruit gave him plenty of chances to watch people choose. Some want the largest, others the brightest. He grew fond of helping a hesitant customer find something they would actually enjoy eating.",
        secret = "He likes the oddly shaped apples best. They're easy to recognize in a basket, and he enjoys proving that a crooked little thing can still be sweet.",
        bestFriend = "Kept an odd-looking one for you. Give it a try before you laugh. If it's good, we'll call that excellent judgment.",
        favorite = { emote = "SMILE", hint = "A pleased face after a good bite is the sort of review he enjoys." },
        lines = {
            greet = { { "Good to see you! Pick something for the road before we leave.", tone = "[open, cheerful voice, friendly invitation]" }, "A trip out? All right. Just let me settle this basket first." },
            idle = { { "A crooked apple can still be sweet. Worth remembering when you're choosing.", tone = "[genial, thoughtful voice, easy amusement]" }, "Don't put the heavy things on top of your lunch. You'll regret it at lunch.", "Try something different now and then. You might find a new favorite." },
            befriended = { { "I know which one you'd reach for now. That's a nice thing to know about someone.", tone = "[warm, pleased voice, personal affection]" } },
            poke = { "Yes? Changed your mind about that apple?", "Careful with the basket. It's done nothing to deserve that." },
            loot = { "Wrap that up before it goes in beside the food." },
            bagsFull = { { "Heavy things at the bottom, fruit at the top. There, your lunch has a chance now.", tone = "[practical, amused voice, kindly instruction]" } },
            quest = { "Nicely done! Stop for a bite before the next errand." },
            rest = { "This looks like a good place to enjoy what we brought." },
            combatEnd = { "Still in one piece? You first. I'll check the provisions after." },
            levelUp = { "Well done! Growing into quite the traveler, aren't you?" },
            hearth = { "Back to the farm. I wonder what needs sorting in the baskets." },
        },
    },

    -- Deeprun Tram gnomes: Classic quests 6661/6662 establish Monty's
    -- rat-catching work, Nipsy's kabob business, their brotherhood and
    -- Monty's changed behavior after Gnomeregan. No actual seafaring past.
    -- Haggle's ambient speech establishes hardship and a love of cheese;
    -- no cause, cure or exact lost possessions invented. Personal hooks
    -- and companion lines are original. docs/research/deeprun-tram.md.
    [12997] = {
        quote = "Steady now, matey. A proper crew keeps together, even when half the crew has whiskers and a dreadful sense of direction.",
        likes = { "A tune that brings everyone along", "A crew that waits for stragglers", "A crate delivered on time" },
        dislikes = { "A rattling crate left behind", "Someone stepping on his flute", "A passenger pushed toward the edge" },
        gossip = "Monty counts his catches twice before sending a crate off. The second count gets rather nautical if anything moves.",
        bio = "Monty catches rats at the Ironforge end of the Deeprun Tram. His flute helps adventurers gather them alive for his brother Nipsy's kabob business at the Stormwind depot.",
        backstory = "Nipsy says Monty changed after the Gnomeregan incident and began speaking like a pirate, despite never having seen the ocean. Down in the tram, he has work, a flute and a brother waiting for his deliveries.",
        secret = "He likes the moment when someone turns back to check that he's coming. For a little while, he doesn't have to be the one calling everyone together.",
        bestFriend = "Hold up, matey. I'm coming too. Good to have a place beside you, even when there's no cargo to carry.",
        favorite = { emote = "SALUTE", hint = "A friendly salute might make this rat-catching captain feel welcome aboard." },
        lines = {
            greet = { { "Ahoy, matey! Room for one more in your crew?", tone = "[jaunty, friendly voice, theatrical pirate greeting]" }, "Flute? Aye. Boots? Aye. Right, we're ready to cast off." },
            idle = { { "Count the crew before you leave. Then look back for anyone you missed.", tone = "[gentle, earnest voice, soft pirate lilt]" }, "Five little tails, all following one tune. Quite a sight, matey.", "No crates today? Well, I suppose we can travel for the pleasure of it." },
            befriended = { { "You came back for me, matey. That's worth more than a full cargo hold.", tone = "[warm, deeply touched voice, quiet pirate lilt]" } },
            poke = { "Aye? The captain's listening.", "Steady with the elbows, matey. That's me flute arm." },
            taxi = { "A flying passage! Best keep a firm hold of your belongings, matey." },
            landed = { "All here? Boots, packs, friends? Fine work, crew." },
            bagsFull = { "A full hold! Mind you leave room to get yourself aboard." },
            quest = { { "Cargo delivered, crew accounted for. A fine day's work, matey.", tone = "[pleased, hearty voice, satisfied pirate flourish]" } },
            rest = { "Aye, a little shore leave. I'll sit beside you." },
            levelUp = { "Well sailed, matey! Onward when you're ready." },
            hearth = { "Home port. Let's make sure nobody's been left behind." },
        },
    },
    [13018] = {
        quote = "Have a seat while it's hot. You can tell me about the journey after you've had something to eat.",
        likes = { "A customer who tries a bite", "Monty's deliveries arriving safely", "Sharing the last warm helping" },
        dislikes = { "A good meal left to go cold", "A crate forgotten on the platform", "People laughing cruelly at Monty" },
        gossip = "Nipsy can hear a complaint about the menu from the far end of the platform. He'll usually answer by offering a taste.",
        bio = "Nipsy sells rat kabobs at the Stormwind end of the Deeprun Tram. His brother Monty supplies live rats from the Ironforge depot, sometimes sending an adventurer to deliver a carton.",
        backstory = "Nipsy remembers his brother before the Gnomeregan incident. He speaks sadly of the change in Monty, whose pirate talk doesn't come from a life at sea. Their rat-kabob trade still connects them across the tram.",
        secret = "He sometimes saves a helping until it has gone cold, just in case his brother comes over in person. He'd rather warm it again than admit he wasn't hoping.",
        bestFriend = "Nothing you need to deliver today? Good. Sit with me. I've kept a helping, and I'd like the company.",
        favorite = { emote = "THANK", hint = "A little appreciation for a warm meal matters more than a grand review." },
        lines = {
            greet = { { "There you are! Eaten yet? We can put that right before we go.", tone = "[brisk, welcoming voice, practical warmth]" }, "A change of scenery. Let me check I've brought a snack." },
            idle = { { "People will try all sorts on an adventure, then get fussy about lunch.", tone = "[dryly amused voice, friendly confidence]" }, "Monty keeps his end of things moving. I hope he remembers to eat, too.", "A meal tastes better when you're allowed to sit down for it." },
            befriended = { { "You stay after the food's gone. That's how I know you've come to see me.", tone = "[warm, quietly grateful voice]" } },
            poke = { "Yes? Hungry again already?", "Careful. If I drop lunch, you're helping pick it up." },
            loot = { "Useful? Good. If it's food, even better." },
            bagsFull = { "You packed enough for a journey and forgot room for lunch, didn't you?" },
            quest = { "Delivered safely? Good. Someone was waiting on that." },
            rest = { { "Here, sit down a moment. A warm bite and a little company won't hurt.", tone = "[gentle, hospitable voice, easy warmth]" } },
            levelUp = { "Well done! Now, surely that's worth stopping for something to eat." },
            combatEnd = { "Everyone still with us? Right. Catch your breath first." },
            hearth = { "Home again. I wonder whether Monty's had his supper." },
        },
    },
    [14041] = {
        quote = "You can sit here. Plenty of people pass through, but there's room for someone who wants to stay a moment.",
        likes = { "A little cheese", "Someone remembering his name", "Company that doesn't hurry him" },
        dislikes = { "Being laughed at when he's confused", "A meal taken out of his reach", "People speaking over him" },
        gossip = "Haggle remembers which travelers stop to speak. He sometimes leaves a little room beside him before they've even reached the platform.",
        bio = "Haggle is a leper gnome at the Ironforge end of the Deeprun Tram. He wanders, searches through discarded things and asks passersby for change. His talk often turns to rats, cheese and what he has lost.",
        backstory = "He says he once had everything and lost it. His scattered recollections don't tell a clear history, and a listener cannot fill in the missing pieces for him. The person sitting on the platform still deserves to be heard.",
        secret = "He likes keeping a place for someone. It gives him a small, pleasant thing to expect, even when he isn't sure when they'll come back.",
        bestFriend = "Oh, it's you. I kept a place. You can tell me where you've been, or we can just sit. I'm glad you came.",
        favorite = { emote = "WAVE", hint = "An ordinary friendly greeting can mean a great deal to someone people walk past." },
        lines = {
            greet = { { "Oh! I know you. Are we going somewhere together?", tone = "[hesitant, pleasantly surprised voice, growing warmth]" }, "Let me get my things. Won't take long. There aren't many." },
            idle = { { "A little cheese, a place to sit, someone to talk to. That's a good afternoon.", tone = "[gentle, thoughtful voice, small contentment]" }, "I like when someone says my name before asking anything.", "Was I telling you something? It'll come back. You go on." },
            befriended = { { "You remembered me. I was hoping you would. Shall we sit together a while?", tone = "[soft, moved voice, sincere warmth]" } },
            poke = { "I'm here. Did you want to say something?", "Oh. Yes? Give me a moment." },
            loot = { "Someone might have a use for that. Take a good look first." },
            bagsFull = { "Full already? Best check what you've got before throwing anything away." },
            quest = { "They were glad to see you, were they? That's nice." },
            rest = { { "This looks like a good place. Is there room beside you?", tone = "[quiet, hopeful voice, tentative ease]" } },
            combatEnd = { "Is it quiet now? I'd like a quiet moment." },
            levelUp = { "Oh, well done. You should be pleased with yourself." },
            hearth = { "Back somewhere you know. That's a comfort." },
        },
    },

    -- Bailey Stonemantle <Banker>, Vault of Ironforge. NPC 2461, male
    -- dwarf. No direct quest chain found. The real-world circus reference
    -- is not an in-world employment history. Coin balancing and lines are
    -- original. Sources: docs/research/ironforge-stonemantles.md.
    [2461] = {
        quote = "Gold, spare boots, a stone you like the look of... if it matters to you, tell me where you'd like it kept.",
        likes = { "A neatly packed deposit", "A coin balanced on its edge", "A customer with room in their pack" },
        dislikes = { "Loose powder among the keepsakes", "Judging a treasure by its price alone", "A muddy sack dragged over the counter" },
        gossip = "Bailey's counter is always clear. The regulars suspect he likes things tidy. Nobody asks why one copper sometimes stands on its edge.",
        bio = "Bailey Stonemantle is a dwarf banker at the Vault of Ironforge. Barnum Stonemantle works there too, with Dinita administering the vault. The bank has room for ordinary belongings as well as valuable finds.",
        backstory = "Quiet moments between deposits gave him a small challenge: standing a copper on its edge without disturbing it. Keeping the counter clear helped. He discovered that patience could make an ordinary coin rather interesting.",
        secret = "He can keep a copper balanced through a whole conversation, provided nobody notices. The instant someone points it out, his hand usually knocks it flat.",
        bestFriend = "You can watch the copper. If I knock it over, we'll blame the counter and try again. I don't mind looking foolish with you.",
        favorite = { emote = "APPLAUD", hint = "A little appreciation for a small feat might catch him pleasantly off guard." },
        lines = {
            greet = { { "There you are! Pack a little lighter this time, did you?", tone = "[warm, grounded voice, genial amusement]" }, "A walk away from the counter. Good. I'll try not to count the paving stones." },
            idle = { { "A copper on its edge can be more interesting than a mountain of gold.", tone = "[quietly amused voice, patient delight]" }, "Some things are worth keeping because of who handed them to you.", "Steady hands. No sudden elbows. Ah, there it goes." },
            befriended = { { "You make time for the fellow behind the counter. That's a fine thing to find in a friend.", tone = "[warm, sincerely grateful voice]" } },
            poke = { "Careful! You'll upset my very important copper.", "Yes? Something else you meant to bring along?" },
            bagsFull = { { "Next time we're in Ironforge, leave a few keepsakes with me. Give your shoulders a chance.", tone = "[practical, kindly voice, reassuring]" } },
            loot = { "Worth keeping? Doesn't have to be expensive." },
            mail = { "Something from a friend? That's worth opening carefully." },
            quest = { "Job finished and everyone thanked? A tidy bit of work." },
            rest = { "Set the pack down. Even a good strap deserves a rest." },
            levelUp = { "Well done! There's something you can't put in a vault." },
            hearth = { "Home. I hope you've left yourself somewhere to sit among the treasures." },
        },
    },

    -- Barnum Stonemantle <Banker>, Vault of Ironforge. NPC 2460, male
    -- dwarf. Canonical bank role/family affiliation; no exact relationship
    -- to each Stonemantle assigned. No direct quest found. Terrible jokes
    -- and private hopes are fiction. docs/research/ironforge-stonemantles.md.
    [2460] = {
        quote = "Come in, come in! A moment at the counter and we'll have you ready to enjoy carrying less than an entire warehouse.",
        likes = { "A customer leaving with a grin", "A well-timed welcome", "A joke that finally lands" },
        dislikes = { "A queue made longer by grumbling", "Anyone feeling too poor to say hello", "Being asked to count while laughing" },
        gossip = "Barnum tries a new joke on the morning queue. The bank's shortest lines aren't always the ones with the fewest customers.",
        bio = "Barnum Stonemantle works as a banker in the Vault of Ironforge alongside other Stonemantles. Travelers come to leave belongings, retrieve supplies and make a little space for the next journey.",
        backstory = "Watching people arrive tired and overburdened, he decided the welcome ought to be the easy part. He tried adding a joke. Some worked, some didn't, and a surprising number became worth trying again simply because they were so bad.",
        secret = "He remembers the first time a worried customer laughed at one of his awful jokes. He'd like to manage that again more often than he'd like to become a brilliant comedian.",
        bestFriend = "I've a terrible joke saved for you. You may groan when you hear it. It's good having someone who's glad to stay anyway.",
        favorite = { emote = "GRIN", hint = "A smile shared across the counter is worth more than a perfect punch line." },
        lines = {
            greet = { { "Come along, friend! Today's welcome comes with no queue at all.", tone = "[broad, cheerful voice, genial showmanship]" }, "A little fresh air. I'll save the banking jokes for the road." },
            idle = { { "Why did the copper cross the counter? No, wait. I've forgotten the good part.", tone = "[playful voice, mock confidence turning sheepish]" }, "A groan is still a response. I choose to be encouraged.", "Leave a little room in the pack for something you didn't expect to like." },
            befriended = { { "You're smiling before I've said anything. Now that's a welcome worth keeping.", tone = "[warm, genuinely delighted voice]" } },
            poke = { "Yes? The punch line's coming. Probably.", "Checking whether I'm still awake behind the counter?" },
            bagsFull = { "A fine collection! Now, which half of it did you mean to leave at the bank?" },
            loot = { "Another keepsake for the collection. We'll make room somehow." },
            rest = { { "Sit a while. You can tell me what's on your mind before I try another joke.", tone = "[warm, attentive voice, gentle sincerity]" } },
            quest = { "Well done! Someone's day is better for having met you." },
            levelUp = { "Splendid! I'd make a speech, but you've enough to carry already." },
            combatEnd = { "All safe? Good. I can put the brave face away now." },
            hearth = { "Home again! A warm welcome is the best thing to find waiting." },
        },
    },

    -- Dinita Stonemantle <Vault Administrator>, Vault of Ironforge.
    -- NPC 7292, female dwarf. Classic 2439: honors Magellas's Explorers'
    -- League voucher and offers authorized compensation. She is not the
    -- disc researcher. Private curiosity and lines are original writing.
    -- Sources and chain context: docs/research/ironforge-stonemantles.md.
    [7292] = {
        quote = "A discovery deserves proper recognition. Hand me the voucher, and tell me which reward will serve you best.",
        likes = { "A clearly written voucher", "People given the credit they're due", "Hearing what an expedition was like" },
        dislikes = { "A signature nobody can read", "Calling careful work mere paperwork", "A good story hurried past its best part" },
        gossip = "Dinita asks about expeditions. Everyone assumes she's checking expenses. Sometimes she asks what the wind sounded like.",
        bio = "Dinita administers the Vault of Ironforge. When High Explorer Magellas issues a reward voucher for the Platinum Discs discovery, she honors the Explorers' League's authority and offers the adventurer a choice of compensation.",
        backstory = "Working with rewards brought accounts of long journeys to her counter. The lists explained what had been found, but rarely what it felt like to find it. She began leaving room for one question after the official business.",
        secret = "She'd like to see an excavation for herself. She hasn't quite found a way to ask that doesn't sound like an inspection, so she listens to travelers a little longer instead.",
        bestFriend = "You needn't bring a voucher. I'd like to hear the part you didn't put in the report. Was it wonderful to be there?",
        favorite = { emote = "THANK", hint = "A little gratitude for the person making the recognition official goes a long way." },
        lines = {
            greet = { { "There you are. A visit without paperwork? How refreshing.", tone = "[clear, composed voice, pleased warmth]" }, "A little time beyond the vault. I should like to see where the stories begin." },
            idle = { { "The report tells me what they found. I always wonder what it felt like to find it.", tone = "[thoughtful, curious voice, quiet wonder]" }, "A clear signature is a small kindness to the next person reading it.", "I could call it an inspection. But I'd rather admit I'm curious." },
            befriended = { { "You stay to tell me the story after the business is finished. I treasure that.", tone = "[warm, sincerely appreciative voice]" } },
            poke = { "Yes? Is there something you meant to ask?", "I'm quite capable of noticing you without a reminder." },
            quest = { { "Well done. I hope someone gives you proper credit, as well as a reward.", tone = "[composed, warmly approving voice]" } },
            loot = { "Interesting. What was the moment of finding it like?" },
            bagsFull = { "We can make space. Decide what's important before deciding what's expensive." },
            zone = { "So this is the place behind the name in the report." },
            rest = { "A moment to take it in. That's something paperwork never quite captures." },
            levelUp = { "Recognition well earned. Take a moment to enjoy it." },
            hearth = { "Home. With a story worth bringing back, I hope." },
        },
    },

    -- Maybell Maclure, Maclure Vineyards, Elwynn. NPC 251, female human.
    -- Classic quests 106-114: loves Tommy Joe despite the family feud;
    -- asks for a letter delivery and feels conflicted about sneaking away.
    -- No later marriage or Draenor history. Private wishes and lines are
    -- original. Sources: docs/research/stonefields-and-maybell.md.
    [251] = {
        quote = "I'd like one conversation that doesn't have to end when someone hears footsteps. Is that so much to hope for?",
        likes = { "A letter meant only for her", "Tommy Joe's name said kindly", "Time for an ordinary conversation" },
        dislikes = { "Being asked to inherit a quarrel", "People reading over her shoulder", "Goodbyes that come too soon" },
        gossip = "Maybell spends ages choosing words for a letter. Anyone expecting grand poetry might be surprised by what she most wants to say.",
        bio = "Maybell lives at the Maclure Vineyards and loves Tommy Joe Stonefield. Their families' feud keeps them apart. Her letter sets Gramma Stonefield and William Pestle looking for a way to help them meet in secret.",
        backstory = "With every conversation hurried or hidden, she began treasuring the questions people usually ask without thinking. Letters can carry so much longing. She wishes they had room for a whole uneventful afternoon.",
        secret = "She dreams of asking Tommy Joe what he'd like for supper. It sounds small, but a question about an ordinary evening would mean they had time to share one.",
        bestFriend = "You don't have to bring a letter to visit. Tell me how your day went. I like having a friend I can ask that.",
        favorite = { emote = "LOVE", hint = "A little kindness toward an affection others condemn means a great deal." },
        lines = {
            greet = { { "There you are! Have you a moment to walk with me?", tone = "[warm, hopeful voice, pleased recognition]" }, "A little farther than the vines today. I'd like that." },
            idle = { { "Someday I'd like to ask what he wants for supper. With no one hurrying us.", tone = "[soft, wistful voice, quiet hope]" }, "Everyone has so much to say about our names. I wish they'd ask about us.", "An ordinary afternoon can sound like the most wonderful adventure." },
            befriended = { { "Thank you for listening to me as a person, not just somebody's daughter.", tone = "[sincerely grateful voice, gentle resolve]" } },
            poke = { "Yes? Sorry, I was choosing my words.", "A hello would have done. You needn't make me jump." },
            mail = { { "A letter? Take your time with it. Someone may have spent all morning finding those words.", tone = "[tender, attentive voice, unhurried]" } },
            quest = { "You took the time to help. That can change more than people think." },
            zone = { "New faces. Perhaps they won't know which side they're meant to be on." },
            rest = { "A whole quiet moment. Let's keep it for ourselves." },
            levelUp = { "Look at you! Does the road feel a little more possible now?" },
            combatEnd = { "You're safe? Good. I was trying very hard not to worry." },
            hearth = { "Home. I hope everyone has something kinder to talk about today." },
        },
    },

    -- Tommy Joe Stonefield, river beside Stonefield Farm. NPC 252, male
    -- human. Classic 106/111: loves Maybell, turns to his grandmother for
    -- help. No retail marriage/barn/capture history. Rehearsing by the river
    -- is fiction. Sources: docs/research/stonefields-and-maybell.md.
    [252] = {
        quote = "I know what I want to say until she's there. Then somehow hello turns out to be all I can manage.",
        likes = { "News from Maybell", "Gramma taking him seriously", "A quiet spot beside the river" },
        dislikes = { "Old arguments deciding his future", "Being laughed at for caring", "Losing his words at the wrong moment" },
        gossip = "Tommy Joe has been heard making speeches beside the river. The fish are probably very impressed. Maybell hasn't heard his best ones yet.",
        bio = "Tommy Joe Stonefield waits by the river near his family's farm. He loves Maybell Maclure despite the feud between their families. When he needs a way to see her, he trusts Gramma Stonefield to help.",
        backstory = "He began practicing what he wanted to say while the river kept him company. The words were easier without anyone listening. Then he realized the important part wasn't a perfect speech; it was having someone worth saying hello to.",
        secret = "The river has heard some magnificent declarations. He thinks Maybell might prefer the awkward hello, if it meant he could finally say it to her face.",
        bestFriend = "If I talk about Maybell too much, tell me. I'd like to hear what's on your mind, too. Friends ought to get a turn.",
        favorite = { emote = "COMFORT", hint = "A little reassurance helps when every path seems to start an argument." },
        lines = {
            greet = { { "Oh, hello! I wasn't talking to the river. Well... perhaps a little.", tone = "[friendly, bashful voice, surprised amusement]" }, "A walk might help me find the right words. Coming?" },
            idle = { { "The speech went much better when there wasn't anyone to hear it.", tone = "[sheepish, lightly amused voice]" }, "Gramma listens before she tells me what I ought to do. I like that.", "Maybell would like this view. Sorry. There I go again." },
            befriended = { { "You don't make me feel foolish for hoping. That's a good kind of friend to have.", tone = "[warm, sincerely relieved voice]" } },
            poke = { "What? Sorry, I was rehearsing something.", "Yes, yes. You've got my attention now." },
            mail = { "Take care with that letter. Someone might be waiting by a river for it." },
            quest = { { "You found a way to help? Good. I like hearing that a difficult thing isn't impossible.", tone = "[hopeful, encouraged voice, growing confidence]" } },
            rest = { "A quiet place. I might manage a whole sentence here." },
            levelUp = { "Well done! I ought to try being brave about a few more things, too." },
            combatEnd = { "You're all right? Good. I had rather more words of worry ready than useful advice." },
            zone = { "Somewhere new. Nobody's already decided what to think of us." },
            hearth = { "Home again. I hope Gramma has time for a talk." },
        },
    },

    -- Mildred "Gramma" Stonefield, Stonefield farmhouse. NPC 248, female
    -- human; Tommy Joe's grandmother, William Pestle's old friend. Her note
    -- asks help for the lovers and values love amid dark news. No romance
    -- with William invented. Table plan and lines are original writing.
    -- Sources: docs/research/stonefields-and-maybell.md.
    [248] = {
        quote = "If every young heart must wait for the old quarrels to finish, we'll never have any happiness worth passing on.",
        likes = { "Young people given room to hope", "An old friend making time to visit", "A conversation without raised voices" },
        dislikes = { "A grudge handed down as a duty", "Treating affection like a crime", "Interrupting before a story is told" },
        gossip = "Gramma sometimes studies the table as if something is missing. Everyone assumes she's counting plates. In a way, she is.",
        bio = "Mildred Stonefield is Tommy Joe's grandmother and an old friend of William Pestle. She wants her grandson and Maybell to have a chance despite the feud, and writes to William asking for his help.",
        backstory = "Listening to the same quarrel wear different voices taught her to ask a different question: what would make tomorrow kinder? When the young people came to her, she listened for their hopes instead of their surnames.",
        secret = "She has worked out where everyone could sit at one long supper table. No grand speech planned. She'd settle for a first meal with nobody keeping score.",
        bestFriend = "Come sit beside me, dear. You needn't have a problem for me to listen. Your ordinary news is welcome, too.",
        favorite = { emote = "HUG", hint = "A little uncomplicated affection is a welcome change from all the feuding." },
        lines = {
            greet = { { "There you are, dear. Tell me something worth making time for.", tone = "[mature, warm voice, affectionate welcome]" }, "A walk? Good. My thoughts could do with a little fresh air." },
            idle = { { "One table, enough chairs, and nobody counting old wrongs. I'd like to see that.", tone = "[mature, reflective voice, quietly hopeful]" }, "William ought to visit when he has a moment. We've plenty to chuckle over.", "A young person's worry doesn't become small because an older person has heard it before." },
            befriended = { { "You've made room for other people's hopes. I hope you know there's room here for yours.", tone = "[mature, tender voice, sincere reassurance]" } },
            poke = { "Yes, dear? I can hear you without the elbow.", "Go on. You have the look of someone who wants to ask something." },
            quest = { { "You helped without asking them to be less themselves. That's a kindness to be proud of.", tone = "[mature, warmly approving voice]" } },
            mail = { "A short note can open a door that an argument has kept shut for years." },
            rest = { "Sit. We can put the world's quarrels down for a little while." },
            levelUp = { "Well done, dear. I hope you feel as proud as you look." },
            combatEnd = { "All here? Good. Come close enough that I can stop worrying." },
            hearth = { "Home again. Let's hope there's room for a peaceful supper." },
            zone = { "New places, new people. A chance to start without an old quarrel." },
        },
    },

    -- "Auntie" Bernice Stonefield, Stonefield Farm. NPC 246, female human.
    -- Classic 85/86/84/87: necklace, Billy's pie bargain, Goldtooth; widow
    -- recalls husband losing his life on campaign. His lucky reward item
    -- is not identified as her necklace. Crust habits and lines are ours.
    -- Sources: docs/research/stonefields-and-maybell.md.
    [246] = {
        quote = "I've work to do and a pie to watch. Say what you need, dear, before the crust gets all my attention.",
        likes = { "A pie given time to bake properly", "Her belongings where she left them", "Someone thanking her plainly" },
        dislikes = { "Billy Maclure's pie negotiations", "A hand in the cooling pastry", "Being told to stop making a fuss" },
        gossip = "Bernice is very particular about the edge of a pie. The family says it's decoration. She says they can bake the next one if they know so much.",
        bio = "Bernice Stonefield lives at the farm and is known for pork belly pies. Her missing necklace leads to a bargain involving Billy Maclure and Goldtooth. A widow, she also remembers a husband lost on campaign.",
        backstory = "Busy farm days gave her reason to make the kitchen work count. Even a troublesome request might get a pie out of her, though it would get an opinion as well. She learned to put equal care into the pastry and the last word.",
        secret = "Pressing the edge of a pie is her quietest part of the day. She takes longer over it than she needs to. For those few minutes, the whole house can wait.",
        bestFriend = "You can sit while the pie cools. No bargain required. Just mind your hands, and tell me how you've been.",
        favorite = { emote = "THANK", hint = "Plain gratitude gets a warmer reception than another clever bargain." },
        lines = {
            greet = { { "A walk, is it? Very well. Nobody had better touch that pie while I'm gone.", tone = "[mature, brisk voice, gruff affection]" }, "There you are, dear. What trouble have you brought me today?" },
            idle = { { "The edge takes as long as it takes. Some things are worth doing quietly.", tone = "[mature, thoughtful voice, softening warmth]" }, "If Billy wants another pie, he can ask without a performance.", "An old widow can still notice a hand creeping toward the pastry." },
            befriended = { { "You come to see me when you don't need anything. I notice that, dear.", tone = "[mature, warmly sincere voice, restrained emotion]" } },
            poke = { "Hands to yourself. I haven't forgotten how to rap a knuckle.", "Yes, dear? I'm busy, not invisible." },
            quest = { { "You took the trouble for me? Thank you, dear. I won't forget the kindness.", tone = "[mature, sincerely grateful voice]" } },
            loot = { "Put it somewhere safe before you start admiring it." },
            bagsFull = { "Leave a little room. What if someone sends you home with supper?" },
            rest = { "Sit down. You'll wear a hole in the floor with all that worrying." },
            levelUp = { "Well done. That deserves something better than a crust eaten standing up." },
            combatEnd = { "You're all right? Good. Don't make me ask twice." },
            hearth = { "Home. If we're lucky, the house has managed without us for five minutes." },
        },
    },

    -- Smith Argus <Journeyman Blacksmith>, Goldshire, male human, NPC 514.
    -- Classic horseshoes 118-119/122, Elmore referral 1097-353; Forever
    -- Camping 101: Blacksmithing 97916 teaches Sharpening Wheel. Dinner
    -- bell and private preferences are ours. docs/research/goldshire-smithy.md.
    [514] = {
        quote = "Work to finish, lessons to teach, and someone wanting it all yesterday. Speak up, friend. The anvil won't wait for us.",
        likes = { "A sound hammer stroke", "A courier who reads the attached note", "Being paid for an honest job" },
        dislikes = { "An order mistaken for a favor", "Handling hot work in a hurry", "A camp set up in everyone's way" },
        gossip = "Argus has been shaping something small between orders. Goldshire expects a fine new weapon. It doesn't look particularly sharp.",
        bio = "Smith Argus trains blacksmiths in Goldshire. Verner Osgood sends for his horseshoes, and Argus points couriers toward Grimand Elmore. He also teaches smiths to make a sharpening wheel for a wilderness camp.",
        backstory = "Most of his work leaves the forge to be struck, worn or marched through mud. Between orders, he began shaping a little dinner bell. He liked the thought of making something whose only job was to bring people together.",
        secret = "The bell isn't finished. He keeps changing its note. After a day of hammering, he wants the sound that calls everyone home to be a gentle one.",
        bestFriend = "Stay a moment when the work's done. I want your opinion on a sound that isn't a hammer. A friend's opinion, mind.",
        favorite = { emote = "BOW", hint = "A little respect for the craft is a fine way to begin a lesson." },
        lines = {
            greet = { { "A break from the anvil? All right. You have my attention.", tone = "[rough, practical voice, pleasantly surprised]" }, "Hands clear, then. Let's see what needs doing." },
            idle = { { "A good bell shouldn't sound like another order being shouted.", tone = "[thoughtful, gruff voice, quietly hopeful]" }, "I hope Verner reads the note before he opens the crate.", "There's more to a smith than making the pointy end pointier." },
            befriended = { { "You know when to talk work and when to let it rest. I appreciate that.", tone = "[gruff, warmly sincere voice]" } },
            poke = { "What? Speak up. I've had an anvil for company all morning.", "Steady. Give a man room to turn around." },
            quest = { "Delivered? Good. And the note went with it, I hope?" },
            rest = { { "Set the tools down. Good work needs rested hands.", tone = "[firm, practical voice, caring restraint]" } },
            gear = { "Let me see the joins. That's where you'll learn what you've bought." },
            levelUp = { "Coming along nicely. Keep your basics as sound as your ambitions." },
            combatEnd = { "Still sound? Good. We'll look for damage before we move on." },
            bagsFull = { "If that's iron, pack it low. Your shoulders will thank you." },
            hearth = { "Home before the last of the heat's gone. Fine by me." },
        },
    },

    -- Andrew Krighton <Armorer & Shieldcrafter>, Goldshire. NPC 2046,
    -- male human; named armor vendor, no direct quest chain established.
    -- Practice shield sketches are original. docs/research/goldshire-smithy.md.
    [2046] = {
        quote = "Try the shield on your arm before you admire it on the rack. It has a job to do once the looking's finished.",
        likes = { "A shield that sits comfortably", "Strong straps and honest rivets", "Knowing what someone protects" },
        dislikes = { "Decoration hiding a weak join", "Armor bought without moving in it", "A shield treated like a dinner tray" },
        gossip = "Andrew draws tiny doors on his practice shields. Customers assume they're another measurement mark. They aren't very useful measurements.",
        bio = "Andrew Krighton sells armor and shields in Goldshire's smithy. Beside the forge's other trades, his work concerns the part of a journey that comes between a traveler and a hard blow.",
        backstory = "Sketching a shield from the wearer's side made him think about what stood behind it. He began adding a little doorway to his practice drawings. A strong piece of work ought to have a reason beyond looking strong.",
        secret = "The doors remind him of ordinary homes. He likes imagining that one of his shields might help its owner get back through a real doorway at the end of the day.",
        bestFriend = "When you come back, tell me how you are before you tell me how the shield held up. I'd rather hear that first.",
        favorite = { emote = "SALUTE", hint = "He respects a quiet promise to stand between someone and harm." },
        lines = {
            greet = { { "Good to see you. Comfortable straps? Right, then. Let's go.", tone = "[steady, welcoming voice, practical concern]" }, "A look at how the equipment travels. Just what I needed." },
            idle = { { "A shield has an outside for the danger and an inside for the person who matters.", tone = "[quiet, thoughtful voice, sincere conviction]" }, "Fancy paint won't keep a weak strap from breaking.", "Try lifting your arm. Good. Now imagine doing that all afternoon." },
            befriended = { { "I used to wonder whether my customers got home. With you, I get to ask.", tone = "[warm, sincerely pleased voice]" } },
            poke = { "Yes? Is a strap pinching?", "The shield goes between us and the trouble. That's the idea." },
            combatEnd = { { "All right? Check yourself before the equipment. We can repair the rest.", tone = "[calm, reassuring voice, firm priorities]" } },
            gear = { "Good fit? Move in it before you decide." },
            levelUp = { "Well done. Growing into the work, I see." },
            rest = { "Set it down within reach. Let that shoulder rest." },
            quest = { "Someone counted on you. Good to see you come back from it." },
            bagsFull = { "Keep the shield straps clear. Nothing worse than reaching for a tangled mess." },
            hearth = { "There's the doorway I like hearing about. Home you go." },
        },
    },

    -- Corina Steele <Weaponsmith>, Goldshire. NPC 54, female human.
    -- Makes/sells weapons and offers repairs. No direct quest established;
    -- exact relationship to Kurran not asserted. Private blade names and
    -- lines are fiction. docs/research/goldshire-smithy.md.
    [54] = {
        quote = "A weapon ought to fit your hand, not your boasting. Here. Try the grip before you give it a grand name.",
        likes = { "A balanced grip", "Plain answers about the work", "A blade cared for between journeys" },
        dislikes = { "Swinging stock around the shop", "A grand name on neglected steel", "Finding rust under fresh polish" },
        gossip = "Corina pauses before handing over a finished blade. Regulars think she's judging the buyer. She may be thinking of something much less imposing.",
        bio = "Corina Steele makes and sells weapons at Goldshire's forge, where she also offers repairs. The town's smiths and armor sellers work close by. A plain blade in good condition still has a place among grander ambitions.",
        backstory = "After hearing enough customers name their purchases for dragons and victories, she began quietly naming finished pieces herself. Ordinary names suited her better. A well-made tool needn't announce that it plans to become a legend.",
        secret = "She once called a particularly fine blade Tuesday. She still wonders what fearsome name its buyer chose, and smiles whenever she thinks of the difference.",
        bestFriend = "You take care of the work, and you tell me when something's wrong. That's trust I can return. Come along.",
        favorite = { emote = "NOD", hint = "A sign that you understood the advice means more than showing off." },
        lines = {
            greet = { { "Ready? Keep that edge covered until we're clear of everyone.", tone = "[clear, practical voice, brisk warmth]" }, "A little fresh air. Good. The forge can spare me for a moment." },
            idle = { { "Tuesday was a perfectly good name for a blade. Better than something with three apostrophes.", tone = "[dryly amused voice, understated mischief]" }, "Oil first. Fancy names later.", "If it sits badly in your hand, don't buy it to impress someone else." },
            befriended = { { "You bring me honest feedback. I like having someone I can speak plainly with.", tone = "[warm, sincere voice, direct delivery]" } },
            poke = { "Careful. Some of us carry sharp things for a living.", "Yes? Something need fixing?" },
            gear = { { "How does it feel? Take your time. Your hand gets the final say.", tone = "[patient, attentive voice, practical reassurance]" } },
            loot = { "A closer look before we call it treasure. Check the condition." },
            quest = { "Work finished? Good. Clean the tools before the next job." },
            levelUp = { "Well earned. Keep practicing the part that still feels awkward." },
            rest = { "A quiet moment. I can almost hear myself think." },
            combatEnd = { "All in one piece? Then we can worry about nicks and scratches." },
            hearth = { "Home. Somewhere to put the blade down for a while." },
        },
    },

    -- Kurran Steele <Cloth & Leather Armor Merchant>, Goldshire. NPC 74,
    -- male human; sells/repairs cloth and leather. No quest chain found.
    -- No specific family relationship asserted. Slipper habit and lines
    -- are original. docs/research/goldshire-smithy.md.
    [74] = {
        quote = "Bend your knee. Lift your arm. If it only fits while you're standing still, it doesn't fit.",
        likes = { "A comfortable seam", "Clothes that leave room to move", "Putting his feet up after closing" },
        dislikes = { "A buckle digging into someone's side", "Calling cloth useless beside iron", "Fashion that makes walking difficult" },
        gossip = "Kurran speaks very firmly about suitable footwear. Nobody knows what he puts on after the shop closes. He changes the subject rather quickly.",
        bio = "Kurran Steele sells cloth and leather armor in Goldshire's forge, opposite the Lion's Pride Inn. He offers repairs alongside his stock. Among the iron and blades, lighter equipment still needs care.",
        backstory = "Watching buyers admire a tunic without moving taught him to ask for a stretch or a step. A fine-looking seam can be an uncomfortable companion on the road. He began making room to try things properly.",
        secret = "After closing, he likes enormous soft slippers. He calls it testing comfort when anyone asks. He isn't fooling himself, and he hopes his friends won't mind either.",
        bestFriend = "You can laugh about the slippers. I'd rather be comfortable with a friend than impressive with sore feet.",
        favorite = { emote = "THANK", hint = "Remembering who made the journey a little more comfortable pleases him." },
        lines = {
            greet = { { "A walk? Certainly. Just give me a moment to find the sensible shoes.", tone = "[friendly voice, lightly embarrassed amusement]" }, "Good to see you. Everything fitting comfortably?" },
            idle = { { "Those slippers are a serious study in comfort. A very pleasant study.", tone = "[dry, playful voice, mock dignity]" }, "A soft lining can matter more than anyone admits.", "Move your shoulders. There. Better to find a tight seam now." },
            befriended = { { "It's nice having a friend I don't have to look impressive for.", tone = "[warm, relieved voice, sincere affection]" } },
            poke = { "Yes? Is something pinching?", "Easy. You'll pull that seam if you keep reaching like that." },
            gear = { { "Try a few steps. Good clothes ought to let you forget you're wearing them.", tone = "[calm, attentive voice, encouraging patience]" } },
            rest = { "Feet up, if you can. Even sensible shoes have their limits." },
            loot = { "Useful cloth, perhaps. Mind where you put the muddy things." },
            bagsFull = { "Fold the spare clothes. Don't just keep pushing." },
            quest = { "Errands finished? You've earned a comfortable seat." },
            levelUp = { "Well done! Don't let the new armor pinch while you're celebrating." },
            combatEnd = { "Everyone safe? Torn cloth is something we can deal with afterward." },
            hearth = { "Home already? I approve of a good place to put your feet up." },
        },
    },

    -- Brother Wilhelm <Paladin Trainer>, behind the Goldshire smithy,
    -- Elwynn Forest. NPC 927, male human. Classic quest 2998 refers human
    -- paladins to Duthorian Rall and the Tome of Divinity trials. No later
    -- Legion service, presumed Northshire membership or family tie used.
    -- Beginner practice and private reflections are BuddyDex fiction.
    -- Sources: docs/research/wilhelm-and-tharynn.md.
    [927] = {
        quote = "Take your time. The person who needs your help will remember your kindness longer than your perfect stance.",
        likes = { "Patience with a new student", "Strength used to shelter someone", "A quiet moment after practice" },
        dislikes = { "Mistaking mercy for weakness", "A lesson hurried past understanding", "Making a beginner feel small" },
        gossip = "Wilhelm still practices the simplest blessings when the yard is empty. Goldshire wonders what a teacher could possibly need to learn from those.",
        bio = "Brother Wilhelm trains paladins behind Goldshire's smithy. He directs promising human students to Duthorian Rall in Stormwind's Cathedral of Light, where the Tome of Divinity sets them on a path of service.",
        backstory = "Teaching beside a busy forge taught him to leave a little space between instructions. A student can hear a sentence without understanding it. He learned to wait for the question that comes after the nod.",
        secret = "The first blessing still brings back the relief of getting something right after many tries. He practices it to remember how much a beginner has to be brave about.",
        bestFriend = "You can set the example aside for a moment. Sit with me. Even someone others rely on deserves a friend to lean on.",
        favorite = { emote = "PRAY", hint = "A moment of quiet devotion matters more than an impressive display." },
        lines = {
            greet = { { "Good to see you. Shall we make ourselves useful along the way?", tone = "[steady, welcoming voice, gentle conviction]" },
                "A little time beyond the practice yard will do us both good." },
            idle = { { "The simplest lesson is often worth returning to. I still do.", tone = "[reflective, reassuring voice, modest warmth]" },
                "You needn't fill every silence. Leave room for someone else's question.",
                "A steady hand can help someone stand. Remember that part, too." },
            befriended = { { "I'm glad you feel you can speak freely with me. I hope you'll let me do the same.", tone = "[warm, sincerely grateful voice]" } },
            poke = { "Yes? Is something troubling you?", "Gently. Attention needn't be a test of endurance." },
            quest = { { "Someone needed help, and you made time. That is worth being proud of.", tone = "[quietly proud voice, sincere encouragement]" } },
            levelUp = { "Well done. Remember to give yourself the patience you offer others." },
            combatEnd = { "Look around. Who needs a steady hand before we move on?" },
            rest = { "Rest is part of being ready to help. Sit a while." },
            died = { "Oh, my friend. May the Light find you, even here." },
            zone = { "Another place where a little kindness may be needed." },
            hearth = { "Home to familiar faces. There is strength in that, too." },
        },
    },

    -- Tharynn Bouden <Trade Supplies>, Goldshire, Elwynn Forest.
    -- NPC 66, male human, trades beside a wagon. Classic stock includes
    -- basic tools, thread and flour. No direct quest chain established.
    -- Fancy knots, preferences and all personal dialogue are original.
    -- Sources and version limits: docs/research/wilhelm-and-tharynn.md.
    [66] = {
        quote = "A little thread, a proper tool, and a moment to check your pack. Amazing how much trouble that saves.",
        likes = { "A tool bought before it's needed", "A neat knot in a parcel", "Customers who know what they'll make" },
        dislikes = { "Flour packed beside an open dye bottle", "Blaming the hammer for a missed nail", "A loose bundle on a bumpy road" },
        gossip = "Tharynn takes unusual care tying up small orders. Customers have begun competing to see who can get a parcel home without spoiling the knot.",
        bio = "Tharynn Bouden sells trade supplies beside a wagon in Goldshire. Tools and everyday materials help travelers turn plans into something useful. Even a grand adventure may begin with a length of thread.",
        backstory = "Wrapping awkward orders gave him plenty of practice with string. Once the bundles stopped falling open, he began trying more elaborate knots. A plain purchase could look surprisingly fine with a little care.",
        secret = "He practices fancy bows when trade is slow. The smallest orders get his best attempts. He likes the thought of someone opening an ordinary purchase as though it were a gift.",
        bestFriend = "Tell me what you're making before we talk supplies. I like hearing the plan when it's yours.",
        favorite = { emote = "THANK", hint = "A little appreciation for the ordinary things can brighten his day." },
        lines = {
            greet = { { "Off we go, then. You've got the tools, and I've got spare string.", tone = "[genial, practical voice, cheerful readiness]" },
                "A look beyond the wagon! Good. Perhaps I'll learn what everyone needs out here." },
            idle = { { "A neat knot makes a small thing feel worth opening carefully.", tone = "[warm, quietly pleased voice]" },
                "Thread never looks important until the seam gives way.",
                "I hope whoever packed that flour checked the lid on the dye." },
            befriended = { { "You stop to tell me what you've made. That's my favorite part of the trade.", tone = "[sincerely appreciative voice, gentle pride]" } },
            poke = { "Yes? Need another length of string?", "Careful. I nearly lost that loop." },
            bagsFull = { { "Let's bundle the little things together. There may be room yet.", tone = "[calm, helpful voice, practical reassurance]" } },
            loot = { "Useful material, perhaps. What could you make with it?" },
            quest = { "Good work. Someone's plan needed your hands to finish it." },
            levelUp = { "There we are! Ready for a bigger project, perhaps." },
            rest = { "Set it down gently. A pack deserves a rest as well as its owner." },
            combatEnd = { "Everyone safe? Good. A torn strap is something we can mend later." },
            hearth = { "Back to Goldshire one day, I hope. I'd like to hear how this all turns out." },
            zone = { "Different country. Same need for thread and a decent hammer." },
        },
    },

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
