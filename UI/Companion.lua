-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/Companion.lua: the buddy on screen (ns.Companion). A little gnome in
-- the player's armor standing on the screen, BonziBuddy style: drag it
-- anywhere, click to poke it, right-click for its menu. It talks in a chat
-- bubble, the words fading in like quest text, and in its own recorded
-- voice when the BuddyDex Voice addon is installed (Core/Voice.lua). Core/Reactions.lua decides what it
-- says and when; this file draws it, animates it, picks its lines and
-- applies the buddy options.
--
-- A friend at Buddy tier or better can come along instead (Companion.SetBuddy):
-- the NPC stands in the Mini Me's place, drawn the way the BuddyDex draws
-- it, and speaks its own lines from Data/Lore.lua mixed with the general NPC
-- lines (Data/NpcLines.lua).
--
-- Lines are drawn like cards (Draw): a shuffled deck per moment, so none
-- comes back until the rest of the pile has been said, and the last few of
-- each moment are remembered between sessions (BuddyDexCharDB.recentLines).
-- Animations never repeat back to back either.
--
-- Options (BuddyDexDB.settings, defaults in Core/Database.lua): companion,
-- voiceMode ("recorded" or "off"), echoChat, combat, hideInInstances, locked, clickThrough,
-- scale, alpha, facing, hideWeapons. Per character (BuddyDexCharDB):
-- companionPoint, companionNpc (the friend who came along; nil for the
-- Mini Me), recentLines.

local Companion = {}
ns.Companion = Companion

local Util = ns.Util

-- The frame is wider than the buddy, so arms flung out (a flex, a cheer, a
-- swing) stay in view; only the middle, BODY_WIDTH wide, answers the mouse.
local WIDTH, HEIGHT = 250, 190
local BODY_WIDTH = 80
local LEGACY_WIDTH = 150          -- the frame's width before, for positions saved then
local DEFAULT_POINT = { "BOTTOMRIGHT", "BOTTOMRIGHT", -250, 170 }
local TURN = math.rad(20)         -- the turn toward the middle of the screen
local FADE = 0.4                  -- in and out, for combat and for showing up
local FOOT_ROOM = 0.08            -- of the frame's height, empty under the model's feet
local FEET_AT = 0.1 / 1.2         -- where the feet are, up the frame (the stage's body framing)
local GNOME_HEIGHT = 1.0          -- yards: the Mini Me's height until it has been measured

local BUBBLE_GAP = 26             -- between the head and the bubble's text
local BUBBLE_MAX_WIDTH = 230
local TAIL_OVERLAP = 6            -- how far the tail reaches up over the bubble's bottom border (tuned by eye in game)
local tailOverlap = TAIL_OVERLAP   -- /bd tail changes it for the session, to tune by eye
local REVEAL_SPEED = 40           -- characters a second as the words fade in
local REVEAL_SOFTNESS = 6         -- how many characters the fade spans
local HOLD_BASE, HOLD_PER_CHAR = 2.5, 0.05   -- reading time once it is all shown

local ANIM_TIME = 2.6             -- an emote plays this long, then it stands again
local TALK, STAND, WAVE = 60, 0, 67
local POKE_MOVES = { 70, 68, 83, 82, 84, 67, 66, 113, 80 }
local POKE_MANY, POKE_WINDOW = 4, 6   -- this many pokes this fast is too many
local RECENT_KEEP = 4             -- lines per moment remembered between sessions

-- A moment with no lines of its own borrows another's.
local ALIASES = {
    greetMorning = "greet", greetAfternoon = "greet", greetEvening = "greet", greetNight = "greet",
    reload = "greet", pokeMany = "poke", maxLevel = "levelUp",
}

local frame, scene, bubble, fallback
local npcScene                    -- the friend who came along, on a stage like the Mini Me's
local npcModel                    -- or drawn the Dex's way, for a friend whose display isn't known yet
local buddyID                     -- their NPC ID; nil while the Mini Me is out
local ApplyBuddy                  -- (below) shows whoever should be out
local animTimer, holdTimer
local pendingAnim                 -- asked for before the model had loaded
local lastAnim
local inCombat, hiddenForCombat, hiddenForInstance = false, false, false
local decks = {}
local pokes = {}
local sessionStart = GetTime()

local function Settings()
    return ns.db and ns.db.settings or {}
end

local function Cancel(timer)
    if timer then timer:Cancel() end
end

local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit) end
end

local function Clamp(v, low, high, default)
    v = tonumber(v)
    if not v then return default end
    return math.max(low, math.min(high, v))
end

-- Animation ------------------------------------------------------------------------

-- Whether the friend who came along has a move, from the moves the
-- BuddyDex found on their model (an empty list: none of them). While it
-- hasn't looked, the model's own fallbacks are trusted.
local function HasMove(id)
    local entry = buddyID and ns.Database and ns.Database.GetEntry(buddyID)
    local moves = entry and entry.moves
    if type(moves) ~= "table" or id == STAND then return true end
    for _, move in ipairs(moves) do
        if move == id then return true end
    end
    return false
end

local function SetAnimation(id)
    if buddyID and npcScene and npcScene:IsShown() then
        -- A friend plays only what its model has, else talks, else stands.
        if not npcScene.loaded then
            pendingAnim = id
            return
        end
        if not HasMove(id) then id = HasMove(TALK) and TALK or STAND end
        pcall(npcScene.actor.SetAnimation, npcScene.actor, id)
        return
    end
    if buddyID then
        local model = npcModel
        if not model then return end
        if not model.loaded then
            pendingAnim = id
            return
        end
        if id ~= STAND and Util.Read(model.HasAnimation, model, id) ~= true then
            id = Util.Read(model.HasAnimation, model, TALK) == true and TALK or STAND
        end
        pcall(model.SetAnimation, model, id)
        return
    end
    local actor = scene and scene.actor
    if not actor then return end
    if scene.loaded then
        pcall(actor.SetAnimation, actor, id)
    else
        pendingAnim = id
    end
end

-- Plays an animation for a while (ANIM_TIME unless told), then stands.
-- "hold" keeps it until something else plays (sleeping while away).
function Companion.Play(id, duration)
    Cancel(animTimer)
    animTimer = nil
    if id ~= STAND then lastAnim = id end
    SetAnimation(id)
    if duration ~= "hold" then
        animTimer = C_Timer.NewTimer(duration or ANIM_TIME, function() SetAnimation(STAND) end)
    end
end

-- One animation from a list, never the last one played if there's a choice.
function Companion.PickAnim(anims)
    if type(anims) ~= "table" then return anims end
    if #anims <= 1 then return anims[1] end
    local id
    repeat id = anims[math.random(#anims)] until id ~= lastAnim
    return id
end

-- Turns to face the way the options say: toward the middle of the screen
-- from whichever side it stands on, left, right, or straight out.
local function Face()
    if not frame then return end
    local facing, yaw = Settings().facing, 0
    if facing == "left" then
        yaw = -TURN
    elseif facing == "right" then
        yaw = TURN
    elseif facing ~= "front" then
        local x = Util.Plain(frame:GetCenter())
        local width = Util.Plain(UIParent:GetWidth())
        if type(x) == "number" and type(width) == "number" then yaw = x > width / 2 and -TURN or TURN end
    end
    if buddyID and npcScene and npcScene:IsShown() then
        pcall(npcScene.actor.SetYaw, npcScene.actor, yaw)
    elseif buddyID and npcModel then
        pcall(npcModel.SetFacing, npcModel, yaw)
    elseif scene and scene.actor then
        pcall(scene.actor.SetYaw, scene.actor, yaw)
    end
end

-- The speech bubble ---------------------------------------------------------------

local function HideBubble()
    Cancel(holdTimer)
    holdTimer = nil
    if bubble then
        bubble:SetScript("OnUpdate", nil)
        bubble.FadeOut:Stop()
        bubble:Hide()
    end
end

-- Fades the words in from left to right, like quest text.
local function Reveal(self, elapsed)
    self.progress = self.progress + elapsed * REVEAL_SPEED
    if not self.String:SetAlphaGradient(self.progress, REVEAL_SOFTNESS) then
        self:SetScript("OnUpdate", nil)
        holdTimer = C_Timer.NewTimer(HOLD_BASE + #self.text * HOLD_PER_CHAR, function()
            holdTimer = nil
            self.FadeOut:Play()
        end)
    end
end

local function BuildBubble()
    local art = ns.Art or {}
    local b
    if art.HasTemplate and art.HasTemplate("ChatBubbleTemplate") then
        -- Blizzard's own chat bubble: it sizes itself around its String.
        b = CreateFrame("Frame", nil, frame, "ChatBubbleTemplate")
        if not b.String then
            b:Hide()
            b = nil
        end
    end
    if not b then
        b = art.CreateCard and art.CreateCard(frame) or CreateFrame("Frame", nil, frame)
        b.String = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        b:SetPoint("TOPLEFT", b.String, "TOPLEFT", -14, 14)
        b:SetPoint("BOTTOMRIGHT", b.String, "BOTTOMRIGHT", 14, -14)
    end
    b.String:ClearAllPoints()
    b.String:SetPoint("BOTTOM", frame, "TOP", 0, BUBBLE_GAP)
    b.String:SetJustifyH("LEFT")
    b.String:SetJustifyV("TOP")
    b.String:SetWordWrap(true)
    pcall(b.String.SetMaxLines, b.String, 0)
    b.String:SetTextColor(1, 1, 1)
    -- The tail's art has blank space at its top and is drawn over the
    -- border (ARTWORK above the NineSlice), so it reaches up across the
    -- bottom edge and the outline opens into it, as the game's own bubbles do.
    if b.Tail then
        b.Tail:ClearAllPoints()
        b.Tail:SetPoint("TOP", b, "BOTTOM", 0, tailOverlap)
    end
    -- The words stay readable whatever size and see-through the buddy is.
    pcall(b.SetIgnoreParentAlpha, b, true)
    pcall(b.SetIgnoreParentScale, b, true)
    b:SetFrameLevel(frame:GetFrameLevel() + 10)
    b:Hide()

    local fade = b:CreateAnimationGroup()
    local alpha = fade:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0)
    alpha:SetDuration(0.35)
    fade:SetScript("OnFinished", function() b:Hide() end)
    b.FadeOut = fade
    bubble = b
end

local function ShowBubble(text)
    if not bubble then BuildBubble() end
    HideBubble()
    local fs = bubble.String
    -- The whole line is set before it fades in, so the words never jump to
    -- the next line as they appear. Only the width is fixed: the height
    -- follows the text, however many lines it wraps to. (Measuring it here
    -- would read the text while the bubble is hidden, where the game keeps
    -- the old size, and a long line came out cut short.)
    fs:SetWidth(BUBBLE_MAX_WIDTH)
    fs:SetText(text)
    local width = tonumber(Util.Plain(fs:GetUnboundedStringWidth())) or BUBBLE_MAX_WIDTH
    fs:SetWidth(math.min(BUBBLE_MAX_WIDTH, math.ceil(width) + 2))
    fs:SetAlphaGradient(0, REVEAL_SOFTNESS)
    bubble.text, bubble.progress = text, 0
    bubble:SetAlpha(1)
    bubble:Show()
    bubble:SetScript("OnUpdate", Reveal)
end

-- Picking lines ----------------------------------------------------------------------

function Companion.TimeOfDay()
    local hour = tonumber(date("%H")) or 12
    if hour >= 5 and hour < 11 then return "morning" end
    if hour >= 11 and hour < 17 then return "afternoon" end
    if hour >= 17 and hour < 22 then return "evening" end
    return "night"
end

local function TextOf(line)
    return type(line) == "table" and line[1] or line
end

-- Whether a line suits right now (its time, zone, class, level, session).
local function Fits(line)
    if type(line) ~= "table" then return type(line) == "string" end
    if type(line[1]) ~= "string" then return false end
    if line.time and line.time ~= Companion.TimeOfDay() then return false end
    if line.zone and line.zone ~= Util.Read(GetZoneText) then return false end
    if line.class then
        local _, token = Util.Read(UnitClass, "player")
        if token ~= line.class then return false end
    end
    local level = tonumber(Util.Read(UnitLevel, "player")) or 1
    if line.min and level < line.min then return false end
    if line.max and level > line.max then return false end
    if line.after and GetTime() - sessionStart < line.after then return false end
    return true
end

-- The last few lines of a moment, kept between sessions.
local function Recent(deckKey)
    local char = ns.char
    if not char then return {} end
    if type(char.recentLines) ~= "table" then char.recentLines = {} end
    if type(char.recentLines[deckKey]) ~= "table" then char.recentLines[deckKey] = {} end
    return char.recentLines[deckKey]
end

local function Remember(deckKey, text)
    local list = Recent(deckKey)
    table.insert(list, 1, text)
    while #list > RECENT_KEEP do table.remove(list) end
end

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- A freshly shuffled deck, with whatever was said lately at the bottom.
local function NewDeck(pool, deckKey)
    local order = {}
    for i = 1, #pool do order[i] = i end
    Shuffle(order)
    local recent = {}
    for _, text in ipairs(Recent(deckKey)) do recent[text] = true end
    local fresh, stale = {}, {}
    for _, i in ipairs(order) do
        local list = recent[TextOf(pool[i])] and stale or fresh
        list[#list + 1] = i
    end
    for _, i in ipairs(stale) do fresh[#fresh + 1] = i end
    return { pool = pool, order = fresh, pos = 0 }
end

-- The next line of a pile that suits right now, or nil.
local function Draw(pool, deckKey)
    if type(pool) ~= "table" or #pool == 0 then return nil end
    local deck = decks[deckKey]
    if not deck or deck.pool ~= pool then
        deck = NewDeck(pool, deckKey)
        decks[deckKey] = deck
    end
    for _ = 1, #pool * 2 do
        deck.pos = deck.pos + 1
        if deck.pos > #deck.order then
            deck = NewDeck(pool, deckKey)
            decks[deckKey] = deck
            deck.pos = 1
        end
        local line = pool[deck.order[deck.pos]]
        if Fits(line) then
            Remember(deckKey, TextOf(line))
            return line
        end
    end
    return nil
end

local function PileFor(lines, key)
    if type(lines) ~= "table" then return nil end
    local pile = lines[key]
    if type(pile) ~= "table" and ALIASES[key] then pile = lines[ALIASES[key]] end
    return type(pile) == "table" and #pile > 0 and pile or nil
end

-- The line for a moment: the Mini Me's own, or a friend's, their own lore
-- lines mixed with the general NPC lines.
local function PickLine(key)
    if not buddyID then
        return Draw(PileFor(ns.Lines, key), "me:" .. key)
    end
    local lore = ns.Lore and ns.Lore[buddyID]
    local own = PileFor(type(lore) == "table" and lore.lines, key)
    local general = PileFor(ns.NpcLines, key)
    local first, second = own, general
    if own and general and math.random() < 0.4 then first, second = general, own end
    local prefix = buddyID .. ":" .. key
    return Draw(first, prefix .. (first == own and ":own" or ":gen"))
        or Draw(second, prefix .. (second == own and ":own" or ":gen"))
end

-- Talking -------------------------------------------------------------------------

function Companion.IsShown()
    return frame ~= nil and frame:IsShown() and not hiddenForCombat and not hiddenForInstance
end

function Companion.IsTalking()
    return bubble ~= nil and bubble:IsShown()
end

function Companion.InCombat()
    return inCombat
end

-- Fills in {name}, {zone} and the rest (Data/Lines.lua) from ctx and the game.
function Companion.Fill(text, ctx)
    ctx = ctx or {}
    return (text:gsub("{(%w+)}", function(key)
        local value = ctx[key]
        if value == nil then
            if key == "name" then value = Util.Read(UnitName, "player")
            elseif key == "zone" then value = Util.Read(GetZoneText)
            elseif key == "level" then value = Util.Read(UnitLevel, "player")
            elseif key == "class" then value = Util.Read(UnitClass, "player")
            elseif key == "race" then value = Util.Read(UnitRace, "player")
            elseif key == "friends" then value = ns.Database and ns.Database.Count and (ns.Database.Count())
            end
        end
        value = Util.Plain(value)
        return value ~= nil and tostring(value) or ("{" .. key .. "}")
    end))
end

-- The Mini Me's voice is the player's sex: 0 male, 1 female (UnitSex 2, 3).
local function MiniMeSex()
    return tonumber(Util.Read(UnitSex, "player")) == 3 and 1 or 0
end

-- What chat calls whoever is out.
local function Speaker()
    return buddyID and Companion.Name() or "Mini Me"
end

-- The display of the friend who is out, for their voice.
local function BuddyDisplay()
    local entry = buddyID and ns.Database and ns.Database.GetEntry(buddyID)
    return entry and tonumber(Util.Plain(entry.display)) or nil
end

-- Says a line: the bubble, the voice (the Mini Me's recording of the line,
-- or a friend's own sounds for the moment), chat too if the echo option is
-- on, and an animation (talking unless told; false for none). opts: line
-- (its text before fill-ins, for the recording), moment (the line's
-- moment, for a friend's sounds), combat (may speak in a fight: the
-- battle cries).
function Companion.Say(text, anim, opts)
    opts = opts or {}
    if type(text) ~= "string" or text == "" or not Companion.IsShown() then return false end
    if inCombat and not opts.combat then return false end
    ShowBubble(text)
    local voice = ns.Voice
    if voice and voice.Speak then
        if buddyID then
            local display = BuddyDisplay()
            if display then voice.Speak({ display = display, moment = opts.moment, line = opts.line }) end
        else
            voice.Speak({ line = opts.line, sex = MiniMeSex(), miniMe = true })
        end
    end
    if Settings().echoChat then
        print(("|cffffff9f%s says: %s|r"):format(Speaker(), text))
    end
    if anim ~= false then Companion.Play(anim or TALK) end
    return true
end

-- A line for a moment, filled in and said. anims: one animation or a list
-- to pick from (a line's own wins), false for none. opts as Say.
function Companion.SayLine(key, ctx, anims, opts)
    local line = PickLine(key)
    if not line then return false end
    opts = opts or {}
    local anim = anims
    if anims ~= false then
        anim = type(line) == "table" and line.anim or Companion.PickAnim(anims)
    end
    return Companion.Say(Companion.Fill(TextOf(line), ctx), anim,
        { combat = opts.combat, line = TextOf(line), moment = key })
end

-- For tuning by eye (/bd tail <n>): moves the bubble's tail and says a test
-- line, for this session only.
function Companion.SetTailOverlap(value)
    tailOverlap = value
    if bubble and bubble.Tail then
        bubble.Tail:ClearAllPoints()
        bubble.Tail:SetPoint("TOP", bubble, "BOTTOM", 0, tailOverlap)
    end
    Companion.Say(("Tail at %s. Does it join up?"):format(tostring(value)), false)
end

-- A sample of the Mini Me's voice, for the options page.
function Companion.TestVoice()
    local voice = ns.Voice
    if not (voice and voice.Test) then return end
    if not voice.HasPack() then
        ns.Print("Your Mini Me's voice comes with the BuddyDex Voice addon. Install it to hear it.")
    elseif not voice.Test(MiniMeSex()) then
        ns.Print("No recordings in this voice yet.")
    end
end

function Companion.Quiet()
    HideBubble()
    local voice = ns.Voice
    if voice and voice.Stop then voice.Stop() end
end

-- Settings ---------------------------------------------------------------------------

-- Changes a setting from here (the menu, /bd buddy) the way the options
-- page does, so its controls follow.
function Companion.SetSetting(key, value)
    if not (ns.db and ns.db.settings) then return end
    ns.db.settings[key] = value
    ns.Bus:TriggerEvent(ns.Event.SettingChanged, key, value)
end

local function OpenOptions()
    local dex = ns.Dex
    if not (dex and dex.Open) then return end
    dex.Open()
    if dex.ShowTab then dex.ShowTab(2) end
end
Companion.OpenOptions = OpenOptions

-- The menu: quick things only. The options live on the BuddyDex's Buddy tab.
local function OpenMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle(Companion.Name())
        root:CreateButton("Say something", function() Companion.SayLine("idle") end)
        root:CreateButton("Dance", function() Companion.Play(69, 6) end)
        local friends = Companion.Buddies()
        if #friends > 0 then
            local menu = root:CreateButton("Bring along")
            if menu.SetScrollMode then menu:SetScrollMode(320) end
            local function IsOut(id) return (buddyID or 0) == id end
            local function BringOut(id) Companion.SetBuddy(id ~= 0 and id or nil) end
            menu:CreateRadio("Your Mini Me", IsOut, BringOut, 0)
            for _, friend in ipairs(friends) do
                menu:CreateRadio(friend.name, IsOut, BringOut, friend.npcID)
            end
        end
        root:CreateDivider()
        -- Always on the BuddyDex tab, whichever tab it was left on.
        root:CreateButton("Open the BuddyDex", function()
            local dex = ns.Dex
            if not (dex and dex.Open) then return end
            dex.Open()
            if dex.ShowTab then dex.ShowTab(1) end
        end)
        root:CreateButton("Buddy options", OpenOptions)
        -- Locked, it can't be dragged; the options page has the same switch.
        local locked = Settings().locked == true
        root:CreateButton(locked and "Unlock" or "Lock in place", function()
            Companion.SetSetting("locked", not locked)
        end)
        root:CreateButton("Hide", function()
            Companion.SetSetting("companion", false)
            ns.Print("Your buddy is resting. Type /bd buddy to bring it back.")
        end)
    end)
end

-- The frame ----------------------------------------------------------------------------

-- Saved by its middle, so a change of size or shape never moves it.
local function SavePosition()
    if not (ns.char and frame) then return end
    local x, y = frame:GetCenter()
    x, y = Util.Plain(x), Util.Plain(y)
    if type(x) == "number" and type(y) == "number" then
        ns.char.companionPoint = { "CENTER", "BOTTOMLEFT", x, y, unscaled = true, center = true }
    end
end

local function RestorePosition()
    local saved = ns.char and ns.char.companionPoint
    local p = type(saved) == "table" and saved or DEFAULT_POINT
    local x, y = p[3], p[4]
    -- Saved while the frame was scaled (before sizes changed the frame
    -- itself): the offsets were in scaled units.
    if type(saved) == "table" and not saved.unscaled and type(x) == "number" and type(y) == "number" then
        local scale = Clamp(Settings().scale, 0.5, 2, 1)
        x, y = x * scale, y * scale
    end
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[2], x, y)
end

function Companion.ResetPosition()
    if ns.char then ns.char.companionPoint = nil end
    if not frame then return end
    RestorePosition()
    Face()
end

-- Size: the frame itself grows, not its scale. A scaled frame scales the
-- 3D model a second time, so past 100% the model outgrew its frame and was
-- cut off; a bigger frame simply frames the model bigger. It grows and
-- shrinks around its middle, so it stays where it stands.
local function Size()
    return Clamp(Settings().scale, 0.5, 2, 1)
end

-- Everyone is drawn at one scale, as in the world: the frame is the Mini
-- Me's size times the size option, and a friend's frame is as much bigger
-- as they are tall (factor: their height over the Mini Me's), so a human
-- stands twice a gnome's height. Each stage aims its camera at its own
-- model's height, so the scale comes out the same for all; the frame keeps
-- its shape, so it does whichever way the camera's field of view runs.
local function SizeFrame(size, factor)
    factor = factor or frame.factor or 1
    local width, height = WIDTH * size * factor, HEIGHT * size * factor
    frame:SetSize(width, height)
    -- Only the middle, where the buddy stands, answers the mouse, and only
    -- it is kept on screen: the empty space around it may go off the edge,
    -- the strip under its feet included (the camera leaves a twelfth of the
    -- frame below them), so it can stand on the bottom edge.
    local insetX, insetTop = (width - BODY_WIDTH * size * factor) / 2, height * 20 / HEIGHT
    frame:SetHitRectInsets(insetX, insetX, insetTop, 0)
    frame:SetClampRectInsets(insetX, -insetX, -insetTop, height * FOOT_ROOM)
    if fallback then fallback:SetSize(64 * size, 64 * size) end
    frame.size, frame.factor = size, factor
end

-- How much taller than the Mini Me a model this tall is.
local function FactorFor(height)
    local reference = ns.char and tonumber(ns.char.miniMeHeight) or GNOME_HEIGHT
    height = tonumber(height)
    if not height or reference <= 0 then return 1 end
    return math.max(0.6, math.min(3, height / reference))
end

-- A new buddy height: the frame grows or shrinks with its feet where they
-- were, so whoever comes along stands on the same spot.
local function Resize(factor)
    if not frame or (frame.factor and math.abs(factor - frame.factor) < 0.001) then return end
    local x, y = frame:GetCenter()
    x, y = Util.Plain(x), Util.Plain(y)
    local oldHeight = Util.Plain(frame:GetHeight())
    SizeFrame(Size(), factor)
    if type(x) == "number" and type(y) == "number" and type(oldHeight) == "number" then
        local feet = y - oldHeight * (0.5 - FEET_AT)
        local height = HEIGHT * Size() * factor
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, feet + height * (0.5 - FEET_AT))
        SavePosition()
    end
end

-- The size option: it grows and shrinks around its middle, so it stays where it stands.
local function ApplyScale()
    if not frame then return end
    local size = Size()
    if frame.size and math.abs(size - frame.size) < 0.001 then return end
    local x, y = frame:GetCenter()
    x, y = Util.Plain(x), Util.Plain(y)
    SizeFrame(size)
    if type(x) == "number" and type(y) == "number" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        SavePosition()
    end
end

-- The mouse: never in a fight (clicks go to whatever is behind it), never
-- with click-through on.
local function ApplyMouse()
    if not frame then return end
    frame:EnableMouse(not Settings().clickThrough and not inCombat and Companion.IsShown())
end

local function Alpha()
    return Clamp(Settings().alpha, 0.2, 1, 1)
end

local function Poke()
    PlayKit("IG_MAINMENU_OPTION_CHECKBOX_ON")
    local now = GetTime()
    pokes[#pokes + 1] = now
    while pokes[1] and now - pokes[1] > POKE_WINDOW do table.remove(pokes, 1) end
    local key = #pokes >= POKE_MANY and "pokeMany" or "poke"
    if not Companion.SayLine(key, nil, POKE_MOVES) then
        Companion.Play(Companion.PickAnim(POKE_MOVES))
    end
end

local function OnEnter(self)
    if self.dragging then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip_SetTitle(GameTooltip, Companion.Name())
    GameTooltip_AddNormalLine(GameTooltip, Settings().locked and "Click to poke. Right-click for more."
        or "Click to poke. Drag to move. Right-click for more.")
    GameTooltip:Show()
end

local function Build()
    if frame then return frame end
    frame = CreateFrame("Button", "BuddyDexCompanion", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(Settings().clampToScreen ~= false)
    frame:RegisterForDrag("LeftButton")
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetScript("OnDragStart", function(self)
        if Settings().locked then return end
        self.dragging = true
        GameTooltip:Hide()
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.dragging then return end
        self:StopMovingOrSizing()
        self.dragging = nil
        SavePosition()
        Face()
    end)
    frame:SetScript("OnClick", function(self, button)
        if button == "RightButton" then OpenMenu(self) else Poke() end
    end)
    frame:SetScript("OnEnter", OnEnter)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:Hide()
    -- Earlier versions scaled the frame; size now comes from SizeFrame.
    -- The position was saved with whoever was out, so the frame takes their
    -- size before it goes back there (a friend not out after all shrinks
    -- back with their feet in place).
    frame:SetScale(1)
    local out = ns.char and ns.char.companionNpc
    local outEntry = out and ns.Database and ns.Database.GetEntry(out)
    local startFactor = outEntry and outEntry.height and FactorFor(outEntry.height) or 1
    SizeFrame(Size(), startFactor)
    local saved = ns.char and ns.char.companionPoint
    if type(saved) == "table" and not saved.center then
        -- Saved by its corner while the frame was narrower: put it back at
        -- that width, find where its middle was, and keep it there.
        frame:SetWidth(LEGACY_WIDTH * Size() * startFactor)
        RestorePosition()
        local x, y = frame:GetCenter()
        x, y = Util.Plain(x), Util.Plain(y)
        SizeFrame(Size(), startFactor)
        if type(x) == "number" and type(y) == "number" then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            SavePosition()
        end
    else
        RestorePosition()
    end

    local fade = frame:CreateAnimationGroup()
    local alpha = fade:CreateAnimation("Alpha")
    alpha:SetDuration(FADE)
    fade:SetScript("OnFinished", function()
        frame:SetAlpha(alpha:GetToAlpha())
        if alpha:GetToAlpha() == 0 then frame:Hide() end
    end)
    frame.Fade, frame.FadeAlpha = fade, alpha

    -- The model, or the gnome portrait if this client can't draw it.
    local art = ns.Art or {}
    fallback = frame:CreateTexture(nil, "ARTWORK")
    fallback:SetSize(64, 64)
    fallback:SetPoint("BOTTOM", 0, 10)
    if art.MiniMePortrait then fallback:SetTexture(art.MiniMePortrait()) end
    local ok, miniMe = pcall(ns.MiniMe.Create, frame, {
        framing = "body", yaw = TURN,
        hideWeapons = function() return Settings().hideWeapons == true end,
        onLoaded = function()
            fallback:Hide()
            Face()
            local id = pendingAnim
            pendingAnim = nil
            if id and id ~= STAND then Companion.Play(id) end
        end,
        onFailed = function() fallback:Show() end,
        onMeasured = function(_, height)
            if ns.char then ns.char.miniMeHeight = height end
            if not buddyID then Resize(1) end
        end,
    })
    if ok and miniMe then
        miniMe:SetAllPoints(frame)
        scene = miniMe
        fallback:Hide()
    end
    SizeFrame(Size())
    ApplyBuddy()
    return frame
end

local function FadeTo(to)
    frame.Fade:Stop()
    frame.FadeAlpha:SetFromAlpha(frame:GetAlpha())
    frame.FadeAlpha:SetToAlpha(to)
    if to > 0 then frame:Show() end
    frame.Fade:Play()
end

-- Shows or hides it to match the options, combat and instances. Fades in
-- when it appears; appearing out of nowhere would startle.
function Companion.Refresh()
    if not ns.db then return end
    local want = Settings().companion ~= false and not hiddenForCombat and not hiddenForInstance
    if want then
        Build()
        if not frame:IsShown() or frame.FadeAlpha:GetToAlpha() ~= Alpha() then
            if not frame:IsShown() then frame:SetAlpha(0) end
            FadeTo(Alpha())
        end
    elseif frame and frame:IsShown() then
        Companion.Quiet()
        FadeTo(0)
    end
    ApplyMouse()
end

function Companion.Toggle()
    Companion.SetSetting("companion", Settings().companion == false)
    if Settings().companion then
        C_Timer.After(FADE, function() Companion.SayLine("greet", nil, WAVE) end)
    end
end

-- Buddies ----------------------------------------------------------------------------------

-- A friend who may come along: Buddy tier or better. Returns their entry.
local function Eligible(npcID)
    local database, friendship = ns.Database, ns.Friendship
    local entry = npcID and database and database.GetEntry and database.GetEntry(npcID)
    if entry and friendship and friendship.IsBuddy and friendship.IsBuddy(entry) then return entry end
    return nil
end

-- The friend who is out, or nil for the Mini Me.
function Companion.Buddy()
    return buddyID
end

-- What the tooltip and the menu call whoever is out.
function Companion.Name()
    local entry = buddyID and Eligible(buddyID)
    local name = entry and Util.Plain(entry.name)
    return type(name) == "string" and name or "Your Mini Me"
end

-- The friends who may come along, by name.
function Companion.Buddies()
    local list = {}
    local roster = ns.Database and ns.Database.GetRoster and ns.Database.GetRoster() or {}
    for npcID, entry in pairs(roster) do
        if Eligible(npcID) then
            local name = Util.Plain(entry.name)
            list[#list + 1] = { npcID = npcID, name = type(name) == "string" and name or ("NPC " .. npcID) }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local function OnNpcLoaded(model)
    if model.loaded then return end
    model.loaded = true
    pcall(model.SetAnimation, model, STAND)
    model:SetAlpha(1)
    Face()
    local id = pendingAnim
    pendingAnim = nil
    if id and id ~= STAND then Companion.Play(id) end
end

-- A friend is drawn the way the BuddyDex draws them: SetCreature works for
-- NPCs nowhere near the player, and never loads a unit.
local function BuildNpcModel()
    local model = CreateFrame("DressUpModel", nil, frame)
    model:SetAllPoints(frame)
    pcall(model.SetScript, model, "OnModelLoaded", OnNpcLoaded)
    model:Hide()
    return model
end

local function OnNpcStageLoaded()
    fallback:Hide()
    Face()
    local id = pendingAnim
    pendingAnim = nil
    if id and id ~= STAND then Companion.Play(id) end
end

-- The stage friends stand on: measured and aimed like the Mini Me's, and
-- its height sizes the frame (Resize). The height is kept with the friend,
-- so next time the frame has its size before the model loads.
local function NpcStage()
    if npcScene ~= nil then return npcScene or nil end
    local ok, stage = pcall(ns.MiniMe.CreateNpc, frame, {
        framing = "body", yaw = TURN,
        display = function() return npcScene and npcScene.display end,
        onLoaded = OnNpcStageLoaded,
        onMeasured = function(_, height)
            local entry = buddyID and ns.Database and ns.Database.GetEntry(buddyID)
            if entry then entry.height = math.floor(height * 100 + 0.5) / 100 end
            if buddyID then Resize(FactorFor(height)) end
        end,
    })
    npcScene = ok and stage or false
    if npcScene then
        npcScene:SetAllPoints(frame)
        npcScene:Hide()
    end
    return npcScene or nil
end

-- Shows whoever should be out: the friend saved for this character if they
-- still qualify, else the Mini Me. Invisible until loaded, like the Mini Me.
ApplyBuddy = function()
    if not frame then return end
    local saved = ns.char and ns.char.companionNpc
    local entry = Eligible(saved)
    buddyID = entry and saved or nil
    pendingAnim = nil
    local display = entry and tonumber(Util.Plain(entry.display))
    local stage = buddyID and display and NpcStage()
    if stage then
        if scene then scene:Hide() end
        if npcModel then
            npcModel:Hide()
            pcall(npcModel.ClearModel, npcModel)
        end
        fallback:Hide()
        if entry.height then Resize(FactorFor(entry.height)) end
        stage.display = display
        if stage:IsShown() then
            stage.Reload(true)
        else
            stage.aimed = false
            stage:Show()
        end
    elseif buddyID then
        if npcScene then npcScene:Hide() end
        Resize(1)
        npcModel = npcModel or BuildNpcModel()
        local model = npcModel
        if scene then scene:Hide() end
        fallback:Hide()
        model.loaded = false
        model:SetAlpha(0)
        model:Show()
        pcall(model.SetCreature, model, buddyID, tonumber(Util.Plain(entry.display)))
        -- A cached model may not call OnModelLoaded; standing is the sign.
        C_Timer.After(0.5, function()
            if model.loaded or buddyID ~= saved then return end
            if Util.Read(model.HasAnimation, model, STAND) == true then OnNpcLoaded(model) end
        end)
        C_Timer.After(2, function()
            if buddyID == saved then model:SetAlpha(1) end
        end)
    else
        if npcScene then npcScene:Hide() end
        if npcModel then
            npcModel:Hide()
            pcall(npcModel.ClearModel, npcModel)
        end
        Resize(1)
        if scene then scene:Show() end
    end
end

-- Brings a friend along (nil brings the Mini Me back). Returns true if
-- they came. Bringing someone along shows the buddy if it was hidden.
function Companion.SetBuddy(npcID)
    if not ns.char then return false end
    if npcID and not Eligible(npcID) then return false end
    if npcID == buddyID and frame then return true end
    Companion.Quiet()
    -- A friend going home says goodbye the way they do in the game.
    local leaving = BuddyDisplay()
    if leaving and ns.Voice and ns.Voice.Farewell and Companion.IsShown() then
        ns.Voice.Farewell(leaving)
    end
    ns.char.companionNpc = npcID
    if frame then ApplyBuddy() else Build() end
    ns.Bus:TriggerEvent(ns.Event.SettingChanged, "buddy", npcID)
    if Settings().companion == false then
        Companion.SetSetting("companion", true)
    else
        Companion.Refresh()
    end
    C_Timer.After(FADE + 0.2, function() Companion.SayLine("greet", nil, WAVE) end)
    return true
end

-- A friend who no longer qualifies (forgotten, or the friendship fell) goes
-- home, and the Mini Me comes back.
local function Recheck(_, npcID)
    if not (buddyID and npcID == buddyID) or Eligible(buddyID) then return end
    if ns.char then ns.char.companionNpc = nil end
    Companion.Quiet()
    ApplyBuddy()
    ns.Bus:TriggerEvent(ns.Event.SettingChanged, "buddy", nil)
end
ns.Bus:RegisterCallback(ns.Event.NpcRemoved, Recheck, Companion)
ns.Bus:RegisterCallback(ns.Event.NpcUpdated, Recheck, Companion)

-- Combat and instances ------------------------------------------------------------------

local function InInstance()
    local inside, kind = Util.Read(IsInInstance)
    return inside == true and (kind == "party" or kind == "raid" or kind == "pvp" or kind == "arena")
end

local function CheckInstance()
    hiddenForInstance = Settings().hideInInstances == true and InInstance()
    Companion.Refresh()
end

-- In a fight it goes quiet and lets clicks through, or hides if the options
-- say so; Core/Reactions.lua plays the battle cries and the celebrations.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        Companion.Quiet()
        hiddenForCombat = Settings().combat == "hide"
        Companion.Refresh()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat, hiddenForCombat = false, false
        Companion.Refresh()
    elseif ns.db then
        CheckInstance()
    end
end)

ns.Bus:RegisterCallback(ns.Event.SettingChanged, function(_, key)
    if key == "companion" or key == "alpha" then
        Companion.Refresh()
    elseif key == "voiceMode" and Settings().voiceMode == "off" then
        local voice = ns.Voice
        if voice and voice.Stop then voice.Stop() end
    elseif key == "scale" then
        ApplyScale()
    elseif key == "locked" or key == "clickThrough" then
        ApplyMouse()
    elseif key == "clampToScreen" then
        if frame then frame:SetClampedToScreen(Settings().clampToScreen ~= false) end
    elseif key == "facing" then
        Face()
    elseif key == "hideWeapons" then
        if scene and scene.Reload and not buddyID then scene.Reload() end
    elseif key == "hideInInstances" then
        CheckInstance()
    elseif key == "combat" and inCombat then
        hiddenForCombat = Settings().combat == "hide"
        Companion.Refresh()
    end
end, Companion)
