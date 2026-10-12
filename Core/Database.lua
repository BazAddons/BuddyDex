-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Database.lua: BuddyDex's saved variables and the friends the
-- BuddyDex shows (ns.Database).
--
-- A friend is an NPC the player has started a friendship with: talked to,
-- traded with, trained with, done a quest for or greeted with an emote
-- (Core/Friendship.lua decides all that). NPCs only reach the Dex that way,
-- the way a faction reaches the reputation panel the first time you gain
-- reputation with it. The scout that used to log every NPC in sight is a
-- developer tool now, BuddyDex Scout in tools/.
--
-- An entry holds plain values only, with nil fields left out:
--   name, title, type, typeID, family, class, level (-1 for "??"), sex,
--   faction, zone, subzone, mapID     who and where, from the first meeting
--   first, last                       dates of the first and latest interaction
--   firstTime, lastTime               time() of the same, for sorting
--   points                            friendship (tiers: Core/Friendship.lua)
--   gains = { [kind] = date }         the daily cap: one gain per kind per day
--   favoriteFound                     the player has found their favorite emote
--   visits                            interactions that counted
--   display, moves                    learned when the Dex loads the model
-- Changes go out on the bus: NpcSeen for a new friend, NpcUpdated when one
-- changes, NpcRemoved when one is forgotten, FriendshipGained for a gain.

local Util = ns.Util

local Database = {}
ns.Database = Database

local DEFAULTS = {
    version = 2,
    friends = {},               -- [npcID] = entry
    settings = {
        -- Friendship
        announce = true, toasts = true, sounds = true,
        -- The buddy on screen (UI/Companion.lua, Core/Voice.lua, Core/Reactions.lua)
        companion = true,
        voiceMode = "recorded",     -- "recorded" (the BuddyDex Voice addon's clips) or "off"
        chattiness = 50,            -- how much it talks, 0 (only when spoken to) to 100
        echoChat = false,           -- also prints what the buddy says in chat
        combat = "stay",            -- "stay" (on screen, quiet, clicks pass through) or "hide"
        hideInInstances = false,    -- dungeons, raids, battlegrounds
        sleepWhenAway = true,
        locked = false,             -- can't be dragged
        clampToScreen = true,       -- can't be dragged off the screen
        clickThrough = false,       -- never takes the mouse
        scale = 1,                  -- 0.5 to 2
        alpha = 1,                  -- 0.2 to 1
        facing = "center",          -- "center", "left", "right", "front"
        hideWeapons = false,
    },
    dex = { point = nil, sort = "recent", buddiesOnly = false, zoneOnly = false,
            hiddenTypes = {}, hiddenRarity = {}, collapsed = {}, tab = 1 },
}

local CHAR_DEFAULTS = { version = 1 }   -- the Mini Me's own settings (milestone 2)

-- Friends are keyed by NPC ID as a plain number. Callers sometimes hold the
-- ID as text (a menu value, a GUID field), and a secret must never become a key.
local function Key(npcID)
    npcID = Util.Plain(npcID)
    if type(npcID) == "string" then npcID = tonumber(npcID) end
    if type(npcID) == "number" and npcID > 0 then return npcID end
    return nil
end
Database.Key = Key

local function Friends()
    return ns.db and ns.db.friends
end

-- The Dex's list. The name is from when the Dex listed every scouted NPC.
function Database.GetRoster()
    -- An empty table before VariablesReady, so a caller's pairs() never throws.
    return Friends() or {}
end
Database.GetFriends = Database.GetRoster

function Database.GetEntry(npcID)
    local id, friends = Key(npcID), Friends()
    if id and friends then return friends[id] end
    return nil
end

-- Friends, and how many of them are Buddies or closer.
function Database.Count()
    local total, buddies = 0, 0
    local friendship = ns.Friendship
    for _, entry in pairs(Friends() or {}) do
        if type(entry) == "table" then
            total = total + 1
            if friendship and friendship.IsBuddy and friendship.IsBuddy(entry) then buddies = buddies + 1 end
        end
    end
    return total, buddies
end

-- Forgets a friendship completely. Meeting the NPC again starts over.
function Database.Remove(npcID)
    local id, friends = Key(npcID), Friends()
    if not (id and friends and friends[id] ~= nil) then return false end
    friends[id] = nil
    ns.Bus:TriggerEvent(ns.Event.NpcRemoved, id)
    return true
end

local function SameList(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

-- Caches what the Dex learns when it loads an NPC's model: the creature
-- display ID (the list draws portraits from it) and the animation IDs the
-- model supports. An empty moves list is kept, meaning "none", which the
-- detail shows differently from "not probed yet" (nil). A display ID that is
-- not a positive plain number leaves the cached one alone. NpcUpdated fires
-- only when something actually changed: the list refresh it triggers
-- re-selects the NPC, which loads the model again, and an unconditional
-- event would loop. Returns true when the entry changed.
function Database.SetModelInfo(npcID, displayID, moves)
    local id = Key(npcID)
    local entry = Database.GetEntry(id)
    if type(entry) ~= "table" then return false end
    local changed = false

    displayID = Util.Plain(displayID)
    if type(displayID) == "number" and displayID > 0 and entry.display ~= displayID then
        entry.display = displayID
        changed = true
    end

    moves = Util.Plain(moves)
    if type(moves) == "table" then
        -- A copy of plain numbers only: the caller's table may be reused,
        -- and nothing else belongs in the saved file.
        local list = {}
        for _, anim in ipairs(moves) do
            anim = Util.Plain(anim)
            if type(anim) == "number" and anim >= 0 then list[#list + 1] = anim end
        end
        if not SameList(entry.moves, list) then
            entry.moves = list
            changed = true
        end
    end

    if changed then ns.Bus:TriggerEvent(ns.Event.NpcUpdated, id, entry) end
    return changed
end

-- Events ---------------------------------------------------------------------
-- An explicit ADDON_LOADED frame with a name check: EventUtil's helpers were
-- seen firing on this client before the saved variables existed.
--
-- Saved files from milestone 1 still hold the scouted roster in
-- BuddyDexDB.roster. It is left alone: BuddyDex Scout takes it over on
-- login when it is installed, and nothing here reads it.

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        -- Keep whatever was saved; only a missing or damaged value is replaced.
        if type(BuddyDexDB) ~= "table" then BuddyDexDB = {} end
        if type(BuddyDexCharDB) ~= "table" then BuddyDexCharDB = {} end
        -- The voice was once on or off, then text to speech or the game's
        -- voice; now it is the recorded voice, or off.
        local settings = BuddyDexDB.settings
        if type(settings) == "table" then
            if settings.voice == false then settings.voiceMode = "off" end
            if settings.voiceMode ~= "off" and settings.voiceMode ~= nil then settings.voiceMode = "recorded" end
            settings.voice, settings.voiceName, settings.voiceRate, settings.voiceVolume = nil, nil, nil, nil
            -- Comments, idle chatter and fight chatter were three options; now
            -- chattiness is one slider.
            if settings.chattiness == nil and (settings.chatty ~= nil or settings.idleChatter or settings.fightChatter) then
                local value = 50
                if settings.chatty == false then value = 15 end
                if settings.idleChatter == "often" or settings.fightChatter == "often" then value = 75 end
                if settings.chatty == false and settings.idleChatter == "off" then value = 0 end
                settings.chattiness = value
            end
            settings.chatty, settings.idleChatter, settings.fightChatter = nil, nil, nil
        end
        Util.CopyDefaults(BuddyDexDB, DEFAULTS)
        Util.CopyDefaults(BuddyDexCharDB, CHAR_DEFAULTS)
        ns.db = BuddyDexDB
        ns.char = BuddyDexCharDB
        ns.Bus:TriggerEvent(ns.Event.VariablesReady)
    elseif event == "PLAYER_LOGIN" then
        ns.Bus:TriggerEvent(ns.Event.Login)
    end
end)
