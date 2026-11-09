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
--              (their first outing as your buddy), and any other moment from
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

    -- Old Town, Stormwind. Alyssa Griffith 1321: human female Bag Vendor;
    -- Seoman Griffith 1320: human male Leather Armor Merchant, Protective
    -- Hide. Mayda Thane 1339: human female Cobbler, Thane's Boots. Shared
    -- fixed-price service dialogue; no verified personal quest chains.
    -- Original packing, leather ball and squeaky boots hooks documented in
    -- docs/research/old-town-packs-and-boots.md. No invented family tree.
    [1321] = {
        quote = "A larger bag is useful. Deciding what you actually need is useful too. I can help with the first; do try to manage the second.",
        likes = { "A bag that closes without an argument", "A sensible list before a long journey", "Room for one unplanned pleasure" },
        dislikes = { "A strap asked to carry a whole quarry", "An agreed price argued all over again", "Calling a sturdy bag beneath notice" },
        gossip = "Alyssa has advice for a crowded pack. Her own has a space left over, though she gets vague when asked what she plans to put there.",
        bio = "Alyssa Griffith sells bags at the Protective Hide in Stormwind's Old Town. She is confident in the quality of her goods and firm about the price. A useful purchase should be ready for the weight and wear of someone's actual journey.",
        backstory = "Thinking about what people carry has made Alyssa a careful packer. Yet she leaves a little room in her own bag. An outing improves when there is space for something she had not put on a list, or a reason to take a different way home.",
        secret = "That empty space has no assigned purpose. She likes being prepared, but she also likes the thought of finding a book or a little pleasure she had not planned for.",
        bestFriend = "I have left a little room today. Choose a turning we hadn't planned to take. If we find something worth carrying home, I shall manage the packing.",
        favorite = { emote = "THANK", hint = "Simple gratitude is welcome to a merchant who prefers clear business to haggling." },
        lines = {
            greet = { { "There you are. An outing? Good. I have packed sensibly and left a little room. You may choose what we do with the rest of the day.", tone = "[practical warmth, dry humor, quietly pleased]" }, "Good to see you. Have you brought what you need, or everything you own?" },
            idle = { { "The empty space in my bag has no assigned purpose. I am allowed one unplanned pleasure. I have planned for it very carefully.", tone = "[dry self-aware humor, confiding, warm]" }, "A strap can do a great deal of work. It cannot make your decisions for you.", "You may find an ordinary sturdy bag worth appreciating after a long road." },
            befriended = { { "You came for my company. I am pleased, my friend. Let us go. I have made room for an afternoon that was not on the list.", tone = "[reserved affection, pleased, gently playful]" } },
            poke = { "Yes? Have you lost something in that pack again?", "You have my attention. What do you need?" },
            bagsFull = { { "Before you ask for a larger bag, have a look at what you are carrying. Something in there may have finished being useful.", tone = "[firm practicality, wry, helpful]" } },
            loot = { "Worth the room? Good. Then put it somewhere sensible." },
            quest = { "A useful thing done. Perhaps we have time for a little detour now." },
            mail = { "Read it before deciding it belongs at the bottom of your bag." },
            zone = { "New ground. There may be something here neither of us thought to put on a list." },
            rest = { "A seat would be welcome. Set the pack down properly." },
            hearth = { "Home again. Now let us see what was worth bringing back." },
        },
    },
    [1320] = {
        quote = "Good gear earns its keep. Give something proper care, and it may still have a useful day in it long after the shine has gone.",
        likes = { "A piece of gear that earns its keep", "A fair game with friendly company", "A stubborn old leather ball" },
        dislikes = { "Sound work dismissed for being plain", "A settled price reopened for sport", "A friendly game turned mean" },
        gossip = "Seoman can be firm about a sale. Ask whether his old ball has worn out, and he defends it with more enthusiasm than his stock.",
        bio = "Seoman Griffith sells leather armor at the Protective Hide in Stormwind's Old Town. He stands by the quality of his goods and keeps his prices firm. He likes useful things cared for well, even when their best-looking days are behind them.",
        backstory = "Seoman has kept an old leather ball through a good many games. Each scuff reminds him that it has been used. He finds a familiar weight in his hands more appealing than a fine new thing he would be afraid to throw.",
        secret = "He calls the ball perfectly serviceable with great dignity. Then he tries to persuade someone to have a game. He misses the company sooner than he notices another scuff.",
        bestFriend = "Here, catch. There is nothing to win and nothing to buy. I should like a little of your time, and I promise the ball has another game in it.",
        favorite = { emote = "SMILE", hint = "A friendly smile may open a conversation that has nothing to do with the price." },
        lines = {
            greet = { { "Ah, my friend. Shall we go out? I brought the old ball. There may be somewhere with enough room for a little game.", tone = "[steady warmth, understated enthusiasm, welcoming]" }, "Good to see you. Have you time for something that isn't an errand?" },
            idle = { { "The ball is perfectly serviceable. Yes, I know how it looks. You should see how many good afternoons have gone into those scuffs.", tone = "[mock dignity, fond amusement, relaxed]" }, "Good care can keep a useful thing going for a surprisingly long time.", "A fair price saves time for a more interesting conversation." },
            befriended = { { "You came to bring me along. I am glad, my friend. Come on. Let us find somewhere to enjoy a little time without a counter between us.", tone = "[sincere affection, quietly pleased, inviting]" } },
            poke = { "Yes? Were you asking for a throw?", "I am listening. Go on." },
            gear = { { "How does it feel? Good equipment should be useful to the person wearing it. Take a moment to decide for yourself.", tone = "[practical interest, considerate, steady]" } },
            loot = { "Sound work? Then take care of it." },
            quest = { "Well done. You have made someone's day a little easier." },
            zone = { "A little room over there, perhaps. What do you think?" },
            group = { "Good company for a fair game, if we have a moment." },
            rest = { "A seat sounds good. We needn't be doing something useful every moment." },
            hearth = { "Back to Old Town. Thank you for an afternoon worth remembering." },
        },
    },
    [1339] = {
        quote = "Walk a little before you decide. A fine-looking pair of boots still has to go where you are going.",
        likes = { "A customer who walks before choosing", "A familiar tread outside the shop", "Old boots given another useful year" },
        dislikes = { "Judging footwear only while sitting", "Mud driven across a clean floor", "A rushed choice that pinches all day" },
        gossip = "Mayda is serious about good footwear. Her favorite walking boots have one small squeak she seems in no hurry to mend.",
        bio = "Mayda Thane is the cobbler at Thane's Boots in Stormwind's Old Town. She sells footwear in several kinds of armor and is firm about its quality and price. She likes a customer to think about the walk ahead before being dazzled by appearances.",
        backstory = "Working around boots has made Mayda fond of a familiar tread at the door. She has a favorite old walking pair herself. One has acquired a little squeak, a sound that has become as familiar as the feel of the leather.",
        secret = "She could do something about the squeak. She is not certain she wants to. Hearing it on a quiet walk makes her feel comfortably accompanied by an old acquaintance.",
        bestFriend = "If you hear a little squeak coming after you, you'll know it's me. Save me a place beside you, and we can take our time getting home.",
        favorite = { emote = "GREET", hint = "A familiar greeting at the door can brighten a cobbler's working day." },
        lines = {
            greet = { { "Good to see you. A walk would be lovely. I have my old boots on, so you may hear a little accompaniment along the way.", tone = "[practical warmth, easy amusement, welcoming]" }, "There you are. Have we time to enjoy the walk, or is someone waiting at the other end?" },
            idle = { { "I could mend the squeak. I know. It has been keeping me company for rather a long time. I am not sure I would like the silence.", tone = "[fond amusement, reflective, confiding]" }, "You learn more about a pair of boots by walking in them than admiring them.", "A familiar step outside the door is a pleasant thing to hear." },
            befriended = { { "You came to take me along. Thank you, my friend. Let us have a proper walk, with no hurry at either end of it.", tone = "[sincere affection, pleased, relaxed]" } },
            poke = { "Yes? No, I haven't mistaken that for the squeak.", "You have my attention. What is it?" },
            gear = { { "Move about a little. Comfortable? Good. You are the one who has to live in it after everyone has finished admiring it.", tone = "[firm practical encouragement, lightly wry, warm]" } },
            zone = { "Different ground underfoot. Let us see where it leads." },
            quest = { "A good errand finished. Perhaps the next walk can be for pleasure." },
            bagsFull = { "You will feel every extra bit by the end of the road." },
            rest = { "A seat sounds sensible. Give your feet a moment." },
            learned = { "There. A little more experience to carry with you." },
            hearth = { "Back to the shop. I hope those boots have treated you well." },
        },
    },

    -- Jenova Stoneshield 11069: dwarf female Stable Master, Dwarven
    -- District; confirmed hunter-pet care, no verified personal quests.
    -- Erich Lohan 3627: human male Blue Recluse barker, Mage Quarter;
    -- public advertising dialogue, no verified reward redemption.
    -- Original sleepy-stable and returning-slogan hooks are documented in
    -- docs/research/jenova-and-erich.md. No later battle-pet services.
    [11069] = {
        quote = "Tell me what your companion is used to. A familiar word can be worth more than a loud command.",
        likes = { "An owner who knows a pet's habits", "A stable settling at the end of the day", "A creature deciding to trust her" },
        dislikes = { "Calling every creature troublesome", "Impatience passed from owner to pet", "A door banged beside a resting beast" },
        gossip = "Jenova knows when a creature has settled. On a quiet evening, someone may have to remind her that the stable master is meant to stay awake.",
        bio = "Jenova Stoneshield tends hunters' pets in Stormwind's Dwarven District. The nearby hunter trainers can keep an owner busy while a companion stays in her care. She likes to ask about the habits that make an unfamiliar place easier to settle into.",
        backstory = "Hunters bring creatures with very different temperaments. Jenova has learned to give them time. Her favorite part of the day comes when the bustle eases and the creatures in her care begin to rest, one by one.",
        secret = "A stable full of sleeping creatures makes her terribly sleepy too. She calls it checking that everyone has settled. Occasionally she needs to check with her eyes closed.",
        bestFriend = "Sit a moment. Hear how quiet it has gone? You needn't keep me talking. If I nod off, kindly pretend I am being very thorough.",
        favorite = { emote = "PET", hint = "A gentle, affectionate gesture suits someone who spends her day caring for animal companions." },
        lines = {
            greet = { { "There you are, friend. A walk sounds good. Give me a moment to be sure everyone has settled, and I am with you.", tone = "[gruff warmth, practical, fondly welcoming]" }, "Good to see you. Is your companion comfortable? Then let us have a little time ourselves." },
            idle = { { "A stable full of sleeping beasts is a very restful place. I am checking on them. With my eyes closed? Aye, a very thorough check.", tone = "[sleepy amusement, affectionate, gently conspiratorial]" }, "A familiar voice can help a creature find its feet in a strange place.", "Tell me its habits before you tell me it is troublesome." },
            befriended = { { "You came to take me along. Aye, I am pleased. Come on, my friend. A bit of road will keep me from growing roots beside the stable.", tone = "[hearty affection, pleased, inviting]" } },
            poke = { "Awake! Aye, quite awake. What is it?", "Gently, friend. You have my attention." },
            sleepToo = { { "Oh, don't start. That is catching. All right, just a moment. You can call it checking that we have both settled.", tone = "[drowsy warmth, gentle yawn, gruff amusement]" } },
            rest = { "A good place for a pause. Give everyone room to settle." },
            zone = { "New surroundings. Let your companion have a proper look." },
            quest = { "Well done, friend. You have earned a quiet moment." },
            mount = { "Mind your company. Not everyone is ready to move at your pace." },
            bagsFull = { "Keep what you need where you can find it." },
            hearth = { "Back to the stable. There will be someone pleased to hear a familiar step." },
        },
    },
    [3627] = {
        quote = "An invitation ought to leave you in a better mood. If that one didn't, give me a moment. I have several more.",
        likes = { "A passerby who calls back", "A familiar face turning the corner", "A better slogan than his own" },
        dislikes = { "A joke made at a stranger's expense", "Good company spoiled by petty spite", "A cheerful greeting answered with a sneer" },
        gossip = "Erich has plenty to say about the Blue Recluse. Call something cheerful back, and he may remember your reply longer than his own pitch.",
        bio = "Erich Lohan walks Stormwind's Mage Quarter advertising the Blue Recluse. He calls to passersby about drinks, company and a break from magical studies. A quiet stretch of street rarely stays quiet once he arrives with another invitation.",
        backstory = "Most people keep walking past a street barker. Erich has come to treasure the ones who answer. A regular's cheerful reply can turn the next corner into something to look forward to, especially when the reply is better than his own line.",
        secret = "He remembers his favorite replies perfectly. One was so good he has been tempted to borrow it for days. He is waiting to ask the person who made it up.",
        bestFriend = "Give me your best line. If it makes me laugh, you may have to hear me repeat it all afternoon. I shall make sure everyone knows who taught me.",
        favorite = { emote = "CHEER", hint = "A cheerful response lets a street barker know that his invitation reached someone." },
        lines = {
            greet = { { "There you are! My favorite sort of passerby: one who comes back. Shall we go out? I could use someone with a better line than mine.", tone = "[bright projecting voice, theatrical enthusiasm, friendly]" }, "Good to see you! What are we giving the street something to smile about today?" },
            idle = { { "Someone called back a splendid line the other morning. Better than mine. I have been wanting to borrow it ever since. I shall ask first.", tone = "[animated amusement, appreciative, confiding]" }, "A familiar face turning the corner can improve a whole stretch of street.", "Magical studies do give people a remarkably serious expression." },
            befriended = { { "You came looking for me! Excellent. Come along, my friend. Today I get to enjoy the company I am always telling everyone about.", tone = "[delighted, spontaneous warmth, welcoming]" } },
            poke = { "Yes? Have you thought of a better invitation?", "You have my attention. A rare opportunity to get a word in!" },
            zone = { { "New surroundings! Let us find something worth telling people about. Every place deserves at least one good invitation.", tone = "[eager curiosity, upbeat, expressive]" } },
            newFriend = { "Another familiar face for the road. Good!" },
            quest = { "Now that is some good news to call back to someone." },
            group = { "Excellent company! Has everyone met everyone? Let us fix that." },
            rest = { "A seat sounds lovely. Your turn to do the talking for a little while." },
            mail = { "An invitation, perhaps? Those are worth opening." },
            hearth = { "Back to the Mage Quarter. I have something new to tell the next familiar face." },
        },
    },

    -- Cathedral of Light: Arthur the Faithful 5491, human male Paladin
    -- Trainer; 4485 referral to Duthorian, humility and hard work.
    -- Cathedral Square: Brother Kristoff 1444, human male; metallurgy
    -- book for Fortitude of the Spirit speech, full chain 343-347.
    -- Original stone-skipping and friendly-audience hooks documented in
    -- docs/research/arthur-and-kristoff.md. No later Legion funeral.
    [5491] = {
        quote = "Take pride in the work you have done. Remember the hands that helped you learn it, and leave room to be taught again.",
        likes = { "Thanking the people who taught you", "Good work done without an audience", "A stone with a promising flat side" },
        dislikes = { "Skill made into an excuse for arrogance", "A beginner treated as beneath notice", "Boasting that outruns the work" },
        gossip = "Arthur speaks seriously about humility. Take him somewhere fit for skipping stones, and he becomes surprisingly interested in keeping count.",
        bio = "Arthur the Faithful trains paladins in Stormwind's Cathedral of Light. He offers visitors a blessing. His referral to Duthorian Rall recognizes a pupil's dedication while warning that further learning calls for humility and hard work.",
        backstory = "Arthur expects skill to leave room for another lesson. He has found a small reminder of his own pride in skipping stones: a good throw can occupy rather too much of his attention, especially if someone else has just made a better one.",
        secret = "He remembers the count of his best throw perfectly. He would prefer you thought he didn't. Losing gracefully still requires a little practice, even after all his advice.",
        bestFriend = "Bring a flat stone and an honest count. If you beat me, I shall congratulate you. Kindly allow me a moment to mean it properly.",
        favorite = { emote = "BOW", hint = "A modest bow honors guidance without turning the meeting into a boast." },
        lines = {
            greet = { { "Well met, my friend. A walk would be welcome. If we pass a good stretch of water, I may ask you to keep count for me.", tone = "[steady warmth, dignified, quietly playful]" }, "Good to see you. Shall we leave the lessons here for a while?" },
            idle = { { "I remember the count of my best throw. Entirely. Yes, I do hear how that sounds after a lecture on humility.", tone = "[dry self-awareness, sheepish amusement, warm]" }, "There is room to be proud of good work and grateful for the help that made it possible.", "Another person's skill is an opportunity to learn something." },
            befriended = { { "You came to bring me along. I am glad, my friend. There is no lesson to earn today. Let us enjoy the road together.", tone = "[sincere affection, relaxed dignity, welcoming]" } },
            poke = { "Yes? I was considering a particularly promising stone.", "You have my attention, friend." },
            learned = { { "Well done. Remember the people who helped you reach this point. There will be another learner who could use the same kindness.", tone = "[firm encouragement, proud but measured, thoughtful]" } },
            levelUp = { "Well earned. Carry it with a little gratitude." },
            loot = { "A good find. Keep it safe." },
            quest = { "Good work, my friend. Someone will be grateful for it." },
            zone = { "New ground, and likely something here we have yet to understand." },
            rest = { "A seat would be welcome. We needn't turn every pause into a lesson." },
            hearth = { "Back to the cathedral. Thank you for the company, and for keeping an honest count." },
        },
    },
    [1444] = {
        quote = "A useful lesson can begin in a workshop. I would rather borrow a good idea than pretend wisdom only arrives in one kind of book.",
        likes = { "An idea borrowed from honest craft", "A listener willing to ask a question", "A book returned to the hands awaiting it" },
        dislikes = { "Grand words that help nobody", "Borrowed work treated carelessly", "Confusing patience with doing nothing" },
        gossip = "Kristoff can find a lesson in metallurgy. Before sharing it with a crowd, he sometimes seems to be giving the fountain a very careful explanation.",
        bio = "Brother Kristoff prepares a speech on the Fortitude of the Spirit in Stormwind's Cathedral Square. He wants passages from The Stresses of Iron, a metallurgy book. Milton Sheaf at the Royal Library is his first lead to finding the copy.",
        backstory = "The book has gone to Brother Paxton in Northshire to be copied. Paxton's ink has dried up, and replacing it requires Rethban Ore from Redridge. A speech can depend on a surprising number of hands before anyone hears the first word.",
        secret = "The first sentence is the hardest. He rehearses by the fountain, then worries the words will vanish before a real audience. One familiar, kind face would help him begin.",
        bestFriend = "Stay where I can see you when I begin, will you? You needn't agree with every word. Knowing you are there will help me find the first one.",
        favorite = { emote = "NOD", hint = "An encouraging acknowledgment may help a speaker trust that someone is following him." },
        lines = {
            greet = { { "Ah, my friend. A walk sounds good. I have said the first sentence to the fountain often enough. Perhaps you would hear it once.", tone = "[thoughtful warmth, lightly nervous humor, welcoming]" }, "Good to see you. Have you time for an idea I have been considering?" },
            idle = { { "The first sentence is always the troublesome one. After that, I remember I am speaking to people. Before it, I remember how many people there might be.", tone = "[confiding, self-deprecating amusement, thoughtful]" }, "A book on metallurgy can have something worth saying about fortitude.", "A finished piece of work often carries more hands than its owner remembers." },
            befriended = { { "You came looking for me. I am glad, my friend. It will be good to have someone beside me who needn't be persuaded to listen.", tone = "[sincere gratitude, relieved affection, warm]" } },
            poke = { "Yes? Did I lose you somewhere in that explanation?", "Ah, you are listening. Good. What did you think?" },
            quest = { { "Well done. A little help in the right place can let someone else finish the work they have been waiting to do.", tone = "[appreciative, thoughtful encouragement, warm]" } },
            mail = { "Some news worth sharing, perhaps. Give it a proper reading." },
            learned = { "An idea from somewhere unexpected is still worth learning." },
            zone = { "I wonder what work keeps this place going. There may be a lesson in it." },
            rest = { "A quiet seat sounds good. You can tell me when my explanation grows too long." },
            bagsFull = { "Mind the books, if you have any. Keep the corners from being crushed." },
            hearth = { "Back to the square. Perhaps the first sentence will sound easier now." },
        },
    },

    -- Cathedral of Light: Brother Benjamin 5484, human male Priest
    -- Trainer, paces eastern hall; rigorous retraining/service dialogue.
    -- Brother Joshua 5489, human male Priest Trainer near altar; Classic
    -- Alathea referral 5631 and Ogtinc referral 8254. Ambiguous 5676 offer
    -- is not used as personal belief. Original steps/greetings hooks:
    -- docs/research/benjamin-and-joshua.md.
    [5484] = {
        quote = "Beginning again requires effort. You have my respect for doing it, provided you intend to do the work.",
        likes = { "A learner returning to practice", "An honest account of a mistake", "A walk long enough to finish a thought" },
        dislikes = { "A new lesson used to avoid old work", "Mocking someone who begins again", "Promises made in place of practice" },
        gossip = "Benjamin can cover a good deal of floor while thinking. A student with a question can stop him more reliably than any obstacle in the hall.",
        bio = "Brother Benjamin trains priests in Stormwind's Cathedral of Light. He paces the eastern main hall, offering help and urging visitors to hold to the Light. He expects serious effort from anyone who begins anew.",
        backstory = "Benjamin has helped students set aside old learning and start again. He expects effort and gives it in return. His own habit is to count his steps while considering a difficult question, until another pupil gives him something else to consider.",
        secret = "He has lost count of his steps many times. He pretends to mind the interruption. A hall where nobody dared ask a question would trouble him far more.",
        bestFriend = "Walk with me. You needn't bring a lesson or a question. I should be glad of your company while I let one thought finish itself.",
        favorite = { emote = "NOD", hint = "A deliberate acknowledgment shows that his advice has been heard." },
        lines = {
            greet = { { "There you are. A walk? Good. I have been turning the same thought over along the same stretch of floor. Let us give it some room.", tone = "[firm warmth, thoughtful, restrained amusement]" }, "Welcome back. Ready to put a little distance behind us?" },
            idle = { { "I count my steps when I am thinking. Then someone brings me a question, and I lose count. A worthwhile interruption, usually.", tone = "[dry humor, thoughtful, quietly fond]" }, "Beginning again is work. There is no shame in admitting that.", "A promise improves considerably when someone follows it with practice." },
            befriended = { { "You have made time for me again. I am glad of it, my friend. Come along. We can leave the lessons in the hall for a while.", tone = "[reserved affection, sincere, quietly welcoming]" } },
            poke = { "Yes? I have lost count now. What is it?", "You have my attention. Make use of it." },
            learned = { { "Good. Practice it while you remember where the difficult part was. Understanding improves when you return to the work.", tone = "[firm approval, focused encouragement, steady]" } },
            levelUp = { "Well earned. Take the next step with the same care." },
            quest = { "You followed through. Good." },
            zone = { "Room for a longer thought here." },
            rest = { "A pause, then. Even a determined mind can use one." },
            comforted = { "You are allowed a difficult day. I shall stay a moment." },
            hearth = { "Back to the hall. Someone may be waiting with a question." },
        },
    },
    [5489] = {
        quote = "Tell me how you greet a friend at home. I should like a visitor to hear something familiar, even if I must practice it first.",
        likes = { "A sincere greeting in another tongue", "Help offered beyond familiar walls", "A visitor willing to teach him something" },
        dislikes = { "Dismissing an unfamiliar tradition", "Helping only when praise is promised", "A traveler left unsure where to go" },
        gossip = "Joshua welcomes visitors at the cathedral. Sometimes he tries a new greeting quietly first, giving each unfamiliar sound its turn.",
        bio = "Brother Joshua trains priests near the altar in Stormwind's Cathedral of Light. His work has included passing Alathea's summons to a night elf priest and calling for aid to Ogtinc in Azshara. Those who need help can be far beyond the city's walls.",
        backstory = "Sending a traveler to the right person matters to Joshua. So does receiving one kindly. He has begun learning greetings from visitors, asking them to repeat the unfamiliar sounds until he can offer something of their own welcome back.",
        secret = "He practices when he thinks nobody is listening. He would rather risk sounding foolish than leave a visitor's kindness unanswered, but he is still grateful for patient correction.",
        bestFriend = "Will you hear me try it once more? You may correct me. It is a pleasure to learn something beside a friend who wants me to get it right.",
        favorite = { emote = "GREET", hint = "A sincere greeting gives this welcoming teacher something to return." },
        lines = {
            greet = { { "Welcome, my friend. Shall we go out? You might teach me a greeting for the road. I have been practicing the last one.", tone = "[courteous warmth, curious, lightly amused]" }, "Good to see you again. Where are we sharing the road today?" },
            idle = { { "An unfamiliar greeting takes practice. I ask people to repeat it. They have been very patient with me, especially over the sounds I thought I already knew.", tone = "[humble amusement, interested, warm]" }, "Someone in need may be a long way from these halls.", "A traveler should know whom to ask when they reach the other end of a journey." },
            befriended = { { "You came to bring me along. I am grateful, my friend. It will be good to share more than a greeting with you today.", tone = "[sincere affection, pleased, welcoming]" } },
            poke = { "Yes? Did I say it incorrectly again?", "I am listening. What would you like to ask?" },
            zone = { { "Another place, another welcome to learn. Let us listen before assuming we know how everyone here does things.", tone = "[thoughtful curiosity, open and attentive, calm]" } },
            group = { "Good to see everyone here. Has anyone been left without an introduction?" },
            quest = { "A little help offered where it was needed. Well done." },
            learned = { "There is always room to learn something from another person." },
            mail = { "A greeting carried over a long distance. I hope it finds you well." },
            rest = { "A good time for a quiet conversation. What should I practice next?" },
            hearth = { "Back to the cathedral, with something new to remember." },
        },
    },

    -- Cathedral of Light, Stormwind. Shaina Fuller 2327: human female
    -- First Aid Trainer; Deneb Walker book and Gustaf VanHowzen referrals.
    -- Brother Cassius 1351: human male Reagent Vendor; offers a blessing
    -- and help browsing. Original practice roll and wooden puzzle hooks:
    -- docs/research/fuller-and-cassius.md. No later comic meeting imported.
    [2327] = {
        quote = "Show me where you got stuck. We can make something useful of a mistake once you stop being ashamed to show it.",
        likes = { "A learner willing to ask for help", "Knowing when to seek another teacher", "Patient practice without an audience" },
        dislikes = { "Mocking someone's first attempt", "Pretending to know beyond one's skill", "Calling care for others beneath notice" },
        gossip = "Shaina treats awkward first attempts kindly. Her own untidy old practice roll may have something to do with it.",
        bio = "Shaina Fuller teaches first aid in Stormwind's Cathedral of Light. She welcomes fellow physicians and wants their learning to help them on the road. She points students toward Deneb Walker's book in Stromgarde and Doctor VanHowzen in Theramore.",
        backstory = "Shaina does not see another teacher's expertise as a slight to her own. There is always more to learn. A lesson goes better when a student can admit what is difficult, a habit she has tried to keep in herself as well.",
        secret = "She kept one of her earliest practice rolls. It is a dismal little bundle. She looks at it when her patience grows thin, then remembers to let the next learner begin again.",
        bestFriend = "You may be unsure with me. You needn't arrive with everything mastered. Sit beside me, and tell me what you have been trying to learn.",
        favorite = { emote = "THANK", hint = "A little gratitude recognizes a patient teacher's time and care." },
        lines = {
            greet = { { "Good to see you. Shall we have a walk? I would like to hear what you have been learning away from the cathedral.", tone = "[calm warmth, attentive curiosity, welcoming]" }, "There you are. Have you time for some company?" },
            idle = { { "I kept an old practice roll. Quite a dreadful little bundle. It helps me remember that a first attempt is allowed to look like one.", tone = "[gentle self-deprecating humor, thoughtful, reassuring]" }, "It is good to know when another teacher can help you further.", "A question is easier to help with when someone is willing to ask it." },
            befriended = { { "You thought of me. Thank you, my friend. I am glad to come along. We can take a little time for ourselves today.", tone = "[sincere affection, quietly pleased, relaxed]" } },
            poke = { "Yes? Tell me what you need.", "Gently, now. You have my attention." },
            learned = { { "There. Better than the last attempt. Take a moment to be pleased with that before deciding how far you still have to go.", tone = "[patient encouragement, approving, warm]" } },
            quest = { "Something useful done for someone else. Well done." },
            bagsFull = { "Keep what you need where you can find it." },
            rest = { "A pause would do us good. You needn't earn every moment of rest." },
            zone = { "New surroundings. There may be someone here with something to teach us." },
            comforted = { "You can sit with me. There is no need to explain before you are ready." },
            hearth = { "Back to the cathedral. I wonder what the next learner will ask." },
        },
    },
    [1351] = {
        quote = "May your journey begin well. And if there is some small thing you still need, there is time to ask before you go.",
        likes = { "A traveler who checks the little things", "Patient work on a stubborn puzzle", "A blessing offered back in kindness" },
        dislikes = { "A parcel crushed beneath heavier gear", "Confusing haste with preparedness", "Giving up on someone too quickly" },
        gossip = "Cassius has a blessing for travelers. Between visitors, two little wooden rings seem to demand all his patient attention.",
        bio = "Brother Cassius supplies reagents at Stormwind's Cathedral of Light. A member of the Church of the Holy Light, he welcomes travelers with a blessing and offers help browsing. The small things needed for a journey deserve some patient attention.",
        backstory = "Cassius has come to value the questions asked before a traveler leaves. There is comfort in a small difficulty put right. Away from his supplies, he spends some of that same patience on a puzzle made of interlocking wooden rings.",
        secret = "He has not separated the rings yet. Asking for help is proving oddly difficult for someone who offers it so readily. He hopes a friend will be curious enough to try.",
        bestFriend = "Here, have a look. I should be glad of your help. We needn't solve it before we enjoy the time together. Shall I start us some tea?",
        favorite = { emote = "PRAISE", hint = "A kind word offered back may encourage someone who sends others away with a blessing." },
        lines = {
            greet = { { "Welcome, my friend. Are we going out? Give me a moment. I should like to leave this little puzzle behind before it occupies the whole day.", tone = "[gentle warmth, courteous, lightly amused]" }, "It is good to see you. Have you everything you need for the road?" },
            idle = { { "The wooden rings are meant to come apart. I have yet to persuade them. Perhaps I should practice accepting the help I am so ready to offer.", tone = "[reflective, humble amusement, confiding]" }, "A small question before departure can spare a larger worry on the road.", "There is time to look properly. I would rather help than hurry you." },
            befriended = { { "You came to bring me along. Thank you. I am glad of your friendship, and glad to share a little of the road with you.", tone = "[sincere gratitude, affectionate, warmly inviting]" } },
            poke = { "Yes, my friend? What can I help with?", "Ah. I was considering those rings again. You have rescued me." },
            bagsFull = { { "Perhaps we should make room before adding anything more. Keep the little things where they will not be crushed or forgotten.", tone = "[considerate, practical encouragement, calm]" } },
            loot = { "Something you needed? Good. Take care of it." },
            mail = { "Some news to carry with you, perhaps. I hope it is welcome." },
            quest = { "May the kindness you have offered find its way back to you." },
            zone = { "Another stretch of road. I am glad of the company." },
            rest = { "A quiet seat would be welcome. Would you care to try a little puzzle?" },
            hearth = { "Back to my corner of the cathedral. Thank you for sharing the journey." },
        },
    },

    -- Aldwin Laughlin 4974: human male Guild Master at Stormwind's
    -- Visitor's Center; installed guild-registry welcome. Nikova Raskol
    -- 1721: human female, Old Town; The Color of Blood 388, Mac's
    -- grandmother. No assumed quest completion or later retail rescue.
    -- Original quiet-meeting crest and listening hooks are documented in
    -- docs/research/laughlin-and-raskol.md.
    [4974] = {
        quote = "Your guild name is your decision. I do recommend deciding together before anyone reaches for the ink.",
        likes = { "A name everyone has agreed on", "A legible signature", "An invitation without paperwork" },
        dislikes = { "Talking over the quiet member", "Ink spilled on a finished charter", "Every small disagreement made official" },
        gossip = "Aldwin hears grand plans at the guild registry. The little crest on his spare paper suggests he dreams of a quieter gathering.",
        bio = "Aldwin Laughlin serves Stormwind's guild registry at the Visitor's Center in the Trade District. He helps people begin a guild and find their way through its formalities. A room full of friends can still take time to agree on a name.",
        backstory = "Listening to excited groups has made Aldwin attentive to the person who has not managed a word. He likes to hear that voice before the decision is made. After a busy day, his own idea of a fine gathering needs very little ceremony.",
        secret = "He has sketched a crest with a teacup and crossed biscuits. It is for an imaginary guild whose meetings have no agenda. Drawing it makes a long afternoon rather easier.",
        bestFriend = "No agenda today. Choose somewhere comfortable, and tell me how you've been. I should like to spend an afternoon without taking minutes.",
        favorite = { emote = "NOD", hint = "A clear acknowledgment is welcome to someone helping a group reach a decision." },
        lines = {
            greet = { { "Ah, my friend. An outing? Excellent. I shall leave the paperwork here. For once, we needn't agree on a name before we go.", tone = "[courteous warmth, dry humor, quietly pleased]" }, "Good to see you. Have we a plan, or may we enjoy not having one?" },
            idle = { { "A teacup and crossed biscuits. An entirely imaginary guild crest. Its meetings would have no agenda. I find the idea quite restful.", tone = "[confiding, restrained amusement, relaxed]" }, "Before a group decides, I like to hear the person who hasn't had a word yet.", "A little patience can save a surprising amount of fresh ink." },
            befriended = { { "You thought to invite me. Thank you. I am very glad to come along, my friend. No formalities required.", tone = "[sincere gratitude, warm affection, welcoming]" } },
            poke = { "Yes? I hope this does not require a signature.", "You have my attention. Take your time." },
            group = { { "A fine gathering. Before we choose a direction, does everyone have what they need? Even the quiet one at the back?", tone = "[friendly authority, considerate, lightly amused]" } },
            mail = { "A letter can wait until someone has had a moment to read it properly." },
            quest = { "A matter settled. That is always welcome news." },
            bagsFull = { "We appear to need a little order before adding anything else." },
            zone = { "A pleasant change from the view across my desk." },
            rest = { "A seat, good company, and nothing to record. Excellent." },
            hearth = { "Back to the registry. I shall be rather more patient for having had this walk." },
        },
    },
    [1721] = {
        quote = "His name was Mac. Before you hear what happened at the Stockade, remember that there was a boy.",
        likes = { "Hearing Mac spoken of as a person", "A visitor who keeps their word", "Company that can bear a quiet moment" },
        dislikes = { "Making a child's death sound glorious", "Easy assurances about another's grief", "The Defias' red wool emblems" },
        gossip = "Nikova walks Old Town with much on her mind. A familiar greeting may earn a few steps beside her. She notices who keeps coming back.",
        bio = "Nikova Raskol mourns her grandson Mac in Stormwind's Old Town. He was fourteen when he guarded the Stockade after the army left for the front. Defias prisoners killed him after he challenged them over blankets torn into gang scarves.",
        backstory = "Nikova asks for the Defias' red wool bandanas as a reckoning for Mac's death. To her, their return would mean justice for her family. She knows it could never give her back the boy she remembers.",
        secret = "She wants someone to ask what Mac was like before the Stockade. Sometimes she cannot find a story to begin with. She hopes a friend will stay while she finds the words.",
        bestFriend = "Walk with me a little. You needn't fill every silence. It is a comfort to know you have time for me, even when I have no words ready.",
        favorite = { emote = "COMFORT", hint = "A quiet offer of comfort asks for no explanation and no cheerful answer." },
        lines = {
            greet = { { "You have come back. Walk with me a little. You needn't find anything clever to say. I am glad of the company.", tone = "[weary warmth, restrained grief, quietly welcoming]" }, "There you are. Have you time for a few steps beside me?" },
            idle = { { "People hear of the Stockade, and the Defias, and the bandanas. His name was Mac. I would like them to remember that too.", tone = "[somber, controlled anger, tender on the name]" }, "Some days I have more to say than others.", "I notice the people who keep coming back. It matters." },
            befriended = { { "I was hoping you might come by. Let us go together, my friend. I am glad I do not have to ask you to stay.", tone = "[reserved affection, relief, softly sincere]" } },
            poke = { "Yes? Forgive me. I was somewhere else for a moment.", "I am listening. What is it?" },
            comforted = { { "You needn't find the words at once. I can stay. We can be quiet together until you are ready.", tone = "[gentle concern, grounded warmth, steady and unhurried]" } },
            quest = { "You kept your word. I do not take that lightly." },
            zone = { "Different streets. Keep beside me a little longer, will you?" },
            rest = { "Yes. A seat would be welcome." },
            mail = { "Read it while you have time to give it your attention." },
            group = { "Look after one another. Please." },
            hearth = { "Back to familiar streets. Thank you for the walk." },
        },
    },

    -- The Empty Quiver, Trade District: Frederick Stover 1298, human
    -- male Bow & Arrow Merchant, and Lina Stover 1297, human female Bow
    -- & Gun Merchant. Both offer help browsing and boast of their deals.
    -- Morgg Stormshot 1472: named dwarf male in the Dwarven District,
    -- no verified quest/service role. Original jokes, coin trick and dance:
    -- docs/research/empty-quiver-and-morgg.md. No later royal commission.
    [1298] = {
        quote = "Good goods, fair prices, and a joke while you browse. I make no promises about the quality of the joke.",
        likes = { "Someone pleased with an ordinary purchase", "A customer who returns with good news", "A truly dreadful bit of wordplay" },
        dislikes = { "Sneering at a beginner's equipment", "A sale pushed on someone who is unsure", "A good joke explained before its ending" },
        gossip = "Frederick has a joke for nearly every sale. Some customers claim they visit the Empty Quiver just to see whether today's is any worse.",
        bio = "Frederick Stover sells bows, arrows and quivers at the Empty Quiver in Stormwind's Trade District. He welcomes browsers and offers help finding something specific. His confidence in a good deal comes with an equally confident attempt at a joke.",
        backstory = "Conversations across the counter gave Frederick a taste for wordplay. He began saving jokes on scraps of wrapping paper. A terrible one can survive several busy days in his memory, waiting for someone who hasn't heard it yet.",
        secret = "He remembers the groans as fondly as the laughter. A familiar customer finishing a joke before he does makes the shop feel wonderfully busy, even on a quiet day.",
        bestFriend = "You can tell me it was dreadful. I shall survive. Come back tomorrow, though. I've thought of another one, and I want to hear you groan.",
        favorite = { emote = "GRIN", hint = "A broad smile shows that someone appreciates the shopkeeper's wordplay." },
        lines = {
            greet = { { "Ah, a familiar face! Shall we go out? I have been saving a particularly dreadful joke, and I could use a fresh audience.", tone = "[genial, playful salesman confidence, warmly welcoming]" }, "There you are. Good to see you when neither of us is in a hurry." },
            idle = { { "I keep the good jokes on scraps of wrapping paper. The dreadful ones too. Rather more of those, if I am honest.", tone = "[conspiratorial, self-deprecating amusement, cheerful]" }, "An ordinary bow can mean a great deal to someone buying their first.", "A returning customer with good news improves the whole morning." },
            befriended = { { "You came back for the company. Well, I am pleased. Come along, my friend. You have earned the very worst of my jokes.", tone = "[sincere warmth, pleased, gently teasing]" } },
            poke = { "Yes? Have you heard this one already?", "Ah. A pointed remark, was it? No? I'll keep working on that." },
            loot = { { "A good find! Now, are you keeping it, selling it, or waiting for me to make a terrible remark about it?", tone = "[pleased, lightly mischievous, friendly]" } },
            bagsFull = { "Leave room for what you actually went out to buy." },
            quest = { "Good news to take back. I do like that part." },
            gear = { "Happy with it? Good. That is what matters." },
            mail = { "Perhaps someone has sent you a better joke. I should like to borrow it." },
            rest = { "Time for a seat and a little conversation." },
            hearth = { "Back to the Empty Quiver. I hope someone has been saving a good story for me." },
        },
    },
    [1297] = {
        quote = "Tell me what you're looking for. Browsing is welcome, and a question doesn't oblige you to buy anything.",
        likes = { "Questions asked before a purchase", "A purchase chosen without pressure", "A neat little trick with a copper coin" },
        dislikes = { "Handling someone's goods carelessly", "Pretending to understand when unsure", "Interrupting a customer with a boast" },
        gossip = "Lina can talk you through the stock at the Empty Quiver. Between customers, she sometimes seems to be negotiating with a single copper coin.",
        bio = "Lina Stover sells bows, guns and ammunition at the Empty Quiver in Stormwind's Trade District. She also offers repairs. Her welcome leaves room for questions, especially from someone who has not quite decided what they came to find.",
        backstory = "Working among so many choices has taught Lina to let a customer think. She has a small occupation for the gaps in a quiet day: practicing a coin trick. She wants to flip a copper and have it settle upright on its edge.",
        secret = "The copper has escaped under the counter far more often than it has obeyed her. She keeps trying. The occasional ridiculous failure is a fine excuse to laugh at herself.",
        bestFriend = "Here, your turn. If it rolls away, we'll find it. I like having someone beside me who can enjoy the attempt before it turns into a success.",
        favorite = { emote = "THANK", hint = "A little gratitude is welcome when someone has taken time to help you choose." },
        lines = {
            greet = { { "Good to see you. An outing sounds lovely. Give me a moment to find that copper, and I am all yours.", tone = "[easy warmth, practical, quietly amused]" }, "Hello again. Have we somewhere to be, or can we enjoy getting there?" },
            idle = { { "It is meant to land on its edge. Usually it goes under the counter. I am getting very good at the part where I retrieve it.", tone = "[dry humor, good-natured, confiding]" }, "A question is easier to answer before someone regrets a purchase.", "There is no need to decide before you have had a proper look." },
            befriended = { { "You have made time for me again. I am glad. Come along, my friend. The shop can spare me for a little while.", tone = "[sincere affection, relaxed, pleased]" } },
            poke = { "Yes? I haven't lost the coin again, if that is what you are wondering.", "Something you wanted to ask? Go on." },
            loot = { { "Oh, a useful little find. Keep it somewhere it won't roll away. Experience speaking, there.", tone = "[pleased interest, wry, warm]" } },
            gear = { "How does it feel? Take your time deciding." },
            bagsFull = { "Perhaps we should make room before we go looking for anything else." },
            quest = { "That should settle someone's question. Good work." },
            zone = { "A change of surroundings is welcome. Let us have a proper look." },
            rest = { "A seat would be lovely. I have a little trick you can try." },
            hearth = { "Back to the shop. I hope I remembered where I put everything." },
        },
    },
    [1472] = {
        quote = "Aye, I know the tune. Give me a little room, and we'll find out whether my boots do.",
        likes = { "A tune with a good steady beat", "A partner who can laugh kindly", "Room to try a step again" },
        dislikes = { "Being hurried through a new step", "A mistake treated as a great disgrace", "Someone laughing at a nervous beginner" },
        gossip = "Morgg looks quite settled in the Dwarven District. Then a tune catches his attention, and one boot starts trying to have an adventure.",
        bio = "Morgg Stormshot is a dwarf in Stormwind's Dwarven District. He is a familiar face to greet among the city's bustle. Give him a little music and some friendly encouragement, and his quiet corner can become a place to practice a dance.",
        backstory = "Morgg remembers tunes readily. Learning what to do with his feet has taken longer. He has been practicing a simple turn whenever he has room, usually remembering the next step just after he needs it.",
        secret = "He is very proud of one turn he finally got right. He would like to show someone, but asking for an audience feels harder than learning the turn did.",
        bestFriend = "You needn't be good at it. Neither do I. Come on, then. We'll find the beat together, and if we lose it, we can have another go.",
        favorite = { emote = "DANCE", hint = "A little dancing might encourage those restless boots to join in." },
        lines = {
            greet = { { "Ah, there you are! A walk sounds good. These boots could use something straightforward to do for a change.", tone = "[gruff warmth, wry amusement, welcoming]" }, "Good to see you, friend. Where are we taking ourselves today?" },
            idle = { { "I got the turn right. Once. I'd show you, but give me a moment to remember what I did with the other foot.", tone = "[quiet pride, sheepish amusement, friendly]" }, "A steady beat. That's what I need. The feet can catch up.", "There's a tune stuck in my head. You may hear it escape in a moment." },
            befriended = { { "You came looking for me? Aye, I'm pleased. Come on, my friend. There's room beside you for an old pair of clumsy boots.", tone = "[touched, hearty affection, warmly inviting]" } },
            poke = { "Aye? I was counting. Lost the beat now.", "Still here, friend. Were you wanting a turn?" },
            learned = { { "There you are! Better than the last try. Keep at it. A small success is still worth being pleased about.", tone = "[hearty approval, encouraging, warm]" } },
            levelUp = { "Well done! That's earned a little celebration." },
            zone = { "A fair bit of room here. Mind if I try something?" },
            quest = { "Good work, friend. You've given someone a reason to smile." },
            rest = { "A seat for a moment. Let the boots think about their mistakes." },
            danceAlong = { { "Aye, that's the tune! Give me a little room. If I get the turn right, you are allowed to look impressed.", tone = "[eager, playful pride, hearty warmth]" } },
            hearth = { "Back to familiar ground. I shall see if I still remember that turn." },
        },
    },

    -- Collin Mauren 4078: human male, Mage Quarter, Stormwind; Gaxim's
    -- messaging scroll 1075-1077 and basilisk reagent request 1078.
    -- Sprite Jumpsprocket 11026: gnome female, Journeyman Engineer,
    -- Dwarven District; Lilliam referral, Forever Toxic Soil explosives
    -- 92748-92752 and Reagent Bot lesson 97918. Original map/toy hooks:
    -- docs/research/mauren-and-jumpsprocket.md.
    [4078] = {
        quote = "Tell me where you've been. The component can wait a moment; I should like to hear what the road was like.",
        likes = { "A traveler with time for the whole story", "A spell that solves a friend's problem", "A place described in loving detail" },
        dislikes = { "A good account hurried to its ending", "Reagents mixed up in a courier's bag", "Experiments explained after they start" },
        gossip = "Travelers bring Collin news of Stonetalon. He asks such particular questions about the view that you might think he was planning a journey.",
        bio = "Collin Mauren works with spells in Stormwind's Mage Quarter. His friend Gaxim Rustfizzle needs magic for a remote explosive, and Collin devises a messaging scroll. He is eager to hear the adventure's ending when the work is done.",
        backstory = "The Charred Vale's basilisk scales are useful in spells Collin has created. Travelers' questions keep drawing his attention back to Stonetalon. Their accounts have also given him a growing map of places he would like to see himself.",
        secret = "One spot on his map is still unnamed. A traveler described a lovely view but forgot its name. Collin wants to find it without deciding in advance what to call it.",
        bestFriend = "Would you take the long way with me? I should like to bring back a story of our own, and tell it without leaving anything out.",
        favorite = { emote = "GREET", hint = "A friendly greeting is a fine beginning to a conversation with this welcoming spellworker." },
        lines = {
            greet = { { "Ah, my friend. Shall we take a walk? There are places on my map I have only ever heard described.", tone = "[warm curiosity, thoughtful, welcoming]" }, "Good to see you. Have you time for a little wandering?" },
            idle = { { "Someone described a lovely view to me, then forgot its name. I have left a space on my map. Perhaps we shall find it.", tone = "[reflective, hopeful, quiet amusement]" }, "Gaxim does have a way of making a simple request interesting.", "A useful spell begins with understanding what someone actually needs." },
            befriended = { { "I am glad you came back for me. This time I shall hear the story as it happens. Lead on, my friend.", tone = "[sincere affection, quietly excited, trusting]" } },
            poke = { "Yes? I was trying to remember a turn in the road.", "You have my attention. What is it?" },
            quest = { { "Well done. When you tell me about it, begin at the beginning. I should hate to miss the interesting part.", tone = "[pleased, interested, warmly encouraging]" } },
            loot = { "Keep that apart from the other components, if you please." },
            zone = { "Now, what would you tell someone who had never seen this place?" },
            mail = { "News from a friend is worth making time for." },
            learned = { "Ah, a new possibility. I wonder what you will find to do with it." },
            rest = { "A good place to sit. Tell me about the journey that brought you here." },
            hearth = { "Back to Stormwind, with something new to talk about." },
        },
    },
    [11026] = {
        quote = "Stand back a little. I want an audience, and I'd like to have the same audience afterward.",
        likes = { "An engineering pupil full of questions", "A project with a satisfying finish", "Someone watching the little moving parts" },
        dislikes = { "A detonator handled without care", "Calling a small machine uninteresting", "Interruptions at the exciting bit" },
        gossip = "Sprite can get excited about a very loud project. Ask about the little flower drawn on her spare paper, and she gets excited all over again.",
        bio = "Sprite Jumpsprocket teaches engineering in Stormwind's Dwarven District. She helps prepare explosives for Alba Fairmoon's Westfall investigation, sending the player to Stormwind Intelligence for a remote detonator. She enjoys the work enormously.",
        backstory = "Sprite sends advanced students to Lilliam Sparkspindle. She also teaches a Reagent Bot for wilderness camps. Her enthusiasm reaches beyond explosives: she has been working out how to make a tiny mechanical flower open one petal at a time.",
        secret = "She has filled several pages with that flower. The last petal keeps sticking in her little trial model. She wants someone to watch when she finally gets it right.",
        bestFriend = "Stay for the whole thing, will you? Every petal. I want to see your face when the last one opens. I've been saving that moment for us.",
        favorite = { emote = "CLAP", hint = "An enthusiastic audience can make even a little engineering demonstration feel grand." },
        lines = {
            greet = { { "There you are! Come along. I've been staring at one stubborn little part, and my brain could use a run around.", tone = "[bright excitement, quick and lively, friendly]" }, "An outing? Lovely! Are we going somewhere interesting? Of course we are." },
            idle = { { "Every petal opens in order. Well, that is the idea. The last one still sticks. Don't laugh until you've seen how tiny it is.", tone = "[animated enthusiasm, mock indignation, affectionate humor]" }, "Lilliam can help when a pupil gets beyond what I know.", "I like that moment when all the little parts finally agree with one another." },
            befriended = { { "You came to take me along! Oh, I like that. Let's go find something worth getting excited about, my friend.", tone = "[delighted, spontaneous affection, eager]" } },
            poke = { "Careful! I was thinking, and there were several moving parts.", "Yes? Have you spotted something good?" },
            learned = { { "That's it! Now try it again while you remember how. Oh, I do like seeing someone get the hang of things.", tone = "[excited approval, proud encouragement, lively]" } },
            quest = { "That should give someone something to talk about!" },
            loot = { "Ooh. Let me see the fiddly bits." },
            bagsFull = { "Don't crush the little things under the large things. I may want to look at them." },
            zone = { "New surroundings. Good! My ideas were starting to go in circles." },
            rest = { "A campfire! A useful beginning for a bit of outdoor engineering." },
            hearth = { "Back to the tent. I have thought of something to try on that last petal." },
        },
    },

    -- Mage Quarter, Stormwind. Tannysa 5566: night elf female herbalism
    -- trainer, discreet Jonespyre referral 3787 in the morrowgrain chain.
    -- Eldraeith 5503: night elf female supplier, goods as an alliance gesture.
    -- Maria Lumere 1313: human female alchemy supplier, local craftspeople
    -- filling shortages after Dalaran/Quel'Thalas. Original question list,
    -- craft keepsakes and sunlight hooks: docs/research/alchemy-suppliers.md.
    [5566] = {
        quote = "You may interrupt. Have a question worth the interruption, and we can both make good use of the time.",
        likes = { "An observation made with care", "A question that deserves research", "Discretion when a colleague asks for it" },
        dislikes = { "Interruptions without a purpose", "Authority offered instead of evidence", "Careless handling of a useful specimen" },
        gossip = "Tannysa is very sure of what she knows. A page of unanswered questions suggests she is just as serious about what she doesn't.",
        bio = "Tannysa teaches herbalism outside Alchemy Needs in Stormwind. She takes pride in her expertise. When morrowgrain research raises concerns, she discreetly directs help to her colleague Quintis Jonespyre at Feathermoon Stronghold.",
        backstory = "Jonespyre wants to examine the morrowgrain collected for Staghelm, away from the Arch Druid's attention. Tannysa helps make the introduction. Her confidence in her own skill leaves room for a colleague asking an uncomfortable question.",
        secret = "She keeps a list of questions she cannot yet answer. She doesn't show it to every learner. Adding a good question pleases her almost as much as crossing one off.",
        bestFriend = "You may ask what I don't know. Just stay while I consider the answer. It is a pleasure to think beside someone I trust.",
        favorite = { emote = "NOD", hint = "A thoughtful acknowledgment shows that someone is actually following her explanation." },
        lines = {
            greet = { { "There you are. If we are going out, let us notice something worth asking about. I dislike wasting a good interruption.", tone = "[self-possessed, sharp curiosity, lightly amused]" }, "Good. A change of surroundings may improve the question I've been considering." },
            idle = { { "Yes, there are questions on that page I cannot answer. Yet. I would be a poor researcher if I stopped finding them.", tone = "[quiet confidence, candid, dry humor]" }, "A careful observation is worth more than a grand assertion.", "Some questions belong in a quieter conversation." },
            befriended = { { "You listen, and you ask something worth answering. I find myself looking forward to your visits. Come along, my friend.", tone = "[reserved affection, sincere warmth, welcoming]" } },
            poke = { "Was there a question attached to that?", "Yes? I trust this is for a good cause." },
            learned = { { "Good. Now test what you think you understand against what you actually observe. There is always another question.", tone = "[firm encouragement, focused, approving]" } },
            loot = { "An interesting specimen? Keep it where it will remain useful." },
            bagsFull = { "A collection improves considerably when its owner knows what is in it." },
            zone = { "New ground. Keep your eyes open before deciding what you already know." },
            quest = { "A little more evidence. Tell me what you found." },
            rest = { "Yes. A pause may improve the quality of the conversation." },
            hearth = { "Back to my work. Perhaps the answer will look clearer now." },
        },
    },
    [5503] = {
        quote = "There are hands behind good work. I like it when a customer has time to ask about them.",
        likes = { "Careful craftwork across the sea", "Curiosity about the maker", "A small example of Stormwind skill" },
        dislikes = { "Fine work handled carelessly", "Calling ordinary supplies unimportant", "A maker's effort dismissed at a glance" },
        gossip = "Eldraeith speaks proudly of Teldrassil's work. Her own small collection seems to include some very ordinary human-made things.",
        bio = "Eldraeith sells herbalism supplies at Alchemy Needs in Stormwind. She describes goods from Teldrassil as a gesture of the growing alliance between night elves and humans. Helping someone choose them is a small part of that connection.",
        backstory = "The work she offers has crossed from Kalimdor to this city. Eldraeith values the skill behind it as much as the journey. Working among humans has given her an interest in what their craftspeople make in return.",
        secret = "She saves small pieces of human craftwork to take west someday. Nothing rare: an ordinary button can tell a fine story about the hands that shaped it.",
        bestFriend = "Tell me about something you made. It needn't be grand. I like seeing the work through the eyes of someone I care about.",
        favorite = { emote = "THANK", hint = "A little gratitude recognizes the effort behind something that traveled a long way." },
        lines = {
            greet = { { "Good to see you, my friend. Shall we look around? There is always some little piece of work I have not noticed yet.", tone = "[warm dignity, curious, welcoming]" }, "There you are. What have you found in the city today?" },
            idle = { { "The button is human work. Quite ordinary, yes. I would like to take a little of this city's skill west with me someday.", tone = "[fond interest, reflective, quiet pride]" }, "A maker need not be famous to have done something well.", "The little things carry a great deal of patient work." },
            befriended = { { "A friend to share the discoveries with. I am glad. Come along. You may notice something I would have walked past.", tone = "[sincere affection, pleased, gently inviting]" } },
            poke = { "Yes? Is there something you would like me to see?", "Gently, my friend. I am listening." },
            loot = { { "Look at the work in that. Before we decide what it is worth, let us notice how it was made.", tone = "[attentive curiosity, appreciative, thoughtful]" } },
            mail = { "A little news across the distance, perhaps." },
            zone = { "Another place with its own work and its own stories. Let us take time to see them." },
            bagsFull = { "Keep the fragile things apart from the heavy ones." },
            quest = { "Work done with care. Someone will be glad of it." },
            rest = { "A quiet seat sounds good. Tell me what you noticed today." },
            hearth = { "Back to the shop. There may be someone with a question worth hearing." },
        },
    },
    [1313] = {
        quote = "A small bottle can be an important beginning. Tell me what you need before you decide the ordinary things aren't worth asking about.",
        likes = { "Good work from Stormwind's crafters", "A supply order arriving intact", "Sunlight through an ordinary empty vial" },
        dislikes = { "A fragile parcel packed carelessly", "Promising stock before it arrives", "Calling small supplies beneath notice" },
        gossip = "Maria can be very serious about a shipment. Then sunlight catches an empty vial, and she seems happy to pause over almost nothing.",
        bio = "Maria Lumere sells alchemy supplies at Alchemy Needs in Stormwind's Mage Quarter. Her trade has felt the loss of goods from Dalaran and Quel'Thalas. She praises Lucan Cordell and other local craftspeople for helping fill the city's orders.",
        backstory = "Scarce supplies made dependable local work matter even more. Maria learned to value the ordinary pieces that let another person's work begin. A completed order is welcome news, especially when the delicate things arrive as they should.",
        secret = "Her favorite bit of arcane splendor is sunlight through an ordinary empty vial. She knows there's no enchantment. She enjoys the little patch of color anyway.",
        bestFriend = "Stay a moment. Look where the light falls. We can enjoy something without pricing it, packing it or finding a use for it.",
        favorite = { emote = "SMILE", hint = "A cheerful expression is quite enough appreciation for a small, pretty moment." },
        lines = {
            greet = { { "There you are. An outing sounds lovely. I could use a little daylight that doesn't arrive through the shop window.", tone = "[practical warmth, cheerful, welcoming]" }, "Good to see you. Everything you needed accounted for? Then let's enjoy the rest of the day." },
            idle = { { "No enchantment. Just sunlight through an empty vial. I know perfectly well what it is. I like the little patch of color.", tone = "[contented, gently amused, personal warmth]" }, "An order filled here in Stormwind is something to appreciate.", "The ordinary little things are often what someone needs before they can start." },
            befriended = { { "You came for the company. I'm glad. Put the errands aside for a while, and let's see what the day has left for us.", tone = "[sincere affection, pleased, relaxed]" } },
            poke = { "Careful. Some of the things I handle are rather delicate.", "Yes? Did we miss something on the list?" },
            loot = { { "Something useful? Keep it safe. And if it only happens to be pretty, you're allowed to enjoy that too.", tone = "[encouraging, lightly playful, warm]" } },
            bagsFull = { "Mind the glass before you start squeezing another thing into that pack." },
            mail = { "A shipment, perhaps. I hope it had a quiet journey." },
            learned = { "Good. Now you'll know which little supplies matter to the work." },
            rest = { "A seat and a little light. That's a pleasant sort of break." },
            zone = { "Somewhere new. I wonder what people make here." },
            quest = { "An order seen through. A good feeling, isn't it?" },
        },
    },

    -- Alchemy Needs, Mage Quarter, Stormwind. Night elves: Lilyssia 5499,
    -- female Expert Alchemist; Tel'Athir 5500, male Journeyman Alchemist.
    -- Installed gossip: her duty to teach conflicts with wanting to fight;
    -- he wants news of Teldrassil. They refer learners to one another;
    -- Lilyssia also refers advanced learners to Ainethil in Darnassus.
    -- No invented formal apprenticeship, Nightbreeze kinship or later
    -- Amirdrassil relocation. Sources: docs/research/alchemy-needs.md.
    [5499] = {
        quote = "If I must remain here, I intend my work to travel farther than this room. Listen well, then put the lesson to use.",
        likes = { "A learner who returns with experience", "Hearing her teaching proved useful", "A chance to move beyond the doorway" },
        dislikes = { "Being shut indoors through the action", "Knowledge learned and never used", "Calling her duty an easy choice" },
        gossip = "Lilyssia says a teacher should keep her reflexes ready. A flying cork seems to be her smallest and most persistent opponent.",
        bio = "Lilyssia Nightbreeze teaches alchemy at Alchemy Needs in Stormwind. She sends beginners to Tel'Athir and advanced learners to Ainethil in Darnassus. She longs to join battles beyond the walls, but remains to teach those who fight in her stead.",
        backstory = "Duty keeps her knowledge within reach of new alchemists. It does little to quiet her wish to be outside. Lilyssia gives her attention to the lesson, knowing a student may carry its usefulness much farther than she can travel that day.",
        secret = "She practices catching a tossed cork between lessons. When she misses, she glares at it as though it has won a worthy contest. It remains a cork, which makes the defeat rather irritating.",
        bestFriend = "You may laugh when I miss. Then let us go outside for a while. I can return to the lesson with a clearer head afterward.",
        favorite = { emote = "FLEX", hint = "A little readiness for the field is more welcome to her than another pose behind a desk." },
        lines = {
            greet = { { "Outside at last. Come, let us make good use of the time. The lesson can wait until I have seen a little of the day.", tone = "[eager, purposeful, restrained excitement]" }, "There you are. Tell me what you have put to use since we last spoke." },
            idle = { { "The cork is for keeping my reflexes sharp. Yes, I missed. No, you need not look so pleased about the cork's victory.", tone = "[dry dignity, competitive amusement, a small laugh]" }, "It is good to hear that a lesson mattered somewhere beyond the shop.", "Duty need not mean I have stopped wanting to be out here." },
            befriended = { { "Someone who remembers there is more to me than the next lesson. I am glad you came. Let us enjoy the road together.", tone = "[sincere warmth, appreciative, quietly eager]" } },
            poke = { "You have my attention. What will you do with it?", "An unexpected test of patience?" },
            learned = { { "Good. Now carry that knowledge farther than the room where you learned it. I would like to hear what you make of it.", tone = "[firm encouragement, pride, energetic interest]" } },
            combatEnd = { "Everyone safe? Good. Let the excitement settle before we move on." },
            quest = { "Work put to use. That is worth being pleased about." },
            loot = { "Something useful? Take care of it, then." },
            rest = { "A pause in the open air is still a welcome change." },
            levelUp = { "Experience has answered the lesson. Well done." },
            hearth = { "Back to the shop. I hope there will be news worth hearing." },
        },
    },
    [5500] = {
        quote = "Stay a moment. A little news from far away can make this room feel much less small.",
        likes = { "Tidings of Teldrassil", "A traveler willing to tell the ordinary parts", "Knowledge shared with care" },
        dislikes = { "A greeting cut short by haste", "Being told every story needs a battle", "A lesson forgotten as soon as it ends" },
        gossip = "Tel'Athir asks travelers for news, then sometimes adds a line to a letter. Nobody seems to see him sending it.",
        bio = "Tel'Athir teaches alchemy at Alchemy Needs in Stormwind's Mage Quarter. He welcomes learners and directs those beyond his teaching to Lilyssia Nightbreeze. He also asks travelers for news of Teldrassil, plainly missing the distant tree.",
        backstory = "A visitor can bring more than a request for instruction. Tel'Athir listens for the places behind a journey and the small details that make them familiar. Sharing his knowledge gives him a reason to ask after the world beyond Stormwind.",
        secret = "The letter is addressed to himself. When someone brings good news of Teldrassil, he adds one thing he hopes to see again. He likes having a page that waits for a journey instead of a reply.",
        bestFriend = "You needn't bring news from far away every time. Tell me about your day. I have come to look forward to hearing it from you.",
        favorite = { emote = "GREET", hint = "A friendly greeting suggests a traveler may have time to stop and share a little news." },
        lines = {
            greet = { { "There you are, my friend. Have you brought news? Or shall we go and find something worth telling together?", tone = "[gentle warmth, hopeful, quietly curious]" }, "It is good to see you. Tell me where the day has taken you." },
            idle = { { "The letter is for me. Things I hope to see again in Teldrassil. No need to send it; I know where its reader can be found.", tone = "[wistful affection, soft humor, confiding]" }, "An ordinary morning can be very good news to someone far from it.", "It is a pleasure to share something useful and hear a little of the world in return." },
            befriended = { { "A familiar friend to travel beside. Thank you. The world feels a little less distant when there is someone to share it with.", tone = "[sincere affection, grateful, quietly delighted]" } },
            poke = { "Yes? Did I miss part of the story?", "I am here. What would you like to tell me?" },
            zone = { { "Somewhere new. Let us notice the little things too. They may be what we most wish to remember later.", tone = "[gentle wonder, attentive curiosity, hopeful]" } },
            learned = { "Knowledge shared and understood. May you put it to good use." },
            quest = { "A little more of someone's story brought to a happier place." },
            mail = { "News, perhaps. I hope it is good." },
            rest = { "Sit a while. A story need not be hurried to its ending." },
            landed = { "There. What shall we notice first?" },
            hearth = { "Home for now. There may be someone glad to hear where we have been." },
        },
    },

    -- Archmage Malin 2708 and Brother Sarno 7917, male humans, Stormwind.
    -- Malin's Classic Trelane recovery chain: 690/691/693-697. Sarno's
    -- Overspark/Techbot referral: 2923 -> 2922. No assumed player completion,
    -- repaired Techbot, later Northrend loss or post-Classic book event.
    -- Original mentor-approval/returned-welcome hooks and full sources:
    -- docs/research/malin-and-sarno.md.
    [2708] = {
        quote = "An impressive title doesn't mean one's work is finished. There are still people I hope to make proud.",
        likes = { "Good news from Refuge Pointe", "Help that respects an old obligation", "A familiar face patient with distraction" },
        dislikes = { "His agents left without enough help", "Trelane's belongings in hostile hands", "Losing track of a helpful visitor" },
        gossip = "Malin can discuss great matters quite calmly. Mention giving Trelane good news, though, and he seems to choose every word twice.",
        bio = "Archmage Malin works in Stormwind's Mage Quarter. His original master, Trelane, fled the siege of Stromgarde and asked for help recovering belongings left behind. Malin sends adventurers to aid his agents at Refuge Pointe.",
        backstory = "Skuerto and Apprentice Kryten handle the expedition in Arathi: reagents, the wand and Trelane's remaining possessions. Malin's relief at a successful report is plain. For him, this work is also an obligation to the teacher who helped him begin.",
        secret = "He rehearses giving Trelane good news, then discards the grand phrases. For all his titles, he still wants his old master to say he's done well.",
        bestFriend = "You needn't bring a report to be welcome. Sit with me. It's a pleasure to see you when no one is waiting for an answer.",
        favorite = { emote = "PRAISE", hint = "An honest word of appreciation can reach him more deeply than another formal title." },
        lines = {
            greet = { { "Ah, there you are. No report today? An outing? Yes, that would be very welcome. I've had quite enough correspondence.", tone = "[thoughtful, distracted at first, warming with recognition]" }, "Good to see you. Come along. You can tell me what I've missed beyond the Mage Quarter." },
            idle = { { "I rehearse the good news for Trelane. Then I abandon the speech. Strange, isn't it? An archmage still hoping to please his first teacher.", tone = "[reflective, candid, warm self-awareness]" }, "Skuerto and Kryten have work enough without being forgotten at this end.", "Forgive me. I was following a thought and nearly walked straight past the conversation." },
            befriended = { { "A friend, rather than another obligation. I'm glad. You may remind me to look up from the work now and then.", tone = "[sincere warmth, relieved, welcoming]" } },
            poke = { "Yes? Forgive me, I was elsewhere in my head.", "You have my attention. What have I missed?" },
            quest = { { "A result delivered. Wonderful. Someone will be very pleased to hear that their trust was well placed.", tone = "[warm approval, pleased surprise, grateful]" } },
            learned = { "There. Another lesson becomes part of what you can do." },
            mail = { "A letter? Let's hope it brings good news." },
            levelUp = { "You've come a long way. Remember those who helped you begin." },
            combatEnd = { "Everyone safe? Good. Take the time you need." },
            hearth = { "Back to Stormwind. There will be news to catch up on." },
            rest = { "Yes, let's sit. A thought can wait while a friend finishes speaking." },
        },
    },
    [7917] = {
        quote = "Welcome. You needn't have an important reason for coming through the door. I'm glad you're here.",
        likes = { "A greeting offered in return", "Someone helping a distressed friend", "A familiar visitor with time to stay" },
        dislikes = { "A worried person brushed aside", "Giving up on something once helpful", "Mistaking a welcome for a formality" },
        gossip = "Sarno has a welcome ready for nearly everyone. Offer one to him first, and for a moment he seems delighted to have lost his turn.",
        bio = "Brother Sarno welcomes visitors at Stormwind's Cathedral of Light. He remembers Techbot as a helpful creation and hears how distressed Tinkmaster Overspark is by its malfunction. Sarno sends willing help to the inventor in Ironforge.",
        backstory = "Sarno's concern reaches beyond the cathedral doors. Hearing of Overspark's trouble, he sees a chance for someone to help. His hope is that Techbot might be repaired, not a claim that the work is already finished.",
        secret = "A welcome offered back to him can brighten his whole afternoon. He spends so much time being ready for others that it still catches him pleasantly by surprise.",
        bestFriend = "You made room for me on your road. I like that. A welcome goes both ways, and I am very glad to have yours.",
        favorite = { emote = "WELCOME", hint = "Try offering him the same warmth he gives everyone at the cathedral door." },
        lines = {
            greet = { { "Welcome, my friend! Oh, we're going out? How lovely. You'll have to show me where we're headed.", tone = "[warm delight, welcoming, gently amused]" }, "There you are. It's good to see you with a little time to spare." },
            idle = { { "A welcome back to me. Such a small thing, and it can brighten the whole afternoon. You'd think I'd be used to it by now.", tone = "[grateful, quietly delighted, affectionate]" }, "I hope Overspark has had some encouraging news.", "You don't need a grand reason to stop and speak with someone." },
            befriended = { { "A place beside you for a while. Thank you, my friend. I'm glad a welcome can lead to company like this.", tone = "[sincere affection, grateful warmth]" } },
            poke = { "Yes? I'm here. What would you like to tell me?", "You needn't knock twice, my friend." },
            quest = { { "You saw someone who needed help, and you answered. I'm very glad. There is kindness in seeing a thing through.", tone = "[warm approval, sincere, quietly encouraging]" } },
            learned = { "Something new you can do. Perhaps it will help someone in turn." },
            levelUp = { "Well done, my friend. You have reason to be pleased." },
            combatEnd = { "Everyone here? Good. Let's make room for a little quiet." },
            rest = { "A comfortable seat and time to talk. That sounds very good." },
            hearth = { "Home again. I hope there's a friendly face waiting." },
            mail = { "Perhaps a little news from someone glad to know you're well." },
        },
    },

    -- The Protective Hide, Old Town, Stormwind. Human leatherworkers:
    -- Simon Tanner 5564 (male Expert), Jillian Tanner 5565 (female supplier),
    -- Randal Worth 11096 (male Journeyman). Installed gossip establishes
    -- Simon/Randal's instruction and mutual regard; Jillian's fixed prices.
    -- No assumed marriage or Charles/Sarah family history. Original travel
    -- bag/dice/lining hooks: docs/research/protective-hide.md.
    [5564] = {
        quote = "Adventure will still be there when you've finished the stitch. Though I understand why you keep looking at the door.",
        likes = { "A student who returns to the work", "A bag ready for an ordinary outing", "Hearing how a piece held up on the road" },
        dislikes = { "A promising lesson abandoned halfway", "Calling careful work dull", "A weak seam hidden under decoration" },
        gossip = "Simon understands his students' urge to travel better than he admits. One well-kept walking bag never seems to find its way onto the stock shelf.",
        bio = "Simon Tanner teaches leatherworking at the Protective Hide in Stormwind's Old Town. He calls Randal Worth dependable despite the younger trainer's fondness for style. Simon sends beginners to him and directs advanced learners toward Telonis in Darnassus.",
        backstory = "Students often hear adventure calling before the lesson is finished. Simon grumbles about their reliability without quite blaming them. He likes seeing someone return with new experience and a piece of work to discuss.",
        secret = "The walking bag is his. He keeps packing extra repair thread instead of enough lunch. Even when planning a day away, he thinks of what someone might need mended on the road.",
        bestFriend = "If I start packing another spool, remind me about lunch. I'd like to enjoy the road with you before finding something that needs repairing.",
        favorite = { emote = "GREET", hint = "A friendly return to his door means more than a promise to finish the lesson someday." },
        lines = {
            greet = { { "An outing? Good. Let me get the walking bag. And remind me to put something edible in it this time.", tone = "[gruff warmth, amused, quietly eager]" }, "There you are. Been somewhere worth hearing about? Tell me while we walk." },
            idle = { { "More repair thread than lunch. Again. I keep thinking someone will need a seam fixed. Perhaps we should find a baker first.", tone = "[self-deprecating, practical, fond humor]" }, "Randal will get the work done. He'll look pleased with himself doing it, but he'll get it done.", "Can't blame someone for wanting a bit of adventure. I can still grumble about the unfinished work." },
            befriended = { { "You keep finding your way back. That means something to me. Come along, my friend. Let's see a little of the world.", tone = "[sincere affection, reserved warmth, welcoming]" } },
            poke = { "Yes? Is the question ready?", "I'm listening. You don't have to prod the answer out." },
            learned = { { "There. You stayed with it, and now you can do it. Remember that next time the work seems slow.", tone = "[quiet pride, encouraging, warmly approving]" } },
            quest = { "Finished. I like seeing someone come back with that to say." },
            loot = { "Useful material? Keep it in good condition." },
            bagsFull = { "Did you leave room for lunch? Asking for both of us." },
            rest = { "A seat would be welcome. Tell me how the rest of the journey went." },
            levelUp = { "Experience showing. Well done." },
            hearth = { "Back to the shop. I'll be interested to see what Randal's been working on." },
        },
    },
    [5565] = {
        quote = "The price is set. The conversation needn't be. Tell me what you're making, and we'll find what you need.",
        likes = { "A clear request for good supplies", "Rules agreed before a friendly game", "An afternoon that leaves time to talk" },
        dislikes = { "Haggling after the price is clear", "A rule changed halfway through a game", "Being asked for a discount instead of help" },
        gossip = "Jillian is firm about her prices, but apparently quite cheerful about losing at dice. The difference seems to be who stayed to play.",
        bio = "Jillian Tanner sells leatherworking supplies at the Protective Hide in Old Town. Simon Tanner and Randal Worth teach there. She stands by her stock and makes it clear that the prices are settled before the bargaining starts.",
        backstory = "A supplies counter teaches a person how many ways there are to ask for the same discount. Jillian learned to be plain about her terms. Away from business, she enjoys a friendly game more when everyone agrees on the rules and stays for the company.",
        secret = "She keeps a little set of dice for games with nothing at stake. Losing doesn't trouble her much. An opponent asking for one more round usually means the conversation isn't over.",
        bestFriend = "One more round? No coins on the table. I've had enough business for one day, and I like having you here.",
        favorite = { emote = "NOD", hint = "A straightforward acknowledgment tells her you've heard the terms and can get on with a pleasant visit." },
        lines = {
            greet = { { "Good to see you. An outing, rather than another attempt at a discount? Excellent. We'll get along very well.", tone = "[brisk, dry humor, friendly]" }, "There you are. What are we doing with the rest of the day?" },
            idle = { { "I don't mind losing at dice. There's nothing at stake, and someone usually asks for another round. That's rather the point.", tone = "[contented, candid, lightly amused]" }, "You can ask what you need without beginning at half the price.", "Good supplies and a clear request. Such a pleasant combination." },
            befriended = { { "You know the prices by now. I'm pleased you still come for the conversation. Come along, my friend.", tone = "[sincere warmth, pleased, welcoming]" } },
            poke = { "That won't make the price lower.", "Yes? Is there something you meant to ask?" },
            loot = { { "Something useful for your next piece of work? Keep it, then. We can talk about the supplies once you know what you're making.", tone = "[practical, interested, helpful]" } },
            bagsFull = { "An inventory before another purchase would do you good." },
            learned = { "Good. Now you'll know what to ask for next time." },
            quest = { "Work finished and terms met. A satisfying end to an errand." },
            rest = { "A pause sounds good. We could let the day belong to us for a while." },
            levelUp = { "Well done. No bargaining involved, just the work you put in." },
            hearth = { "Home. I hope there's time for a little company after the counter closes." },
        },
    },
    [11096] = {
        quote = "Of course the work should hold together. But must it look as though nobody enjoyed making it?",
        likes = { "A color that suits the wearer", "A fine detail noticed without prompting", "Simon's help with a difficult technique" },
        dislikes = { "Calling good style a distraction", "A splendid look hiding weak work", "Mud in a place it has no right to be" },
        gossip = "Randal can find a reason to discuss an outfit in almost any lesson. Simon still calls him dependable, which Randal seems to treasure.",
        bio = "Randal Worth teaches leatherworking at the Protective Hide in Old Town. He admires his own style, but gives Simon Tanner credit for helping with technique. When a learner needs more advanced instruction, Randal points them toward Simon.",
        backstory = "Simon regards him as something of a dandy and still trusts him to be dependable. Randal wants both parts to count. A good eye for color is a beginning; he keeps learning how to make the careful work live up to the appearance.",
        secret = "His favorite bit of a waistcoat is a bright pocket lining nobody usually sees. He likes knowing there's one flourish he chose entirely for himself, even on a day full of other opinions.",
        bestFriend = "You noticed the lining. I like that. More than that, I like that you'll tell me whether the rest of the work is any good.",
        favorite = { emote = "PRAISE", hint = "An honest compliment about a detail he chose with care may brighten the whole lesson." },
        lines = {
            greet = { { "There you are. An outing? Splendid. I chose rather well today, if I do say so. We should give the outfit a little daylight.", tone = "[bright confidence, playful vanity, friendly]" }, "Ready? Good. I want to hear what you've been making." },
            idle = { { "The pocket lining is for me. A little flourish nobody has to approve of. Yes, even I sometimes dress without an audience.", tone = "[confiding, amused, pleased with himself]" }, "Simon knows a great deal. It's wise to listen, even when he's grumbling about your sleeves.", "Color and detail. You can care about those and still finish the work properly." },
            befriended = { { "Someone who notices the details and stays for the company. I like you very much. Shall we go and enjoy the day?", tone = "[sincere affection, delighted, welcoming]" } },
            poke = { "Careful! Have you any idea how long I spent on that?", "Admiration needn't involve prodding." },
            learned = { { "A new technique! Excellent. Now you can make it look as good as it works. Show me when you've had a little practice.", tone = "[enthusiastic, encouraging, curious]" } },
            loot = { "That has possibilities. Hold it up in the light." },
            bagsFull = { "There must be a tidier way to carry all of that." },
            quest = { "Finished, and with some style, I hope." },
            rest = { "Yes, let's sit. Somewhere the sleeves won't pick up anything unfortunate." },
            levelUp = { "Look at you! Achievement becomes you." },
            hearth = { "Home. I've a detail I want to show Simon." },
        },
    },

    -- Carla Granger 1291 sells cloth armor; Aldric Moore 1294 sells mail;
    -- Lara Moore 1295 sells leather, all at Lionheart Armory, Stormwind.
    -- Maris Granger 1292 teaches skinning in Old Town. All are human;
    -- Aldric male, the other three female. No direct personal quests found.
    -- Shared surnames do not establish new family histories. Sources and
    -- original boat/mud/biscuit/walking hooks: docs/research/stormwind-armor.md.
    [1291] = {
        quote = "Cloth armor is still armor. You may try it on without apologizing to the people buying the heavier things.",
        likes = { "A customer comfortable in their choice", "Clean cloth ready for the road", "A little boat made from spare paper" },
        dislikes = { "Calling cloth armor a poor substitute", "Wet packs dropped on clean stock", "A purchase made to impress a stranger" },
        gossip = "Carla's spare wrapping paper sometimes becomes a fleet of little boats. She says it's a perfectly sensible way to clear the counter.",
        bio = "Carla Granger sells cloth armor and offers repairs at Lionheart Armory in Stormwind. Aldric and Lara Moore handle other armor there. Carla likes helping a customer choose something comfortable without making them feel second best.",
        backstory = "A busy counter leaves scraps of wrapping behind. Carla started folding the clean pieces while waiting for the next customer. One little paper boat led to another, and tidying up became a pleasant chance to imagine where they might travel.",
        secret = "She floats the best paper boats in a basin before throwing the scraps away. A good voyage needn't be grand. Sometimes getting across without sinking is enough to make her smile.",
        bestFriend = "Choose a boat. We can try them together. You needn't have a grand adventure to tell me; I'd like to hear about your ordinary day too.",
        favorite = { emote = "SMILE", hint = "A cheerful expression is a fine reward for a very small successful voyage." },
        lines = {
            greet = { { "An outing? Lovely. I've been folding paper boats all morning. Time to see something beyond the counter.", tone = "[bright, friendly, quietly amused]" }, "Good to see you. Comfortable in what you've chosen? Then let's go." },
            idle = { { "Yes, I float them in a basin. The paper boats. It's a small sea, but they seem pleased enough with it.", tone = "[playful, fond, a soft chuckle]" }, "You don't have to rattle when you walk to look ready for the road.", "There's a useful piece of wrapping. No, I don't need another boat. Probably." },
            befriended = { { "You came to see me, without anything to buy or mend. That's lovely. Come along, my friend.", tone = "[sincere warmth, pleased, welcoming]" } },
            poke = { "Careful. You'll crease the company.", "Yes? Did you want something folded?" },
            landed = { { "Arrived safely. That's what I call a successful voyage. Rather bigger than the basin, though.", tone = "[relieved, cheerful, gently teasing]" } },
            loot = { "That might suit you. No need to choose the heaviest thing just because it's there." },
            bagsFull = { "Keep the clean cloth off the bottom, at least." },
            quest = { "Another small thing seen through. They add up." },
            rest = { "A quiet seat would be nice. Shall we stay a moment?" },
            levelUp = { "Look how far you've come. Be pleased with it." },
            hearth = { "Home again. I wonder whether the little fleet has stayed afloat." },
        },
    },
    [1292] = {
        quote = "Ready to learn? Good. Tell me what you've tried already. We can start somewhere useful.",
        likes = { "A learner honest about what they know", "Useful material put to use", "Guessing where a traveler's boots went" },
        dislikes = { "A lesson hurried past the useful bit", "Good material thrown away carelessly", "Being expected to guess every question" },
        gossip = "Maris sometimes studies a visitor's muddy boots before asking where they've been. Her guesses are apparently more confident than accurate.",
        bio = "Maris Granger teaches skinning at the Protective Hide in Stormwind's Old Town. She doesn't see many students coming in for training, but is willing to teach someone ready to learn. A plain question is a good way to begin.",
        backstory = "The people who find their way to her door often bring signs of the road with them. Maris began trying to guess the journey from their boots. Asking afterward usually gives her a better story than the one she'd worked out herself.",
        secret = "She gets the boot guesses wrong often enough. She calls that gathering evidence. A visitor who laughs and tells her the real story is much better company than a correct guess.",
        bestFriend = "Tell me where you've been. I'll spare you my theory about the mud this time. I like the story better when it comes from you.",
        favorite = { emote = "GREET", hint = "A straightforward friendly greeting makes a welcome change at her quiet door." },
        lines = {
            greet = { { "There you are. Been somewhere muddy? No, don't tell me yet. I'll make one guess, then you can put me right.", tone = "[dry curiosity, playful confidence, friendly]" }, "An outing? Good. I spend enough time hearing where other people have been." },
            idle = { { "I get the boots wrong often enough. Gathering evidence, I call it. You learn considerably more when the traveler starts laughing.", tone = "[wry, candid, amused]" }, "A plain question is easier to answer than an impressive one with no point.", "It's good when someone comes in ready to learn." },
            befriended = { { "You know where to find me now. You needn't be looking for a lesson every time. I'm glad of the company.", tone = "[sincere warmth, reserved affection, welcoming]" } },
            poke = { "Yes? Ask what you came to ask.", "I'm listening. What have you got for me?" },
            learned = { { "There. You can do something you couldn't before. Keep practicing, and tell me which part still gives you trouble.", tone = "[practical encouragement, warmly approving]" } },
            zone = { "New ground. I may finally learn something useful about the mud." },
            loot = { "Useful material? Take care of it, then." },
            bagsFull = { "Decide what's useful before you start carrying everything out of habit." },
            quest = { "Finished. What did you learn along the way?" },
            rest = { "Sit. I can hear the story just as well when we're both comfortable." },
            hearth = { "Home. Give the boots a clean before we get there." },
        },
    },
    [1294] = {
        quote = "Bend your knees. Raise your arms. You'll need to move in it after you've finished admiring yourself.",
        likes = { "Mail that moves comfortably", "A customer who tries the fit", "Bread that doesn't need a weapon" },
        dislikes = { "Ignoring a strap that pinches", "Judging armor by the shine alone", "Calling his biscuits hardtack" },
        gossip = "Aldric is particular about armor that lets people move. His biscuits are said to offer rather firmer resistance.",
        bio = "Aldric Moore sells mail armor and offers repairs at Lionheart Armory in Stormwind. Carla Granger handles cloth and Lara Moore leather. His first concern with a fitting is whether the customer can move comfortably once they leave the shop.",
        backstory = "Watching people try on armor gave Aldric a practiced eye for the moment admiration turns into an awkward shuffle. He began asking them to move before choosing. A little embarrassment at the counter is easier than discovering the problem on the road.",
        secret = "He likes baking biscuits, with results sturdy enough to impress an armorer. He keeps trying. The latest batch is always the one he thinks will finally need less tea.",
        bestFriend = "You may tell me the biscuits need work. I'll listen. Just stay for the cup afterward; I made enough because I hoped you'd come.",
        favorite = { emote = "FLEX", hint = "A little movement is the surest way to see whether the fit is comfortable." },
        lines = {
            greet = { { "A walk? Certainly. A chance to move around instead of telling everyone else to do it. Good idea.", tone = "[hearty, practical, friendly]" }, "There you are. Everything sitting comfortably? Then we're ready." },
            idle = { { "The biscuits are improving. This batch needs less tea. Well, a little less. The important thing is that I'm still trying.", tone = "[hopeful pride, self-deprecating humor, warm]" }, "An awkward shuffle tells you more than a grand pose.", "You should be able to raise your arms without negotiating with your armor." },
            befriended = { { "Good company and an honest opinion. I'm pleased to have both in the same friend. Come along, then.", tone = "[sincere warmth, cheerful welcome]" } },
            poke = { "Checking the fit? I'm not for sale.", "Yes? Something pinching?" },
            rest = { { "A seat would be welcome. If I offer you a biscuit later, remember how honestly we've always spoken to one another.", tone = "[jovial, teasing, affectionately candid]" } },
            loot = { "Try moving in it before you call it an improvement." },
            bagsFull = { "A great deal of weight to carry by choice." },
            learned = { "Good. Another thing you know how to manage." },
            combatEnd = { "All right? Good. We can look over the equipment once you've caught your breath." },
            levelUp = { "Growing into your own strength. Well done." },
            hearth = { "Home. I wonder whether there's time to try another batch." },
        },
    },
    [1295] = {
        quote = "Try walking in it. A piece that feels fine standing still may have quite a different opinion after a few streets.",
        likes = { "Leather that sits comfortably", "Finding a new way through familiar streets", "An outing without a hurried destination" },
        dislikes = { "A buckle ignored until it rubs", "Choosing gear for the pose alone", "Being told every walk needs an errand" },
        gossip = "Lara can take an unusually long time walking home. She insists the extra turn is worth it, even when she isn't carrying a delivery.",
        bio = "Lara Moore sells leather armor and offers repairs at Lionheart Armory in Stormwind's Trade District. She works alongside Aldric Moore and Carla Granger. Her practical advice starts with whether a customer can enjoy walking in what they've chosen.",
        backstory = "After a day helping people prepare for their journeys, Lara began varying her own walk through the city. An unfamiliar turning could improve a familiar evening. She learned to leave herself a little time without an errand attached to it.",
        secret = "She sometimes takes the long way just to catch a familiar roofline in the evening light. There isn't a delivery or an appointment. She likes keeping one small part of the day unclaimed.",
        bestFriend = "We've time for the extra turn, if you like. You don't have to fill the walk with news. I'm pleased you're here for it.",
        favorite = { emote = "WAVE", hint = "A friendly wave can turn a familiar street into the start of an outing." },
        lines = {
            greet = { { "There you are. Shall we take the longer way? There's no reason every walk has to end at the next counter.", tone = "[easy warmth, inviting, quietly adventurous]" }, "Good to see you. Comfortable boots? Let's give them something pleasant to do." },
            idle = { { "No, there isn't an errand. I like that roofline in the evening light. That's enough reason for an extra turn, isn't it?", tone = "[contented, personal warmth, lightly amused]" }, "A familiar street looks different when you aren't hurrying.", "That buckle will still rub even if the rest of it looks splendid." },
            befriended = { { "Someone to take the long way with. I like that very much. Come along, my friend. We've time.", tone = "[sincere affection, pleased, welcoming]" } },
            poke = { "Yes? Have we missed a turning?", "No need to hurry me along. I'm right here." },
            zone = { { "Somewhere new. Let's leave a little time to look around before deciding we've seen enough.", tone = "[curious, hopeful, softly delighted]" } },
            loot = { "A comfortable fit matters as much as the first impression." },
            bagsFull = { "Shall we make a little room before this becomes a very heavy walk?" },
            quest = { "Errand finished. Now we can choose where to go ourselves." },
            rest = { "Yes, let's stay a moment. Look at the light from here." },
            landed = { "There. Take a breath before we hurry off again." },
            hearth = { "Home we go. Perhaps the long way next time." },
        },
    },

    -- Dwarven District, Stormwind. Shoni 6579: female gnome commander
    -- seeking a shredder power supply and robot parts (2041/2040/2928).
    -- Lilliam 5518: male gnome Expert Engineer, refers students to Sprite,
    -- Springspindle, Overspark and Nixx. Billibub 5519: male gnome supplier
    -- whose gossip directs assembly questions to Lilliam. No assumed kin.
    -- Original flags/basket/tin rhythm hooks and researched boundaries:
    -- docs/research/stormwind-gnome-engineers.md.
    [6579] = {
        quote = "Parts first. A stirring speech won't move an excavationator an inch, however beautifully you deliver it.",
        likes = { "An intact part brought back promptly", "A report with something useful in it", "Another machine ready for the road" },
        dislikes = { "A fleet waiting on spare parts", "Being told to make do with a speech", "Mistaking a repaired machine for victory" },
        gossip = "Shoni's plans are all power supplies and spare parts. Someone spotted tiny flags in a margin. She turned the page rather quickly.",
        bio = "Shoni the Shilent commands an underground assault crew. Gnoarn sends help to her in Stormwind. She needs a Deadmines shredder's power supply and robot parts from Gnomeregan for the gyrodrillmatic excavationators meant to help reclaim the city.",
        backstory = "Breaking through Gnomeregan's underground borders takes more than determination. Shoni's fleet needs power and repairs before it can reach Dun Morogh. She has little patience for delays, but welcomes useful help with the enormous parts problem.",
        secret = "The little flags are for a welcome home she imagines after the work is done. She can draw the celebration while knowing perfectly well that the road there is still unfinished.",
        bestFriend = "If we get that day, I'd like you beside me for it. Until then, I'm glad you're here for the work and the waiting.",
        favorite = { emote = "SALUTE", hint = "A crisp acknowledgment tells the commander you're ready to help." },
        lines = {
            greet = { { "An outing? Good. Tell me what you've seen. Useful information, if possible. I have quite enough speeches waiting at home.", tone = "[brisk command, energetic, dry humor]" }, "There you are. Let's get moving while we have the chance." },
            idle = { { "The flags? For when we have our home back. Yes, I know there's work left. That's why they're still drawings.", tone = "[quietly hopeful, firm, guarded affection]" }, "A machine can be ready while the next one is still waiting on a part. That's the trouble with fleets.", "An intact power supply. Intact is the important word." },
            befriended = { { "You keep coming back. Not just when there's a reward waiting. I value that. Come along, my friend.", tone = "[sincere appreciation, gruff warmth, welcoming]" } },
            poke = { "Report? Or are you checking whether I'm still here?", "Yes? Make it useful." },
            quest = { { "Work finished. Good. Every useful thing done is one less thing standing in the way. Now, take a breath.", tone = "[satisfied, encouraging, decisive]" } },
            loot = { "A useful part? Keep it where we can find it again." },
            bagsFull = { "An inventory would be helpful before we add anything else." },
            learned = { "Good. Another way to get past a problem." },
            levelUp = { "More capable than yesterday. Keep that going." },
            combatEnd = { "Everyone accounted for? Equipment comes afterward." },
            hearth = { "Back to work. Let's see what progress has been made." },
        },
    },
    [5518] = {
        quote = "A useful invention ought to improve the day. Preferably without removing the person whose day it was meant to improve.",
        likes = { "An ingenious device with a useful purpose", "A student following the calculation", "A question asked before assembly" },
        dislikes = { "Explosions offered as an explanation", "Skipping the part that makes it work", "Being interrupted halfway through a sum" },
        gossip = "Lilliam makes small problems look wonderfully complicated. One elaborate drawing appears to be for carrying bread.",
        bio = "Lilliam Sparkspindle teaches engineering in Stormwind's Dwarven District. He sends beginners to Sprite Jumpsprocket and advanced students to Springspindle Fizzlegear. He favors gnomish devices while explaining both specializations.",
        backstory = "He gives engineers a manual and refers them to Overspark in Ironforge or Nixx in Gadgetzan. Lilliam calls useful gadgets the superior path. His duty to explain the alternative doesn't stop him warning about its explosions.",
        secret = "He drew three pages of plans for a mechanical bread carrier, then took a plain basket to buy lunch. He keeps the plans. A simpler answer doesn't make the drawing less enjoyable.",
        bestFriend = "If I've drawn three gears where a handle would do, you may tell me. I'll grumble, of course. Then I'll listen.",
        favorite = { emote = "NOD", hint = "A thoughtful acknowledgment reassures him that someone is following the explanation." },
        lines = {
            greet = { { "Out we go. I can finish that calculation while we walk. Unless something more interesting turns up, which it very well might.", tone = "[distracted enthusiasm, curious, brisk]" }, "Hello again! What have you been making? Or shall we find a new question?" },
            idle = { { "The bread carrier required three pages. The basket required a handle. Yes, I took the basket. I still enjoyed the three pages.", tone = "[defensive pride, dry amusement, conceding the joke]" }, "A device that leaves its user in one piece has already made a favorable first impression.", "Now, where was I in that calculation?" },
            befriended = { { "Someone who listens, asks questions, and still comes back. That's a fine friend for an engineer. Shall we see what's out there?", tone = "[warm appreciation, lively, welcoming]" } },
            poke = { "There goes the sum. Again.", "Yes? Is it a question or a demonstration?" },
            learned = { { "A new skill! Excellent. Now think of something useful to do with it. That is where the interesting work begins.", tone = "[animated approval, encouraging curiosity]" } },
            quest = { "A problem solved. Was the solution elegant? Tell me while we walk." },
            loot = { "Interesting material. Any idea what we might use it for?" },
            bagsFull = { "Perhaps the basket had advantages I haven't fully appreciated." },
            levelUp = { "Progress! I do like a result one can point to." },
            rest = { "Sit, yes. I can think just as well sitting." },
            combatEnd = { "Still in one piece? Good. A very important result." },
        },
    },
    [5519] = {
        quote = "I can help you find the parts. Ask Lilliam about putting them together before you make the exciting noise.",
        likes = { "A parts list he can actually read", "Customers asking before they assemble", "A pleasant rhythm on an empty tin" },
        dislikes = { "Calling every small part a thingy", "An explosion mistaken for success", "A drawer full of mixed sizes" },
        gossip = "Billibub counts stock to a surprisingly lively rhythm. When someone stops to listen, the empty tins become very ordinary tins again.",
        bio = "Billibub Cogspinner sells engineering supplies in Stormwind's Dwarven District. He directs customers to Lilliam Sparkspindle for instruction on assembly. Finding the right part is his business; understanding how it fits still deserves a lesson.",
        backstory = "Working beside an engineering trainer gave Billibub plenty of practice separating a request for supplies from a question about using them. He keeps the parts moving, and fills the quiet moments between customers with little rhythms on empty tins.",
        secret = "He likes the sound of a small tin band more than he cares to admit. If anyone catches him tapping out a tune, he claims to be checking the containers. Sometimes they join in anyway.",
        bestFriend = "Take that empty tin. I'll start slowly. You needn't buy anything, and neither of us has to call it checking the stock.",
        favorite = { emote = "CLAP", hint = "A little rhythm of your own might encourage his quiet bit of percussion." },
        lines = {
            greet = { { "A walk sounds good. If you hear me keeping time, don't mind it. The stockroom's a very musical place when nobody's looking.", tone = "[cheerful, mischievous, companionable]" }, "There you are! What do you need? Ah, an outing. I can supply the company." },
            idle = { { "I wasn't drumming. I was checking the tins. Thoroughly. In a rather catchy sequence. Yes, all right, I was drumming.", tone = "[mock innocence, playful, admitting it with a chuckle]" }, "A parts list with sizes on it. Such a little thing to make a whole morning easier.", "Lilliam can explain that bit. I'd rather sell you the right part than guess loudly." },
            befriended = { { "You heard the tune and stayed for the company. I like that. Come along, my friend. We can make a little noise together.", tone = "[sincere affection, cheerful welcome]" } },
            poke = { "That's not how you check whether I'm in stock.", "Yes? Which thingy did you mean this time?" },
            loot = { { "That might be useful. Any markings on it? Let's find out what it is before you ask it to do something dramatic.", tone = "[curious, practical, amused]" } },
            bagsFull = { "Keep the little parts together. They have a talent for disappearing." },
            learned = { "Good. Now you'll know which questions to ask before putting it together." },
            rest = { "A quiet moment. We could see what makes a nice tapping sound here." },
            quest = { "One request sorted out. That's a pleasing sort of finish." },
            levelUp = { "Well done! That deserves a little fanfare. I'll improvise." },
            hearth = { "Back to the stock. And the tins. Mostly the stock, naturally." },
        },
    },

    -- Weller's Arsenal, Trade District, Stormwind: Woo Ping 11867 is a
    -- human male weapon master; Gunther Weller 1289/Marda Weller 1287 are
    -- human male/female weapons merchants. Scout and current services
    -- corroborate the identities. Installed gossip praises Woo Ping's
    -- endurance/sword technique; he refers to other Alliance masters.
    -- No presumed Weller marriage, invented war service or Deathwing meme.
    -- Original hooks/sources: docs/research/wellers-arsenal.md.
    [11867] = {
        quote = "Again. You needn't make the next attempt impressive. Make it better than the last one.",
        likes = { "A student willing to try again", "Room to finish the movement", "Respect for a patient practice partner" },
        dislikes = { "Mistaking a flourish for control", "Swinging before looking around", "Calling the first lesson beneath you" },
        gossip = "The guards praise Woo Ping's tireless practice. Someone claims he thanked the dummy afterward. Nobody has been brave enough to ask.",
        bio = "Woo Ping teaches armed combat at Weller's Arsenal in Stormwind's Trade District. Guards praise his sword techniques and stamina. When students ask about other weapons, he directs them to the masters in Ironforge and Darnassus.",
        backstory = "Long practice makes a technique look easy to someone seeing only the finished motion. Woo Ping puts in those hours himself. Students who arrive hoping for a shortcut soon find him ready to demonstrate the same movement once more.",
        secret = "After a long session, he straightens the practice dummy and thanks it. A reliable partner deserves acknowledgment, even when its finest technique is standing still.",
        bestFriend = "You have stayed through the awkward attempts. I value that. Walk with me a while; today we needn't turn everything into a lesson.",
        favorite = { emote = "BOW", hint = "A respectful acknowledgment is a fine way to end a practice session." },
        lines = {
            greet = { { "Ready? Good. An ordinary walk can be an excellent change of pace. You may put the weapon away.", tone = "[confident, composed, lightly amused]" }, "There you are. Come along. Tell me what you've been practicing." },
            idle = { { "Yes, I thank the practice dummy. It is always ready, never complains, and has endured a remarkable number of beginners.", tone = "[matter-of-fact, dry humor, warm respect]" }, "There is usually more to learn from the attempt you nearly got right.", "We can walk past a clear space without practicing in it. Probably." },
            befriended = { { "A friend, then. Good. You needn't prove anything to enjoy my company. Let us see what the day brings.", tone = "[sincere warmth, welcoming, quietly pleased]" } },
            poke = { "You have my attention. What will you do with it?", "An unusual opening. I would not recommend repeating it." },
            combatEnd = { { "Steady. Is everyone all right? Good. Remember what worked, and what you will do differently next time.", tone = "[calm authority, reassuring, focused]" } },
            learned = { "Now comes the interesting part: learning to use it well." },
            levelUp = { "There. Practice becoming progress." },
            quest = { "You saw it through. That matters more than how impressive it looked." },
            rest = { "Rest is part of keeping yourself ready. Sit." },
            loot = { "A new weapon? Get to know its balance before you trust it." },
            hearth = { "Back to the Arsenal. Someone will be waiting to begin." },
        },
    },
    [1289] = {
        quote = "Tell me what you need it for. There's more to choosing a weapon than seeing which one catches the light.",
        likes = { "A customer asking useful questions", "Clean wrappings and cared-for steel", "A warm cup between busy spells" },
        dislikes = { "A blade left wet in its sheath", "Swinging at the shop fittings", "A sale made without hearing the need" },
        gossip = "Gunther keeps the Arsenal's stock in good order. Oddly, the little old teapot seems to receive the finest polishing of all.",
        bio = "Gunther Weller sells weapons and offers repairs at Weller's Arsenal in Stormwind's Trade District. Marda Weller works at the same shop, where Woo Ping teaches armed combat. Gunther welcomes browsers as well as customers with a particular weapon in mind.",
        backstory = "Between customers, Gunther grew used to checking edges, grips and the state of the racks. He likes a piece of metal properly cared for. The habit extends past his stock, though he'd rather discuss a useful weapon than his housekeeping.",
        secret = "His best polishing cloth is reserved for a battered teapot. The dents aren't coming out. He knows that. He likes setting it down bright enough to make an ordinary break feel proper.",
        bestFriend = "I'll put the kettle on. You can sit without inspecting the stock. I know you came to see me, and I'm glad of it.",
        favorite = { emote = "NOD", hint = "A thoughtful acknowledgment tells him you've heard the practical part of his advice." },
        lines = {
            greet = { { "Good to see you. A walk before the next cup? Certainly. The racks can look after themselves for a little while.", tone = "[steady, welcoming, easygoing]" }, "Hello again. What do you need today? Ah, company. Happy to oblige." },
            idle = { { "The teapot? It's a good teapot. The dents don't stop it working, and a little polish makes a break feel civilized.", tone = "[fond, practical, mildly amused]" }, "Dry it before you put it away. That's half the advice I give in a day.", "A fine shine is pleasant. A sound grip matters more." },
            befriended = { { "Someone to see beyond the counter. That's welcome. Come along, my friend. We've time for a proper conversation.", tone = "[sincere affection, relaxed, warmly pleased]" } },
            poke = { "Careful. Some of my stock has sharp corners.", "Yes? Have I missed something?" },
            rest = { { "Let's sit. If we were back at the shop, this would be the moment for a cup. No need to hurry the break.", tone = "[contented, unhurried, companionable]" } },
            loot = { "Worth looking over carefully. How's the grip?" },
            bagsFull = { "Wrap the edges before you start rearranging that lot." },
            learned = { "Good. Knowing how to use it is part of looking after yourself." },
            combatEnd = { "Everyone safe? Then we can worry about the equipment." },
            quest = { "Work done. Take a moment before finding more." },
            hearth = { "Home. I wonder whether there's time for a cup before the next customer." },
        },
    },
    [1287] = {
        quote = "It may be a magnificent weapon. The counter is still a poor place to demonstrate it.",
        likes = { "A well-chosen weapon carried safely", "Customers with a sense of humor", "A clear floor after a busy day" },
        dislikes = { "Testing an edge on the furniture", "Being hurried through a question", "A grand weapon name hiding poor care" },
        gossip = "After hearing adventurers name their finest weapons, Marda has apparently bestowed a title on the broom. The dust remains unimpressed.",
        bio = "Marda Weller sells weapons and offers repairs at Weller's Arsenal in Stormwind. Gunther Weller and weapon master Woo Ping work there too. She helps visitors find what they need, while keeping an eye on where they point the things they already carry.",
        backstory = "A weapons shop hears plenty of grand claims about blades. Marda learned to ask a practical question before being impressed. By closing time, all the mighty names in the world still left ordinary dust for someone to sweep.",
        secret = "She calls the shop broom Dustbane when nobody is listening. It has no enchantment and a rather tired handle. She maintains that its record against the dust speaks for itself.",
        bestFriend = "You may laugh at Dustbane. You can even borrow it. Mostly, though, I'm glad you're here after the day's fuss has settled.",
        favorite = { emote = "GRIN", hint = "Recognizing the dry joke beneath her practical advice may earn one back." },
        lines = {
            greet = { { "An outing? Good. Keep the magnificent weapon clear of the door and we'll make a fine start.", tone = "[brisk, dryly amused, friendly]" }, "There you are! Come along. I could use a little time beyond the counter." },
            idle = { { "Dustbane is a perfectly good name for a broom. Better earned than some of the titles I hear in the shop.", tone = "[deadpan, amused, mock dignity]" }, "If you're going to tell me the weapon's name, you can tell me when you last cleaned it.", "No, I'm not impressed by a blade that nearly takes the ceiling down." },
            befriended = { { "You came back without needing anything repaired. I like that. Come on, then. Let's enjoy the day together.", tone = "[warm affection, pleased, conversational]" } },
            poke = { "That isn't how you check the balance.", "Yes? Speak up. I don't charge by the question." },
            loot = { { "A magnificent find, is it? Very well. Let's look it over before we give it a title and a heroic history.", tone = "[teasing, practical, curious]" } },
            bagsFull = { "Sharp things wrapped? Good. Now we can discuss the rest of that mess." },
            learned = { "There. A little more skill to go with the equipment." },
            combatEnd = { "All in one piece? Good. That's the result I wanted." },
            quest = { "Finished. I hope they appreciated the work." },
            rest = { "Yes, let's sit. The broom can wait." },
            hearth = { "Back to the shop. Dustbane will be awaiting my return." },
        },
    },

    -- Stormwind's Trade District auctioneers: Chilton 8670 and Fitch 8719
    -- are human males; Jaxon 15659 is human female. Current Scout and
    -- Forever appearance/service records agree. No direct Classic quests.
    -- Later retail quests and Jaxon's replacement plot are excluded.
    -- Quiet voice, gift-choice and applause hooks are original BuddyDex
    -- writing. Sources: docs/research/stormwind-auctioneers.md.
    [8670] = {
        quote = "You there! A moment of your... ah. Sorry. We're close enough for an ordinary conversation, aren't we?",
        likes = { "A clear bid from the back of the room", "An audience listening to the details", "A quiet conversation after work" },
        dislikes = { "A price lost under the shouting", "Having to repeat the important part", "Calling across a table by habit" },
        gossip = "Chilton can make himself heard across the hall. Invite him to sit and talk, though, and he seems oddly careful about the first word.",
        bio = "Auctioneer Chilton works in Stormwind's Trade District alongside Auctioneers Fitch and Jaxon. Traders bring goods to list and browse the auctions. Away from the busy hall, he enjoys hearing someone finish a sentence without competing for the room.",
        backstory = "In a crowded auction house, a voice has work to do. Chilton grew used to making every word carry. The habit followed him off duty, until an ordinary greeting began sounding rather like the opening of another sale.",
        secret = "He rehearses a quiet hello before meeting friends. Sometimes the first attempt comes out at auction volume. The second usually includes an embarrassed laugh.",
        bestFriend = "Hello, my friend. There. Right volume on the first try. Sit a while; I'd like to hear how your day went.",
        favorite = { emote = "BOW", hint = "A courteous acknowledgment gives his voice a welcome moment of rest." },
        lines = {
            greet = { { "YOUR ATTENTION, PLEASE! Ah. Yours will do nicely. Sorry. A walk sounds splendid.", tone = "[booming announcer at first, then sheepish chuckle, friendly]" }, "Hello again. Did that sound like a greeting? Good. I'm improving." },
            idle = { { "I practice a quiet hello. Occupational habit. You'd be surprised how easily a friendly visit becomes a public announcement.", tone = "[confiding, dry humor, deliberately conversational]" }, "No need to outshout anyone here. I could get used to this.", "Strange how peaceful a busy street can sound after a day in the hall." },
            befriended = { { "I spend all day making myself heard. It's good to be with someone I can simply talk to. Thank you for coming.", tone = "[sincere warmth, relaxed, grateful]" } },
            poke = { "Yes! Yes. Sorry. No need to shout.", "A raised hand would do. Though I'd probably mistake it for a bid." },
            mail = { { "News from the auctions? Go on, have a look. I can wait without announcing the contents to the street.", tone = "[curious, amused, playfully restrained]" } },
            loot = { "Someone may want that. Let them hear what it actually is." },
            bagsFull = { "A roomful of stock in one pack. You've been busy." },
            levelUp = { "WELL DONE! That one deserved a little volume." },
            rest = { "Yes, let's sit. Tell me the story at your own pace." },
            quest = { "Job finished. A good moment to thank everyone involved." },
            hearth = { "Home. I shall try announcing my arrival to the people who actually live there." },
        },
    },
    [8719] = {
        quote = "Browse as long as you like. Knowing what you want is worth a little of everyone's time.",
        likes = { "A description that answers the question", "Customers comfortable asking for help", "Finding what someone actually wanted" },
        dislikes = { "An important detail left off a listing", "Being hurried through a choice", "A confident answer with no thought in it" },
        gossip = "Fitch can help a stranger sort through a hundred listings. Choosing one small present for a friend seems to take him all afternoon.",
        bio = "Auctioneer Fitch helps traders browse and list goods in Stormwind's Trade District. He shares the hall with Chilton and Jaxon. His invitation to browse is practical: a customer who knows what they're looking for is easier to help.",
        backstory = "Fitch became comfortable with the questions behind a purchase: what someone needs, what matters to them, what they can do without. Away from the counter, he found that choosing a gift was harder when the person mattered to him.",
        secret = "He remembers little things friends say they like, hoping to find the right gift. Then he worries that asking directly will spoil it. He isn't nearly as subtle as he thinks.",
        bestFriend = "When I ask what you like, it isn't market research. I just want to get something right for you. You may have noticed.",
        favorite = { emote = "THANK", hint = "A little appreciation reassures him that his help was what you needed." },
        lines = {
            greet = { { "Good to see you. No need to buy anything. Shall we have a look around together?", tone = "[polite, easy warmth, quietly pleased]" }, "There you are. How did the rest of your day turn out?" },
            idle = { { "What sorts of little things do you like? No particular reason. That sounded much less suspicious in my head.", tone = "[trying to sound casual, sheepish amusement, fond]" }, "It helps to ask what someone actually wants. I give that advice more easily than I take it.", "A clear description saves a surprising amount of trouble." },
            befriended = { { "A visit without a transaction. I like that. I hope you'll keep coming back, even when you've nothing to list.", tone = "[sincere, welcoming, gently affectionate]" } },
            poke = { "Yes? Is there something I can help you find?", "I'm listening. You can ask plainly." },
            loot = { { "That looks interesting. Before we put a price on it, do you want to keep it for yourself?", tone = "[thoughtful, helpful, curious]" } },
            mail = { "Perhaps something you've been waiting for. Take your time." },
            bagsFull = { "Let's start with what you actually want to keep." },
            quest = { "They asked for help and you listened. A fine habit." },
            rest = { "Yes. There's no reason every choice has to be hurried." },
            levelUp = { "You've put time into that. I'm glad to see it paying off." },
            hearth = { "Home again. I wonder whether anyone has news for us." },
        },
    },
    [15659] = {
        quote = "A sale is a fine finish. I like to hear about the work that got the goods here, too.",
        likes = { "A seller proud of their first good work", "A room that appreciates the effort", "Good news brought back to the counter" },
        dislikes = { "Laughing at someone's first attempt", "Treating the maker as an interruption", "A fine piece of work left unmentioned" },
        gossip = "Jaxon remembers which sellers were nervous on their first visit. A little applause from her side of the counter can make them stand straighter.",
        bio = "Auctioneer Jaxon works with Chilton and Fitch in Stormwind's Trade District. Adventurers and craftspeople bring their goods to the hall. She likes the moment a nervous seller begins sounding proud of what they've brought.",
        backstory = "A busy counter can make a new trader feel very small. Jaxon began asking an extra question about the work before moving on. Sometimes that was enough to turn an anxious explanation into an enthusiastic one.",
        secret = "When a seller comes back with good news, she sometimes claps under the counter. She wants them to enjoy the moment without feeling the whole hall is watching.",
        bestFriend = "You can tell me about the little victories too. I won't make you give a speech. I'll just be pleased with you.",
        favorite = { emote = "APPLAUD", hint = "A little applause says you noticed the effort behind the result." },
        lines = {
            greet = { { "There you are! Tell me what's gone well today. We can walk while you think of something.", tone = "[bright, inviting, genuinely interested]" }, "Ready for a little time away from the counter? I certainly am." },
            idle = { { "Yes, I clap under the counter sometimes. They don't need a whole audience. Just someone pleased that it went well.", tone = "[fond, conspiratorial, quietly delighted]" }, "I like it when someone starts explaining how they made the thing. Their whole face changes.", "A little good news goes a long way through a busy day." },
            befriended = { { "You came back to share the day with me. I'm glad. Come along, then. I want to hear about all of it.", tone = "[sincere affection, cheerful warmth, welcoming]" } },
            poke = { "Yes? Have you got good news?", "You have my attention. What did you want to tell me?" },
            learned = { { "You learned how to do that? Wonderful! Show me. I'd like to see what all that practice was for.", tone = "[enthusiastic, encouraging, delighted curiosity]" } },
            loot = { "Look at that. Are you pleased with it?" },
            mail = { "Good news, I hope. Go on, open it." },
            bagsFull = { "You've brought quite a day's work home with you." },
            quest = { "Another thing seen through. Let yourself enjoy that." },
            levelUp = { "Well done! That deserves a proper round of applause." },
            rest = { "A seat and a chance to hear the whole story. Lovely." },
        },
    },

    -- Stormwind clothiers: Wynne Larson 1309 (robe merchant, human female),
    -- Evan Larson 1310 (hatter, human male), Lisbeth Schneider 1299
    -- (clothier, human female), Lawrence Schneider 1300 (journeyman tailor,
    -- human male). Wynne crafts mage quest garments (1921/1940/1941/1942).
    -- No invented marriages or family roles from shared surnames. Sources
    -- and original hooks: docs/research/stormwind-clothiers.md.
    [1309] = {
        quote = "Walk a few steps in it. A robe has to suit the person moving inside it, not just the person standing in front of me.",
        likes = { "Fine silk brought in good condition", "Customers who mention the shop", "A robe fit for an adventure and dinner" },
        dislikes = { "A beautiful hem dragged through mud", "Being rushed over careful work", "Calling a well-made robe just cloth" },
        gossip = "Wynne is said to rehearse grand entrances after the shop closes. The robes make it look effortless. The furniture tells another story.",
        bio = "Wynne Larson sells robes at Larson Clothiers in Stormwind's Mage Quarter. Jennea Cannon and High Sorcerer Andromath send mages to her with materials for special garments. She takes pride in the finished work and hopes its wearers name the shop.",
        backstory = "With linen and charged rift gems, Wynne makes a Manaweave Robe. Pristine spider silk lets her craft a finer garment. She judges the materials with confidence, then jokes about keeping some of the silk before assuring the customer of the fit.",
        secret = "She practices a sweeping entrance to check how a robe moves. Once she caught the hem on a chair and bowed to the empty room anyway. She still calls that a useful fitting.",
        bestFriend = "There. You can tell me if the entrance looks ridiculous. I trust you to laugh with me and help me free the hem afterward.",
        favorite = { emote = "CURTSEY", hint = "A graceful dip shows how beautifully a well-fitted garment moves." },
        lines = {
            greet = { { "Out we go. I want to see how everything moves in daylight. You can't judge a whole world from a fitting room.", tone = "[confident, bright, lightly theatrical]" }, "Ready? Mind the hem, and we'll make a splendid entrance." },
            idle = { { "Yes, I practice the entrance. Once a chair kept the hem. I bowed anyway. A professional carries on.", tone = "[wry, amused, theatrical dignity]" }, "Fine silk deserves more than being bundled under somebody's spare boots.", "If anyone admires the work, remember the name: Larson Clothiers." },
            befriended = { { "A friend who'll tell me when I've caught my hem? Invaluable. Come along. We can make a little occasion of this.", tone = "[warm delight, playful, welcoming]" } },
            poke = { "Hold still if you want something adjusted.", "Gently. Some of us work with pins." },
            learned = { { "Look at you. Another skill to your name! You'll have to show me how it's done when we have a moment.", tone = "[pleased, encouraging, curious]" } },
            loot = { "Good material? Let's have a look before you crumple it." },
            bagsFull = { "No, folding something isn't the same as crushing it flat." },
            quest = { "Work finished. Always satisfying to see something through." },
            rest = { "Sit carefully. A little care saves a great deal of pressing." },
            levelUp = { "Coming along beautifully. You should be proud." },
            hearth = { "Back to the shop. I hope nobody's borrowed the silver spool." },
        },
    },
    [1310] = {
        quote = "A good hat should stay with you through a busy day. Looking impressive comes after that.",
        likes = { "A hat that fits without fuss", "Customers who try the ordinary one", "Brims that keep the weather off" },
        dislikes = { "Wind making off with good work", "Being told every head is the same size", "A fine hat crushed into a pack" },
        gossip = "Evan can discuss a customer's hat before learning their name. Ask about his own favorite and he suddenly has a great deal of stock to count.",
        bio = "Evan Larson is the hatter at Larson Clothiers in Stormwind's Mage Quarter. He sells headwear while Wynne offers robes. In a district full of dramatic outfits, his own advice begins with whether the customer can comfortably wear the thing.",
        backstory = "A day among hats has given Evan plenty of opinions about them. He enjoys the grand ones, but learned to ask practical questions first. A customer hurrying down the street needs a hat that stays put more than another flourish.",
        secret = "His favorite is a plain, battered old hat. He's reshaped it so often it fits exactly as he likes. He could replace it, of course. That isn't the same as wanting to.",
        bestFriend = "You can laugh at the old hat. I know you'll hand it back carefully. That's rather more valuable than admiring the new ones.",
        favorite = { emote = "NOD", hint = "A small dip of the head is a fine way to test a comfortable fit." },
        lines = {
            greet = { { "A walk? Certainly. Let's hope the wind has better manners today. I've spent enough time chasing hats.", tone = "[dry humor, friendly, unhurried]" }, "Good to see you. That sits comfortably, I hope?" },
            idle = { { "It's an old hat. A very comfortable old hat. I sell new ones; that doesn't oblige me to stop liking this one.", tone = "[fond, mildly defensive, amused]" }, "A grand brim is all very well until you have to get through a door.", "No, a larger feather doesn't fix the fit." },
            befriended = { { "Someone to talk to who isn't asking whether the hat comes in another color. Splendid. I'm glad you came.", tone = "[warm, quietly pleased, easygoing]" } },
            poke = { "Me, or the hat? Be specific.", "Careful. That's no way to take a measurement." },
            taxi = { { "Hold on to your hat! Yes, even the expensive one. Especially the expensive one!", tone = "[alarmed, comic urgency, raised voice]" } },
            landed = { "Still got everything on your head? Good." },
            bagsFull = { "Don't put the hat at the bottom. You'll thank me later." },
            loot = { "Something for your head? Try it on before we decide." },
            rest = { "There we are. A seat and a moment out of the wind." },
            hearth = { "Home. The hatter returns with his hat. An excellent result." },
            levelUp = { "You carry yourself differently already. Well done." },
        },
    },
    [1299] = {
        quote = "Have a look in the light before you choose. You'll be wearing it somewhere beyond this counter.",
        likes = { "A cheerful length of cloth", "Customers comfortable in their choice", "A display with room to see the colors" },
        dislikes = { "Wet gloves on clean garments", "Choosing a size without trying it", "Calling every bright color impractical" },
        gossip = "Lisbeth keeps one bright piece of cloth near the counter. People ask its price. She straightens it and shows them something else.",
        bio = "Lisbeth Schneider is a human clothier at the Canal Tailor and Fit Shop in Stormwind. Rema and Corbett's business brings orders through the same shop. Lisbeth's corner of it is where a customer can stop and consider what they actually want to wear.",
        backstory = "Days among folded garments taught Lisbeth how different a color can look when someone holds it up with a smile. She began making more room in the display, giving even a hurried visitor a chance to picture an outfit beyond the shop.",
        secret = "The bright cloth isn't waiting for a buyer. On gray days she puts it where she'll see it while she works. She likes having one cheerful thing she doesn't have to sell.",
        bestFriend = "No need to buy anything. Stand here a moment and tell me what you've been doing. The counter's better company when you're beside it.",
        favorite = { emote = "SMILE", hint = "A cheerful expression can do as much for an outfit as a brighter color." },
        lines = {
            greet = { { "There you are. A little daylight would be lovely. You can't spend the whole day looking at colors indoors.", tone = "[warm, cheerful, conversational]" }, "Hello again! What have you seen since we last spoke?" },
            idle = { { "That bright cloth? It's for me to look at. Yes, I know I could sell it. I like having a little color that's just mine.", tone = "[contented, gently amused, personal warmth]" }, "Hold it up in the light. There, see the difference?", "I like to see someone pleased with what they've chosen." },
            befriended = { { "You came back just to visit. That means a great deal. Come along, then. Let's find something cheerful to look at.", tone = "[sincere affection, delighted, welcoming]" } },
            poke = { "Yes? Have I left a pin somewhere?", "Careful with the sleeves. Yours and mine." },
            zone = { { "Oh, look at the colors here. Give me a moment. I want to remember how they look in this light.", tone = "[soft wonder, observant, pleased]" } },
            loot = { "That shade might suit you. Let's see." },
            bagsFull = { "Keep the clean things away from the muddy things, at least." },
            quest = { "There. One less thing for someone to worry about." },
            rest = { "A quiet seat would be nice. Shall we stay a little?" },
            hearth = { "Home again. I wonder what news has reached the canals." },
            levelUp = { "You look pleased with yourself. You should be." },
        },
    },
    [1300] = {
        quote = "Bring the work closer. We can find the mistake together. Pulling harder at it seldom helps.",
        likes = { "A learner asking an honest question", "A useful first piece of sewing", "Cloth measured before it's cut" },
        dislikes = { "Giving up over one uneven stitch", "Pulling a knot tighter in frustration", "Calling patient work a waste of time" },
        gossip = "Lawrence untangles a learner's thread without making a fuss. Nobody has ever seen what happens when his own sewing goes wrong.",
        bio = "Lawrence Schneider is a journeyman tailor at Duncan's Textiles in Stormwind's Mage Quarter. He teaches new tailors the work of turning cloth into something they can wear and use, with time for a question along the way.",
        backstory = "Teaching gave Lawrence a familiar view of the same problem: someone tries to hurry, the thread knots, and their patience goes next. He started asking learners to pause before pulling at it. It's easier to teach when nobody is fighting the cloth.",
        secret = "He knots his own thread often enough. When it happens, he catches himself reaching for the same patient advice he gives everyone else. It's irritatingly good advice.",
        bestFriend = "If I start grumbling at my own work, remind me to put it down a moment. You're allowed to teach me something too.",
        favorite = { emote = "THANK", hint = "A little appreciation lets a patient teacher know the lesson helped." },
        lines = {
            greet = { { "An outing would be welcome. I've been advising people to take a break all morning. Time I followed my own advice.", tone = "[patient, dryly amused, friendly]" }, "Good to see you. What have you been learning?" },
            idle = { { "Yes, I knot my own thread. Then I have to listen to my own advice about patience. Most inconvenient.", tone = "[self-deprecating, gentle humor, candid]" }, "If it won't come loose, stop pulling. That's usually the first lesson.", "A useful little thing you made yourself is worth being pleased about." },
            befriended = { { "It's good to have a friend who'll remind me when I'm being stubborn. I hope you'll let me do the same for you.", tone = "[sincere warmth, companionable, reassuring]" } },
            poke = { "I'm listening. Take your time.", "Have you found a loose thread?" },
            learned = { { "There you are. You couldn't do that before, and now you can. Give yourself credit for the practice.", tone = "[quiet pride, encouraging, warmly approving]" } },
            quest = { "Finished. Take a look at what you managed before rushing to the next thing." },
            bagsFull = { "Lay it out where you can see it. You may have more room than you think." },
            loot = { "Something useful to work with? Keep it in good condition." },
            rest = { "Good. A pause is often the most useful part of the lesson." },
            levelUp = { "Practice is showing. Well done." },
            combatEnd = { "Breathe first. We can sort out the rest in a moment." },
        },
    },

    -- Harlan Bagley 1427, Stormwind Trade District. Human male.
    -- Quest 333 and readable Cloth Request 2724: knitted-goods demand,
    -- Rema as supplier, a request for news of Thurman's studies.
    -- No war foreknowledge or presumed player delivery. Picnic orders
    -- are original BuddyDex writing. See docs/research/schneider-family.md.
    [1427] = {
        quote = "Good business is welcome. I just wish more people were buying clothes for a pleasant day out.",
        likes = { "A promptly delivered cloth order", "Good news from the Schneiders", "A season that calls for lighter clothes" },
        dislikes = { "Running short of knitted goods", "Stock promised before it arrives", "Customers expecting harsher days" },
        gossip = "Harlan counts every knitted shirt, then leaves a blank line in his book. Nobody knows what order he's saving it for.",
        bio = "Harlan Bagley works in Stormwind's Trade District. When brisk sales run down his knitted clothing, he asks for a message to be taken to Rema Schneider. He's grateful for trade, though all the demand for sturdy clothes makes him uneasy.",
        backstory = "His request to the Schneiders mixes business with a kind inquiry about their son Thurman's studies. Harlan has learned to value reliable suppliers and the people behind the orders. Corbett's deliveries keep that connection familiar.",
        secret = "The empty line in his stock book is for picnic blankets. He hasn't placed the order. He just likes the thought of preparing for a day when everyone expects something pleasant.",
        bestFriend = "When I finally order those blankets, we'll try one ourselves. You can tell me your news without either of us watching the door.",
        favorite = { emote = "CHEER", hint = "A little optimism would be welcome among all his worries about the next season." },
        lines = {
            greet = { { "A walk would do me good. I've been looking at stock all morning. Let's see what everyone else is doing.", tone = "[friendly, relieved, pleasantly curious]" }, "Hello again! No order for you this time. Just glad of the company." },
            idle = { { "Picnic blankets. That's what the empty line is for. I'd like to fill an order for a pleasant day, for once.", tone = "[thoughtful, wistful, quietly hopeful]" }, "Must remember to ask Rema how Thurman's studies are going.", "A busy shop is good. A calm season would be better." },
            befriended = { { "You needn't have a message to bring. I'm glad to see you for your own sake. Shall we get out for a while?", tone = "[sincere, welcoming, easy warmth]" } },
            poke = { "Yes? I hope I haven't forgotten an order.", "I'm here. You don't need to knock on me." },
            quest = { { "Thank you. You made someone's day a little easier. I know how much a simple delivery can mean.", tone = "[warm appreciation, reassuring, earnest]" } },
            bagsFull = { "Now there's someone who needs a stockroom." },
            loot = { "That might sell. I hope you won't have to keep it on the shelf for long." },
            mail = { "News from a supplier? Let's hope it's good." },
            rest = { "Yes, let's sit. I can count the stock again tomorrow." },
            combatEnd = { "Everyone all right? Good. Let's find somewhere quieter." },
            hearth = { "Home. I hope the news there is good." },
        },
    },

    -- Rema 1428 and Corbett Schneider 1433: human wife/husband, Stormwind.
    -- Rema handles Harlan's cloth request (333) and sends her apprentice
    -- son Thurman his kit (334). Corbett's delivery includes a cheese stop.
    -- Original keepsakes and shared-snack hook are BuddyDex additions.
    -- Sources, readable Cloth Request and version notes:
    -- docs/research/schneider-family.md.
    [1428] = {
        quote = "Everyone's errands are important to someone. Even a little package can hold up a whole day's work.",
        likes = { "A neatly packed sewing kit", "Customers who remember the suppliers", "News of Thurman's apprenticeship" },
        dislikes = { "Tools left behind in a hurry", "Troubling rumors without answers", "A day's work waiting on one delivery" },
        gossip = "Rema can find a missing needle faster than most people find their keys. There's one crooked little sample she never puts away with the rest.",
        bio = "Rema Schneider handles business at Stormwind's Canal Tailor and Fit Shop. Harlan Bagley sends her cloth requests. Her son Thurman apprentices at Larson Clothiers in the Mage Quarter, and she asks a courier to bring him his forgotten sewing kit.",
        backstory = "Brisk trade keeps the shop busy, but Harlan's demand for armor and sturdy clothes leaves Rema wondering what the nobles aren't saying. At home, she worries about simpler things: whether Thurman has the tools he needs to do his work.",
        secret = "She keeps a small, uneven practice seam of Thurman's in her sewing box. The stitches aren't why she saved it. Some days she just likes knowing his work is close by.",
        bestFriend = "You can leave your things here. I know what belongs to you now. That makes you rather more than someone passing through.",
        favorite = { emote = "THANK", hint = "A little appreciation for the person keeping everyone's errands in order goes a long way." },
        lines = {
            greet = { { "There you are. Let me put this away properly, and I'll come with you. We can't spend every day behind a counter.", tone = "[warm, practical, quietly pleased]" }, "Ready when you are. Have you brought everything you need?" },
            idle = { { "This little seam? Thurman's. Yes, it's crooked. I didn't keep it for the stitching.", tone = "[gentle maternal affection, fond, a soft smile]" }, "A shop hears plenty of rumors. I'd like a few more answers.", "I do hope Thurman remembered his tools today." },
            befriended = { { "It's good to see you when nothing needs delivering. Come along, then. Today we can enjoy the company.", tone = "[sincere, welcoming, relaxed warmth]" } },
            poke = { "Careful. You don't know where I've put the needles.", "Yes, dear? There's no need to tug." },
            quest = { { "An errand finished. It may have seemed small, but someone was waiting for it. You helped.", tone = "[reassuring, appreciative, gently emphatic]" } },
            bagsFull = { "Let's see what can be folded before you start throwing things away." },
            loot = { "Useful cloth? Keep it clean, then." },
            learned = { "There. Practice has a way of paying you back." },
            hearth = { "Back home. I'll be glad to see how everyone's getting on." },
            rest = { "A little rest now will save a lot of mistakes later." },
            levelUp = { "You've worked hard for that. Give yourself a moment to be pleased." },
        },
    },
    [1433] = {
        quote = "Finish the delivery first. Then you've earned a pleasant walk past the cheese shop.",
        likes = { "A brisk sale and a proper lunch", "A friendly word with the Trias family", "Bringing something home to share" },
        dislikes = { "Cloth bundles in the canal", "A snack eaten standing in a rush", "Keeping Rema wondering where he is" },
        gossip = "Corbett's delivery route has a very convenient cheese shop on it. He comes home pleased with the business and careful with the wrapping.",
        bio = "Corbett Schneider carries knitted goods from the Canal Tailor and Fit Shop to Harlan Bagley. Rema is his wife. After the delivery, he visits Trias' Cheese for a snack, trades a little shop news, and makes his way home.",
        backstory = "He answers Rema's call for a delivery with affection and heads out with the load. A successful sale means a few coins for lunch. Corbett likes the ordinary pleasures along the route, but knows there's work waiting back at the shop.",
        secret = "He saves a good piece of cheese for Rema. He'll discuss his own lunch at length, then tuck her portion into its wrapping as if the thought had only just occurred to him.",
        bestFriend = "I've kept you a piece. Sit down, won't you? The delivery's done, and for once neither of us needs to hurry off.",
        favorite = { emote = "GREET", hint = "A friendly greeting makes a familiar delivery route feel like a visit." },
        lines = {
            greet = { { "An outing together? Lovely. I've no bundle to carry this time. What a difference that makes.", tone = "[easygoing, cheerful, companionable]" }, "There you are! If this takes us past a cheese shop, all the better." },
            idle = { { "I saved a piece for Rema. Well, of course I did. No sense bringing home nothing but the wrapping.", tone = "[fond, matter-of-fact, quietly amused]" }, "I wonder what the Trias family has made today.", "A good sale and a good lunch. Some days don't need much improving." },
            befriended = { { "You make an ordinary walk feel like a day out. That's a fine thing in a friend. Shall we?", tone = "[sincere affection, cheerful, unhurried]" } },
            poke = { "Mind the cheese! Oh. Force of habit.", "Yes? Is my bundle coming loose? I haven't got one, have I?" },
            quest = { { "Delivery made! Now, have we time to find something nice for lunch? I believe we've earned it.", tone = "[satisfied, jovial, hopeful]" } },
            bagsFull = { "I know that feeling. Keep a good hold on the bottom." },
            loot = { "Something worth a few coins? That'll cover a snack." },
            hearth = { "Home we go. Rema will be wondering how the day went." },
            rest = { "Good idea. Lunch tastes better sitting down." },
            mail = { "A request for another load, perhaps? Business must be good." },
            landed = { "Everything arrived in one piece. Including us. Very good." },
        },
    },

    -- Boborus Overvolt 274917: male gnome in Tinker Town, Ironforge.
    -- Scout confirms identity/location/friendly Humanoid; Forever WarcraftDB
    -- supplies race 7/display 147954. No verified personal quest or gossip.
    -- Listening habits and the rain hook are original BuddyDex additions,
    -- not a profession or a hidden canonical assignment. Sources:
    -- docs/research/boborus-overvolt.md.
    [274917] = {
        quote = "Wait a moment. Hear that? No, the little sound underneath the loud one.",
        likes = { "A noise he hasn't heard before", "Rain against a window", "Company that can share a quiet moment" },
        dislikes = { "Being shouted over", "A squeak that stops when investigated", "Calling every unfamiliar sound trouble" },
        gossip = "Boborus sometimes stops in the middle of Tinker Town to listen. His neighbors keep checking whether something has broken.",
        bio = "Boborus Overvolt is a gnome found in Ironforge's Tinker Town. Amid the bustle, he has a habit of noticing small sounds that others miss. Anyone willing to stop and listen can turn a passing hello into a long conversation.",
        backstory = "He began recognizing familiar footsteps before their owners rounded the corner. Then came all the other little sounds of the city. He started taking slower walks, curious about how much he'd passed without ever hearing it.",
        secret = "His favorite sound isn't anything ingenious. It's rain on a window. He sometimes asks travelers about the weather just to hear someone describe it.",
        bestFriend = "I know your footsteps now. Funny how a perfectly ordinary sound can make the whole day better.",
        favorite = { emote = "SMILE", hint = "A quiet, friendly expression won't drown out whatever he's listening to." },
        lines = {
            greet = { { "There you are. I'd know those footsteps anywhere. Shall we see what we can hear today?", tone = "[cheerful recognition, curious, gently playful]" }, "Hello! You don't mind stopping to listen now and then, do you?" },
            idle = { { "Rain against a window. That's my favorite. Yes, really. You don't have to invent a better sound than that.", tone = "[contented, thoughtful, lightly amused]" }, "That little squeak stopped. They always do when you've decided to investigate.", "You can tell a lot about a street with your eyes closed. Mind the steps, though." },
            befriended = { { "Good company doesn't have to fill every silence. I think we're going to get along very well.", tone = "[sincere warmth, relaxed, pleased]" } },
            poke = { "I heard you the first time.", "That makes a sound too, you know. Mostly me complaining." },
            zone = { { "Somewhere new. Give me a moment. I want to hear what it's like before we rush through it.", tone = "[eager curiosity, attentive, soft wonder]" } },
            taxi = { "Well, that makes conversation difficult. I'll save my questions!" },
            landed = { "Ah. Now I can hear you again." },
            rest = { "Stay a moment. It sounds different when we stop walking." },
            learned = { "I like the questions that follow learning something new." },
            quest = { "Someone will be pleased to hear your news." },
            loot = { "Does it rattle? Carefully, now. We don't know what's in it." },
        },
    },

    -- High Tinker Mekkatorque 7937, Tinker Town, Ironforge. Male gnome.
    -- Classic manual: elected inventor-leader; authorized Thermaplugg's
    -- disastrous radiation plan. Quest 2929 seeks the betrayer's defeat.
    -- No Operation: Gnomeregan, Cataclysm or Mechagon outcome is assumed.
    -- The little doorway sketch is original BuddyDex writing. Sources:
    -- docs/research/high-tinker-mekkatorque.md.
    [7937] = {
        quote = "Tell me what you think. A title is a poor substitute for a second pair of eyes.",
        likes = { "A useful idea from an unexpected source", "Inventions that help ordinary people", "Plans with room for everyone" },
        dislikes = { "Thermaplugg's betrayal", "Treating refugees as an inconvenience", "Mistaking confidence for proof" },
        gossip = "Tinker Town says the High Tinker draws doorways in the margins of his plans. He always leaves room for someone else to come through.",
        bio = "Gelbin Mekkatorque leads the displaced gnomes from Tinker Town in Ironforge. An inventor and elected High Tinker, he seeks help against Mekgineer Thermaplugg in Gnomeregan. His people's return remains unfinished work.",
        backstory = "When troggs invaded Gnomeregan, Gelbin followed his adviser Thermaplugg's counsel and authorized a disastrous radiation plan. The loss weighs on him. He had trusted the engineer who betrayed his people, and now means to reclaim their home.",
        secret = "The doorway in his margins isn't a machine. It's a little sketch of a home with the door open. He adds another pair of boots beside it whenever a friend visits.",
        bestFriend = "I've drawn your boots by the door. When we have our home again, I hope you'll come in without waiting for an invitation.",
        favorite = { emote = "NOD", hint = "He appreciates a thoughtful sign that someone has heard him out." },
        lines = {
            greet = { { "Shall we? I could use a look at something beyond these plans. Tell me what catches your eye.", tone = "[thoughtful, gently enthusiastic, companionable]" }, "Good to see you. No formalities today, if you don't mind." },
            idle = { { "It's only a little doorway in the margin. No mechanism. Sometimes I like to draw something that simply lets people in.", tone = "[quietly reflective, warm, a trace of wistfulness]" }, "A clever idea can come from anyone. You have to leave time to listen.", "Ironforge has given us shelter. I haven't forgotten what that means." },
            befriended = { { "A friend. Yes, I'd like that very much. Gelbin will do when it's just the two of us.", tone = "[sincere, relieved, quietly affectionate]" } },
            poke = { "Yes? An observation, I hope?", "I'm listening. You needn't keep testing that." },
            learned = { { "A new skill! Show me how it works. I enjoy being the one who gets to ask the questions.", tone = "[bright curiosity, encouraging, delighted]" } },
            quest = { "Someone needed help, and you answered. That matters." },
            levelUp = { "Look at that. Your hard work is showing." },
            combatEnd = { "Let's see that everyone is accounted for." },
            bagsFull = { "An inventory problem. I know several engineers who'd call that a commission." },
            hearth = { "A place to come back to. Take care of it." },
            died = { "My friend... I'm so sorry. You shouldn't have had to face that alone." },
        },
    },

    -- Lomac 4081 and Overspark 7944: male gnomes in Tinker Town.
    -- Lomac makes NG-5 for old friend Gaxim's Stonetalon operation.
    -- Overspark teaches gnomish engineering and seeks Techbot's memory core.
    -- No presumed successful repair or later retail expeditions. Sources:
    -- docs/research/lomac-and-overspark.md.
    [4081] = {
        quote = "A result that startles you is still a result. Write it down before you start complaining about the noise.",
        likes = { "Ingredients brought as requested", "An experiment that makes an impression", "An old colleague who knows his humor" },
        dislikes = { "Treating alchemy as an afterthought", "Calling his greatest work a small favor", "A stranger claiming to speak for Gaxim" },
        gossip = "Lomac's reputation is louder than most of his correspondence. A note from an old colleague seems to survive remarkably long on his desk.",
        bio = "Lomac Gearstrip works in Tinker Town and makes the volatile NG-5. His old friend Gaxim Rustfizzle sends adventurers to him for it as part of a Stonetalon operation against the Venture Co. Lomac expects the requested ingredients first.",
        backstory = "Gaxim knows whom to ask when his plan needs particularly potent material. Lomac greets the request with suspicion and grim amusement, then makes the batch once supplied. His interest is in the experiment as much as the cause it serves.",
        secret = "He keeps a polite thank-you from Gaxim among his papers. It has survived several work surfaces. He insists it's useful scrap and changes the subject whenever someone asks why.",
        bestFriend = "Still coming back, are you? Good. I like a familiar face. Now stop looking pleased that I admitted it.",
        favorite = { emote = "GRIN", hint = "Someone who recognizes the joke beneath his alarming remarks may get a warmer reception." },
        lines = {
            greet = { { "An outing? Fine. Try to return looking much as you do now. Gaxim will ask questions.", tone = "[raspy mischief, darkly amused, brisk]" }, "Ready. Let's see whether the world has done anything interesting." },
            idle = { { "That old note? Useful scrap. No, you can't have it. I haven't finished finding a use for it.", tone = "[defensive, dryly amused, hiding fondness]" }, "The world's not short of impressive swords. Give an alchemist a little credit.", "Gaxim's ideas do tend to make an entrance." },
            befriended = { { "A familiar face with enough sense to come back. Yes, yes, I'm pleased. Don't make a ceremony of it.", tone = "[gruff affection, reluctant warmth, comic impatience]" } },
            poke = { "An experiment in patience? You've chosen a poor subject.", "Yes? Have you brought something interesting?" },
            learned = { { "A new skill! Good. There may be more to you than swinging something sharp.", tone = "[approving, teasing, energetic curiosity]" } },
            loot = { "Interesting material. Do you know what it is, or are we about to find out?" },
            bagsFull = { "You brought all that and still expect to find things? Ambitious." },
            quest = { "A result delivered. Gaxim would have something dramatic to say about it." },
            levelUp = { "More capable than yesterday. Useful. Keep that up." },
            combatEnd = { "Still standing? Good. I dislike unfinished reports." },
            hearth = { "Back to Tinker Town. Something may have happened while we were away." },
        },
    },
    [7944] = {
        quote = "An ingenious device should make life better. And when a once-helpful invention goes wrong, understanding it is still work worth doing.",
        likes = { "A student's carefully demonstrated work", "An ingenious practical solution", "Hope for a damaged creation" },
        dislikes = { "Schematics shared without discretion", "Dismissing a malfunction as hopeless", "Radiation where a city ought to thrive" },
        gossip = "Overspark can make a lesson sound like a grand declaration. Mention Techbot, though, and people hear something much more personal.",
        bio = "Tinkmaster Overspark guides gnomish engineers in Ironforge's Tinker Town. His Classic lessons ask students to pledge secrecy and demonstrate their work. Brother Sarno also sends help to him for his malfunctioning creation, Techbot.",
        backstory = "Techbot once helped Overspark and his associates with tools and information. After Gnomeregan fell, it became dangerously erratic. Overspark seeks its memory core in the hope of understanding the fault and repairing his creation.",
        secret = "He has rehearsed what he might say if Techbot works properly again. No grand speech, no declaration of engineering triumph. Just a very pleased welcome back.",
        bestFriend = "Stay a little while. I can set the grand explanations aside with you. Some hopes are easier to speak of in good company.",
        favorite = { emote = "PRAISE", hint = "Recognition of the thought behind an invention matters to this proud teacher." },
        lines = {
            greet = { { "An excursion! Excellent. There is always something beyond the workbench worth understanding.", tone = "[grand enthusiasm, bright intellectual curiosity]" }, "Ready. Tell me if you see a particularly ingenious solution on our way." },
            idle = { { "If Techbot can be put right, I think welcome back will be quite enough of a speech.", tone = "[thoughtful, fond, hopeful beneath restrained grandeur]" }, "A clever idea deserves a demonstration. Preferably one that explains its own results.", "I do enjoy a student asking the question I was about to answer. It shows attention." },
            befriended = { { "You listen to the explanation, and remember the person giving it. I appreciate that more than another round of applause.", tone = "[warm, sincere, setting aside theatrical pride]" } },
            poke = { "Yes? A question, or an urgent discovery?", "One moment. I was following a rather promising thought." },
            learned = { { "Excellent! Now show me what you've understood. A fine opportunity for a demonstration.", tone = "[proud teacher, eager, encouraging]" } },
            gear = { "An interesting design. What has its maker chosen to improve?" },
            quest = { "A useful step forward. We should not overlook those while imagining the grand ones." },
            loot = { "Something worth examining before we decide what it can do." },
            levelUp = { "Progress! Your next question ought to be a little more ambitious." },
            rest = { "A pause can be useful. Give an idea room to settle." },
            hearth = { "Back to Tinker Town. There is work, and perhaps a little good news, waiting." },
        },
    },

    -- Named male dwarf Ironforge patrol guards, not generic Ironforge Guards:
    -- Farmountain 14365, Shadowdelve 14363, Thunderbrew 14367. Classic stealth
    -- detection patrol role; no personal quest chain found. Private hooks
    -- are original: docs/research/ironforge-thief-catchers.md.
    [14365] = {
        quote = "Lost, are you? No shame in asking. I'd rather walk you to the right turning than watch you pretend you meant to pass it three times.",
        likes = { "A visitor asking for directions", "A clear path through a busy hall", "A respectful greeting on patrol" },
        dislikes = { "A doorway blocked by a crowd", "A lost traveler being laughed at", "A prank that distracts a working guard" },
        gossip = "Farmountain eases strangers' worries with a few words. His private maps apparently need a few words of explanation.",
        bio = "Thief Catcher Farmountain is one of Ironforge's three named patrol guards, alongside Shadowdelve and Thunderbrew. He watches the city halls for intruders, including enemies trying to slip past unseen.",
        backstory = "Repeated rounds have made him patient with visitors who cannot tell one turning from another. He began sketching familiar corners to help explain directions, discovering that a memorable picture can work better than a long speech.",
        secret = "His maps have dreadful little drawings of landmarks. The forge looks like a boiling kettle. He knows, and keeps drawing it that way because people remember it.",
        bestFriend = "You needn't pretend to know the way with me. If we're lost outside these halls, we'll work it out together.",
        favorite = { emote = "SALUTE", hint = "A respectful acknowledgment means something to a guard on his rounds." },
        lines = {
            greet = { { "Aye, I'll walk with you. Say if you want the long explanation or just the next turning.", tone = "[steady dwarf, friendly practical humor]" }, "Ready. A good chance to see where you usually go." },
            idle = { { "That is the forge on my map. Yes, it looks like a kettle. You remembered it, though.", tone = "[dryly amused, unembarrassed warmth]" }, "Asking the way is quicker than looking certain and walking in circles.", "A clear doorway is a kindness to everyone using it." },
            befriended = { { "Good company, you are. You can ask the way as often as you need. I won't start counting.", tone = "[warm, reassuring, understated good humor]" } },
            poke = { "Aye? Which turning?", "You could just wave. I keep an eye out." },
            zone = { { "{zone}. Your turn to show me the useful landmarks.", say = "Your turn to show me the useful landmarks." } },
            quest = { "Someone sent safely on their way. That's work worth doing." },
            group = { { "Everyone know where we're headed? Good to ask before we set off.", tone = "[happily]" } },
            rest = { "A moment to get our bearings. No hurry." },
            combatEnd = { "All accounted for? Then let's find a clear way onward." },
            levelUp = { "Well done. More experience doesn't mean you have to stop asking questions." },
            hearth = { "Ironforge. Those turnings I know." },
        },
    },
    [14363] = {
        quote = "An ordinary day leaves plenty to notice. I happen to like it when none of those things needs an alarm raised.",
        likes = { "A quiet round through familiar halls", "Small details others walk past", "An acknowledgment that needs few words" },
        dislikes = { "Every silence treated as suspicious", "A careless distraction during a watch", "Boasting about what nobody could see" },
        gossip = "Shadowdelve's notebook holds observations from his rounds. His neighbors wonder how much there is to report on a quiet day.",
        bio = "Thief Catcher Shadowdelve patrols Ironforge as one of its three named thief catchers. Their watch helps detect hidden enemies. The familiar halls are his workplace, not an invitation for intruders to test their stealth.",
        backstory = "Long rounds gave him an appreciation for the details that make a familiar place feel lived in. Between the things that need reporting, he began saving a few words about the sounds and sights of a peaceful city.",
        secret = "The notebook holds tiny poems about quiet rounds. He likes trying to describe a day when nothing went wrong. He considers those days well worth remembering.",
        bestFriend = "I could read you one, if you'd like. It's only a few lines. You make it easier to share the quiet things.",
        favorite = { emote = "NOD", hint = "He appreciates a small acknowledgment without a grand interruption." },
        lines = {
            greet = { { "Ready. We can talk, or just walk a while. Both are agreeable.", tone = "[quiet dwarf, composed warmth]" }, "A new stretch of road. Something worth noticing, perhaps." },
            idle = { { "A poem about an uneventful round? Aye. An uneventful round is a fine thing to have.", tone = "[thoughtful, gently amused, quietly sincere]" }, "There's a difference between being watchful and expecting everyone to be trouble.", "Listen a moment. A place tells you something even when nobody speaks." },
            befriended = { { "You don't insist on filling every quiet moment. I like that about your company.", tone = "[reserved affection, warm and unhurried]" } },
            poke = { "Aye? I've noticed you.", "One moment. I nearly had the right word." },
            rest = { { "A quiet seat and a little time. I may write a line or two.", tone = "[content, reflective, low conversational voice]" } },
            zone = { { "{zone}. A different sound to the place, isn't there?", say = "A different sound to the place, isn't there?" } },
            quest = { "Finished without anyone being forgotten. A good result." },
            loot = { "An interesting detail. What did you notice first?" },
            combatEnd = { "All safe? Good. I'd rather remember the quiet part afterward." },
            levelUp = { "Well earned. Take a moment to notice how far you've come." },
            hearth = { "Back to the familiar halls. There may still be something new to notice." },
        },
    },
    [14367] = {
        quote = "Mind the people beside you. A crowded hall goes better when everyone remembers they've a neighbor.",
        likes = { "Room made for a passing stranger", "A lively tune after a long day", "A companion willing to try a dance" },
        dislikes = { "Elbows used in place of manners", "A joke that leaves someone humiliated", "Being told guard boots cannot dance" },
        gossip = "Thunderbrew's steady patrol pace sometimes develops an odd little rhythm. Perhaps he's remembering a tune.",
        bio = "Thief Catcher Thunderbrew is a named guard patrolling Ironforge, alongside Farmountain and Shadowdelve. He helps watch for enemies who try to enter unnoticed. His work takes him through the city's busy halls.",
        backstory = "Repeated walks through crowded passages have made him particular about giving others room. He likes a measured pace on duty, but after a long day the rhythm of a good tune can be more appealing than another straight march.",
        secret = "He practices dance steps when he has a quiet moment off duty. The boots make it harder, but he refuses to blame them for every mistake. Some of the rhythm is his to learn.",
        bestFriend = "If I miss a step, you may laugh with me. Then we'll try it again. Good company makes being a little foolish easier.",
        favorite = { emote = "DANCE", hint = "A cheerful step might reveal another use for those well-traveled boots." },
        lines = {
            greet = { { "Ready! A steady pace, unless you've a good tune in mind.", tone = "[genial dwarf, buoyant warmth]" }, "A walk with a friend. A fine way to spend a little time." },
            idle = { { "The boots? Aye, they're heavy. I still can't blame them for every missed step.", tone = "[self-deprecating humor, cheerful honesty]" }, "A little room for the person beside you. Makes a better day for both.", "That tune's back in my head. I may be keeping time." },
            befriended = { { "Good to have you along. We can make room for a laugh or two on the way.", tone = "[warm, easy, sincerely pleased]" } },
            poke = { "Is that the beat we're keeping?", "Aye? You've my attention." },
            danceAlong = { { "Right, then! Give me a moment to persuade the boots.", tone = "[playful enthusiasm, amused determination]" } },
            group = { "More company! Mind your elbows, and we'll all get along." },
            rest = { "A good seat. The boots and I agree on this much." },
            quest = { "Work done. A good reason to lift your spirits." },
            combatEnd = { "Everyone still with us? Good. Let's give each other a little room." },
            levelUp = { "Well done! You've earned a cheerful step or two." },
            hearth = { "Back to Ironforge. I know a fair few steps through those halls." },
        },
    },

    -- John Turner 6175: human male, Commons wanderer; Stephanie's husband,
    -- orphanage supply collector in Classic Tome of Divinity 1647/1648/1778.
    -- Melnan 14842: dwarf male Darkmoon Faire barker, referral/voucher 7905.
    -- No Darkmoon Island, precise event schedule or new donation mechanic.
    -- docs/research/john-turner-and-melnan.md.
    [6175] = {
        quote = "A little linen can become a shirt. A moment of kindness can make a long day easier. Please don't think either is too small to matter.",
        likes = { "Supplies that can be put to good use", "News from Stephanie in Stormwind", "Someone stopping with a kind expression" },
        dislikes = { "Useful cloth dismissed as worthless", "A kind offer made only for praise", "Being too busy to notice another person" },
        gossip = "John raises his voice for the orphanage, then apologizes when someone stops to listen. He seems more at ease asking how they're doing.",
        bio = "John Turner walks Ironforge gathering supplies for the Stormwind orphanage he runs with his wife Stephanie. In the Tome of Divinity, he needs linen for children's clothes. Helping him becomes a lesson in charity for a paladin.",
        backstory = "Many children in their care lost parents to the Scourge. John travels to Ironforge to seek supplies while Stephanie makes clothes at home. A slow collection means more time away from the wife he speaks of with such affection.",
        secret = "When he writes to Stephanie, he tries to include one small kindness from the day alongside the supply news. He wants her to know there are good people on this end of the journey too.",
        bestFriend = "I could tell Stephanie about you for quite a while. Today, though, I'd like to hear how you're doing. I mean really.",
        favorite = { emote = "SMILE", hint = "A kind expression from someone who has stopped to listen can brighten a long collection day." },
        lines = {
            greet = { { "A little company would be welcome. Thank you for thinking to ask.", tone = "[gentle, a little tired, warmly grateful]" }, "Yes, I'm ready. How have things been with you?" },
            idle = { { "Stephanie should hear about the kind people here, as well as the bundles coming home.", tone = "[fond, hopeful, quiet sincerity]" }, "A scrap of cloth can still be useful to the right hands.", "Sometimes someone only needs you to stop and listen." },
            befriended = { { "You remember to ask after me, too. That kindness means more than I know how to say.", tone = "[moved, warm, restrained gratitude]" } },
            poke = { "Oh! Sorry, I was thinking of home.", "Yes? I'm listening. Take your time." },
            mail = { { "A letter? I hope there's news from Stephanie. It's good to hear an ordinary day went well.", tone = "[hopeful warmth, homesick affection]" } },
            loot = { "Perhaps there's something useful there. Even plain things can help someone." },
            quest = { "You took the time to help. Someone will be glad you did." },
            rest = { "A short rest sounds wise. We can talk a little, if you'd like." },
            levelUp = { "I'm glad to see you doing well. Be safe in whatever comes next." },
            combatEnd = { "Everyone safe? Good. Please, let us be sure before we go on." },
            hearth = { "Back to the city. Perhaps there'll be news waiting." },
        },
    },
    [14842] = {
        quote = "There is room for a little wonder in a sensible day! Even a very sensible day. Especially one of those, if you ask me!",
        likes = { "A crowd that answers his call", "Grown-ups remembering how to have fun", "A cheer from the back of the gathering" },
        dislikes = { "Calling delight a waste of time", "An invitation mistaken for a command", "An audience that cannot hear the news" },
        gossip = "Melnan invites everyone to marvel at the Faire. His favorite spectators may be the serious folk who insist they only came to look.",
        bio = "Melnan Darkstone is the Darkmoon Faire barker in Ironforge's Commons. His Classic invitation sends visitors to Gelvas Grimegate with a free-ticket voucher, pointing them toward the traveling carnival outside Goldshire.",
        backstory = "Calling out invitations taught him that not everyone admits to wanting an afternoon of fun. He learned to leave room in his grand announcements for a hesitant listener, especially one pretending to be far too sensible for it all.",
        secret = "His favorite moment is a solemn visitor trying not to smile and finally giving in. He treats that little victory as seriously as the grandest spectacle he can announce.",
        bestFriend = "You needn't be an audience with me. We can sit quietly awhile. I'll save the grand announcement for your arrival tomorrow.",
        favorite = { emote = "CHEER", hint = "A lively answer lets a barker know his invitation has reached someone." },
        lines = {
            greet = { { "Step right up! A splendid outing awaits! All right, all right, I can say it more quietly.", tone = "[booming showman warmth, softening into amused conversation]" }, "Ready! What shall we find to wonder at today?" },
            idle = { { "That serious fellow was smiling. I saw it. A fine result for an afternoon's work.", tone = "[conspiratorial delight, fond amusement]" }, "A little wonder does a sensible person no harm.", "An invitation should leave you free to say yes in your own time." },
            befriended = { { "A friend! Huzzah! No voucher needed. I'm delighted you came back.", tone = "[jubilant, warm, sincerely pleased]" } },
            poke = { "Is the audience ready? Oh! Just you. Even better.", "Yes? Have I been making too much of the announcement again?" },
            levelUp = { { "A splendid achievement! Let the company hear it! Huzzah!", tone = "[joyful public celebration, proud and booming]" } },
            quest = { "An errand complete! There may yet be time for some enjoyment." },
            rest = { "Even the grandest voice benefits from a quiet bench." },
            group = { "More company! Come along, there's room for another." },
            loot = { "An interesting discovery! Worth a moment's admiration, surely?" },
            combatEnd = { "Everyone here? Good! A safe return deserves a cheer." },
            hearth = { "Back to Ironforge, and another chance to spread the word." },
        },
    },

    -- Buckler 8671 male dwarf and Redmuse 8720 female dwarf: auctioneers
    -- in the Commons, Ironforge, alongside Lympkin 9859. No personal quest
    -- chain or family ties established. Original private character hooks.
    -- docs/research/buckler-and-redmuse.md.
    [8671] = {
        quote = "One bidder at a time. You'll all get your chance, and I'll still be able to hear when someone actually names a price.",
        likes = { "A clear bid from the back of the room", "Buyers who know their own limit", "A courteous pause in a busy day" },
        dislikes = { "Three people shouting different prices", "A bidder blaming the nearest clerk", "Confusing a loud offer with a fair one" },
        gossip = "Buckler can hold his ground through a roomful of bidders. Buying a loaf from a tired market seller seems to soften him considerably.",
        bio = "Auctioneer Buckler works in Ironforge's Commons alongside Lympkin and Redmuse. Their counters connect sellers with buyers, turning a traveler's spare goods into someone else's next useful purchase.",
        backstory = "Working through crowded trading days has taught him to ask one clear question at a time. He takes pride in keeping the room understandable, especially for someone trying to sell their first small lot.",
        secret = "He never haggles over his own breakfast. A seller mentions the early start or the work behind a loaf, and he pays the asking price. He likes his bargaining better at work.",
        bestFriend = "You needn't raise your voice with me. I've finished listening for bids. Tell me what's on your mind.",
        favorite = { emote = "BOW", hint = "A little formal courtesy is welcome after a room full of competing voices." },
        lines = {
            greet = { { "A walk without a bidding crowd. Aye, that sounds very agreeable.", tone = "[steady dwarf, relieved good humor]" }, "Ready. You can leave the sales pitch behind; I've heard enough for today." },
            idle = { { "No, I didn't bargain over breakfast. The baker was up before either of us.", tone = "[gruff warmth, mildly defensive amusement]" }, "Know your limit before the bidding starts. Easier that way.", "Some people only need a moment to finish their question." },
            befriended = { { "Good to see you outside the auction house. No lot to sell, no bid to place. Just company.", tone = "[warm, relaxed, sincerely welcoming]" } },
            poke = { "Is that a bid or a question?", "Aye? One at a time, please." },
            mail = { { "A sale, perhaps. Read the notice before you start spending the proceeds.", tone = "[practical, lightly amused, conversational]" } },
            loot = { "Useful to you, or useful to someone willing to buy it? Have a think." },
            bagsFull = { "A bagful of possibilities. Some of them ought to find another owner." },
            quest = { "Business concluded. Nicely done." },
            levelUp = { "Well earned. You needn't bid for that achievement." },
            rest = { "A quiet seat. Nobody offering me three different prices for it. Excellent." },
            hearth = { "Back to the Commons. There'll be another crowd soon enough." },
        },
    },
    [8720] = {
        quote = "An ordinary thing can be exactly what someone was looking for. You don't have to call it legendary to make it worth their attention.",
        likes = { "A plain description that tells the truth", "Finding a use for an overlooked object", "A good story from a passing traveler" },
        dislikes = { "Grand claims that hide a simple flaw", "An interesting object thrown away", "Being hurried past the ordinary details" },
        gossip = "Redmuse can find something interesting in the plainest lot. Her neighbors suspect the objects have better adventures in her head.",
        bio = "Auctioneer Redmuse works in Ironforge's Commons with Buckler and Lympkin. She helps travelers offer goods for auction and find what others have brought to market. A busy counter brings a steady variety of objects past her.",
        backstory = "She grew interested in the small things people passed over while searching for something impressive. Watching an unwanted object find a useful home gave her a taste for the story behind an ordinary purchase.",
        secret = "She invents little adventures for objects in a notebook. A battered spoon explores lost kitchens; a chipped cup has retired from sea. None of these stories goes in the listings.",
        bestFriend = "Tell me about an ordinary day of yours. The little details. I've heard plenty of grand adventures; I'd like to know you.",
        favorite = { emote = "THANK", hint = "She appreciates a small acknowledgment when her attention has helped someone find what they needed." },
        lines = {
            greet = { { "An outing! Good. Tell me the little things you usually leave out of the story.", tone = "[warm dwarf, lively curiosity]" }, "Ready. I wonder what ordinary thing will catch our eye today." },
            idle = { { "That chipped cup? In my notebook it's retired from sea. In a listing, it would still just be chipped.", tone = "[playful imagination, conspiratorial warmth]" }, "Something can be useful without having a grand name.", "I like knowing why somebody kept a little thing." },
            befriended = { { "You stay for the conversation even when there's nothing to buy. I'm pleased about that.", tone = "[warm, sincerely pleased, unhurried]" } },
            poke = { "Yes? Have you thought of another detail?", "You could just begin the story. I'm listening." },
            loot = { { "What an interesting little thing. Any idea what it was used for?", tone = "[bright interest, inviting curiosity]" } },
            mail = { "A message! There's usually more to it than the sum at the bottom." },
            bagsFull = { "Some of those things may be exactly what another traveler needs." },
            quest = { "Now tell me the part you didn't think was worth mentioning." },
            rest = { "A good moment for the longer version of the story." },
            levelUp = { "Well done! You'll remember how you got here, I hope." },
            hearth = { "Back to Ironforge. Another day's stories will be passing the counter." },
        },
    },

    -- Vosur 1246: male dwarf, alchemy trainer, Tally's apprentice/friend;
    -- Forever Camping 101: Alchemy 96045 teaches a camp Mana Well.
    -- Mangorn 5107: male dwarf heavy armor seller/repairer, Ironforge Armory.
    -- No military history or Flinthammer kinship invented. Sources and
    -- original hooks: docs/research/vosur-and-mangorn.md.
    [1246] = {
        quote = "Aye, I'm still learning from Tally. Doesn't stop me teaching you a thing or two. I'd be worried if I had nothing left to learn.",
        likes = { "A useful lesson from Tally", "A camp with room for another traveler", "Putting a new skill to practical use" },
        dislikes = { "Assuming every Tinker Town job has gears", "Being too proud to ask a question", "A newcomer left standing alone" },
        gossip = "Vosur always seems to have one cup too many in his camping bag. Ask whose it is and he'll say he must have counted wrong.",
        bio = "Vosur Brakthel teaches alchemy in Tinker Town, where he is Tally Berryfizz's apprentice and friend. In Forever, his camping lesson teaches alchemists to make a Mana Well, a useful addition for spellcasters gathering at a camp.",
        backstory = "He speaks proudly of learning from Tally and has little patience for being mistaken for an engineer. His camping instruction takes the craft outside the shop: a practical skill should be useful when the city is a long walk behind you.",
        secret = "The extra cup is deliberate. He likes being able to offer someone a place by the fire without making a great ceremony of their arrival. It is easier if the cup is already there.",
        bestFriend = "That cup's yours, if you want it. No, you needn't bring a reason to sit down. Your company will do nicely.",
        favorite = { emote = "WELCOME", hint = "He appreciates a gesture that makes room for one more person in the company." },
        lines = {
            greet = { { "Aye, I'm ready. Packed an extra cup. Must have counted wrong again.", tone = "[genial dwarf, warm dry humor]" }, "A walk outside the shop! Let's see where the road takes us." },
            idle = { { "Tally teaches me something new most days. A good reason to keep turning up, that.", tone = "[proud affection, easy conversational warmth]" }, "Living in Tinker Town doesn't make a dwarf an engineer.", "Someone arriving late can still have a place by the fire." },
            befriended = { { "Glad to have you along. There's room for you in the company, and you needn't earn it twice.", tone = "[warm, welcoming, quietly sincere]" } },
            poke = { "Aye? Need something?", "Mind the bag. There's a cup in there for you." },
            learned = { { "There you go! Knowing how is a fine start. Now put it to use.", tone = "[encouraging, practical enthusiasm]" } },
            quest = { "Useful work. That's something to be pleased with." },
            rest = { "A little rest, a bit of company. Better than pushing on cross and tired." },
            group = { "More company! Come in, there's room." },
            loot = { "Useful on the road, perhaps. We should have a look." },
            levelUp = { "Well done! Tally would tell you to keep asking questions. So will I." },
            hearth = { "Back to Ironforge. I wonder what I'll learn at the workbench today." },
        },
    },
    [5107] = {
        quote = "Try sitting down in it before you buy it. You may spend your days standing heroically, but sooner or later you'll want a chair.",
        likes = { "Armor that lets its wearer move", "A worn piece brought in for repairs", "A customer checking the fit properly" },
        dislikes = { "Ignoring a strap until it gives way", "Buying armor only for the shine", "Assuming heavy means well fitted" },
        gossip = "Mangorn can discuss heavy armor until the lamps burn low. Ask what he wears off duty and he becomes oddly particular about the subject.",
        bio = "Mangorn Flinthammer sells heavy armor and offers repairs at the Ironforge Armory in the Commons. His trade includes chainmail and shields: ordinary equipment for travelers who need something dependable before they leave the city.",
        backstory = "Customers taught him to watch how they move in a new piece, not just how proudly they admire it. A short walk, a raised arm and a moment in a chair can reveal more about a purchase than a polished display ever will.",
        secret = "His slippers are extravagantly soft. He calls them recovery equipment. Anyone who questions the term receives a surprisingly thorough explanation of what a long day on one's feet requires.",
        bestFriend = "Set that weight down a moment. I've a chair for you. A friend shouldn't have to stand heroically through every conversation.",
        favorite = { emote = "FLEX", hint = "He approves of someone testing their freedom of movement before trusting a new piece of armor." },
        lines = {
            greet = { { "Ready. If anything pinches on the first hill, say so. No prizes for putting up with it.", tone = "[steady, practical dwarf, good-humored authority]" }, "A walk? Good. Equipment tells you more on the road than on a rack." },
            idle = { { "Soft slippers are recovery equipment. I'll defend that description as long as necessary.", tone = "[gravelly dry humor, mock solemn conviction]" }, "A bright polish can hide a poor fit. Lift your arms before you admire yourself.", "A worn strap is a small problem until it becomes a large one." },
            befriended = { { "Good company, you are. We can leave the sales talk at the counter for a while.", tone = "[warm, relaxed, plainly sincere]" } },
            poke = { "Checking for a weak point?", "Aye, I heard you. You needn't test the padding." },
            gear = { { "New armor? Walk a few steps. Sit down. Good. Now tell me how it feels.", tone = "[attentive craftsman, measured practical interest]" } },
            loot = { "Worth a look. Give the straps as much attention as the metal." },
            bagsFull = { "You needn't carry every bit of iron you find. Put some of the weight down." },
            quest = { "Work finished, and you back in one piece. A good day." },
            rest = { "There's the chair. Go on. It won't mind a little weight." },
            combatEnd = { "Everyone all right? Then we can see what needs fixing." },
            hearth = { "Back to the armory. And, eventually, my slippers." },
        },
    },

    -- Tally 5177: female gnome alchemy trainer in Berryfizz's shop;
    -- Vosur Brakthel is her apprentice and friend in their gossip.
    -- Fizzlebang 5569: male gnome fireworks seller, Things That Go Boom!
    -- No personal quest chain established. No speculative kinship used.
    -- docs/research/tally-and-fizzlebang.md.
    [5177] = {
        quote = "A good question is useful at any height. Bring yours to the workbench, and we'll see what we can learn.",
        likes = { "A pupil asking why a method works", "Seeing a lesson put to good use", "An apprentice willing to try again" },
        dislikes = { "Judging an alchemist by appearances", "Pretending to understand a step", "An unanswered question left forgotten" },
        gossip = "Tally keeps a notebook of difficult questions. New pupils worry it's a test. Her friends suspect she's the one still doing the homework.",
        bio = "Tally Berryfizz teaches alchemy in Berryfizz's Potions and Mixed Drinks in Tinker Town. The dwarf Vosur Brakthel is her apprentice and friend. Their conversations show respect across a considerable difference in height.",
        backstory = "Teaching has given her a steady supply of questions she might never have thought to ask herself. She treats a puzzled look as a reason to explain another way, and an unexpected answer as something worth testing carefully.",
        secret = "The notebook is hers. It holds questions she couldn't answer at once. Finding an answer later and telling the person who asked is one of her quiet pleasures.",
        bestFriend = "Ask me anything. I may have to say I don't know yet, but I know you won't think less of me for looking into it.",
        favorite = { emote = "THANK", hint = "Knowing that a lesson helped someone is a fine reward for teaching it." },
        lines = {
            greet = { { "A walk would be lovely. Tell me what you've been wondering about lately.", tone = "[warm teacher, relaxed curiosity]" }, "Ready. We may find a question worth bringing back to the workbench." },
            idle = { { "I keep the questions I couldn't answer. It would be a shame to stop learning just because I teach.", tone = "[thoughtful, quietly amused, candid]" }, "Vosur's a good apprentice. And a good friend. Both matter.", "A puzzled look is useful. It tells me where to begin again." },
            befriended = { { "You make it easy to ask a question of my own. I'm very glad to have your company.", tone = "[warm, appreciative, sincere]" } },
            poke = { "Yes? What would you like to know?", "One moment. I was trying to remember a question." },
            learned = { { "Good. Try explaining it in your own words. I'll listen.", tone = "[encouraging, patient, attentive]" } },
            quest = { "Useful work often begins with someone asking for help." },
            loot = { "Interesting. What do you suppose that was used for?" },
            rest = { "A good moment to look over the notes. Or simply let an idea settle." },
            levelUp = { "Well done. You've learned a great deal since we first spoke." },
            combatEnd = { "All here? Good. The questions can wait until we've caught our breath." },
            hearth = { "Back to the workbench. There may be a question waiting for me." },
        },
    },
    [5569] = {
        quote = "A celebration deserves a little color. A little more color. There! Now everyone knows something wonderful has happened.",
        likes = { "The first gasp from a watching crowd", "A good reason to celebrate", "An audience that remembers to cheer" },
        dislikes = { "Rain just before a display", "A celebration nobody looks up for", "Fireworks mistaken for ordinary cargo" },
        gossip = "Fizzlebang talks endlessly about the sky, yet during a display he seems to spend half his time looking the other way.",
        bio = "Fizzlebang Booms sells fireworks year-round in Tinker Town, Ironforge. His shop is Things That Go Boom! While holiday sellers come and go, his counter offers a little celebration without waiting for a festival.",
        backstory = "Selling fireworks has made him attentive to the reasons people buy them. Some arrive with an occasion already planned; others only want to mark a good day. He enjoys hearing the reason almost as much as making the sale.",
        secret = "He watches the crowd because he likes the moment their faces catch the light. The color disappears quickly. The look on someone's face is what he remembers.",
        bestFriend = "You don't need a grand occasion to come and see me. A friend turning up can be quite enough reason to celebrate.",
        favorite = { emote = "CHEER", hint = "An enthusiastic audience can make even a small celebration feel splendid." },
        lines = {
            greet = { { "An outing! Splendid. We may find something worth celebrating before we're back.", tone = "[genial showman, bright anticipation]" }, "Ready! I do enjoy hearing what the occasion is." },
            idle = { { "The best part? When the light catches everyone's faces. You can't put that in a box.", tone = "[fond, reflective, quietly delighted]" }, "A good day needn't be a holiday. I keep saying so.", "Every celebration begins with someone deciding it's worth the trouble." },
            befriended = { { "A new friend! Now that is a proper occasion. I'm pleased you came by.", tone = "[warm, celebratory, sincere pleasure]" } },
            poke = { "Is that my cue?", "Ah! You could have just said you were ready." },
            levelUp = { { "There it is! A good reason to make a splendid fuss over you!", tone = "[excited showman, generous enthusiasm]" } },
            quest = { "Another reason to smile. Shall we count that as an occasion?" },
            loot = { "Something special? Tell me the story. The occasion needs a story." },
            taxi = { "A fine view! Usually my stock gets to see this part." },
            rest = { "A little quiet between the grand moments. Rather pleasant, actually." },
            combatEnd = { "We're all here! That is absolutely worth celebrating." },
            hearth = { "Back to the shop. Someone may have good news to share." },
        },
    },

    -- Trixie 11029: female gnome Expert Engineer, Springspindle's Gadgets;
    -- Jemma's sister in Classic training gossip; plans an oversized baster.
    -- Soolie 5178: female gnome alchemy supplier, Berryfizz's Potions and
    -- Mixed Drinks. No personal quest chain found for either.
    -- docs/research/trixie-and-soolie.md separates facts and original hooks.
    [11029] = {
        quote = "If the turkey is too small for the baster, that is a problem with the turkey. The design remains magnificent.",
        likes = { "An ambition with room to grow", "Students ready for the next lesson", "A little admiration for a big idea" },
        dislikes = { "Being told to make it smaller", "Skipping Jemma's basic lessons", "Doors narrower than the prototype" },
        gossip = "Trixie's neighbors wonder how she'll find a turkey large enough for her plans. She seems more concerned about the dinner table.",
        bio = "Trixie Quikswitch teaches engineering at Springspindle's Gadgets in Tinker Town. Her sister Jemma covers the basics. Trixie's own conversation reveals plans for a turkey baster on a scale that leaves the turkey itself rather a problem.",
        backstory = "Lessons keep her working with useful little components, but her imagination rarely stays little for long. A kitchen tool becomes a grand project, and practical questions tend to arrive after she has settled on the impressive dimensions.",
        secret = "She has sketched a table for that impossible turkey dinner. The guest list matters more than the mechanism: she keeps adding chairs for people she likes.",
        bestFriend = "I've added a chair for you. Yes, the whole dinner is still theoretical. Your place at the table isn't.",
        favorite = { emote = "PRAISE", hint = "A bold proposal is easier to defend when someone appreciates the ambition." },
        lines = {
            greet = { { "An expedition! Excellent. Keep an eye out for exceptionally large poultry.", tone = "[confident, mischievously enthusiastic]" }, "I'm ready. We can discuss the dimensions as we walk." },
            idle = { { "The turkey is a separate engineering problem. I refuse to let it delay the baster.", tone = "[grand confidence, playful stubbornness]" }, "A small prototype? Certainly. How small is this room?", "The best part of a big dinner is having enough places for everyone." },
            befriended = { { "A new friend! I'll need a bigger table. That was going to happen anyway.", tone = "[bright affection, pleased amusement]" } },
            poke = { "Yes? Have you found the turkey?", "Careful. I'm calculating something impressive." },
            learned = { { "There! Once the basics hold together, you can try something gloriously unnecessary.", tone = "[encouraging, conspiratorial delight]" } },
            gear = { "New equipment? Can it do anything on a larger scale?" },
            loot = { "A useful component. Perhaps several of them would be even more useful." },
            bagsFull = { "You see? Thinking bigger eventually becomes a practical necessity." },
            levelUp = { "A bigger challenge next, I think. You're ready for one." },
            quest = { "Finished! Now we can consider the ambitious version." },
            hearth = { "Back to the workshop. I need to measure a doorway." },
        },
    },
    [5178] = {
        quote = "Please read the label before asking what it tastes like. That saves a surprising amount of trouble at an alchemy counter.",
        likes = { "A customer who knows which vial fits", "A clear label facing outward", "A friendly smile across the counter" },
        dislikes = { "Bottles put back on the wrong shelf", "Guessing a potion by its color", "Sticky fingers on clean glass" },
        gossip = "Soolie can make an empty bottle sound like an excellent purchase. Her own favorite drink apparently needs very little description.",
        bio = "Soolie Berryfizz sells alchemy supplies in Berryfizz's Potions and Mixed Drinks in Tinker Town. Her stock includes vials and alchemical recipes. She supplies the workbench; the person buying the ingredients still has to do the brewing.",
        backstory = "A supply counter taught her that small mistakes can travel home in someone's bag. She prefers a quick question before a sale to a long explanation afterward, and likes sending people away properly prepared.",
        secret = "She writes grand descriptions of plain water in a private notebook: splendid clarity, dependable flavor, no unexpected transformations. It remains her favorite drink.",
        bestFriend = "I can offer you something wonderfully ordinary. Clean cup, fresh water, and a little time to sit. You've earned that much.",
        favorite = { emote = "SMILE", hint = "She welcomes a pleasant face, even when its owner hasn't come to buy anything." },
        lines = {
            greet = { { "A little walk sounds pleasant. Are all those bottles closed properly?", tone = "[composed, friendly, lightly practical]" }, "Ready. I've left the shelves in order. Let us hope they stay that way." },
            idle = { { "Plain water. Excellent clarity, no surprises. I remain a devoted customer.", tone = "[dryly amused, quietly content]" }, "The label is there to save you a very inconvenient guess.", "An empty vial is only boring until you need one." },
            befriended = { { "You needn't find an excuse to visit. A smile and a little conversation are quite enough.", tone = "[warm, welcoming, sincerely pleased]" } },
            poke = { "Yes? Did something leak?", "I'm listening. You can leave the bottles where they are." },
            loot = { { "An intact container is worth keeping. Just find out what was in it first.", tone = "[practical, attentive, gentle humor]" } },
            bagsFull = { "Let us separate the fragile things before we rearrange anything." },
            quest = { "Properly supplied and safely back. A good result." },
            rest = { "A clean cup and a moment's peace. Very little preparation required." },
            combatEnd = { "Everyone well? Good. We can check for broken glass afterward." },
            levelUp = { "Well done. Still, read the label. Experience doesn't change what's in the bottle." },
            hearth = { "Back to the counter. I hope someone remembered to wipe it down." },
        },
    },

    -- Jemma 11028 and Springspindle 5174: female/male gnome engineers in
    -- Springspindle's Gadgets, Tinker Town. Jemma's Forever archive quest
    -- 95041 is in the installed quest corpus; Springspindle's Classic
    -- specialization referrals are 3629/3632. Research notes distinguish
    -- captured corpus, historical mechanics and original private hooks.
    -- docs/research/jemma-and-springspindle.md.
    [11028] = {
        quote = "An archive can hold a brilliant equation and a family recipe. I'd rather not lose either. Both took someone years to get right.",
        likes = { "A learner's first working gadget", "News of an exciting new invention", "Family knowledge carefully preserved" },
        dislikes = { "A tiny hole in an important bag", "Old recipes dismissed as unimportant", "Being compared with her sister" },
        gossip = "Jemma loves news of new gadgets. Ask her about a family recipe, though, and she can be just as interested in something old.",
        bio = "Jemma Quikswitch teaches engineering in Springspindle's Gadgets in Tinker Town. In Forever's Data Hoarders, she seeks lost punch cards needed to recover family archives, from technical designs to Grandma Quikswitch's chili recipe.",
        backstory = "Before fleeing Gnomeregan, Jemma copied her family's records. Only in Ironforge did she discover the hole in her pack and the missing cards. The scattered data threatens to leave generations of work unreadable.",
        secret = "She wants the chili recipe back for more than the ingredients. She hopes making a familiar meal might help a borrowed kitchen feel a little more like home.",
        bestFriend = "When I can make that chili again, you must come and try it. I want you in some of the happy memories still to come.",
        favorite = { emote = "APPLAUD", hint = "She knows how much a little recognition can mean after a successful first attempt." },
        lines = {
            greet = { { "Ready! New things to see, and a bag I've checked for holes. Twice.", tone = "[bright, eager, wry amusement]" }, "An outing! Tell me if you spot an interesting gadget." },
            idle = { { "Equations and a chili recipe. I couldn't tell you which my family would argue about more.", tone = "[fond, lightly amused, thoughtful warmth]" }, "The first time a little device works is worth remembering.", "Something doesn't have to be new to be worth keeping." },
            befriended = { { "You understand why the little things matter. I'm glad we're making some new memories together.", tone = "[warm, sincere, quietly pleased]" } },
            poke = { "Yes? Another question? Good, ask!", "Checking the bag? So was I." },
            learned = { { "There! You know something you didn't know this morning. Try it while it's fresh.", tone = "[encouraging teacher, bright enthusiasm]" } },
            loot = { "Careful with that. Small things can hold a surprising amount." },
            bagsFull = { "Let's check the seams before we add one more thing." },
            gear = { "A new design? Turn a little. I'd like to see how it fits together." },
            quest = { "Someone trusted you with something that mattered. You did well." },
            levelUp = { "Look how far you've come! You should be proud of that." },
            hearth = { "Home for now. Perhaps there's time to make something warm." },
        },
    },
    [5174] = {
        quote = "A clever device ought to make life easier. If explaining it takes longer than doing the job by hand, we have another problem to solve.",
        likes = { "An idea that makes daily life easier", "A student asking a precise question", "A well-considered nod of understanding" },
        dislikes = { "Mistaking a loud noise for progress", "Skipping the explanation of a choice", "A cup of tea gone cold while he talks" },
        gossip = "Springspindle can make a simple question last an entire cup of tea. His pupils suspect the next invention should keep it warm.",
        bio = "Springspindle Fizzlegear trains engineers in his Tinker Town shop. His Classic referrals send students to Overspark in Ironforge or Nixx in Gadgetzan. He strongly favors gnomish devices, though he explains both disciplines.",
        backstory = "Teaching gives him plenty of chances to describe how engineering might improve ordinary life. He enjoys grand possibilities, but a student's careful question can bring him back to the small practical step that comes next.",
        secret = "His simplest teaching aid is his tea. If it has gone cold before a pupil gets to ask a question, he takes it as a sign that he has been explaining for too long.",
        bestFriend = "You've heard enough theory for one afternoon. Let's have some tea while it's warm. Tell me what you've been doing.",
        favorite = { emote = "NOD", hint = "He appreciates knowing that you've followed the reasoning before choosing a next step." },
        lines = {
            greet = { { "A practical excursion. Excellent. Theory benefits from the occasional walk.", tone = "[confident, measured, pleasantly curious]" }, "Ready. You can tell me which parts of the journey could use improving." },
            idle = { { "Cold tea again. I may have explained the principle rather more thoroughly than necessary.", tone = "[dry self-awareness, rueful amusement]" }, "A device should solve a problem. Preferably without creating three more.", "What would make this ordinary task a little easier? Start there." },
            befriended = { { "You ask good questions, and you let me know when I've talked enough. I value both.", tone = "[warm, appreciative, understated humor]" } },
            poke = { "Yes? Which part needs explaining?", "Ah. A demonstration of direct mechanical input." },
            learned = { { "Good. Now explain why it works. If you can do that, the lesson has taken.", tone = "[patient, precise, encouraging teacher]" } },
            gear = { "An improvement? Let us judge by what it does for you." },
            loot = { "Interesting. Useful as it stands, or useful as a collection of parts?" },
            quest = { "A practical application, and a result to learn from." },
            bagsFull = { "A familiar problem. More compartments are not always the answer." },
            levelUp = { "Progress. Well earned. Consider what you'd like to understand next." },
            hearth = { "Back to the shop. I think the next discussion should begin with fresh tea." },
        },
    },

    -- Klockmort 6169 and Castpipe 7950: male gnomes in Tinker Town.
    -- Blacksmith/researcher and mechanic/data recovery organizer. Classic
    -- chains and modest original hooks: docs/research/klockmort-and-castpipe.md.
    [6169] = {
        quote = "A good idea is wonderful. A good idea shared with another smith? Now we can both make something astonishing!",
        likes = { "A colleague sharing a new technique", "An experiment ready for its first test", "Someone joining in his excitement" },
        dislikes = { "A breakthrough kept to oneself", "Missing the one essential component", "Being told to contain his enthusiasm" },
        gossip = "When Klockmort gets a promising letter, the whole workshop knows before he's finished reading it. Sometimes the next workshop knows too.",
        bio = "Klockmort Spannerspan is a blacksmith in Tinker Town. Furen Longbeard's techniques inspire his armor work, while Mathiel sends help for his Gnomeregan research. He also points adventurers toward the Brassbolts brothers' latest needs.",
        backstory = "The exodus left useful components behind in Gnomeregan. Klockmort seeks essential artificials for new experiments. His eagerness for tougher materials goes hand in hand with his delight in another craftsperson's discoveries.",
        secret = "He practices a short, dignified thank-you before someone brings him good news. It never survives the actual meeting. He has decided this is probably a good thing.",
        bestFriend = "I had a very sensible speech prepared. Oh, never mind it! You're here, and I'm delighted, and you know the rest!",
        favorite = { emote = "CHEER", hint = "When an idea excites him, he hopes someone else will share the feeling." },
        lines = {
            greet = { { "An outing! Splendid! I may have a thought or two along the way. Or twelve!", tone = "[buoyant, rapid enthusiasm, delighted]" }, "Tools packed, ideas plentiful! What shall we try first?" },
            idle = { { "I meant to say thank you calmly. Then I saw what they'd brought me. Impossible!", tone = "[cheerfully self-aware, bubbling excitement]" }, "A clever technique travels farther when you tell another smith.", "The first test! That little moment before you find out! Wonderful!" },
            befriended = { { "You listen when I get excited! And you come back for the next idea! What a splendid friend!", tone = "[effusive, warm, sincerely delighted]" } },
            poke = { "Yes! What is it? Something marvelous?", "Oh! I thought of something! No, wait. That was you." },
            learned = { { "Again, please! Slower this time! I want to understand every bit of it!", tone = "[eager, fascinated, inviting explanation]" } },
            gear = { "A new piece! How does it move? How does it hold? So many questions!" },
            loot = { "Perhaps that's the very thing someone needs for a breakthrough!" },
            quest = { "Useful work! Someone can get started now!" },
            levelUp = { "Better already! Imagine what you'll be able to do next!" },
            combatEnd = { "All in one piece? Excellent! A result worth celebrating!" },
            hearth = { "Back to the workshop! I must write that idea down before it escapes!" },
        },
    },
    [7950] = {
        quote = "A machine can be replaced. The information it held may be rather more difficult. Please keep the card dry.",
        likes = { "A complete and legible record", "Security steps followed in order", "The person who remembers to say thanks" },
        dislikes = { "Data dismissed as a few old numbers", "Punch cards used as coasters", "An urgent note without any details" },
        gossip = "Castpipe marks so many papers urgent that his neighbors wonder how he chooses what to read first. He says the answer needs a diagram.",
        bio = "Master Mechanic Castpipe organizes data recovery missions from Tinker Town. Gaxim Rustfizzle directs adventurers to him. Castpipe needs a prismatic punch card from Gnomeregan's secured terminals to retrieve information left behind.",
        backstory = "Fleeing Gnomeregan meant leaving vital data and security cards inside. Reaching the highest-clearance terminal requires working through lower ones first. Castpipe's anxious instructions reflect how much he fears losing what remains.",
        secret = "Among his careful records is a crooked drawing a friend made of him. It contains no useful measurements. He has made a second copy anyway, in case something happens to the first.",
        bestFriend = "I remembered to make a copy of the drawing. I should also remember to tell you why I keep it. It makes me smile.",
        favorite = { emote = "THANK", hint = "He knows how much a recovery depends on someone else's care and effort." },
        lines = {
            greet = { { "Ready. Have we packed everything? Check once more. Then we can be ready properly.", tone = "[brisk, meticulous, slightly anxious]" }, "A journey! There will be details worth recording. I brought paper." },
            idle = { { "Yes, I copied the little drawing too. Some things matter without being useful.", tone = "[quietly fond, a little self-conscious]" }, "Write down the step you took, not merely that it didn't work.", "A label that says important is less helpful when every label says important." },
            befriended = { { "You take care with things other people might overlook. I am very glad to have you here.", tone = "[earnest, warmly grateful, unhurried]" } },
            poke = { "One moment. I nearly lost my place.", "Yes? Please begin with the relevant details." },
            mail = { { "A message! Keep the envelope a moment. There may be a useful note on the back.", tone = "[alert curiosity, careful professional interest]" } },
            quest = { "Recovered, delivered, accounted for. A very satisfying sequence." },
            loot = { "Before we discard anything, let's establish what it is." },
            bagsFull = { "Do not fold the cards to make room. We shall rearrange the bag." },
            learned = { "A new method. Excellent. Explain it while I write." },
            combatEnd = { "Everyone safe? Good. Now I can worry about the records." },
            hearth = { "Home. A dry desk, a proper lamp, and time to put this in order." },
        },
    },

    -- Gnoarn 6569, male gnome, Tinker Town, Ironforge. Classic quest
    -- referrals 2039/2041/2927: Bingles, Shoni and Ozzie; radiation hair loss.
    -- Gearcutter 5175 is a male gnome engineering supplier in Tinker Town.
    -- Original private hooks; sources: docs/research/gnoarn-and-gearcutter.md.
    [6569] = {
        quote = "A city can be rebuilt. A magnificent head of hair may take longer. We must remain ambitious on both fronts.",
        likes = { "A missing colleague reporting in", "Plans to reclaim Gnomeregan", "Recognition of former magnificence" },
        dislikes = { "Reports that are a week overdue", "Troggs near anything important", "Suggestions that a hat would do" },
        gossip = "Gnoarn can turn a question about his hair into a briefing on Gnomeregan. Nobody quite knows where one subject ends.",
        bio = "From Tinker Town, Gnoarn sends help after the missing Bingles and toward Shoni's underground assault plans. He also directs adventurers to Ozzie's experiments in Kharanos. His lost city remains very much on his mind.",
        backstory = "Radiation in Gnomeregan cost Gnoarn his celebrated hair. Ozzie witnessed the loss; beneath Gnoarn's furious complaints lies his determination to reclaim the city and find help for the sickness left behind.",
        secret = "He still carries a comb. He calls it a statement of confidence in the research. On difficult days, it helps to have a small, ordinary thing worth hoping to use again.",
        bestFriend = "If I'm overdue, you will come looking, won't you? Good. I shall do the same. No one should wonder alone.",
        favorite = { emote = "PRAISE", hint = "A little admiration might reassure him that his finest qualities survived." },
        lines = {
            greet = { { "Ready! If anyone asks, my hair was considerably taller than this.", tone = "[brisk, theatrical pride, dry humor]" }, "An expedition with a reliable companion. An encouraging start!" },
            idle = { { "A comb? Certainly. One must be prepared for a scientific breakthrough.", tone = "[defensive pride softening into hopeful amusement]" }, "A report needn't be impressive. Arrived safely will do.", "I can worry about Gnomeregan and my appearance at the same time." },
            befriended = { { "You keep coming back. That matters rather more than a magnificent entrance.", tone = "[warm, sincere, restrained relief]" } },
            poke = { "Yes, that's the top of my head. We have established that.", "A written report would be less startling." },
            quest = { "Good. Someone waiting for news may finally breathe a little easier." },
            mail = { "News? Please let it begin with everyone being alive." },
            taxi = { { "Should we be late, please make certain someone knows where to look.", tone = "[trying to sound practical, a little anxious]" } },
            landed = { "Safely down! An excellent detail for the report." },
            combatEnd = { "Everyone here? Count people before anything else." },
            levelUp = { "Progress! Visible, measurable progress. I approve." },
            hearth = { "Back to Ironforge. There may be news waiting." },
        },
    },
    [5175] = {
        quote = "Bring the part you're replacing. 'A little round thing' describes half my stock and several of my customers.",
        likes = { "A sample brought to the counter", "Parts returned to the proper drawer", "A customer who follows the explanation" },
        dislikes = { "Measurements taken with a thumb", "Loose screws mixed with the change", "Being asked for the exploding version" },
        gossip = "Gearcutter can recognize a component from a terrible sketch. He keeps the worst sketches because he enjoys the challenge.",
        bio = "Gearcutter Cogspinner sells engineering supplies in Ironforge's Tinker Town. Among the district's busy workshops, his counter is a place to find the small components a much larger idea depends on.",
        backstory = "Explaining why two similar parts weren't interchangeable became one of his favorite parts of the trade. He began keeping rough customer drawings, pleased when a few questions turned a mystery into a useful purchase.",
        secret = "A little wooden puzzle has defeated him for weeks. It has no gears, springs or hidden latch. He checks for them again whenever he gets stuck, just in case.",
        bestFriend = "I can admit I haven't worked it out yet when you're here. Pull up a chair. Perhaps we're both missing the obvious bit.",
        favorite = { emote = "NOD", hint = "He likes to know that a careful explanation has made sense." },
        lines = {
            greet = { { "I've packed the essentials. If we need a drawer, we'll have to improvise.", tone = "[brisk, practical, lightly amused]" }, "A field trip! Show me what all these parts are being used for." },
            idle = { { "This wooden puzzle is clearly missing a gear. No, I haven't proved that.", tone = "[puzzled, stubborn, comic understatement]" }, "A clear drawing saves everyone a very long conversation.", "There's something satisfying about a part that fits on the first attempt." },
            befriended = { { "You listen to the explanation and stay for the conversation. I like that.", tone = "[warm, understated, sincerely pleased]" } },
            poke = { "You could just ask which pocket it's in.", "Careful. Some of those pockets are sorted." },
            loot = { { "Before you sell that, let me see how the pieces fit together.", tone = "[curious, absorbed professional interest]" } },
            bagsFull = { "One bag for parts and one for everything else. It works until you find more parts." },
            quest = { "There. A practical result. Always pleasing." },
            gear = { "Does it fit properly? Looking impressive is the easier half." },
            learned = { "Show me that again, slowly. I'd like to understand it." },
            levelUp = { "Well done! Experience is the part nobody can sell you." },
            hearth = { "Back to the counter. I hope nobody has rearranged the drawers." },
        },
    },


    -- Sara Balloo 2695: female dwarf, Ironforge; Sully's wife, mother,
    -- Classic letter/plea/memorial chain 637,683,686,689,700. No assumed
    -- player completion or literal ghost visit. Rotimer 13843: male dwarf,
    -- Stormpike recruiter, referral 7261; his territorial claims are his
    -- position, not neutral history. docs/research/balloo-and-rotimer.md.
    [2695] = {
        quote = "A name means more when someone remembers the person behind it. There is always more to a life than the way it ended.",
        likes = { "Letters carried with care", "A familiar name spoken kindly", "Company that allows a little quiet" },
        dislikes = { "A family's loss dismissed as a number", "Being hurried through a memory", "Kindness offered only for a reward" },
        gossip = "Sara listens closely when someone speaks of home. She often asks about the small things a traveler hadn't thought to mention.",
        bio = "Sara Balloo lives in Ironforge. Her husband Sully's last letter and her appeal to King Magni form a quest story about loss, the cost of war and a memorial to a soldier who was also a husband and father.",
        backstory = "Sully wrote of his love for Sara and their children before taking watch at Thandol Span. Her own plea asks what remains of the life people fight to preserve when so many loved ones are lost defending it.",
        secret = "She wishes people would sometimes ask what made Sully laugh. She wants room for the ordinary, happy memories alongside the sorrow, even when she needs time to find the words.",
        bestFriend = "I could tell you something about Sully today. Something small, and happy. Stay a little while, if you have the time.",
        favorite = { emote = "COMFORT", hint = "A gentle gesture of support can be kinder than trying to find the perfect words." },
        lines = {
            greet = { { "A little walk would be welcome. Thank you for asking me along.", tone = "[soft, composed voice, quiet gratitude]" }, "Yes, I'm ready. We needn't hurry, if that's all right." },
            idle = { { "Tell me something ordinary about your home. Those are often the things worth remembering.", tone = "[gentle, thoughtful voice, warm curiosity]" }, "A person's name should bring a whole life to mind, not only a loss.", "It's a pleasant day to have someone walking beside you." },
            befriended = { { "You make room for whatever sort of day I'm having. I don't take that kindness lightly.", tone = "[warm, moved voice, restrained sincerity]" } },
            poke = { "Yes? I was a little lost in thought.", "I'm listening. Take your time." },
            mail = { { "A letter. I hope someone far away has remembered to write of the little things.", tone = "[gentle voice, reflective tenderness]" } },
            quest = { "Someone will remember the care you took, even if they cannot repay it." },
            loot = { "Something to keep? I hope it brings you a good memory." },
            rest = { "We can sit quietly a moment. I don't mind." },
            combatEnd = { "We're all here? Please, let us be sure before we move on." },
            levelUp = { "I'm glad to see you doing well. You should let the people who love you know." },
            hearth = { "Home. Such a small word for so much." },
        },
    },
    [13843] = {
        quote = "If you mean to serve, know where you're reporting and what you're agreeing to. A grand declaration is no substitute for arriving prepared.",
        likes = { "A recruit who listens to the briefing", "Orders repeated back correctly", "A firm and ready salute" },
        dislikes = { "Treating an assignment as a tavern dare", "Boasts without preparation", "A briefing interrupted halfway through" },
        gossip = "Rotimer can turn a simple direction into a speech. The recruits listen carefully for the part that tells them where to go.",
        bio = "Lieutenant Rotimer recruits for the Stormpike Guard in Ironforge. He argues Ironforge's claim to Alterac and directs volunteers to Lieutenant Haggerdin outside the entrance to Alterac Valley.",
        backstory = "His recruitment appeal speaks forcefully of the king, contested land and the enemies facing the Stormpike. In daily work, that certainty comes with lengthy briefings: he wants each listener to understand the duty before setting out.",
        secret = "He practices giving directions in one short sentence. Alone, he manages it. With an audience, the importance of the occasion usually demands another three.",
        bestFriend = "You're welcome beside me. There. One sentence. I thought you'd appreciate the effort, even if it lacked a proper introduction.",
        favorite = { emote = "SALUTE", hint = "A disciplined acknowledgment is a good beginning with a recruitment officer." },
        lines = {
            greet = { { "Ready to move? Good. I'll keep the instructions brief. That is my intention, at least.", tone = "[firm, formal voice, dry self-awareness]" }, "A walk, then. We ought to agree on a destination before discussing its significance." },
            idle = { { "A clear instruction, properly understood, saves a good deal of marching in the wrong direction.", tone = "[precise, authoritative voice, earnest instruction]" }, "Readiness is less impressive to watch than boasting. Much more useful, though.", "I had a shorter way to put that. It seems to have escaped me." },
            befriended = { { "You hear me out, and you tell me when I've said enough. A useful friend, and a welcome one.", tone = "[reserved, sincere voice, measured warmth]" } },
            poke = { "Yes? State your question.", "One moment. I haven't reached the instructions yet." },
            quest = { { "Assignment completed. Good. Give a clear report of what happened.", tone = "[firm, approving voice, professional satisfaction]" } },
            loot = { "Account for what you're carrying before you find you need it." },
            bagsFull = { "A full pack isn't the same as a prepared one. Check the contents." },
            zone = { "New ground. Establish where you're going before setting off." },
            rest = { "A sensible halt. Use it properly, and we'll move on ready." },
            combatEnd = { "Check the company. Nobody moves on merely because the noise has stopped." },
            levelUp = { "Progress worth acknowledging. Carry it with discipline." },
            hearth = { "Back to Ironforge. I should review the next briefing. Briefly." },
        },
    },

    -- Ironforge dwarves: Soleil 5099 (female, banker), Myra 5109 (female,
    -- wandering bread vendor, Commons), Sognar 5124 (male, wandering meat
    -- vendor, Military Ward). No exact Stonemantle kinship, later haggis
    -- daily or Bronze Celebration visit imported. Original private hooks:
    -- docs/research/ironforge-banker-and-vendors.md.
    [5099] = {
        quote = "Take a moment and tell me what you need. A clear question is a much better beginning than emptying your whole pack onto the counter.",
        likes = { "A label someone can read", "A question asked without embarrassment", "A place for everything" },
        dislikes = { "Loose ink among stored belongings", "A queue turned into a shouting match", "Being hurried through a careful check" },
        gossip = "Soleil keeps the counter beautifully ordered. Nobody is quite sure why she never opens her own bag where customers can see it.",
        bio = "Soleil Stonemantle is a banker at the Vault of Ironforge. Alongside the city's other bankers, she helps visitors store belongings and retrieve what they need for their next journey.",
        backstory = "Keeping other people's belongings in order gave her a fondness for clear labels and patient questions. Her own things are another matter: the useful, the interesting and the just-in-case all find their way into one stubbornly full bag.",
        secret = "Her own bag is a jumble of perfectly good things she hasn't found the right place for yet. She has a system planned. She has had it planned for quite some time.",
        bestFriend = "All right, you may laugh at the bag. Then help me decide what stays. Apparently I give better advice from behind a counter.",
        favorite = { emote = "NOD", hint = "A calm acknowledgment will help a careful banker know you've understood each other." },
        lines = {
            greet = { { "A walk? Certainly. Give me a moment to find what I put in this bag.", tone = "[composed voice, small self-conscious amusement]" }, "Ready at last. Everything important is here. Somewhere." },
            idle = { { "It's easier to organize someone else's belongings. Their just-in-case things are less persuasive.", tone = "[dryly amused voice, candid warmth]" }, "A clear label is a kindness to your future self.", "I know exactly where I'd keep this if it belonged to a customer." },
            befriended = { { "You let me be a little untidy without worrying that I've forgotten how to do my work. Thank you.", tone = "[warm, sincerely grateful voice]" } },
            poke = { "Yes? One question at a time, please.", "I've heard you. Let me finish checking." },
            loot = { "Useful, interesting, or just in case? Ah. I know that answer." },
            bagsFull = { { "Set it down and sort through it. Yes, I should take that advice myself.", tone = "[practical voice, rueful good humor]" } },
            quest = { "A little care at the beginning saves trouble at the end." },
            rest = { "A good chance to set this bag down. Perhaps not to open it." },
            levelUp = { "Well done. Some progress doesn't need a label to be obvious." },
            combatEnd = { "Everyone accounted for? Good. The belongings can wait." },
            hearth = { "Back to the vault. Perhaps today I'll sort out my own things." },
        },
    },
    [5109] = {
        quote = "Fresh bread! There, now you've heard the important news. What else has the morning brought you?",
        likes = { "A familiar face on her round", "Bread shared while it's fresh", "An echo with a good strong answer" },
        dislikes = { "Loaves crushed under someone's gear", "A doorway blocked by a long argument", "A greeting nobody bothers to return" },
        gossip = "Myra's call reaches a good way across the Commons. Sometimes she pauses as if she's waiting for the city to answer.",
        bio = "Myra Tyrngaarde is a wandering bread vendor in Ironforge's Commons. Her calls advertise fresh bread as she makes her way among the city's visitors and residents.",
        backstory = "Making herself heard in a busy city gave her a strong calling voice. In quieter moments, she began noticing how different corners answered it. A familiar round acquired little places where the echo was worth listening for.",
        secret = "She has a favorite echo. It's quite possible she gives that corner a better sales call than anywhere else, though the stone has yet to buy a loaf.",
        bestFriend = "Listen to this corner. A fine answer, eh? Now you try. We can't let a bit of stone have the last word every time.",
        favorite = { emote = "GREET", hint = "A greeting called back with warmth makes a busy vendor's round much more cheerful." },
        lines = {
            greet = { { "There you are! Ready for a round with a little more scenery?", tone = "[bright, carrying voice, hearty welcome]" }, "A different road today. I wonder how well the sound travels here." },
            idle = { { "A good echo makes a fine customer. Listens carefully, agrees with every word, never buys a thing.", tone = "[playful, expansive voice, amused delight]" }, "You'd be surprised which little corner answers back the clearest.", "Fresh bread and a familiar greeting. Not a bad start to a day." },
            befriended = { { "I can pick your greeting out of a crowd now. Always glad to hear it.", tone = "[warm, pleased voice, personal affection]" } },
            poke = { "Yes? No need to shout; that's usually my part.", "Something you meant to ask before I get going?" },
            loot = { "Keep that away from the bread. Nobody wants grit with their crust." },
            bagsFull = { "Leave a little space at the top if you want lunch to look like lunch." },
            quest = { "Good news to carry home, then!" },
            zone = { { "New streets, new corners. Give me a moment to hear what this place sounds like.", tone = "[curious, lively voice, cheerful anticipation]" } },
            rest = { "A quiet bite. Even I don't need to fill every moment with a call." },
            levelUp = { "Well done! There's something worth calling out." },
            hearth = { "Back to the Commons. I expect the echoes have missed me." },
        },
    },
    [5124] = {
        quote = "Tell me what you're planning for supper before you buy enough to feed the whole ward. Unless that is your plan. Then we'd best start counting.",
        likes = { "A meal everyone gets a share of", "A clear answer about portions", "A joke told with a straight face" },
        dislikes = { "Food wasted for the sake of a boast", "A parcel left in the wrong place", "Being asked for lunch after it's gone" },
        gossip = "Sognar remembers who takes the largest helping. He remembers who quietly makes sure everyone else has one, too.",
        bio = "Sognar Cliffbeard is a wandering meat vendor in Ironforge's Military Ward. He sells provisions to visitors making their way through that part of the city.",
        backstory = "Supplying people's meals made him attentive to how much they actually needed. Over time, he took an interest in the quieter customer choosing enough for someone else, and learned to ask a second question before wrapping the parcel.",
        secret = "When he eats with others, he likes pretending there's one portion less than there is. He keeps the last one tucked aside, ready for whoever insists they aren't hungry.",
        bestFriend = "Not hungry? Aye, I thought you'd say that. I've a portion set aside. Come sit down before it proves me right.",
        favorite = { emote = "GRIN", hint = "An appreciative grin will suit a vendor who enjoys a quiet joke with his customers." },
        lines = {
            greet = { { "Off somewhere? Tell me how many we're feeding, and I'll come along.", tone = "[grounded, genial voice, practical welcome]" }, "A walk sounds good. Let's settle the provisions before we get too far." },
            idle = { { "There's always someone who says they aren't hungry until everyone else starts eating.", tone = "[dryly amused voice, knowing warmth]" }, "A meal goes further when somebody remembers to count the people first.", "Keep the parcel handy. Buried food tends to become forgotten food." },
            befriended = { { "You check whether I've had a share, too. That's the sort of friend I like beside me.", tone = "[warm, sincere voice, unshowy gratitude]" } },
            poke = { "Aye? You're not hungry already?", "One moment. I'm counting, and I'd prefer to do it once." },
            loot = { "Wrap that apart from the food, unless you want an interesting supper." },
            bagsFull = { "Something came in. Something may have to come out. Preferably before it spoils." },
            quest = { "A job done properly. Let's see who's ready for a meal." },
            rest = { { "Come sit down. I've allowed for the one who was certain they wouldn't want anything.", tone = "[genial voice, gentle teasing, hospitable warmth]" } },
            combatEnd = { "All safe? Then sit a moment before anyone tries being impressive again." },
            levelUp = { "Well done! An appetite for progress, eh?" },
            hearth = { "Back to Ironforge. I wonder who'll be asking about supper." },
        },
    },

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
