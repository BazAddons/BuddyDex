-- SPDX-License-Identifier: GPL-2.0-or-later
-- tools/tests/mock.lua: a small stand-in for the WoW: Forever client, enough
-- to load every file in BuddyDex.toc and click through the BuddyDex.
--
-- It is not a faithful client. It is two things at once: a stage that runs
-- the addon's code paths, so nil errors and contract mismatches show up
-- here instead of in game, and a recorder that writes down every template,
-- font, event, sound kit, global and widget method the addon touches, so
-- tools/tests/smoke.py can check each one against tools/tests/blizzard_api.lua
-- (generated from the client's own exported UI code).

MOCK = {
    now = 0,
    errors = {},          -- every error the addon reports or throws
    printed = {},
    timers = {},
    templates = {},       -- [template] = true, from CreateFrame
    frameTypes = {},      -- [type] = true
    fonts = {},           -- [font object] = true
    events = {},          -- [event] = true
    sounds = {},          -- [SOUNDKIT key] = true
    methods = {},         -- [widget method] = true, every method looked up on a frame
    globals = {},         -- [name] = true, every global the addon reads
    defined = {},         -- [name] = true, every global the addon writes
    namespaced = {},      -- ["C_X.Y"] = true
    frames = {},          -- every frame created, in order
    cvars = { nameplateShowFriendlyNPCs = "0" },
    combat = false,
    units = {},           -- [unit] = { guid, name, type, ... }
    position = { 0.5641, 0.5262 },   -- the player's map position, or nil
    -- heights: yards tall, by creature display (the player's model is playerHeight).
    model = { displays = {}, anims = {}, setCreature = {}, heights = {}, playerHeight = 1 },
}

local function Record(err)
    MOCK.errors[#MOCK.errors + 1] = tostring(err)
end

function geterrorhandler() return Record end
function seterrorhandler() end
function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    MOCK.printed[#MOCK.printed + 1] = table.concat(parts, " ")
end

-- Lua and WoW Lua helpers -----------------------------------------------------------

function strsplit(sep, s)
    local out = {}
    for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
    return unpack(out)
end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
tinsert, tremove = table.insert, table.remove
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
time = os.time
-- MOCK.today stands in for the calendar day, so a test can move to tomorrow.
function date(fmt, t)
    if fmt == "%Y-%m-%d" and MOCK.today and t == nil then return MOCK.today end
    return os.date(fmt, t)
end
MOCK.played = {}
MOCK.spoken = {}
MOCK.soundFiles = {}
function GetTime() return MOCK.now end
function issecretvalue(v) return v == MOCK.SECRET end
MOCK.SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
function canaccessvalue(v) return v ~= MOCK.SECRET end
function CopyTable(t)
    local c = {}
    for k, v in pairs(t) do c[k] = type(v) == "table" and CopyTable(v) or v end
    return c
end
function Mixin(obj, ...)
    for i = 1, select("#", ...) do
        for k, v in pairs((select(i, ...))) do obj[k] = v end
    end
    return obj
end
function CreateFromMixins(...) return Mixin({}, ...) end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function hooksecurefunc(name, fn)
    local original = _G[name]
    _G[name] = function(...)
        local results = { original(...) }
        fn(...)
        return unpack(results)
    end
end
function DoEmote(token, target) MOCK.lastEmote = token end

-- Timers ---------------------------------------------------------------------------

local function Schedule(delay, fn, repeating)
    local t = { at = MOCK.now + delay, fn = fn, delay = delay, repeating = repeating }
    function t:Cancel() self.canceled = true end
    function t:IsCancelled() return self.canceled end
    MOCK.timers[#MOCK.timers + 1] = t
    return t
end
C_Timer = {
    After = function(delay, fn) Schedule(delay, fn) end,
    NewTimer = function(delay, fn) return Schedule(delay, fn) end,
    NewTicker = function(delay, fn) return Schedule(delay, fn, true) end,
}
local function RunTimers(stop)
    while true do
        local nextTimer
        for _, t in ipairs(MOCK.timers) do
            if not t.canceled and not t.done and t.at <= stop and (not nextTimer or t.at < nextTimer.at) then
                nextTimer = t
            end
        end
        if not nextTimer then break end
        MOCK.now = nextTimer.at
        if nextTimer.repeating then
            nextTimer.at = nextTimer.at + nextTimer.delay
        else
            nextTimer.done = true
        end
        local ok, err = pcall(nextTimer.fn, nextTimer)
        if not ok then Record(err) end
    end
    MOCK.now = stop
end

-- Time passes in frames of a tenth of a second: timers run as they come
-- due, and every visible frame with an OnUpdate script gets it.
local FRAME_TIME = 0.1
function MOCK.Advance(seconds)
    local stop = MOCK.now + seconds
    while MOCK.now < stop do
        local step = math.min(FRAME_TIME, stop - MOCK.now)
        RunTimers(MOCK.now + step)
        for _, f in ipairs(MOCK.frames) do
            local fn = f.__scripts and f.__scripts.OnUpdate
            if fn and f:IsVisible() then
                local ok, err = pcall(fn, f, step)
                if not ok then Record(err) end
            end
        end
    end
    MOCK.now = stop
end

-- Frames ------------------------------------------------------------------------------

local Methods = {}
local function Noop() return nil end
-- A real frame answers its widget methods and nothing else: a field it was
-- never given (page.LeftInset before the list builds it) is nil. So only
-- names the client documents as widget methods resolve here; anything else
-- is nil and recorded, in case it was meant as a method.
local FrameMT = {
    __index = function(f, k)
        if type(k) ~= "string" then return nil end
        if Methods[k] then
            MOCK.methods[k] = true
            return Methods[k]
        end
        if BLIZZARD.widgetMethods[k] or MOCK.extraMethods[k] then
            MOCK.methods[k] = true
            return Noop
        end
        if k:match("^%u") then MOCK.fieldMisses[k] = true end
        return nil
    end,
}
MOCK.fieldMisses = {}
-- GameTooltip's own methods, which the generated widget list lacks.
MOCK.extraMethods = {
    SetOwner = true, AddLine = true, AddDoubleLine = true, ClearLines = true, NumLines = true,
    SetText = true,
    -- ScrollingMessageFrame is built on a Lua mixin (Blizzard_SharedXML/
    -- ScrollingMessageFrame.lua), so its methods are not C widget methods.
    AddMessage = true, Clear = true, ScrollToTop = true, ScrollToBottom = true, ScrollUp = true,
    ScrollDown = true, SetMaxLines = true, SetFading = true, SetInsertMode = true,
}

local NewFrame

local function Child(f, key, kind, template)
    local c = NewFrame(kind or "Frame", nil, f, template)
    rawset(f, key, c)
    return c
end

-- Fields and mixin methods the templates the addon uses give a frame.
local Templates = {}
Templates.PortraitFrameTemplate = function(f)
    Child(f, "CloseButton", "Button")
    Child(f, "Bg", "Texture")
    Child(f, "NineSlice", "Frame")
    rawset(f, "SetTitle", function(self, t) self.__title = t end)
    rawset(f, "SetPortraitToAsset", function(self, a) self.__portrait = a end)
end
Templates.LargeSideTabButtonTemplate = function(f)
    Child(f, "Icon", "Texture")
    Child(f, "Background", "Texture")
    Child(f, "SelectedTexture", "Texture")
    rawset(f, "SetFillToInterior", function(self, fill, extent) self.__fill = { fill, extent } end)
    rawset(f, "SetCustomOnMouseUpHandler", function(self, fn) self.__mouseUp = fn end)
    rawset(f, "SetChecked", function(self, checked)
        self.__checked = checked
        self.SelectedTexture:SetShown(checked)
    end)
end
Templates.SearchBoxTemplate = function(f)
    Child(f, "Instructions", "FontString")
end
Templates.UICheckButtonTemplate = function(f) Child(f, "Text", "FontString") end
Templates.InsetFrameTemplate = function(f) Child(f, "Bg", "Texture") end
Templates.InsetFrameTemplate3 = Templates.InsetFrameTemplate
Templates.TooltipBackdropTemplate = function(f)
    rawset(f, "SetBackdropColor", function(self, ...) self.__backdrop = { ... } end)
    rawset(f, "SetBackdropBorderColor", function() end)
end
Templates.WowStyle1DropdownTemplate = function(f)
    rawset(f, "SetupMenu", function(self, gen) self.__menu = gen end)
    rawset(f, "GenerateMenu", function(self) self.__generated = (self.__generated or 0) + 1 end)
    rawset(f, "SetDefaultText", function() end)
end
MinimalSliderWithSteppersMixin = {
    Event = { OnValueChanged = "OnValueChanged" },
    Label = { Left = 1, Right = 2, Top = 3, Min = 4, Max = 5 },
}
Templates.MinimalSliderWithSteppersTemplate = function(f)
    rawset(f, "Init", function(self, value, minValue, maxValue, steps, formatters)
        self.__value, self.__min, self.__max, self.__formatters = value, minValue, maxValue, formatters
    end)
    rawset(f, "RegisterCallback", function(self, event, fn, owner) self.__onChange = fn end)
    rawset(f, "SetValue", function(self, value)
        self.__value = value
        if self.__onChange then self.__onChange(self, value) end
    end)
    rawset(f, "GetValue", function(self) return self.__value end)
end
Templates.WowStyle1FilterDropdownTemplate = function(f)
    Child(f, "ResetButton", "Button")
    rawset(f, "SetupMenu", function(self, gen) self.__menu = gen end)
    rawset(f, "SetIsDefaultCallback", function(self, fn) self.__isDefault = fn end)
    rawset(f, "SetDefaultCallback", function(self, fn) self.__default = fn end)
    rawset(f, "SetUpdateCallback", function(self, fn) self.__update = fn end)
    rawset(f, "ValidateResetState", function() end)
end
ColoredProgressBarMixin = { ColorType = { Red = 1, Green = 2, Blue = 3, White = 4 } }
Templates.ColoredProgressBarTemplate = function(f)
    Child(f, "Text", "FontString")
    Child(f, "Fill", "Texture")
    rawset(f, "SetFillPercent", function(self, p) self.__percent = p end)
    rawset(f, "SetFillTextureByColorType", function(self, c) self.__color = c end)
    rawset(f, "SetText", function(self, t) self.Text:SetText(t) end)
end
-- Blizzard_ChatBubble/ChatBubbleTemplates.xml: a String and a Tail.
Templates.ChatBubbleTemplate = function(f)
    Child(f, "String", "FontString")
    Child(f, "Tail", "Texture")
end

-- ScrollBarMixin's methods (Blizzard_SharedXML/Shared/Scroll/ScrollBar.lua).
Templates.MinimalScrollBar = function(bar)
    for _, k in ipairs({ "SetHideIfUnscrollable", "RegisterCallback", "SetScrollPercentage",
        "SetVisibleExtentPercentage", "SetPanExtentPercentage", "ScrollStepInDirection" }) do
        rawset(bar, k, function() end)
    end
end

Templates.WowScrollBoxList = function(sb)
    rawset(sb, "__pool", {})
    rawset(sb, "SetDataProvider", function(self, dp)
        self.__dp = dp
        if self.__selection then self.__selection.selected = nil end
        self.__frames = {}
        local view = self.__view
        assert(view, "A view is required")
        assert(view.__init or view.__factory, "elementFactory was nil")
        assert(view.__extent or view.__extentCalc, "GetTemplateExtent: Failed to obtain template info")
        -- Frames are pooled per frame type, as the real view pools per template.
        local used = {}
        for _, data in ipairs(dp.items) do
            local kind, init = view.__type, view.__init
            if view.__factory then
                view.__factory(function(k, i) kind, init = k, i end, data)
            end
            self.__pool[kind] = self.__pool[kind] or {}
            used[kind] = (used[kind] or 0) + 1
            local row = self.__pool[kind][used[kind]] or NewFrame(kind, nil, self)
            self.__pool[kind][used[kind]] = row
            rawset(row, "GetElementData", function() return data end)
            self.__frames[data] = row
            init(row, data)
        end
    end)
    rawset(sb, "GetDataProvider", function(self) return self.__dp end)
    rawset(sb, "FindFrame", function(self, data) return self.__frames and self.__frames[data] end)
    rawset(sb, "FindElementDataByPredicate", function(self, pred)
        assert(self.__dp, "no data provider")
        for _, d in ipairs(self.__dp.items) do if pred(d) then return d end end
    end)
    rawset(sb, "ScrollToElementDataByPredicate", function() end)
    rawset(sb, "ReinitializeFrames", function() end)
end

function NewFrame(kind, name, parent, template)
    local f = setmetatable({ __kind = kind, __scripts = {}, __shown = true, __points = {},
        __parent = parent, __template = template }, FrameMT)
    MOCK.frames[#MOCK.frames + 1] = f
    if name then _G[name] = f end
    if template then
        for t in template:gmatch("[^,%s]+") do
            MOCK.templates[t] = true
            if Templates[t] then Templates[t](f) end
        end
    end
    return f
end

function CreateFrame(kind, name, parent, template)
    MOCK.frameTypes[kind] = true
    return NewFrame(kind, name, parent, template)
end

local function Fire(f, script, ...)
    local fn = f.__scripts[script]
    if fn then
        local ok, err = pcall(fn, f, ...)
        if not ok then Record(err) end
    end
end
MOCK.Fire = Fire

function Methods:SetScript(script, fn) self.__scripts[script] = fn end
function Methods:GetScript(script) return self.__scripts[script] end
function Methods:HookScript(script, fn)
    local old = self.__scripts[script]
    self.__scripts[script] = function(...)
        if old then old(...) end
        fn(...)
    end
end
function Methods:Show()
    if not self.__shown then
        self.__shown = true
        Fire(self, "OnShow")
    end
end
function Methods:Hide()
    if self.__shown then
        self.__shown = false
        Fire(self, "OnHide")
    end
end
function Methods:SetShown(v) if v then self:Show() else self:Hide() end end
function Methods:IsShown() return self.__shown end
function Methods:IsVisible()
    local f = self
    while f do
        if not f.__shown then return false end
        f = f.__parent
    end
    return true
end
function Methods:SetText(t) self.__text = t end
function Methods:GetText() return self.__text end
function Methods:SetFormattedText(fmt, ...) self.__text = fmt:format(...) end
function Methods:SetPoint(...) self.__points[#self.__points + 1] = { ... } end
function Methods:ClearAllPoints() self.__points = {} end
function Methods:GetPoint(i)
    local p = self.__points[i or 1]
    if not p then return nil end
    return p[1], p[2], p[3] or p[1], p[4] or 0, p[5] or 0
end
function Methods:GetParent() return self.__parent end
function Methods:GetFrameLevel() return 1 end
function Methods:GetWidth() return 100 end
function Methods:GetHeight() return 100 end
function Methods:IsMouseOver() return true end
function Methods:GetName() return nil end
function Methods:RegisterEvent(event)
    MOCK.events[event] = true
    self.__events = self.__events or {}
    self.__events[event] = true
end
function Methods:UnregisterEvent(event) if self.__events then self.__events[event] = nil end end
function Methods:RegisterUnitEvent(event) Methods.RegisterEvent(self, event) end
function Methods:SetModelByUnit(unit)
    MOCK.modelByUnit = (MOCK.modelByUnit or 0) + 1
    self.__boxHeight = MOCK.model.playerHeight
end
function Methods:SetModelByCreatureDisplayID(display)
    self.__display, self.__boxHeight = display, MOCK.model.heights[display]
end
-- A ModelScene's camera, and where it draws a point: the field of view
-- spans the frame's width, as on a frame twice as wide as it is tall (the
-- mock's 100x100 frames), so a camera aimed by height alone draws the
-- model twice too big, and the stage has to see that and correct it.
function Methods:SetCameraFieldOfView(fov) self.__fov = fov end
function Methods:SetCameraPosition(x, y, z) self.__cam = { x, y, z } end
function Methods:GetEffectiveScale() return 1 end
function Methods:Project3DPointTo2D(x, y, z)
    local cam, fov = self.__cam, self.__fov
    if not (cam and fov) then return nil end
    local width, height = 2 * self:GetHeight(), self:GetHeight()
    local d = cam[1] - x
    local perUnit = (width / 2) / (d * math.tan(fov / 2))
    return width / 2 + y * perUnit, height / 2 + (z - cam[3]) * perUnit, d
end
-- An actor's box, once it has a model of known height: feet at 0.
function Methods:GetActiveBoundingBox()
    local h = self.__boxHeight
    if not h then return nil end
    return -0.3, -0.3, 0, 0.3, 0.3, h
end
function Methods:CreateTexture() return NewFrame("Texture", nil, self) end
function Methods:CreateMaskTexture() return NewFrame("MaskTexture", nil, self) end
function Methods:CreateFontString(name, layer, font)
    if font then MOCK.fonts[font] = true end
    return NewFrame("FontString", name, self)
end
function Methods:SetFontObject(font)
    if type(font) == "string" then MOCK.fonts[font] = true end
end
function Methods:CreateAnimationGroup() return NewFrame("AnimationGroup", nil, self) end
function Methods:CreateAnimation(kind) return NewFrame(kind or "Animation", nil, self) end
function Methods:GetChecked() return self.__checked end
function Methods:SetChecked(v) self.__checked = v end
function Methods:SetEnabled(v) self.__enabled = v end
function Methods:IsEnabled() return self.__enabled ~= false end
function Methods:GetElementData() return nil end
-- Models
function Methods:SetCreature(npcID, displayID)
    local calls = MOCK.model.setCreature
    calls[#calls + 1] = { npcID, displayID }
    self.__npc = npcID
end
function Methods:GetDisplayInfo() return MOCK.model.displays[self.__npc] or 0 end
function Methods:HasAnimation(id)
    local anims = MOCK.model.anims[self.__npc]
    return anims ~= nil and anims[id] == true
end
function Methods:ClearModel() self.__npc, self.__display, self.__boxHeight = nil, nil, nil end
function Methods:CreateActor() return NewFrame("ModelSceneActor", nil, self) end
-- Text and scroll frames: about 14 units a line, 90 characters a line.
function Methods:GetStringHeight()
    local text = self.__text or ""
    if text == "" then return 0 end
    local lines = 0
    for line in (text .. "\n"):gmatch("(.-)\n") do lines = lines + 1 + math.floor(#line / 90) end
    return lines * 14
end
function Methods:SetScrollChild(child) self.__scrollChild = child end
function Methods:GetVerticalScroll() return self.__vscroll or 0 end
function Methods:SetVerticalScroll(v) self.__vscroll = v end
function Methods:GetVerticalScrollRange() return 0 end
function Methods:SetAnimation(id) self.__anim = id end
-- Alpha, and animation groups that finish half a second after they play.
function Methods:SetAlpha(a) self.__alpha = a end
function Methods:SetScale(s) self.__scale = s end
function Methods:GetCenter() return 500, 300 end
function Methods:SetSize(w, h) self.__w, self.__h = w, h end
function Methods:SetClampedToScreen(v) self.__clamped = v end
function Methods:GetScale() return self.__scale or 1 end
function Methods:GetAlpha() return self.__alpha or 1 end
function Methods:SetFromAlpha(a) self.__fromAlpha = a end
function Methods:SetToAlpha(a) self.__toAlpha = a end
function Methods:GetToAlpha() return self.__toAlpha end
function Methods:Play()
    if self.__kind ~= "AnimationGroup" then return end
    self.__playToken = (self.__playToken or 0) + 1
    local token = self.__playToken
    C_Timer.After(0.5, function()
        if self.__playToken == token then MOCK.Fire(self, "OnFinished") end
    end)
end
function Methods:Stop() self.__playToken = (self.__playToken or 0) + 1 end

UIParent = NewFrame("Frame", "UIParent")
WorldFrame = NewFrame("Frame", "WorldFrame")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
function GetAppropriateTooltip() return GameTooltip end
for _, name in ipairs({ "GameTooltip_SetTitle", "GameTooltip_AddNormalLine",
    "GameTooltip_AddHighlightLine", "GameTooltip_AddColoredLine", "GameTooltip_AddBlankLineToTooltip",
    "GameTooltip_AddInstructionLine", "GameTooltip_AddErrorLine", "GameTooltip_Hide" }) do
    _G[name] = function() end
end
UISpecialFrames = {}
SlashCmdList = {}
function GetCursorPosition() return 0, 0 end
function PlaySound(kit) MOCK.played[#MOCK.played + 1] = kit end
function PlaySoundFile(path, channel)
    MOCK.soundFiles[#MOCK.soundFiles + 1] = path
    return true, #MOCK.soundFiles
end
function StopSound(handle) MOCK.stopped = handle end
SOUNDKIT = setmetatable({}, { __index = function(_, k) MOCK.sounds[k] = true return k end })
GREEN_FONT_COLOR = CreateColor(0.1, 1, 0.1)
function SetPortraitTextureFromCreatureDisplayID() end

-- Scroll lists, selection and menus ---------------------------------------------------

function CreateDataProvider(items) return { items = items or {} } end
ScrollBoxConstants = { RetainScrollPosition = true, DiscardScrollPosition = false, AlignNearest = 1 }
SelectionBehaviorMixin = { Event = { OnSelectionChanged = "OnSelectionChanged" } }
function CreateScrollBoxListLinearView()
    local view = {}
    function view:SetElementInitializer(kind, fn) self.__type, self.__init = kind, fn end
    function view:SetElementExtent(n) self.__extent = n end
    function view:SetElementFactory(fn) self.__factory = fn end
    function view:SetElementExtentCalculator(fn) self.__extentCalc = fn end
    function view:SetPadding() end
    return view
end
ScrollUtil = {}
function ScrollUtil.InitScrollBoxListWithScrollBar(sb, bar, view) sb.__view = view end
function ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, bar)
    assert(bar.SetHideIfUnscrollable, "not a scroll bar")
    rawset(scrollFrame, "__bar", bar)
    scrollFrame:SetScript("OnMouseWheel", function() end)
end
function ScrollUtil.AddSelectionBehavior(sb)
    local sel = { callbacks = {} }
    rawset(sb, "__selection", sel)
    local function FireSel(data, selected)
        for _, c in ipairs(sel.callbacks) do c.fn(c.owner, data, selected) end
    end
    function sel:RegisterCallback(event, fn, owner)
        self.callbacks[#self.callbacks + 1] = { fn = fn, owner = owner }
    end
    function sel:SelectElementData(data)
        if self.selected == data then return end
        local old = self.selected
        self.selected = data
        if old then FireSel(old, false) end
        FireSel(data, true)
    end
    function sel:IsElementDataSelected(d) return self.selected == d end
    function sel:HasSelection() return self.selected ~= nil end
    function sel:SelectElementDataByPredicate(pred)
        local d = sb:FindElementDataByPredicate(pred)
        if d then self:SelectElementData(d) end
        return d
    end
    function sel:SelectFirstElementData(pred)
        for _, d in ipairs(sb.__dp and sb.__dp.items or {}) do
            if not pred or pred(d) then
                self:SelectElementData(d)
                return d
            end
        end
    end
    function sel:Select(frame) self:SelectElementData(frame:GetElementData()) end
    return sel
end

MenuResponse = { Open = 1, Refresh = 2, Close = 3, CloseAll = 4 }
local function NewDescription(text, kind, a, b, c)
    local d = { text = text, kind = kind, a = a, b = b, data = c, children = {} }
    local function add(child) d.children[#d.children + 1] = child return child end
    function d:CreateCheckbox(t, isSel, set, data) return add(NewDescription(t, "checkbox", isSel, set, data)) end
    function d:CreateRadio(t, isSel, set, data) return add(NewDescription(t, "radio", isSel, set, data)) end
    function d:CreateButton(t, fn, data) return add(NewDescription(t, "button", fn, nil, data)) end
    function d:CreateTitle(t) return add(NewDescription(t, "title")) end
    function d:CreateDivider() return add(NewDescription(nil, "divider")) end
    function d:CreateSpacer() return add(NewDescription(nil, "spacer")) end
    function d:SetTag(tag) self.tag = tag end
    function d:SetEnabled(v) self.enabled = v end
    function d:SetScrollMode() end
    return d
end
function MOCK.RunMenu(generator, owner)
    local root = NewDescription(nil, "root")
    generator(owner, root)
    return root
end
-- Walks a menu, calling every getter and setter (checkboxes, radios, buttons).
function MOCK.ClickEverything(desc)
    for _, child in ipairs(desc.children) do
        if child.kind == "checkbox" or child.kind == "radio" then
            child.a(child.data)
            child.b(child.data)
            child.b(child.data)
        elseif child.kind == "button" and child.a then
            child.a(child.data)
        end
        MOCK.ClickEverything(child)
    end
end
MenuUtil = {}
function MenuUtil.CreateContextMenu(owner, generator)
    MOCK.lastContextMenu = MOCK.RunMenu(generator, owner)
end

-- Event bus ----------------------------------------------------------------------------

CallbackRegistryMixin = {}
function CallbackRegistryMixin:OnLoad() self.__callbacks = {} end
function CallbackRegistryMixin:GenerateCallbackEvents(events)
    self.Event = self.Event or {}
    for _, e in ipairs(events) do self.Event[e] = e end
end
function CallbackRegistryMixin:RegisterCallback(event, fn, owner)
    assert(self.Event[event], "undeclared event " .. tostring(event))
    assert(type(owner) ~= "number", "numeric owner")
    self.__callbacks[event] = self.__callbacks[event] or {}
    self.__callbacks[event][owner or fn] = fn
end
function CallbackRegistryMixin:UnregisterCallback(event, owner)
    if self.__callbacks[event] then self.__callbacks[event][owner] = nil end
end
function CallbackRegistryMixin:TriggerEvent(event, ...)
    assert(self.Event[event], "undeclared event " .. tostring(event))
    for owner, fn in pairs(self.__callbacks[event] or {}) do fn(owner, ...) end
end

-- Client API ---------------------------------------------------------------------------

C_AddOns = { GetAddOnMetadata = function() return "001" end }
C_CVar = {
    GetCVar = function(n) return MOCK.cvars[n] end,
    SetCVar = function(n, v) MOCK.cvars[n] = tostring(v) return true end,
}
C_Texture = { GetAtlasInfo = function(name) return { file = 1, width = 16, height = 16 } end }
C_XMLUtil = { GetTemplateInfo = function(name) return BLIZZARD.templates[name] and {} or nil end }
C_Map = {
    GetBestMapForUnit = function() return 1455 end,
    GetPlayerMapPosition = function(mapID, unit)
        if not MOCK.position then return nil end
        local x, y = MOCK.position[1], MOCK.position[2]
        return { GetXY = function() return x, y end }
    end,
    CanSetUserWaypointOnMap = function(mapID) return mapID ~= 0 end,
    SetUserWaypoint = function(point) MOCK.userWaypoint = point end,
}
UiMapPoint = { CreateFromCoordinates = function(mapID, x, y) return { uiMapID = mapID, x = x, y = y } end }
C_SuperTrack = { SetSuperTrackedUserWaypoint = function(v) MOCK.superTracked = v end }
C_Item = { GetItemQualityColor = function() return 1, 1, 1 end }
ColorManager = { GetColorDataForItemQuality = function(q) return { r = 1, g = 1, b = 1, color = CreateColor(1, 1, 1) } end }
C_RestrictedActions = { IsAddOnRestrictionActive = function() return false end }
C_Secrets = { ShouldUnitIdentityBeSecret = function() return false end }
Enum = { AddOnRestrictionType = { Combat = 0, Map = 1 } }
C_TooltipInfo = {
    GetUnit = function(unit)
        local u = MOCK.units[unit]
        if not u then return nil end
        local lines = { { leftText = u.name } }
        for _, line in ipairs(u.tip or {}) do lines[#lines + 1] = { leftText = line } end
        return { lines = lines }
    end,
}

function InCombatLockdown() return MOCK.combat end
function GetZoneText() return MOCK.zone or "Ironforge" end
function IsResting() return MOCK.resting or false end
C_VoiceChat = {
    GetTtsVoices = function() return { { voiceID = 3, name = "Fred" }, { voiceID = 7, name = "Grandpa" } } end,
    SpeakText = function(voiceID, text, rate, volume, overlap)
        MOCK.spoken[#MOCK.spoken + 1] = { voiceID = voiceID, text = text }
    end,
    StopSpeakingText = function() end,
}
C_TTSSettings = { GetSpeechVolume = function() return 80 end }
function GetSubZoneText() return MOCK.subzone or "The Great Forge" end

local function U(unit, field)
    local u = MOCK.units[unit]
    return u and u[field]
end
function UnitExists(unit) return MOCK.units[unit] ~= nil end
function UnitIsPlayer(unit) return U(unit, "player") or false end
function UnitIsAFK(unit) return U(unit, "afk") or false end
function UnitHealth(unit) return U(unit, "health") or 100 end
function UnitHealthMax(unit) return U(unit, "healthMax") or 100 end
function UnitIsGhost(unit) return U(unit, "ghost") or false end
function UnitIsDead(unit) return U(unit, "dead") or false end
function UnitPlayerControlled(unit) return U(unit, "controlled") or false end
function UnitIsVisible(unit) return MOCK.units[unit] ~= nil end
function UnitGUID(unit) return U(unit, "guid") end
function UnitCreatureID(unit) return U(unit, "npcID") end
function UnitName(unit) return U(unit, "name") end
function UnitCreatureType(unit) return U(unit, "type"), U(unit, "typeID") end
function UnitCreatureFamily(unit) return U(unit, "family") end
function UnitClassification(unit) return U(unit, "class") or "normal" end
function UnitLevel(unit) return U(unit, "level") or 1 end
function UnitSex(unit) return U(unit, "sex") or 2 end
function UnitReaction(unit) return U(unit, "reaction") or 5 end
function UnitRace(unit) if unit == "player" then return "Human", "Human" end return nil end
function UnitClass(unit)
    if unit == "player" then return "Mage", "MAGE" end
    return nil
end
function UnitOnTaxi() return MOCK.onTaxi or false end
function IsMounted() return MOCK.mounted or false end
function IsInInstance() return MOCK.instance ~= nil, MOCK.instance or "none" end
function GetMaxPlayerLevel() return 60 end
function GetLocale() return "enUS" end
function HasNewMail() return MOCK.mail or false end
LOOT_ITEM_SELF = "You receive loot: %s."
ERR_INV_FULL = "Inventory is full."
function UnitFactionGroup(unit) return U(unit, "faction") end
function UnitCanAttack(_, unit) return U(unit, "attackable") or false end
