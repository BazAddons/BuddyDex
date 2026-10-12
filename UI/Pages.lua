-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/Pages.lua: the Buddy and Settings tabs of the BuddyDex window
-- (ns.Pages). The Buddy tab keeps the Mini Me's place until it arrives in
-- milestone 2. The Settings tab binds the friendship switches (chat lines,
-- toasts, sounds) to ns.db.settings, explains how friends are made, shows
-- the totals, and lists the slash commands. UI/DexFrame.lua calls both
-- builders once, the first time the window opens, with page frames it owns.

local Pages = {}
ns.Pages = Pages

-- The mask PortraitFrameTemplate cuts the window portrait with, so the
-- buddy placeholder is round in the same way.
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

-- The totals on the settings page redraw at most this often.
local REFRESH_DELAY = 0.5

-- UICheckButtonTemplate is 32 px; 26 matches Blizzard's own option lists.
-- Its label hangs off the box's right edge, 2 px in.
local CHECK_SIZE = 26
local CHECK_INDENT = -4                               -- the box art has a margin; this lines it up with the headings
local CHECK_TEXT_INDENT = CHECK_INDENT + CHECK_SIZE - 2

local ui = { checks = {} }   -- the settings page's widgets, once built
local countsDirty = false
local countsPending = false

-- Helpers ----------------------------------------------------------------------

local function Plain(v)
    local util = ns.Util
    if util and util.Plain then return util.Plain(v) end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

-- A failing call into another module is reported once per distinct error
-- and never takes the page down with it.
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

local function Fire(event, ...)
    local bus, events = ns.Bus, ns.Event
    if bus and events and events[event] then
        Call(bus.TriggerEvent, bus, events[event], ...)
    end
end

-- One callback per event with ns.Pages as the owner, as the bus requires.
local function Listen(event, fn)
    local bus, events = ns.Bus, ns.Event
    if bus and events and events[event] then
        bus:RegisterCallback(events[event], fn, Pages)
    end
end

local function Settings()
    local db = ns.db
    if type(db) == "table" and type(db.settings) == "table" then return db.settings end
    return nil
end

local function Counts()
    local db = ns.Database
    if not (db and db.Count) then return 0, 0 end
    local ok, friends, buddies = pcall(db.Count)
    if not ok then
        Report(friends)
        return 0, 0
    end
    return math.floor(tonumber(Plain(friends)) or 0), math.floor(tonumber(Plain(buddies)) or 0)
end

local function Plural(n, one, many)
    return n == 1 and one or many
end

-- Buddy page -------------------------------------------------------------------

-- The pages sit in a dark card on the Legacy background, like the Dex page's
-- panels (ns.Art.CreateCard); a plain inset when Art is missing.
local function NewCard(page)
    local art = ns.Art
    if art and art.CreateCard then return art.CreateCard(page) end
    return CreateFrame("Frame", nil, page, "InsetFrameTemplate")
end


-- Settings page: layout --------------------------------------------------------
-- Each column lays its rows out top to bottom, every row hung off the one
-- above it, so text that wraps pushes the rest of its column down by itself.

local function NewColumn(parent, x, y, width)
    return { parent = parent, x = x, y = y, width = width }
end

-- indent is the row's left edge relative to the column's; gap is the space
-- above it.
local function Place(col, region, indent, gap)
    indent = indent or 0
    if col.last then
        region:SetPoint("TOPLEFT", col.last, "BOTTOMLEFT", indent - col.lastIndent, -(gap or 0))
    else
        region:SetPoint("TOPLEFT", col.parent, "TOPLEFT", col.x + indent, col.y)
    end
    col.last, col.lastIndent = region, indent
end

local function AddHeading(col, text, gap)
    local heading = col.parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetJustifyH("LEFT")
    heading:SetText(text)
    Place(col, heading, 0, gap)
    -- A faint rule in the heading's gold, under it.
    local rule = col.parent:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(1, 0.82, 0, 0.25)
    rule:SetSize(col.width, 1)
    Place(col, rule, 0, 5)
    return heading
end

local function AddText(col, font, text, indent, gap)
    indent = indent or 0
    local fs = col.parent:CreateFontString(nil, "ARTWORK", font)
    fs:SetWidth(col.width - indent)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    Place(col, fs, indent, gap)
    return fs
end

local function AddButton(col, text, width, onClick, gap)
    local button = CreateFrame("Button", nil, col.parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    Place(col, button, 0, gap)
    return button
end

local function AddCommand(col, command, what)
    local name = col.parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    name:SetWidth(96)
    name:SetJustifyH("LEFT")
    name:SetText(command)
    Place(col, name, 0, 7)
    local desc = col.parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("LEFT", name, "RIGHT", 6, 0)
    desc:SetJustifyH("LEFT")
    desc:SetText(what)
    return name
end

-- Settings page: switches -----------------------------------------------------------

-- Saved as false, never as nil: the defaults are deep-filled on every load,
-- and a missing key would come back switched on.
local function OnCheckClick(check)
    local settings, key = Settings(), check.settingKey
    if not (settings and key) then return end
    local value = check:GetChecked() and true or false
    settings[key] = value
    PlayKit(value and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Fire("SettingChanged", key, value)
end

local function AddCheckbox(col, key, label, desc)
    local check = CreateFrame("CheckButton", nil, col.parent, "UICheckButtonTemplate")
    check:SetSize(CHECK_SIZE, CHECK_SIZE)
    Place(col, check, CHECK_INDENT, 8)
    check.settingKey = key
    check:SetScript("OnClick", OnCheckClick)

    -- UICheckButtonTemplate names its label Text (and aliases it as text).
    local text = check.Text or check.text
    if text then
        text:SetText(label)
        -- The label clicks the box too, as in Blizzard's option lists. Its
        -- width is secret only while anchoring is, which never holds here.
        local width = Plain(text:GetStringWidth())
        if type(width) == "number" then check:SetHitRectInsets(0, -(width + 4), 0, 0) end
    end

    if desc then
        local fs = col.parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        if text then
            fs:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
        else
            fs:SetPoint("TOPLEFT", check, "BOTTOMLEFT", CHECK_TEXT_INDENT - CHECK_INDENT, 0)
        end
        fs:SetWidth(col.width - CHECK_TEXT_INDENT)
        fs:SetJustifyH("LEFT")
        fs:SetText(desc)
        check.Description = fs
        -- The next row hangs off the description, the lowest thing here.
        col.last, col.lastIndent = fs, CHECK_TEXT_INDENT
    end
    ui.checks[key] = check
    return check
end

-- value is the new setting when the caller has it (SettingChanged carries
-- it); otherwise the saved one is read.
local function UpdateCheck(key, value)
    local check = key ~= nil and ui.checks[key]
    if not check then return end
    if type(value) ~= "boolean" then
        local settings = Settings()
        value = settings ~= nil and settings[key] and true or false
    end
    check:SetChecked(value)
end

local function UpdateChecks()
    for key in pairs(ui.checks) do UpdateCheck(key) end
end

-- Settings page: totals ---------------------------------------------------------------

local function UpdateCounts()
    countsDirty = false
    if not ui.count then return end
    local friends, buddies = Counts()
    ui.count:SetText(("%d %s, %d %s"):format(friends, Plural(friends, "friend", "friends"),
        buddies, Plural(buddies, "buddy", "buddies")))
end

-- Settings page: live updates ------------------------------------------------------

-- IsVisible, not IsShown: the page stays shown as the current tab while
-- the window itself is closed.
local function SettingsOnScreen()
    local page = ui.page
    if not page then return false end
    local ok, visible = pcall(page.IsVisible, page)
    if ok and visible ~= nil then return visible and true or false end
    return page:IsShown() and true or false
end

local function FlushCounts()
    countsPending = false
    if countsDirty and SettingsOnScreen() then UpdateCounts() end
end

-- Counting walks the whole roster, so a burst of sightings during a sweep
-- is folded into one recount; off screen, the page recounts when shown.
local function QueueCounts()
    countsDirty = true
    if countsPending or not SettingsOnScreen() then return end
    if C_Timer and C_Timer.After then
        countsPending = true
        C_Timer.After(REFRESH_DELAY, FlushCounts)
    else
        UpdateCounts()
    end
end

local function RefreshSettings()
    UpdateChecks()
    UpdateCounts()
end

-- Settings page --------------------------------------------------------------------

-- The Buddy page ---------------------------------------------------------------------------
-- Your buddy and how it behaves: who's out on the left, with the quick
-- buttons, and every option on the right (Voice and Chatter, Behavior and
-- Look). Its right-click menu keeps only the quick things.

local DROPDOWN_WIDTH = 200
local SLIDER_WIDTH = 190
local ROW_HEIGHT = 28
local STAGE_W, STAGE_H = 300, 350
local buddyUI = { dropdowns = {}, sliders = {} }

local function Set(key, value)
    local settings = Settings()
    if not settings then return end
    settings[key] = value
    Fire("SettingChanged", key, value)
end

local function Get(key)
    return (Settings() or {})[key]
end

local function Percent(value)
    return ("%d%%"):format(math.floor(value * 100 + 0.5))
end

-- A row for a labeled control: the label on the left, the control on the right.
local function NewRow(col, label, gap)
    local row = CreateFrame("Frame", nil, col.parent)
    row:SetSize(col.width, ROW_HEIGHT)
    Place(col, row, 0, gap or 8)
    row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.Label:SetPoint("LEFT", 0, 0)
    row.Label:SetJustifyH("LEFT")
    row.Label:SetText(label)
    return row
end

-- A dropdown. spec: label, choices (a list of { value, text }, or a
-- function returning one when it opens), get() and set(value), desc.
local function AddDropdown(col, spec)
    local row = NewRow(col, spec.label)
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(DROPDOWN_WIDTH)
    dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    dropdown:SetupMenu(function(_, root)
        local list = type(spec.choices) == "function" and spec.choices() or spec.choices
        if #list > 12 and root.SetScrollMode then root:SetScrollMode(320) end
        for _, choice in ipairs(list) do
            root:CreateRadio(choice[2], function(value) return spec.get() == value end, function(value)
                PlayKit("IG_MAINMENU_OPTION_CHECKBOX_ON")
                spec.set(value)
            end, choice[1])
        end
    end)
    if spec.desc then AddText(col, "GameFontHighlightSmall", spec.desc, 0, 3) end
    buddyUI.dropdowns[#buddyUI.dropdowns + 1] = dropdown
    return dropdown
end

-- A dropdown for a setting with fixed choices.
local function AddChoice(col, key, label, choices, desc)
    return AddDropdown(col, { label = label, choices = choices, desc = desc,
        get = function() return Get(key) end, set = function(value) Set(key, value) end })
end

-- A slider for a numeric setting. spec: label, key, min, max, steps,
-- default, format(value), round (decimal places kept), desc.
local function AddSlider(col, spec)
    local row = NewRow(col, spec.label)
    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetSize(SLIDER_WIDTH, 30)
    slider:SetPoint("RIGHT", row, "RIGHT", -44, 0)
    local mixin = MinimalSliderWithSteppersMixin
    local function Current() return tonumber(Get(spec.key)) or spec.default end
    local scale = 10 ^ (spec.round or 0)
    slider:Init(Current(), spec.min, spec.max, spec.steps,
        mixin and mixin.Label and { [mixin.Label.Right] = spec.format } or nil)
    if mixin and mixin.Event then
        slider:RegisterCallback(mixin.Event.OnValueChanged, function(_, value)
            if buddyUI.refreshing then return end
            Set(spec.key, math.floor(value * scale + 0.5) / scale)
        end, slider)
    end
    slider.Refresh = function()
        buddyUI.refreshing = true
        pcall(slider.SetValue, slider, Current())
        buddyUI.refreshing = false
    end
    if spec.desc then AddText(col, "GameFontHighlightSmall", spec.desc, 0, 3) end
    buddyUI.sliders[#buddyUI.sliders + 1] = slider
    return slider
end

local function AddButton(parent, text, width, onClick)
    local art = ns.Art or {}
    local button = art.CreateSmallButton and art.CreateSmallButton(parent, width, 24)
        or CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", function(self)
        PlayKit("IG_MAINMENU_OPTION_CHECKBOX_ON")
        onClick(self)
    end)
    return button
end

-- Who's out: the Mini Me, or a friend at Buddy tier or better.
local function OutChoices()
    local list = { { 0, "Your Mini Me" } }
    local companion = ns.Companion
    for _, friend in ipairs(companion and companion.Buddies() or {}) do
        list[#list + 1] = { friend.npcID, friend.name }
    end
    return list
end

-- The stage shows whoever is out: the Mini Me in your armor, or the friend.
local function UpdateStage()
    local page = buddyUI.page
    if not page then return end
    local companion = ns.Companion
    local npcID = companion and companion.Buddy()
    local entry = npcID and ns.Database and ns.Database.GetEntry(npcID)
    if entry then
        if page.MiniMe then page.MiniMe:Hide() end
        page.Portrait:Hide()
        page.Npc:Show()
        if page.Npc.npcID ~= npcID then
            page.Npc.npcID = npcID
            pcall(page.Npc.SetCreature, page.Npc, npcID, tonumber(Plain(entry.display)))
            pcall(page.Npc.SetFacing, page.Npc, math.rad(25))
        end
        local name = Plain(entry.name) or "Your buddy"
        page.Headline:SetText(name)
        page.Body:SetText(("%s is keeping you company on screen, speaking their own lines. Pick someone else below, or bring your Mini Me back."):format(name))
    else
        page.Npc:Hide()
        page.Npc.npcID = nil
        if page.MiniMe then page.MiniMe:Show() else page.Portrait:Show() end
        page.Headline:SetText("Your Mini Me")
        page.Body:SetText("A pint-sized gnome version of you, in whatever armor you wear. Friends at Buddy tier or better can come along instead.")
    end
    page.Toggle:SetText(Get("companion") == false and "Show on screen" or "Hide from screen")
end

local function RefreshBuddy()
    if not buddyUI.page then return end
    UpdateChecks()
    for _, dropdown in ipairs(buddyUI.dropdowns) do
        if dropdown.GenerateMenu then pcall(dropdown.GenerateMenu, dropdown) end
    end
    for _, slider in ipairs(buddyUI.sliders) do slider.Refresh() end
    UpdateStage()
end

function Pages.BuildBuddy(page)
    if not page or page.Inset then return end
    buddyUI.page = page
    local inset = NewCard(page)
    inset:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -60)
    inset:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -14, 20)
    page.Inset = inset

    -- Who's out, on the left.
    local art = ns.Art or {}
    local stage = CreateFrame("Frame", nil, inset)
    stage:SetSize(STAGE_W, STAGE_H)
    stage:SetPoint("TOPLEFT", inset, "TOPLEFT", 40, -24)
    page.Stage = stage

    local portrait = inset:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(96, 96)
    portrait:SetPoint("CENTER", stage, "CENTER", 0, 0)
    if art.MiniMePortrait then portrait:SetTexture(art.MiniMePortrait()) end
    portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    pcall(function()
        local mask = inset:CreateMaskTexture()
        mask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(portrait)
        portrait:AddMaskTexture(mask)
    end)
    page.Portrait = portrait

    -- The icon stays until the model has loaded, and comes back if it can't.
    local ok, miniMe = pcall(ns.MiniMe.Create, stage, {
        framing = "body", yaw = math.rad(25),
        hideWeapons = function() return Get("hideWeapons") == true end,
        onLoaded = function() portrait:Hide() end,
        onFailed = function() portrait:Show() end,
    })
    if ok and miniMe then
        miniMe:SetAllPoints(stage)
        page.MiniMe = miniMe
    end
    local npc = CreateFrame("DressUpModel", nil, stage)
    npc:SetAllPoints(stage)
    npc:Hide()
    page.Npc = npc

    local headline = inset:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    headline:SetPoint("TOP", stage, "BOTTOM", 0, -8)
    page.Headline = headline
    local body = inset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOP", headline, "BOTTOM", 0, -10)
    body:SetWidth(STAGE_W + 40)
    body:SetJustifyH("CENTER")
    body:SetSpacing(2)
    page.Body = body

    local left = NewColumn(inset, 30, -(24 + STAGE_H + 104), STAGE_W + 60)
    AddDropdown(left, { label = "Who's out", choices = OutChoices,
        get = function() local companion = ns.Companion return companion and companion.Buddy() or 0 end,
        set = function(npcID)
            local companion = ns.Companion
            if companion then companion.SetBuddy(npcID ~= 0 and npcID or nil) end
        end })
    local buttons = CreateFrame("Frame", nil, inset)
    buttons:SetSize(STAGE_W + 60, 24)
    Place(left, buttons, 0, 14)
    page.Toggle = AddButton(buttons, "Hide from screen", 116, function()
        local companion = ns.Companion
        if companion and companion.Toggle then companion.Toggle() end
    end)
    page.Toggle:SetPoint("LEFT", 0, 0)
    local say = AddButton(buttons, "Say something", 116, function()
        local companion = ns.Companion
        if companion then companion.SayLine("idle") end
    end)
    say:SetPoint("LEFT", page.Toggle, "RIGHT", 8, 0)
    local reset = AddButton(buttons, "Reset position", 116, function()
        local companion = ns.Companion
        if companion and companion.ResetPosition then companion.ResetPosition() end
    end)
    reset:SetPoint("LEFT", say, "RIGHT", 8, 0)

    -- Faint dividers between the three parts.
    for _, x in ipairs({ 420, 880 }) do
        local divider = inset:CreateTexture(nil, "ARTWORK")
        divider:SetColorTexture(1, 1, 1, 0.08)
        divider:SetWidth(1)
        divider:SetPoint("TOP", inset, "TOPLEFT", x, -18)
        divider:SetPoint("BOTTOM", inset, "BOTTOMLEFT", x, 18)
    end

    -- Voice and chatter.
    local voice = NewColumn(inset, 450, -18, 400)
    AddHeading(voice, "Voice")
    AddChoice(voice, "voiceMode", "Voice", { { "recorded", "On" }, { "off", "Off" } },
        "Your Mini Me's own voice, recorded for BuddyDex, comes with the BuddyDex Voice addon. Gnome friends speak in these voices too; other friends who come along use their own voices from the game. The game's dialog volume sets how loud. The chat bubble always shows the words.")
    local test = CreateFrame("Frame", nil, inset)
    test:SetSize(400, 24)
    Place(voice, test, 0, 10)
    AddButton(test, "Test voice", 116, function()
        local companion = ns.Companion
        if companion and companion.TestVoice then companion.TestVoice() end
    end):SetPoint("RIGHT", 0, 0)

    AddHeading(voice, "Chatter", 22)
    AddSlider(voice, { label = "Chattiness", key = "chattiness", min = 0, max = 100, steps = 20, default = 50,
        format = function(value)
            value = math.floor(value + 0.5)
            return value == 0 and "Quiet" or ("%d%%"):format(value)
        end,
        desc = "How much it talks: comments on zones, quests, loot and flights, idle chatter, and cheering in fights. At Quiet it only answers when you poke it or emote at it." })
    AddCheckbox(voice, "echoChat", "Show what it says in chat",
        "Its lines also appear in your chat window, the way NPCs talk, so you never miss one.")

    -- Behavior and look.
    local behavior = NewColumn(inset, 910, -18, 400)
    AddHeading(behavior, "Behavior")
    AddChoice(behavior, "combat", "In combat", { { "stay", "Stay on screen" }, { "hide", "Hide" } },
        "Staying, it gestures as fights start and end, cheers you on now and then, and lets your clicks pass through.")
    AddCheckbox(behavior, "hideInInstances", "Hide in dungeons, raids and battlegrounds")
    AddCheckbox(behavior, "sleepWhenAway", "Nap when you're away")
    AddCheckbox(behavior, "locked", "Lock in place", "It can't be dragged by accident.")
    AddCheckbox(behavior, "clampToScreen", "Keep on screen",
        "Off, you can drag it partly off the edge to peek in from the side.")
    AddCheckbox(behavior, "clickThrough", "Let clicks pass through",
        "It never takes the mouse. Type /bd options to come back here.")

    AddHeading(behavior, "Look", 22)
    AddSlider(behavior, { label = "Size", key = "scale", min = 0.5, max = 2, steps = 30, default = 1,
        round = 2, format = Percent })
    AddSlider(behavior, { label = "Opacity", key = "alpha", min = 0.2, max = 1, steps = 16, default = 1,
        round = 2, format = Percent })
    AddChoice(behavior, "facing", "Facing", {
        { "center", "Toward the middle" }, { "left", "Left" }, { "right", "Right" }, { "front", "Straight out" },
    })
    AddCheckbox(behavior, "hideWeapons", "Hide weapons")

    page:HookScript("OnShow", RefreshBuddy)
    -- Its own owner: Listen's owner holds the settings page's callbacks.
    ns.Bus:RegisterCallback(ns.Event.SettingChanged, function()
        if page:IsVisible() then RefreshBuddy() end
    end, buddyUI)
    RefreshBuddy()
end

function Pages.BuildSettings(page)
    if not page or ui.page then return end
    ui.page = page

    local inset = NewCard(page)
    inset:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -60)
    inset:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -14, 20)
    page.Inset = inset

    local left = NewColumn(inset, 20, -18, 330)
    local right = NewColumn(inset, 396, -18, 330)

    -- A faint divider between the two columns.
    local divider = inset:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.08)
    divider:SetWidth(1)
    divider:SetPoint("TOP", inset, "TOPLEFT", 373, -18)
    divider:SetPoint("BOTTOM", inset, "BOTTOMLEFT", 373, 18)

    AddHeading(left, "Friendship")
    AddCheckbox(left, "announce", "Show friendship gains in chat",
        "A line in chat, like a reputation gain, each time a friendship grows.")
    AddCheckbox(left, "toasts", "Show friendship toasts",
        "A small card near the top of the screen with the friend's portrait and progress.")
    AddCheckbox(left, "sounds", "Play a sound for a new tier",
        "A fanfare when a friend becomes your Buddy, and a chime for every other tier.")

    AddHeading(left, "Making friends", 26)
    AddText(left, "GameFontHighlightSmall",
        "Talking to an NPC, trading, training, using their services and doing their quests all count. Once you've met, greeting them with an emote counts too. Each kind counts once a day per NPC, so coming back matters more than clicking.",
        0, 8)
    AddText(left, "GameFontHighlightSmall",
        "Everyone has a favorite emote: the BuddyDex hints at it. Rude emotes cost friendship. Only friendly NPCs can become friends.",
        0, 8)

    AddHeading(right, "Your BuddyDex")
    ui.count = AddText(right, "GameFontHighlight", "", 0, 10)

    AddHeading(right, "Commands", 26)
    AddCommand(right, "/bd", "Opens or closes the BuddyDex")
    AddCommand(right, "/bd settings", "Opens this page")
    AddCommand(right, "/bd buddy", "Shows or hides your buddy")
    AddCommand(right, "/bd options", "Opens the buddy's options")
    AddText(right, "GameFontHighlightSmall", "Your buddy's voice, chatter, behavior and look are on the Buddy tab.", 0, 14)
    AddText(right, "GameFontDisableSmall", "/buddydex works too.", 0, 8)

    local version = inset:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    version:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -12, 10)
    version:SetText(("BuddyDex %s"):format(tostring(ns.VERSION or "?")))

    -- Handles for anything that needs to reach a control (the tests do).
    page.Checks = ui.checks
    page.CountText = ui.count

    -- Shown as a tab, or with the window while it is the current tab: either
    -- way the page reads everything fresh.
    page:HookScript("OnShow", RefreshSettings)

    Listen("NpcSeen", QueueCounts)
    Listen("NpcUpdated", QueueCounts)
    Listen("NpcRemoved", QueueCounts)
    Listen("SettingChanged", function(_, key, value) UpdateCheck(key, value) end)

    RefreshSettings()
end
