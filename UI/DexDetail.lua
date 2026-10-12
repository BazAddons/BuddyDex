-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/DexDetail.lua: the right half of the BuddyDex page (ns.DexDetail). It
-- owns the header (name, title, level, type), the model card (the selected
-- NPC in 3D on the mount journal's backdrop), the Details and Moves cards
-- beside it, the BuddyDex entry card below, and the portrait loader that
-- fills in the list's icons in the background.
--
-- Models are DressUpModels loaded with SetCreature(npcID), which works for
-- NPCs nowhere near the player. Nothing here loads a unit: SetUnit on a
-- nameplate unit crashed the client (DESIGN.md, hard rule 1). Loading is
-- asynchronous, so every load carries a token; anything that arrives for an
-- older token is ignored, and only the NPC a load was for is ever written.

local Detail = {}
ns.DexDetail = Detail

-- Layout, in the space right of the list (664 x 602 in a 1040 x 700 window).
local HEADER_HEIGHT = 56     -- name, title, level, type above the cards
local MODEL_WIDTH, MODEL_HEIGHT = 400, 402
local COLUMN_GAP = 12
local STORY_SPACING = 14   -- between the cards and the BuddyDex entry column
local DETAILS_HEIGHT = 226

local MAX_MOVES = 12
local MOVE_COLUMNS = 3
local MOVE_W, MOVE_H = 72, 22

local SELECT_DELAY = 0.1     -- debounce while arrowing or scrolling through the list
local LOAD_TIMEOUT = 6       -- after this, the card says the model is unavailable
local MOVE_DURATION = 3      -- a move plays this long, then the model goes back to idle

-- The model frame's own camera frames a creature edge to edge. Pulled back
-- a little it gets room to breathe; the wheel moves between these.
local CAMERA_DEFAULT, CAMERA_NEAR, CAMERA_FAR = 1.05, 0.75, 3

-- A three-quarter pose reads better than a mugshot: every model starts
-- turned 30 degrees, and Reset view comes back to it.
local FACING_DEFAULT = math.rad(30)

-- The portrait loader works through rows that have no display ID yet, one
-- NPC at a time, only while the BuddyDex page is on screen.
local PORTRAIT_TIMEOUT = 3
local PORTRAIT_GAP = 0.15
local PORTRAIT_QUEUE_MAX = 60
-- A load can time out while the server is still answering about an NPC,
-- so one miss is not final; the row asks again the next time it draws.
local PORTRAIT_TRIES = 2

local ui = {}
local shownNpcID       -- the NPC the text shows
local modelNpcID       -- the NPC the model holds or is loading; nil after Release
local token = 0        -- bumped by every load and every release
local loaded = false   -- the current token's model has loaded
local selectTimer, timeoutTimer, moveTimer

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

local function Entry(npcID)
    local database = ns.Database
    if not (npcID and database and database.GetEntry) then return nil end
    local ok, entry = pcall(database.GetEntry, npcID)
    return ok and type(entry) == "table" and entry or nil
end

local function Cancel(timer)
    if timer and timer.Cancel then timer:Cancel() end
    return nil
end

-- C_Timer.NewTimer when it exists; a cancellable stand-in otherwise.
local function After(delay, fn)
    if C_Timer and C_Timer.NewTimer then return C_Timer.NewTimer(delay, fn) end
    local handle = { canceled = false }
    function handle:Cancel() self.canceled = true end
    C_Timer.After(delay, function() if not handle.canceled then fn() end end)
    return handle
end

local function PlayKit(name)
    local kit = SOUNDKIT and SOUNDKIT[name]
    if kit and PlaySound then pcall(PlaySound, kit) end
end

local function Plural(n, one, many)
    return n == 1 and one or many:format(n)
end

local function NewCard(parent)
    local art = ns.Art
    if art and art.CreateCard then return art.CreateCard(parent) end
    return CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
end

local function NewHeader(parent, text)
    local art = ns.Art
    if art and art.CreateSectionHeader then return art.CreateSectionHeader(parent, text) end
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(196, 40)
    header.Label = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header.Label:SetPoint("CENTER", 0, 1)
    header.Label:SetText(text)
    return header
end

local function NewButton(parent, width, height)
    local art = ns.Art
    if art and art.CreateSmallButton then return art.CreateSmallButton(parent, width, height) end
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    return button
end

-- The placeholder ------------------------------------------------------------

local function ShowPlaceholder(text)
    ui.placeholder:Show()
    ui.placeholderText:SetText(text)
    ui.placeholderText:Show()
end

local function HidePlaceholder()
    ui.placeholder:Hide()
    ui.placeholderText:Hide()
end

-- Camera ------------------------------------------------------------------------

local function ApplyCamera()
    local model = ui.model
    pcall(model.SetCamDistanceScale, model, ui.camera or CAMERA_DEFAULT)
    pcall(model.SetFacing, model, ui.facing or FACING_DEFAULT)
end

local function ResetView()
    ui.facing, ui.camera = FACING_DEFAULT, CAMERA_DEFAULT
    pcall(ui.model.SetPortraitZoom, ui.model, 0)
    ApplyCamera()
end

-- Moves -------------------------------------------------------------------------

-- Greetings an NPC plays when it is picked, chosen at random from the ones
-- its model has. A creature with none of them roars if it can.
local GREETINGS = { 67, 113, 66 }   -- Wave, Salute, Bow
local GREETING_FALLBACK = { 74 }    -- Roar
local GREET_DELAY = 0.25            -- let the model settle on screen first

local function PlayAnimation(id)
    local model = ui.model
    if not model then return end
    pcall(model.SetAnimation, model, id)
    moveTimer = Cancel(moveTimer)
    local mine = token
    moveTimer = After(MOVE_DURATION, function()
        moveTimer = nil
        if mine == token then pcall(model.SetAnimation, model, 0) end
    end)
end

local function PlayMove(id)
    PlayKit("IG_MAINMENU_OPTION_CHECKBOX_ON")
    PlayAnimation(id)
end

local function Greet(moves)
    local has = {}
    for _, id in ipairs(type(moves) == "table" and moves or {}) do has[id] = true end
    local choices = {}
    for _, id in ipairs(GREETINGS) do
        if has[id] then choices[#choices + 1] = id end
    end
    if #choices == 0 then
        for _, id in ipairs(GREETING_FALLBACK) do
            if has[id] then choices[#choices + 1] = id end
        end
    end
    if #choices > 0 then PlayAnimation(choices[math.random(#choices)]) end
end

local function MoveButton(i)
    local button = ui.moveButtons[i]
    if button then return button end
    button = NewButton(ui.movesCard, MOVE_W, MOVE_H)
    local row, col = math.floor((i - 1) / MOVE_COLUMNS), (i - 1) % MOVE_COLUMNS
    button:SetPoint("TOPLEFT", ui.movesCard, "TOPLEFT", 12 + col * (MOVE_W + 6), -44 - row * (MOVE_H + 4))
    button:SetScript("OnClick", function(self) PlayMove(self.moveID) end)
    ui.moveButtons[i] = button
    return button
end

local function UpdateMoves(entry)
    for _, button in ipairs(ui.moveButtons) do button:Hide() end
    local moves = entry and entry.moves
    if type(moves) ~= "table" then
        ui.movesStatus:SetText(entry and "Loading..." or "")
        ui.movesStatus:Show()
        return
    end
    if #moves == 0 then
        ui.movesStatus:SetText("This one just stands there.")
        ui.movesStatus:Show()
        return
    end
    ui.movesStatus:Hide()
    local label = ns.Moves and ns.Moves.Label
    for i = 1, math.min(#moves, MAX_MOVES) do
        local id = tonumber(Plain(moves[i]))
        if id then
            local button = MoveButton(i)
            button.moveID = id
            button:SetText(label and label(id) or ("Move " .. id))
            button:Show()
        end
    end
end

-- Text ----------------------------------------------------------------------------

local function TypeText(entry)
    local kind, family = Text(entry.type), Text(entry.family)
    if kind and family then return kind .. " (" .. family .. ")" end
    return kind or family or "Unknown"
end

local function LevelText(level)
    level = tonumber(Plain(level))
    if not level then return "?" end
    if level < 0 then return "??" end
    return tostring(level)
end

-- The BuddyDex entry --------------------------------------------------------------

-- A friendship unlocks an NPC's entry (Data/Lore.lua) a part at a time, like
-- the rewards on a reputation track. Two cards show it: Personality under
-- the model (the quote, likes and dislikes) and Lore down the right, a
-- page of sections (Word Around Town, Story, Backstory, Secret, Just Between Friends) whose
-- headers name the tier that opens them. A locked part says what it takes,
-- the next one a little brighter. Tiers are indexes into Friendship.TIERS.
-- "/bd lore" shows every part, for writers checking an entry.
local LORE_UNLOCKS = {
    { tier = 2, card = "personality", keys = { "quote" }, teaser = "to hear from %s", pronoun = 1 },
    { tier = 3, card = "personality", keys = { "likes", "dislikes" }, teaser = "to learn %s likes and dislikes", pronoun = 2 },
    { tier = 3, card = "story", title = "Word Around Town", keys = { "gossip" },
        teaser = "to hear what people say about %s", pronoun = 1 },
    { tier = 4, card = "story", title = "Story", keys = { "bio" }, teaser = "to hear %s story", pronoun = 2 },
    { tier = 4, card = "story", title = "Backstory", keys = { "backstory" },
        teaser = "to learn where %s story began", pronoun = 2 },
    { tier = 5, card = "story", title = "Secret", keys = { "secret" }, teaser = "to learn %s secret", pronoun = 2 },
    { tier = 6, card = "story", title = "Just Between Friends", keys = { "bestFriend" },
        teaser = "to hear what only a best friend hears" },
}
-- Object and possessive, by the sex UnitSex gave (2 male, 3 female).
local PRONOUNS = { [2] = { "him", "his" }, [3] = { "her", "her" } }
local THEY = { "them", "their" }

local GOLD, GRAY = "|cffffd100%s|r", "|cff808080%s|r"
local NEXT, LATER = "|cffb4b4b4%s|r", "|cff6e6e6e%s|r"   -- the next locked part, and the ones after it
local SPEECH = "|cffffff9f%s|r"   -- the color of NPC speech in chat, for what they say
local LOCK = "|TInterface\\LFGFrame\\UI-LFG-ICON-LOCK:14:14:0:-1|t "
local BULLET = "\226\128\162 "   -- U+2022

local function LoreString(v)
    return type(v) == "string" and v ~= "" and v or nil
end

-- "Likes" over one item per line, or nil when there are none.
local function LoreList(label, list)
    if type(list) ~= "table" then return nil end
    local lines = { GOLD:format(label) }
    for _, item in ipairs(list) do
        item = LoreString(item)
        if item then lines[#lines + 1] = BULLET .. item end
    end
    return #lines > 1 and table.concat(lines, "\n") or nil
end

local function Spoken(v)
    local s = LoreString(v)
    return s and SPEECH:format(('"%s"'):format(s))
end

local LORE_TEXT = {
    quote = function(lore) return Spoken(lore.quote) end,
    likes = function(lore) return LoreList("Likes", lore.likes) end,
    dislikes = function(lore) return LoreList("Dislikes", lore.dislikes) end,
    gossip = function(lore) return LoreString(lore.gossip) end,
    bio = function(lore) return LoreString(lore.bio) end,
    backstory = function(lore) return LoreString(lore.backstory) end,
    secret = function(lore) return LoreString(lore.secret) end,
    bestFriend = function(lore) return Spoken(lore.bestFriend) end,
}

-- An NPC's entry as far as this friendship has unlocked it:
--   quote, likes, dislikes, gossip, bio, backstory, secret, bestFriend: the open parts' text
--   personalityLocked: the Personality card's locked parts, one per line
--   sections: the entry page's sections the lore has, in order, each
--     { key, title, tier, label, text (when open), teaser (when locked) }
--   unlocked, total: parts open and parts written
--   note: when nobody has written the NPC yet
function Detail.LoreParts(npcID, entry)
    local parts = { sections = {}, unlocked = 0, total = 0 }
    if not entry then return parts end
    local name = Text(entry.name) or "them"
    local lore = ns.Lore and ns.Lore[npcID]
    if type(lore) ~= "table" then
        parts.personalityLocked = GRAY:format("Nothing written yet.")
        parts.note = GRAY:format(("The BuddyDex has no entry on %s yet."):format(name))
        return parts
    end
    local friendship = ns.Friendship
    local tier = friendship and friendship.TierIndex and friendship.TierIndex(entry) or 1
    if ns.lorePreview then tier = math.huge end
    local pronouns = PRONOUNS[tonumber(Plain(entry.sex))] or THEY
    local personalityLocked, isNext = {}, true
    for _, unlock in ipairs(LORE_UNLOCKS) do
        local texts = {}
        for _, key in ipairs(unlock.keys) do texts[key] = LORE_TEXT[key](lore) end
        if next(texts) then
            parts.total = parts.total + 1
            local tierInfo = friendship and friendship.TIERS and friendship.TIERS[unlock.tier]
            local label = tierInfo and tierInfo.label or "Closer"
            local teaser
            if tier >= unlock.tier then
                parts.unlocked = parts.unlocked + 1
                for key, text in pairs(texts) do parts[key] = text end
            else
                local what = unlock.pronoun and unlock.teaser:format(pronouns[unlock.pronoun]) or unlock.teaser
                teaser = LOCK .. (isNext and NEXT or LATER):format(("Reach %s with %s %s."):format(label, name, what))
                isNext = false
            end
            if unlock.card == "personality" then
                if teaser then personalityLocked[#personalityLocked + 1] = teaser end
            else
                local key = unlock.keys[1]
                parts.sections[#parts.sections + 1] = { key = key, title = unlock.title, tier = unlock.tier,
                    label = label, text = not teaser and texts[key] or nil, teaser = teaser }
            end
        end
    end
    if #personalityLocked > 0 then parts.personalityLocked = table.concat(personalityLocked, "\n") end
    return parts
end

local ENTRY_GAP = 8            -- between the parts of a card
local ENTRY_COLUMN_GAP = 20    -- between likes and dislikes
local ENTRY_PAIR_WIDTH = 420   -- narrower than this, likes go above dislikes
local SECTION_GAP = 18         -- between the entry page's sections
local SECTION_RULE_GAP = 4     -- around the rule under a section's header

-- The friendship bar's colors by tier (Core/Friendship.lua TIER_BAR), for
-- the tier a section names.
local TIER_COLORS = {
    { 1, 1, 1 }, { 1, 1, 1 }, { 0.1, 1, 0.1 }, { 0.1, 1, 0.1 }, { 0.3, 0.65, 1 }, { 0.3, 0.65, 1 },
}

-- Stacks the parts that have text down a card's scroll child, a pair side by
-- side when the card is wide enough, and sizes the child to fit so the
-- scroll range is right.
local function LayoutCard(card)
    local width = math.floor(tonumber(card.scroll:GetWidth()) or 0)
    if width <= 0 then return end
    card.child:SetWidth(width)
    local paired = width >= ENTRY_PAIR_WIDTH
    local half = math.floor((width - ENTRY_COLUMN_GAP) / 2)
    local y = 0
    for _, row in ipairs(card.rows) do
        local height = 0
        for i, fs in ipairs(row) do
            if fs:IsShown() then
                local x, w = 0, width
                if #row > 1 and paired then
                    x, w = (i - 1) * (half + ENTRY_COLUMN_GAP), half
                elseif height > 0 then
                    -- Stacked: the second of a pair goes under the first.
                    y, height = y + height + ENTRY_GAP, 0
                end
                fs:ClearAllPoints()
                fs:SetPoint("TOPLEFT", card.child, "TOPLEFT", x, -y)
                fs:SetWidth(w)
                height = math.max(height, tonumber(fs:GetStringHeight()) or 0)
            end
        end
        if height > 0 then y = y + height + ENTRY_GAP end
    end
    card.child:SetHeight(math.max(1, y - ENTRY_GAP))
end

-- The entry page: the note, or each section's header with its tier on the
-- right, the rule under it, and its text.
local function LayoutStory(card)
    local width = math.floor(tonumber(card.scroll:GetWidth()) or 0)
    if width <= 0 then return end
    local child = card.child
    child:SetWidth(width)
    local y = 0
    local function Text(fs, x)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", x or 0, -y)
        fs:SetWidth(width - (x or 0))
        return tonumber(fs:GetStringHeight()) or 0
    end
    if card.note:IsShown() then y = y + Text(card.note) + SECTION_GAP end
    for _, section in ipairs(card.sections) do
        if section.header:IsShown() then
            local headerHeight = tonumber(section.header:GetStringHeight()) or 14
            section.header:ClearAllPoints()
            section.header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            section.tag:ClearAllPoints()
            section.tag:SetPoint("BOTTOMRIGHT", child, "TOPRIGHT", 0, -(y + headerHeight - 1))
            y = y + headerHeight + SECTION_RULE_GAP
            section.rule:ClearAllPoints()
            section.rule:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            section.rule:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
            y = y + 1 + SECTION_RULE_GAP + 2
            y = y + Text(section.body) + SECTION_GAP
        end
    end
    child:SetHeight(math.max(1, y - SECTION_GAP))
end

-- Another NPC starts at the top; a refresh of the same one keeps the place.
local function ResetScroll(card, npcID)
    if card.npcID ~= npcID then
        card.npcID = npcID
        card.scroll:SetVerticalScroll(0)
    end
end

local function FillCard(card, parts, npcID)
    for key, fs in pairs(card.parts) do
        fs:SetText(parts[key] or "")
        fs:SetShown(parts[key] ~= nil)
    end
    LayoutCard(card)
    ResetScroll(card, npcID)
end

local function SetRule(rule, open)
    if open then
        rule:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 0.55), CreateColor(1, 0.82, 0, 0))
    else
        rule:SetGradient("HORIZONTAL", CreateColor(0.5, 0.5, 0.5, 0.35), CreateColor(0.5, 0.5, 0.5, 0))
    end
end

-- One dot per page, gold once it is unlocked.
local function Pips(unlocked, total)
    local dots = {}
    for i = 1, total do dots[i] = (i <= unlocked and GOLD or "|cff4a4a4a%s|r"):format("\226\128\162") end
    return table.concat(dots, " ")
end

local function FillStory(card, parts, npcID)
    card.note:SetText(parts.note or "")
    card.note:SetShown(parts.note ~= nil)
    for i, section in ipairs(card.sections) do
        local data = parts.sections[i]
        for _, region in ipairs({ section.header, section.tag, section.rule, section.body }) do
            region:SetShown(data ~= nil)
        end
        if data then
            local open = data.text ~= nil
            section.header:SetText(data.title)
            if open then
                section.header:SetTextColor(1, 0.82, 0)
                local c = TIER_COLORS[data.tier] or TIER_COLORS[1]
                section.tag:SetTextColor(c[1], c[2], c[3])
                section.tag:SetText(data.label)
            else
                section.header:SetTextColor(0.5, 0.5, 0.5)
                section.tag:SetTextColor(0.5, 0.5, 0.5)
                section.tag:SetText(LOCK .. data.label)
            end
            SetRule(section.rule, open)
            section.body:SetText(data.text or data.teaser)
        end
    end

    -- How much of the entry this friendship has opened: the count in the
    -- header (where a zone row counts its friends) and a dot per page below.
    local total, unlocked = parts.total or 0, parts.unlocked or 0
    local complete = total > 0 and unlocked >= total
    card.Header.Count:SetText(total > 0 and ("%d of %d pages"):format(unlocked, total) or "")
    if complete then
        card.Header.Count:SetTextColor(1, 0.82, 0)
    else
        card.Header.Count:SetTextColor(1, 1, 1)
    end
    card.footer:SetShown(total > 0)
    if total > 0 then
        card.pips:SetText(Pips(unlocked, total))
        if ns.lorePreview then
            card.progress:SetText(GRAY:format("Lore preview: every page shown. /bd lore turns it off."))
        else
            card.progress:SetText(complete and GOLD:format("Every page unlocked") or "")
        end
    end
    LayoutStory(card)
    ResetScroll(card, npcID)
end

local function UpdateLore(npcID, entry)
    local parts = Detail.LoreParts(npcID, entry)
    FillCard(ui.personality, parts, npcID)
    FillStory(ui.story, parts, npcID)
end

-- The waypoint button ----------------------------------------------------------------

-- Bring along -------------------------------------------------------------------------

-- A friend at Buddy tier or better can come along in the Mini Me's place
-- (UI/Companion.lua); the button sends them home again.
local function UpdateBringAlong(entry)
    local friendship, companion = ns.Friendship, ns.Companion
    local eligible = entry ~= nil and friendship ~= nil and friendship.IsBuddy(entry) and companion ~= nil
    local out = eligible and companion.Buddy() == shownNpcID
    ui.bringAlong:SetText(out and "Send home" or "Bring along")
    ui.bringAlong:SetEnabled(eligible)
end

local function BringAlongTooltip(self)
    local entry = shownNpcID and Entry(shownNpcID)
    local name = entry and Text(entry.name) or "them"
    local friendship, companion = ns.Friendship, ns.Companion
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if companion and companion.Buddy() == shownNpcID then
        GameTooltip_SetTitle(GameTooltip, "Send home")
        GameTooltip_AddNormalLine(GameTooltip, ("%s goes home, and your Mini Me comes back."):format(name))
    else
        GameTooltip_SetTitle(GameTooltip, "Bring along")
        if entry and friendship and friendship.IsBuddy(entry) then
            GameTooltip_AddNormalLine(GameTooltip, ("%s keeps you company on screen instead of your Mini Me."):format(name))
        else
            local tier = friendship and friendship.TIERS[friendship.BUDDY_TIER]
            GameTooltip_AddNormalLine(GameTooltip, ("Reach %s with %s and they can come along."):format(
                tier and tier.label or "Buddy", name))
        end
    end
    GameTooltip:Show()
end

local function OnBringAlong()
    local companion = ns.Companion
    if not (companion and shownNpcID) then return end
    companion.SetBuddy(companion.Buddy() ~= shownNpcID and shownNpcID or nil)
end

local function UpdateWaypoint(entry)
    local waypoint = ns.Waypoint
    ui.waypoint:SetEnabled(entry ~= nil and waypoint ~= nil and waypoint.Has(entry))
end

local function WaypointTooltip(self)
    local waypoint = ns.Waypoint
    local entry = shownNpcID and Entry(shownNpcID)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip_SetTitle(GameTooltip, "Set waypoint")
    if not (waypoint and entry and waypoint.Has(entry)) then
        GameTooltip_AddNormalLine(GameTooltip, "BuddyDex learns where a friend is the next time you visit them.")
    elseif waypoint.HasTomTom() then
        GameTooltip_AddNormalLine(GameTooltip, "TomTom's arrow points the way to where you last met.")
    else
        GameTooltip_AddNormalLine(GameTooltip, "Pins where you last met on your map and tracks it on screen.")
    end
    GameTooltip:Show()
end

local function SetValue(key, text, r, g, b)
    local fs = ui.values[key]
    fs:SetText(text or "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
end

local function UpdateText(npcID, entry)
    if not entry then
        ui.name:SetText("")
        ui.subtitle:SetText("")
        ui.tier:SetText("")
        if ui.bar then ui.bar:Hide() end
        for key in pairs(ui.values) do SetValue(key, "") end
        UpdateLore(nil, nil)
        UpdateWaypoint(nil)
        UpdateBringAlong(nil)
        UpdateMoves(nil)
        return
    end
    local art = ns.Art or {}
    local r, g, b = 1, 0.82, 0
    if art.RarityColor then
        local ok, cr, cg, cb = pcall(art.RarityColor, entry.class)
        if ok and cr then r, g, b = cr, cg, cb end
    end
    local okRarity, rarity = false, nil
    if art.Rarity then okRarity, rarity = pcall(art.Rarity, entry.class) end

    ui.name:SetText(Text(entry.name) or "Unknown NPC")
    ui.name:SetTextColor(r, g, b)
    local title = Text(entry.title)
    ui.subtitle:SetText(title and ("<" .. title .. ">") or TypeText(entry))
    local friendship = ns.Friendship
    if friendship and friendship.TierInfo then
        local info = friendship.TierInfo(entry)
        ui.tier:SetText(info.label)
        if ui.bar then
            ui.bar:Show()
            ui.bar:SetFriendship(info)
        end
    end

    SetValue("zone", Text(entry.zone) or "Unknown")
    -- Where they were when the player last visited, as map coordinates.
    local area, waypoint = Text(entry.subzone), ns.Waypoint
    if waypoint and waypoint.Has(entry) then
        local coords = ("%.1f, %.1f"):format(entry.x * 100, entry.y * 100)
        area = area and ("%s (%s)"):format(area, coords) or coords
    end
    SetValue("area", area or "-")
    SetValue("type", TypeText(entry))
    SetValue("rarity", okRarity and type(rarity) == "table" and rarity.label or "Common", r, g, b)
    SetValue("level", LevelText(entry.level))
    SetValue("met", Text(entry.first) or "Unknown")
    SetValue("last", Text(entry.last) or Text(entry.first) or "Unknown")
    local visits = tonumber(Plain(entry.visits)) or 0
    SetValue("visits", Plural(visits, "Once", "%d times"))
    -- Their favorite emote: a hint until the player finds it.
    if friendship and friendship.Favorite then
        local favorite = friendship.Favorite(entry, npcID)
        if entry.favoriteFound then
            SetValue("favorite", favorite.label, 0.25, 1, 0.25)
        else
            SetValue("favorite", favorite.hint, 0.6, 0.6, 0.6)
        end
    end

    UpdateLore(npcID, entry)
    UpdateWaypoint(entry)
    UpdateBringAlong(entry)
    UpdateMoves(entry)
end

-- Reading a loaded model ----------------------------------------------------------

-- Stand (animation 0) answering yes is the sign a model has really loaded;
-- before that HasAnimation says no to everything and would cache an NPC
-- with no moves. Returns the display ID and moves, or nil while loading.
local function ReadModel(model)
    local ok, standing = pcall(model.HasAnimation, model, 0)
    if not (ok and standing) then return nil end
    local okDisplay, displayID = pcall(model.GetDisplayInfo, model)
    displayID = okDisplay and tonumber(Plain(displayID)) or nil
    if displayID and displayID <= 0 then displayID = nil end
    local moves = ns.Moves and ns.Moves.Probe and ns.Moves.Probe(model) or nil
    return true, displayID, moves
end

local function Store(npcID, displayID, moves)
    local database = ns.Database
    if database and database.SetModelInfo then
        pcall(database.SetModelInfo, npcID, displayID, moves)
    end
end

-- The detail model ---------------------------------------------------------------

local function CacheModelInfo(mine)
    if mine ~= token or not modelNpcID or loaded then return end
    local ready, displayID, moves = ReadModel(ui.model)
    if not ready then return end
    loaded = true
    timeoutTimer = Cancel(timeoutTimer)
    HidePlaceholder()
    ApplyCamera()
    Store(modelNpcID, displayID, moves)
    if modelNpcID == shownNpcID then UpdateMoves(Entry(shownNpcID)) end
    -- Once per load, so a list refresh never re-greets; reopening the
    -- window or picking the NPC again does.
    After(GREET_DELAY, function()
        if mine == token then Greet(moves) end
    end)
end

local function OnModelLoaded()
    CacheModelInfo(token)
end

local function LoadModel(npcID, entry)
    local model = ui.model
    token = token + 1
    local mine = token
    loaded = false
    modelNpcID = npcID
    timeoutTimer = Cancel(timeoutTimer)
    moveTimer = Cancel(moveTimer)
    ui.facing, ui.camera = FACING_DEFAULT, CAMERA_DEFAULT

    if not npcID then
        pcall(model.ClearModel, model)
        ShowPlaceholder("Pick an NPC to see it here.")
        return
    end

    HidePlaceholder()
    local displayID = entry and tonumber(Plain(entry.display))
    local ok
    if displayID then
        ok = pcall(model.SetCreature, model, npcID, displayID)
    else
        ok = pcall(model.SetCreature, model, npcID)
    end
    if not ok then
        ShowPlaceholder("No model available for this NPC.")
        return
    end
    pcall(model.SetAnimation, model, 0)
    ApplyCamera()

    -- Without OnModelLoaded (or if it never fires), look once a second.
    if not ui.hasLoadedScript then
        local function Poll(left)
            if mine ~= token or loaded then return end
            CacheModelInfo(mine)
            if not loaded and left > 1 then After(1, function() Poll(left - 1) end) end
        end
        After(1, function() Poll(LOAD_TIMEOUT - 1) end)
    end

    timeoutTimer = After(LOAD_TIMEOUT, function()
        timeoutTimer = nil
        if mine == token and not loaded then
            -- One last look: the load may have finished without telling us.
            CacheModelInfo(mine)
            if not loaded then ShowPlaceholder("No model available for this NPC.") end
        end
    end)
end

-- The portrait loader ---------------------------------------------------------------
-- A list row shows the NPC's portrait once its display ID is known, and that
-- used to be learned only by clicking it. This loads the rows' NPCs one at a
-- time into a second, invisible model and caches what it reads, the same
-- SetCreature route as the detail model. Newest requests first, so the rows
-- on screen fill in before ones scrolled past.

local warm = { stack = {}, wanted = {}, failed = {}, busy = nil, token = 0 }

local function WarmDone()
    warm.busy = nil
    if ui.warmModel then pcall(ui.warmModel.ClearModel, ui.warmModel) end
end

local WarmNext

local function WarmCheck(job)
    if warm.busy ~= job then return end
    local ready, displayID, moves = ReadModel(ui.warmModel)
    if ready then
        Store(job.npcID, displayID, moves)
        WarmDone()
        After(PORTRAIT_GAP, WarmNext)
    elseif GetTime() - job.started >= PORTRAIT_TIMEOUT then
        warm.failed[job.npcID] = (warm.failed[job.npcID] or 0) + 1
        WarmDone()
        After(PORTRAIT_GAP, WarmNext)
    else
        After(0.25, function() WarmCheck(job) end)
    end
end

function WarmNext()
    if warm.busy or not ui.warmModel then return end
    -- Only while the page is on screen; the queue waits for the next open.
    if not (ui.inset and ui.inset:IsVisible()) then return end
    local npcID
    repeat
        npcID = table.remove(warm.stack)
        if npcID then
            warm.wanted[npcID] = nil
            local entry = Entry(npcID)
            if not entry or entry.display then npcID = nil end
            if npcID == nil and #warm.stack == 0 then return end
        end
    until npcID or #warm.stack == 0
    if not npcID then return end

    local job = { npcID = npcID, started = GetTime() }
    warm.busy = job
    if not pcall(ui.warmModel.SetCreature, ui.warmModel, npcID) then
        warm.failed[npcID] = PORTRAIT_TRIES
        WarmDone()
        After(PORTRAIT_GAP, WarmNext)
        return
    end
    After(0.25, function() WarmCheck(job) end)
end

-- Asks for a row's portrait. The list calls this for rows without one.
function Detail.WantPortrait(npcID)
    npcID = tonumber(Plain(npcID))
    if not npcID or (warm.failed[npcID] or 0) >= PORTRAIT_TRIES then return end
    if not warm.wanted[npcID] then
        warm.wanted[npcID] = true
        warm.stack[#warm.stack + 1] = npcID
        -- Keep the newest requests; ones far behind are asked for again
        -- when their rows come back on screen.
        if #warm.stack > PORTRAIT_QUEUE_MAX then
            local dropped = table.remove(warm.stack, 1)
            warm.wanted[dropped] = nil
        end
    end
    WarmNext()
end

-- Public --------------------------------------------------------------------------

local function ShowNow(npcID)
    selectTimer = nil
    if not ui.model then return end
    local entry = Entry(npcID)
    if not entry then npcID = nil end
    shownNpcID = npcID
    UpdateText(npcID, entry)
    LoadModel(npcID, entry)
end

-- Shows an NPC (nil for none). Debounced, so scrolling fast through the
-- list loads one model, not one per row passed.
function Detail.Show(npcID)
    npcID = tonumber(Plain(npcID))
    selectTimer = Cancel(selectTimer)
    selectTimer = After(SELECT_DELAY, function() ShowNow(npcID) end)
end

-- Updates the text for the NPC already shown, e.g. a new seen count. If the
-- model was released since (the window closed or the tab changed), it is
-- loaded again.
function Detail.UpdateInfo(npcID)
    npcID = tonumber(Plain(npcID))
    if not ui.model then return end
    if npcID ~= modelNpcID or npcID ~= shownNpcID then
        Detail.Show(npcID)
        return
    end
    UpdateText(npcID, Entry(npcID))
    WarmNext()
end

-- The NPC the page shows, or nil.
function Detail.ShownNpcID()
    return shownNpcID
end

-- Redraws the text of the NPC on show, after a change that is not about one
-- NPC (the lore preview).
function Detail.Redraw()
    if shownNpcID and ui.values then UpdateText(shownNpcID, Entry(shownNpcID)) end
end

-- Lets go of both models while the page is off screen.
function Detail.Release()
    token = token + 1
    loaded = false
    modelNpcID = nil
    selectTimer = Cancel(selectTimer)
    timeoutTimer = Cancel(timeoutTimer)
    moveTimer = Cancel(moveTimer)
    if ui.model then pcall(ui.model.ClearModel, ui.model) end
    if warm.busy then
        -- Not a failure: it was interrupted. Ask again next time.
        local npcID = warm.busy.npcID
        WarmDone()
        if not warm.wanted[npcID] then
            warm.wanted[npcID] = true
            warm.stack[#warm.stack + 1] = npcID
        end
    end
end

-- Building -------------------------------------------------------------------------

local function BuildHeader(inset)
    ui.name = inset:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    ui.name:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -4)
    ui.name:SetPoint("RIGHT", inset, "RIGHT", -230, 0)
    ui.name:SetJustifyH("LEFT")
    ui.name:SetWordWrap(false)

    ui.subtitle = inset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    ui.subtitle:SetPoint("TOPLEFT", ui.name, "BOTTOMLEFT", 0, -6)
    ui.subtitle:SetPoint("RIGHT", inset, "RIGHT", -230, 0)
    ui.subtitle:SetJustifyH("LEFT")
    ui.subtitle:SetWordWrap(false)

    -- Where the friendship stands, the way the reputation panel shows it.
    ui.tier = inset:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ui.tier:SetPoint("TOPRIGHT", inset, "TOPRIGHT", -4, -2)
    ui.tier:SetJustifyH("RIGHT")

    local art = ns.Art
    if art and art.CreateFriendshipBar then
        ui.bar = art.CreateFriendshipBar(inset, 210, 26, "GameFontHighlightSmall")
        ui.bar:SetPoint("TOPRIGHT", inset, "TOPRIGHT", 0, -24)
    end
end

local function BuildModelCard(inset)
    local art = ns.Art or {}
    local card = NewCard(inset)
    card:SetPoint("TOPLEFT", inset, "TOPLEFT", 0, -HEADER_HEIGHT)
    card:SetSize(MODEL_WIDTH, MODEL_HEIGHT)

    local bg = card:CreateTexture(nil, "BACKGROUND", nil, 2)
    bg:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)
    if art.MODEL_BG then
        bg:SetTexture(art.MODEL_BG)
        local c = art.MODEL_BG_COORDS
        if c then bg:SetTexCoord(c[1], c[2], c[3], c[4]) end
    else
        bg:SetColorTexture(0, 0, 0, 0.5)
    end

    local model = CreateFrame("DressUpModel", nil, card)
    model:SetPoint("TOPLEFT", bg, "TOPLEFT")
    model:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT")
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    ui.facing, ui.camera = FACING_DEFAULT, CAMERA_DEFAULT
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.dragX = GetCursorPosition() end
    end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnHide", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        ui.facing = (ui.facing or 0) + (x - self.dragX) * 0.02
        self.dragX = x
        pcall(self.SetFacing, self, ui.facing)
    end)
    -- Wheel up comes closer, wheel down backs off.
    model:SetScript("OnMouseWheel", function(self, delta)
        ui.camera = math.max(CAMERA_NEAR, math.min(CAMERA_FAR, (ui.camera or CAMERA_DEFAULT) - delta * 0.1))
        pcall(self.SetCamDistanceScale, self, ui.camera)
    end)
    ui.hasLoadedScript = pcall(model.SetScript, model, "OnModelLoaded", OnModelLoaded)
    ui.model = model

    -- Everything drawn over the model lives on a frame above it.
    local overlay = CreateFrame("Frame", nil, card)
    overlay:SetAllPoints(bg)
    overlay:SetFrameLevel(model:GetFrameLevel() + 5)
    if art.HasTemplate and art.HasTemplate("ShadowOverlayTemplate") then
        local shadow = CreateFrame("Frame", nil, overlay, "ShadowOverlayTemplate")
        shadow:SetAllPoints()
    end

    -- The mount journal's empty pane: its "no mounts" art fills the whole
    -- model pane with the same crop as the backdrop, and a large line sits
    -- in the middle (Blizzard_MountCollection.xml:438-446).
    ui.placeholder = overlay:CreateTexture(nil, "ARTWORK", nil, 1)
    ui.placeholder:SetAllPoints(bg)
    if art.MODEL_EMPTY then
        ui.placeholder:SetTexture(art.MODEL_EMPTY)
        local c = art.MODEL_BG_COORDS
        if c then ui.placeholder:SetTexCoord(c[1], c[2], c[3], c[4]) end
    end
    ui.placeholderText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    ui.placeholderText:SetSize(280, 80)
    ui.placeholderText:SetPoint("CENTER")
    ui.placeholderText:SetJustifyH("CENTER")

    local hint = overlay:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 10, 12)
    hint:SetText("Drag to turn, scroll to zoom")

    local reset = NewButton(overlay, 84, 22)
    reset:SetPoint("BOTTOMRIGHT", -8, 8)
    reset:SetText("Reset view")
    reset:SetScript("OnClick", ResetView)

    -- TomTom's arrow, or the map's own pin, to where the player last met them.
    local waypoint = NewButton(overlay, 96, 22)
    waypoint:SetPoint("RIGHT", reset, "LEFT", -6, 0)
    waypoint:SetText("Set waypoint")
    waypoint:SetMotionScriptsWhileDisabled(true)
    waypoint:SetScript("OnClick", function()
        if shownNpcID and ns.Waypoint then ns.Waypoint.Set(shownNpcID) end
    end)
    waypoint:SetScript("OnEnter", WaypointTooltip)
    waypoint:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ui.waypoint = waypoint

    -- Top right, clear of the model's head and the buttons below.
    local bringAlong = NewButton(overlay, 96, 22)
    bringAlong:SetPoint("TOPRIGHT", -8, -8)
    bringAlong:SetText("Bring along")
    bringAlong:SetMotionScriptsWhileDisabled(true)
    bringAlong:SetScript("OnClick", OnBringAlong)
    bringAlong:SetScript("OnEnter", BringAlongTooltip)
    bringAlong:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ui.bringAlong = bringAlong

    -- The portrait loader's model: shown so it loads, but invisible.
    local warmModel = CreateFrame("DressUpModel", nil, card)
    warmModel:SetSize(1, 1)
    warmModel:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 0)
    warmModel:SetAlpha(0)
    ui.warmModel = warmModel

    ui.modelCard = card
    return card
end

-- The Details card: label on the left, value on the right, every other row
-- striped like the character sheet's stats.
local DETAIL_ROWS = {
    { key = "zone", label = "Zone" },
    { key = "area", label = "Area" },
    { key = "type", label = "Type" },
    { key = "rarity", label = "Rarity" },
    { key = "level", label = "Level" },
    { key = "met", label = "Met" },
    { key = "last", label = "Last visit" },
    { key = "visits", label = "Visits" },
    { key = "favorite", label = "Favorite" },
}
local ROW_STEP = 19

local function BuildDetails(inset, modelCard)
    local card = NewCard(inset)
    card:SetPoint("TOPLEFT", modelCard, "TOPRIGHT", COLUMN_GAP, 0)
    card:SetPoint("TOPRIGHT", inset, "TOPRIGHT", 0, -HEADER_HEIGHT)
    card:SetHeight(DETAILS_HEIGHT)
    local header = NewHeader(card, "Details")
    header:SetPoint("TOP", card, "TOP", 0, -2)

    ui.values = {}
    local art = ns.Art
    for i, spec in ipairs(DETAIL_ROWS) do
        local y = -42 - (i - 1) * ROW_STEP
        if i % 2 == 0 and art and art.CreateStripe then
            local stripe = art.CreateStripe(card)
            stripe:SetPoint("TOPLEFT", card, "TOPLEFT", 6, y + 2)
            stripe:SetPoint("BOTTOMRIGHT", card, "TOPRIGHT", -6, y - ROW_STEP + 2)
        end
        local label = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", card, "TOPLEFT", 14, y - 2)
        label:SetText(spec.label)
        local value = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        value:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, y - 2)
        value:SetPoint("LEFT", label, "RIGHT", 8, 0)
        value:SetJustifyH("RIGHT")
        -- The favorite's hint can run long: it gets a second line.
        if spec.key == "favorite" then
            value:SetJustifyV("TOP")
            value:SetWordWrap(true)
            value:SetMaxLines(2)
        else
            value:SetWordWrap(false)
        end
        ui.values[spec.key] = value
    end
    ui.detailsCard = card
    return card
end

local function BuildMoves(inset, detailsCard, modelCard)
    local card = NewCard(inset)
    card:SetPoint("TOPLEFT", detailsCard, "BOTTOMLEFT", 0, -COLUMN_GAP)
    card:SetPoint("TOPRIGHT", detailsCard, "BOTTOMRIGHT", 0, -COLUMN_GAP)
    card:SetPoint("BOTTOM", modelCard, "BOTTOM", 0, 0)
    local header = NewHeader(card, "Moves")
    header:SetPoint("TOP", card, "TOP", 0, -2)
    ui.movesStatus = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    ui.movesStatus:SetPoint("TOP", header, "BOTTOM", 0, -12)
    ui.moveButtons = {}
    ui.movesCard = card
    return card
end

-- What the Personality card shows, row by row: { part, font, justify }.
-- Two in a row sit side by side when there is room.
local PERSONALITY_LAYOUT = {
    { { "quote", "GameFontHighlightMedium", "CENTER" } },
    { { "likes", "GameFontHighlight" }, { "dislikes", "GameFontHighlight" } },
    { { "personalityLocked", "GameFontHighlightSmall" } },
}

local function NewText(parent, font, justify)
    local fs = parent:CreateFontString(nil, "ARTWORK", font)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(2)
    fs:Hide()
    return fs
end

local ROW_HEADER_HEIGHT = 30   -- the list's zone headers (UI/DexList.lua HEADER_HEIGHT)
local BOOK_ICON = "Interface\\QuestFrame\\UI-QuestLog-BookIcon"

-- A header row across the top of a card, the way the friends list heads
-- each zone: the striped bar, an icon, the title in gold, a count on the
-- right (row.Count).
local function NewRowHeader(card, title, icon)
    local art = ns.Art or {}
    local row = CreateFrame("Frame", nil, card)
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -5)
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -5)
    row:SetHeight(ROW_HEADER_HEIGHT)
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints()
    if art.SetAtlas and not art.SetAtlas(stripe, art.ROW_STRIPE) then art.SetAtlas(stripe, art.ROW_STRIPE_FALLBACK) end
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(16, 16)
    row.Icon:SetPoint("LEFT", 8, 0)
    row.Icon:SetTexture(icon)
    row.Title = row:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    row.Title:SetPoint("LEFT", row.Icon, "RIGHT", 8, 0)
    row.Title:SetText(title)
    row.Count = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.Count:SetPoint("RIGHT", -10, 0)
    row.Count:SetJustifyH("RIGHT")
    return row
end

-- A card with a header (the pill, or with rowIcon a row header) and a
-- scroll frame for its text, footerHeight kept clear at the bottom. A long
-- entry scrolls with the wheel, and a thin bar shows only when there is
-- more than fits.
local function NewScrollCard(parent, title, footerHeight, rowIcon)
    local art = ns.Art or {}
    local card = NewCard(parent)
    local top = -42
    if rowIcon then
        card.Header = NewRowHeader(card, title, rowIcon)
        top = -(5 + ROW_HEADER_HEIGHT + 10)
    else
        local header = NewHeader(card, title)
        header:SetPoint("TOP", card, "TOP", 0, -2)
    end

    local scroll = CreateFrame("ScrollFrame", nil, card)
    scroll:SetPoint("TOPLEFT", card, "TOPLEFT", 18, top)
    scroll:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -26, 10 + (footerHeight or 0))
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    card.scroll, card.child = scroll, child
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar and art.HasTemplate
        and art.HasTemplate("MinimalScrollBar") then
        local bar = CreateFrame("EventFrame", nil, card, "MinimalScrollBar")
        bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, 0)
        bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 0)
        ScrollUtil.InitScrollFrameWithScrollBar(scroll, bar)
        if bar.SetHideIfUnscrollable then bar:SetHideIfUnscrollable(true) end
    else
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local range = tonumber(self:GetVerticalScrollRange()) or 0
            local offset = (tonumber(self:GetVerticalScroll()) or 0) - delta * 30
            self:SetVerticalScroll(math.max(0, math.min(range, offset)))
        end)
    end
    return card
end

-- Under the model: the quote, likes and dislikes.
local function BuildPersonality(inset, modelCard)
    local card = NewScrollCard(inset, "Personality")
    card:SetPoint("TOPLEFT", modelCard, "BOTTOMLEFT", 0, -COLUMN_GAP)
    card:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, 0)
    card.parts, card.rows = {}, {}
    for _, row in ipairs(PERSONALITY_LAYOUT) do
        local strings = {}
        for _, spec in ipairs(row) do
            local fs = NewText(card.child, spec[2], spec[3])
            card.parts[spec[1]] = fs
            strings[#strings + 1] = fs
        end
        card.rows[#card.rows + 1] = strings
    end
    -- Cards size with the window, so the text is laid out once it has a width.
    card.scroll:SetScript("OnSizeChanged", function() LayoutCard(card) end)
    ui.personality = card
end

local STORY_FOOTER = 46   -- the page dots under the entry page
local STORY_SECTIONS = 5  -- Word Around Town, Story, Backstory, Secret, Just Between Friends

-- The column down the right of the page, level with the friends list on
-- the left and headed the same way, so the page reads symmetrically.
local function BuildStory(page, inset)
    local card = NewScrollCard(page, "Lore", STORY_FOOTER, BOOK_ICON)
    card:SetPoint("TOPRIGHT", page, "TOPRIGHT", -16, -80)
    card:SetPoint("BOTTOMLEFT", inset, "BOTTOMRIGHT", STORY_SPACING, 0)
    local child = card.child

    card.note = NewText(child, "GameFontHighlight")
    card.sections = {}
    for i = 1, STORY_SECTIONS do
        local section = {
            header = NewText(child, "GameFontNormalMed2"),
            tag = NewText(child, "GameFontHighlightSmall", "RIGHT"),
            rule = child:CreateTexture(nil, "ARTWORK"),
            body = NewText(child, "GameFontHighlight"),
        }
        section.rule:SetHeight(1)
        section.rule:SetColorTexture(1, 1, 1, 1)
        section.rule:Hide()
        card.sections[i] = section
    end

    -- The footer: a faint rule, a dot per page, and the count.
    local footer = CreateFrame("Frame", nil, card)
    footer:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 18, 10)
    footer:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -18, 10)
    footer:SetHeight(STORY_FOOTER - 6)
    local rule = footer:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT")
    rule:SetPoint("TOPRIGHT")
    rule:SetColorTexture(1, 0.82, 0, 0.2)
    card.pips = footer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    card.pips:SetPoint("TOP", footer, "TOP", 0, -6)
    card.progress = footer:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    card.progress:SetPoint("TOP", card.pips, "BOTTOM", 0, -2)
    footer:Hide()
    card.footer = footer

    card.scroll:SetScript("OnSizeChanged", function() LayoutStory(card) end)
    ui.story = card
end

-- entryColumn: the width UI/DexFrame.lua keeps down the right of the page
-- for the BuddyDex entry, gap included.
local ENTRY_COLUMN_DEFAULT = 374

function Detail.Build(page, leftInset, entryColumn)
    if not page or page.RightInset then return end
    entryColumn = tonumber(entryColumn) or ENTRY_COLUMN_DEFAULT
    -- A plain area, not a card: the cards inside it carry the frames.
    local inset = CreateFrame("Frame", nil, page)
    if leftInset then
        inset:SetPoint("TOPLEFT", leftInset, "TOPRIGHT", 14, 0)
    else
        inset:SetPoint("TOPLEFT", page, "TOPLEFT", 360, -80)
    end
    inset:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -16 - entryColumn, 18)
    page.RightInset = inset
    ui.inset = inset

    BuildHeader(inset)
    local modelCard = BuildModelCard(inset)
    local details = BuildDetails(inset, modelCard)
    BuildMoves(inset, details, modelCard)
    BuildPersonality(inset, modelCard)
    BuildStory(page, inset)
    UpdateText(nil, nil)
    ShowPlaceholder("Pick an NPC to see it here.")
end

-- Whoever came along changed (the buddy's menu, the list's menu): the
-- button says Bring along or Send home to match.
ns.Bus:RegisterCallback(ns.Event.SettingChanged, function(_, key)
    if key == "buddy" then Detail.Redraw() end
end, Detail)
