-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Friendship.lua: friendship with NPCs, the BuddyDex's reputation
-- (ns.Friendship). It owns the tiers, the gains and their daily cap, each
-- NPC's favorite emote, and the listeners that turn what the player does
-- into friendship: talking to an NPC, trading, training, using a service,
-- doing quests for them, and emoting at them.
--
-- Buddies are friendly NPCs only (never hostile mobs), met in person: every
-- gain needs the NPC to be the one the player is interacting with or has
-- targeted, friendly to them right now, and out of combat. Nothing here
-- loads a model, and nothing reads a unit while its identity is restricted.
--
-- Presentation (chat lines, toasts, sounds) lives in UI/Toast.lua, which
-- listens for FriendshipGained.

local Friendship = {}
ns.Friendship = Friendship

local Util = ns.Util

-- Tiers ----------------------------------------------------------------------------
-- WoW's own friendship reputations (the Tillers in Pandaria) use these
-- names. Reaching Buddy befriends an NPC: it can join you, and Friend opens
-- its BuddyDex entry. Points are for a common NPC; rarer NPCs scale up.

Friendship.TIERS = {
    { key = "stranger", label = "Stranger", min = 0 },
    { key = "acquaintance", label = "Acquaintance", min = 100 },
    { key = "buddy", label = "Buddy", min = 300 },
    { key = "friend", label = "Friend", min = 600 },
    { key = "goodfriend", label = "Good Friend", min = 1000 },
    { key = "bestfriend", label = "Best Friend", min = 1500 },
}
Friendship.BUDDY_TIER = 3
Friendship.STORY_TIER = 4

-- Forever's own reputation bars (ColoredProgressBarTemplate) come in four
-- colors: white while getting to know them, green as buddies and friends,
-- blue for the closest.
local TIER_BAR = { "White", "White", "Green", "Green", "Blue", "Blue" }

local RARITY_SCALE = {
    trivial = 0.75, minus = 0.75, normal = 1, elite = 1.5, rare = 2, rareelite = 2.5, worldboss = 3,
}

-- What each kind of interaction is worth, once per NPC per day: coming back
-- tomorrow counts, clicking a vendor fifty times does not.
Friendship.GAINS = {
    talk = 40,       -- gossip or a quest greeting
    shop = 60,       -- buying or selling
    train = 60,      -- a trainer
    service = 50,    -- flight master, bank, auction house
    quest = 100,     -- taking or handing in a quest
    emote = 25,      -- any friendly emote at them
    favorite = 150,  -- their favorite emote
    rude = -25,      -- a rude one
}

local function Scale(entry)
    return RARITY_SCALE[entry and entry.class] or 1
end

local function Threshold(entry, index)
    local tier = Friendship.TIERS[index]
    return tier and math.floor(tier.min * Scale(entry) + 0.5) or nil
end

local function Points(entry)
    return tonumber(Util.Plain(entry and entry.points)) or 0
end

function Friendship.TierIndex(entry)
    local points, index = Points(entry), 1
    for i = 2, #Friendship.TIERS do
        if points >= Threshold(entry, i) then index = i end
    end
    return index
end

-- Where an NPC stands: the tier and the progress through it, for a bar.
function Friendship.TierInfo(entry)
    local index = Friendship.TierIndex(entry)
    local tier = Friendship.TIERS[index]
    local floor, ceiling = Threshold(entry, index), Threshold(entry, index + 1)
    local info = {
        index = index, key = tier.key, label = tier.label, points = Points(entry),
        colorType = TIER_BAR[index],
    }
    if ceiling then
        info.current, info.needed = Points(entry) - floor, ceiling - floor
    else
        info.current, info.needed, info.isMax = 1, 1, true
    end
    return info
end

function Friendship.IsBuddy(entry)
    return Friendship.TierIndex(entry) >= Friendship.BUDDY_TIER
end

function Friendship.HasStory(entry)
    return Friendship.TierIndex(entry) >= Friendship.STORY_TIER
end

-- Favorite emotes -----------------------------------------------------------------
-- Who someone is says what they like: guards respect a salute, merchants
-- good manners, trainers a bow, critters a scratch. The first rule whose
-- words appear in the NPC's title (or name) wins; everyone else likes a wave.

local FAVORITES = {
    { token = "SALUTE", hint = "Respects discipline.", words = { "guard", "mountaineer", "captain",
        "commander", "officer", "marshal", "sergeant", "lieutenant", "soldier", "sentinel", "warden",
        "defender", "knight", "general", "watch", "militia", "battlesmith", "artilleryman", "kingsguard" } },
    { token = "PRAY", hint = "Finds peace in quiet devotion.", words = { "priest", "bishop", "cleric",
        "brother", "sister", "monk", "acolyte", "chaplain", "paladin", "light" } },
    { token = "CHEER", hint = "Loves a bit of enthusiasm.", words = { "innkeeper", "bartender", "brewer",
        "brewmaster", "cook", "chef", "engineer", "tinker", "inventor", "fireworks" } },
    { token = "APPLAUD", hint = "Lives for an audience.", words = { "bard", "musician", "performer",
        "entertainer", "dancer", "storyteller" } },
    { token = "THANK", hint = "Appreciates good manners.", words = { "merchant", "vendor", "supplies",
        "supplier", "trade", "goods", "provisioner", "quartermaster", "auctioneer", "banker", "clerk",
        "outfitter", "dealer", "seller", "keymaster", "recipes", "crafter" } },
    { token = "WAVE", hint = "Sees riders off all day long.", words = { "gryphon master", "flight master",
        "wind rider master", "hippogryph master", "bat handler", "dragonhawk master" } },
    { token = "BOW", hint = "Expects a little ceremony.", words = { "trainer", "master", "artisan",
        "expert", "journeyman", "lord", "lady", "king", "queen", "prince", "princess", "archbishop",
        "advisor", "senator", "historian", "ambassador", "emissary" } },
    { token = "PET", hint = "Just wants a scratch behind the ears.", types = { "critter", "beast" } },
}
local FAVORITE_DEFAULT = { token = "WAVE", hint = "Likes a friendly hello." }

-- Emotes that count as friendly, and ones that hurt a friendship.
local FRIENDLY_EMOTES = {
    WAVE = true, BOW = true, SALUTE = true, THANK = true, HUG = true, CHEER = true, APPLAUD = true,
    GREET = true, HELLO = true, SMILE = true, PRAY = true, PET = true, KISS = true, CURTSEY = true,
    WELCOME = true, PRAISE = true, LOVE = true, DANCE = true, FLEX = true, TICKLE = true, HIGHFIVE = true,
    CLAP = true, GOLFCLAP = true, NOD = true, GRIN = true, BLUSH = true, WINK = true, COMFORT = true,
}
local RUDE_EMOTES = {
    RUDE = true, SPIT = true, SLAP = true, INSULT = true, MOCK = true, CHICKEN = true, FART = true,
    PUNCH = true, THREATEN = true, TAUNT = true, GLARE = true, SCOFF = true, RASP = true,
}

local function Lower(v)
    v = Util.Plain(v)
    return type(v) == "string" and v:lower() or ""
end

-- The favorite for an entry: { token, hint, label ("/salute") }. A BuddyDex
-- entry can name its own (Data/Lore.lua); otherwise the title decides.
function Friendship.Favorite(entry, npcID)
    local lore = npcID and ns.Lore and ns.Lore[npcID]
    local own = type(lore) == "table" and type(lore.favorite) == "table" and lore.favorite
    if own and type(own.emote) == "string" then
        local token = own.emote:upper()
        return { token = token, hint = own.hint or FAVORITE_DEFAULT.hint, label = "/" .. token:lower() }
    end
    local text = Lower(entry and entry.title) .. " " .. Lower(entry and entry.name)
    local kind = Lower(entry and entry.type)
    local pick = FAVORITE_DEFAULT
    for _, rule in ipairs(FAVORITES) do
        local hit = false
        for _, word in ipairs(rule.words or {}) do
            if text:find(word, 1, true) then hit = true break end
        end
        for _, t in ipairs(rule.types or {}) do
            if kind == t then hit = true break end
        end
        if hit then pick = rule break end
    end
    return { token = pick.token, hint = pick.hint, label = "/" .. pick.token:lower() }
end

-- Reading a unit ---------------------------------------------------------------------

local function Text(fn, ...)
    local v = Util.Read(fn, ...)
    if type(v) ~= "string" or v == "" then return nil end
    return v
end

local function Number(fn, ...)
    local v = Util.Read(fn, ...)
    return type(v) == "number" and v or nil
end

-- Identity reads are only meaningful out of combat and while the client is
-- not hiding unit identities (Midnight's restrictions). Checked first, so a
-- restricted unit is never read at all.
local function Restricted(unit)
    if InCombatLockdown() then return true end
    local actions, types = C_RestrictedActions, Enum and Enum.AddOnRestrictionType
    if actions and actions.IsAddOnRestrictionActive and types then
        if Util.Read(actions.IsAddOnRestrictionActive, types.Combat)
            or Util.Read(actions.IsAddOnRestrictionActive, types.Map) then
            return true
        end
    end
    local secrets = C_Secrets
    if secrets and secrets.ShouldUnitIdentityBeSecret and Util.Read(secrets.ShouldUnitIdentityBeSecret, unit) then
        return true
    end
    return false
end

-- Tooltip lines after the name: a title sits above the level line, and a
-- line like "Riley's Pet" marks a unit someone owns.
local OWNED = { "'s Pet", "'s Minion", "'s Companion", "'s Guardian" }

local function ReadTooltip(unit)
    local info = C_TooltipInfo and Util.Read(C_TooltipInfo.GetUnit, unit)
    if type(info) ~= "table" or type(info.lines) ~= "table" then return nil, false end
    local title
    for i = 2, math.min(#info.lines, 5) do
        local line = info.lines[i]
        local text = line and Util.Plain(line.leftText)
        if type(text) == "string" then
            for _, mark in ipairs(OWNED) do
                if text:find(mark, 1, true) then return nil, true end
            end
            if text:find("^Level ") then break end
            title = title or text:gsub("^<(.*)>$", "%1")
        end
    end
    return title, false
end

-- The NPC behind a unit token, if it may be befriended: an NPC (not a
-- player, not anyone's pet), friendly to the player, not attackable, with a
-- name the client has resolved. Returns the NPC ID.
local function FriendlyNpc(unit)
    if not unit or not Util.Read(UnitExists, unit) or Restricted(unit) then return nil end
    if Util.Read(UnitIsPlayer, unit) or Util.Read(UnitPlayerControlled, unit) then return nil end
    local reaction = Number(UnitReaction, unit, "player")
    if not reaction or reaction < 4 then return nil end
    if Util.Read(UnitCanAttack, "player", unit) then return nil end
    local id = Number(UnitCreatureID, unit) or Util.NpcIDFromGUID(Util.Read(UnitGUID, unit))
    local name = Text(UnitName, unit)
    if not id or not name or name == UNKNOWNOBJECT then return nil end
    return id
end

-- The player's map and position on it (0..1), rounded, or nil where the
-- client won't say (instances, restricted maps).
function Friendship.PlayerPosition()
    local map = C_Map
    if not (map and map.GetBestMapForUnit and map.GetPlayerMapPosition) then return nil end
    local mapID = Util.Read(map.GetBestMapForUnit, "player")
    if type(mapID) ~= "number" then return nil end
    local position = Util.Read(map.GetPlayerMapPosition, mapID, "player")
    if type(position) ~= "table" or not position.GetXY then return nil end
    local ok, x, y = pcall(position.GetXY, position)
    x, y = ok and Util.Plain(x), ok and Util.Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return nil end
    return mapID, math.floor(x * 10000 + 0.5) / 10000, math.floor(y * 10000 + 0.5) / 10000
end

-- One of many, or someone -----------------------------------------------------------
-- An NPC named for what they are rather than who they are (Stormwind City
-- Guard, Ironforge Mountaineer, Orgrimmar Grunt, Protector of the People) is
-- one NPC to the game however many of them stand around, so a friendship
-- with one would be a friendship with all of them. They can't be befriended
-- (user, 2026-10-10). A named one is someone (Guard Thomas, Mountaineer
-- Kadrell), and so is any NPC with a lore entry (Data/Lore.lua).
local ROLES = {}
for role in ([[guard guards guardian guardsman patroller sentinel grunt footman peasant citizen
    deathguard bluffwatcher watcher watchman lookout defender soldier marine sailor worker laborer
    miner militia militiaman mountaineer rifleman protector trooper cadet recruit peacekeeper
    warder]]):gmatch("%a+") do
    ROLES[role] = true
end

function Friendship.IsSomeone(name, npcID)
    if npcID and ns.Lore and ns.Lore[npcID] then return true end
    name = Util.Plain(name)
    if type(name) ~= "string" or name == "" then return false end
    local lower = name:lower()
    if lower:find(" of the ", 1, true) then return false end
    local last = lower:match("([%a']+)%s*$")
    return not (last and ROLES[last])
end

local function Snapshot(unit)
    local typeName, typeID = Util.Read(UnitCreatureType, unit)
    local title, owned = ReadTooltip(unit)
    if owned then return nil end
    if typeName == "Non-combat Pet" then return nil end
    local mapID = C_Map and C_Map.GetBestMapForUnit and Util.Read(C_Map.GetBestMapForUnit, "player")
    return {
        name = Text(UnitName, unit),
        title = title,
        type = type(typeName) == "string" and typeName or nil,
        typeID = type(typeID) == "number" and typeID or nil,
        family = Text(UnitCreatureFamily, unit),
        class = Text(UnitClassification, unit),
        level = Number(UnitLevel, unit),
        sex = Number(UnitSex, unit),
        faction = Text(UnitFactionGroup, unit),
        zone = Text(GetZoneText),
        subzone = Text(GetSubZoneText),
        mapID = type(mapID) == "number" and mapID or nil,
        points = 0,
        gains = {},
        visits = 0,
    }
end

-- Gaining ------------------------------------------------------------------------------

local function Friends()
    return ns.db and ns.db.friends
end

-- Adds friendship for kind with the NPC behind unit. Creates the friend on
-- the first gain. Returns true when anything changed.
local function Gain(unit, kind)
    local friends = Friends()
    if not friends then return false end
    local npcID = FriendlyNpc(unit)
    if not npcID then return false end
    local amount = Friendship.GAINS[kind]
    if not amount then return false end

    local entry, isNew = friends[npcID], false
    if not entry then
        -- Nobody becomes a friend by being insulted.
        if amount <= 0 then return false end
        entry = Snapshot(unit)
        if not entry or not Friendship.IsSomeone(entry.name, npcID) then return false end
        entry.first, entry.firstTime = Util.Today(), time()
        isNew = true
    end

    -- Where they are, for a waypoint: the player is next to them right now.
    -- Kept current on every visit, even one that earns nothing today, since
    -- some NPCs wander. Unavailable inside instances.
    local moved = false
    local mapID, x, y = Friendship.PlayerPosition()
    if mapID and (entry.mapID ~= mapID or entry.x ~= x or entry.y ~= y) then
        entry.mapID, entry.x, entry.y = mapID, x, y
        moved = true
    end

    local today = Util.Today()
    if type(entry.gains) ~= "table" then entry.gains = {} end
    if entry.gains[kind] == today then
        if moved and not isNew then ns.Bus:TriggerEvent(ns.Event.NpcUpdated, npcID, entry) end
        return false
    end
    entry.gains[kind] = today

    local before = Friendship.TierIndex(entry)
    local ceiling = Threshold(entry, #Friendship.TIERS)
    entry.points = math.max(0, math.min(ceiling, Points(entry) + amount))
    if amount > 0 then entry.visits = (tonumber(entry.visits) or 0) + 1 end
    entry.last, entry.lastTime = today, time()
    -- A level or a title can arrive late; keep the freshest.
    local level = Number(UnitLevel, unit)
    if level then entry.level = level end
    if not entry.title then entry.title = (ReadTooltip(unit)) end

    if isNew then
        friends[npcID] = entry
        ns.Bus:TriggerEvent(ns.Event.NpcSeen, npcID, entry)
    else
        ns.Bus:TriggerEvent(ns.Event.NpcUpdated, npcID, entry)
    end
    ns.Bus:TriggerEvent(ns.Event.FriendshipGained, npcID, entry, amount, kind, before, Friendship.TierIndex(entry))
    return true
end
Friendship.Gain = Gain

-- For testing (/bd give) ------------------------------------------------------------

-- Starts a friendship with a unit that qualifies, without any points or
-- the usual first interaction. Returns its NPC ID, or nil and the unit's
-- name if it is one of many (IsSomeone).
function Friendship.Meet(unit)
    local friends = Friends()
    local npcID = friends and FriendlyNpc(unit)
    if not npcID then return nil end
    if not friends[npcID] then
        local entry = Snapshot(unit)
        if not entry then return nil end
        if not Friendship.IsSomeone(entry.name, npcID) then return nil, entry.name end
        entry.first, entry.firstTime = Util.Today(), time()
        entry.last, entry.lastTime = entry.first, entry.firstTime
        local mapID, x, y = Friendship.PlayerPosition()
        if mapID then entry.mapID, entry.x, entry.y = mapID, x, y end
        friends[npcID] = entry
        ns.Bus:TriggerEvent(ns.Event.NpcSeen, npcID, entry)
    end
    return npcID
end

-- The points where a tier starts for this NPC (tiers scale by rarity).
function Friendship.Threshold(entry, index)
    return Threshold(entry, index)
end

-- Changes a friendship by any amount, past the daily caps, and fires the
-- events a real gain fires, so the chat line, toast and sounds play.
-- Returns the change actually made (the bar stops at 0 and at Best Friend).
function Friendship.Add(npcID, amount)
    local friends = Friends()
    local entry = friends and friends[npcID]
    if not entry or type(amount) ~= "number" then return 0 end
    local before, old = Friendship.TierIndex(entry), Points(entry)
    local ceiling = Threshold(entry, #Friendship.TIERS)
    entry.points = math.max(0, math.min(ceiling, math.floor(old + amount + 0.5)))
    local change = entry.points - old
    if change == 0 then return 0 end
    ns.Bus:TriggerEvent(ns.Event.NpcUpdated, npcID, entry)
    ns.Bus:TriggerEvent(ns.Event.FriendshipGained, npcID, entry, change, "dev", before, Friendship.TierIndex(entry))
    return change
end

-- Interactions: the "npc" unit is whoever the player is dealing with.
local INTERACTIONS = {
    GOSSIP_SHOW = "talk",
    QUEST_GREETING = "talk",
    QUEST_DETAIL = "quest",
    QUEST_PROGRESS = "quest",
    QUEST_COMPLETE = "quest",
    MERCHANT_SHOW = "shop",
    TRAINER_SHOW = "train",
    TAXIMAP_OPENED = "service",
    BANKFRAME_OPENED = "service",
    AUCTION_HOUSE_SHOW = "service",
}

-- Windows only an NPC opens. Gossip and quests also come from objects (a
-- book, a wanted poster), which have no "npc" unit.
local NPC_ONLY = {
    MERCHANT_SHOW = true, TRAINER_SHOW = true, TAXIMAP_OPENED = true,
    BANKFRAME_OPENED = true, AUCTION_HOUSE_SHOW = true,
}

-- An "npc" unit that doesn't qualify (hostile, say) counts for nobody: never
-- for whoever the player has targeted. Only when the client won't name the
-- "npc" unit for a window only an NPC opens does the target stand in, since
-- right-clicking an NPC targets it.
local function OnInteraction(_, event)
    local kind = INTERACTIONS[event]
    if not kind then return end
    local ok, err = pcall(function()
        if Util.Read(UnitExists, "npc") then
            Gain("npc", kind)
        elseif NPC_ONLY[event] then
            Gain("target", kind)
        end
    end)
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
    end
end

-- Emotes: DoEmote(token, target) runs for /wave and friends and for the
-- emote menu. A post-hook only reads what happened. The emote's target is
-- the named unit or, without one, the player's target.
local function OnEmote(token, target)
    token = Util.Plain(token)
    if type(token) ~= "string" then return end
    token = token:upper()
    local unit = "target"
    target = Util.Plain(target)
    if type(target) == "string" and target ~= "" and Util.Read(UnitExists, target) then unit = target end
    local friends = Friends()
    if not friends then return end

    if RUDE_EMOTES[token] then
        Gain(unit, "rude")
        return
    end
    if not FRIENDLY_EMOTES[token] then return end

    -- Emotes deepen a friendship but never start one: an NPC has to be met
    -- first, by talking, trading, training, traveling or questing with
    -- them. NPCs with nothing to say (guards, townsfolk) stay out of the Dex.
    local npcID = FriendlyNpc(unit)
    if not npcID then return end
    local entry = friends[npcID]
    if not entry then return end
    local favorite = Friendship.Favorite(entry, npcID)
    if token == favorite.token then
        if Gain(unit, "favorite") then
            local friend = friends[npcID]
            if friend and not friend.favoriteFound then
                friend.favoriteFound = true
                ns.Bus:TriggerEvent(ns.Event.NpcUpdated, npcID, friend)
            end
        end
    else
        Gain(unit, "emote")
    end
end

local frame = CreateFrame("Frame")
for event in pairs(INTERACTIONS) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", OnInteraction)

if hooksecurefunc and DoEmote then
    hooksecurefunc("DoEmote", function(token, target)
        local ok, err = pcall(OnEmote, token, target)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
        end
    end)
end

-- Friends made before the one-of-many rule who break it leave the Dex at
-- login, with a word in chat.
ns.Bus:RegisterCallback(ns.Event.Login, function()
    local friends, database = Friends(), ns.Database
    if not (friends and database and database.Remove) then return end
    local leaving = {}
    for npcID, entry in pairs(friends) do
        if not Friendship.IsSomeone(entry.name, npcID) then leaving[npcID] = Util.Plain(entry.name) or "Someone" end
    end
    for npcID, name in pairs(leaving) do
        database.Remove(npcID)
        ns.Print("%s left the BuddyDex: every %s is the same NPC to the game, so they can't be befriended one at a time.",
            name, name)
    end
end, Friendship)
