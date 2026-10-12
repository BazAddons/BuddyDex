-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/DexFrame.lua: the BuddyDex window shell (ns.Dex). It owns the portrait
-- frame and its Legacy background, the title drag strip and the saved
-- position, Escape and the close button, the three side tabs and the pages
-- they switch between, the seen and caught count box in the Dex page's
-- attic, and the live refresh that keeps an open list current while the
-- scout works. The list, the detail pane and the Buddy and Settings pages
-- are built into these pages by their own modules, the first time the
-- window opens.

local Dex = {}
ns.Dex = Dex

-- The window's global name: Escape finds the window by name through
-- UISpecialFrames.
local FRAME_NAME = "BuddyDexFrame"
-- Roomier than Camelot's own journals (703 x 606) and its Legacy window
-- (920 x 575): the BuddyDex shows a tall model beside its details, and the
-- BuddyDex entry in a column down the right (ENTRY_COLUMN, gap included).
local ENTRY_COLUMN = 374
local WIDTH, HEIGHT = 1040 + ENTRY_COLUMN, 760
-- On a screen too small for all that, the window shrinks to fit, tabs and a
-- margin included. Wherever it fits, it is full size.
local SCREEN_MARGIN = 20

-- Tab order. A tab's label is also the window title while it is selected.
local TAB_DEX, TAB_BUDDY, TAB_SETTINGS = 1, 2, 3
local TAB_TEXT = { "BuddyDex", "Buddy", "Settings" }
local PAGE_KEYS = { "DexPage", "BuddyPage", "SettingsPage" }

-- The tabs hang down the right edge like Forever's Legacy window's
-- (LegacySystemTabTemplate is LargeSideTabButtonTemplate with its icon
-- filled to the interior), starting 60 px down and 2 px apart. Camelot's
-- tab art is wider than retail's; about 55 px hangs outside the frame.
local SIDE_TAB_TEMPLATE = "LargeSideTabButtonTemplate"
local TAB_TOP, TAB_GAP, TAB_ICON_EXTENT = -60, 2, 50
local TAB_OVERHANG = 55

-- A sweep in a city hands the scout new NPCs several times a second. An
-- open list redraws at most this often, however many arrive.
local REFRESH_DELAY = 0.5

local frame             -- the window, once it is built
local pages = {}        -- [tab] = page frame
local tabs = {}         -- [tab] = tab button
local header            -- the count box in the Dex page's attic
local currentTab = TAB_DEX
local dirty = true      -- the list is out of date
local pending = false   -- a coalesced refresh is already scheduled
local moving = false    -- the drag strip is moving the window
local shownAt           -- GetTime() when the window last opened
local building = false
local buildFailed = false

-- Helpers ----------------------------------------------------------------------

-- ns.Util.Plain once the core has loaded, which it always has by the time a
-- window opens; the local check only covers a broken load order.
local function Plain(v)
    local util = ns.Util
    if util and util.Plain then return util.Plain(v) end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

-- Errors from the modules that fill the window go to the error handler,
-- each distinct one once a session: a broken list must not take the whole
-- window down with it, and the live refresh must not repeat one error
-- twice a second for as long as a sweep runs.
local reported = {}

local function Report(err)
    local msg = Plain(err)
    msg = msg ~= nil and tostring(msg) or "unknown error"
    if reported[msg] then return end
    reported[msg] = true
    local handler = geterrorhandler and geterrorhandler()
    if handler then handler(msg) end
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn, ...)
    if not ok then Report(err) end
    return ok
end

local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit) end
end

local function DexSettings()
    local db = ns.db
    if type(db) == "table" and type(db.dex) == "table" then return db.dex end
    return nil
end

-- A tab index from anywhere (saved file, slash command) as 1..3.
local function ClampTab(index)
    index = tonumber(Plain(index))
    if not index then return TAB_DEX end
    index = math.floor(index)
    if index < 1 or index > #TAB_TEXT then return TAB_DEX end
    return index
end

-- Position ---------------------------------------------------------------------
-- The client's own layout cache is off for this window (SetDontSavePosition),
-- so the saved variables are the one record of where it was left. With both,
-- the two would disagree about it on the next login.

local function SavePosition(f)
    local db = DexSettings()
    if not db then return end
    -- GetPoint answers with secrets while anchoring is secret. That never
    -- applies to this window, but a secret must never reach the saved file.
    local ok, point, _, relPoint, x, y = pcall(f.GetPoint, f, 1)
    if not ok then return end
    point, relPoint, x, y = Plain(point), Plain(relPoint), Plain(x), Plain(y)
    if type(point) ~= "string" or type(x) ~= "number" or type(y) ~= "number" then return end
    if type(relPoint) ~= "string" then relPoint = point end
    db.point = { point, relPoint, x, y }
end

local function RestorePosition(f)
    f:ClearAllPoints()
    local db = DexSettings()
    local p = db and db.point
    if type(p) == "table" and type(p[1]) == "string" and type(p[3]) == "number" and type(p[4]) == "number" then
        local relPoint = type(p[2]) == "string" and p[2] or p[1]
        -- A hand-edited file can hold a point name SetPoint rejects.
        if pcall(f.SetPoint, f, p[1], UIParent, relPoint, p[3], p[4]) then return end
        f:ClearAllPoints()
    end
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

-- Refresh ----------------------------------------------------------------------

local function Counts()
    local db = ns.Database
    if not (db and db.Count) then return 0, 0 end
    local ok, seen, caught = pcall(db.Count)
    if not ok then
        Report(seen)
        return 0, 0
    end
    return math.floor(tonumber(Plain(seen)) or 0), math.floor(tonumber(Plain(caught)) or 0)
end

local function UpdateHeader()
    if not header then return end
    local friends, buddies = Counts()
    header.Friends.Value:SetText(friends)
    header.Buddies.Value:SetText(buddies)
end

-- The list and the count box live on the Dex page and only redraw while it
-- is on screen. A list refresh re-selects the current NPC, and the detail
-- pane would load that NPC's model into a hidden frame, where the load may
-- never finish and time out into the "no model" picture. A change that
-- arrives meanwhile marks the list dirty, and showing the page catches up.
local function DexPageOnScreen()
    return frame ~= nil and frame:IsShown() and currentTab == TAB_DEX
end

function Dex.Refresh()
    if not frame then return end
    if not DexPageOnScreen() then
        dirty = true
        return
    end
    dirty = false
    UpdateHeader()
    local list = ns.DexList
    if list and list.Refresh then Call(list.Refresh) end
end

local function Flush()
    pending = false
    if dirty and DexPageOnScreen() then Dex.Refresh() end
end

-- Bus callback for NpcSeen, NpcUpdated and NpcRemoved: the first change
-- schedules one refresh, and everything until it runs rides along.
local function OnRosterChanged()
    dirty = true
    if pending or not DexPageOnScreen() then return end
    if C_Timer and C_Timer.After then
        pending = true
        C_Timer.After(REFRESH_DELAY, Flush)
    else
        Dex.Refresh()
    end
end

-- The detail pane holds a model while the Dex page shows one. It lets go
-- whenever the page leaves the screen; the dirty flag makes sure the next
-- time the page shows, the list refreshes, re-selects and loads it again.
local function ReleaseDetail()
    local detail = ns.DexDetail
    if detail and detail.Release then Call(detail.Release) end
end

-- Tabs -------------------------------------------------------------------------

local function SelectTab(index, withSound)
    index = ClampTab(index)
    local previous = currentTab
    currentTab = index

    -- SetChecked only shows the selected art here: it would swap the icon
    -- for an atlas, but only on tabs that set activeAtlas, which these don't.
    for i, tab in ipairs(tabs) do
        if tab.SetChecked then
            Call(tab.SetChecked, tab, i == index)
        elseif tab.SelectedTexture then
            tab.SelectedTexture:SetShown(i == index)
        end
    end
    -- Hide before show, so no page ever sees another one up at the same time.
    for i, page in ipairs(pages) do
        if i ~= index then page:Hide() end
    end
    pages[index]:Show()
    frame:SetTitle(TAB_TEXT[index])

    local db = DexSettings()
    if db then db.tab = index end
    if withSound and index ~= previous then PlayKit("IG_CHARACTER_INFO_TAB") end

    if previous == TAB_DEX and index ~= TAB_DEX then
        -- A closed window has released the model already, in OnHide.
        if frame:IsShown() then ReleaseDetail() end
        dirty = true
    elseif index == TAB_DEX and dirty then
        Dex.Refresh()
    end
end

-- The template's OnMouseUp has already played the tab sound by the time
-- this runs, so the selection itself stays quiet. A press dragged off the
-- tab before letting go is not a click.
local function OnTabMouseUp(tab, button, upInside)
    if button ~= "LeftButton" or upInside == false then return end
    SelectTab(tab.tabIndex, false)
end

-- Building ---------------------------------------------------------------------

local function ShowHeaderTooltip(box)
    GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, "Friends and Buddies")
    GameTooltip_AddNormalLine(GameTooltip, "Talk, trade, train, do quests and emote to make friends.")
    GameTooltip_AddHighlightLine(GameTooltip, "Friends who reach Buddy can join you (coming soon).")
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- Two stat cards in the attic's right corner, a big number over a small
-- label, in the cards the panels use. Camelot's journals show a single
-- count box (CollectionsCountTemplate, load-on-demand); two cards read at
-- a glance and leave the attic's left side to the search and filter.
local function StatCard(page, label, r, g, b)
    local art = ns.Art
    local card = art and art.CreateCard and art.CreateCard(page)
        or CreateFrame("Frame", nil, page, "InsetFrameTemplate3")
    card:SetSize(112, 46)

    local value = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
    value:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -7)
    value:SetTextColor(r, g, b)
    card.Value = value

    local text = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", value, "BOTTOMLEFT", 0, -2)
    text:SetText(label)
    card.Label = text

    -- A card has no mouse scripts of its own; it takes the mouse for its tooltip.
    card:EnableMouse(true)
    card:SetScript("OnEnter", ShowHeaderTooltip)
    card:SetScript("OnLeave", HideTooltip)
    return card
end

local function BuildHeader(page)
    local buddies = StatCard(page, "Buddies", 1, 0.82, 0)
    -- Over the Lore column, as the search and filter sit over the list.
    buddies:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -28)
    local friends = StatCard(page, "Friends", 1, 1, 1)
    friends:SetPoint("RIGHT", buddies, "LEFT", -8, 0)
    local box = { Friends = friends, Buddies = buddies }
    page.Header = box
    return box
end

-- One side tab. The template sizes itself from its atlas as it loads and
-- leaves the icon unsized; SetFillToInterior sizes and trims it. Tooltips
-- come from tooltipText. Ported from BazUI's Core/SideTabs.lua, which has
-- the same fallback for a client without the template.
local function CreateSideTab(f, index)
    local tab
    local art = ns.Art
    if art and art.HasTemplate and art.HasTemplate(SIDE_TAB_TEMPLATE) then
        tab = CreateFrame("Frame", nil, f, SIDE_TAB_TEMPLATE)
        tab:SetFillToInterior(true, TAB_ICON_EXTENT)
        tab:SetCustomOnMouseUpHandler(OnTabMouseUp)
    else
        tab = CreateFrame("Frame", nil, f)
        tab:SetSize(43, 55)
        tab.Background = tab:CreateTexture(nil, "BACKGROUND")
        tab.Background:SetAllPoints()
        tab.Background:SetColorTexture(0.10, 0.09, 0.07, 0.9)
        tab.Icon = tab:CreateTexture(nil, "ARTWORK")
        tab.Icon:SetPoint("CENTER", -2, 0)
        tab.Icon:SetSize(30, 30)
        tab.Icon:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
        tab.SelectedTexture = tab:CreateTexture(nil, "OVERLAY")
        tab.SelectedTexture:SetAllPoints()
        tab.SelectedTexture:SetColorTexture(1, 0.82, 0, 0.25)
        local hi = tab:CreateTexture(nil, "HIGHLIGHT")
        hi:SetAllPoints()
        hi:SetColorTexture(1, 1, 1, 0.15)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", HideTooltip)
        tab:SetScript("OnMouseUp", function(self, button)
            PlayKit("IG_CHARACTER_INFO_TAB")
            OnTabMouseUp(self, button, self:IsMouseOver())
        end)
    end
    tab:EnableMouse(true)
    tab.tabIndex = index
    tab.tooltipText = TAB_TEXT[index]
    local icons = art and art.TAB_ICONS
    tab.Icon:SetTexture(icons and icons[index] or nil)
    if index == TAB_BUDDY and art and art.MiniMePortrait then
        -- The Buddy tab wears the same gnome portrait as the window.
        tab.Icon:SetTexture(art.MiniMePortrait())
    end
    return tab
end

local function BuildTabs(f)
    for i in ipairs(TAB_TEXT) do
        local tab = CreateSideTab(f, i)
        if i == 1 then
            tab:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, TAB_TOP)
        else
            tab:SetPoint("TOPLEFT", tabs[i - 1], "BOTTOMLEFT", 0, -TAB_GAP)
        end
        tabs[i] = tab
    end
end

-- The Legacy reward track's page background, laid over the template's own
-- Bg the way LegacyRewardTrackPageTemplate lays it: the page inset 5 px at
-- the sides and 6 px at the bottom, the texture 2 px below the page's top.
-- BORDER sits above every BACKGROUND texture of the template and below the
-- portrait and NineSlice, which are child frames hundreds of levels up.
-- Without the atlas the texture hides and the template's Bg shows.
local function BuildBackground(f)
    local bg = f:CreateTexture(nil, "BORDER", nil, -8)
    bg:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -2)
    bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 6)
    local art = ns.Art
    if art and art.SetAtlas and art.WINDOW_BG then
        art.SetAtlas(bg, art.WINDOW_BG)
    else
        bg:Hide()
    end
    f.LegacyBackground = bg
end

local function FitToScreen()
    if not frame then return end
    local width, height = Plain(UIParent:GetWidth()), Plain(UIParent:GetHeight())
    if type(width) ~= "number" or type(height) ~= "number" then return end
    local scale = math.min(1, (width - 2 * SCREEN_MARGIN) / (WIDTH + TAB_OVERHANG),
        (height - 2 * SCREEN_MARGIN) / HEIGHT)
    frame:SetScale(math.max(0.5, scale))
end

-- A new resolution or UI scale while the window is open.
local screenEvents = CreateFrame("Frame")
screenEvents:RegisterEvent("DISPLAY_SIZE_CHANGED")
screenEvents:RegisterEvent("UI_SCALE_CHANGED")
screenEvents:SetScript("OnEvent", function()
    if frame and frame:IsShown() then FitToScreen() end
end)

local function OnWindowShow()
    if not frame then return end
    FitToScreen()
    PlayKit("IG_CHARACTER_INFO_OPEN")
    shownAt = GetTime and GetTime() or nil
    -- The detail pane let go of its model when the window closed, and the
    -- roster, or the zone a filter depends on, may have changed since.
    dirty = true
    SelectTab(currentTab, false)
end

local function OnWindowHide(f)
    PlayKit("IG_CHARACTER_INFO_CLOSE")
    -- Escape can close the window in the middle of a drag. End the move
    -- here so it cannot carry on into the next open, and keep where it got to.
    if moving then
        moving = false
        f:StopMovingOrSizing()
        SavePosition(f)
    end
    ReleaseDetail()
end

local function BuildShell()
    local f = CreateFrame("Frame", FRAME_NAME, UIParent, "PortraitFrameTemplate")
    -- Hidden before any script is set, so OnShow and OnHide only ever see
    -- real opens and closes.
    f:Hide()
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    -- Clicks on the window must not fall through to the world behind it.
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    -- Clamp the tabs as well, so a window dragged to the right edge of the
    -- screen keeps them where they can be clicked.
    f:SetClampRectInsets(0, TAB_OVERHANG, 0, 0)
    f:SetDontSavePosition(true)

    f:SetTitle(TAB_TEXT[TAB_DEX])
    local art = ns.Art
    if art and art.MiniMePortrait then f:SetPortraitToAsset(art.MiniMePortrait()) end
    BuildBackground(f)

    -- The template's close button goes through HideUIPanel, which refuses
    -- addon code in combat. This window is no UI panel, so a plain Hide
    -- does the job anywhere.
    f.CloseButton:SetScript("OnClick", function() f:Hide() end)

    -- Escape: CloseSpecialWindows hides every shown frame named in this list.
    if type(UISpecialFrames) == "table" then
        local listed = false
        for _, name in ipairs(UISpecialFrames) do
            if name == FRAME_NAME then
                listed = true
                break
            end
        end
        if not listed then table.insert(UISpecialFrames, FRAME_NAME) end
    end

    -- Set before the modules build their pages, so a module that hooks the
    -- window's scripts adds to these instead of being wiped by them.
    f:SetScript("OnShow", OnWindowShow)
    f:SetScript("OnHide", OnWindowHide)

    for i, key in ipairs(PAGE_KEYS) do
        local page = CreateFrame("Frame", nil, f)
        page:SetAllPoints(f)
        page:Hide()
        f[key] = page
        pages[i] = page
    end
    header = BuildHeader(pages[TAB_DEX])
    f.Header = header

    -- The window drags by its title strip only, so a drag on the model can
    -- turn the model and a drag in the list cannot move the window.
    local drag = CreateFrame("Button", nil, f, "PanelDragBarTemplate")
    drag:SetPoint("TOPLEFT", f, "TOPLEFT", 58, 0)
    drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -26, 0)
    drag:SetHeight(22)
    -- Above anything the pages put near the top edge.
    drag:SetFrameLevel(f:GetFrameLevel() + 10)
    -- PanelDragBarMixin runs its stop callbacks before StopMovingOrSizing.
    -- A hook runs after the whole handler, once the new position is final.
    drag:HookScript("OnDragStart", function() moving = true end)
    drag:HookScript("OnDragStop", function()
        moving = false
        SavePosition(f)
    end)
    f.DragBar = drag

    RestorePosition(f)
    BuildTabs(f)
    return f
end

-- Built on the first open, never at load. Returns the window, or nil when
-- the saved variables are not ready yet or the shell could not be built.
local function Build()
    if frame then return frame end
    if building or buildFailed then return nil end
    -- The pages read and write saved settings, which exist from ADDON_LOADED.
    if type(ns.db) ~= "table" then return nil end
    building = true

    local ok, f = pcall(BuildShell)
    if not ok then
        building, buildFailed = false, true
        Report(f)
        if ns.Print then ns.Print("The BuddyDex window could not be built.") end
        return nil
    end

    -- Each page is filled by its own module. One that fails is reported and
    -- leaves its page empty; the rest of the window still works.
    local dexPage = pages[TAB_DEX]
    local list, detail, extra = ns.DexList, ns.DexDetail, ns.Pages
    if list then Call(list.Build, dexPage) end
    if detail then Call(detail.Build, dexPage, dexPage.LeftInset, ENTRY_COLUMN) end
    if extra then
        Call(extra.BuildBuddy, pages[TAB_BUDDY])
        Call(extra.BuildSettings, pages[TAB_SETTINGS])
    end

    frame = f
    building = false

    local bus, events = ns.Bus, ns.Event
    if bus and events then
        for _, event in ipairs({ "NpcSeen", "NpcUpdated", "NpcRemoved" }) do
            if events[event] then bus:RegisterCallback(events[event], OnRosterChanged, Dex) end
        end
    end

    local db = DexSettings()
    SelectTab(db and db.tab or TAB_DEX, false)
    return frame
end

-- Public -----------------------------------------------------------------------

function Dex.IsOpen()
    return frame ~= nil and frame:IsShown() and true or false
end

function Dex.Close()
    if frame then frame:Hide() end
end

-- Shows a tab (1 BuddyDex, 2 Buddy, 3 Settings), opening the window first
-- if it is closed.
function Dex.ShowTab(index)
    if not Build() then return false end
    if frame:IsShown() then
        -- A tab picked in the frame the window opened in (Open, then
        -- ShowTab) is part of opening it, and the open sound covers it.
        local justOpened = shownAt ~= nil and GetTime ~= nil and GetTime() == shownAt
        SelectTab(index, not justOpened)
        frame:Raise()
    else
        SelectTab(index, false)
        frame:Show()
    end
    return true
end

-- Opens the window on the last tab used. With an NPC ID it opens the
-- BuddyDex tab and selects that NPC, clearing a search or filter that
-- hides it (DexList.SelectNpc does that part).
function Dex.Open(npcID)
    if not Build() then return false end
    npcID = tonumber(Plain(npcID))
    if npcID then
        Dex.ShowTab(TAB_DEX)
        local list = ns.DexList
        if list and list.SelectNpc then Call(list.SelectNpc, npcID) end
    elseif frame:IsShown() then
        frame:Raise()
    else
        frame:Show()
    end
    return true
end

function Dex.Toggle()
    if Dex.IsOpen() then
        Dex.Close()
    else
        Dex.Open()
    end
end
