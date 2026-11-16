    -- Abercrombie <The Hermit>, shack north of Raven Hill Cemetery, Duskwood.
    -- Human, male. Facts: Elaine Carevin's "The Hermit" sends the player to
    -- check on the old man who used to shop in Darkshire. Pleading age, he
    -- has them fetch Ghost Hair Thread from Madame Eva ("Supplies from
    -- Darkshire", "Deliver the Thread"), Zombie Juice from Tavernkeep Smitts
    -- ("Zombie Juice", "Juice Delivery"), ghoul ribs for a ghoul "scarecrow"
    -- ("Ghoulish Effigy") and the crate of tools and herbs he dropped when
    -- ogres chased him off a few weeks ago ("Ogre Thieves"). Twice he stops
    -- himself mid-word ("Thank the Nec-", "your foolish-"). "Note to the
    -- Mayor" calls Lord Ello Ebonlocke an old friend; Ello has never heard
    -- of him and cannot read the note. The chain ends with Stitches <Gift
    -- from the Embalmer> walking from behind the shack to Darkshire; the
    -- entry only winks at that. His name and Stitches nod to Abercrombie &
    -- Fitch. That the frailty is put on, how the scarecrow keeps growing
    -- and what he hopes it will make of visitors are ours.
    [289] = {
        quote = "What is a feeble old hermit to do? Sit by the fire while kind young people fetch things. "
            .. "A marvelous arrangement. A hard life, I mean! Very hard.",
        likes = { "Visitors with strong backs", "Zombie Juice on a cold night", "A good tight stitch" },
        dislikes = { "The long road to Darkshire", "Ogres with sticky fingers",
            "Being asked what the scarecrow is for" },
        gossip = "Darkshire has him down as a harmless old dear, too frail to reach his own gate. "
            .. "He calls the mayor an old friend. The mayor says: who?",
        bio = "Abercrombie keeps a shack north of Raven Hill Cemetery and no longer comes to town, which "
            .. "worries Elaine Carevin. So visitors fetch for him: thread from Madame Eva, Zombie Juice from "
            .. "Tavernkeep Smitts, ghoul ribs for the scarecrow he is sewing to keep the dead from his door.",
        backstory = "Ask what he did before the shack and he says a little of this, a little needlework, and "
            .. "how is the weather in town? He picked the cemetery, he says, for the quiet neighbors. The "
            .. "errands began with one spool of thread. The list has grown ever since, and so has the scarecrow.",
        secret = "He is not feeble. A few weeks back he outran a whole band of ogres. The limp turns up "
            .. "when visitors do, and leaves once the errand is agreed.",
        bestFriend = "You never once asked what the scarecrow is for. I treasure that. Do come by when it "
            .. "is finished. It will so want to meet you.",
        favorite = { emote = "COMFORT", hint = "Nothing pleases him like sympathy for a poor, feeble old man." },
        recordingVoice = "human-male",
        lines = {
            greet = { { "Out of the shack at last! Lead on. Slowly. I'm very feeble, remember.",
                tone = "[gleeful] [wheedling]" },
                "Fresh air! Much nicer than embalming fluid. Than mildew! I said mildew." },
            idle = { { "Good bones on you. Manners! I meant good manners.", tone = "[admiring] [flustered]" },
                "I hope the scarecrow isn't lonely. Scarecrows don't get lonely. Naturally.",
                "Is that thread in your pack? No? Pity. One can never have too much." },
            befriended = { { "A friend! My first since the mayor. Do ask him about me.",
                tone = "[delighted] [sly]" } },
            poke = { "Careful! I'm held together with thread. Figure of speech!",
                "Hee hee! Do that again and you go on the list. The errand list!" },
            quest = { { "Splendid! All fetched. You have a real gift for carrying things.",
                tone = "[delighted]" } },
            ghost = { "You make a lovely ghost! Might I trouble you for one hair?" },
            alive = { "Up again! Marvelous. How did you manage it? Asking for a hobby." },
            combatEnd = { "Well fought! Mind the ribs, though. Theirs. Good ribs are hard to find." },
            mail = { "A letter? Not from the mayor, I suppose. He never does write back." },
            rest = { "An inn! Ask if they keep Zombie Juice. Purely against the cold." },
            comforted = { "Oh, bless you. A poor old man could be pitied like that all day." },
        },
    },
