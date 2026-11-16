    -- Bront Coldcleave <Butcher>, Southshore, Hillsbrad Foothills. Human, male.
    -- Facts: Southshore's butcher, selling Cured Ham Steak, Haunch of Meat,
    -- Mutton Chop, Roasted Quail, Tough Jerky and Wild Hog Shank. No quests or
    -- gossip found. Southshore is a fishing town: Hal McAllister sells fish,
    -- Chef Jessen is known for Soothing Turtle Bisque, the inn is Innkeeper
    -- Anderson's, and Tarren Mill lies to the north. Removed from Hillsbrad in
    -- 4.0.3a; present in the Classic-era town. The yeti tale, his years
    -- splitting ice for Hal's fish cart and the origin of his name are ours.
    [2365] = {
        quote = "Ham, mutton, quail, hog. Four good reasons to walk past the fish. The jerky's a fifth, if you're "
            .. "headed into the hills.",
        likes = { "A clean cut on the first stroke", "Mutton chops (the meal and the whiskers)",
            "Customers who walk past the fish" },
        dislikes = { "The smell of low tide", "Murlocs eyeing his hams", "Being asked how he got his name" },
        gossip = "Southshore says Bront earned the name Coldcleave splitting a yeti in two up in the Alterac "
            .. "hills. He has never once said otherwise.",
        bio = "Bront Coldcleave is Southshore's butcher: ham steaks, mutton chops, roasted quail, hog shanks "
            .. "and jerky tough enough for the road. In a town that lives on fish, he counts every meat sale as "
            .. "a point scored against Hal McAllister's catch.",
        backstory = "He came to Southshore young, with a strong arm and no trade. His first job smelled so much "
            .. "of fish that he still won't say what it was. The day he bought his own cleaver, he swore off "
            .. "fish for good. He won't even eat at the inn when Chef Jessen makes turtle bisque.",
        secret = "There was no yeti. He got the name at fifteen, splitting ice for Hal McAllister's fish cart "
            .. "all winter. Hal still calls him that, and only the two of them know why.",
        bestFriend = "You've bought more jerky from me than the whole town. Next haunch is on the house. Just "
            .. "don't tell Hal I told you about the ice.",
        favorite = { emote = "FLEX", hint = "Proud of the arm that swings the cleaver." },
        recordingVoice = "human-male",
        lines = {
            greet = { { "Shop's shut. Let's see what the hills are feeding on.", tone = "[gruff] [cheerful]" },
                "Out from behind the counter. Smells better already." },
            idle = { { "Somewhere a haunch is hanging too long. I can feel it.", tone = "[gruff]" },
                "Smell that? Fish. It follows you out of Southshore.",
                "Tough Jerky's tough on purpose. Builds character. And jaws." },
            befriended = { { "Right. You're a regular now. Regulars get the good end of the ham.",
                tone = "[warm] [gruff]" } },
            poke = { "Poke the ham, not the butcher.", "Easy. That's a prime cut you're jabbing." },
            loot = { "Meat? Give it here. That's a decent shank, that is.",
                "Fish? Put it away. Put it away right now." },
            bagsFull = { "Bags full? Drop the fish first. That's just good sense." },
            rest = { { "Sit. Eat. Nobody swings straight on an empty stomach.", tone = "[firm]" } },
            combatEnd = { "Clean work. I'd have done it in one stroke, mind." },
            levelUp = { "Bigger every day. That's the mutton working." },
            hearth = { "Home for the night? Good. I've got hams to check." },
        },
    },
