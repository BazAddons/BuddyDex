-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- BuddyDex Scout core, copied from BuddyDex's Core/Namespace.lua so the
-- scout and sweep files move between the two unchanged: the shared namespace
-- every other file builds on. It owns
-- the addon's name and version, chat output (ns.Print), the private event
-- bus the modules talk through (ns.Bus, ns.Event), and ns.Util, the
-- secret-safe helpers for anything read from the client.

ns.NAME = ADDON_NAME

-- The TOC is the one place the version is written, so read it from there.
local function ReadVersion()
    local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata
    if type(getMetadata) ~= "function" then return "?" end
    local ok, version = pcall(getMetadata, ADDON_NAME, "Version")
    if ok and type(version) == "string" and version ~= "" then return version end
    return "?"
end

ns.VERSION = ReadVersion()

-- Util -----------------------------------------------------------------------

local Util = {}
ns.Util = Util

-- Midnight's secret values: in combat or under a restriction, unit and
-- tooltip APIs can hand back values that addon code may hold but must not
-- test, compare, concatenate, use as a table key or save. Plain turns them
-- into nil, which every caller already treats as "unknown". issecretvalue
-- is looked up on each call rather than captured at load so the test
-- harness can swap it, and it runs under pcall: if it ever refused a value,
-- the safe answer is still nil. The probe showed issecretvalue(nil) is fine.
local function Plain(v)
    local isSecret = issecretvalue
    if isSecret then
        local ok, secret = pcall(isSecret, v)
        if not ok or secret then return nil end
    end
    return v
end
Util.Plain = Plain

-- Calls a client API that may be missing or may throw, and passes up to two
-- results through Plain. Nil on any failure.
function Util.Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b)
end

-- Creature GUIDs read "Creature-0-<server>-<instance>-<zone>-<npcID>-<spawn>",
-- and vehicles share the layout. Players, pets and objects carry no NPC ID.
-- Plain string matching keeps this cheap for the scout and free of strsplit.
function Util.NpcIDFromGUID(guid)
    guid = Plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, id = string.match(guid, "^(%a+)%-[^%-]*%-[^%-]*%-[^%-]*%-[^%-]*%-(%d+)")
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    id = tonumber(id)
    if id and id > 0 then return id end
    return nil
end

-- Dates are saved as text so the saved file stays readable. date is WoW's
-- os.date; the os fallback only serves the test harness.
function Util.Today()
    local dateFn = date or (os and os.date)
    return dateFn("%Y-%m-%d")
end

-- Text for the helpers below: strings as they are, numbers as their text
-- (so a search for "45" can match a level), anything else or secret as nil.
local function Text(s)
    s = Plain(s)
    local kind = type(s)
    if kind == "string" then return s end
    if kind == "number" then return tostring(s) end
    return nil
end

function Util.Trim(s)
    s = Text(s)
    if s then return (string.match(s, "^%s*(.-)%s*$")) end
    return nil
end

function Util.Lower(s)
    s = Text(s)
    if s then return (string.lower(s)) end
    return nil
end

local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local copy = {}
    for k, x in pairs(v) do copy[k] = DeepCopy(x) end
    return copy
end

-- Fills every key dst is missing from src, recursing into sub-tables, and
-- copies default tables so saved data never shares a table with the
-- defaults. Values already present are kept, false included. A slot that
-- should hold a table but holds something else (a hand-edited or damaged
-- file) is replaced, because the modules index those tables without
-- checking. Returns dst, or a new table when dst was not one.
function Util.CopyDefaults(dst, src)
    if type(dst) ~= "table" then dst = {} end
    if type(src) ~= "table" then return dst end
    for k, v in pairs(src) do
        local current = dst[k]
        if type(v) == "table" then
            if type(current) == "table" then
                Util.CopyDefaults(current, v)
            else
                dst[k] = DeepCopy(v)
            end
        elseif current == nil then
            dst[k] = v
        end
    end
    return dst
end

-- Chat -----------------------------------------------------------------------

local PREFIX = "|cffd8b25c[BuddyDex Scout]|r "

-- string.format with a safety net, because a chat line is never worth an
-- error in the middle of an event handler. Secret arguments are dropped to
-- nil before formatting; a format that fails (nil for %s, say) is tried once
-- more with every argument as text, nil and secrets as "?", and if even that
-- fails the bare format is printed. print is looked up on each call so the
-- test harness can catch it.
function ns.Print(fmt, ...)
    local msg = type(fmt) == "string" and fmt or tostring(fmt)
    local count = select("#", ...)
    if count > 0 then
        local args = { ... }
        for i = 1, count do args[i] = Plain(args[i]) end
        local ok, text = pcall(string.format, msg, unpack(args, 1, count))
        if not ok then
            for i = 1, count do
                local v = args[i]
                args[i] = v == nil and "?" or tostring(v)
            end
            ok, text = pcall(string.format, msg, unpack(args, 1, count))
        end
        if ok then msg = text end
    end
    print(PREFIX .. msg)
end

-- Bus ------------------------------------------------------------------------
-- A private CallbackRegistry rather than the shared EventRegistry, so an
-- event name with a typo is an error instead of a message nobody hears.
--
--   Listen: ns.Bus:RegisterCallback(ns.Event.NpcSeen, function(owner, npcID, entry) end, ns.Dex)
--   Fire:   ns.Bus:TriggerEvent(ns.Event.NpcSeen, npcID, entry)
--
-- An owner holds one callback per event, and registering again replaces the
-- first one silently, so each module registers with its own module table as
-- owner. Owners are tables or strings: numbers are reserved by the registry.

ns.Bus = CreateFromMixins(CallbackRegistryMixin)
ns.Bus:OnLoad()   -- CreateFromMixins copies the methods but does not initialize them
ns.Bus:GenerateCallbackEvents({
    "VariablesReady",   -- ()               saved variables initialized (ADDON_LOADED)
    "Login",            -- ()               PLAYER_LOGIN, after the probe import ran
    "NpcSeen",          -- (npcID, entry)   a new roster entry
    "NpcUpdated",       -- (npcID, entry)   an existing entry changed
    "NpcRemoved",       -- (npcID)
    "SweepChanged",     -- (isActive)
    "SettingChanged",   -- (key, value)
})
ns.Event = ns.Bus.Event
