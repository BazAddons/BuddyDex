#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Smoke tests and API audit for BuddyDex and BuddyDex Scout.

Each addon is loaded into a mock client (tools/tests/mock.lua) from its TOC,
then a short session is played through it, failing on any Lua error or
broken expectation:

- BuddyDex: making friends (talking, trading, quests, emotes, the daily
  cap, tiers, friendly NPCs only), the toasts, and the BuddyDex window
  (grouped list, filters, model, greeting, portraits, tabs, settings).
- BuddyDex Scout: taking over BuddyDex's old roster, scouting nameplates,
  the sweep, the window.

While a session runs, the mock records every template, font, event, sound
kit, global, C_ namespace member and widget method the addon touches. Those
are checked against tools/tests/blizzard_api.lua, generated from the
client's own exported UI code: a name the client does not have is exactly
the kind of mistake that otherwise only shows up in game.

    .venv/bin/python tools/tests/smoke.py
"""
import os
import sys

from lupa.lua51 import LuaRuntime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

# Frame types every client has; the generated file lists only the
# intrinsic ones (EventFrame, DropdownButton, ...).
BASE_TYPES = {
    "Frame", "Button", "CheckButton", "EditBox", "ScrollFrame", "Slider", "StatusBar",
    "Model", "PlayerModel", "DressUpModel", "CinematicModel", "TabardModel", "ModelScene",
    "GameTooltip", "MessageFrame", "SimpleHTML", "Cooldown", "ColorSelect", "Texture",
    "FontString", "MaskTexture", "Line", "AnimationGroup", "Animation", "Alpha",
}

# Globals from Lua itself, from the client's C side, or created by XML,
# which the generated lists (built from Lua sources and API docs) miss.
BUILTINS = {
    "_G", "assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "print",
    "rawequal", "rawget", "rawset", "select", "setmetatable", "tonumber", "tostring", "type",
    "unpack", "xpcall", "math", "string", "table", "coroutine", "bit",
    "date", "time", "strsplit", "strtrim", "strjoin", "format", "tinsert", "tremove", "wipe",
    "geterrorhandler", "seterrorhandler", "securecall", "hooksecurefunc", "issecure",
    "debugstack", "GameTooltip", "UIParent", "WorldFrame", "C_Timer",
    "CreateFrame", "Enum", "InCombatLockdown", "SlashCmdList", "ReloadUI",
    # GlobalStrings and client colors: client data, not in the Lua export.
    "UNKNOWNOBJECT", "GREEN_FONT_COLOR",
}

# Saved variables of the other addon, read on purpose.
EXPECTED_FOREIGN = {"BuddyDexDB", "AzerBuddyProbeAccountDB", "TomTom"}
# Missing from the generated lists but confirmed in this client: PlaySoundFile
# by the probe's scan of globals (it reported "function"), StopSound by
# Blizzard's own code calling it.
VERIFIED_GLOBALS = {"PlaySoundFile", "StopSound"}


def toc_files(addon_dir, toc_name):
    files = []
    with open(os.path.join(addon_dir, toc_name)) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                files.append(line.replace("\\", "/"))
    return files


LOADER = r"""
function MOCK.LoadAddonFile(src, chunkname, addonName, ns)
    local chunk, err = loadstring(src, "@" .. chunkname)
    if not chunk then error(err) end
    local env = setmetatable({}, {
        __index = function(_, k)
            MOCK.globals[k] = true
            local v = _G[k]
            if type(k) == "string" and k:match("^C_") and type(v) == "table" then
                return setmetatable({}, { __index = function(_, field)
                    MOCK.namespaced[k .. "." .. field] = true
                    return v[field]
                end, __newindex = function(_, field, value)
                    v[field] = value
                end })
            end
            return v
        end,
        __newindex = function(_, k, v)
            MOCK.defined[k] = true
            _G[k] = v
        end,
    })
    setfenv(chunk, env)
    chunk(addonName, ns)
end
"""

COMMON = r"""
local failures = {}
MOCK.failures = failures

function step(name, fn)
    local before = #MOCK.errors
    local ok, err = pcall(fn)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(err) end
    for i = before + 1, #MOCK.errors do
        failures[#failures + 1] = name .. " (reported): " .. MOCK.errors[i]
    end
end

function FireAll(event, ...)
    for _, f in ipairs(MOCK.frames) do
        if f.__events and f.__events[event] then MOCK.Fire(f, "OnEvent", event, ...) end
    end
end

function FindFrames(template)
    local out = {}
    for _, f in ipairs(MOCK.frames) do
        if f.__template and f.__template:find(template, 1, true) then out[#out + 1] = f end
    end
    return out
end

function FindByKind(kind)
    local out = {}
    for _, f in ipairs(MOCK.frames) do
        if f.__kind == kind then out[#out + 1] = f end
    end
    return out
end

function Printed(pattern)
    for _, line in ipairs(MOCK.printed) do
        if line:find(pattern) then return true end
    end
    return false
end
"""

BUDDYDEX = r"""
local ns = MOCK.ns

step("the main addon loads its bundled voices", function()
    assert(ns.Voice.HasPack(), "the main TOC did not load the recordings")
    assert(ns.VoicePack.path == "Interface\\AddOns\\BuddyDex\\voice\\", "wrong bundled audio path")
    local line, file = next(ns.VoicePack.voices.male)
    assert(line and file, "no bundled male recordings")
    MOCK.soundFiles = {}
    assert(ns.Voice.PlayClip(line, "male"), "bundled clip did not play")
    assert(MOCK.soundFiles[1] == ns.VoicePack.path .. file, "wrong playback path")
    -- Classic display IDs, cross-checked against the branch's DB2 race/sex
    -- metadata, route signature recordings to the selected racial voices.
    assert(ns.Voice.NpcVoice(1311) == "orc-male" and ns.Voice.NpcVoice(5706) == "orc-female",
        "Horde service NPC voice identity mismatch")
    for _, sample in ipairs({ {3310, 1311, "orc-male"}, {6929, 5706, "orc-female"},
        {3626, 1697, "human-female"}, {279, 5082, "human-male"},
        {1568, 1582, "forsaken-male"}, {1661, 1593, "forsaken-female"},
        {244808, 129405, "forsaken-male"}, {267326, 145035, "forsaken-female"},
        {3188, 4072, "troll-male"}, {2981, 3809, "tauren-male"},
        {5884, 4526, "troll-female"},
        {3287, 2025, "troll-male"}, {3145, 1875, "orc-female"},
        {2980, 3808, "tauren-male"}, {2982, 3813, "tauren-male"},
        {3061, 3810, "tauren-male"}, {3062, 10180, "tauren-female"},
        {3143, 1653, "orc-male"},
        {2079, 1285, "nightelf-male"}, {8583, 7895, "nightelf-female"},
        {2082, 2458, "nightelf-male"}, {3593, 1721, "nightelf-female"},
        {3595, 1733, "nightelf-female"},
        {12738, 12967, "dwarf-male"}, {836, 3406, "dwarf-male"},
        {460, 1930, "male"}, {6376, 5093, "female"},
        {658, 1362, "dwarf-male"},
        {257006, 140040, "skyborne-female"},
        {251362, 136968, "skyborne-female"}, {251361, 136966, "skyborne-male"},
        {254089, 138005, "skyborne-female"}, {251905, 137343, "skyborne-male"},
        {251374, 136975, "skyborne-male"},
        {254082, 137998, "skyborne-male"},
        {252800, 137628, "skyborne-female"},
        {3064, 3820, "tauren-female"}, {3191, 3751, "orc-male"},
        {3067, 3795, "tauren-male"}, {6747, 5486, "tauren-male"},
        {3185, 4085, "troll-female"}, {3706, 1897, "troll-female"},
        {6928, 5705, "orc-male"}, {3158, 1879, "orc-female"},
        {2948, 3826, "tauren-male"}, {3884, 3807, "tauren-female"},
        {11189, 10746, "goblin-female"},
        {3453, 7053, "goblin-male"},
        {3615, 1652, "orc-male"}, {3338, 3850, "orc-female"},
        {3184, 4071, "troll-male"}, {5941, 4609, "troll-male"},
        {7714, 6550, "tauren-male"}, {3418, 3818, "tauren-male"},
        {8385, 7615, "tauren-female"}, {3419, 1814, "forsaken-female"},
        {3448, 3914, "tauren-male"}, {3482, 4095, "troll-male"},
        {3432, 3855, "orc-male"}, {7953, 7040, "troll-female"},
        {3401, 4360, "troll-male"}, {3333, 1333, "orc-female"}, {12136, 12229, "goblin-female"},
        {9564, 8848, "goblin-male"}, {2995, 2098, "tauren-male"}, {6746, 5487, "tauren-female"},
          {3344, 1360, "orc-female"}, {3403, 4231, "troll-female"}, {3347, 1368, "orc-male"},
          {3026, 2107, "tauren-female"}, {3028, 2088, "tauren-male"},
          {4047, 4514, "orc-male"}, {4049, 3897, "orc-female"},
          {1521, 3515, "forsaken-female"}, {1496, 2855, "forsaken-male"},
          {3442, 7054, "goblin-male"}, {9316, 8630, "goblin-female"},
          {4201, 7156, "goblin-male"}, {9317, 8631, "goblin-male"},
          {6018, 4711, "troll-male"}, {5882, 4524, "troll-female"},
          {3389, 3847, "orc-male"}, {3449, 3849, "orc-male"},
          {3009, 2108, "tauren-female"}, {3013, 2091, "tauren-male"},
          {2118, 1632, "forsaken-female"}, {2114, 3520, "forsaken-female"},
          {3317, 1317, "orc-male"}, {3342, 1358, "orc-female"},
          {11317, 11468, "troll-male"}, {12031, 12037, "troll-female"},
          {11259, 11469, "tauren-male"}, {11106, 10564, "tauren-female"},
          {3391, 7052, "goblin-male"}, {15165, 15300, "goblin-female"},
          {10537, 9899, "tauren-male"}, {11116, 10653, "tauren-male"},
          {3995, 4104, "troll-male"}, {7731, 6551, "orc-female"},
          {12724, 12968, "goblin-female"}, {12616, 12974, "orc-female"},
          {2861, 4148, "orc-male"}, {6411, 5235, "forsaken-female"},
          {6408, 5370, "troll-male"}, {6410, 5372, "tauren-male"},
          {3955, 2068, "nightelf-female"}, {11596, 11470, "goblin-male"},
          {12032, 12038, "troll-female"}, {4210, 2242, "nightelf-male"},
          {3399, 2734, "troll-female"}, {4211, 2248, "nightelf-male"},
          {7583, 7175, "goblin-female"}, {3014, 2119, "tauren-female"},
          {270582, 146415, "troll-female"}, {266881, 144913, "troll-female"},
          {7564, 7185, "goblin-male"}, {269068, 145744, "tauren-female"},
          {1518, 1565, "forsaken-male"}, {2132, 1601, "forsaken-female"},
          {1937, 1661, "forsaken-male"}, {2080, 2484, "nightelf-male"},
          {1938, 1278, "forsaken-male"}, {2083, 2459, "nightelf-female"},
          {3007, 2127, "tauren-female"}, {6286, 4989, "nightelf-male"},
          {2851, 3972, "orc-female"}, {1387, 1868, "orc-female"},
          {3173, 3746, "orc-male"}, {2130, 1603, "forsaken-female"},
          {3304, 4086, "troll-male"}, {3015, 2114, "tauren-female"},
          {252382, 140050, "skyborne-female"}, {7733, 7346, "goblin-male"},
        {251487, 139694, "skyborne-female"}, {255940, 139379, "skyborne-male"},
        {3364, 1386, "orc-male"}, {3400, 2735, "troll-male"},
        {3358, 1380, "orc-female"}, {10118, 9344, "nightelf-female"},
        {9501, 8634, "tauren-male"}, {255894, 139284, "goblin-female"},
        {8361, 7625, "tauren-female"}, {4585, 2625, "forsaken-male"},
        {2913, 1286, "dwarf-female"}, {3413, 7136, "goblin-male"},
        {3934, 3881, "tauren-male"}, {3348, 1369, "orc-male"},
        {5150, 3068, "dwarf-female"}, {3490, 4096, "troll-male"},
        {3057, 4307, "tauren-male"}, {4046, 4510, "tauren-female"},
        {5144, 3108, "female"}, {3366, 1388, "orc-male"},
        {5811, 4350, "orc-female"}, {6300, 5022, "dwarf-female"},
        {7737, 6554, "tauren-female"}, {3412, 7135, "goblin-male"},
        {9087, 8356, "tauren-female"}, {3404, 4358, "troll-female"},
        {8997, 8229, "nightelf-male"}, {4877, 4529, "tauren-female"},
        {4164, 2199, "nightelf-female"}, {2832, 7180, "goblin-male"},
        {4575, 2663, "forsaken-female"}, {2388, 3675, "forsaken-male"},
        {3841, 1932, "nightelf-female"}, {4312, 2411, "tauren-male"},
        {1257, 1431, "human-male"}, {1275, 1444, "human-female"} }) do
        assert(ns.Voice.NpcVoice(sample[2]) == sample[3], "signature voice identity mismatch")
        local line = ns.Lore[sample[1]].lines.greet[1][1]
        MOCK.soundFiles = {}
        assert(ns.Voice.Speak({ display = sample[2], moment = "greet", line = line }),
            "signature greeting did not play")
        assert(#MOCK.soundFiles == 1, "signature greeting did not use its recording")
    end

    -- An obsolete standalone pack cannot override the private manifest.
    _G["BuddyDexVoicePack"] = { path = "obsolete/", voices = {} }
    assert(ns.Voice.PlayClip(line, "male"), "obsolete addon replaced bundled voices")
    _G["BuddyDexVoicePack"] = nil
    ns.Voice.Stop()
    MOCK.soundFiles = {}
end)
ns.VoicePack = nil

-- Friendly NPCs to make friends with, and ones that must never count.
local LYMPKIN = { guid = "Creature-0-1-2-3-9859-0000AB", npcID = 9859, name = "Auctioneer Lympkin",
    type = "Humanoid", typeID = 7, class = "normal", level = 45, sex = 3, reaction = 5,
    faction = "Alliance", tip = { "Auctioneer", "Level 45", "Ironforge" } }
local GUARD = { guid = "Creature-0-1-2-3-5595-0000AB", npcID = 5595, name = "Ironforge Guard",
    type = "Humanoid", class = "elite", level = 55, reaction = 5, faction = "Alliance",
    tip = { "Level 55 (Elite)", "Ironforge", "PvP" } }
-- A guard with a name is someone; an Ironforge Guard is one of many.
local GUARD_THOMAS = { guid = "Creature-0-1-2-3-261-0000AB", npcID = 261, name = "Guard Thomas",
    type = "Humanoid", class = "normal", level = 25, sex = 2, reaction = 5, faction = "Alliance",
    tip = { "Level 25", "Elwynn Forest" } }
local GRUNT = { guid = "Creature-0-1-2-3-3296-0000AB", npcID = 3296, name = "Orgrimmar Grunt",
    type = "Humanoid", class = "elite", level = 55, reaction = 2, attackable = true }
local BOAR = { guid = "Creature-0-1-2-3-1125-0000AB", npcID = 1125, name = "Rockjaw Boar",
    type = "Beast", class = "normal", level = 5, reaction = 4, attackable = true }

local THOR = { guid = "Creature-0-1-2-3-523-0000AB", npcID = 523, name = "Thor", type = "Humanoid",
    typeID = 7, class = "elite", level = 55, sex = 2, reaction = 5, faction = "Alliance",
    tip = { "Gryphon Master", "Level 55 (Elite)", "Westfall" } }

-- The fewest points that put an entry at a tier (thresholds scale by rarity).
local function SetTier(e, index)
    for p = 0, 10000, 5 do
        e.points = p
        if ns.Friendship.TierIndex(e) == index then return end
    end
    error("could not reach tier " .. index)
end

local function Points(id)
    local e = BuddyDexCharDB.friends[id]
    return e and e.points
end

local function FriendRows()
    local sb = FindFrames("WowScrollBoxList")[1]
    local rows = {}
    for _, d in ipairs(sb and sb.__dp and sb.__dp.items or {}) do
        if not d.header then rows[#rows + 1] = d end
    end
    return rows, sb
end

step("ADDON_LOADED and PLAYER_LOGIN", function()
    BuddyDexCharDB = { friends = {
        [247] = { name = "Billy Maclure", points = 5000, display = 221 },
    }, companionNpc = 247, dex = { pinned = { [247] = true } } }
    FireAll("ADDON_LOADED", "BuddyDex")
    assert(not BuddyDexCharDB.friends[247], "legacy child stayed in roster")
    assert(BuddyDexCharDB.excludedChildren[247].points == 5000, "old progress was not archived")
    assert(not BuddyDexCharDB.companionNpc and not BuddyDexCharDB.dex.pinned[247], "stale child selection/pin")
    assert(type(BuddyDexCharDB) == "table" and type(BuddyDexCharDB.friends) == "table", "no friends table")
    -- Befriended before the one-of-many rule: leaves at login.
    BuddyDexCharDB.friends[68] = { name = "Stormwind City Guard", points = 40, zone = "Stormwind City" }
    FireAll("PLAYER_LOGIN")
    assert(BuddyDexCharDB.friends[68] == nil, "a Stormwind City Guard stayed a friend")
    assert(Printed("Stormwind City Guard left the BuddyDex"), "no word about it leaving")
end)

step("trading starts a friendship", function()
    MOCK.today = "2026-10-10"
    MOCK.units.npc = LYMPKIN
    FireAll("MERCHANT_SHOW")
    local e = BuddyDexCharDB.friends[9859]
    assert(e, "no friend")
    assert(e.points == 60, "points " .. tostring(e.points))
    assert(e.title == "Auctioneer" and e.zone == "Ironforge", "snapshot")
    local portrait = MOCK.portraits[#MOCK.portraits]
    assert(not e.display and portrait and portrait.unit == "npc" and portrait.guid == LYMPKIN.guid,
        "first-meeting toast did not show the live NPC headshot")
    assert(Printed("Friendship with Auctioneer Lympkin increased by 60"), "no chat line")
end)

step("toast portraits use matching units or cached displays, never another NPC", function()
    local saved = MOCK.units.npc
    MOCK.units.npc = nil
    MOCK.units.target = LYMPKIN
    local entry = { name = "Portrait Test", type = "Humanoid", class = "normal", points = 25, display = 4321 }
    ns.Bus:TriggerEvent(ns.Event.FriendshipGained, 990010, entry, 25, "dev", 1, 1)
    local portrait = MOCK.portraits[#MOCK.portraits]
    assert(portrait and portrait.display == 4321 and not portrait.unit,
        "toast used an unrelated target instead of its cached portrait")
    local count = #MOCK.portraits
    entry.display = nil
    ns.Bus:TriggerEvent(ns.Event.FriendshipGained, 990010, entry, 25, "dev", 1, 1)
    assert(#MOCK.portraits == count, "unknown NPC toast used somebody else's headshot")
    MOCK.units.npc = saved
    MOCK.units.target = nil
end)

step("the daily cap, though a visit still updates where they are", function()
    MOCK.position = { 0.25, 0.75 }
    FireAll("MERCHANT_SHOW")
    assert(Points(9859) == 60, "trading twice in a day counted twice")
    assert(BuddyDexCharDB.friends[9859].x == 0.25, "a capped visit did not update where they are")
    MOCK.position = { 0.5641, 0.5262 }
end)

step("talking reaches Acquaintance", function()
    FireAll("GOSSIP_SHOW")
    assert(Points(9859) == 100, "points " .. tostring(Points(9859)))
    assert(ns.Friendship.TierIndex(BuddyDexCharDB.friends[9859]) == 2, "not an Acquaintance")
    assert(Printed("now considers you an Acquaintance"), "no tier line")
end)

step("the favorite emote, and a rude one", function()
    MOCK.units.npc = nil
    MOCK.units.target = LYMPKIN
    local fav = ns.Friendship.Favorite(BuddyDexCharDB.friends[9859], 9859)
    assert(fav.token == "APPLAUD", "Lympkin's favorite is " .. fav.token)
    DoEmote("APPLAUD")
    assert(Points(9859) == 250, "favorite did not count: " .. tostring(Points(9859)))
    assert(BuddyDexCharDB.friends[9859].favoriteFound, "favorite not marked found")
    DoEmote("RUDE")
    assert(Points(9859) == 225, "rude did not cost: " .. tostring(Points(9859)))
end)

step("Forever's chat emote API introduces Jenn without the legacy function", function()
    MOCK.units.npc = nil
    MOCK.units.target = { guid = "Creature-0-1-2-3-3626-0000AB", npcID = 3626,
        name = "Jenn Langston", type = "Humanoid", typeID = 7, class = "normal",
        sex = 3, reaction = 5, faction = "Alliance" }
    -- ChatFrameEditBox passes HELLO and an empty message for /hi.
    C_ChatInfo.PerformEmote("HELLO", "")
    assert(Points(3626) == 25, "chat /hi did not introduce Jenn")
    C_ChatInfo.PerformEmote("KISS", "")
    C_ChatInfo.PerformEmote("BOW", "")
    C_ChatInfo.PerformEmote("HUG", "")
    assert(Points(3626) == 25, "chat emotes bypassed the shared daily cap")
    C_ChatInfo.PerformEmote("WAVE", "")
    assert(Points(3626) == 175, "chat favorite was not recognized")
    DoEmote("WAVE")
    assert(Points(3626) == 175, "legacy forwarding counted twice")
    ns.Database.Remove(3626)
    MOCK.units.target = GUARD
end)

step("NPC unit menus offer real emotes and retain their original recipient", function()
    local jenn = { guid = "Creature-0-1-2-3-3626-0000AB", npcID = 3626,
        name = "Jenn Langston", type = "Humanoid", class = "normal", reaction = 5 }
    MOCK.units.npc = nil
    MOCK.units.target = jenn
    local root = MOCK.UnitMenu("MENU_UNIT_TARGET", "target")
    assert(not BuddyDexCharDB.friends[3626], "opening the menu befriended its NPC")
    local submenu = root.children[2]
    assert(submenu and submenu.text == "BuddyDex Emotes" and #submenu.children > 20,
        "missing friendly emote submenu")
    local hello, wave
    for _, item in ipairs(submenu.children) do
        if item.text == "Hello (/hello)" then hello = item end
        if item.text == "Wave (/wave)" then wave = item end
        assert(item.text ~= "Rude (/rude)", "a harmful emote was offered as friendship")
    end
    assert(hello and wave, "missing greeting choices")
    hello.a()
    assert(MOCK.lastEmote == "HELLO" and MOCK.lastEmoteTarget == nil
        and MOCK.lastEmoteRecipient == jenn.guid,
        "the menu did not perform an emote at Jenn")
    assert(Points(3626) == 25, "menu greeting did not introduce Jenn")
    wave.a()
    wave.a()
    assert(Points(3626) == 175, "menu favorite/daily cap failed")
    -- Match the reported /wink case: menu output must address the NPC,
    -- rather than merely making the addon award friendship by their name.
    for _, item in ipairs(submenu.children) do
        if item.text == "Wink (/wink)" then item.a() end
    end
    assert(MOCK.lastEmote == "WINK" and MOCK.lastEmoteRecipient == jenn.guid,
        "menu wink was untargeted")
    local lastEmote = MOCK.lastEmote
    MOCK.units.target = GUARD_THOMAS
    hello.a()
    assert(not BuddyDexCharDB.friends[261] and Points(3626) == 175,
        "a stale menu greeted another target")
    assert(MOCK.lastEmote == lastEmote, "a stale menu sent an emote")
    ns.Database.Remove(3626)
    MOCK.units.focus = jenn
    MOCK.units.target = GUARD
    local focusMenu = MOCK.UnitMenu("MENU_UNIT_TARGET", "focus")
    for _, item in ipairs(focusMenu.children[2].children) do
        if item.text == "Hello (/hello)" then item.a() end
    end
    assert(not BuddyDexCharDB.friends[3626] and not BuddyDexCharDB.friends[5595]
        and MOCK.lastEmote == lastEmote,
        "focus menu sent an emote at an unrelated current target")
    MOCK.units.target = jenn
    for _, item in ipairs(focusMenu.children[2].children) do
        if item.text == "Hello (/hello)" then item.a() end
    end
    assert(Points(3626) == 25 and MOCK.lastEmoteRecipient == jenn.guid,
        "focus menu did not work after targeting that NPC")
    ns.Database.Remove(3626)
    MOCK.units.focus = nil
    for _, unit in ipairs({ GUARD, GRUNT, { name = "A Player", player = true, reaction = 5 } }) do
        MOCK.units.target = unit
        assert(#MOCK.UnitMenu("MENU_UNIT_TARGET", "target").children == 0,
            "an ineligible unit received BuddyDex actions")
    end
    MOCK.units.target = jenn
    MOCK.combat = true
    local combatMenu = MOCK.UnitMenu("MENU_UNIT_TARGET", "target")
    MOCK.combat = false
    assert(#combatMenu.children == 0, "combat menu offered restricted friendship actions")
    MOCK.units.target = GUARD
end)

step("emotes never befriend generic NPCs, even with authored lore", function()
    MOCK.units.target = GUARD
    assert(ns.Friendship.Favorite(GUARD).token == "SALUTE", "guard favorite")
    ns.Lore[5595] = { quote = "Move along." }
    DoEmote("WAVE")
    DoEmote("SALUTE")
    ns.Lore[5595] = nil
    assert(BuddyDexCharDB.friends[5595] == nil, "an emote befriended a generic guard")
end)

step("a named wanderer can be met by emote and earns daily friendship", function()
    -- Synthetic ID: this tests Jenn's no-window interaction, not client data.
    local id = 990001
    local jenn = { guid = "Creature-0-1-2-3-990001-0000AB", npcID = id,
        name = "Jenn Langston", type = "Humanoid", typeID = 7,
        class = "normal", sex = 3, reaction = 5, faction = "Alliance" }
    local today = MOCK.today
    MOCK.units.npc = nil
    MOCK.units.target = jenn
    DoEmote("RUDE")
    DoEmote("SIT")
    assert(not BuddyDexCharDB.friends[id], "a rude or unsupported emote introduced someone")
    DoEmote("SMILE")
    local e = BuddyDexCharDB.friends[id]
    assert(e and e.name == jenn.name and e.points == 25, "a friendly emote did not introduce the wanderer")
    assert(e.first == today and e.last == today and e.x == 0.5641, "first meeting not saved")
    DoEmote("BOW")
    DoEmote("GREET")
    assert(e.points == 25, "switching friendly emotes bypassed the daily cap")
    DoEmote("WAVE")
    assert(e.points == 175 and e.favoriteFound, "favorite discovery did not work for a wanderer")
    DoEmote("WAVE")
    assert(e.points == 175, "favorite counted twice in a day")
    MOCK.today = "2026-10-11"
    DoEmote("HELLO")
    DoEmote("WAVE")
    assert(e.points == 350 and ns.Friendship.IsBuddy(e), "next day's emotes did not grow the friendship")
    ns.Database.Remove(id)
    -- A favorite can also be the very first greeting.
    DoEmote("WAVE")
    assert(Points(id) == 150 and BuddyDexCharDB.friends[id].favoriteFound,
        "a first-meeting favorite was not discovered")
    ns.Database.Remove(id)
    MOCK.today = today
    MOCK.units.target = GUARD_THOMAS
    DoEmote("SALUTE")
    assert(Points(261) == 150, "a named guard could not be introduced by emote")
    ns.Database.Remove(261)
    MOCK.units.target = GUARD
end)

step("emote introductions respect recipients and unit restrictions", function()
    local id = 990002
    local wanderer = { guid = "Creature-0-1-2-3-990002-0000AB", npcID = id,
        name = "Test Wanderer", type = "Humanoid", class = "normal", reaction = 5 }
    MOCK.units.npc = nil
    MOCK.units.target = wanderer
    DoEmote("WAVE", "missing")
    assert(not BuddyDexCharDB.friends[id], "an unavailable recipient credited the selected target")
    MOCK.units.mouseover = wanderer
    MOCK.units.target = GUARD
    DoEmote("SMILE", "mouseover")
    assert(Points(id) == 25 and not BuddyDexCharDB.friends[5595], "explicit recipient was ignored")
    ns.Database.Remove(id)
    MOCK.units.mouseover = nil
    MOCK.units.target = wanderer
    local function Blocked(why)
        DoEmote("WAVE")
        assert(not BuddyDexCharDB.friends[id], why .. " was befriended through an emote")
    end
    MOCK.combat = true
    Blocked("combat target")
    MOCK.combat = false
    local identity = C_Secrets.ShouldUnitIdentityBeSecret
    C_Secrets.ShouldUnitIdentityBeSecret = function() return true end
    Blocked("restricted identity")
    C_Secrets.ShouldUnitIdentityBeSecret = identity
    wanderer.reaction = 2
    Blocked("hostile NPC")
    wanderer.reaction = 5
    for _, flag in ipairs({ "attackable", "player", "controlled" }) do
        wanderer[flag] = true
        Blocked(flag)
        wanderer[flag] = nil
    end
    wanderer.tip = { wanderer.name, "Someone's Pet", "Level 1" }
    Blocked("owned pet")
    wanderer.tip = nil
    wanderer.type = "Non-combat Pet"
    Blocked("non-combat pet")
    MOCK.units.target = nil
    DoEmote("WAVE")
    assert(not BuddyDexCharDB.friends[id], "an untargeted wave created a friend")
    MOCK.units.target = GUARD
end)

step("hostile and attackable NPCs, players and combat never count", function()
    MOCK.units.npc = GRUNT
    FireAll("GOSSIP_SHOW")
    MOCK.units.npc = BOAR
    FireAll("GOSSIP_SHOW")
    MOCK.units.npc = { guid = "Player-1-0001", name = "Someone", player = true, reaction = 5 }
    FireAll("GOSSIP_SHOW")
    MOCK.units.npc = { guid = "Creature-0-1-2-3-999-0000AB", npcID = 999, name = "Pet", controlled = true, reaction = 5 }
    FireAll("GOSSIP_SHOW")
    MOCK.combat = true
    MOCK.units.npc = { guid = "Creature-0-1-2-3-4258-0000AB", npcID = 4258, name = "Bengus", reaction = 5 }
    FireAll("GOSSIP_SHOW")
    MOCK.combat = false
    for _, id in ipairs({ 3296, 1125, 999, 4258 }) do
        assert(BuddyDexCharDB.friends[id] == nil, "befriended " .. id)
    end
    -- The guard was targeted all along: an NPC that doesn't count never
    -- passes the credit to the target.
    assert(BuddyDexCharDB.friends[5595] == nil, "the target took the credit")
    -- A wanted poster (no "npc" unit) never counts for the target either.
    MOCK.units.npc = nil
    FireAll("QUEST_DETAIL")
    assert(BuddyDexCharDB.friends[5595] == nil, "an object's quest counted for the target")
end)

step("the next day counts again, and Buddy plays the fanfare", function()
    MOCK.today = "2026-10-11"
    MOCK.played = {}
    MOCK.units.target = nil
    MOCK.units.npc = LYMPKIN
    FireAll("QUEST_COMPLETE")
    assert(Points(9859) == 325, "points " .. tostring(Points(9859)))
    assert(ns.Friendship.IsBuddy(BuddyDexCharDB.friends[9859]), "not a Buddy")
    local fanfare = false
    for _, kit in ipairs(MOCK.played) do
        if kit == "UI_GARRISON_TOAST_FOLLOWER_GAINED" then fanfare = true end
    end
    assert(fanfare, "no Buddy fanfare")
    -- An Ironforge Guard is one of many: talking to one makes no friend.
    MOCK.units.npc = GUARD
    FireAll("GOSSIP_SHOW")
    assert(BuddyDexCharDB.friends[5595] == nil, "an Ironforge Guard became a friend")
    MOCK.units.npc = GUARD_THOMAS
    FireAll("GOSSIP_SHOW")
    MOCK.units.npc = nil
    -- Once met, a friendly emote counts a little.
    MOCK.units.target = GUARD_THOMAS
    DoEmote("WAVE")
    assert(Points(261) == 65, "an emote after meeting did not count: " .. tostring(Points(261)))
    MOCK.units.target = nil
end)

step("one of many, or someone", function()
    local is = ns.Friendship.IsSomeone
    for _, name in ipairs({ "Stormwind City Guard", "Ironforge Mountaineer", "Orgrimmar Grunt", "Darnassus Sentinel",
        "Undercity Guardian", "Thunder Bluff Bluffwatcher", "Protector of the People", "Stormwind City Patroller",
        "Stormwind Citizen", "Stormwind Civilian", "Stormwind City Watch", "Townsfolk", "Dwarf Guard", "Deathguard Veteran" }) do
        assert(not is(name, 1), name .. " counted as someone")
    end
    for _, name in ipairs({ "Guard Thomas", "Mountaineer Kadrell", "Thor", "Auctioneer Lympkin", "Gina MacGregor", "Jenn Langston",
        "Deathguard Bartrand", "Deathguard Oliver", "Deathguard Phillip", "Deathguard Randolph" }) do
        assert(is(name, 1), name .. " counted as one of many")
    end
    ns.Lore[68] = { quote = "Move along." }
    assert(not is("Stormwind City Guard", 68), "a lore entry bypassed the generic-name exclusion")
    ns.Lore[68] = nil
    MOCK.units.target = GUARD
    SlashCmdList.BUDDYDEX("give 100")
    assert(BuddyDexCharDB.friends[5595] == nil and Printed("Every Ironforge Guard is the same NPC"), "/bd give befriended a guard")
    MOCK.units.target = nil
end)

step("/bd opens the BuddyDex, grouped by zone", function()
    SlashCmdList.BUDDYDEX("")
    MOCK.Advance(1)
    assert(BuddyDexFrame and BuddyDexFrame:IsShown(), "window not shown")
    local rows, sb = FriendRows()
    assert(#rows == 2, "expected 2 friends, got " .. #rows)
    assert(sb.__dp.items[1].header and sb.__dp.items[1].zone == "Ironforge", "no Ironforge header first")
    assert(#MOCK.model.setCreature >= 1, "no model loaded")
end)

step("a loaded model caches display and moves, and the NPC greets", function()
    local npc = MOCK.model.setCreature[1][1]
    MOCK.model.displays[npc] = 7028
    MOCK.model.anims[npc] = { [0] = true, [67] = true, [69] = true }
    for _, f in ipairs(FindByKind("DressUpModel")) do MOCK.Fire(f, "OnModelLoaded") end
    MOCK.Advance(1)
    local e = BuddyDexCharDB.friends[npc]
    assert(e.display == 7028, "display not cached")
    assert(type(e.moves) == "table" and #e.moves == 2, "moves not cached")
    local greeted = false
    for _, f in ipairs(FindByKind("DressUpModel")) do
        if f.__npc == npc and f.__anim == 67 then greeted = true end
    end
    assert(greeted, "the NPC did not wave when picked")
end)

step("the portrait loader fills in every row, only while open", function()
    for id in pairs(BuddyDexCharDB.friends) do
        MOCK.model.displays[id] = MOCK.model.displays[id] or (50000 + id)
        MOCK.model.anims[id] = MOCK.model.anims[id] or { [0] = true, [66] = true }
    end
    MOCK.Advance(20)
    for id, e in pairs(BuddyDexCharDB.friends) do assert(e.display, "no portrait for " .. id) end
end)

step("search, filters and zone headers", function()
    local search = FindFrames("SearchBoxTemplate")[1]
    search:SetText("lymp")
    MOCK.Fire(search, "OnTextChanged", true)
    MOCK.Advance(1)
    assert(#FriendRows() == 1, "search did not narrow")
    search:SetText("")
    MOCK.Fire(search, "OnTextChanged", false)

    local filter = FindFrames("WowStyle1FilterDropdownTemplate")[1]
    local root = MOCK.RunMenu(filter.__menu, filter)
    MOCK.ClickEverything(root)
    filter.__update()
    filter.__default()
    assert(filter.__isDefault() == true, "reset did not restore the defaults")
    BuddyDexCharDB.dex.buddiesOnly = true
    filter.__update()
    assert(#FriendRows() == 1, "buddies only kept " .. #FriendRows())
    filter.__default()
    assert(#FriendRows() == 2, "reset did not bring both back")

    local _, sb = FriendRows()
    local header = sb.__pool.CheckButton[1]
    MOCK.Fire(header, "OnClick")
    assert(#FriendRows() == 0, "collapsing the zone did not hide its friends")
    MOCK.Fire(header, "OnClick")
    assert(#FriendRows() == 2, "expanding did not bring them back")
end)

step("pinning a friend lists them first, under Pinned", function()
    local function RowFor(id)
        local _, sb = FriendRows()
        for _, row in ipairs(sb.__pool.Button) do
            local d = row:GetElementData()
            if d and d.npcID == id then return row end
        end
    end
    local function Click(row, text)
        MOCK.Fire(row, "OnClick", "RightButton")
        for _, child in ipairs(MOCK.lastContextMenu.children) do
            if child.kind == "button" and child.text == text then child.a(child.data) return true end
        end
        return false
    end
    local rows, sb = FriendRows()
    local id = rows[#rows].npcID
    assert(Click(RowFor(id), "Pin to top"), "no Pin to top")
    MOCK.Advance(1)
    local items = sb.__dp.items
    assert(items[1].header and items[1].zone == "Pinned" and items[2].npcID == id, "not pinned first")
    assert(#FriendRows() == #rows, "pinning changed how many friends are listed")
    assert(Click(RowFor(id), "Unpin"), "no Unpin")
    MOCK.Advance(1)
    assert(sb.__dp.items[1].zone ~= "Pinned", "still pinned")
end)

step("forget a friendship from the row menu", function()
    local _, sb = FriendRows()
    local row = sb.__pool.Button[1]
    local id = row:GetElementData().npcID
    MOCK.Fire(row, "OnEnter")
    MOCK.Fire(row, "OnLeave")
    MOCK.Fire(row, "OnClick", "RightButton")
    local forgot = false
    for _, child in ipairs(MOCK.lastContextMenu.children) do
        if child.kind == "button" and child.text:find("Forget") then
            child.a(child.data)
            forgot = true
        end
    end
    assert(forgot, "no forget button")
    MOCK.Advance(1)
    assert(BuddyDexCharDB.friends[id] == nil, "still a friend")
    assert(#FriendRows() == 1, "row still listed")
end)

step("side tabs, the settings page and the buddy's checkboxes", function()
    local tabs = FindFrames("LargeSideTabButtonTemplate")
    assert(#tabs == 3, "expected 3 side tabs, got " .. #tabs)
    tabs[3].__mouseUp(tabs[3], "LeftButton", true)
    tabs[2].__mouseUp(tabs[2], "LeftButton", true)
    local checks = FindFrames("UICheckButtonTemplate")
    assert(#checks == 10, "expected 10 checkboxes, got " .. #checks)
    for _, check in ipairs(checks) do
        local key = check.settingKey
        local before = BuddyDexCharDB.settings[key] and true or false
        check:SetChecked(not before)
        MOCK.Fire(check, "OnClick")
        assert(BuddyDexCharDB.settings[key] == not before, key .. " not saved")
        check:SetChecked(before)
        MOCK.Fire(check, "OnClick")
        assert(BuddyDexCharDB.settings[key] == before, key .. " not put back")
    end
    tabs[1].__mouseUp(tabs[1], "LeftButton", true)
    assert(BuddyDexFrame.__title == "BuddyDex", "title " .. tostring(BuddyDexFrame.__title))
end)

step("a new friend appears live, and reopening reloads the model", function()
    MOCK.today = "2026-10-12"
    MOCK.units.npc = { guid = "Creature-0-1-2-3-5163-0000AB", npcID = 5163, name = "Burbik Gearspanner",
        type = "Humanoid", class = "normal", level = 30, reaction = 5, tip = { "Trade Supplier", "Level 30" } }
    local before = #FriendRows()
    FireAll("MERCHANT_SHOW")
    MOCK.Advance(1)
    assert(#FriendRows() == before + 1, "new friend did not appear")
    local loads = #MOCK.model.setCreature
    BuddyDexFrame:Hide()
    MOCK.Advance(1)
    SlashCmdList.BUDDYDEX("")
    MOCK.Advance(1)
    assert(#MOCK.model.setCreature > loads, "model not reloaded after reopening")
end)

step("slash commands and the addon compartment", function()
    for _, arg in ipairs({ "settings", "help", "nonsense", "" }) do
        SlashCmdList.BUDDYDEX(arg)
        MOCK.Advance(0.5)
    end
    BuddyDex_OnAddonCompartmentEnter("BuddyDex", UIParent)
    BuddyDex_OnAddonCompartmentLeave("BuddyDex", UIParent)
    BuddyDex_OnAddonCompartmentClick("BuddyDex", "RightButton")
    BuddyDex_OnAddonCompartmentClick("BuddyDex", "LeftButton")
    MOCK.Advance(5)
end)

step("Thor: met at the flight path, with his own favorite", function()
    MOCK.today = "2026-10-13"
    MOCK.units.target = nil
    MOCK.units.npc = THOR
    FireAll("TAXIMAP_OPENED")
    MOCK.units.npc = nil
    local e = BuddyDexCharDB.friends[523]
    assert(e and e.points == 50, "Thor not met: " .. tostring(e and e.points))
    assert(e.mapID == 1455 and e.x == 0.5641 and e.y == 0.5262, "position not saved")
    local fav = ns.Friendship.Favorite(e, 523)
    assert(fav.token == "WAVE" and fav.hint == ns.Lore[523].favorite.hint, "Thor's own favorite not used")
end)

step("Farley's merchant friendship discovers his favorite and unlocks his entry", function()
    local farley = { guid = "Creature-0-1-2-3-295-0000AB", npcID = 295,
        name = "Innkeeper Farley", type = "Humanoid", typeID = 7,
        class = "normal", level = 30, sex = 2, reaction = 5,
        faction = "Alliance", tip = { "Innkeeper", "Level 30", "Goldshire" } }
    MOCK.units.npc = farley
    FireAll("MERCHANT_SHOW")
    MOCK.units.npc = nil
    local e = BuddyDexCharDB.friends[295]
    assert(e and e.points == 60, "Farley was not met through his services")
    assert(not ns.DexDetail.LoreParts(295, e).quote, "Farley's personality unlocked too soon")
    MOCK.units.target = farley
    DoEmote("THANK")
    assert(e.favoriteFound and e.points == 210, "Farley's favorite cannot be discovered")
    DoEmote("THANK")
    assert(e.points == 210, "Farley's favorite bypassed its daily cap")
    SetTier(e, 6)
    local parts = ns.DexDetail.LoreParts(295, e)
    assert(parts.unlocked == 7 and parts.bestFriend
        and parts.bestFriend:find(ns.Lore[295].bestFriend, 1, true),
        "Farley's complete entry did not unlock")
    MOCK.units.target = nil
    ns.Database.Remove(295)
end)

step("Thor's entry unlocks by tier, and /bd lore previews it", function()
    local e = BuddyDexCharDB.friends[523]
    local parts = ns.DexDetail.LoreParts(523, e)
    assert(not parts.quote and (parts.personalityLocked or ""):find("Reach Acquaintance with Thor to hear from him"),
        "stranger: " .. tostring(parts.personalityLocked))
    local titles = {}
    for i, section in ipairs(parts.sections) do titles[i] = section.title end
    assert(table.concat(titles, ", ") == "Word Around Town, Story, Backstory, Secret, Just Between Friends",
        "lore sections: " .. table.concat(titles, ", "))
    assert((parts.sections[1].teaser or ""):find("Reach Buddy with Thor to hear what people say about him"),
        "gossip lock: " .. tostring(parts.sections[1].teaser))
    assert((parts.sections[2].teaser or ""):find("Reach Friend with Thor to hear his story"),
        "story lock: " .. tostring(parts.sections[2].teaser))
    assert((parts.sections[3].teaser or ""):find("to learn where his story began"), "backstory lock")
    assert(not parts.sections[5].text and parts.sections[5].label == "Best Friend", "best friend section")
    assert(parts.unlocked == 0 and parts.total == 7, "page count " .. parts.unlocked .. "/" .. parts.total)
    SetTier(e, 3)
    parts = ns.DexDetail.LoreParts(523, e)
    assert(parts.quote and parts.likes and parts.dislikes and not parts.bio, "buddy parts")
    assert(parts.likes:find("Well%-fed gryphons"), "likes text")
    assert(not parts.personalityLocked, "personality still locked: " .. tostring(parts.personalityLocked))
    assert(parts.gossip and parts.sections[1].text and parts.sections[2].teaser and parts.unlocked == 3,
        "a buddy hears the word around town, and no more")
    SetTier(e, 6)
    parts = ns.DexDetail.LoreParts(523, e)
    for _, key in ipairs({ "quote", "likes", "dislikes", "gossip", "bio", "backstory", "secret", "bestFriend" }) do
        assert(parts[key], "a best friend is missing " .. key)
    end
    for _, section in ipairs(parts.sections) do
        assert(section.text and not section.teaser, section.title .. " still locked")
    end
    assert(not parts.personalityLocked and parts.unlocked == 7, "not every page unlocked")
    e.points = 50
    SlashCmdList.BUDDYDEX("lore")
    parts = ns.DexDetail.LoreParts(523, e)
    assert(parts.bestFriend and parts.unlocked == 7, "the preview did not show everything")
    SlashCmdList.BUDDYDEX("lore")
    assert(not ns.DexDetail.LoreParts(523, e).quote, "the preview did not turn off")
    local other = ns.DexDetail.LoreParts(999999, { name = "Unauthored acquaintance", points = 9999 })
    assert((other.note or ""):find("no entry on Unauthored acquaintance") and #other.sections == 0, "an NPC without lore")
end)

-- The writing rules in docs/LORE.md that a test can check. The Lore column
-- is about 52 characters wide; wrapping at 50 counts a little high, which
-- keeps an entry that passes here clear of the scroll bar in game.
step("every lore entry fits its pages", function()
    local WRAP = 50
    local function Lines(text)
        if type(text) ~= "string" or text == "" then return 0 end
        local lines, width = 1, 0
        for word in text:gmatch("%S+") do
            if width == 0 then
                width = #word
            elseif width + 1 + #word <= WRAP then
                width = width + 1 + #word
            else
                lines, width = lines + 1, #word
            end
        end
        return lines
    end
    local BUDGET = { { "gossip", 3 }, { "bio", 6 }, { "backstory", 6 }, { "secret", 4 }, { "bestFriend", 3 } }
    local TOTAL = 21
    local acceptedEmotes = {}
    for _, emote in ipairs(ns.Friendship.EMOTES) do acceptedEmotes[emote.token] = true end
    for npcID, lore in pairs(ns.Lore) do
        local function Check(ok, what) assert(ok, ("NPC %d: %s"):format(npcID, what)) end
        if lore.favorite then
            Check(acceptedEmotes[lore.favorite.emote], "favorite cannot earn friendship or appear in the emote menu")
        end
        local total = 0
        for _, rule in ipairs(BUDGET) do
            local key, most = rule[1], rule[2]
            local text = lore[key]
            if key == "bestFriend" and text then text = '"' .. text .. '"' end
            local lines = Lines(text)
            Check(lines <= most, ("%s runs %d lines, %d at most"):format(key, lines, most))
            total = total + lines
        end
        Check(total <= TOTAL, ("the Lore column runs %d lines, %d at most"):format(total, TOTAL))
        Check(not lore.quote or #lore.quote <= 200, "the quote runs past two lines")
        for _, list in ipairs({ "likes", "dislikes" }) do
            local items = lore[list]
            if items then
                Check(#items >= 2 and #items <= 3, list .. " should have two or three items")
                for _, item in ipairs(items) do Check(#item <= 45, list .. " item too long: " .. item) end
            end
        end
        if lore.lines then
            local count = 0
            for _, pile in pairs(lore.lines) do count = count + #pile end
            Check(count >= 12 and count <= 20, ("%d lines of their own, about 15 wanted"):format(count))
        end
    end
end)

step("a waypoint to Thor: TomTom first, then the map's own pin", function()
    TomTom = { AddWaypoint = function(self, m, x, y, opts) MOCK.tomtom = { m = m, x = x, y = y, opts = opts } end }
    assert(ns.Waypoint.Set(523), "TomTom waypoint not set")
    local t = MOCK.tomtom
    assert(t and t.m == 1455 and t.x == 0.5641 and t.y == 0.5262, "TomTom position")
    assert(t.opts.title == "Thor <Gryphon Master>" and t.opts.from == "BuddyDex", "TomTom options")
    TomTom = nil
    assert(ns.Waypoint.Set(523), "map pin not set")
    assert(MOCK.userWaypoint and MOCK.userWaypoint.uiMapID == 1455 and MOCK.superTracked == true, "map pin")
    local e = BuddyDexCharDB.friends[523]
    local x = e.x
    e.x = nil
    assert(not ns.Waypoint.Set(523), "set a waypoint without a position")
    assert(Printed("doesn't know where Thor is yet"), "no explanation")
    e.x = x
end)

step("the Dex shows Thor's story, his coordinates and the waypoint button", function()
    ns.Dex.Open()
    ns.Dex.ShowTab(1)
    MOCK.Advance(1)
    ns.DexDetail.Show(523)
    MOCK.Advance(1)
    SetTier(BuddyDexCharDB.friends[523], 6)
    ns.DexDetail.Redraw()
    local story, coords, button = false, false, nil
    for _, f in ipairs(MOCK.frames) do
        local text = f.__text
        if type(text) == "string" then
            if text:find("gryphon roost on Sentinel Hill", 1, true) and f:IsShown() then story = true end
            if text:find("56.4, 52.6", 1, true) then coords = true end
            if text == "Set waypoint" and f.__kind == "Button" then button = f end
        end
    end
    assert(story, "Thor's story is not on the card")
    local complete = false
    for _, f in ipairs(MOCK.frames) do
        if type(f.__text) == "string" and f.__text:find("Every page unlocked", 1, true) then complete = true end
    end
    assert(complete, "the footer does not say the entry is complete")
    local counted = false
    for _, f in ipairs(MOCK.frames) do
        if f.__text == "7 of 7 pages" then counted = true end
    end
    assert(counted, "the Lore header does not count the pages")
    assert(coords, "no coordinates in Area")
    assert(button and button:IsEnabled(), "the waypoint button is missing or disabled")
    TomTom = { AddWaypoint = function(self, m) MOCK.tomtom = { m = m } end }
    MOCK.tomtom = nil
    MOCK.Fire(button, "OnEnter")
    MOCK.Fire(button, "OnLeave")
    MOCK.Fire(button, "OnClick")
    assert(MOCK.tomtom and MOCK.tomtom.m == 1455, "the button did not set a waypoint")
    TomTom = nil
end)

step("/bd give changes a friendship for testing", function()
    -- The Dex shows Thor; nothing is targeted.
    MOCK.units.target = nil
    local thor = BuddyDexCharDB.friends[523]
    SlashCmdList.BUDDYDEX("give stranger")
    assert(thor.points == 0, "give stranger: " .. tostring(thor.points))
    MOCK.played = {}
    SlashCmdList.BUDDYDEX("give buddy")
    assert(ns.Friendship.TierIndex(thor) == 3 and thor.points == ns.Friendship.Threshold(thor, 3), "give buddy")
    assert(#MOCK.played > 0, "no tier-up sound")
    SlashCmdList.BUDDYDEX("give 25")
    assert(thor.points == ns.Friendship.Threshold(thor, 3) + 25, "give 25")
    SlashCmdList.BUDDYDEX("give -99999")
    assert(thor.points == 0, "the bar went below zero")
    SlashCmdList.BUDDYDEX("give Best Friend")
    assert(ns.Friendship.TierIndex(thor) == 6, "give best friend")
    SlashCmdList.BUDDYDEX("give 500")
    assert(Printed("Thor is already at Best Friend"), "no message at the top")
    -- A target is used first, and a qualifying one becomes a friend.
    MOCK.units.target = { guid = "Creature-0-1-2-3-6094-0000AB", npcID = 6094, name = "Byancie",
        type = "Humanoid", class = "normal", level = 20, sex = 3, reaction = 5, tip = { "First Aid Trainer", "Level 20" } }
    SlashCmdList.BUDDYDEX("give 120")
    local e = BuddyDexCharDB.friends[6094]
    assert(e and e.points == 120, "target not befriended: " .. tostring(e and e.points))
    MOCK.units.target = GUARD
    SlashCmdList.BUDDYDEX("give nonsense")
    assert(Printed("Usage: /bd give"), "no usage line")
    MOCK.units.target = nil
end)

-- The Mini Me on screen ---------------------------------------------------------------

local function Bubble()
    for _, f in ipairs(MOCK.frames) do
        if f.__kind == "Frame" and f.__template == "ChatBubbleTemplate" then return f end
    end
end

local function Saying()
    local b = Bubble()
    return b and b:IsShown() and b.String and b.String.__text or nil
end

local function Actor()
    for _, f in ipairs(FindByKind("ModelSceneActor")) do
        if f.__parent and f.__parent.__parent == BuddyDexCompanion then return f end
    end
end

-- Whether a line said is one of a pile's, once its tokens are filled in.
local function FromPile(text, pile)
    if type(text) ~= "string" then return false end
    for _, line in ipairs(pile or {}) do
        local raw = type(line) == "table" and line[1] or line
        local pattern = "^" .. raw:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("{%w+}", ".-") .. "$"
        if text:find(pattern) then return true end
    end
    return false
end

local function Quiet() MOCK.Advance(30) end

step("the Mini Me steps onto the screen and says hello", function()
    MOCK.units.player = { name = "Baz", level = 14, sex = 2 }
    MOCK.spoken = {}
    local settings = BuddyDexCharDB.settings
    -- At full chattiness every comment is said (below it, chance skips some).
    settings.companion, settings.voiceMode, settings.chattiness = true, "recorded", 100
    -- Idle chatter on a timer would talk over the steps below.
    ns.Reactions.IDLE_BASE = 1e9
    FireAll("PLAYER_ENTERING_WORLD", true, false)
    MOCK.Advance(2.2)
    assert(BuddyDexCompanion and BuddyDexCompanion:IsShown(), "no Mini Me on screen")
    for _, f in ipairs(FindByKind("ModelSceneActor")) do MOCK.Fire(f, "OnModelLoaded") end
    MOCK.Advance(1)
    local said = Saying()
    local greetings = {}
    for _, key in ipairs({ "greet", "greetMorning", "greetAfternoon", "greetEvening", "greetNight" }) do
        for _, line in ipairs(ns.Lines[key] or {}) do greetings[#greetings + 1] = line end
    end
    assert(FromPile(said, greetings), "not a greeting: " .. tostring(said))
    assert(#MOCK.spoken == 0 and #MOCK.soundFiles == 0, "a sound without voice recordings")
    assert(Actor() and Actor().__anim and Actor().__anim ~= 0, "no gesture with the greeting")
    -- Framed by where the model lands, not the camera's guess: feet to head,
    -- five sixths of the frame's height, whichever way the field of view runs.
    local scene = Actor().__parent
    local _, feet = scene:Project3DPointTo2D(0, 0, 0)
    local _, head = scene:Project3DPointTo2D(0, 0, 1)
    local share = (head - feet) / scene:GetHeight()
    assert(math.abs(share - 1 / 1.2) < 0.03, "the Mini Me fills " .. share .. " of the frame, not 5/6")
    assert(math.abs(scene.zoom - 2) < 0.05, "the camera did not step back for the wide field of view")
end)

step("lines fade out, small comments wait their turn, big moments don't", function()
    Quiet()
    assert(not Saying(), "the greeting never faded")
    MOCK.zone = "Westfall"
    FireAll("ZONE_CHANGED_NEW_AREA")
    local zoneLine = Saying()
    assert(zoneLine and zoneLine:find("Westfall", 1, true), "no zone comment: " .. tostring(zoneLine))
    FireAll("QUEST_TURNED_IN")
    assert(Saying() == zoneLine, "a small comment talked over another")
    FireAll("PLAYER_LEVEL_UP", 15)
    assert((Saying() or ""):find("15", 1, true), "no level-up line: " .. tostring(Saying()))
    Quiet()
    BuddyDexCharDB.settings.chattiness = 0
    MOCK.zone = "Duskwood"
    FireAll("ZONE_CHANGED_NEW_AREA")
    FireAll("PLAYER_LEVEL_UP", 16)
    assert(not Saying(), "talked at Quiet")
    MOCK.units.target = nil
    DoEmote("WAVE")
    assert(FromPile(Saying(), ns.Lines.waveBack), "didn't answer a wave at Quiet")
    BuddyDexCharDB.settings.chattiness = 100
end)

step("no line comes back until its pile is used up", function()
    local pile = ns.Lines.poke
    local seen, said = {}, 0
    for _ = 1, #pile do
        Quiet()
        ns.Companion.SayLine("poke")
        local text = Saying()
        assert(text, "nothing said")
        assert(not seen[text], "a poke line came back early: " .. text)
        seen[text] = true
        said = said + 1
    end
    assert(said == #pile, "not every poke line was said")
    assert(type(BuddyDexCharDB.recentLines["me:poke"]) == "table", "recent lines not remembered")
end)

step("lines that suit a class, a zone or a level", function()
    local classLines, wrongClass = 0, 0
    for _ = 1, 200 do
        Quiet()
        ns.Companion.SayLine("idle")
        local text = Saying() or ""
        for _, line in ipairs(ns.Lines.idle) do
            if type(line) == "table" and line[1] == text then
                if line.class == "MAGE" then classLines = classLines + 1 end
                if line.class and line.class ~= "MAGE" then wrongClass = wrongClass + 1 end
                if line.zone and line.zone ~= MOCK.zone then error("a line for another zone: " .. text) end
            end
        end
    end
    assert(wrongClass == 0, "lines for another class")
    assert(classLines > 0, "never a mage line")
end)

step("a new Buddy gets a celebration", function()
    Quiet()
    MOCK.units.target = nil
    ns.DexDetail.Show(523)
    MOCK.Advance(1)
    SlashCmdList.BUDDYDEX("give stranger")
    SlashCmdList.BUDDYDEX("give buddy")
    assert((Saying() or ""):find("Thor", 1, true), "no Buddy line: " .. tostring(Saying()))
    local anim = Actor().__anim
    assert(anim == 68 or anim == 69 or anim == 80, "no celebration: " .. tostring(anim))
end)

step("the recorded voice: his clips, her clips, none without recordings or with voice off", function()
    Quiet()
    local male, female = {}, {}
    for _, line in ipairs(ns.Lines.poke) do
        local text = type(line) == "table" and line[1] or line
        male[text], female[text] = "male\\poke.ogg", "female\\poke.ogg"
    end
    ns.VoicePack = { version = 1, path = "Interface\\AddOns\\BuddyDex\\voice\\",
        voices = { male = male, female = female } }
    assert(ns.Voice.Mode() == "recorded", "no recorded voice with recordings loaded")
    MOCK.soundFiles = {}
    ns.Companion.SayLine("poke")
    assert(MOCK.soundFiles[1] == "Interface\\AddOns\\BuddyDex\\voice\\male\\poke.ogg", "his clip did not play")
    Quiet()
    MOCK.units.player.sex = 3
    ns.Companion.SayLine("poke")
    assert(MOCK.soundFiles[2] == "Interface\\AddOns\\BuddyDex\\voice\\female\\poke.ogg", "her clip did not play")
    MOCK.units.player.sex = 2
    Quiet()
    FireAll("PLAYER_LEVEL_UP", 18)
    assert(Saying() and #MOCK.soundFiles == 2, "a line without a clip made a sound")
    Quiet()
    ns.Companion.SetSetting("voiceMode", "off")
    ns.Companion.SayLine("poke")
    assert(Saying() and #MOCK.soundFiles == 2, "spoke with the voice off")
    ns.Companion.SetSetting("voiceMode", "recorded")
    ns.VoicePack = nil
    assert(ns.Voice.Mode() == "off", "a voice without recordings")
end)

step("new gear redresses the Mini Me once the swap settles", function()
    Quiet()
    local before = MOCK.modelByUnit or 0
    FireAll("PLAYER_EQUIPMENT_CHANGED", 5, true)
    FireAll("PLAYER_EQUIPMENT_CHANGED", 7, true)
    MOCK.Advance(0.2)
    assert((MOCK.modelByUnit or 0) == before, "redressed before the swap settled")
    FireAll("UNIT_MODEL_CHANGED", "player")
    MOCK.Advance(1)
    assert((MOCK.modelByUnit or 0) - before == 1, "expected one redress")
    for _, f in ipairs(FindByKind("ModelSceneActor")) do MOCK.Fire(f, "OnModelLoaded") end
    MOCK.Advance(1)
    assert(FromPile(Saying(), ns.Lines.gear), "no word about the new gear")
end)

step("away it naps, back it wakes", function()
    Quiet()
    MOCK.units.player.afk = true
    FireAll("PLAYER_FLAGS_CHANGED", "player")
    assert(Actor().__anim == 100, "not asleep")
    MOCK.Advance(30)
    assert(Actor().__anim == 100, "woke up on its own")
    MOCK.units.player.afk = false
    FireAll("PLAYER_FLAGS_CHANGED", "player")
    assert(Actor().__anim ~= 100, "did not wake")
end)

step("in combat it stays, quietly, or hides if asked", function()
    Quiet()
    FireAll("PLAYER_REGEN_DISABLED")
    MOCK.Advance(0.5)
    assert(ns.Companion.IsShown(), "left in combat while set to stay")
    assert(ns.Companion.InCombat(), "doesn't know it's in combat")
    FireAll("PLAYER_LEVEL_UP", 16)
    local said = Saying()
    assert(not said or FromPile(said, ns.Lines.combatStart), "chatted in a fight: " .. tostring(said))
    FireAll("PLAYER_REGEN_ENABLED")
    MOCK.Advance(1)
    assert(not ns.Companion.InCombat(), "still thinks it's fighting")
    Quiet()
    ns.Companion.SetSetting("combat", "hide")
    FireAll("PLAYER_REGEN_DISABLED")
    MOCK.Advance(1)
    assert(not BuddyDexCompanion:IsShown(), "didn't hide in combat when asked to")
    FireAll("PLAYER_REGEN_ENABLED")
    MOCK.Advance(1)
    assert(BuddyDexCompanion:IsShown(), "didn't come back after combat")
    ns.Companion.SetSetting("combat", "stay")
end)

step("flights, emotes at it, targeting a friend", function()
    Quiet()
    MOCK.onTaxi = true
    FireAll("PLAYER_CONTROL_LOST")
    MOCK.Advance(1.5)
    assert(FromPile(Saying(), ns.Lines.taxi), "nothing said about flying: " .. tostring(Saying()))
    Quiet()
    MOCK.onTaxi = false
    FireAll("PLAYER_CONTROL_GAINED")
    MOCK.Advance(1)
    assert(FromPile(Saying(), ns.Lines.landed), "nothing said about landing")
    Quiet()
    FireAll("CHAT_MSG_LOOT", "You receive loot: |cff0070dd|Hitem:2244::::::::|h[Krol Blade]|h|r.", "Baz")
    assert((Saying() or ""):find("Krol Blade", 1, true), "no word about the loot: " .. tostring(Saying()))
    Quiet()
    FireAll("CHAT_MSG_LOOT", "Someone receives loot: |cffa335ee|Hitem:1::::::::|h[Thing]|h|r.", "Someone")
    assert(not Saying(), "talked about someone else's loot")
    MOCK.units.target = nil
    C_ChatInfo.PerformEmote("WAVE", "")
    assert(FromPile(Saying(), ns.Lines.waveBack) and Actor().__anim == 67, "didn't wave back to a chat emote")
    Quiet()
    MOCK.units.target = { guid = "Creature-0-1-2-3-523-0000AB", npcID = 523, name = "Thor", reaction = 5 }
    FireAll("PLAYER_TARGET_CHANGED")
    assert((Saying() or ""):find("Thor", 1, true), "didn't point out a friend")
    MOCK.units.target = nil
end)

step("cheers from the sidelines partway into a fight", function()
    Quiet()
    FireAll("PLAYER_REGEN_DISABLED")
    MOCK.Advance(0.5)
    local said = ns.Companion.SayLine("combatMid", nil, nil, { combat = true }) and Saying()
    local quiet = not ns.Companion.SayLine("idle")
    -- End the fight before checking anything, so a failure can't leave it running.
    FireAll("PLAYER_REGEN_ENABLED")
    MOCK.Advance(1)
    assert(FromPile(said, ns.Lines.combatMid), "no fight cheer: " .. tostring(said))
    assert(quiet, "chatted in a fight")
    local mage = 0
    for _ = 1, 60 do
        Quiet()
        ns.Companion.SayLine("combatMid", nil, nil, { combat = true })
        for _, line in ipairs(ns.Lines.combatMid) do
            if type(line) == "table" and line[1] == Saying() then
                assert(not line.class or line.class == "MAGE", "a cheer for another class: " .. line[1])
                if line.class then mage = mage + 1 end
            end
        end
    end
    assert(mage > 0, "never a mage cheer")
end)

step("low on health in a fight, it worries, once", function()
    Quiet()
    -- Chance decides it in play; here it always speaks.
    local chances = ns.Reactions.FIGHT_CHANCES
    local saved, savedStart = chances.lowHealth, chances.combatStart
    -- Isolate the health reaction: a random opening cheer would still be
    -- talking at 0.5 seconds and legitimately suppress this reaction.
    chances.lowHealth, chances.combatStart = 1, 0
    FireAll("PLAYER_REGEN_DISABLED")
    MOCK.Advance(0.5)
    MOCK.units.player.health = 12
    FireAll("UNIT_HEALTH", "player")
    local said = Saying()
    MOCK.Advance(5)
    FireAll("UNIT_HEALTH", "player")
    local again = Saying()
    FireAll("PLAYER_REGEN_ENABLED")
    MOCK.units.player.health = 100
    MOCK.Advance(1)
    chances.lowHealth, chances.combatStart = saved, savedStart
    assert(FromPile(said, ns.Lines.lowHealth), "no worried line at 12% health: " .. tostring(said))
    assert(again == nil or again == said, "worried twice in one fight")
    assert(BuddyDexCharDB.probe and BuddyDexCharDB.probe.healthInCombat == "readable", "didn't note whether health was readable")
end)

step("the ghost walk gets its own lines", function()
    Quiet()
    MOCK.units.player.ghost = true
    FireAll("PLAYER_ALIVE")
    assert(FromPile(Saying(), ns.Lines.ghost), "nothing about the corpse run: " .. tostring(Saying()))
    MOCK.units.player.ghost = false
end)

step("the options page: voice, size, see-through", function()
    Quiet()
    local function Dropdown(firstChoice)
        for _, dd in ipairs(FindFrames("WowStyle1DropdownTemplate")) do
            local root = MOCK.RunMenu(dd.__menu, dd)
            if root.children[1] and root.children[1].text == firstChoice then return dd, root end
        end
    end
    local _, root = Dropdown("On")
    assert(root and #root.children == 2, "no voice dropdown, or more than On and Off")
    for _, child in ipairs(root.children) do
        if child.text == "Off" then child.b(child.data) end
    end
    assert(BuddyDexCharDB.settings.voiceMode == "off", "the voice dropdown did not save")
    ns.Companion.SetSetting("voiceMode", "recorded")
    local _, out = Dropdown("Your Mini Me")
    assert(out, "no Who's out dropdown")
    for _, slider in ipairs(FindFrames("MinimalSliderWithSteppersTemplate")) do
        if slider.__min == 0.5 then
            slider:SetValue(1.5)
            assert(BuddyDexCharDB.settings.scale == 1.5, "size not saved")
            assert(BuddyDexCompanion:GetScale() == 1, "the frame was scaled, which cuts the model off")
            assert(BuddyDexCompanion.__w == 250 * 1.5 and BuddyDexCompanion.__h == 190 * 1.5, "the frame didn't grow")
            local p = BuddyDexCompanion.__points[#BuddyDexCompanion.__points]
            assert(p[1] == "CENTER" and p[4] == 500 and p[5] == 300, "it didn't grow around its middle")
            assert(BuddyDexCompanion.__clamped == true, "not kept on screen by default")
            ns.Companion.SetSetting("clampToScreen", false)
            assert(BuddyDexCompanion.__clamped == false, "Keep on screen off didn't let it go")
            ns.Companion.SetSetting("clampToScreen", true)
            slider:SetValue(1)
        elseif slider.__min == 0.2 then
            slider:SetValue(0.6)
            assert(BuddyDexCharDB.settings.alpha == 0.6, "see-through not saved")
            slider:SetValue(1)
        elseif slider.__min == 0 and slider.__max == 100 then
            slider:SetValue(25)
            assert(BuddyDexCharDB.settings.chattiness == 25, "chattiness not saved")
            assert(slider.__formatters[MinimalSliderWithSteppersMixin.Label.Right](0) == "Quiet", "0 isn't Quiet")
            slider:SetValue(100)
        end
    end
    SlashCmdList.BUDDYDEX("options")
    MOCK.Advance(1)
end)

step("poke, the menu, hiding it and /bd buddy", function()
    Quiet()
    MOCK.Fire(BuddyDexCompanion, "OnEnter")
    MOCK.Fire(BuddyDexCompanion, "OnLeave")
    MOCK.Fire(BuddyDexCompanion, "OnClick", "LeftButton")
    assert(Saying(), "a poke got no answer")
    for _ = 1, 4 do MOCK.Fire(BuddyDexCompanion, "OnClick", "LeftButton") end
    assert(FromPile(Saying(), ns.Lines.pokeMany), "too many pokes got no complaint: " .. tostring(Saying()))
    MOCK.Fire(BuddyDexCompanion, "OnDragStart")
    MOCK.Fire(BuddyDexCompanion, "OnDragStop")
    MOCK.Fire(BuddyDexCompanion, "OnClick", "RightButton")
    local menu = MOCK.lastContextMenu
    assert(menu and menu.children[1].text == "Your Mini Me", "no menu")
    for _, child in ipairs(menu.children) do
        assert(child.text ~= "Voice" and child.text ~= "Speak out loud", "options crept back into the menu")
    end
    local lockItem
    for _, child in ipairs(menu.children) do
        if child.text == "Lock in place" or child.text == "Unlock" then lockItem = child end
    end
    assert(lockItem and lockItem.text == "Lock in place", "no lock toggle in the menu")
    lockItem.a(lockItem.data)
    assert(BuddyDexCharDB.settings.locked == true, "Lock in place didn't lock it")
    MOCK.Fire(BuddyDexCompanion, "OnClick", "RightButton")
    menu = MOCK.lastContextMenu
    local unlock
    for _, child in ipairs(menu.children) do
        if child.text == "Unlock" then unlock = child end
    end
    assert(unlock, "a locked buddy's menu has no Unlock")
    unlock.a(unlock.data)
    assert(BuddyDexCharDB.settings.locked == false, "Unlock didn't unlock it")
    MOCK.ClickEverything(menu)
    MOCK.Advance(1)
    assert(BuddyDexCharDB.settings.companion == false and not BuddyDexCompanion:IsShown(), "Hide did not hide it")
    SlashCmdList.BUDDYDEX("buddy")
    MOCK.Advance(2)
    assert(BuddyDexCharDB.settings.companion == true and BuddyDexCompanion:IsShown(), "/bd buddy did not bring it back")
end)

step("Thor comes along in the Mini Me's place, and goes home", function()
    -- The menu test clicked everything, Bring along included.
    ns.Companion.SetBuddy(nil)
    Quiet()
    local thor = BuddyDexCharDB.friends[523]
    SetTier(thor, 6)
    MOCK.model.anims[523] = { [0] = true, [60] = true, [67] = true, [68] = true }
    -- What the Dex learns when it loads him (tested above): his real display.
    MOCK.model.heights[3263] = 2
    ns.Database.SetModelInfo(523, 3263, { 60, 67, 68 })
    BuddyDexCharDB.settings.voiceMode = "recorded"
    MOCK.played = {}
    local function Played(kit)
        for _, k in ipairs(MOCK.played) do if k == kit then return true end end
        return false
    end
    ns.DexDetail.Show(523)
    MOCK.Advance(1)
    local gnomeHeight = BuddyDexCompanion.__h
    local button
    for _, f in ipairs(MOCK.frames) do
        if f.__kind == "Button" and f.__text == "Bring along" then button = f end
    end
    assert(button and button:IsEnabled(), "no Bring along button for a Best Friend")
    MOCK.Fire(button, "OnClick")
    assert(ns.Companion.Buddy() == 523 and BuddyDexCharDB.companionNpc == 523, "Thor did not come along")
    MOCK.Advance(0.2)
    assert(button.__text == "Send home", "the button did not change to Send home")
    -- He stands on a stage like the Mini Me's, at the same scale: a human
    -- twice a gnome's height, his feet where the Mini Me's were.
    local model
    for _, f in ipairs(FindByKind("ModelSceneActor")) do
        if f.__parent and f.__parent.__parent == BuddyDexCompanion and f.__display == 3263 then model = f end
    end
    assert(model, "Thor is not drawn on the stage")
    MOCK.Fire(model, "OnModelLoaded")
    MOCK.Advance(1)
    assert(math.abs(BuddyDexCharDB.miniMeHeight - 1) < 0.001, "the Mini Me was not measured")
    assert(math.abs(BuddyDexCompanion.__h / gnomeHeight - 2) < 0.001,
        "Thor is not twice the Mini Me's height: " .. tostring(BuddyDexCompanion.__h) .. " vs " .. tostring(gnomeHeight))
    assert(thor.height == 2, "Thor's height was not kept")
    local own, general = ns.Lore[523].lines, ns.NpcLines
    local said = Saying()
    assert(FromPile(said, own.befriended) or FromPile(said, own.greet) or FromPile(said, general.greet), "not a greeting or welcome: " .. tostring(said))
    -- In his own voice: the human male set his model uses (greeting 5974).
    assert(Played(5974), "Thor did not greet in his own voice")
    local kits = ns.Voice.NpcKits(3263)
    assert(kits and kits[1] == 5974 and kits[2] == 5975 and kits[3] == 5976, "Thor's voice set is wrong")
    assert(ns.Voice.NpcKits(326) == nil or ns.Voice.NpcKits(326) ~= kits, "a display matched another's prefix")
    MOCK.played = {}
    ns.Voice.Speak({ display = 3263, moment = "pokeMany" })
    assert(Played(5976), "poked too often, Thor was not annoyed")
    BuddyDexCharDB.settings.voiceMode = "off"
    MOCK.played = {}
    ns.Voice.Speak({ display = 3263, moment = "greet" })
    assert(#MOCK.played == 0, "Thor spoke with the voice off")
    BuddyDexCharDB.settings.voiceMode = "recorded"
    -- A gnome friend speaks in the Mini Me's recorded gnome voices instead,
    -- line by line. Thor, a human, has a recorded voice too, but this pack
    -- lacks it (an older pack), so he keeps the game's sounds.
    local savedPack = ns.VoicePack
    ns.VoicePack = { path = "Interface\\AddOns\\BuddyDex\\voice\\",
        voices = { female = { ["Lead the way, {name}."] = "female\\npc_greet_1.ogg" } } }
    assert(ns.Voice.NpcVoice(139800) == "female" and ns.Voice.NpcVoice(3263) == "human-male",
        "voices by race and sex")
    MOCK.played, MOCK.soundFiles = {}, {}
    assert(ns.Voice.Speak({ display = 139800, moment = "greet", line = "Lead the way, {name}." }),
        "a gnome friend's recorded line did not play")
    assert(#MOCK.soundFiles == 1 and #MOCK.played == 0, "a gnome friend made the game's sound too")
    assert(not ns.Voice.Speak({ display = 139800, moment = "greet", line = "Not recorded." })
        and #MOCK.played == 0, "a gnome friend's unrecorded line fell back to someone else's voice")
    assert(not ns.Voice.Farewell(139800), "a gnome friend said the game's farewell")
    assert(ns.Voice.Speak({ display = 3263, moment = "greet", line = "Lead the way, {name}." }) and Played(5974),
        "Thor lost his own voice to the pack")
    ns.VoicePack = savedPack


    Quiet()
    MOCK.Fire(BuddyDexCompanion, "OnClick", "LeftButton")
    assert(FromPile(Saying(), own.poke) or FromPile(Saying(), general.poke), "not a poke line: " .. tostring(Saying()))
    Quiet()
    FireAll("PLAYER_LEVEL_UP", 17)
    assert(FromPile(Saying(), own.levelUp) or FromPile(Saying(), general.levelUp), "not a level line")
    ns.Companion.Play(82)
    assert(model.__anim == 60, "a move Thor's model lacks did not fall back to talking")
    Quiet()
    FireAll("GROUP_JOINED")
    assert(FromPile(Saying(), general.group), "no general line for a moment Thor has none for")
    MOCK.Fire(BuddyDexCompanion, "OnClick", "RightButton")
    assert(MOCK.lastContextMenu.children[1].text == "Thor", "the menu is not Thor's")

    assert(not ns.Companion.SetBuddy(5595), "a guard who is no Buddy came along")
    ns.Friendship.Add(523, -99999)
    assert(ns.Companion.Buddy() == nil and BuddyDexCharDB.companionNpc == nil, "Thor stayed after the friendship fell")
    assert(not model.__parent:IsShown() and model.__display == nil, "Thor is still drawn")
    assert(BuddyDexCompanion.__h == gnomeHeight, "the Mini Me did not shrink back")
end)

step("personal friendship welcomes play once when a friend first comes along", function()
    local id, own = 5177, ns.Lore[5177].lines
    local entry = { name = "Tally Berryfizz", points = 10000, display = 3124 }
    BuddyDexCharDB.friends[id] = entry
    local originalSpeak, heard = ns.Voice.Speak, {}
    ns.Voice.Speak = function(opts) heard[#heard + 1] = opts; return true end
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    Quiet()
    heard = {}
    assert(ns.Companion.SetBuddy(id))
    MOCK.Advance(1)
    assert(#heard == 1 and heard[1].moment == "befriended"
        and FromPile(heard[1].line, own.befriended), "personal welcome was not selected")
    assert(entry.buddyWelcomed, "successful welcome was not saved")
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    Quiet()
    heard = {}
    ns.Companion.SetBuddy(id)
    MOCK.Advance(1)
    assert(#heard == 1 and heard[1].moment == "greet", "welcome repeated on a later outing")
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    Quiet()
    entry.buddyWelcomed = nil
    heard = {}
    ns.Companion.SetBuddy(id)
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    for _, opts in ipairs(heard) do assert(opts.display ~= 3124, "cancelled welcome spoke as Tally") end
    assert(not entry.buddyWelcomed, "cancelled welcome consumed the first welcome")
    -- Returning to the same NPC before the first fade ends must cancel the old timer too.
    heard = {}
    ns.Companion.SetBuddy(id)
    ns.Companion.SetBuddy(nil)
    ns.Companion.SetBuddy(id)
    MOCK.Advance(1)
    assert(#heard == 1 and heard[1].moment == "befriended", "rapid switches duplicated the welcome")
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    Quiet()
    entry.buddyWelcomed = nil
    -- A friend without an authored welcome still gets a normal greeting.
    local welcome = own.befriended
    own.befriended = nil
    heard = {}
    ns.Companion.SetBuddy(id)
    MOCK.Advance(1)
    assert(#heard == 1 and heard[1].moment == "greet", "missing welcome blocked greeting")
    assert(not entry.buddyWelcomed, "missing welcome was marked as delivered")
    own.befriended = welcome
    ns.Companion.SetBuddy(nil)
    MOCK.Advance(1)
    ns.Voice.Speak = originalSpeak
    BuddyDexCharDB.friends[id] = nil
    Quiet()
end)

step("the row menu sets a waypoint too", function()
    local _, sb = FriendRows()
    local row = sb.__pool.Button[1]
    MOCK.Fire(row, "OnClick", "RightButton")
    local item
    for _, child in ipairs(MOCK.lastContextMenu.children) do
        if child.kind == "button" and child.text == "Set waypoint" then item = child end
    end
    assert(item and item.enabled ~= false, "no waypoint entry in the row menu")
    MOCK.userWaypoint = nil
    item.a(item.data)
    assert(MOCK.userWaypoint, "the menu did not set a waypoint")
end)
step("child identities and models cannot become friends or companions", function()
    local beforeTotal = ns.Database.Count()
    for id, name in pairs(ns.NpcEligibility.children) do
        assert(not ns.Lore[id], "child lore remained: " .. id)
        assert(not ns.Friendship.IsSomeone(name, id), "child identity eligible")
        assert(not ns.Friendship.IsSomeone("Renamed NPC", id), "name bypassed child ID")
        local child = { npcID = id, name = name, type = "Humanoid", level = 1, sex = 2, reaction = 5,
            guid = "Creature-0-1-2-3-" .. id .. "-0000AB", tip = { "Level 1" } }
        MOCK.units.npc, MOCK.units.target = child, child
        assert(not ns.Friendship.EligibleNpcID("target"), "child got emote menu")
        assert(not ns.Friendship.Meet("target"), "child met through developer command")
        FireAll("GOSSIP_SHOW")
        DoEmote("HELLO", "target")
        assert(not BuddyDexCharDB.friends[id], "child earned friendship")
        BuddyDexCharDB.friends[id] = { name = name, display = 221, points = 10000 }
        assert(not ns.Friendship.Gain("target", "talk"), "legacy child gained points")
        assert(ns.Friendship.Add(id, 100) == 0, "developer points bypassed exclusion")
        assert(not ns.Database.GetEntry(id) and not ns.Database.GetRoster()[id], "child exposed in journal")
        ns.Companion.SetBuddy(id)
        assert(ns.char.companionNpc ~= id, "child companion selected")
        ns.Database.ExcludeChild(id)
    end
    assert(ns.Database.Count() == beforeTotal, "child affected friendship count")
    -- A newly discovered ID using a verified child display is also excluded.
    local id = 990081
    BuddyDexCharDB.friends[id] = { name = "Model Test", points = 10000 }
    assert(ns.Database.SetModelInfo(id, 257, {}), "child model not recognized")
    assert(not ns.Database.GetEntry(id) and BuddyDexCharDB.excludedChildren[id], "child model not quarantined")
    assert(not ns.Friendship.IsSomeone("Model Test", id), "learned child ID forgotten")
    local characterDB = ns.db
    ns.db = {}
    assert(ns.Friendship.IsSomeone("Model Test", id), "learned exclusions leaked across characters")
    ns.db = characterDB
    assert(ns.Friendship.IsSomeone("Billy", 990082), "a personal name became an age blacklist")
    assert(ns.Friendship.IsSomeone("Clara Charles", 5917, 4558), "adult Clara excluded")
    assert(ns.Friendship.IsSomeone("Auctioneer Lympkin", 9859), "adult gnome excluded")
    MOCK.units.target, MOCK.units.npc = LYMPKIN, LYMPKIN
end)
step("authored Goblin access still follows the live neutral and attackable state", function()
    local id = 11189
    local oldTarget, oldNpc = MOCK.units.target, MOCK.units.npc
    local unit = { guid = "Creature-0-1-2-3-11189-0000AB", npcID = id,
        name = "Qia", type = "Humanoid", typeID = 7, class = "normal", sex = 3,
        reaction = 4, attackable = true }
    ns.Database.Remove(id)
    MOCK.units.npc, MOCK.units.target = nil, unit
    DoEmote("HELLO")
    assert(not BuddyDexCharDB.friends[id], "an authored profile bypassed attackability")
    unit.attackable, unit.reaction = false, 3
    DoEmote("HELLO")
    assert(not BuddyDexCharDB.friends[id], "an authored profile bypassed hostile reaction")
    unit.reaction = 4
    DoEmote("HELLO")
    assert(Points(id) == 25, "a resolved non-attackable neutral merchant could not be met")
    ns.Database.Remove(id)
    MOCK.units.target, MOCK.units.npc = oldTarget, oldNpc
    assert(ns.Voice.NpcVoice(7053) == "goblin-male", "adult male Goblin route missing")
end)


"""

SCOUT = r"""
step("ADDON_LOADED", function()
    BuddyDexScoutDB = { version = 1, settings = { scout = true, announce = false }, roster = { [247] = { name = "Billy Maclure", display = 221 } } }
    FireAll("ADDON_LOADED", "BuddyDexScout")
    assert(not BuddyDexScoutDB.roster[247] and BuddyDexScoutDB.excludedChildren[247], "Scout child migration")
    assert(type(BuddyDexScoutDB) == "table" and type(BuddyDexScoutDB.roster) == "table", "no roster")
    assert(BuddyDexScoutDB.version == 2 and BuddyDexScoutDB.settings.announce, "old silent default was not migrated")
end)

step("takes over BuddyDex's old roster on login", function()
    BuddyDexDB = { roster = {
        [11996] = { name = "Ashley Bridenbecker", display = 257 },
        [8720] = { name = "Auctioneer Redmuse", title = "Auctioneer", zone = "Ironforge", seen = 4,
            display = 7989, moves = { 66, 67 } },
        [2784] = { name = "King Magni Bronzebeard", title = "Lord of Ironforge", zone = "Ironforge", class = "worldboss" },
    } }
    FireAll("PLAYER_LOGIN")
    local r = BuddyDexScoutDB.roster
    assert(not r[11996], "Scout reimported a child")
    assert(r[8720] and r[8720].display == 7989 and #r[8720].moves == 2, "Redmuse not taken over")
    assert(r[2784] and r[2784].title == "Lord of Ironforge", "Magni not taken over")
end)

step("scouts a nameplate NPC with faction and attackable", function()
    MOCK.units.nameplate1 = { guid = "Creature-0-1-2-3-3296-0000AB", npcID = 3296, name = "Orgrimmar Grunt",
        type = "Humanoid", class = "elite", level = 55, reaction = 2, faction = "Horde", attackable = true,
        tip = { "Level 55 (Elite)", "Orgrimmar" } }
    FireAll("NAME_PLATE_UNIT_ADDED", "nameplate1")
    local e = BuddyDexScoutDB.roster[3296]
    assert(e and e.faction == "Horde" and e.attackable == true, "faction or attackable missing")
end)

step("announces new discoveries once and honors the announcement switch", function()
    MOCK.units.target = { guid = "Creature-0-1-2-3-3626-0000AB", npcID = 3626, name = "Jenn Langston",
        type = "Humanoid", reaction = 5, faction = "Alliance", tip = { "Level 5" } }
    local before = #MOCK.printed
    FireAll("PLAYER_TARGET_CHANGED")
    assert(#MOCK.printed == before + 1 and Printed("Jenn Langston.*NPC #3626.*Added to Scout"), "new discovery was not announced")
    FireAll("PLAYER_TARGET_CHANGED")
    MOCK.Advance(61)
    FireAll("PLAYER_TARGET_CHANGED")
    assert(#MOCK.printed == before + 1, "repeat sighting was announced")
    SlashCmdList.BUDDYDEXSCOUT("announce off")
    before = #MOCK.printed
    MOCK.units.target = { guid = "Creature-0-1-2-3-2461-0000AB", npcID = 2461, name = "Bailey Stonemantle",
        type = "Humanoid", reaction = 5, faction = "Alliance", tip = { "Banker", "Level 45" } }
    FireAll("PLAYER_TARGET_CHANGED")
    assert(BuddyDexScoutDB.roster[2461] and #MOCK.printed == before, "disabled announcement printed or blocked scouting")
    SlashCmdList.BUDDYDEXSCOUT("announce on")
    assert(BuddyDexScoutDB.settings.announce, "announcement switch did not turn back on")
end)

step("Scout ignores child sightings", function()
    MOCK.units.nameplateChild = { npcID = 11996, name = "Ashley Bridenbecker", type = "Humanoid",
        guid = "Creature-0-1-2-3-11996-0000AB", level = 1, reaction = 5 }
    local count = #MOCK.printed
    FireAll("NAME_PLATE_UNIT_ADDED", "nameplateChild")
    assert(not BuddyDexScoutDB.roster[11996], "child added to Scout")
    assert(#MOCK.printed == count, "Scout announced an excluded child")
end)

step("the window and the sweep", function()
    SlashCmdList.BUDDYDEXSCOUT("")
    MOCK.Advance(1)
    assert(BuddyDexScoutFrame and BuddyDexScoutFrame:IsShown(), "window not shown")
    SlashCmdList.BUDDYDEXSCOUT("sweep")
    assert(MOCK.cvars.nameplateShowFriendlyNPCs == "1", "sweep did not start")
    FireAll("PLAYER_LOGOUT")
    assert(MOCK.cvars.nameplateShowFriendlyNPCs == "0", "logout did not restore the setting")
    SlashCmdList.BUDDYDEXSCOUT("off")
    SlashCmdList.BUDDYDEXSCOUT("on")
    MOCK.Advance(1)
end)
"""


def keys(t):
    return set(t.keys()) if t is not None else set()


def run(label, addon_dir, toc_name, addon_name, session):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(open(os.path.join(HERE, "blizzard_api.lua")).read())
    L.execute(open(os.path.join(HERE, "mock.lua")).read())
    L.execute(LOADER)
    L.execute(COMMON)
    G = L.globals()
    ns = L.table()
    G.MOCK.ns = ns

    load_errors = []
    files = toc_files(addon_dir, toc_name)
    for rel in files:
        try:
            G.MOCK.LoadAddonFile(open(os.path.join(addon_dir, rel)).read(), rel, addon_name, ns)
        except Exception as e:  # noqa: BLE001 - report every file
            load_errors.append(f"{rel}: {e}")
    L.execute(session)
    M = G.MOCK
    failures = [M.failures[i] for i in range(1, len(M.failures) + 1)]

    B = G.BLIZZARD
    templates, fonts, events, sounds = keys(B.templates), keys(B.fonts), keys(B.events), keys(B.soundkit)
    intrinsics = keys(B.intrinsics)
    known_globals = keys(B.apiGlobals) | keys(B.luaGlobals) | fonts | BUILTINS | EXPECTED_FOREIGN | VERIFIED_GLOBALS
    namespaces = {n: keys(B.apiNamespaces[n]) for n in B.apiNamespaces.keys()}
    used_templates = keys(M.templates)
    template_methods = set()
    for t in used_templates:
        if B.templateMethods[t] is not None:
            template_methods |= keys(B.templateMethods[t])
    methods_ok = keys(B.widgetMethods) | template_methods | keys(M.extraMethods)

    problems = []
    for t in sorted(used_templates):
        if t not in templates:
            problems.append(f"template not loaded for Camelot: {t}")
    for t in sorted(keys(M.frameTypes)):
        if t not in BASE_TYPES and t not in intrinsics:
            problems.append(f"unknown frame type: {t}")
    for f in sorted(keys(M.fonts)):
        if f not in fonts:
            problems.append(f"unknown font object: {f}")
    for e in sorted(keys(M.events)):
        if e not in events:
            problems.append(f"unknown event: {e}")
    for s in sorted(keys(M.sounds)):
        if s not in sounds:
            problems.append(f"unknown SOUNDKIT key: {s}")
    for name in sorted(keys(M.namespaced)):
        n, fn = name.split(".", 1)
        if n not in namespaces or fn not in namespaces[n]:
            problems.append(f"unknown API: {name}")

    warnings = []
    defined = keys(M.defined)
    for g in sorted(keys(M.globals)):
        if g in defined or g in known_globals or (g.startswith("C_") and g in namespaces):
            continue
        warnings.append(f"global not in the client lists: {g}")
    for m in sorted(keys(M.methods)):
        if m not in methods_ok:
            warnings.append(f"widget method not in the client lists: {m}")

    print(f"== {label}: {len(files)} files, {len(load_errors)} load errors, {len(failures)} failures")
    for e in load_errors:
        print("  LOAD ERROR", e)
    for f in failures:
        print("  FAIL", f)
    print(f"   audit: {len(used_templates)} templates, {len(keys(M.fonts))} fonts, {len(keys(M.events))} events, "
          f"{len(keys(M.sounds))} sound kits, {len(keys(M.namespaced))} C_ calls, {len(keys(M.methods))} widget methods")
    for p in problems:
        print("  PROBLEM", p)
    for w in warnings:
        print("  CHECK", w)
    return not load_errors and not failures and not problems


def main():
    ok = run("BuddyDex", ROOT, "BuddyDex.toc", "BuddyDex", BUDDYDEX)
    scout_dir = os.path.join(ROOT, "tools", "BuddyDexScout")
    ok = run("BuddyDex Scout", scout_dir, "BuddyDexScout.toc", "BuddyDexScout", SCOUT) and ok
    print("PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
