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
EXPECTED_FOREIGN = {"BuddyDexDB", "AzerBuddyProbeAccountDB", "BuddyDexVoicePack", "TomTom"}
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

-- Friendly NPCs to make friends with, and ones that must never count.
local LYMPKIN = { guid = "Creature-0-1-2-3-8720-0000AB", npcID = 8720, name = "Auctioneer Lympkin",
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
    local e = BuddyDexDB.friends[id]
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
    FireAll("ADDON_LOADED", "BuddyDex")
    assert(type(BuddyDexDB) == "table" and type(BuddyDexDB.friends) == "table", "no friends table")
    -- Befriended before the one-of-many rule: leaves at login.
    BuddyDexDB.friends[68] = { name = "Stormwind City Guard", points = 40, zone = "Stormwind City" }
    FireAll("PLAYER_LOGIN")
    assert(BuddyDexDB.friends[68] == nil, "a Stormwind City Guard stayed a friend")
    assert(Printed("Stormwind City Guard left the BuddyDex"), "no word about it leaving")
end)

step("trading starts a friendship", function()
    MOCK.today = "2026-10-10"
    MOCK.units.npc = LYMPKIN
    FireAll("MERCHANT_SHOW")
    local e = BuddyDexDB.friends[8720]
    assert(e, "no friend")
    assert(e.points == 60, "points " .. tostring(e.points))
    assert(e.title == "Auctioneer" and e.zone == "Ironforge", "snapshot")
    assert(Printed("Friendship with Auctioneer Lympkin increased by 60"), "no chat line")
end)

step("the daily cap, though a visit still updates where they are", function()
    MOCK.position = { 0.25, 0.75 }
    FireAll("MERCHANT_SHOW")
    assert(Points(8720) == 60, "trading twice in a day counted twice")
    assert(BuddyDexDB.friends[8720].x == 0.25, "a capped visit did not update where they are")
    MOCK.position = { 0.5641, 0.5262 }
end)

step("talking reaches Acquaintance", function()
    FireAll("GOSSIP_SHOW")
    assert(Points(8720) == 100, "points " .. tostring(Points(8720)))
    assert(ns.Friendship.TierIndex(BuddyDexDB.friends[8720]) == 2, "not an Acquaintance")
    assert(Printed("now considers you an Acquaintance"), "no tier line")
end)

step("the favorite emote, and a rude one", function()
    MOCK.units.npc = nil
    MOCK.units.target = LYMPKIN
    local fav = ns.Friendship.Favorite(BuddyDexDB.friends[8720])
    assert(fav.token == "THANK", "Lympkin's favorite is " .. fav.token)
    DoEmote("THANK")
    assert(Points(8720) == 250, "favorite did not count: " .. tostring(Points(8720)))
    assert(BuddyDexDB.friends[8720].favoriteFound, "favorite not marked found")
    DoEmote("RUDE")
    assert(Points(8720) == 225, "rude did not cost: " .. tostring(Points(8720)))
end)

step("emotes never start a friendship", function()
    MOCK.units.target = GUARD
    assert(ns.Friendship.Favorite(GUARD).token == "SALUTE", "guard favorite")
    DoEmote("WAVE")
    DoEmote("SALUTE")
    assert(BuddyDexDB.friends[5595] == nil, "an emote befriended a stranger")
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
        assert(BuddyDexDB.friends[id] == nil, "befriended " .. id)
    end
    -- The guard was targeted all along: an NPC that doesn't count never
    -- passes the credit to the target.
    assert(BuddyDexDB.friends[5595] == nil, "the target took the credit")
    -- A wanted poster (no "npc" unit) never counts for the target either.
    MOCK.units.npc = nil
    FireAll("QUEST_DETAIL")
    assert(BuddyDexDB.friends[5595] == nil, "an object's quest counted for the target")
end)

step("the next day counts again, and Buddy plays the fanfare", function()
    MOCK.today = "2026-10-11"
    MOCK.played = {}
    MOCK.units.target = nil
    MOCK.units.npc = LYMPKIN
    FireAll("QUEST_COMPLETE")
    assert(Points(8720) == 325, "points " .. tostring(Points(8720)))
    assert(ns.Friendship.IsBuddy(BuddyDexDB.friends[8720]), "not a Buddy")
    local fanfare = false
    for _, kit in ipairs(MOCK.played) do
        if kit == "UI_GARRISON_TOAST_FOLLOWER_GAINED" then fanfare = true end
    end
    assert(fanfare, "no Buddy fanfare")
    -- An Ironforge Guard is one of many: talking to one makes no friend.
    MOCK.units.npc = GUARD
    FireAll("GOSSIP_SHOW")
    assert(BuddyDexDB.friends[5595] == nil, "an Ironforge Guard became a friend")
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
        "Undercity Guardian", "Thunder Bluff Bluffwatcher", "Protector of the People", "Stormwind City Patroller" }) do
        assert(not is(name, 1), name .. " counted as someone")
    end
    for _, name in ipairs({ "Guard Thomas", "Mountaineer Kadrell", "Thor", "Auctioneer Lympkin", "Gina MacGregor" }) do
        assert(is(name, 1), name .. " counted as one of many")
    end
    ns.Lore[68] = { quote = "Move along." }
    assert(is("Stormwind City Guard", 68), "a lore entry didn't make someone of them")
    ns.Lore[68] = nil
    MOCK.units.target = GUARD
    SlashCmdList.BUDDYDEX("give 100")
    assert(BuddyDexDB.friends[5595] == nil and Printed("Every Ironforge Guard is the same NPC"), "/bd give befriended a guard")
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
    local e = BuddyDexDB.friends[npc]
    assert(e.display == 7028, "display not cached")
    assert(type(e.moves) == "table" and #e.moves == 2, "moves not cached")
    local greeted = false
    for _, f in ipairs(FindByKind("DressUpModel")) do
        if f.__npc == npc and f.__anim == 67 then greeted = true end
    end
    assert(greeted, "the NPC did not wave when picked")
end)

step("the portrait loader fills in every row, only while open", function()
    for id in pairs(BuddyDexDB.friends) do
        MOCK.model.displays[id] = MOCK.model.displays[id] or (50000 + id)
        MOCK.model.anims[id] = MOCK.model.anims[id] or { [0] = true, [66] = true }
    end
    MOCK.Advance(20)
    for id, e in pairs(BuddyDexDB.friends) do assert(e.display, "no portrait for " .. id) end
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
    BuddyDexDB.dex.buddiesOnly = true
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
    assert(BuddyDexDB.friends[id] == nil, "still a friend")
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
        local before = BuddyDexDB.settings[key] and true or false
        check:SetChecked(not before)
        MOCK.Fire(check, "OnClick")
        assert(BuddyDexDB.settings[key] == not before, key .. " not saved")
        check:SetChecked(before)
        MOCK.Fire(check, "OnClick")
        assert(BuddyDexDB.settings[key] == before, key .. " not put back")
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
    local e = BuddyDexDB.friends[523]
    assert(e and e.points == 50, "Thor not met: " .. tostring(e and e.points))
    assert(e.mapID == 1455 and e.x == 0.5641 and e.y == 0.5262, "position not saved")
    local fav = ns.Friendship.Favorite(e, 523)
    assert(fav.token == "WAVE" and fav.hint == ns.Lore[523].favorite.hint, "Thor's own favorite not used")
end)

step("Thor's entry unlocks by tier, and /bd lore previews it", function()
    local e = BuddyDexDB.friends[523]
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
    local other = ns.DexDetail.LoreParts(8720, { name = "Auctioneer Lympkin", points = 9999 })
    assert((other.note or ""):find("no entry on Auctioneer Lympkin") and #other.sections == 0, "an NPC without lore")
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
    for npcID, lore in pairs(ns.Lore) do
        local function Check(ok, what) assert(ok, ("NPC %d: %s"):format(npcID, what)) end
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
    local e = BuddyDexDB.friends[523]
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
    SetTier(BuddyDexDB.friends[523], 6)
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
    local thor = BuddyDexDB.friends[523]
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
    local e = BuddyDexDB.friends[6094]
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
    local settings = BuddyDexDB.settings
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
    assert(#MOCK.spoken == 0 and #MOCK.soundFiles == 0, "a sound without the voice addon")
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
    BuddyDexDB.settings.chattiness = 0
    MOCK.zone = "Duskwood"
    FireAll("ZONE_CHANGED_NEW_AREA")
    FireAll("PLAYER_LEVEL_UP", 16)
    assert(not Saying(), "talked at Quiet")
    MOCK.units.target = nil
    DoEmote("WAVE")
    assert(FromPile(Saying(), ns.Lines.waveBack), "didn't answer a wave at Quiet")
    BuddyDexDB.settings.chattiness = 100
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

step("the recorded voice: his clips, her clips, none without the addon or with it off", function()
    Quiet()
    local male, female = {}, {}
    for _, line in ipairs(ns.Lines.poke) do
        local text = type(line) == "table" and line[1] or line
        male[text], female[text] = "male\\poke.ogg", "female\\poke.ogg"
    end
    BuddyDexVoicePack = { version = 1, path = "Interface\\AddOns\\BuddyDex_Voice\\",
        voices = { male = male, female = female } }
    assert(ns.Voice.Mode() == "recorded", "no recorded voice with the addon installed")
    MOCK.soundFiles = {}
    ns.Companion.SayLine("poke")
    assert(MOCK.soundFiles[1] == "Interface\\AddOns\\BuddyDex_Voice\\male\\poke.ogg", "his clip did not play")
    Quiet()
    MOCK.units.player.sex = 3
    ns.Companion.SayLine("poke")
    assert(MOCK.soundFiles[2] == "Interface\\AddOns\\BuddyDex_Voice\\female\\poke.ogg", "her clip did not play")
    MOCK.units.player.sex = 2
    Quiet()
    FireAll("PLAYER_LEVEL_UP", 18)
    assert(Saying() and #MOCK.soundFiles == 2, "a line without a clip made a sound")
    Quiet()
    ns.Companion.SetSetting("voiceMode", "off")
    ns.Companion.SayLine("poke")
    assert(Saying() and #MOCK.soundFiles == 2, "spoke with the voice off")
    ns.Companion.SetSetting("voiceMode", "recorded")
    BuddyDexVoicePack = nil
    assert(ns.Voice.Mode() == "off", "a voice without the addon")
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
    DoEmote("WAVE")
    assert(FromPile(Saying(), ns.Lines.waveBack) and Actor().__anim == 67, "didn't wave back")
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
    local saved = chances.lowHealth
    chances.lowHealth = 1
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
    chances.lowHealth = saved
    assert(FromPile(said, ns.Lines.lowHealth), "no worried line at 12% health: " .. tostring(said))
    assert(again == nil or again == said, "worried twice in one fight")
    assert(BuddyDexDB.probe and BuddyDexDB.probe.healthInCombat == "readable", "didn't note whether health was readable")
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
    assert(BuddyDexDB.settings.voiceMode == "off", "the voice dropdown did not save")
    ns.Companion.SetSetting("voiceMode", "recorded")
    local _, out = Dropdown("Your Mini Me")
    assert(out, "no Who's out dropdown")
    for _, slider in ipairs(FindFrames("MinimalSliderWithSteppersTemplate")) do
        if slider.__min == 0.5 then
            slider:SetValue(1.5)
            assert(BuddyDexDB.settings.scale == 1.5, "size not saved")
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
            assert(BuddyDexDB.settings.alpha == 0.6, "see-through not saved")
            slider:SetValue(1)
        elseif slider.__min == 0 and slider.__max == 100 then
            slider:SetValue(25)
            assert(BuddyDexDB.settings.chattiness == 25, "chattiness not saved")
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
    assert(BuddyDexDB.settings.locked == true, "Lock in place didn't lock it")
    MOCK.Fire(BuddyDexCompanion, "OnClick", "RightButton")
    menu = MOCK.lastContextMenu
    local unlock
    for _, child in ipairs(menu.children) do
        if child.text == "Unlock" then unlock = child end
    end
    assert(unlock, "a locked buddy's menu has no Unlock")
    unlock.a(unlock.data)
    assert(BuddyDexDB.settings.locked == false, "Unlock didn't unlock it")
    MOCK.ClickEverything(menu)
    MOCK.Advance(1)
    assert(BuddyDexDB.settings.companion == false and not BuddyDexCompanion:IsShown(), "Hide did not hide it")
    SlashCmdList.BUDDYDEX("buddy")
    MOCK.Advance(2)
    assert(BuddyDexDB.settings.companion == true and BuddyDexCompanion:IsShown(), "/bd buddy did not bring it back")
end)

step("Thor comes along in the Mini Me's place, and goes home", function()
    -- The menu test clicked everything, Bring along included.
    ns.Companion.SetBuddy(nil)
    Quiet()
    local thor = BuddyDexDB.friends[523]
    SetTier(thor, 6)
    MOCK.model.anims[523] = { [0] = true, [60] = true, [67] = true, [68] = true }
    -- What the Dex learns when it loads him (tested above): his real display.
    MOCK.model.heights[3263] = 2
    ns.Database.SetModelInfo(523, 3263, { 60, 67, 68 })
    BuddyDexDB.settings.voiceMode = "recorded"
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
    assert(FromPile(said, own.greet) or FromPile(said, general.greet), "not a greeting: " .. tostring(said))
    -- In his own voice: the human male set his model uses (greeting 5974).
    assert(Played(5974), "Thor did not greet in his own voice")
    local kits = ns.Voice.NpcKits(3263)
    assert(kits and kits[1] == 5974 and kits[2] == 5975 and kits[3] == 5976, "Thor's voice set is wrong")
    assert(ns.Voice.NpcKits(326) == nil or ns.Voice.NpcKits(326) ~= kits, "a display matched another's prefix")
    MOCK.played = {}
    ns.Voice.Speak({ display = 3263, moment = "pokeMany" })
    assert(Played(5976), "poked too often, Thor was not annoyed")
    BuddyDexDB.settings.voiceMode = "off"
    MOCK.played = {}
    ns.Voice.Speak({ display = 3263, moment = "greet" })
    assert(#MOCK.played == 0, "Thor spoke with the voice off")
    BuddyDexDB.settings.voiceMode = "recorded"
    -- A gnome friend speaks in the Mini Me's recorded gnome voices instead,
    -- line by line. Thor, a human, has a recorded voice too, but this pack
    -- lacks it (an older pack), so he keeps the game's sounds.
    local savedPack = BuddyDexVoicePack
    BuddyDexVoicePack = { path = "Interface\\AddOns\\BuddyDex_Voice\\",
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
    BuddyDexVoicePack = savedPack

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
"""

SCOUT = r"""
step("ADDON_LOADED", function()
    FireAll("ADDON_LOADED", "BuddyDexScout")
    assert(type(BuddyDexScoutDB) == "table" and type(BuddyDexScoutDB.roster) == "table", "no roster")
end)

step("takes over BuddyDex's old roster on login", function()
    BuddyDexDB = { roster = {
        [8720] = { name = "Auctioneer Lympkin", title = "Auctioneer", zone = "Ironforge", seen = 4,
            display = 7028, moves = { 66, 67 } },
        [2784] = { name = "King Magni Bronzebeard", title = "Lord of Ironforge", zone = "Ironforge", class = "worldboss" },
    } }
    FireAll("PLAYER_LOGIN")
    local r = BuddyDexScoutDB.roster
    assert(r[8720] and r[8720].display == 7028 and #r[8720].moves == 2, "Lympkin not taken over")
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
