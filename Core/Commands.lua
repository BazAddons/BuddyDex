-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- BuddyDex core: the slash commands (/buddydex, /bd) and the
-- three global functions the TOC names for the minimap's addon compartment.
-- Both only route to the other modules' documented functions. This file
-- loads last, so every module table already exists when it runs.

local Util = ns.Util

local SETTINGS_TAB = 3   -- the Dex's tabs: BuddyDex, Buddy, Settings

-- Actions --------------------------------------------------------------------
-- The window lives in another file. If it failed to
-- load, say so in chat instead of throwing from a slash command.

local function Dex()
    local dex = ns.Dex
    if type(dex) == "table" then return dex end
    ns.Print("The BuddyDex window is not available.")
    return nil
end

local function ToggleDex()
    local dex = Dex()
    if dex and dex.Toggle then dex.Toggle() end
end

local function OpenSettings()
    local dex = Dex()
    if not (dex and dex.Open and dex.ShowTab) then return end
    dex.Open()
    dex.ShowTab(SETTINGS_TAB)
end

-- For writers: every BuddyDex entry shows in full, whatever the friendship,
-- until it is turned off or the UI reloads. Left out of the help on purpose
-- (docs/LORE.md).
local function ToggleLorePreview()
    ns.lorePreview = (not ns.lorePreview) or nil
    ns.Print(ns.lorePreview and "Lore preview on: every BuddyDex entry shows in full. /bd lore turns it off."
        or "Lore preview off.")
    local detail = ns.DexDetail
    if detail and detail.Redraw then detail.Redraw() end
end

-- For testing: "/bd give 200", "/bd give -50" or "/bd give buddy" (a tier
-- name) changes the friendship of your target, starting one if they qualify,
-- or else of the NPC the BuddyDex shows. Past the daily caps. Left out of
-- the help on purpose.
local GIVE_USAGE = "Usage: /bd give <amount or tier>, with an NPC targeted or picked in the BuddyDex. "
    .. "Tiers: stranger, acquaintance, buddy, friend, good friend, best friend."

local function GiveFriendship(rest)
    local friendship = ns.Friendship
    if not (friendship and friendship.Add) then return end
    rest = Util.Trim(rest or "") or ""
    local amount, tier = tonumber(rest), nil
    if not amount then
        for i, t in ipairs(friendship.TIERS) do
            if Util.Lower(t.label) == rest then tier = i end
        end
        if not tier then
            ns.Print(GIVE_USAGE)
            return
        end
    end
    local npcID, generic = friendship.Meet("target")
    if generic then
        ns.Print("Every %s is the same NPC to the game, so they can't be befriended.", generic)
        return
    end
    if not npcID then
        local detail = ns.DexDetail
        npcID = detail and detail.ShownNpcID and detail.ShownNpcID()
    end
    local entry = npcID and ns.Database and ns.Database.GetEntry(npcID)
    if not entry then
        ns.Print(GIVE_USAGE)
        return
    end
    if tier then amount = friendship.Threshold(entry, tier) - (tonumber(entry.points) or 0) end
    if friendship.Add(npcID, amount) == 0 then
        ns.Print("%s is already at %s.", entry.name or "They", friendship.TierInfo(entry).label)
    end
end

local HELP = {
    { "/bd", "Open or close the BuddyDex." },
    { "/bd settings", "Open the settings." },
    { "/bd buddy", "Show or hide your buddy." },
    { "/bd options", "Open your buddy's options." },
    { "/bd help", "Show this list." },
}

local function ShowHelp()
    ns.Print("Commands (version %s). /buddydex works like /bd.", ns.VERSION)
    for _, line in ipairs(HELP) do
        print(("    |cffffd100%s|r  %s"):format(line[1], line[2]))
    end
end

-- Slash commands -------------------------------------------------------------

local ACTIONS = {
    [""] = ToggleDex,
    settings = OpenSettings,
    help = ShowHelp,
    lore = ToggleLorePreview,
    give = GiveFriendship,
    -- For tuning the speech bubble's tail by eye; left out of the help.
    tail = function(rest)
        local value, companion = tonumber(rest), ns.Companion
        if value and companion and companion.SetTailOverlap then
            companion.SetTailOverlap(value)
        else
            ns.Print("Usage: /bd tail <number>, how far the bubble's tail reaches up (normally 6).")
        end
    end,
    buddy = function(rest)
        local companion = ns.Companion
        if not companion then return end
        if rest == "options" then
            companion.OpenOptions()
        elseif companion.Toggle then
            companion.Toggle()
        end
    end,
    options = function()
        local companion = ns.Companion
        if companion then companion.OpenOptions() end
    end,
}

-- The first word picks the command, in any case: "/bd Settings please" opens
-- settings. The rest goes to the command. Anything unknown shows the help.
local function RunCommand(msg)
    local word, rest = string.match(Util.Lower(msg) or "", "^%s*(%S*)%s*(.-)%s*$")
    local action = ACTIONS[word] or ShowHelp
    action(rest)
end

SLASH_BUDDYDEX1 = "/buddydex"
SLASH_BUDDYDEX2 = "/bd"
-- AzerBuddy's old command, for anyone used to it.
SLASH_BUDDYDEX3 = "/ab"
if type(SlashCmdList) == "table" then
    SlashCmdList.BUDDYDEX = RunCommand
end

-- Addon compartment ----------------------------------------------------------
-- Registered through the TOC (AddonCompartmentFunc and friends), never with
-- AddonCompartmentFrame:RegisterAddon as well: using both lists the addon
-- twice. Blizzard calls these after forceinsecure(), as
-- (addonName, buttonName) for a click and (addonName, menuButton) for the
-- tooltip pair.

function BuddyDex_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        OpenSettings()
    else
        ToggleDex()
    end
end

function BuddyDex_OnAddonCompartmentEnter(addonName, button)
    local tooltip = GameTooltip
    if not tooltip then return end
    if type(button) == "table" then
        tooltip:SetOwner(button, "ANCHOR_LEFT")
    else
        tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    end
    tooltip:SetText("BuddyDex", 1, 1, 1)
    tooltip:AddLine("Click: BuddyDex", 0.1, 1, 0.1)
    tooltip:AddLine("Right-click: settings", 0.1, 1, 0.1)
    local friends, buddies = 0, 0
    if ns.Database and ns.Database.Count then friends, buddies = ns.Database.Count() end
    tooltip:AddLine(("%d %s, %d %s"):format(friends, friends == 1 and "friend" or "friends",
        buddies, buddies == 1 and "buddy" or "buddies"), 1, 0.82, 0)
    tooltip:Show()
end

function BuddyDex_OnAddonCompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end
