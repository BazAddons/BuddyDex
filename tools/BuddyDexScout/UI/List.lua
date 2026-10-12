-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/List.lua: the scout's window (/bdscout): every NPC logged, newest first
-- and colored by rarity, with counts, the sweep and a save button. A plain
-- developer view; the polished browsing happens in the BuddyDex.

local FRAME_NAME = "BuddyDexScoutFrame"
local REFRESH_DELAY = 0.5

local RARITY_COLORS = {
    trivial = { 0.6, 0.6, 0.6 }, minus = { 0.6, 0.6, 0.6 }, normal = { 1, 1, 1 },
    elite = { 1, 0.82, 0 }, rare = { 0.55, 0.75, 1 }, rareelite = { 0.75, 0.4, 1 }, worldboss = { 1, 0.5, 0 },
}

local frame
local pending = false

local function Text(v)
    v = ns.Util.Plain(v)
    if type(v) == "string" or type(v) == "number" then return tostring(v) end
    return nil
end

local function Line(e)
    local title = Text(e.title) and (" |cffaaaaaa<" .. Text(e.title) .. ">|r") or ""
    local place = Text(e.subzone) or Text(e.zone) or "?"
    local level = Text(e.level) and (" " .. Text(e.level)) or ""
    local faction = Text(e.faction) and (", " .. Text(e.faction)) or ""
    local hostile = e.attackable and " |cffff6060attackable|r" or ""
    return ("%s%s  |cff888888%s%s, %s%s|r%s"):format(Text(e.name) or "?", title,
        Text(e.type) or "?", level, place, faction, hostile)
end

local function Render()
    pending = false
    if not (frame and frame:IsShown() and ns.db) then return end
    local rows, zones = {}, {}
    for id, e in pairs(ns.db.roster) do
        if type(e) == "table" then
            rows[#rows + 1] = { id = id, e = e }
            zones[Text(e.zone) or "?"] = true
        end
    end
    table.sort(rows, function(a, b)
        local at, bt = tonumber(a.e.firstTime) or 0, tonumber(b.e.firstTime) or 0
        if at ~= bt then return at > bt end
        return (Text(a.e.name) or "") < (Text(b.e.name) or "")
    end)
    local zoneCount = 0
    for _ in pairs(zones) do zoneCount = zoneCount + 1 end
    local new = 0
    for _ in pairs(ns.Scout and ns.Scout.sessionNew or {}) do new = new + 1 end

    frame.header:SetText(("%d NPCs in %d zones    %d new this session    Scout %s"):format(
        #rows, zoneCount, new, ns.db.settings.scout and "on" or "|cffff6060off|r"))
    frame.sweep:SetText(ns.Sweep and ns.Sweep.IsActive() and "Stop sweep" or "Start sweep")
    frame.list:Clear()
    for _, row in ipairs(rows) do
        local c = RARITY_COLORS[row.e.class] or RARITY_COLORS.normal
        frame.list:AddMessage(Line(row.e), c[1], c[2], c[3])
    end
    frame.list:ScrollToTop()
end

local function Queue()
    if pending or not (frame and frame:IsShown()) then return end
    pending = true
    C_Timer.After(REFRESH_DELAY, Render)
end

local function Build()
    if frame then return frame end
    local f = CreateFrame("Frame", FRAME_NAME, UIParent, "PortraitFrameTemplate")
    f:Hide()
    f:SetSize(620, 480)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetTitle("BuddyDex Scout")
    f:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Spyglass_03")
    f.CloseButton:SetScript("OnClick", function() f:Hide() end)
    table.insert(UISpecialFrames, FRAME_NAME)

    local drag = CreateFrame("Button", nil, f, "PanelDragBarTemplate")
    drag:SetPoint("TOPLEFT", 58, 0)
    drag:SetPoint("TOPRIGHT", -26, 0)
    drag:SetHeight(22)

    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.header:SetPoint("TOPLEFT", 70, -34)
    f.header:SetPoint("TOPRIGHT", -16, -34)
    f.header:SetJustifyH("LEFT")

    local list = CreateFrame("ScrollingMessageFrame", nil, f)
    list:SetPoint("TOPLEFT", 16, -66)
    list:SetPoint("BOTTOMRIGHT", -16, 44)
    list:SetFontObject(GameFontHighlightSmall)
    list:SetJustifyH("LEFT")
    list:SetFading(false)
    list:SetMaxLines(5000)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    f.list = list

    local sweep = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sweep:SetSize(120, 22)
    sweep:SetPoint("BOTTOMLEFT", 14, 12)
    sweep:SetScript("OnClick", function() if ns.Sweep then ns.Sweep.Toggle() end end)
    f.sweep = sweep

    local save = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    save:SetSize(140, 22)
    save:SetPoint("BOTTOMRIGHT", -14, 12)
    save:SetText("Save (reload UI)")
    save:SetScript("OnClick", function() ReloadUI() end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", sweep, "RIGHT", 10, 0)
    hint:SetText("Mouse wheel scrolls. A sweep shows friendly nameplates so everyone nearby is logged.")

    f:SetScript("OnShow", Render)
    frame = f
    return f
end

for _, event in ipairs({ "NpcSeen", "NpcUpdated", "NpcRemoved", "SweepChanged", "SettingChanged" }) do
    ns.Bus:RegisterCallback(ns.Event[event], Queue, "BuddyDexScoutList." .. event)
end

SLASH_BUDDYDEXSCOUT1 = "/bdscout"
SlashCmdList.BUDDYDEXSCOUT = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "sweep" then
        if ns.Sweep then ns.Sweep.Toggle() end
    elseif msg == "on" or msg == "off" then
        ns.db.settings.scout = msg == "on"
        ns.Print("Scouting %s.", msg)
        ns.Bus:TriggerEvent(ns.Event.SettingChanged, "scout", ns.db.settings.scout)
    else
        local f = Build()
        f:SetShown(not f:IsShown())
    end
end
