-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Waypoint.lua: points the player at a friend (ns.Waypoint). TomTom's
-- arrow when TomTom is loaded (TomTom:AddWaypoint, the call TomTom offers
-- other addons), otherwise the game's own map pin with on-screen tracking
-- (C_Map.SetUserWaypoint and C_SuperTrack). A friend's position is where
-- the player stood the last time they interacted (Core/Friendship.lua),
-- which is next to the NPC.

local Waypoint = {}
ns.Waypoint = Waypoint

local Util = ns.Util

local function Text(v)
    v = Util.Plain(v)
    return type(v) == "string" and v ~= "" and v or nil
end

function Waypoint.Has(entry)
    return type(entry) == "table" and type(entry.mapID) == "number"
        and type(entry.x) == "number" and type(entry.y) == "number"
end

-- The sound the map makes when a pin starts being tracked.
local function Confirm()
    local kit = SOUNDKIT and SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON
    if kit and PlaySound then pcall(PlaySound, kit) end
end

function Waypoint.HasTomTom()
    local tomtom = _G.TomTom
    return type(tomtom) == "table" and type(tomtom.AddWaypoint) == "function"
end

-- Sets a waypoint to a friend. Returns true when one was set.
function Waypoint.Set(npcID)
    local database = ns.Database
    local entry = database and database.GetEntry and database.GetEntry(npcID)
    local name = entry and Text(entry.name) or "them"
    if not Waypoint.Has(entry) then
        ns.Print("BuddyDex doesn't know where %s is yet. Talk to them once and it will remember.", name)
        return false
    end
    local title = Text(entry.title) and ("%s <%s>"):format(name, Text(entry.title)) or name

    if Waypoint.HasTomTom() then
        local tomtom = _G.TomTom
        local ok = pcall(tomtom.AddWaypoint, tomtom, entry.mapID, entry.x, entry.y, {
            title = title, from = "BuddyDex", persistent = false, crazy = true,
        })
        if ok then
            Confirm()
            ns.Print("TomTom is pointing you to %s.", name)
            return true
        end
    end

    local map = C_Map
    if map and map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        if map.CanSetUserWaypointOnMap and not Util.Read(map.CanSetUserWaypointOnMap, entry.mapID) then
            ns.Print("The map won't take a pin where %s is.", name)
            return false
        end
        local ok = pcall(function()
            map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(entry.mapID, entry.x, entry.y))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
        if ok then
            Confirm()
            ns.Print("Your map now has a pin on %s.", name)
            return true
        end
    end
    ns.Print("Couldn't set a waypoint to %s.", name)
    return false
end
