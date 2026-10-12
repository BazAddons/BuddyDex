-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/Toast.lua: what the player sees and hears when a friendship grows
-- (ns.Toast). A chat line like a reputation gain, a small toast with the
-- NPC's portrait and friendship bar that fades in and out near the top of
-- the screen, and a sound when a new tier is reached: a fanfare for a new
-- Buddy, a lighter rank-up for the others. Each is a setting.

local Toast = {}
ns.Toast = Toast

local HOLD = 3            -- seconds a toast stays fully visible
local FADE_IN, FADE_OUT = 0.25, 0.6
local CHAT_COLOR = "|cff8080ff"   -- the default chat color of reputation gains

local SOUND_BUDDY = "UI_GARRISON_TOAST_FOLLOWER_GAINED"
local SOUND_TIER = "UI_70_ARTIFACT_FORGE_TRAIT_RANKUP"

local toast

local function Settings()
    return ns.db and ns.db.settings or {}
end

local function Text(v)
    v = ns.Util.Plain(v)
    return type(v) == "string" and v or nil
end

local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit) end
end

-- "an Acquaintance", "a Buddy".
local function WithArticle(label)
    return (label:match("^[AEIOU]") and "an " or "a ") .. label
end

-- Chat --------------------------------------------------------------------------------

local function Announce(entry, amount, oldTier, newTier)
    local name = Text(entry.name) or "Someone"
    if amount > 0 then
        print(("%sFriendship with %s increased by %d.|r"):format(CHAT_COLOR, name, amount))
    elseif amount < 0 then
        print(("%sFriendship with %s decreased by %d.|r"):format(CHAT_COLOR, name, -amount))
    end
    if newTier ~= oldTier then
        local tier = ns.Friendship.TIERS[newTier]
        if newTier > oldTier then
            print(("%s%s now considers you %s.|r"):format(CHAT_COLOR, name, WithArticle(tier.label)))
        end
    end
end

-- The toast ------------------------------------------------------------------------------

local function Build()
    if toast then return toast end
    local art = ns.Art or {}
    local f = art.CreateCard and art.CreateCard(UIParent) or CreateFrame("Frame", nil, UIParent)
    f:SetSize(320, 70)
    f:SetPoint("TOP", UIParent, "TOP", 0, -150)
    f:SetFrameStrata("HIGH")
    f:Hide()

    f.Icon = f:CreateTexture(nil, "ARTWORK")
    f.Icon:SetSize(46, 46)
    f.Icon:SetPoint("LEFT", 12, 0)
    f.IconBorder = f:CreateTexture(nil, "OVERLAY")
    f.IconBorder:SetAllPoints(f.Icon)
    if art.ICON_BORDER then f.IconBorder:SetTexture(art.ICON_BORDER) end

    f.Name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    f.Name:SetPoint("TOPLEFT", f.Icon, "TOPRIGHT", 12, -1)
    f.Name:SetPoint("RIGHT", -12, 0)
    f.Name:SetJustifyH("LEFT")
    f.Name:SetWordWrap(false)

    f.Gain = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    f.Gain:SetPoint("TOPLEFT", f.Name, "BOTTOMLEFT", 0, -3)
    f.Gain:SetPoint("RIGHT", -12, 0)
    f.Gain:SetJustifyH("LEFT")

    if art.CreateFriendshipBar then
        f.Bar = art.CreateFriendshipBar(f, 160, 22, "GameFontHighlightSmall")
        f.Bar:SetPoint("BOTTOMLEFT", f.Icon, "BOTTOMRIGHT", 10, -4)
    end

    -- Fade in, hold, fade out, hide.
    local anim = f:CreateAnimationGroup()
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(FADE_IN)
    fadeIn:SetOrder(1)
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(FADE_OUT)
    fadeOut:SetStartDelay(HOLD)
    fadeOut:SetOrder(2)
    anim:SetScript("OnFinished", function() f:Hide() end)
    f.Anim = anim

    toast = f
    return f
end

local function ShowToast(npcID, entry, amount, oldTier, newTier)
    local f = Build()
    local art = ns.Art or {}
    if art.SetRowIcon then pcall(art.SetRowIcon, f.Icon, entry) end
    local r, g, b = 1, 0.82, 0
    if art.RarityColor then
        local ok, cr, cg, cb = pcall(art.RarityColor, entry.class)
        if ok and cr then r, g, b = cr, cg, cb end
    end
    f.IconBorder:SetVertexColor(r, g, b)
    f.Name:SetText(Text(entry.name) or "Someone")
    f.Name:SetTextColor(r, g, b)

    local tier = ns.Friendship.TIERS[newTier]
    if newTier > oldTier then
        f.Gain:SetText(("|cffffd100Now %s!|r"):format(WithArticle(tier.label)))
    elseif amount >= 0 then
        f.Gain:SetText(("|cff40ff40+%d Friendship|r"):format(amount))
    else
        f.Gain:SetText(("|cffff6060%d Friendship|r"):format(amount))
    end
    if f.Bar then
        local info = ns.Friendship.TierInfo(entry)
        f.Bar:SetFriendship(info, info.isMax and info.label
            or ("%s  %d / %d"):format(info.label, info.current, info.needed))
    end

    f.Anim:Stop()
    f:SetAlpha(1)
    f:Show()
    f.Anim:Play()
end

-- Listener ---------------------------------------------------------------------------------

local function OnGained(_, npcID, entry, amount, kind, oldTier, newTier)
    local settings = Settings()
    if settings.announce then Announce(entry, amount, oldTier, newTier) end
    if settings.toasts then ShowToast(npcID, entry, amount, oldTier, newTier) end
    if settings.sounds and newTier > oldTier then
        PlayKit(newTier == ns.Friendship.BUDDY_TIER and SOUND_BUDDY or SOUND_TIER)
    end
end

ns.Bus:RegisterCallback(ns.Event.FriendshipGained, function(...)
    local ok, err = pcall(OnGained, ...)
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
    end
end, Toast)
