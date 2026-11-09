# BuddyDex

[![Part of BazAddons](https://img.shields.io/badge/Part_of-BazAddons-b8924a?labelColor=2a2519)](https://bazaddons.com) [![WoW](https://img.shields.io/badge/WoW-Forever-blue)](https://worldofwarcraft.blizzard.com) [![License](https://img.shields.io/badge/License-GPL_v2-green)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html) [![Version](https://img.shields.io/github/v/tag/BazAddons/BuddyDex?label=Version&color=orange&sort=date)](https://github.com/BazAddons/BuddyDex/releases)

A pocket-sized gnome companion for World of Warcraft: Forever, and a Dex of every NPC you befriend.

Your **Mini Me** is a little gnome version of you, in your own armor, who stands on your screen, chats in speech bubbles and reacts to your adventures. The **BuddyDex** collects the people of Azeroth you make friends with: talk, trade, train, travel and quest with them, and the friendship grows from Stranger to Best Friend.

***

## Features

### Your Mini Me

*   A gnome you, wearing whatever you wear, redressed the moment you change gear
*   Speech bubbles and animations for fights, level-ups, flights, loot, mail, deaths, new zones and your emotes
*   Hundreds of lines, shuffled so they rarely repeat, with class-specific cheers in combat
*   A chattiness slider, from quiet to talkative
*   Drag it anywhere, resize it, fade it, lock it, or let clicks pass through
*   Stays with you in combat or steps aside, your choice

### The BuddyDex

*   Every friend's 3D model, zone and coordinates, with a waypoint (TomTom first, then the map's own pin)
*   Friendship tiers: Stranger, Acquaintance, Buddy, Friend, Good Friend, Best Friend
*   Each friend has a favorite emote; find it for a bonus
*   Pin your favorites to the top of the list
*   Meet named NPCs even when they have no dialogue: target them and use a friendly emote such as `/wave`, `/greet`, `/smile` or `/bow`
*   Right-click an eligible NPC's unit frame and hover **BuddyDex Emotes** to choose from the supported friendly emotes
*   Ordinary friendly emotes earn 25 friendship once per NPC per day; their favorite earns 150 once per day, separately. Switching emotes won't bypass either daily limit
*   Generic NPCs such as Stormwind City Guards stay out of your collection; named guards such as Guard Thomas can become friends

### Lore That Unlocks

Written entries open a page at a time as a friendship grows:

*   **Personality** - their quote, likes and dislikes
*   **Word Around Town** - what people say about them
*   **Story** and **Backstory** - who they are and how they got here
*   **Secret** - something only close friends hear
*   **Just Between Friends** - what they tell their best friend

### Bring a Friend Along

Any friend at Buddy or better can come along in your Mini Me's place, drawn true to size, with lines of their own.

### Voices

Recorded voices are built into **BuddyDex**: your gnome Mini Me and NPC friends have voices for humans, dwarves, night elves, gnomes, Skyborne, orcs, and Forsaken. Completed profiles include personal signature recordings. The Forsaken voices currently cover those signatures; lines without recordings still appear as speech bubbles. Turn Voice off in `/bd options` for speech bubbles only. Races without a bundled recorded voice use their in-game NPC sounds when Voice is on. There is one addon folder and no separate voice pack to install.

**Upgrading from the separate voice addon?** Remove the old `BuddyDex_Voice` folder from your AddOns directory; BuddyDex now includes those recordings. Your BuddyDex friendships and settings are kept.

***

## Commands

*   `/bd` or `/buddydex` - open the BuddyDex
*   `/bd buddy` - show or hide your buddy
*   `/bd options` - buddy options
*   `/bd help` - everything else

***

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).

### Character-specific progress

Each character has their own friends, friendship points, daily gains, discoveries, pins, journal preferences, and companion settings. These are saved in `BuddyDexCharDB`. The old account-wide `BuddyDexDB` is retained as a legacy backup; its mixed roster is not automatically assigned to any character. Existing per-character Mini Me position and dialogue history are preserved.
