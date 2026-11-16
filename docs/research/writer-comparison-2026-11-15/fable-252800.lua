    -- Aamelia Windfield, Windfield Orchard, Gustberry Lowlands, Zephras Isle.
    -- High Order Skyborne, female. Forever quests 92679-92703 (Warcraft DB,
    -- Wowhead Forever). Facts: she and her husband Alvarion grow stormapples
    -- west of Valanaar, where Ferauu "the Bludgeon" and his bandits take a
    -- bigger share of each harvest. Alvarion, badly hurt, recruits the
    -- player in Valanaar ("Blood Tithe"). She calls them "stranger", says
    -- they have more courage than sense and puts them to work for their
    -- meals: stormapples and bandits ("Make Yourself Useful"), Flutterfly
    -- Dust she will not explain ("stuff and things"), galestrider
    -- tenderloins for a hot meal ("Ornery Ornery Galestriders"), bloody
    -- bandit masks ("The Hills Have Eyes"). Four of her quests pay five Red
    -- Delicious Stormapples. An old construct has wandered her fields for
    -- decades, asking its function ("What Is My Purpose?"); her quotes at
    -- the last stand ("Standing Our Ground") call it the big lug. In
    -- "Deliver the News" she uses the player's name at last, wants a
    -- windshaper to check the construct, and hints she is expecting, which
    -- Alvarion does not know. The entry names neither the dust's use nor
    -- the news. That she settles every debt in apples, the construct's
    -- included, is ours.
    [252800] = {
        quote = "All nerve and no sense, are you? Good. Sense never picked a stormapple. Grab a basket, stranger.",
        likes = { "A full basket before noon", "Strangers who stay for the hard part", "A hot galestrider supper" },
        dislikes = { "Bandits who think they're sneaky", "Galestriders in the stormapples",
            "Questions about the flutterfly dust" },
        gossip = "Valanaar says a job at the Windfield orchard pays five stormapples, hero or hired hand, "
            .. "and that Aamelia has never yet left a debt unpaid.",
        bio = "Aamelia and her husband Alvarion grow stormapples at the Windfield Orchard, in the lowlands "
            .. "west of Valanaar. She puts every stranger to work for their meals: apples to pick, galestriders "
            .. "to cull, bandits to thin. What the flutterfly dust is for, she will not say.",
        backstory = "Each season the bandits took a bigger cut, until coin meant little in the lowlands. "
            .. "So Aamelia settles up in the one thing she still has: five stormapples a job, no haggling. "
            .. "A name costs more. Until you earn yours, you are 'stranger'.",
        secret = "Every evening she sets one stormapple at the feet of the old construct in her field. Wages. "
            .. "It cannot eat. The apple is gone by morning all the same, and she has decided not to look into it.",
        bestFriend = "There's one thing Alvarion doesn't know yet. Keep it between us a while longer and "
            .. "I'll make it ten stormapples.",
        favorite = { emote = "FLEX", hint = "She likes to see what a stranger has got before she feeds them." },
        recordingVoice = "skyborne-female",
        lines = {
            greet = { { "Lead on, stranger. Hm. Habit. I'm working on it.", tone = "[dry] [brisk]" },
                "The orchard can spare me an hour. Don't make it two." },
            idle = { { "The big lug asked its purpose again. I said: hold the ladder.", tone = "[deadpan]" },
                "Flutterfly dust in my boots again. No, I won't say what it's for.",
                "Hear that? Bandit. A good one you wouldn't hear. We don't get the good ones." },
            befriended = { { "All right, {name}. 'Stranger' doesn't suit you anymore.",
                say = "All right. 'Stranger' doesn't suit you anymore.", tone = "[grudging] [warm]" } },
            poke = { "Poke me again and you're on galestrider duty.",
                "Those hands are for baskets. Go find one." },
            questAccepted = { "More work? Good. Idle hands eat just as much." },
            quest = { { "Job's done. That's five stormapples. Don't spend them all at once.",
                tone = "[dry] [pleased]" } },
            combatEnd = { "I watched that. You'll do. Wipe your boots." },
            loot = { { "{item}? I'd have paid you in apples. You did better.",
                say = "Not bad. I'd have paid you in apples. You did better." } },
            rest = { "Sit. Eat. It's galestrider. Don't ask which one." },
            died = { "Up you get. Dying doesn't get you out of the harvest." },
            flexBack = { "Very nice. Save some of that for the top branches." },
        },
    },
