    -- Aamelia Windfield, Windfield Orchard, Gustberry Lowlands, Zephras Isle. High Order Skyborne, female.
    -- Facts: wife of Alvarion Windfield, who recruits help in Valanaar while
    -- badly hurt ("Blood Tithe"). She works the orchard west of Valanaar:
    -- stormapples, bandits in the trees ("Make Yourself Useful"), flutterfly
    -- dust for the household, ornery galestriders stealing apples, masks from
    -- the hill camp. Ferauu and his bandits take a cut of the harvest; she
    -- leads the last stand ("Standing Our Ground"). The Malfunctioning Cyclone
    -- Construct asks its purpose; she says it has wandered the fields for
    -- decades and they mostly ignore it. In "Deliver the News" she wants a
    -- windshaper to check it is safe around her family, and asks the player
    -- to keep her pregnancy quiet. That she told the construct first, and has
    -- put it to work, is ours.
    [252800] = {
        quote = "Stormapples don't pick themselves, and bandits don't leave on their own. Grab a basket or a blade. "
            .. "I'm not fussy which.",
        likes = { "A full crate of stormapples", "Flutterfly dust (it scrubs anything)", "Lost causes that win anyway" },
        dislikes = { "Galestriders in the orchard", "Ferauu's idea of a fair share", "Being asked if she should sit down" },
        gossip = "Valanaar says the old construct out at the Windfield place drifted around for decades doing "
            .. "nothing. Lately it's been seen carrying apple crates.",
        bio = "Aamelia Windfield works the Windfield Orchard in the Gustberry Lowlands, west of Valanaar. When "
            .. "Ferauu's bandits came for their cut of the harvest and her husband Alvarion went for help, she put "
            .. "every stranger who showed up to work and made her stand anyway.",
        backstory = "The orchard came with an old cyclone construct that wandered the fields asking what its "
            .. "purpose was. Everyone ignored it. Aamelia answers every question with a chore, so after the "
            .. "bandits she gave it one. Until a windshaper looks it over, it only carries crates.",
        secret = "She told the construct about the baby before she told anyone, Alvarion included. It couldn't "
            .. "spread it around. Now it asks what the baby's purpose is.",
        bestFriend = "Alvarion still doesn't know you knew first. Keep it that way. When the little one can walk, "
            .. "you're teaching them to swat flutterflies.",
        favorite = { emote = "NOD", hint = "Has no use for speeches. A short answer suits her fine." },
        recordingVoice = "skyborne-female",
        lines = {
            greet = { { "Done standing around? Good. Let's go.", tone = "[brisk]" },
                "Another stranger with nowhere to be. Lucky me." },
            idle = { { "Someone had better be watching those stormapple trees.", tone = "[dry]" },
                "If that construct asks me one more question, I'm handing it a broom.",
                "I'm fine. Don't look at me like that. I'm fine." },
            befriended = { { "Fine. You're not a stranger anymore. Don't make me regret it.",
                tone = "[gruff] [softening]" } },
            poke = { "Poke a galestrider instead. See how that goes.",
                "Hands off. I still have the swatter, and I'm not afraid to use it." },
            combatStart = { { "Sneaking up on us? Cute.", tone = "[fierce]" } },
            combatEnd = { "Heads high. That's how it's done." },
            lowHealth = { "Watch the kicks! One good one and you're down." },
            loot = { "Is that meat? Bring it. I can cook anything that kicked me." },
            quest = { "Done? Good. There's always another job." },
            rest = { "Sitting down? Fine. Just this once. For you, not me." },
        },
    },
