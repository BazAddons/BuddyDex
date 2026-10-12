-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Data/Art.lua: every texture, atlas and color the BuddyDex UI draws with,
-- and the helpers that turn a roster entry into art: its creature-type
-- badge, its list icon, its rarity and the color of that rarity. Other
-- files ask for ns.Art.ROW_BG and friends instead of writing paths, so art
-- that turns out to be missing on this client is fixed here, once.
--
-- Every file path below is in the client's art export, and every atlas is
-- used by Blizzard code that loads for Camelot (docs/research/art.md). The
-- atlas database itself is client data the export does not include, which
-- is why atlases only ever reach a texture through Art.SetAtlas.

local Art = {}
ns.Art = Art

-- Roster values are saved plain, but a caller handing a Unit* result
-- straight through must not be able to turn a secret into a table key.
-- ns.Util.Plain is the one check (Core/Namespace.lua loads first); the
-- local copy only matters if that file failed to load.
local function Plain(v)
    local util = ns.Util
    if util and util.Plain then return util.Plain(v) end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

-- Textures and atlases --------------------------------------------------------

-- The window portrait. PortraitFrameTemplate masks it into a circle, which
-- suits a square icon; an already round portrait would be masked twice.
Art.PORTRAIT = "Interface\\Icons\\Achievement_Character_Gnome_Male"

-- The model card is the mount journal's backdrop. Its art fills only the
-- left 0.785 of the 512 px file and the rest shows as a seam, so it is
-- always drawn with MODEL_BG_COORDS (left, right, top, bottom).
Art.MODEL_BG = "Interface\\PetBattles\\MountJournal-BG"
Art.MODEL_BG_COORDS = { 0, 0.78515625, 0, 1 }

-- The journal's own picture for an empty card: nothing picked, or a model
-- that never loaded.
Art.MODEL_EMPTY = "Interface\\PetBattles\\MountJournal-NoMounts"

-- List rows copy the mount and pet journal rows. Those templates live in
-- load-on-demand Blizzard_Collections, so only their art is reused.
Art.ROW_BG = "PetList-ButtonBackground"
Art.ROW_HIGHLIGHT = "PetList-ButtonHighlight"
Art.ROW_SELECTED = "PetList-ButtonSelect"
Art.NEW_GLOW = "collections-newglow"

-- Row icons. The border is white so it can be tinted by rarity, the way
-- the pet journal tints it by quality.
Art.ICON_BORDER = "Interface\\Common\\WhiteIconFrame"
Art.EMPTY_ICON = "Interface\\PetBattles\\MountJournalEmptyIcon"
Art.UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- The caught mark, with the ready-check tick as its file fallback.
Art.CAUGHT = "checkmark-minimal"
Art.CAUGHT_FALLBACK = "Interface\\RaidFrame\\ReadyCheck-Ready"

-- Rarity rings: the dragons Camelot's own target frame puts around a
-- portrait (Blizzard_UnitFrame/Camelot/TargetFrameUtils.lua). Camelot
-- spells the silver one differently from Mainline, so these are its names.
Art.RING_ELITE = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold"
Art.RING_RARE = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged"
Art.RING_BOSS = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged"

-- SetAtlas ---------------------------------------------------------------------

-- Textures this file hid because it could draw neither their atlas nor a
-- fallback. Only those are shown again when a later call succeeds, so a
-- texture its owner hid on purpose (a selection overlay, a caught mark on
-- an uncaught row) stays hidden. Weak keys keep the bookkeeping from
-- holding anything alive.
local hiddenByArt = setmetatable({}, { __mode = "k" })

local function Restore(tex)
    if hiddenByArt[tex] then
        hiddenByArt[tex] = nil
        tex:Show()
    end
end

-- What to draw for this file's own atlases when the caller passed no
-- fallback. They only matter if this client's atlas data lacks the name,
-- and each one keeps the row readable rather than leaving a hole: dark
-- and gold washes for the row background and selection (the colors the
-- scroll-list research settled on), the quest log's title highlight for
-- hover, and the ready-check tick for caught. size stands in for
-- useAtlasSize, which a file cannot honor: a texture anchored by a single
-- point would otherwise stay 0 x 0.
local STAND_INS = {
    [Art.ROW_BG] = { color = { 0, 0, 0, 0.35 } },
    [Art.ROW_SELECTED] = { color = { 1, 0.82, 0, 0.18 } },
    [Art.ROW_HIGHLIGHT] = { file = "Interface\\QuestFrame\\UI-QuestTitleHighlight", blend = "ADD" },
    [Art.CAUGHT] = { file = Art.CAUGHT_FALLBACK, size = 18 },
}

local function AtlasExists(atlas)
    if type(atlas) ~= "string" or atlas == "" then return false end
    local getInfo = C_Texture and C_Texture.GetAtlasInfo
    if not getInfo then return false end
    local ok, info = pcall(getInfo, atlas)
    return ok and type(info) == "table"
end

-- A file path or file ID. The coordinates are reset because a texture that
-- last held an atlas or an icon would otherwise keep showing that crop.
local function ApplyFile(tex, file)
    if not pcall(tex.SetTexture, tex, file) then return false end
    tex:SetTexCoord(0, 1, 0, 1)
    return true
end

-- { r, g, b[, a] }, or anything with r/g/b/a fields, such as a ColorMixin.
local function ApplyColor(tex, color)
    local r = color.r or color[1]
    local g = color.g or color[2]
    local b = color.b or color[3]
    local a = color.a or color[4]
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
    return (pcall(tex.SetColorTexture, tex, r, g, b, type(a) == "number" and a or 1))
end

local function ApplyFallback(tex, fallback)
    local kind = type(fallback)
    if kind == "string" or kind == "number" then return ApplyFile(tex, fallback) end
    if kind == "table" then return ApplyColor(tex, fallback) end
    return false
end

local function ApplyStandIn(tex, standIn, useAtlasSize)
    local applied
    if standIn.file then
        applied = ApplyFile(tex, standIn.file)
        if applied and standIn.blend then pcall(tex.SetBlendMode, tex, standIn.blend) end
    elseif standIn.color then
        applied = ApplyColor(tex, standIn.color)
    end
    if applied and useAtlasSize and standIn.size then
        pcall(tex.SetSize, tex, standIn.size, standIn.size)
    end
    return applied
end

-- The only way an atlas reaches a texture. An unknown atlas name fails
-- silently in the client and leaves a blank texture, so the name is
-- checked first. Order of preference: the atlas; the caller's fallback (a
-- file path or ID, or a color table); this file's stand-in for its own
-- atlases; otherwise the texture is cleared and hidden. Visibility is
-- otherwise left alone: the only texture this shows is one it hid itself.
-- Passing a nil atlas therefore clears and hides, which suits a ring that
-- only some NPCs get. Returns true when the atlas itself was used.
function Art.SetAtlas(tex, atlas, fallbackFile, useAtlasSize)
    if not tex then return false end
    atlas = Plain(atlas)
    if AtlasExists(atlas) and pcall(tex.SetAtlas, tex, atlas, useAtlasSize and true or false) then
        Restore(tex)
        return true
    end

    local applied
    if fallbackFile then
        applied = ApplyFallback(tex, fallbackFile)
    else
        local standIn = type(atlas) == "string" and STAND_INS[atlas]
        applied = standIn and ApplyStandIn(tex, standIn, useAtlasSize)
    end

    if applied then
        Restore(tex)
    else
        -- Cleared as well as hidden, so an owner that shows it later (a
        -- pooled row toggling its caught mark) shows nothing rather than
        -- whatever art the texture held before.
        pcall(tex.SetTexture, tex, nil)
        if tex.Hide then tex:Hide() end
        hiddenByArt[tex] = true
    end
    return false
end

-- Creature types ---------------------------------------------------------------

-- Pet-battle family badges: self-contained 32 x 32 round files, drawn
-- whole. Pet families are not creature types: the badge is "Dragon", not
-- "Dragonkin", and there is no Demon, Giant or Aberration family, so Demon
-- and Giant borrow the hunter's Track Demons and Track Giants icons and
-- Aberration an eye, cropped like any icon. Keys are lowercased
-- creature-type names; the client's localized names are English.
local BADGE = "Interface\\TargetingFrame\\PetBadge-"

local TYPE_ART = {
    ["humanoid"] = { file = BADGE .. "Humanoid", badge = true },
    ["beast"] = { file = BADGE .. "Beast", badge = true },
    ["dragonkin"] = { file = BADGE .. "Dragon", badge = true },
    ["undead"] = { file = BADGE .. "Undead", badge = true },
    ["critter"] = { file = BADGE .. "Critter", badge = true },
    ["non-combat pet"] = { file = BADGE .. "Critter", badge = true },
    ["elemental"] = { file = BADGE .. "Elemental", badge = true },
    ["mechanical"] = { file = BADGE .. "Mechanical", badge = true },
    ["demon"] = { file = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
    ["giant"] = { file = "Interface\\Icons\\Ability_Racial_Avatar" },
    ["aberration"] = { file = "Interface\\Icons\\INV_Misc_Eye_01" },
}

-- Everything else (Totem, Gas Cloud, Not specified, a type this table has
-- never heard of) gets the question mark.
local UNKNOWN_ART = { file = Art.UNKNOWN_ICON }

-- UnitCreatureType's second return, the creature-type ID, for an entry
-- whose name does not match: a client in another language, or an entry
-- saved without a name. These are the standard CreatureType IDs. The
-- exported code never lists them, so they are not verified in this client,
-- which is why the name is tried first.
local TYPE_NAMES = {
    [1] = "beast", [2] = "dragonkin", [3] = "demon", [4] = "elemental",
    [5] = "giant", [6] = "undead", [7] = "humanoid", [8] = "critter",
    [9] = "mechanical", [10] = "not specified", [11] = "totem",
    [12] = "non-combat pet", [13] = "gas cloud", [14] = "wild pet",
    [15] = "aberration",
}

local function TypeArt(entry)
    if type(entry) ~= "table" then return UNKNOWN_ART end
    local name = Plain(entry.type)
    local art = type(name) == "string" and TYPE_ART[name:lower()]
    if art then return art end
    local id = Plain(entry.typeID)
    local idName = type(id) == "number" and TYPE_NAMES[id]
    return idName and TYPE_ART[idName] or UNKNOWN_ART
end

-- Draws the creature-type badge (or icon) for a roster entry. Every call
-- sets the crop as well as the file, because list textures are pooled and
-- the last NPC's crop must not carry over. Badges are drawn whole; icons
-- lose the bevel baked into their edges, the way Blizzard draws icons
-- inside its own borders. Returns the file it drew.
function Art.SetTypeIcon(tex, entry)
    if not tex then return nil end
    local art = TypeArt(entry)
    tex:SetTexture(art.file)
    if art.badge then
        tex:SetTexCoord(0, 1, 0, 1)
    else
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    Restore(tex)
    return art.file
end

-- The list icon: the NPC's own 2D portrait once the Dex has cached its
-- display ID (the client renders it from game data, no model frame
-- involved), the creature-type badge until then. Returns true when the
-- portrait was used.
function Art.SetRowIcon(tex, entry)
    if not tex then return false end
    local display = type(entry) == "table" and Plain(entry.display)
    if type(display) == "number" and display > 0 and SetPortraitTextureFromCreatureDisplayID then
        if pcall(SetPortraitTextureFromCreatureDisplayID, tex, display) then
            -- The portrait fills its texture; drop any icon crop left on it.
            tex:SetTexCoord(0, 1, 0, 1)
            Restore(tex)
            return true
        end
    end
    Art.SetTypeIcon(tex, entry)
    return false
end

-- Rarity ---------------------------------------------------------------------------

-- UnitClassification values mapped onto item quality, so rarity borrows
-- colors players already read: gray critter-level mobs, white commons,
-- green elites, blue rares, purple rare elites and orange bosses. "minus"
-- (the weaker mobs that come in groups) shares trivial's record, so the
-- filter treats the two as one.
--
-- The contract writes a record as { key, label, quality }, so each carries
-- both the named fields and the same values by position. The records are
-- shared between callers and must be treated as read-only.
local function Record(key, label, quality)
    return { key = key, label = label, quality = quality, key, label, quality }
end

local RARITY = {
    trivial = Record("trivial", "Critter-level", 0),
    normal = Record("normal", "Common", 1),
    elite = Record("elite", "Elite", 2),
    rare = Record("rare", "Rare", 3),
    rareelite = Record("rareelite", "Rare elite", 4),
    worldboss = Record("worldboss", "Boss", 5),
}
RARITY.minus = RARITY.trivial

local function RarityOf(class)
    local key = Plain(class)
    return type(key) == "string" and RARITY[key] or RARITY.normal
end

-- { key, label, quality } for a classification; anything unknown is normal.
function Art.Rarity(class)
    return RarityOf(class)
end

-- The item-quality color of a classification's rarity. ColorManager comes
-- first because it honors the player's colorblind and color-override
-- settings; Blizzard asks code outside Blizzard_Colors not to read its
-- tables directly.
function Art.RarityColor(class)
    local quality = RarityOf(class).quality

    local manager = ColorManager
    if manager and manager.GetColorDataForItemQuality then
        local ok, data = pcall(manager.GetColorDataForItemQuality, quality)
        if ok and type(data) == "table" and type(data.r) == "number"
            and type(data.g) == "number" and type(data.b) == "number" then
            return data.r, data.g, data.b
        end
    end

    local getColor = C_Item and C_Item.GetItemQualityColor
    if getColor then
        local ok, r, g, b = pcall(getColor, quality)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            return r, g, b
        end
    end

    return 1, 1, 1
end

-- The ring atlas for a classification, or nil when it gets none. Camelot's
-- convention: gold winged for bosses, silver winged for rares and rare
-- elites, plain gold for elites. Made for Art.SetAtlas, where nil hides
-- the ring.
local RINGS = {
    worldboss = Art.RING_BOSS,
    rareelite = Art.RING_RARE,
    rare = Art.RING_RARE,
    elite = Art.RING_ELITE,
}

function Art.RarityRing(class)
    return RINGS[RarityOf(class).key]
end

-- Filter menu lists ---------------------------------------------------------------

-- Rarity keys, rarest first. "minus" has no row of its own: it is trivial.
Art.RARITY_ORDER = { "worldboss", "rareelite", "rare", "elite", "normal", "trivial" }

-- Creature types the filter always offers. Types missing from this list
-- but present in the roster are added by the list at runtime.
Art.TYPES = {
    "Humanoid", "Beast", "Critter", "Demon", "Dragonkin", "Elemental",
    "Giant", "Mechanical", "Undead", "Aberration", "Not specified",
}

-- The Legacy look -------------------------------------------------------------------
-- The user wants the BuddyDex to wear Forever's own Legacy window: the
-- copper PortraitFrameTemplate (which the window already is) over the
-- Legacy reward track's page background, with dark cards laid on it. The
-- background is the atlas LegacyRewardTrackPageTemplate fills its page
-- with (Blizzard_LegacyRewardTrack.xml:74-86); a frame stack of the live
-- window shows it as RewardTrackPage.Background over LegacySystemFrameBg.
Art.WINDOW_BG = "Legacy-Rewards-Tracker-background"

-- A Blizzard template exists for this client. CreateFrame with a missing
-- one throws ("Couldn't find inherited node"), and some templates in the
-- export are gated to game types Forever does not answer to.
function Art.HasTemplate(name)
    local util = C_XMLUtil
    if not (util and util.GetTemplateInfo) then return false end
    local ok, info = pcall(util.GetTemplateInfo, name)
    return ok and info ~= nil
end

-- The cards the panels sit in: the tooltip border with a dark fill, the
-- way the BazUI codex boxes its sections (Modules/Codex/Panel.lua,
-- Panel.CreateBox). Without the template it falls back to an inset.
local CARD_TEMPLATE = "TooltipBackdropTemplate"
Art.CARD_FILL = { 0.02, 0.02, 0.02, 0.62 }

function Art.CreateCard(parent, frameType)
    local card
    if Art.HasTemplate(CARD_TEMPLATE) then
        card = CreateFrame(frameType or "Frame", nil, parent, CARD_TEMPLATE)
        if card.SetBackdropColor then
            card:SetBackdropColor(Art.CARD_FILL[1], Art.CARD_FILL[2], Art.CARD_FILL[3], Art.CARD_FILL[4])
        end
    else
        card = CreateFrame(frameType or "Frame", nil, parent, "InsetFrameTemplate")
    end
    return card
end

-- Side-tab icons, Legacy style (all three are in the art export).
Art.TAB_ICONS = {
    "Interface\\Icons\\INV_Misc_Book_09",
    "Interface\\Icons\\Achievement_Character_Gnome_Male",
    "Interface\\Icons\\INV_Misc_Gear_01",
}

-- Section headers, stripes and small buttons ------------------------------------
-- The carved pill heading and the row stripe come from Forever's own
-- character sheet (Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml:78-93,
-- PaperDollFrame.xml:175): a 196 x 40 frame filled by the pill atlas with
-- its label centered one pixel up.
Art.HEADER_PILL = "UI-Character-Info-Title"
Art.ROW_STRIPE = "UI-Character-Info-Line-Bounce2"
Art.ROW_STRIPE_FALLBACK = "UI-Character-Info-Line-Bounce"

function Art.CreateSectionHeader(parent, text)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(196, 40)
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Art.SetAtlas(bg, Art.HEADER_PILL)
    local label = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("CENTER", 0, 1)
    label:SetText(text)
    header.Label = label
    return header
end

-- A faint stripe for every other row of a list or a block of details.
function Art.CreateStripe(parent)
    local stripe = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
    if not Art.SetAtlas(stripe, Art.ROW_STRIPE) then
        Art.SetAtlas(stripe, Art.ROW_STRIPE_FALLBACK)
    end
    stripe:SetAlpha(0.55)
    return stripe
end

-- A slim button for the cards: the cards' thin border and dark fill, gold
-- text, a soft gold wash on hover. Lighter than UIPanelButtonTemplate's red,
-- which crowds a card when there are ten of them.
function Art.CreateSmallButton(parent, width, height)
    local template = Art.HasTemplate(CARD_TEMPLATE) and CARD_TEMPLATE or nil
    local button = CreateFrame("Button", nil, parent, template)
    button:SetSize(width, height)
    if button.SetBackdropColor then button:SetBackdropColor(0.08, 0.06, 0.04, 0.9) end
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("CENTER", 0, 0)
    button:SetFontString(label)
    -- Gold, white under the mouse, gray when it can't be used.
    button:SetNormalFontObject("GameFontNormalSmall")
    button:SetHighlightFontObject("GameFontHighlightSmall")
    button:SetDisabledFontObject("GameFontDisableSmall")
    button:SetPushedTextOffset(1, -1)
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetPoint("TOPLEFT", 3, -3)
    hover:SetPoint("BOTTOMRIGHT", -3, 3)
    hover:SetColorTexture(1, 0.82, 0, 0.15)
    return button
end

-- Friendship bars ------------------------------------------------------------------
-- The bar Forever's own reputation panel draws (ReputationBarTemplate is
-- ColoredProgressBarTemplate at 160 x 29, Blizzard_UIPanels_Game/Camelot/
-- ReputationFrame.xml:56), so friendship reads like reputation. It sizes its
-- fill from its width, so every bar is given an explicit size.
local BAR_TEMPLATE = "ColoredProgressBarTemplate"

function Art.CreateFriendshipBar(parent, width, height, font)
    height = height or 29
    local bar
    if Art.HasTemplate(BAR_TEMPLATE) then
        bar = CreateFrame("Frame", nil, parent, BAR_TEMPLATE)
        bar:SetSize(width, height)
        if font and bar.Text then pcall(bar.Text.SetFontObject, bar.Text, font) end
    else
        bar = CreateFrame("Frame", nil, parent)
        bar:SetSize(width, height)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.6)
        bar.Fill = bar:CreateTexture(nil, "BORDER")
        bar.Fill:SetPoint("LEFT", 2, 0)
        bar.Fill:SetHeight(math.max(4, height - 10))
        bar.Fill:SetColorTexture(0.25, 0.8, 0.25)
        bar.Text = bar:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
        bar.Text:SetPoint("CENTER")
        function bar:SetFillPercent(p)
            self.Fill:SetWidth(math.max(1, p * (self:GetWidth() - 4)))
        end
        function bar:SetText(text) self.Text:SetText(text) end
    end

    -- info is ns.Friendship.TierInfo(entry).
    function bar:SetFriendship(info, text)
        local mixin = ColoredProgressBarMixin
        if mixin and mixin.ColorType and self.SetFillTextureByColorType and info.colorType then
            -- Resets the fill's size to the atlas, so the percent comes after.
            pcall(self.SetFillTextureByColorType, self, mixin.ColorType[info.colorType])
        end
        local percent = 1
        if not info.isMax then
            percent = (info.needed or 0) > 0 and (info.current or 0) / info.needed or 0
        end
        self:SetFillPercent(percent)
        if text == nil then
            text = info.isMax and info.label or ("%d / %d"):format(info.current or 0, info.needed or 0)
        end
        self:SetText(text)
    end
    return bar
end

-- The Mini Me's portrait: the game's own gnome race art, male or female to
-- match the player. A 3D Mini Me cannot be cut into the window's circle
-- (models take no masks) and the game paints flat portraits only of real
-- units and NPC displays, so the circle and the Buddy tab use this; the
-- Buddy page shows the 3D Mini Me itself.
Art.GNOME_PORTRAITS = {
    [2] = "Interface\\Icons\\Achievement_Character_Gnome_Male",
    [3] = "Interface\\Icons\\Achievement_Character_Gnome_Female",
}

function Art.MiniMePortrait()
    local sex = ns.Util and ns.Util.Read and ns.Util.Read(UnitSex, "player")
    return Art.GNOME_PORTRAITS[sex] or Art.PORTRAIT
end
