-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Reactions.lua: what the buddy notices (ns.Reactions). Game events,
-- friendships and the player's own emotes become lines (Data/Lines.lua,
-- Data/NpcLines.lua), said by UI/Companion.lua with an emote picked from
-- the moment's list.
--
-- Big moments (the greeting, a level, a new Buddy, the player emoting at
-- it) always get a line. The rest are small comments: only when the
-- options say it comments, never over another line, never in the burst of
-- events while the world loads, and each kind only now and then. A fight
-- gets a battle cry or a fighting stance at the start and a celebration at
-- the end, and quiet in between.

local Reactions = {}
ns.Reactions = Reactions

local Util = ns.Util

local MUTE_AFTER_LOAD = 10        -- seconds of quiet while the world loads

-- How much it talks is one slider, chattiness (0 to 100, default 50):
--   0     it only answers the player (pokes, emotes at it)
--   low   big moments only (greeting, level, new Buddy), idle chatter rare
--   50    comments most of the time, idle chatter every 4 to 8 minutes,
--         some fights get a line
--   100   every comment it can, idle chatter every 2 to 4 minutes, fights
--         twice as talkative
-- The gap between comments and each kind's cooldown stretch as it drops.
local GAP_MIN, GAP_SPREAD = 8, 22 -- seconds between comments: 8 at 100%, 30 at 0%
Reactions.IDLE_BASE = 120         -- seconds between idle chatter at 100%: twice that at 50%
local COOLDOWN = {
    zone = 90, gear = 300, quest = 20, questAccepted = 60, rest = 600, newFriend = 15, tier = 5, alive = 10,
    mount = 300, loot = 20, mail = 600, bagsFull = 120, group = 60, dungeon = 60, learned = 30,
    taxi = 30, landed = 30, combatEnd = 60, seeFriend = 20, died = 10, combatMid = 90, combatLong = 120, ghost = 10,
    combatStart = 45, lowHealth = 240,
}
local SEE_FRIEND_AGAIN = 600      -- seconds before the same friend is pointed out again
local STANCE_GAP = 4              -- seconds between fighting stances, for quick pulls
local MID_FIGHT = { 8, 14 }       -- seconds into a fight for a cheer from the sidelines
local LONG_FIGHT = 30             -- seconds into a fight for some encouragement
local LOW_HEALTH = 0.15           -- of the player's health, in a fight

-- How often a fight gets words at full chattiness (scaled down with it): a
-- battle cry at the start (else a stance), a cheer partway, encouragement
-- in a long one, a worried line at low health, words at the end (else a
-- gesture). Most fights get a gesture or nothing: the same line every pull
-- grates. The cooldowns space them out further.
Reactions.FIGHT_CHANCES = { combatStart = 0.4, combatMid = 0.6, combatLong = 0.7, lowHealth = 0.7, combatEnd = 0.45 }

local HEARTHSTONE = 8690
local SECOND_TAXI_LINE = 40       -- seconds into a flight for a second remark

-- Emotes (Data/Moves.lua, all checked on a gnome).
local TALK, BOW, WAVE, CHEER, DANCE, LAUGH, RUDE, ROAR = 60, 66, 67, 68, 69, 70, 73, 74
local KNEEL, CRY, CHICKEN, BEG, APPLAUD, SHOUT, FLEX, SHY, POINT = 75, 77, 78, 79, 80, 81, 82, 83, 84
local SIT, SLEEP, SALUTE = 97, 100, 113

local ANIMS = {
    greet = { WAVE, WAVE, BOW, SALUTE, CHEER },
    levelUp = { CHEER, DANCE, FLEX, APPLAUD, SALUTE, SHOUT },
    died = { CRY, KNEEL, BEG },
    ghost = { SHY, BEG, TALK },
    alive = { CHEER, SHY, FLEX, LAUGH },
    quest = { APPLAUD, CHEER, FLEX, DANCE, BOW },
    questAccepted = { POINT, SALUTE, TALK },
    zone = { POINT, WAVE, TALK },
    gear = { FLEX, SHY, DANCE },
    newFriend = { WAVE, BOW, CHEER },
    tier = { APPLAUD, CHEER, DANCE },
    buddy = { CHEER, DANCE, APPLAUD },
    rest = { SIT, TALK },
    combatStart = { ROAR, SHOUT, POINT, FLEX },
    combatMid = { CHEER, SHOUT, POINT, FLEX, APPLAUD },
    combatLong = { SHOUT, BEG, CHEER },
    lowHealth = { SHY, CRY, BEG, SHOUT },
    combatEnd = { CHEER, APPLAUD, FLEX, LAUGH, SALUTE, DANCE, BOW },
    taxi = { CHEER, LAUGH, WAVE, POINT },
    landed = { KNEEL, BOW, TALK },
    mount = { CHEER, POINT, SALUTE },
    loot = { CHEER, POINT, DANCE },
    mail = { POINT, TALK },
    bagsFull = { CRY, BEG, SHY },
    group = { WAVE, DANCE, CHEER },
    dungeon = { POINT, SHOUT, SALUTE },
    hearth = { WAVE, BOW },
    seeFriend = { WAVE, POINT, BOW },
    learned = { FLEX, APPLAUD, TALK },
    back = { WAVE, SALUTE, CHEER },
    idle = { TALK, TALK, POINT, SHY, LAUGH },
}
-- Now and then the idle chatter is a gesture instead.
local FUN_MOVES = { DANCE, FLEX, LAUGH, CHEER, SHY, POINT, BOW, SALUTE, SIT, APPLAUD }
local IDLE_GESTURE_CHANCE = 0.3

-- The player's emotes it answers, when nothing is targeted: the lines to
-- say, the animation, and how long to hold it for some.
local MIRRORS = {
    WAVE = { "waveBack", WAVE }, DANCE = { "danceAlong", DANCE, 8 }, CHEER = { "cheerAlong", CHEER },
    LAUGH = { "laughAlong", LAUGH }, BOW = { "bowBack", BOW }, SALUTE = { "saluteBack", SALUTE },
    THANK = { "thanked", BOW }, HUG = { "hugged", SHY }, KISS = { "kissed", SHY },
    CRY = { "comforted", SHY }, FLEX = { "flexBack", FLEX }, CHICKEN = { "chickenBack", CHICKEN },
    ROAR = { "roarBack", ROAR }, RUDE = { "rudeBack", RUDE }, SLEEP = { "sleepToo", SLEEP, 8 },
    SIT = { "sitToo", SIT, 6 }, POINT = { "pointToo", POINT }, SHY = { "shyToo", SHY },
    APPLAUD = { "applaudToo", APPLAUD }, CLAP = { "applaudToo", APPLAUD }, JOKE = { "jokeBack", LAUGH },
}
local MIRROR_GAP = 2

local muteUntil, lastSaid = 0, 0
local lastByKey = {}
local seenFriends = {}
local lastZone
local away, onTaxi = false, false
local lastStance, lastMirror = 0, 0
local fight = 0   -- counts fights, so a cheer meant for one never lands in the next
local lowHealthFight              -- the fight the low-health line was said in
local idleTimer

local function Settings()
    return ns.db and ns.db.settings or {}
end

-- Chattiness, 0 to 1.
local function Chattiness()
    local value = tonumber(Settings().chattiness)
    if not value then return 0.5 end
    return math.max(0, math.min(1, value / 100))
end
Reactions.Chattiness = Chattiness

local function FightChance(key)
    return math.random() < (Reactions.FIGHT_CHANCES[key] or 0) * Chattiness()
end

local function Companion()
    local companion = ns.Companion
    return companion and companion.IsShown() and companion or nil
end

-- Says a line for a moment. anims: one or a list (a line's own wins); nil
-- for the moment's usual ones. big: a big moment, said whenever it talks at
-- all. opts.answer: the player spoke to it, always answered. Returns true if
-- it was said.
function Reactions.React(key, ctx, anims, big, opts)
    local companion = Companion()
    if not companion then return false end
    local now = GetTime()
    local chattiness = Chattiness()
    if not (opts and opts.answer) and chattiness <= 0 then return false end
    if not big then
        if now < muteUntil or companion.IsTalking() then return false end
        if now - lastSaid < GAP_MIN + (1 - chattiness) * GAP_SPREAD then return false end
        local cooldown, last = COOLDOWN[key], lastByKey[key]
        if cooldown and last and now - last < cooldown * (1.5 - chattiness) then return false end
        -- Below about 60%, some comments go unsaid.
        if math.random() >= math.min(1, chattiness * 1.6) then return false end
    end
    if anims == nil then anims = ANIMS[key] end
    if companion.SayLine(key, ctx, anims, opts) then
        lastSaid, lastByKey[key] = now, now
        return true
    end
    return false
end
local React = Reactions.React

-- "a Buddy", "an Acquaintance".
local function WithArticle(label)
    return (label:match("^[AEIOU]") and "an " or "a ") .. label
end

-- Half the time, a greeting for the time of day.
local function GreetKey()
    if math.random() < 0.5 then
        local companion = ns.Companion
        local time = companion and companion.TimeOfDay and companion.TimeOfDay() or "afternoon"
        return "greet" .. time:sub(1, 1):upper() .. time:sub(2)
    end
    return "greet"
end

local function MaxLevel()
    local level = GetMaxPlayerLevel and Util.Read(GetMaxPlayerLevel)
    return tonumber(level) or 60
end

local function ScheduleIdle()
    if idleTimer then idleTimer:Cancel() end
    idleTimer = nil
    local chattiness = Chattiness()
    if chattiness <= 0 then return end
    local wait = Reactions.IDLE_BASE / chattiness
    idleTimer = C_Timer.NewTimer(wait + math.random() * wait, function()
        idleTimer = nil
        local companion = Companion()
        if companion and not away and not companion.IsTalking() and not companion.InCombat() then
            if math.random() < IDLE_GESTURE_CHANCE then
                companion.Play(companion.PickAnim(FUN_MOVES))
            else
                -- Its timing already follows chattiness, so it skips the comment rules.
                React("idle", nil, nil, true)
            end
        end
        ScheduleIdle()
    end)
end

local function Name(entry)
    local name = Util.Plain(entry and entry.name)
    return type(name) == "string" and name or "them"
end

local function TierText(entry)
    local friendship = ns.Friendship
    local info = friendship and friendship.TierInfo and friendship.TierInfo(entry)
    return info and WithArticle(info.label) or "a friend"
end

-- Game events -------------------------------------------------------------------------

local handlers = {}

function handlers.PLAYER_ENTERING_WORLD(isLogin, isReload)
    muteUntil = GetTime() + MUTE_AFTER_LOAD
    lastZone = Util.Read(GetZoneText)
    onTaxi = false
    if isLogin or isReload then
        -- Give the player's model a moment to exist, then step in and say hi.
        C_Timer.After(2, function()
            local companion = ns.Companion
            if not companion then return end
            companion.Refresh()
            C_Timer.After(0.8, function() React(isLogin and GreetKey() or "reload", nil, ANIMS.greet, true) end)
        end)
        ScheduleIdle()
        return
    end
    local inside, kind = Util.Read(IsInInstance)
    if inside and (kind == "party" or kind == "raid") then
        C_Timer.After(MUTE_AFTER_LOAD + 1, function() React("dungeon") end)
    end
end

function handlers.PLAYER_LEVEL_UP(level)
    level = tonumber(Util.Plain(level))
    React(level and level >= MaxLevel() and "maxLevel" or "levelUp", { level = level }, ANIMS.levelUp, true)
end

function handlers.PLAYER_DEAD()
    -- After the fight: it stays quiet while one is on.
    C_Timer.After(1.5, function() React("died") end)
end

function handlers.PLAYER_UNGHOST()
    React("alive")
end

function handlers.PLAYER_ALIVE()
    -- Also fires on releasing as a ghost: the walk back gets its own lines.
    if Util.Read(UnitIsGhost, "player") then
        React("ghost")
    elseif not Util.Read(UnitIsDead, "player") then
        React("alive")
    end
end

function handlers.QUEST_TURNED_IN()
    React("quest")
end

function handlers.QUEST_ACCEPTED()
    React("questAccepted")
end

function handlers.ZONE_CHANGED_NEW_AREA()
    local zone = Util.Read(GetZoneText)
    if type(zone) ~= "string" or zone == "" or zone == lastZone then return end
    lastZone = zone
    React("zone", { zone = zone })
end

function handlers.PLAYER_EQUIPMENT_CHANGED()
    -- After the Mini Me has redressed (UI/MiniMe.lua), so it shows off the new gear.
    C_Timer.After(1.5, function() React("gear") end)
end

function handlers.PLAYER_UPDATE_RESTING()
    if Util.Read(IsResting) then React("rest") end
end

-- Away: it falls asleep (if the options let it) and wakes when the player is back.
function handlers.PLAYER_FLAGS_CHANGED(unit)
    if unit ~= "player" then return end
    local isAway = Util.Read(UnitIsAFK, "player") == true
    if isAway == away then return end
    away = isAway
    local companion = Companion()
    if not companion then return end
    if away then
        React("away", nil, false)
        if Settings().sleepWhenAway ~= false then companion.Play(SLEEP, "hold") end
    elseif not React("back") then
        companion.Play(companion.PickAnim(ANIMS.back))
    end
end

-- Partway into a fight, and in a long one, it cheers from the sidelines.
-- Nothing here reads the fight itself (Forever keeps that secret in
-- combat): the cheers come with time.
local function Sidelines(this)
    local function StillFighting()
        local companion = ns.Companion
        return fight == this and companion and companion.InCombat()
    end
    local wait = MID_FIGHT[1] + math.random() * (MID_FIGHT[2] - MID_FIGHT[1])
    C_Timer.After(wait, function()
        if StillFighting() and FightChance("combatMid") then React("combatMid", nil, nil, false, { combat = true }) end
    end)
    C_Timer.After(LONG_FIGHT, function()
        if StillFighting() and FightChance("combatLong") then React("combatLong", nil, nil, false, { combat = true }) end
    end)
end

-- Low on health in a fight: a worried line, once a fight. Forever may keep
-- the player's health secret in combat; then this stays quiet. Whether it
-- could read it is noted once (BuddyDexDB.probe.healthInCombat), to check.
function handlers.UNIT_HEALTH(unit)
    if unit ~= "player" then return end
    local companion = ns.Companion
    if not (companion and companion.InCombat()) or lowHealthFight == fight then return end
    local health, maximum = Util.Read(UnitHealth, "player"), Util.Read(UnitHealthMax, "player")
    local db = ns.db
    if db then
        if type(db.probe) ~= "table" then db.probe = {} end
        if db.probe.healthInCombat == nil then
            db.probe.healthInCombat = type(health) == "number" and "readable" or "secret"
        end
    end
    if type(health) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then return end
    if health > 0 and health / maximum <= LOW_HEALTH then
        -- Once a fight at most, and only now and then: not every close call.
        lowHealthFight = fight
        if FightChance("lowHealth") then React("lowHealth", nil, nil, false, { combat = true }) end
    end
end

-- A fight starts: a battle cry now and then, a fighting stance otherwise.
-- The companion goes quiet on the same event; this waits a moment so it has.
function handlers.PLAYER_REGEN_DISABLED()
    fight = fight + 1
    Sidelines(fight)
    C_Timer.After(0.1, function()
        local companion = Companion()
        if not companion then return end
        local now = GetTime()
        if FightChance("combatStart") and React("combatStart", nil, nil, false, { combat = true }) then
            lastStance = now
        elseif now - lastStance > STANCE_GAP then
            lastStance = now
            companion.Play(companion.PickAnim(ANIMS.combatStart))
        end
    end)
end

-- A fight ends: a celebration, with words now and then.
function handlers.PLAYER_REGEN_ENABLED()
    fight = fight + 1
    C_Timer.After(0.6, function()
        local companion = Companion()
        if not companion or Util.Read(UnitIsDead, "player") then return end
        if FightChance("combatEnd") and React("combatEnd") then return end
        companion.Play(companion.PickAnim(ANIMS.combatEnd))
    end)
end

-- A flight: the player loses control as the gryphon takes off.
function handlers.PLAYER_CONTROL_LOST()
    C_Timer.After(1, function()
        if not Util.Read(UnitOnTaxi, "player") then return end
        onTaxi = true
        React("taxi")
        C_Timer.After(SECOND_TAXI_LINE, function()
            if onTaxi and Util.Read(UnitOnTaxi, "player") then
                lastByKey.taxi = nil
                React("taxi")
            end
        end)
    end)
end

function handlers.PLAYER_CONTROL_GAINED()
    if not onTaxi then return end
    onTaxi = false
    C_Timer.After(0.5, function() React("landed") end)
end

function handlers.PLAYER_MOUNT_DISPLAY_CHANGED()
    if Util.Read(IsMounted) then React("mount") end
end

-- Loot: only the player's own (the looter's GUID, else name, is the
-- player's), and only something rare or better.
local GOOD_QUALITY = { ["0070dd"] = true, ["a335ee"] = true, ["ff8000"] = true }

local function MyLoot(looter, guid)
    guid, looter = Util.Plain(guid), Util.Plain(looter)
    local mine = Util.Read(UnitGUID, "player")
    if type(guid) == "string" and guid ~= "" and mine then return guid == mine end
    return type(looter) == "string" and looter:match("^[^%-]+") == Util.Read(UnitName, "player")
end

function handlers.CHAT_MSG_LOOT(text, looter, _, _, _, _, _, _, _, _, _, guid)
    text = Util.Plain(text)
    if type(text) ~= "string" or not MyLoot(looter, guid) then return end
    local link = text:match("(|c%x%x%x%x%x%x%x%x|Hitem:.-|h%[.-%]|h|r)")
    local color = link and link:match("^|c%x%x(%x%x%x%x%x%x)")
    if color and GOOD_QUALITY[color:lower()] then React("loot", { item = link }) end
end

function handlers.UPDATE_PENDING_MAIL()
    if HasNewMail and Util.Read(HasNewMail) then React("mail") end
end

function handlers.UI_ERROR_MESSAGE(_, message)
    message = Util.Plain(message)
    if ERR_INV_FULL and message == ERR_INV_FULL then React("bagsFull") end
end

function handlers.GROUP_JOINED()
    React("group")
end

function handlers.LEARNED_SPELL_IN_SKILL_LINE()
    React("learned")
end
handlers.NEW_RECIPE_LEARNED = handlers.LEARNED_SPELL_IN_SKILL_LINE

function handlers.UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
    if unit == "player" and Util.Plain(spellID) == HEARTHSTONE then React("hearth") end
end

-- Targeting a friend: it points them out, once in a while per friend.
function handlers.PLAYER_TARGET_CHANGED()
    local guid = Util.Read(UnitGUID, "target")
    local npcID = guid and Util.NpcIDFromGUID and Util.NpcIDFromGUID(guid)
    local companion = ns.Companion
    if not npcID or (companion and companion.Buddy() == npcID) then return end
    local entry = ns.Database and ns.Database.GetEntry(npcID)
    if not entry then return end
    local now = GetTime()
    if seenFriends[npcID] and now - seenFriends[npcID] < SEE_FRIEND_AGAIN then return end
    if React("seeFriend", { friend = Name(entry), tier = TierText(entry) }) then seenFriends[npcID] = now end
end

local events = CreateFrame("Frame")
for event in pairs(handlers) do
    if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_HEALTH" then
        pcall(events.RegisterUnitEvent, events, event, "player")
    else
        pcall(events.RegisterEvent, events, event)
    end
end
events:SetScript("OnEvent", function(_, event, ...)
    local ok, err = pcall(handlers[event], ...)
    if not ok then
        local handler = geterrorhandler and geterrorhandler()
        if handler then handler(err) end
    end
end)

-- The player's emotes -------------------------------------------------------------------

-- With nothing targeted, the buddy answers: waves back, dances along.
local function OnEmote(token, target)
    token = Util.Plain(token)
    if type(token) ~= "string" then return end
    token = token:upper()
    local mirror = MIRRORS[token]
    if not mirror then return end
    target = Util.Plain(target)
    if (type(target) == "string" and target ~= "") or Util.Read(UnitExists, "target") then return end
    local companion = Companion()
    if not companion or companion.InCombat() then return end
    local now = GetTime()
    if now - lastMirror < MIRROR_GAP then return end
    lastMirror = now
    React(mirror[1], nil, false, true, { answer = true })
    companion.Play(mirror[2], mirror[3])
end

if hooksecurefunc and DoEmote then
    hooksecurefunc("DoEmote", function(...)
        local ok, err = pcall(OnEmote, ...)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
        end
    end)
end

-- Friendships ---------------------------------------------------------------------------

local function OnSeen(_, npcID, entry)
    React("newFriend", { friend = Name(entry) })
end

local function OnGained(_, npcID, entry, amount, kind, oldTier, newTier)
    local friendship = ns.Friendship
    if not (friendship and newTier and oldTier and newTier > oldTier) then return end
    if newTier == friendship.BUDDY_TIER then
        React("buddy", { friend = Name(entry) }, ANIMS.buddy, true)
    else
        local tier = friendship.TIERS[newTier]
        React("tier", { friend = Name(entry), tier = WithArticle(tier.label) })
    end
end

-- A buddy that trips must never stop the other listeners (the Dex, the toast).
local function Safely(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) end
        end
    end
end

ns.Bus:RegisterCallback(ns.Event.NpcSeen, Safely(OnSeen), Reactions)
ns.Bus:RegisterCallback(ns.Event.FriendshipGained, Safely(OnGained), Reactions)
ns.Bus:RegisterCallback(ns.Event.SettingChanged, Safely(function(_, key)
    if key == "chattiness" then ScheduleIdle() end
end), Reactions)
