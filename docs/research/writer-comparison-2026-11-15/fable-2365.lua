    -- Bront Coldcleave <Butcher>, Southshore, Hillsbrad Foothills. Human,
    -- male. Facts: a meat vendor with no quests or gossip. Sells Cured Ham
    -- Steak, Haunch of Meat, Mutton Chop, Roasted Quail, Tough Jerky and
    -- Wild Hog Shank. His map pin is on the west side of town, north of the
    -- town hall where Marshal Redpath stands ("Crushridge Bounty"). The fish
    -- trade (Hal McAllister, Lindea and Donald Rabonne) is down at the
    -- docks; Chef Jessen at the inn gives "Soothing Turtle Bisque";
    -- Southshore Guards patrol the town. That recruits take his name for a
    -- soldier's, that he never corrects them and that he enjoys the salutes
    -- are ours.
    [2365] = {
        quote = "Bront Coldcleave. No, I don't talk about it. Now: ham, mutton or quail?",
        likes = { "A cold cellar and a sharp edge", "Customers who know a chop from a shank",
            "Wind that blows the fish smell out to sea" },
        dislikes = { "Being asked which battle", "Complaints that the Tough Jerky is tough",
            "Chef Jessen calling turtle a meat" },
        gossip = "Every recruit new to Southshore hears the name Bront Coldcleave and salutes, just in case. "
            .. "The town has never corrected one. Neither has Bront.",
        bio = "Bront Coldcleave is Southshore's butcher: ham, mutton, hog shank and quail, sold well back "
            .. "from the docks and the smell of the fish trade. The Southshore Guard marches on his jerky, and "
            .. "Chef Jessen at the inn would still rather cook turtle.",
        backstory = "A man named Coldcleave has two trades open to him, he says, and he picked the one with "
            .. "supper in it. The name still does the other job. Twice Marshal Redpath has offered him a patrol "
            .. "on the strength of it, and twice Bront has sent him away with a ham instead.",
        secret = "The salutes have gone to his head a little. When a column marches past, he takes up the "
            .. "big cleaver and sharpens it, slowly, eyes on the horizon.",
        bestFriend = "There's nothing to talk about. Never was. Only you know. Here, the good ham, from the "
            .. "back. Don't salute. Oh, go on. Once.",
        favorite = { emote = "SALUTE", hint = "Recruits keep doing it by mistake. He has stopped minding." },
        recordingVoice = "human-male",
        lines = {
            greet = { { "Shop's shut. The cleaver comes along. Don't read into it.", tone = "[gruff] [dry]" },
                "Lead on. If anyone salutes, we keep walking." },
            idle = { { "Wind's off the docks. Smell that? That's why I sell ham.", tone = "[gruff] [grumbling]" },
                "It's called Tough Jerky. I don't know what people expect.",
                "Jessen's stewing turtle again. Turtle. I ask you." },
            befriended = { { "Call me Bront. 'Coldcleave' is for the recruits.", tone = "[gruff] [pleased]" } },
            poke = { "Poke the ham, not the butcher.", "No, I still don't talk about it." },
            combatStart = { "Against the grain! Always cut against the grain!" },
            combatEnd = { { "Clean work. You've a butcher's wrist.", tone = "[gruff] [approving]" } },
            lowHealth = { "You've gone gray as old mutton. Eat something!" },
            loot = { { "{item}? Can't eat it, can't cure it. Well done, I suppose.",
                say = "Can't eat it, can't cure it. Well done, I suppose." } },
            rest = { "An inn. If it's fish for supper, I brought my own jerky." },
            mount = { "Fine animal. Good shoulders. Relax, I'm off duty." },
            saluteBack = { "At ease. Wait. No. I sell mutton. Stop that." },
        },
    },
