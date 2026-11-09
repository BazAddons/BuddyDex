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
local WIDTH, HEIGHT = 320, 78
local INSET, PORTRAIT, GAP = 12, 52, 12
local CONTENT_LEFT = INSET + PORTRAIT + GAP
local CONTENT_WIDTH = WIDTH - CONTENT_LEFT - INSET
local CHAT_COLOR = "|cff8080ff"   -- the default chat color of reputation gains

local SOUND_BUDDY = "UI_GARRISON_TOAST_FOLLOWER_GAINED"
local SOUND_TIER = "UI_70_ARTIFACT_FORGE_TRAIT_RANKUP"

local toast

-- Fresh friends have no cached display until the journal loads their model.
-- Render the headshot directly from a matching, unrestricted live unit on
-- the first interaction, without loading any unit into a model frame.
local function Portrait(tex, npcID, entry)
    local art = ns.Art or {}
    -- Reset the previous toast's texture even if no portrait is available.
    if art.SetRowIcon then art.SetRowIcon(tex, entry) end
    local friendship = ns.Friendship
    if not SetPortraitTexture or not friendship or not friendship.EligibleNpcID then return end
    for _, unit in ipairs({ "npc", "target", "focus", "mouseover" }) do
        if friendship.EligibleNpcID(unit) == npcID then
            if pcall(SetPortraitTexture, tex, unit) then
                tex:SetTexCoord(0, 1, 0, 1)
                tex:SetVertexColor(1, 1, 1)
                tex:SetDesaturated(false)
                return
            end
        end
    end
end

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
    f:SetSize(WIDTH, HEIGHT)
    if f.SetBackdropColor then f:SetBackdropColor(0.025, 0.02, 0.015, 0.92) end
    f:SetPoint("TOP", UIParent, "TOP", 0, -150)
    f:SetFrameStrata("HIGH")
    f:Hide()

    f.Icon = f:CreateTexture(nil, "ARTWORK")
    f.Icon:SetSize(PORTRAIT, PORTRAIT)
    f.Icon:SetPoint("LEFT", INSET, 0)
    f.IconBorder = f:CreateTexture(nil, "OVERLAY")
    f.IconBorder:SetAllPoints(f.Icon)
    if art.ICON_BORDER then f.IconBorder:SetTexture(art.ICON_BORDER) end

    f.Name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    f.Name:SetPoint("TOPLEFT", f, "TOPLEFT", CONTENT_LEFT, -11)
    f.Name:SetPoint("TOPRIGHT", f, "TOPRIGHT", -INSET, -11)
    f.Name:SetHeight(18)
    f.Name:SetJustifyH("LEFT")
    f.Name:SetWordWrap(false)

    -- Reserve a stable right-hand column for the actual gain, including on
    -- rank-ups. Keep the rank outside the bar so it isn't printed twice.
    f.Delta = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    f.Delta:SetPoint("TOPRIGHT", f.Name, "BOTTOMRIGHT", 0, -2)
    f.Delta:SetSize(106, 14)
    f.Delta:SetJustifyH("RIGHT")
    f.Delta:SetWordWrap(false)

    f.Gain = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    f.Gain:SetPoint("TOPLEFT", f.Name, "BOTTOMLEFT", 0, -2)
    f.Gain:SetPoint("TOPRIGHT", f.Delta, "TOPLEFT", -8, 0)
    f.Gain:SetHeight(14)
    f.Gain:SetJustifyH("LEFT")
    f.Gain:SetWordWrap(false)
    f.Gain:SetTextColor(0.84, 0.82, 0.76)

    if art.CreateFriendshipBar then
        f.Bar = art.CreateFriendshipBar(f, CONTENT_WIDTH, 18, "GameFontHighlightSmall")
        f.Bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", CONTENT_LEFT, 11)
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
    Portrait(f.Icon, npcID, entry)
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
        f.Gain:SetText(("|cffffd100New %s!|r"):format(tier.label))
    elseif newTier < oldTier then
        f.Gain:SetText(("|cffff6060%s|r"):format(tier.label))
    else
        f.Gain:SetText(tier.label)
    end
    if amount >= 0 then
        f.Delta:SetText(("|cff40ff40+%d Friendship|r"):format(amount))
    else
        f.Delta:SetText(("|cffff6060%d Friendship|r"):format(amount))
    end
    if f.Bar then
        local info = ns.Friendship.TierInfo(entry)
        f.Bar:SetFriendship(info, info.isMax and "Max friendship"
            or ("%d / %d"):format(info.current, info.needed))
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
