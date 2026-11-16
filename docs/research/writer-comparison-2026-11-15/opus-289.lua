    -- Abercrombie <The Hermit>, shack north of Raven Hill Cemetery, Duskwood. Human, male.
    -- Facts: Elaine Carevin's "The Hermit" sends the player to check on him.
    -- He calls himself a poor, feeble old man; "Supplies from Darkshire" and
    -- "Zombie Juice" send the player to Madame Eva (Ghost Hair Thread, strung
    -- on his door and windows) and Tavernkeep Smitts. "Ghoulish Effigy" wants
    -- ghoul ribs after Bone Chewers pounded his walls; "Ogre Thieves" fetches
    -- his crate of tools and herbs. He slips ("Thank the Nec-", "your
    -- foolish-"). "Note to the Mayor": he calls Ello Ebonlocke an old friend;
    -- Ello has never heard of him and can't read the ancient script. Classic's
    -- chain goes on to Sirra Von'Indi's translation, the Embalmer, Eliza and
    -- Stitches. That he reads aloud to Eliza nightly is ours.
    [289] = {
        quote = "Visitors! How lovely. Mind the ribs on the porch, they're for the effigy. Ghoul ribs. Nobody you'd know.",
        likes = { "Long, quiet nights", "Ghost Hair Thread by the spool", "A warming bottle of Zombie Juice" },
        dislikes = { "Bone Chewers knocking at all hours", "Ogres who keep other people's crates",
            "Questions about his handwriting" },
        gossip = "Abercrombie tells anyone who'll listen that he and Mayor Ebonlocke are old friends. The mayor "
            .. "has never heard of him.",
        bio = "Abercrombie keeps a shack north of Raven Hill Cemetery and sends visitors to Darkshire on his "
            .. "behalf: Ghost Hair Thread from Madame Eva, Zombie Juice from Tavernkeep Smitts. Elaine Carevin "
            .. "noticed he stopped coming to town. He blames the roads.",
        backstory = "He moved out past the cemetery for the quiet, and for neighbors who never complain. He "
            .. "insists he is a poor, feeble old man, usually just before he hands you something heavy. He "
            .. "learned his letters from very old books, which is why nobody in Darkshire can read his notes.",
        secret = "Every night he reads aloud to someone named Eliza. Ask about her and he says she's resting, "
            .. "and will be up and about any day now.",
        bestFriend = "You've run more errands for me than anyone alive. Well. Anyone. Come by after dark "
            .. "sometime. I'd like you to meet her.",
        favorite = { emote = "GRIN", hint = "Shows rather a lot of teeth when a plan comes together." },
        recordingVoice = "human-male",
        lines = {
            greet = { { "Out of the shack! Do keep yourself between me and the ghouls.", tone = "[creaky] [cheerful]" },
                "A lovely evening for a walk. Every evening is lovely, out here." },
            idle = { { "I never said I was a necro- a neighbor. A good neighbor.", tone = "[sly]" },
                "The thread on my door keeps out unwanted spirits. The wanted ones know the way.",
                "My knees, my back, my poor old... oh, would you carry this?" },
            befriended = { { "A friend! And a living one. How refreshing.", tone = "[delighted] [cackling]" } },
            poke = { "Careful! These bones are older than they look. Mine, I mean.",
                "Poke a feeble old man, will you? I'll remember that. Fondly." },
            ghost = { { "Oh, don't look so glum. Death is hardly permanent, in my experience.",
                tone = "[soothing] [amused]" } },
            alive = { "Back on your feet! You see? Hardly permanent." },
            quest = { "Another errand done! Smitts must be sick of the sight of you." },
            loot = { "Ooh, is that a rib? No? Pity. Keep looking." },
            combatEnd = { "Splendid. Leave that one where it fell. I may have a use for it." },
            rest = { "Rest? At night? That's when the fun... I mean the ghouls come out." },
            hearth = { "Home already? Mine's just past the cemetery. Lovely view." },
        },
    },
