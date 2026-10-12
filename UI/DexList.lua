-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/DexList.lua: the left half of the BuddyDex page (ns.DexList), laid out
-- like the reputation panel: friends grouped under collapsible zone
-- headers, each with a friendship bar. It owns the search box and filter
-- menu in the attic, the scrolling list with its selection, right-click
-- menu and empty state. Selecting a friend hands it to ns.DexDetail.
--
-- Everything here is always-loaded Blizzard code: WowScrollBoxList,
-- MinimalScrollBar, the linear view with an element factory (headers and
-- friends are different frames), a data provider and SelectionBehavior
-- (docs/research/scrollbox.md), SearchBoxTemplate and the new Menu system
-- through WowStyle1FilterDropdownTemplate (docs/research/searchfilter.md).

local List = {}
ns.DexList = List

local INSET_WIDTH = 330
local ROW_HEIGHT = 56
local HEADER_HEIGHT = 30
local ICON_SIZE = 40
local ICON_X = -45       -- the icon hangs off the row's left edge, as in the journals
local LEFT_GUTTER = 47   -- view padding, so the clipped ScrollBox still shows the icon
-- The attic row over the list: the search box from the rows' left edge
-- (clear of the portrait ring) to the filter, which ends at the list's
-- right edge, both centered on the line the Friends and Buddies cards sit
-- on (UI/DexFrame.lua: 28 down, 46 tall; the list starts 80 down).
local ATTIC_ROW_Y = 29                    -- above the list's top edge
local SEARCH_LEFT = 4 + LEFT_GUTTER + 5   -- the rows' left edge, plus the box's border art
local SEARCH_GAP = 12                     -- between the search box and the filter
local BAR_WIDTH = 238    -- a row's width less its margins; the bar fills from its width

-- Headers and friends are different frame types, so the list's frame pool
-- never hands a header's frame to a friend or the other way round.
local HEADER_TYPE, ROW_TYPE = "CheckButton", "Button"

local SORTS = {
    { key = "recent", label = "Last visited" },
    { key = "name", label = "Name" },
    { key = "friendship", label = "Friendship" },
    { key = "level", label = "Level" },
}

local SESSION_START = time()

local ui = {}             -- the widgets, once built
local selectedNpcID       -- the NPC the detail pane shows
local searchText = ""     -- lowercased, trimmed

-- Helpers ----------------------------------------------------------------------

local function Plain(v)
    local util = ns.Util
    if util and util.Plain then return util.Plain(v) end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

local function Text(v)
    v = Plain(v)
    if type(v) == "string" then return v end
    if type(v) == "number" then return tostring(v) end
    return nil
end

local function Lower(v)
    local s = Text(v)
    return s and s:lower() or ""
end

local function Number(v, default)
    return tonumber(Plain(v)) or default
end

local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit) end
end

local function DexSettings()
    local db = ns.db
    if type(db) ~= "table" then return nil end
    if type(db.dex) ~= "table" then db.dex = {} end
    local dex = db.dex
    if type(dex.hiddenTypes) ~= "table" then dex.hiddenTypes = {} end
    if type(dex.hiddenRarity) ~= "table" then dex.hiddenRarity = {} end
    if type(dex.collapsed) ~= "table" then dex.collapsed = {} end
    if type(dex.pinned) ~= "table" then dex.pinned = {} end
    return dex
end

-- Pinned friends have a group of their own at the top. Its key in
-- dex.collapsed can't be a zone's name.
local PINNED_KEY, PINNED_LABEL = "|pinned", "Pinned"


local function Friends()
    local database = ns.Database
    if database and database.GetRoster then
        local ok, friends = pcall(database.GetRoster)
        if ok and type(friends) == "table" then return friends end
    end
    return {}
end

local function TierInfo(entry)
    local friendship = ns.Friendship
    if friendship and friendship.TierInfo then
        local ok, info = pcall(friendship.TierInfo, entry)
        if ok and type(info) == "table" then return info end
    end
    return { index = 1, label = "Stranger", current = 0, needed = 1, colorType = "White" }
end

-- The rarity key a filter checkbox talks about ("minus" counts as trivial).
local function RarityKey(class)
    local art = ns.Art
    if art and art.Rarity then
        local ok, r = pcall(art.Rarity, class)
        if ok and type(r) == "table" and r.key then return r.key end
    end
    return "normal"
end

local function RarityLabel(key)
    local art = ns.Art
    if art and art.Rarity then
        local ok, r = pcall(art.Rarity, key)
        if ok and type(r) == "table" and r.label then return r.label end
    end
    return key
end

local function TypeOf(entry)
    return Text(entry.type) or "Not specified"
end

local function ZoneOf(entry)
    return Text(entry.zone) or "Unknown"
end

-- The group a friend is listed under: Pinned, or their zone.
local function GroupKey(npcID, entry, dex)
    if dex and dex.pinned[npcID] then return PINNED_KEY end
    return ZoneOf(entry)
end

local function Place(entry)
    local zone, subzone = Text(entry.zone), Text(entry.subzone)
    if zone and subzone and subzone ~= zone then return zone .. " - " .. subzone end
    return zone or subzone or ""
end

local function CurrentZone()
    local ok, zone = pcall(GetZoneText)
    zone = ok and Text(zone) or nil
    if zone == "" then return nil end
    return zone
end

local TIER_TEXT_COLORS = {
    White = { 0.85, 0.85, 0.85 }, Green = { 0.25, 1, 0.25 }, Blue = { 0.45, 0.7, 1 },
}

-- Filters ----------------------------------------------------------------------

local function IsDefaultFilters()
    local dex = DexSettings()
    if not dex then return true end
    if dex.buddiesOnly or dex.zoneOnly then return false end
    if (dex.sort or "recent") ~= "recent" then return false end
    for _, hidden in pairs(dex.hiddenTypes) do
        if hidden then return false end
    end
    for _, hidden in pairs(dex.hiddenRarity) do
        if hidden then return false end
    end
    return true
end

local function ResetFilters()
    local dex = DexSettings()
    if not dex then return end
    dex.buddiesOnly, dex.zoneOnly, dex.sort = false, false, "recent"
    dex.hiddenTypes, dex.hiddenRarity = {}, {}
end

local function Matches(entry, query)
    if query == "" then return true end
    for _, field in ipairs({ entry.name, entry.title, entry.zone, entry.subzone, entry.type }) do
        local s = Lower(field)
        if s ~= "" and s:find(query, 1, true) then return true end
    end
    return false
end

local function Passes(entry, dex, zone)
    if dex.buddiesOnly then
        local friendship = ns.Friendship
        if not (friendship and friendship.IsBuddy and friendship.IsBuddy(entry)) then return false end
    end
    if dex.zoneOnly and ZoneOf(entry) ~= zone then return false end
    if dex.hiddenTypes[TypeOf(entry)] then return false end
    if dex.hiddenRarity[RarityKey(entry.class)] then return false end
    return Matches(entry, searchText)
end

-- Sorting ---------------------------------------------------------------------

local function ByName(a, b)
    local an, bn = Lower(a.entry.name), Lower(b.entry.name)
    if an ~= bn then return an < bn end
    return a.npcID < b.npcID
end

local COMPARATORS = {
    recent = function(a, b)
        local at, bt = Number(a.entry.lastTime, 0), Number(b.entry.lastTime, 0)
        if at ~= bt then return at > bt end
        return ByName(a, b)
    end,
    name = ByName,
    friendship = function(a, b)
        local ap, bp = Number(a.entry.points, 0), Number(b.entry.points, 0)
        if ap ~= bp then return ap > bp end
        return ByName(a, b)
    end,
    -- Bosses ("??", saved as -1) come first.
    level = function(a, b)
        local al, bl = Number(a.entry.level, 0), Number(b.entry.level, 0)
        if al < 0 then al = 999 end
        if bl < 0 then bl = 999 end
        if al ~= bl then return al > bl end
        return ByName(a, b)
    end,
}

-- Rows --------------------------------------------------------------------------

local function SetAtlas(tex, atlas, ...)
    local art = ns.Art
    if art and art.SetAtlas and atlas then return art.SetAtlas(tex, atlas, ...) end
    tex:Hide()
    return false
end

local function ElementData(row)
    if not row.GetElementData then return nil end   -- released rows lose their accessors
    local ok, data = pcall(row.GetElementData, row)
    if ok and type(data) == "table" then return data end
    return nil
end

local function ShowRowTooltip(row)
    local data = ElementData(row)
    if not data or data.header then return end
    local e = data.entry
    local info = TierInfo(e)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, Text(e.name) or "Unknown NPC")
    if Text(e.title) then GameTooltip_AddNormalLine(GameTooltip, "<" .. Text(e.title) .. ">") end
    local place = Place(e)
    if place ~= "" then GameTooltip_AddHighlightLine(GameTooltip, place) end
    GameTooltip_AddHighlightLine(GameTooltip, info.isMax and info.label
        or ("%s: %d / %d"):format(info.label, info.current, info.needed))
    GameTooltip:Show()
end

local function OpenRowMenu(row, data)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    local npcID, name = data.npcID, Text(data.entry.name) or "Unknown NPC"
    MenuUtil.CreateContextMenu(row, function(_, root)
        root:CreateTitle(name)
        -- Pinned friends lead the list, above every zone.
        local dex = DexSettings()
        if dex then
            local pinned = dex.pinned[npcID] and true or false
            root:CreateButton(pinned and "Unpin" or "Pin to top", function()
                dex.pinned[npcID] = (not pinned) or nil
                List.Refresh()
            end)
        end
        -- A Buddy or better can come along in the Mini Me's place.
        local companion, friendship = ns.Companion, ns.Friendship
        if companion and friendship then
            local out = companion.Buddy() == npcID
            local button = root:CreateButton(out and "Send home" or "Bring along", function()
                companion.SetBuddy(not out and npcID or nil)
            end)
            if not friendship.IsBuddy(data.entry) then button:SetEnabled(false) end
        end
        -- Grayed out until BuddyDex knows where they are (Core/Waypoint.lua).
        local waypoint = ns.Waypoint
        if waypoint then
            local button = root:CreateButton("Set waypoint", function() waypoint.Set(npcID) end)
            if not waypoint.Has(data.entry) then button:SetEnabled(false) end
        end
        root:CreateButton("Forget this friendship", function()
            local database = ns.Database
            if dex then dex.pinned[npcID] = nil end
            if database and database.Remove then database.Remove(npcID) end
        end)
    end)
end

local function OnRowClick(row, button)
    local data = ElementData(row)
    if not data then return end
    if button == "RightButton" then
        OpenRowMenu(row, data)
    else
        PlayKit("IG_MAINMENU_OPTION_CHECKBOX_ON")
        ui.selection:SelectElementData(data)
    end
end

-- Built once per pooled frame; InitRow sets every visual every time.
local function BuildRow(row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetMotionScriptsWhileDisabled(true)

    row.Background = row:CreateTexture(nil, "BACKGROUND")
    row.Background:SetAllPoints()

    row.Icon = row:CreateTexture(nil, "BORDER")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT", ICON_X, 0)

    row.IconBorder = row:CreateTexture(nil, "ARTWORK", nil, -1)
    row.IconBorder:SetAllPoints(row.Icon)

    row.Tier = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.Tier:SetPoint("TOPRIGHT", -10, -9)
    row.Tier:SetJustifyH("RIGHT")

    row.New = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.New:SetPoint("RIGHT", row.Tier, "LEFT", -6, 0)
    row.New:SetText("New")
    row.New:SetTextColor(0.25, 1, 0.25)

    row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    row.Name:SetJustifyH("LEFT")
    row.Name:SetWordWrap(false)
    row.Name:SetPoint("TOPLEFT", 10, -7)
    row.Name:SetPoint("RIGHT", row.New, "LEFT", -4, 0)

    local art = ns.Art or {}
    if art.CreateFriendshipBar then
        row.Bar = art.CreateFriendshipBar(row, BAR_WIDTH, 22, "GameFontHighlightSmall")
        row.Bar:SetPoint("BOTTOMLEFT", 8, 4)
    end

    row.Selected = row:CreateTexture(nil, "OVERLAY")
    row.Selected:SetAllPoints()

    row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.Highlight:SetAllPoints()

    SetAtlas(row.Background, art.ROW_BG)
    SetAtlas(row.Selected, art.ROW_SELECTED)
    SetAtlas(row.Highlight, art.ROW_HIGHLIGHT)
    if art.ICON_BORDER then row.IconBorder:SetTexture(art.ICON_BORDER) end

    row:SetScript("OnClick", OnRowClick)
    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.isBuilt = true
end

local function InitRow(row, data)
    if not row.isBuilt then BuildRow(row) end
    local e = data.entry
    local art = ns.Art or {}

    if art.SetRowIcon then
        pcall(art.SetRowIcon, row.Icon, e)
    else
        row.Icon:SetTexture(art.UNKNOWN_ICON)
    end
    -- No display ID yet means no portrait: the detail pane's loader fetches
    -- one in the background, and the row redraws when it arrives.
    if not e.display then
        local detail = ns.DexDetail
        if detail and detail.WantPortrait then detail.WantPortrait(data.npcID) end
    end

    local r, g, b = 1, 1, 1
    if art.RarityColor then
        local ok, cr, cg, cb = pcall(art.RarityColor, e.class)
        if ok and cr then r, g, b = cr, cg, cb end
    end
    row.IconBorder:SetVertexColor(r, g, b)
    row.Name:SetText(Text(e.name) or "Unknown NPC")
    row.Name:SetTextColor(r, g, b)

    local info = TierInfo(e)
    row.Tier:SetText(info.label)
    local c = TIER_TEXT_COLORS[info.colorType] or TIER_TEXT_COLORS.White
    row.Tier:SetTextColor(c[1], c[2], c[3])
    if row.Bar then row.Bar:SetFriendship(info) end

    row.New:SetShown(Number(e.firstTime, 0) >= SESSION_START)
    row.Selected:SetShown(ui.selection and ui.selection:IsElementDataSelected(data) or false)
end

-- Zone headers --------------------------------------------------------------------

local function OnHeaderClick(header)
    local data = ElementData(header)
    if not (data and data.header) then return end
    local dex = DexSettings()
    if not dex then return end
    local key = data.key or data.zone
    dex.collapsed[key] = not dex.collapsed[key] or nil
    PlayKit(dex.collapsed[key] and "IG_MAINMENU_OPTION_CHECKBOX_OFF" or "IG_MAINMENU_OPTION_CHECKBOX_ON")
    List.Refresh()
end

local function BuildHeader(header)
    header:RegisterForClicks("LeftButtonUp")
    local art = ns.Art or {}

    header.Stripe = header:CreateTexture(nil, "BACKGROUND")
    header.Stripe:SetPoint("TOPLEFT", -LEFT_GUTTER + 4, 0)
    header.Stripe:SetPoint("BOTTOMRIGHT", 0, 0)
    if not SetAtlas(header.Stripe, art.ROW_STRIPE) then
        SetAtlas(header.Stripe, art.ROW_STRIPE_FALLBACK)
    end

    header.Toggle = header:CreateTexture(nil, "ARTWORK")
    header.Toggle:SetSize(14, 14)
    header.Toggle:SetPoint("LEFT", -LEFT_GUTTER + 12, 0)

    header.Zone = header:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    header.Zone:SetPoint("LEFT", header.Toggle, "RIGHT", 8, 0)
    header.Zone:SetJustifyH("LEFT")

    header.Count = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    header.Count:SetPoint("RIGHT", -10, 0)
    header.Count:SetJustifyH("RIGHT")

    header.Highlight = header:CreateTexture(nil, "HIGHLIGHT")
    header.Highlight:SetAllPoints(header.Stripe)
    header.Highlight:SetColorTexture(1, 0.82, 0, 0.08)

    header:SetScript("OnClick", OnHeaderClick)
    header.isBuilt = true
end

local function InitHeader(header, data)
    if not header.isBuilt then BuildHeader(header) end
    header.Zone:SetText(data.zone)
    header.Toggle:SetTexture(data.collapsed and "Interface\\Buttons\\UI-PlusButton-Up"
        or "Interface\\Buttons\\UI-MinusButton-Up")
    header.Count:SetText(data.buddies > 0 and ("%d friends, %d buddies"):format(data.count, data.buddies)
        or (data.count == 1 and "1 friend" or ("%d friends"):format(data.count)))
end

local function ElementFactory(factory, data)
    if data.header then
        factory(HEADER_TYPE, InitHeader)
    else
        factory(ROW_TYPE, InitRow)
    end
end

local function ElementExtent(_, data)
    return data.header and HEADER_HEIGHT or ROW_HEIGHT
end

-- Selection ------------------------------------------------------------------

local function ShowDetail(npcID)
    local detail = ns.DexDetail
    if detail and detail.Show then detail.Show(npcID) end
end

-- Fires for the old row (selected = false) and the new one (true). A
-- refresh re-selects the same NPC after every friendship change; that one
-- only updates the detail pane's text, so the model is not reloaded.
local function OnSelectionChanged(_, data, selected)
    if data.header then return end
    local row = ui.scrollBox:FindFrame(data)
    if row and row.Selected then row.Selected:SetShown(selected) end
    if not selected then return end
    if data.npcID == selectedNpcID then return end
    selectedNpcID = data.npcID
    ShowDetail(data.npcID)
end

local function PredicateFor(npcID)
    return function(data) return not data.header and data.npcID == npcID end
end

local function IsFriendRow(data)
    return not data.header
end

-- Refresh ----------------------------------------------------------------------

local function UpdateEmptyText(shown, noFriends)
    ui.empty:SetShown(shown)
    if shown then
        ui.empty:SetText(noFriends
            and "No friends yet.\n\nTalk to NPCs, trade, train or travel with them, or do their quests, and they will start to remember you. Once you've met, a friendly emote helps too."
            or "No friends match these filters.")
    end
end

-- Builds the element list: a header per group followed by its friends,
-- unless the group is collapsed. Pinned friends come first, in a group of
-- their own; then a group per zone, the current zone first, then A to Z.
local function BuildElements(dex)
    local zoneNow = CurrentZone()
    local onlyZone = dex.zoneOnly and zoneNow or nil
    local groups, order, total = {}, {}, 0
    local friendship = ns.Friendship
    for npcID, entry in pairs(Friends()) do
        if type(npcID) == "number" and type(entry) == "table" then
            total = total + 1
            if Passes(entry, dex, onlyZone) then
                local zone = GroupKey(npcID, entry, dex)
                local group = groups[zone]
                if not group then
                    group = { zone = zone, rows = {}, buddies = 0 }
                    groups[zone] = group
                    order[#order + 1] = zone
                end
                group.rows[#group.rows + 1] = { npcID = npcID, entry = entry }
                if friendship and friendship.IsBuddy and friendship.IsBuddy(entry) then
                    group.buddies = group.buddies + 1
                end
            end
        end
    end
    table.sort(order, function(a, b)
        if a == PINNED_KEY or b == PINNED_KEY then return a == PINNED_KEY end
        if a == zoneNow then return true end
        if b == zoneNow then return false end
        return a < b
    end)

    local elements, friendRows = {}, 0
    local compare = COMPARATORS[dex.sort] or COMPARATORS.recent
    for _, zone in ipairs(order) do
        local group = groups[zone]
        local collapsed = dex.collapsed[zone] and true or false
        elements[#elements + 1] = { header = true, key = zone, zone = zone == PINNED_KEY and PINNED_LABEL or zone,
            count = #group.rows, buddies = group.buddies, collapsed = collapsed }
        if not collapsed then
            table.sort(group.rows, compare)
            for _, row in ipairs(group.rows) do
                elements[#elements + 1] = row
                friendRows = friendRows + 1
            end
        end
    end
    return elements, friendRows, total
end

function List.Refresh()
    if not ui.scrollBox then return end
    local dex = DexSettings()
    if not dex then return end

    local elements, friendRows, total = BuildElements(dex)
    ui.scrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
    UpdateEmptyText(#elements == 0, total == 0)

    -- Swapping the provider cleared the selection; put it back by NPC ID.
    local restored = selectedNpcID and ui.selection:SelectElementDataByPredicate(PredicateFor(selectedNpcID))
    if restored then
        local detail = ns.DexDetail
        if detail and detail.UpdateInfo then detail.UpdateInfo(selectedNpcID) end
    elseif friendRows > 0 then
        selectedNpcID = nil
        ui.selection:SelectFirstElementData(IsFriendRow)
    elseif selectedNpcID ~= nil or not ui.shownEmpty then
        selectedNpcID = nil
        ui.shownEmpty = true
        ShowDetail(nil)
    end
    if friendRows > 0 then ui.shownEmpty = false end
end

function List.GetSelected()
    return selectedNpcID
end

-- Selects a friend and scrolls to it. A search, filter or collapsed zone
-- hiding it is cleared first, so a link to a friend always lands on it.
function List.SelectNpc(npcID)
    npcID = tonumber(Plain(npcID))
    if not (npcID and ui.scrollBox) then return false end
    local entry = Friends()[npcID]
    if not entry then return false end
    local pred = PredicateFor(npcID)
    if not ui.scrollBox:FindElementDataByPredicate(pred) then
        ResetFilters()
        local dex = DexSettings()
        if dex then dex.collapsed[GroupKey(npcID, entry, dex)] = nil end
        if ui.search then ui.search:SetText("") end
        searchText = ""
        if ui.filter and ui.filter.ValidateResetState then ui.filter:ValidateResetState() end
        List.Refresh()
    end
    ui.selection:SelectElementDataByPredicate(pred)
    ui.scrollBox:ScrollToElementDataByPredicate(pred, ScrollBoxConstants.AlignNearest)
    return true
end

-- Filter menu ------------------------------------------------------------------

-- Types the menu offers: the usual ones, then any other type among friends.
local function MenuTypes()
    local types, seen = {}, {}
    local art = ns.Art
    for _, t in ipairs(art and art.TYPES or {}) do
        types[#types + 1] = t
        seen[t] = true
    end
    local extra = {}
    for _, entry in pairs(Friends()) do
        local t = type(entry) == "table" and TypeOf(entry)
        if t and not seen[t] then
            seen[t] = true
            extra[#extra + 1] = t
        end
    end
    table.sort(extra)
    for _, t in ipairs(extra) do types[#types + 1] = t end
    return types
end

local function SetAllTypes(shown)
    local dex = DexSettings()
    if not dex then return end
    for _, t in ipairs(MenuTypes()) do dex.hiddenTypes[t] = not shown or nil end
    return MenuResponse.Refresh
end

-- The menu is rebuilt every time it opens, so every getter reads live state.
local function SetupFilterMenu(_, root)
    root:SetTag("MENU_BUDDYDEX_DEX_FILTER")
    local function Dex() return DexSettings() or {} end

    root:CreateCheckbox("Buddies only",
        function() return Dex().buddiesOnly and true or false end,
        function() local d = Dex(); d.buddiesOnly = not d.buddiesOnly end)
    root:CreateCheckbox("Current zone only",
        function() return Dex().zoneOnly and true or false end,
        function() local d = Dex(); d.zoneOnly = not d.zoneOnly end)

    root:CreateDivider()
    root:CreateTitle("Creature type")
    for _, t in ipairs(MenuTypes()) do
        root:CreateCheckbox(t,
            function(key) return not (Dex().hiddenTypes or {})[key] end,
            function(key) local h = Dex().hiddenTypes; h[key] = not h[key] or nil end,
            t)
    end
    local bulk = root:CreateButton("Select")
    bulk:CreateButton("Check all", SetAllTypes, true)
    bulk:CreateButton("Uncheck all", SetAllTypes, false)

    root:CreateDivider()
    root:CreateTitle("Rarity")
    local art = ns.Art
    for _, key in ipairs(art and art.RARITY_ORDER or {}) do
        root:CreateCheckbox(RarityLabel(key),
            function(k) return not (Dex().hiddenRarity or {})[k] end,
            function(k) local h = Dex().hiddenRarity; h[k] = not h[k] or nil end,
            key)
    end

    root:CreateDivider()
    local sort = root:CreateButton("Sort by")
    for _, s in ipairs(SORTS) do
        sort:CreateRadio(s.label,
            function(key) return (Dex().sort or "recent") == key end,
            function(key)
                Dex().sort = key
                return MenuResponse.Refresh
            end,
            s.key)
    end

    root:CreateDivider()
    root:CreateButton("Reset filters", function()
        ResetFilters()
        return MenuResponse.Refresh
    end)
end

-- Building ---------------------------------------------------------------------

local function BuildSearch(page, inset)
    local search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
    -- Its right end is pinned to the filter once that exists (List.Build).
    search:SetHeight(22)
    search:SetPoint("LEFT", inset, "TOPLEFT", SEARCH_LEFT, ATTIC_ROW_Y)
    search:SetMaxLetters(40)
    if search.Instructions then search.Instructions:SetText("Search friends") end
    -- HookScript keeps the template's own handler, which runs the clear
    -- button and the gray instructions. The clear button changes the text
    -- from code, so this must not wait for userInput.
    search:HookScript("OnTextChanged", function(self)
        local text = Text(self:GetText()) or ""
        text = text:match("^%s*(.-)%s*$"):lower()
        if text == searchText then return end
        searchText = text
        List.Refresh()
    end)
    search:HookScript("OnHide", function(self) self:SetText("") end)
    return search
end

local function BuildFilter(page, inset)
    local filter = CreateFrame("DropdownButton", nil, page, "WowStyle1FilterDropdownTemplate")
    -- The template grows to its text after every pick unless told not to.
    filter.resizeToText = false
    filter:SetWidth(90)
    filter:SetPoint("RIGHT", inset, "TOPRIGHT", 0, ATTIC_ROW_Y)
    filter:SetIsDefaultCallback(IsDefaultFilters)
    -- The red X resets without going through the menu, so it refreshes here.
    filter:SetDefaultCallback(function()
        ResetFilters()
        List.Refresh()
    end)
    filter:SetUpdateCallback(List.Refresh)
    filter:SetupMenu(SetupFilterMenu)
    return filter
end

function List.Build(page)
    if not page or page.LeftInset then return end
    local art = ns.Art
    local inset = art and art.CreateCard and art.CreateCard(page)
        or CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    inset:SetWidth(INSET_WIDTH)
    inset:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -80)
    inset:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 16, 18)
    page.LeftInset = inset

    ui.search = BuildSearch(page, inset)
    ui.filter = BuildFilter(page, inset)
    ui.search:SetPoint("RIGHT", ui.filter, "LEFT", -SEARCH_GAP, 0)

    -- The bar sits inside the card, to the right of the rows.
    local scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -5)
    scrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -18, 5)
    local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    -- Order matters: the factory and extents before the view is attached,
    -- the view before any provider, and a provider before anything queries.
    local view = CreateScrollBoxListLinearView()
    view:SetElementFactory(ElementFactory)
    view:SetElementExtentCalculator(ElementExtent)
    view:SetPadding(0, 0, LEFT_GUTTER, 0, 0)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    scrollBox:SetDataProvider(CreateDataProvider())

    local selection = ScrollUtil.AddSelectionBehavior(scrollBox)
    selection:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, OnSelectionChanged, List)

    local empty = inset:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("LEFT", inset, "LEFT", 24, 0)
    empty:SetPoint("RIGHT", inset, "RIGHT", -24, 0)
    empty:SetJustifyH("CENTER")
    empty:Hide()

    ui.inset, ui.scrollBox, ui.scrollBar, ui.view = inset, scrollBox, scrollBar, view
    ui.selection, ui.empty = selection, empty
end
