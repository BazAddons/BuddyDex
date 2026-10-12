-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Scout/Scout.lua: the scout, which logs every NPC the player meets into the
-- roster the BuddyDex entries are written from. A developer tool:
-- players never need it. Owns ns.Scout: the unit events that feed it (mouseover,
-- target, nameplates), the checks that decide whether a unit may be read at
-- all, new roster entries and their sighting counts, and sessionNew, the
-- NPCs first logged this session. It reads unit and tooltip data only and
-- never touches a model: loading nameplate units into one crashed the
-- client in the probe ("Missing model in GeosRenderPrep").
--
-- Observe runs for every nameplate that appears, which in a city is all the
-- time. It asks the cheap questions first, and an NPC already counted in the
-- last minute costs a few plain lookups: no tooltip, no new table, no event.

local Util = ns.Util

local Scout = {}
ns.Scout = Scout

-- [npcID] = true for each NPC first logged this session. The Dex list draws
-- its "new" glow from it. Never saved.
Scout.sessionNew = {}

-- Session state --------------------------------------------------------------

-- Nameplates come and go as the camera turns, so one NPC standing nearby
-- would otherwise be counted dozens of times. A sighting counts only when
-- more than a minute has passed since the last one that counted, and
-- lastSeen[npcID] is the GetTime() of that one.
local SIGHTING_GAP = 60
local lastSeen = {}

-- Entries whose missing title was already looked for this session. Most
-- NPCs have no title at all, and without this every counted sighting of one
-- would read its tooltip again.
local titleChecked = {}

-- NPCs that turned out to belong to a player (a companion's tooltip names
-- its owner). Remembered for the session, so their nameplates, which keep
-- coming back, are dropped before any tooltip work.
local ignored = {}

-- Reading the client ---------------------------------------------------------
-- Every value comes through Util.Read or Util.Plain, so a secret arrives
-- here as nil and is never compared, concatenated, used as a key or saved.

local function ReadText(fn, ...)
    local value = Util.Read(fn, ...)
    if type(value) == "string" and value ~= "" then return value end
    return nil
end

local function ReadNumber(fn, ...)
    local value = Util.Read(fn, ...)
    if type(value) == "number" then return value end
    return nil
end

-- Players and what players control: pets, minions, guardians, vehicles. The
-- API docs mark none of these answers as ever secret, and a nil answer from
-- an API this client lacks counts as "no". Companions can get past all four;
-- AddEntry catches them by creature type and by the owner line in their
-- tooltip.
local function BelongsToPlayer(unit)
    return Util.Read(UnitIsPlayer, unit)
        or Util.Read(UnitPlayerControlled, unit)
        or Util.Read(UnitIsOtherPlayersPet, unit)
        or Util.Read(UnitIsBattlePetCompanion, unit)
end

-- Hard rule 3: scout only while the client lets addons see who a unit is.
-- An API that is missing or throws answers nil and does not block the
-- scout. That is safe, because every value read afterwards still passes
-- through Util.Plain, so a wrong "no" here can never put a secret in the
-- roster.
local function Restricted(unit)
    local actions = C_RestrictedActions
    local kinds = Enum and Enum.AddOnRestrictionType
    if actions and kinds then
        local isActive = actions.IsAddOnRestrictionActive
        if Util.Read(isActive, kinds.Combat) or Util.Read(isActive, kinds.Map) then
            return true
        end
    end
    local secrets = C_Secrets
    if secrets and Util.Read(secrets.ShouldUnitIdentityBeSecret, unit) then
        return true
    end
    return false
end

-- UnitCreatureID needs identity access and answers nothing without it. The
-- GUID is the fallback, and Util.NpcIDFromGUID only accepts Creature- and
-- Vehicle- GUIDs, so a player or a hunter pet never yields an ID.
local function NpcID(unit)
    local id = ReadNumber(UnitCreatureID, unit)
    if id and id > 0 then return id end
    return Util.NpcIDFromGUID((Util.Read(UnitGUID, unit)))
end

-- GetBestMapForUnit only answers for the player and party members. The NPC
-- is in sight, so the player's map is its map.
local function PlayerMapID()
    local map = C_Map
    local mapID = ReadNumber(map and map.GetBestMapForUnit, "player")
    if mapID and mapID > 0 then return mapID end
    return nil
end

-- UnitName answers UNKNOWNOBJECT ("Unknown") while the client is still
-- fetching a creature's data, typically for a nameplate that has just
-- appeared. Such a unit is left alone and not remembered, so its next
-- sighting tries again.
local function UsableName(name)
    if type(name) ~= "string" or name == "" then return nil end
    local unknown = UNKNOWNOBJECT
    if type(unknown) ~= "string" then unknown = "Unknown" end
    if name == unknown then return nil end
    return name
end

-- time() is WoW's os.time; the os fallback only serves the test harness.
local function Timestamp()
    local clock = time or (os and os.time)
    return clock and clock() or 0
end

-- Tooltip --------------------------------------------------------------------
-- After the name come a title if the NPC has one ("Priest Trainer", or
-- "<Priest Trainer>" on some units), then the level line, then the faction
-- ("Ironforge") and the rest. So the title is the line above the level line,
-- and an NPC whose level line comes first has none. The probe skipped the
-- level line instead of stopping at it and saved factions as titles. A unit
-- a player owns names its owner where the title goes ("Riley Blackwood's
-- Pet", "Ankle Chompa's Companion"); a companion's level line reads "Pet
-- Level 0 Critter". All of this is from the probe's saved tooltips.

local OWNER_MARKERS = { "'s Pet", "'s Minion", "'s Companion", "'s Guardian" }

-- Companions (the probe's "Rat Familiar") carry this creature type. It is
-- the same marker the probe import in Core/Database.lua skips.
local NON_COMBAT_PET = "Non-combat Pet"

-- The space keeps a title such as "Leveling Guide" from passing for the
-- level line.
local function IsLevelLine(text)
    return string.sub(text, 1, 6) == "Level " or string.sub(text, 1, 10) == "Pet Level "
end

local function NamesAnOwner(text)
    for i = 1, #OWNER_MARKERS do
        if string.find(text, OWNER_MARKERS[i], 1, true) then return true end
    end
    return false
end

-- Returns the title (or nil) and whether the tooltip names a player owner.
-- C_TooltipInfo.GetUnit may return nothing, and any single line may be
-- secret; a secret line is skipped like an empty one.
local function ReadTooltip(unit)
    local tooltipInfo = C_TooltipInfo
    local data = Util.Read(tooltipInfo and tooltipInfo.GetUnit, unit)
    if type(data) ~= "table" then return nil, false end
    local lines = Util.Plain(data.lines)
    if type(lines) ~= "table" then return nil, false end

    local candidate
    for i = 2, #lines do   -- line 1 is the name
        local line = Util.Plain(lines[i])
        local text = type(line) == "table" and Util.Trim(line.leftText) or nil
        if text and text ~= "" then
            if IsLevelLine(text) then
                if not candidate then return nil, false end
                candidate = Util.Trim(string.match(candidate, "^<(.*)>$") or candidate)
                if candidate == "" then candidate = nil end
                return candidate, false
            end
            if NamesAnOwner(text) then return nil, true end
            candidate = candidate or text
        end
    end
    -- No level line: nothing tells a title from a faction, so no title.
    return nil, false
end

-- New entries ----------------------------------------------------------------

local function AddEntry(db, unit, npcID, zone, now)
    local name = UsableName(Util.Read(UnitName, unit))
    if not name then return end

    local typeName, typeID = Util.Read(UnitCreatureType, unit)
    if type(typeName) ~= "string" or typeName == "" then typeName = nil end
    if type(typeID) ~= "number" then typeID = nil end
    if typeName == NON_COMBAT_PET then
        ignored[npcID] = true
        return
    end
    local title, owned = ReadTooltip(unit)
    if owned then
        ignored[npcID] = true
        return
    end

    local today = Util.Today()
    local entry = {
        name = name,
        title = title,
        type = typeName,
        typeID = typeID,
        family = ReadText(UnitCreatureFamily, unit),
        class = ReadText(UnitClassification, unit),
        level = ReadNumber(UnitLevel, unit),
        sex = ReadNumber(UnitSex, unit),
        reaction = ReadNumber(UnitReaction, unit, "player"),
        -- Buddies are friendly NPCs only. Reaction is relative to the
        -- scouting character's faction, so the NPC's own faction and whether
        -- it can be attacked are kept too: an Orgrimmar NPC is hostile to an
        -- Alliance scout but befriendable for a Horde player.
        faction = ReadText(UnitFactionGroup, unit),
        attackable = Util.Read(UnitCanAttack, "player", unit) and true or nil,
        zone = zone,
        subzone = ReadText(GetSubZoneText),
        mapID = PlayerMapID(),
        first = today,
        last = today,
        firstTime = Timestamp(),
        seen = 1,
    }
    db.roster[npcID] = entry
    lastSeen[npcID] = now
    titleChecked[npcID] = true   -- the tooltip was just read
    Scout.sessionNew[npcID] = true
    -- A fresh sighting undoes an earlier "Remove from BuddyDex".
    if type(ns.db.removed) == "table" then ns.db.removed[npcID] = nil end
    ns.Bus:TriggerEvent(ns.Event.NpcSeen, npcID, entry)
    if db.settings.announce then
        ns.Print("New BuddyDex entry: |cffffffff%s|r", name)
    end
end

-- Known NPCs -----------------------------------------------------------------

-- A counted sighting bumps seen and last, and fills in what an older entry
-- lacks: probe imports have no typeID or mapID and sometimes no title.
local function CountSighting(unit, npcID, entry, zone)
    entry.seen = (tonumber(entry.seen) or 0) + 1
    entry.last = Util.Today()

    if entry.type == nil or entry.typeID == nil then
        local typeName, typeID = Util.Read(UnitCreatureType, unit)
        if entry.type == nil and type(typeName) == "string" and typeName ~= "" then
            entry.type = typeName
        end
        if entry.typeID == nil and type(typeID) == "number" then
            entry.typeID = typeID
        end
    end
    -- The player's map only places the NPC while it stands in the zone it
    -- was logged in: one NPC ID can spawn in more than one zone.
    if entry.mapID == nil and entry.zone == zone then
        entry.mapID = PlayerMapID()
    end
    if entry.title == nil and not titleChecked[npcID] then
        titleChecked[npcID] = true
        local title, owned = ReadTooltip(unit)
        if title and not owned then entry.title = title end
    end
    ns.Bus:TriggerEvent(ns.Event.NpcUpdated, npcID, entry)
end

-- Observe --------------------------------------------------------------------

-- Logs the NPC behind a unit token, or counts another sighting of it.
function Scout.Observe(unit)
    unit = Util.Plain(unit)
    if type(unit) ~= "string" then return end
    local db = ns.db
    local settings = db and db.settings
    if not (settings and settings.scout) then return end
    if InCombatLockdown() then return end
    if not Util.Read(UnitExists, unit) or BelongsToPlayer(unit) then return end
    if Restricted(unit) then return end
    -- The zone reads empty during loading screens, and an entry needs one.
    local zone = ReadText(GetZoneText)
    if not zone then return end

    local npcID = NpcID(unit)
    if not npcID or ignored[npcID] then return end
    local roster = db.roster
    if type(roster) ~= "table" then return end

    local now = GetTime()
    local entry = roster[npcID]
    if entry == nil then
        AddEntry(db, unit, npcID, zone, now)
    elseif type(entry) == "table" then
        local last = lastSeen[npcID]
        if last and now - last <= SIGHTING_GAP then return end
        lastSeen[npcID] = now
        CountSighting(unit, npcID, entry, zone)
    end
end

-- Events ---------------------------------------------------------------------
-- UPDATE_MOUSEOVER_UNIT and PLAYER_TARGET_CHANGED carry no unit, so their
-- token is fixed. NAME_PLATE_UNIT_ADDED carries the nameplate's own token.

local UNIT_FOR_EVENT = {
    UPDATE_MOUSEOVER_UNIT = "mouseover",
    PLAYER_TARGET_CHANGED = "target",
    NAME_PLATE_UNIT_ADDED = false,
}

local errorReported = false

local function OnEvent(_, event, unitToken)
    local ok, err = pcall(Scout.Observe, UNIT_FOR_EVENT[event] or unitToken)
    if ok or errorReported then return end
    -- Once a session: a fault here would otherwise repeat for every
    -- nameplate in a city.
    errorReported = true
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(err) end
end

local eventFrame

local function Listen()
    if eventFrame then return end
    eventFrame = CreateFrame("Frame")
    for event in pairs(UNIT_FOR_EVENT) do
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
    eventFrame:SetScript("OnEvent", OnEvent)
end

-- The roster exists from VariablesReady on, so that is when listening starts.
ns.Bus:RegisterCallback(ns.Event.VariablesReady, Listen, Scout)
