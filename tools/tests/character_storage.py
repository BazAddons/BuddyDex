#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Exercise character switches and reloads against the real database module."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[2]
L = LuaRuntime(unpack_returned_tuples=True)
L.execute((ROOT / "tools/tests/blizzard_api.lua").read_text())
L.execute((ROOT / "tools/tests/mock.lua").read_text())
G = L.globals()
ns = L.table()
load = L.eval('function(src, ns) assert(loadstring(src))("BuddyDex", ns) end')
load((ROOT / "Core/Namespace.lua").read_text(), ns)
G.TEST_NS = ns
G.TEST_DATABASE_SOURCE = (ROOT / "Core/Database.lua").read_text()
L.execute(r'''
local ns = TEST_NS
local function login(character)
    BuddyDexCharDB = character
    assert(loadstring(TEST_DATABASE_SOURCE))("BuddyDex", ns)
    for _, frame in ipairs(MOCK.frames) do
        if frame.__events and frame.__events.ADDON_LOADED then
            MOCK.Fire(frame, "OnEvent", "ADDON_LOADED", "BuddyDex")
        end
    end
    assert(ns.db == character and ns.char == character)
end
local shared = { version = 2, friends = {
    [3626] = { name = "Jenn Langston", points = 175, gains = { emote = "2026-11-08" } },
}, settings = { voice = false }, dex = { pinned = { [3626] = true } } }
BuddyDexDB = shared
local alliance = { version = 1, companionPoint = { "CENTER", "CENTER", 10, 20 },
    recentLines = { ["me:poke"] = { "Hello" } }, miniMeHeight = 1.2 }
login(alliance)
assert(next(ns.Database.GetFriends()) == nil, "shared roster leaked into first character")
assert(ns.db.settings.voiceMode == "recorded", "shared options leaked into character")
assert(alliance.companionPoint[3] == 10 and alliance.recentLines["me:poke"][1] == "Hello")
assert(alliance.miniMeHeight == 1.2 and alliance.version == 3)
ns.db.friends[3626] = { name = "Jenn Langston", points = 25,
    gains = { emote = "2026-11-08" }, favoriteFound = true, visits = 2 }
ns.db.dex.pinned = { [3626] = true }
ns.db.dex.collapsed.Elwynn = true
ns.db.dex.point = { "CENTER", "CENTER", 50, 60 }
ns.db.settings.chattiness = 25
ns.char.companionNpc = 3626
local undead = {}
login(undead)
assert(ns.Database.Count() == 0, "undead inherited Alliance friends")
assert(not ns.db.dex.pinned and not ns.db.dex.collapsed.Elwynn and not ns.db.dex.point)
assert(ns.db.settings.chattiness == 50 and not ns.char.companionNpc)
assert(not ns.char.companionPoint and not ns.char.recentLines)
ns.db.friends[3310] = { name = "Doras", points = 150, gains = { emote = "2026-11-08" } }
ns.db.dex.collapsed.Durotar = true
ns.db.settings.voiceMode = "off"
login(alliance)
assert(ns.Database.Count() == 1 and not ns.db.friends[3310])
assert(ns.db.friends[3626].points == 25 and ns.db.friends[3626].favoriteFound)
assert(ns.db.friends[3626].gains.emote == "2026-11-08" and ns.db.friends[3626].visits == 2)
assert(ns.db.dex.pinned[3626] and ns.db.dex.collapsed.Elwynn and not ns.db.dex.collapsed.Durotar)
assert(ns.db.settings.voiceMode == "recorded" and ns.db.settings.chattiness == 25)
assert(ns.char.companionNpc == 3626 and ns.db.dex.point[3] == 50)
login(undead)
assert(ns.db.friends[3310].points == 150 and not ns.db.friends[3626])
assert(ns.db.settings.voiceMode == "off")
local third = {}
login(third)
assert(ns.Database.Count() == 0 and ns.db.settings.voiceMode == "recorded")
assert(BuddyDexDB == shared and shared.version == 2)
assert(shared.friends[3626].points == 175 and shared.dex.pinned[3626])
assert(shared.settings.voice == false and shared.settings.voiceMode == nil,
    "legacy backup was modified")
assert(#MOCK.errors == 0)
''')
print("PASS: character isolation, existing Mini Me preservation, reloads, legacy backup")
