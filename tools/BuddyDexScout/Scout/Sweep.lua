-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Scout/Sweep.lua: the sweep. Owns ns.Sweep and ns.db.sweep. A sweep turns
-- on friendly NPC nameplates, so every NPC in range raises
-- NAME_PLATE_UNIT_ADDED and reaches the scout, and afterwards puts the
-- player's own setting back. While a sweep runs, ns.db.sweep.restore holds
-- the value to put back: a sweep is active exactly while it is set, and one
-- a session ended without undoing is undone at the next login.

local Util = ns.Util

local Sweep = {}
ns.Sweep = Sweep

-- The client's own constant spells it nameplateShowFriendlyNpcs
-- (Blizzard_NamePlates/Camelot/Blizzard_NamePlateConstants.lua:19). CVar
-- names are not case-sensitive (Blizzard's code reads ActionButtonUseKeyDown
-- and ActionButtonUseKeydown as one setting), so this is the same CVar under
-- the name the design and the saved data use.
local CVAR = "nameplateShowFriendlyNPCs"
local CVAR_KEY = string.lower(CVAR)   -- CVAR_UPDATE names may differ in case
local ON = "1"

-- "Always show nameplates". When it is off, Blizzard's nameplate key bindings
-- announce their "_AUTO" message instead (Blizzard_FrameXML/
-- Bindings_Camelot.xml:1115-1119): nameplates then come up in combat, which
-- is exactly when the scout rests. A sweep only reads it, to warn.
local SHOW_ALL_CVAR = "nameplateShowAll"

local STOPPED = "Sweep stopped: friendly NPC nameplates are back the way you had them."

-- CVars ----------------------------------------------------------------------
-- C_CVar first, the old globals (Blizzard_SharedXMLBase/CVarUtil.lua) when it
-- is missing, always under pcall: a setting the client refuses must not
-- throw out of a slash command or the logout handler.

local function ReadCVar(name)
    local api = C_CVar
    local value = Util.Read((api and api.GetCVar) or GetCVar, name)
    if type(value) == "number" then value = tostring(value) end
    if type(value) == "string" then return value end
    return nil
end

-- Set while this file writes the CVar, so the CVAR_UPDATE the write fires
-- (synchronously) is not taken for the player changing the setting.
local writing = false

-- True when the CVar now holds value. C_CVar.SetCVar answers false when it
-- refuses (an unknown or secure CVar), and reading the value back catches a
-- refusal that does not say so.
local function WriteCVar(name, value)
    local api = C_CVar
    local set = (api and api.SetCVar) or SetCVar
    if type(set) ~= "function" then return false end
    writing = true
    local ok, result = pcall(set, name, value)
    writing = false
    if not ok or Util.Plain(result) == false then return false end
    local now = ReadCVar(name)
    return now == nil or now == value
end

-- restore is saved as text ("0" or "1"), and the CVar only takes text. A
-- hand-edited or damaged file could hold anything else.
local function RestoreText(value)
    local kind = type(value)
    if kind == "string" then return value end
    if kind == "number" then return tostring(value) end
    if kind == "boolean" then return value and "1" or "0" end
    return "0"
end

-- State ----------------------------------------------------------------------

local function State()
    local db = ns.db
    if type(db) ~= "table" then return nil end
    if type(db.sweep) ~= "table" then db.sweep = {} end
    return db.sweep
end

function Sweep.IsActive()
    local db = ns.db
    local state = db and db.sweep
    return type(state) == "table" and state.restore ~= nil
end

local events = CreateFrame("Frame")

local function Changed(isActive)
    ns.Bus:TriggerEvent(ns.Event.SweepChanged, isActive)
end

-- The retail engine refuses addon changes to nameplate settings in combat,
-- which is why a sweep cannot start then. A stop asked for in combat waits
-- for PLAYER_REGEN_ENABLED instead of being dropped.
local stopAfterCombat = false

local function StopAfterCombat()
    if stopAfterCombat then return end
    stopAfterCombat = true
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function CancelStopAfterCombat()
    if not stopAfterCombat then return end
    stopAfterCombat = false
    events:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- CVAR_UPDATE fires for every setting change in the game, so it is only
-- listened to while a sweep runs.
local function WatchCVar(on)
    if on then
        events:RegisterEvent("CVAR_UPDATE")
    else
        events:UnregisterEvent("CVAR_UPDATE")
    end
end

-- Puts the saved value back and ends the sweep. If the client will not take
-- the value, the sweep ends all the same (a sweep nobody can stop is worse)
-- and the player is told to fix the setting by hand.
local function Finish(message)
    local state = State()
    if not state or state.restore == nil then return false end
    CancelStopAfterCombat()
    WatchCVar(false)
    local restored = WriteCVar(CVAR, RestoreText(state.restore))
    state.restore = nil
    if restored then
        if message then ns.Print(message) end
    else
        ns.Print("Could not put friendly NPC nameplates back. Set them in the game's nameplate options.")
    end
    Changed(false)
    return restored
end

-- API ------------------------------------------------------------------------
-- Start, Stop and Toggle return true when they did what was asked.

function Sweep.Start()
    local state = State()
    if not state then return false end
    if state.restore ~= nil then
        -- Already sweeping. A stop still waiting for combat to end is called
        -- off, since the sweep was asked for again.
        CancelStopAfterCombat()
        return true
    end
    if InCombatLockdown() then
        ns.Print("Leave combat first: nameplate settings cannot change in combat.")
        return false
    end
    -- Saved before the write, so IsActive() already holds while it happens.
    -- A value that cannot be read is put back as off.
    state.restore = ReadCVar(CVAR) or "0"
    if not WriteCVar(CVAR, ON) then
        state.restore = nil
        ns.Print("Could not turn on friendly NPC nameplates, so the sweep did not start.")
        return false
    end
    WatchCVar(true)
    ns.Print("Sweep started: friendly NPC nameplates are on until you stop it (/bd sweep).")
    local settings = ns.db.settings
    if type(settings) == "table" and not settings.scout then
        ns.Print("The scout is off, so nothing is logged. Type /bd scout to turn it on.")
    end
    if ReadCVar(SHOW_ALL_CVAR) == "0" then
        ns.Print("Always show nameplates is off, so nameplates may only appear in combat, when the scout rests.")
    end
    Changed(true)
    return true
end

function Sweep.Stop()
    if not Sweep.IsActive() then return false end
    if InCombatLockdown() then
        StopAfterCombat()
        ns.Print("The sweep stops when combat ends.")
        return false
    end
    return Finish(STOPPED)
end

function Sweep.Toggle()
    if Sweep.IsActive() then return Sweep.Stop() end
    return Sweep.Start()
end

-- Events ---------------------------------------------------------------------

-- The player changed the setting by hand during a sweep (the game's options
-- or a key binding). Turned off, the sweep is over and their choice stands,
-- rather than the value saved when the sweep began.
local function OnCVarUpdate(name, value)
    if writing or not Sweep.IsActive() then return end
    if Util.Lower(name) ~= CVAR_KEY then return end
    if Util.Plain(value) == ON then return end
    State().restore = nil
    CancelStopAfterCombat()
    WatchCVar(false)
    ns.Print("Sweep ended: friendly NPC nameplates were turned off.")
    Changed(false)
end

-- A sweep never outlives the session. In combat (a /reload mid-fight) the
-- setting cannot change, so restore stays saved and the next login puts it
-- back; the same happens when the client refuses the value now.
local function OnLogout()
    if not Sweep.IsActive() or InCombatLockdown() then return end
    local state = State()
    if WriteCVar(CVAR, RestoreText(state.restore)) then
        state.restore = nil
        WatchCVar(false)
        Changed(false)
    end
end

events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGOUT" then
        OnLogout()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CancelStopAfterCombat()
        if Sweep.IsActive() then Finish(STOPPED) end
    elseif event == "CVAR_UPDATE" then
        OnCVarUpdate(...)
    end
end)

-- restore is still saved at login only when the last session ended without
-- the logout handler putting the setting back: a reload in combat, a value
-- the client refused, or a crash after the saved variables were written.
-- Bus callbacks get their owner first; nothing else comes with Login.
ns.Bus:RegisterCallback(ns.Event.Login, function()
    if not Sweep.IsActive() then return end
    if InCombatLockdown() then
        WatchCVar(true)
        StopAfterCombat()
        return
    end
    Finish("A sweep was still running when you left. Friendly NPC nameplates are back the way you had them.")
end, Sweep)
