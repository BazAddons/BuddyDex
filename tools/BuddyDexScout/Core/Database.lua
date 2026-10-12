-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Database.lua: BuddyDex Scout's saved roster (BuddyDexScoutDB).
-- BuddyDex Scout is a developer tool. It logs every NPC you meet so the
-- BuddyDex can be given lore, favorite emotes and the like; players never
-- need it, which is why it left BuddyDex and lives in tools/.
--
-- The roster schema is the one the BuddyDex used while the scout
-- lived there (docs/DESIGN.md, "Roster entry"), plus faction and attackable.
-- On login it takes over whatever BuddyDex and the BuddyDex Probe logged
-- before the split, so nothing scouted so far is lost.

local Util = ns.Util

local DEFAULTS = {
    version = 1,
    roster = {},                    -- [npcID] = entry
    settings = { scout = true, announce = false },
    sweep = { restore = nil },      -- the friendly-nameplate setting while a sweep runs
    removed = {},
    imported = {},                  -- [source] = number of entries taken over
}

local FIELDS = {
    "name", "title", "type", "typeID", "family", "class", "level", "sex", "reaction",
    "faction", "attackable", "zone", "subzone", "mapID", "first", "last", "firstTime",
    "seen", "display", "moves",
}

-- Copies the plain fields of an entry logged elsewhere.
local function Copy(entry)
    local copy = {}
    for _, field in ipairs(FIELDS) do
        local v = Util.Plain(entry[field])
        if field == "moves" and type(v) == "table" then
            local moves = {}
            for i, id in ipairs(v) do moves[i] = tonumber(Util.Plain(id)) end
            v = moves
        end
        if type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "table" then
            copy[field] = v
        end
    end
    return copy
end

-- BuddyDex kept the roster in BuddyDexDB.roster before the split. A global
-- only while BuddyDex is enabled; read, never changed.
local function ImportBuddyDex()
    local source = type(BuddyDexDB) == "table" and BuddyDexDB.roster
    if type(source) ~= "table" then return 0 end
    local roster, count = ns.db.roster, 0
    for key, entry in pairs(source) do
        local id = tonumber(Util.Plain(key))
        if id and roster[id] == nil and type(entry) == "table" and entry.name then
            roster[id] = Copy(entry)
            count = count + 1
        elseif id and type(roster[id]) == "table" and type(entry) == "table" then
            -- Display IDs and moves BuddyDex's Dex learned since.
            roster[id].display = roster[id].display or tonumber(Util.Plain(entry.display))
            if roster[id].moves == nil and type(entry.moves) == "table" then
                roster[id].moves = Copy({ moves = entry.moves }).moves
            end
        end
    end
    if count > 0 then
        ns.db.imported.azerbuddy = (ns.db.imported.azerbuddy or 0) + count
        ns.Print("Took over %d NPCs BuddyDex had logged.", count)
    end
    return count
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        if type(BuddyDexScoutDB) ~= "table" then BuddyDexScoutDB = {} end
        Util.CopyDefaults(BuddyDexScoutDB, DEFAULTS)
        ns.db = BuddyDexScoutDB
        ns.Bus:TriggerEvent(ns.Event.VariablesReady)
    elseif event == "PLAYER_LOGIN" then
        local ok, err = pcall(ImportBuddyDex)
        if not ok then geterrorhandler()(err) end
        ns.Bus:TriggerEvent(ns.Event.Login)
    end
end)
