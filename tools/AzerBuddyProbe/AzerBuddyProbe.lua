-- AzerBuddyProbe: finds out what WoW Forever lets an addon do before
-- AzerBuddy commits to a design. /probe runs every check, prints a summary
-- and opens a test window. A /reload afterwards writes the full report to
-- AzerBuddyProbeCharDB, where it can be read outside the game.

local ADDON_NAME = ...

-- Animation names follow AnimationData; HasAnimation decides what is real.
local ANIMS = {
    { 0, "Stand" }, { 4, "Walk" }, { 5, "Run" }, { 60, "Talk" },
    { 64, "TalkExclamation" }, { 65, "TalkQuestion" }, { 66, "Bow" },
    { 67, "Wave" }, { 68, "Cheer" }, { 69, "Dance" }, { 70, "Laugh" },
    { 71, "EmoteSleep" }, { 72, "EmoteSit" }, { 73, "Rude" }, { 74, "Roar" },
    { 75, "Kneel" }, { 76, "Kiss" }, { 77, "Cry" }, { 78, "Chicken" },
    { 79, "Beg" }, { 80, "Applaud" }, { 81, "Shout" }, { 82, "Flex" },
    { 83, "Shy" }, { 84, "Point" }, { 97, "SitGround" }, { 100, "Sleep" },
    { 113, "Salute" }, { 1, "Death" }, { 14, "Stun" },
}

-- Candidate buddy gear. Expected names only; the probe records the real ones.
local ITEMS = {
    { 6219, "Arclight Spanner" },
    { 10545, "Gnomish Goggles" },
    { 4368, "Flying Tiger Goggles" },
    { 10726, "Gnomish Mind Control Cap" },
    { 16866, "Helm of Might (T1)" },
    { 16921, "Halo of Transcendence (T2)" },
    { 19019, "Thunderfury" },
}

-- Gnome NPCs, the fallback if the dressing-room model cannot change race.
local CREATURES = {
    { 7937, "Gelbin Mekkatorque" },
    { 7944, "Tinkmaster Overspark" },
}

local GLOBALS = {
    "issecretvalue", "canaccessvalue", "canaccesssecrets", "InCombatLockdown",
    "C_VoiceChat.SpeakText", "C_VoiceChat.GetTtsVoices", "C_VoiceChat.StopSpeakingText",
    "C_TTSSettings.GetSpeechRate", "C_TTSSettings.GetSpeechVolume",
    "PlaySound", "PlaySoundFile", "StopSound", "DoEmote",
    "C_ChatInfo.SendAddonMessage", "C_ChatInfo.RegisterAddonMessagePrefix",
    "C_ChatInfo.InChatMessagingLockdown",
    "C_Item.RequestLoadItemDataByID", "C_Item.GetItemInfo", "GetItemInfo",
    "GetCursorInfo", "ClearCursor", "C_CreatureInfo.GetRaceInfo",
    "C_BarberShop.GetAvailableCustomizations", "C_TransmogCollection.GetItemInfo",
    "TransmogUtil.CreateTransmogLocation", "ItemTransmogInfoMixin",
    "C_Timer.After", "C_Timer.NewTicker", "C_AddOns.LoadAddOn",
    "C_EncodingUtil.SerializeCBOR", "C_DamageMeter", "UnitXP", "UnitXPMax",
    "GetXPExhaustion", "GetInventoryItemDurability", "C_Container.GetContainerNumFreeSlots",
    "C_QuestLog.GetInfo", "GetQuestLogTitle", "C_Map.GetBestMapForUnit",
    "GetZoneText", "GetSubZoneText", "GetGameTime", "C_DateAndTime.GetCurrentCalendarTime",
    "GetAchievementInfo", "C_PetJournal", "Settings.RegisterCanvasLayoutCategory",
    "AddonCompartmentFrame", "C_ModelInfo", "ModelSceneMixin", "DressUpFrame",
}

local WIDGETS = { "DressUpModel", "PlayerModel", "CinematicModel", "TabardModel", "Model", "ModelScene" }

local GLOBAL_PATTERNS = {
    "model", "dress", "race", "sound", "speak", "tts", "emote", "secret",
    "cursor", "customiz", "transmog", "barber", "voice",
}

local report        -- this run's results
local window        -- the test window
local docsCache     -- parsed API documentation, by namespace
local probeRunning = false
local gnomeRaceID = 7

local function say(fmt, ...)
    local msg = select("#", ...) > 0 and fmt:format(...) or fmt
    print("|cff7fd4ff[AzerBuddyProbe]|r " .. msg)
end

local function put(section, key, value)
    if not report then return end
    report[section] = report[section] or {}
    report[section][key] = value
end

-- Keeps only what SavedVariables can hold.
local function plain(v)
    local t = type(v)
    if t == "string" or t == "number" or t == "boolean" or t == "nil" then return v end
    return tostring(v)
end

local function resolve(path)
    local v = _G
    for part in path:gmatch("[^%.]+") do
        if type(v) ~= "table" then return nil end
        v = v[part]
    end
    return v
end

local function methodList(obj)
    local seen, names = {}, {}
    local function add(k, v)
        if type(k) == "string" and type(v) == "function" and not seen[k] then
            seen[k] = true
            names[#names + 1] = k
        end
    end
    local mt = getmetatable(obj)
    if mt and type(mt.__index) == "table" then
        for k, v in pairs(mt.__index) do add(k, v) end
    end
    for k, v in pairs(obj) do add(k, v) end
    table.sort(names)
    return names
end

local function enumName(enumTable, value)
    if type(enumTable) == "table" then
        for k, v in pairs(enumTable) do
            if v == value then return k end
        end
    end
    return tostring(value)
end

local function fileID(m)
    local ok, id = pcall(m.GetModelFileID, m)
    return ok and id or nil
end

-- Environment ---------------------------------------------------------------

local function probeEnvironment()
    local version, build, date, toc = GetBuildInfo()
    put("env", "version", version)
    put("env", "build", build)
    put("env", "buildDate", date)
    put("env", "toc", toc)
    put("env", "projectID", plain(WOW_PROJECT_ID))
    put("env", "locale", GetLocale())
    local raceName, raceFile, raceID = UnitRace("player")
    put("env", "playerRace", ("%s / %s / %s"):format(tostring(raceName), tostring(raceFile), tostring(raceID)))
    put("env", "playerSex", UnitSex("player"))
    put("env", "playerLevel", UnitLevel("player"))
    put("env", "screen", ("%dx%d scale %.2f"):format(math.floor(GetScreenWidth()), math.floor(GetScreenHeight()), UIParent:GetEffectiveScale()))
end

local function probeGlobals()
    for _, path in ipairs(GLOBALS) do
        put("globals", path, type(resolve(path)))
    end

    local namespaces = {}
    for k, v in pairs(_G) do
        if type(k) == "string" and k:match("^C_") and type(v) == "table" then
            local fns = {}
            for fk, fv in pairs(v) do
                if type(fv) == "function" then fns[#fns + 1] = fk end
            end
            table.sort(fns)
            namespaces[k] = fns
        end
    end
    report.namespaces = namespaces

    local matched = {}
    for k, v in pairs(_G) do
        if type(k) == "string" and type(v) == "function" then
            local lower = k:lower()
            for _, p in ipairs(GLOBAL_PATTERNS) do
                if lower:find(p, 1, true) then
                    matched[#matched + 1] = k
                    break
                end
            end
        end
    end
    table.sort(matched)
    report.globalFunctions = matched
end

local function probeWidgets()
    report.widgets = {}
    for _, kind in ipairs(WIDGETS) do
        local ok, w = pcall(CreateFrame, kind, nil, UIParent)
        if ok and w then
            w:Hide()
            report.widgets[kind] = methodList(w)
        else
            report.widgets[kind] = { "CREATE FAILED: " .. tostring(w) }
        end
    end

    local ok, scene = pcall(CreateFrame, "ModelScene", nil, UIParent)
    if ok and scene then
        scene:Hide()
        local okA, actor = pcall(scene.CreateActor, scene)
        report.widgets.ModelSceneActor = (okA and actor) and methodList(actor) or { "CREATE FAILED: " .. tostring(actor) }
    end

    local okF, err = pcall(function()
        local group = CreateFrame("Frame"):CreateAnimationGroup()
        return group:CreateAnimation("FlipBook")
    end)
    put("features", "flipBookAnimation", okF and "yes" or ("no: " .. tostring(err)))
end

local function probeRaces()
    local races = {}
    if C_CreatureInfo and C_CreatureInfo.GetRaceInfo then
        for id = 1, 150 do
            local ok, info = pcall(C_CreatureInfo.GetRaceInfo, id)
            if ok and type(info) == "table" then
                races[#races + 1] = ("%d %s (%s)"):format(id, tostring(info.raceName), tostring(info.clientFileString))
                if info.clientFileString == "Gnome" then gnomeRaceID = id end
            end
        end
    end
    report.races = races
    put("features", "gnomeRaceID", gnomeRaceID)
end

-- Blizzard's own API documentation carries exact signatures, including the
-- widget methods, so it answers most questions without guessing.
local DOC_KNOWN = { Name = true, Type = true, Arguments = true, Returns = true, Payload = true, LiteralName = true, Documentation = true }

local function fieldList(fields)
    local parts = {}
    for _, f in ipairs(fields or {}) do
        local t = tostring(f.Type or "?")
        if f.InnerType then t = t .. "<" .. tostring(f.InnerType) .. ">" end
        if f.Mixin then t = t .. "(" .. tostring(f.Mixin) .. ")" end
        parts[#parts + 1] = tostring(f.Name or "?") .. ": " .. t .. (f.Nilable and "?" or "")
    end
    return table.concat(parts, ", ")
end

local function flags(entry)
    local extra = {}
    for k, v in pairs(entry) do
        if type(k) == "string" and not DOC_KNOWN[k] and type(v) ~= "table" and type(v) ~= "function" then
            extra[#extra + 1] = k .. "=" .. tostring(v)
        end
    end
    table.sort(extra)
    return #extra > 0 and (" [" .. table.concat(extra, " ") .. "]") or ""
end

local function probeDocs()
    local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
    if load then
        pcall(load, "Blizzard_APIDocumentation")
        pcall(load, "Blizzard_APIDocumentationGenerated")
    end
    local systems = APIDocumentation and APIDocumentation.systems
    if type(systems) ~= "table" then
        put("features", "apiDocs", "not available")
        return
    end

    local docs, saved, count = {}, {}, 0
    for _, sys in ipairs(systems) do
        local key = tostring(sys.Namespace or sys.Name or "?")
        while docs[key] do key = key .. "+" end
        local entry = { type = plain(sys.Type), name = plain(sys.Name), functions = {}, events = {} }
        for _, fn in ipairs(sys.Functions or {}) do
            local line = ("%s(%s)"):format(tostring(fn.Name), fieldList(fn.Arguments))
            if fn.Returns and #fn.Returns > 0 then line = line .. " -> " .. fieldList(fn.Returns) end
            entry.functions[#entry.functions + 1] = line .. flags(fn)
        end
        for _, ev in ipairs(sys.Events or {}) do
            entry.events[#entry.events + 1] = ("%s(%s)"):format(tostring(ev.LiteralName or ev.Name), fieldList(ev.Payload)) .. flags(ev)
        end
        docs[key] = entry
        -- One string per system keeps the saved file small and flat.
        local lines = { ("type=%s name=%s"):format(tostring(entry.type), tostring(entry.name)) }
        for _, line in ipairs(entry.functions) do lines[#lines + 1] = "F " .. line end
        for _, line in ipairs(entry.events) do lines[#lines + 1] = "E " .. line end
        saved[key] = table.concat(lines, "\n")
        count = count + 1
    end
    docsCache = docs
    report.docs = saved

    local shape = {}
    for k in pairs(systems[1] or {}) do shape[#shape + 1] = tostring(k) end
    table.sort(shape)
    report.docsShape = shape
    put("features", "apiDocs", count .. " systems")
end

-- Items, voice and addon messages --------------------------------------------

local function requestItems()
    for _, item in ipairs(ITEMS) do
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, item[1])
        end
    end
end

local function itemName(id)
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local ok, name = pcall(getInfo, id)
    return ok and name or nil
end

local function ttsVoices()
    if not (C_VoiceChat and C_VoiceChat.GetTtsVoices) then return {} end
    local ok, voices = pcall(C_VoiceChat.GetTtsVoices)
    return (ok and type(voices) == "table") and voices or {}
end

local function speakArgsFromDocs(voiceID, text)
    -- Build the call from the documented argument names, so it is right
    -- whichever signature this client has.
    local sys = docsCache and docsCache.C_VoiceChat
    local line
    for _, fn in ipairs(sys and sys.functions or {}) do
        if fn:match("^SpeakText%(") then line = fn break end
    end
    if not line then return nil end
    local args, n = {}, 0
    for name in line:match("^SpeakText%((.-)%)"):gmatch("(%w+):") do
        local lower = name:lower()
        n = n + 1
        if lower:find("voice") then args[n] = voiceID
        elseif lower == "text" then args[n] = text
        elseif lower:find("destination") then
            local dest = Enum and Enum.VoiceTtsDestination
            args[n] = dest and (dest.LocalPlayback or dest.QueuedLocalPlayback) or 1
        elseif lower:find("rate") then args[n] = 0
        elseif lower:find("volume") then args[n] = 100
        elseif lower:find("overlap") then args[n] = true
        end
    end
    args.n = n
    return args, line
end

local function speak(text)
    if not (C_VoiceChat and C_VoiceChat.SpeakText) then
        put("tts", "speak", "C_VoiceChat.SpeakText missing")
        return false, "missing"
    end
    local voices = ttsVoices()
    local voiceID = voices[1] and voices[1].voiceID or 0
    local args, signature = speakArgsFromDocs(voiceID, text)
    if not args then
        -- 11.0+ order: voiceID, text, rate, volume, overlap
        args, signature = { voiceID, text, 0, 100, true, n = 5 }, "guessed"
    end
    local ok, err = pcall(C_VoiceChat.SpeakText, unpack(args, 1, args.n))
    put("tts", "signature", signature)
    put("tts", "speak", ok and "called without error" or ("error: " .. tostring(err)))
    return ok, err
end

local function probeVoice()
    local voices = ttsVoices()
    local list = {}
    for _, v in ipairs(voices) do
        list[#list + 1] = ("%s: %s"):format(tostring(v.voiceID), tostring(v.name))
    end
    report.ttsVoices = list
    speak("Hello! I am your Azer Buddy. Shall we go on an adventure?")
end

local function probeAddonMessages()
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then
        put("comms", "send", "missing")
        return
    end
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, "AZBPROBE")
    local ok, result = pcall(C_ChatInfo.SendAddonMessage, "AZBPROBE", "ping", "WHISPER", UnitName("player"))
    put("comms", "sendSelfWhisper", ok and enumName(Enum and Enum.SendAddonMessageResult, result) or ("error: " .. tostring(result)))
    put("comms", "received", false)
end

-- Model ----------------------------------------------------------------------

local function animSupport(m)
    local supported, missing = {}, {}
    for _, a in ipairs(ANIMS) do
        local ok, has = pcall(m.HasAnimation, m, a[1])
        if ok and has then
            supported[#supported + 1] = a[1] .. " " .. a[2]
        else
            missing[#missing + 1] = a[1] .. " " .. a[2] .. (ok and "" or " (HasAnimation errored)")
        end
    end
    return supported, missing
end

local function tryOn(m, id)
    local ok, reason = pcall(m.TryOn, m, "item:" .. id)
    if not ok then return "error: " .. tostring(reason) end
    return enumName(Enum and Enum.ItemTryOnReason, reason)
end

local function setGnome(m, sex)
    if not m.SetCustomRace then return false, "SetCustomRace missing" end
    local ok, err = pcall(m.SetCustomRace, m, gnomeRaceID, sex)
    return ok, err
end

local function runModelChecks(done)
    local m = window.model
    local steps = {
        function()
            m:SetUnit("player")
        end,
        function()
            put("model", "playerFileID", plain(fileID(m)))
            local ok, err = setGnome(m, 0)
            put("model", "setCustomRaceMale", ok and "ok" or tostring(err))
        end,
        function()
            put("model", "gnomeMaleFileID", plain(fileID(m)))
            local ok, err = setGnome(m, 1)
            put("model", "setCustomRaceFemale", ok and "ok" or tostring(err))
        end,
        function()
            put("model", "gnomeFemaleFileID", plain(fileID(m)))
            setGnome(m, 0)
        end,
        function()
            local supported, missing = animSupport(m)
            report.animSupported, report.animMissing = supported, missing
            put("model", "undress", select(1, pcall(m.Undress, m)) and "ok" or "error")
            local results = {}
            for _, item in ipairs(ITEMS) do
                results[#results + 1] = ("%d %s -> %s"):format(item[1], itemName(item[1]) or ("? (" .. item[2] .. ")"), tryOn(m, item[1]))
            end
            report.tryOn = results
        end,
    }
    local i = 0
    local function step()
        i = i + 1
        if not steps[i] then return done() end
        local ok, err = pcall(steps[i])
        if not ok then put("errors", "modelStep" .. i, tostring(err)) end
        C_Timer.After(1.5, step)
    end
    step()
end

-- Test window ----------------------------------------------------------------

local function buildWindow()
    if window then return window end
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbeWindow", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbeWindow", UIParent, "BackdropTemplate") end
    f:SetSize(340, 508)
    f:SetPoint("CENTER", 300, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then
        f.TitleText:SetText("AzerBuddy Probe")
    else
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -6)
        title:SetText("AzerBuddy Probe")
    end

    local m = CreateFrame("DressUpModel", nil, f)
    m:SetPoint("TOPLEFT", 12, -30)
    m:SetPoint("BOTTOMRIGHT", -12, 168)
    m:EnableMouse(true)
    m:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    m:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    m:SetScript("OnUpdate", function(self)
        if self.dragX then
            local x = GetCursorPosition()
            self:SetFacing((self:GetFacing() or 0) + (x - self.dragX) * 0.02)
            self.dragX = x
        end
    end)
    f.model = m

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 14, 14)
    status:SetPoint("BOTTOMRIGHT", -14, 14)
    status:SetJustifyH("LEFT")
    status:SetText("Drag the model to turn it.")
    f.status = status
    local function show(fmt, ...) status:SetText(fmt:format(...)) end

    local function button(text, w, x, y, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(w, 22)
        b:SetPoint("BOTTOMLEFT", x, y)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        return b
    end

    local creature, item, anim = 0, 0, 1
    local gnomeFile = 900914   -- Overspark's model; replaced by any NPC gnome loaded

    -- The gnome model straight from its file, with no skin, face or hair
    -- choices applied, and whatever unit is targeted, which arrives fully
    -- customized.
    button("Raw gnome file", 156, 12, 134, function()
        local ok, err = pcall(m.SetModel, m, gnomeFile)
        C_Timer.After(0.5, function() show("Raw file %d: %s, file now %s", gnomeFile, ok and "set" or tostring(err), tostring(fileID(m))) end)
    end)
    button("Target", 156, 172, 134, function()
        if not UnitExists("target") then return show("Target someone first, ideally a gnome.") end
        local ok, err = pcall(m.SetUnit, m, "target")
        local race = UnitRace("target")
        C_Timer.After(0.5, function() show("Target (%s): %s, file %s", tostring(race), ok and "set" or tostring(err), tostring(fileID(m))) end)
    end)

    button("Me", 74, 12, 106, function()
        m:SetUnit("player")
        show("Your own model. File %s", tostring(fileID(m)))
    end)
    button("Gnome M", 74, 90, 106, function()
        local ok, err = setGnome(m, 0)
        C_Timer.After(0.5, function() show("Gnome male: %s, file %s", ok and "ok" or tostring(err), tostring(fileID(m))) end)
    end)
    button("Gnome F", 74, 168, 106, function()
        local ok, err = setGnome(m, 1)
        C_Timer.After(0.5, function() show("Gnome female: %s, file %s", ok and "ok" or tostring(err), tostring(fileID(m))) end)
    end)
    button("NPC gnome", 74, 246, 106, function()
        creature = creature % #CREATURES + 1
        local c = CREATURES[creature]
        local ok, err = pcall(m.SetCreature, m, c[1])
        C_Timer.After(0.5, function()
            gnomeFile = fileID(m) or gnomeFile
            show("%s: %s, file %s", c[2], ok and "set" or tostring(err), tostring(fileID(m)))
        end)
    end)

    button("Undress", 100, 12, 78, function()
        local ok = pcall(m.Undress, m)
        show("Undress: %s", ok and "ok" or "error")
    end)
    button("Try gear", 100, 116, 78, function()
        item = item % #ITEMS + 1
        local it = ITEMS[item]
        show("%s: %s", itemName(it[1]) or it[2], tryOn(m, it[1]))
    end)
    button("Speak", 100, 220, 78, function()
        local ok, err = speak("Ooh, shiny! Can I wear that?")
        show("Speak: %s", ok and "called, listen..." or tostring(err))
    end)

    local animLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    animLabel:SetPoint("BOTTOM", 0, 56)
    local function playAnim()
        local a = ANIMS[anim]
        local okHas, has = pcall(m.HasAnimation, m, a[1])
        pcall(m.SetAnimation, m, a[1])
        animLabel:SetText(("%d %s%s"):format(a[1], a[2], (okHas and not has) and " (missing)" or ""))
    end
    button("<", 40, 12, 50, function() anim = (anim - 2) % #ANIMS + 1; playAnim() end)
    button(">", 40, 288, 50, function() anim = anim % #ANIMS + 1; playAnim() end)
    animLabel:SetText("Animations: < >")

    window = f
    return f
end

-- Actor window -------------------------------------------------------------------
-- SetCustomRace is gone, but ModelScene actors take a customRaceID in
-- SetModelByUnit (and SetPlayerModelFromGlues), per Forever's own API docs.

local actorWindow

local function buildActorWindow()
    if actorWindow then return actorWindow end
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbeActorWindow", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbeActorWindow", UIParent, "BackdropTemplate") end
    f:SetSize(340, 508)
    f:SetPoint("CENTER", -60, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("AzerBuddy Probe: Actor") end

    local scene = CreateFrame("ModelScene", nil, f)
    scene:SetPoint("TOPLEFT", 12, -30)
    scene:SetPoint("BOTTOMRIGHT", -12, 168)
    -- World axes: x forward, y left, z up. The camera sits on +x looking back.
    scene:SetCameraPosition(5, 0, 1.0)
    scene:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
    scene:SetCameraFieldOfView(0.6)
    scene:SetCameraNearClip(0.1)
    scene:SetCameraFarClip(100)
    pcall(scene.SetLightVisible, scene, true)
    pcall(scene.SetLightAmbientColor, scene, 0.7, 0.7, 0.7)
    pcall(scene.SetLightDiffuseColor, scene, 0.8, 0.8, 0.8)
    pcall(scene.SetLightDirection, scene, -1, 0.3, -0.5)

    local actor = scene:CreateActor()
    actor:SetPosition(0, 0, 0)
    actor:SetYaw(0)

    scene:EnableMouse(true)
    scene:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    scene:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    scene:SetScript("OnUpdate", function(self)
        if self.dragX then
            local x = GetCursorPosition()
            actor:SetYaw(actor:GetYaw() + (x - self.dragX) * 0.02)
            self.dragX = x
        end
    end)

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 14, 14)
    status:SetPoint("BOTTOMRIGHT", -14, 14)
    status:SetJustifyH("LEFT")
    status:SetText("Drag the model to turn it.")

    -- Results also go to chat and the saved report.
    local function show(key, fmt, ...)
        local text = fmt:format(...)
        status:SetText(text)
        say("Actor %s", text)
        if report then put("actor", key, text) end
    end

    local function later(key, label, ok, result)
        C_Timer.After(0.75, function()
            show(key, "%s: %s, returned %s, file %s", label, ok and "ok" or "error", tostring(result), tostring(select(2, pcall(actor.GetModelFileID, actor))))
        end)
    end

    local function button(text, w, x, y, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(w, 22)
        b:SetPoint("BOTTOMLEFT", x, y)
        b:SetText(text)
        b:SetScript("OnClick", onClick)
        return b
    end

    -- SetModelByUnit(unit, sheatheWeapons, autoDress, hideWeapons, usePlayerNativeForm, holdBowString, customRaceID)
    button("Me", 74, 12, 134, function()
        local ok, r = pcall(actor.SetModelByUnit, actor, "player", false, true, false, false, false)
        later("me", "Me", ok, r)
    end)
    button("Gnome (unit)", 98, 90, 134, function()
        local ok, r = pcall(actor.SetModelByUnit, actor, "player", false, true, false, false, false, gnomeRaceID)
        later("gnomeUnit", "Gnome via SetModelByUnit", ok, r)
    end)
    -- SetPlayerModelFromGlues(characterIndex, sheatheWeapons, autoDress, hideWeapons, usePlayerNativeForm, customRaceID)
    button("Gnome (glues)", 142, 190, 134, function()
        local ok, r = pcall(actor.SetPlayerModelFromGlues, actor, nil, false, true, false, false, gnomeRaceID)
        later("gnomeGlues", "Gnome via SetPlayerModelFromGlues", ok, r)
    end)

    local item = 0
    button("Undress", 100, 12, 106, function()
        local ok, err = pcall(actor.Undress, actor)
        show("undress", "Undress: %s", ok and "ok" or tostring(err))
    end)
    button("Try gear", 100, 116, 106, function()
        item = item % #ITEMS + 1
        local it = ITEMS[item]
        local ok, reason = pcall(actor.TryOn, actor, "item:" .. it[1])
        show("tryOn" .. it[1], "Try on %s: %s", itemName(it[1]) or it[2], ok and enumName(Enum and Enum.ItemTryOnReason, reason) or tostring(reason))
    end)
    button("Dress", 100, 220, 106, function()
        local ok, err = pcall(actor.Dress, actor)
        show("dress", "Dress: %s", ok and "ok" or tostring(err))
    end)

    -- NPC gnomes: a DressUpModel turns the creature ID into a display ID,
    -- which the actor then loads. Undress and Try gear then test whether an
    -- NPC body can be re-dressed.
    local lookup = CreateFrame("DressUpModel", nil, f)
    lookup:SetSize(1, 1)
    lookup:SetPoint("TOPLEFT")
    lookup:SetAlpha(0)
    local creature = 0
    button("NPC gnome", 98, 90, 78, function()
        creature = creature % #CREATURES + 1
        local c = CREATURES[creature]
        pcall(lookup.SetCreature, lookup, c[1])
        C_Timer.After(0.75, function()
            local _, displayID = pcall(lookup.GetDisplayInfo, lookup)
            local ok, r = pcall(actor.SetModelByCreatureDisplayID, actor, displayID, false)
            later("npc" .. c[1], ("%s (display %s)"):format(c[2], tostring(displayID)), ok, r)
        end)
    end)

    local CAMERAS = { { 5, 1.0 }, { 3.5, 0.55 }, { 9, 1.1 } }
    local camera = 1
    button("Zoom", 98, 190, 78, function()
        camera = camera % #CAMERAS + 1
        scene:SetCameraPosition(CAMERAS[camera][1], 0, CAMERAS[camera][2])
        status:SetText(("Camera %d of %d"):format(camera, #CAMERAS))
    end)

    local scale = 1
    button("Scale", 74, 12, 78, function()
        scale = scale == 1 and 1.6 or (scale == 1.6 and 0.6 or 1)
        actor:SetScale(scale)
        status:SetText(("Scale %.1f"):format(scale))
    end)
    local anim = 1
    local animLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    animLabel:SetPoint("BOTTOM", 0, 56)
    animLabel:SetText("Animations: < >")
    local function playAnim()
        local a = ANIMS[anim]
        local ok, err = pcall(actor.SetAnimation, actor, a[1], 0, 1, 0)
        animLabel:SetText(("%d %s%s"):format(a[1], a[2], ok and "" or " (error)"))
    end
    button("<", 40, 12, 50, function() anim = (anim - 2) % #ANIMS + 1; playAnim() end)
    button(">", 40, 288, 50, function() anim = anim % #ANIMS + 1; playAnim() end)

    actorWindow = f
    return f
end

-- Summary ----------------------------------------------------------------------

local function summarize()
    local env = report.env or {}
    say("Build %s (%s), toc %s", tostring(env.version), tostring(env.build), tostring(env.toc))

    local model = report.model or {}
    local changed = model.gnomeMaleFileID and model.gnomeMaleFileID ~= model.playerFileID
    if env.playerRace and env.playerRace:find("Gnome") then
        changed = model.gnomeFemaleFileID and model.gnomeFemaleFileID ~= model.gnomeMaleFileID
    end
    say("Gnome via SetCustomRace: %s (files: you %s, male %s, female %s)",
        changed and "|cff40ff40YES|r" or "|cffff4040NO|r",
        tostring(model.playerFileID), tostring(model.gnomeMaleFileID), tostring(model.gnomeFemaleFileID))

    say("Animations: %d of %d supported", #(report.animSupported or {}), #ANIMS)
    for _, line in ipairs(report.tryOn or {}) do say("Try on %s", line) end

    local features = report.features or {}
    say("API docs: %s. Flipbook sprites: %s", tostring(features.apiDocs), tostring(features.flipBookAnimation))
    say("TTS: %d voices, speak %s, playback %s", #(report.ttsVoices or {}),
        tostring(report.tts and report.tts.speak), tostring(report.tts and report.tts.playback or "no event"))
    say("Addon messages: send %s, received %s", tostring(report.comms and report.comms.sendSelfWhisper),
        tostring(report.comms and report.comms.received))

    local persist = AzerBuddyProbeCharDB.persistence or {}
    say("Saved data read back: per-character %s, account %s", tostring(persist.charReadBack), tostring(persist.accountReadBack))
    say("Done. Play with the window, then type /reload twice so the full report is saved.")
end

-- The first run's report never reached disk: the client dropped the whole
-- table without a word. The large dumps now go in keys of their own, so a
-- dropped one only loses itself, and their sizes are kept in the report.
local BLOBS = { "namespaces", "globalFunctions", "widgets", "docs", "docsShape" }

local function size(v)
    local t = type(v)
    if t == "string" then return #v + 4 end
    if t ~= "table" then return 8 end
    local n = 0
    for k, x in pairs(v) do n = n + size(k) + size(x) end
    return n
end

local function stash()
    for _, key in ipairs(BLOBS) do
        local v = report[key]
        if v ~= nil then
            put("sizes", key, size(v))
            AzerBuddyProbeCharDB["blob_" .. key] = v
            report[key] = nil
        end
    end
    put("sizes", "report", size(report))
end

local function runProbe()
    if probeRunning then return say("Already running.") end
    if InCombatLockdown() then return say("Leave combat first.") end
    probeRunning = true

    report = { ranAt = date("%Y-%m-%d %H:%M:%S") }
    AzerBuddyProbeCharDB.report = report
    for _, key in ipairs(BLOBS) do AzerBuddyProbeCharDB["blob_" .. key] = nil end
    say("Running checks, this takes about 10 seconds...")

    local steps = {
        { "environment", probeEnvironment },
        { "globals", probeGlobals },
        { "widgets", probeWidgets },
        { "races", probeRaces },
        { "docs", probeDocs },
        { "voice", probeVoice },
        { "comms", probeAddonMessages },
    }
    for _, s in ipairs(steps) do
        local ok, err = pcall(s[2])
        if not ok then put("errors", s[1], tostring(err)) say("|cffff4040%s failed:|r %s", s[1], tostring(err)) end
    end

    stash()
    requestItems()
    buildWindow():Show()
    runModelChecks(function()
        probeRunning = false
        stash()
        local ok, err = pcall(summarize)
        if not ok then say("Summary failed: %s", tostring(err)) end
    end)
end

-- Gnome lab ------------------------------------------------------------------------
-- Every remaining route to a gnome body, side by side, so one screenshot
-- compares them. The in-game shop puts your outfit on another race with
-- SetModelByUnit(..., usePlayerNativeForm = true, ..., customRaceID); the
-- actor window passed false. 51877/53291 are the gnome male/female ChrModel
-- display IDs (HD) and 1563/1564 the classic ones, none with baked NPC gear.
-- 900914 is the gnome male HD model file.

local LAB_TILES = {
    { "Me as race 7, native", "actor", function(a) return a:SetModelByUnit("player", false, true, false, true, false, gnomeRaceID) end },
    { "Me as race 10, native", "actor", function(a) return a:SetModelByUnit("player", false, true, false, true, false, 10) end },
    { "Actor display 51877", "actor", function(a) return a:SetModelByCreatureDisplayID(51877, false) end },
    { "Actor display 53291", "actor", function(a) return a:SetModelByCreatureDisplayID(53291, false) end },
    { "Actor 51877, my look", "actor", function(a) return a:SetModelByCreatureDisplayID(51877, true) end },
    { "DressUp display 51877", "model", function(m) return m:SetDisplayInfo(51877) end },
    { "DressUp display 53291", "model", function(m) return m:SetDisplayInfo(53291) end },
    { "DressUp display 1563", "model", function(m) return m:SetDisplayInfo(1563) end },
    { "DressUp display 1564", "model", function(m) return m:SetDisplayInfo(1564) end },
    { "DressUp file 900914", "model", function(m) return m:SetModel(900914) end },
}

-- Whole sets, so chest, legs, hands and feet (painted onto the body) are
-- tested as well as helms, shoulders and weapons (separate geometry).
local LAB_SETS = {
    { "Gnome kit", { 10545, 6219 } },
    { "Might (T1)", { 16866, 16868, 16865, 16861, 16863, 16864, 16867, 16862 } },
    { "Transcendence (T2)", { 16921, 16924, 16923, 16926, 16920, 16925, 16922, 16919 } },
}

local LAB_ANIMS = { { "Stand", 0 }, { "Wave", 67 }, { "Dance", 69 }, { "Laugh", 70 } }

-- Every race Forever lists with a player model. The sweep draws the unit as
-- each of them, the way tile 1 of the lab draws you as a gnome.
local RACES = {
    { 1, "Human" }, { 2, "Orc" }, { 3, "Dwarf" }, { 4, "Night Elf" }, { 5, "Undead" },
    { 6, "Tauren" }, { 7, "Gnome" }, { 8, "Troll" }, { 9, "Goblin" }, { 10, "Blood Elf" },
    { 11, "Draenei" }, { 22, "Worgen" }, { 24, "Pandaren" }, { 27, "Nightborne" },
    { 28, "Highmountain" }, { 29, "Void Elf" }, { 30, "Lightforged" }, { 31, "Zandalari" },
    { 32, "Kul Tiran" }, { 34, "Dark Iron" }, { 35, "Vulpera" }, { 36, "Mag'har" },
    { 37, "Mechagnome" }, { 52, "Dracthyr" }, { 84, "Earthen" }, { 86, "Haranir" },
    { 95, "Skyborne HO" }, { 96, "Skyborne WS" },
}

-- "player" or "target": a female target shows whether sex follows the unit.
local raceUnit = "player"

local RACE_TILES = {}
for i, race in ipairs(RACES) do
    RACE_TILES[i] = { race[2] .. " " .. race[1], "actor", function(a)
        return a:SetModelByUnit(raceUnit, false, true, false, true, false, race[1])
    end }
end

local GRIDS = {
    lab = { title = "AzerBuddy Gnome Lab", tiles = LAB_TILES, cols = 5, tileW = 150, tileH = 230, camDistance = 4.2 },
    races = { title = "AzerBuddy Race Sweep", tiles = RACE_TILES, cols = 7, tileW = 112, tileH = 176, camDistance = 5 },
}

local GAP = 6

local function tileStatus(tile)
    tile.status:SetText((tile.setupText or "") .. "\n" .. (tile.actionText or ""))
end

local function placeCamera(tile)
    tile.scene:SetCameraPosition(tile.camDistance, 0, 0.35 + tile.camDistance * 0.1)
end

local function createTile(grid, index, def)
    local col = (index - 1) % grid.cols
    local row = math.floor((index - 1) / grid.cols)
    local tile = CreateFrame("Frame", nil, grid.frame, "BackdropTemplate")
    tile:SetSize(grid.tileW, grid.tileH)
    tile:SetPoint("TOPLEFT", 12 + col * (grid.tileW + GAP), -30 - row * (grid.tileH + GAP))
    if tile.SetBackdrop then
        tile:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        tile:SetBackdropColor(0, 0, 0, 0.5)
        tile:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end
    tile.def = def

    local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 4, -4)
    title:SetPoint("TOPRIGHT", -4, -4)
    title:SetJustifyH("LEFT")
    title:SetText(index .. ". " .. def[1])

    local status = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 4, 4)
    status:SetPoint("BOTTOMRIGHT", -4, 4)
    status:SetHeight(28)
    status:SetJustifyH("LEFT")
    tile.status = status

    local view
    if def[2] == "actor" then
        local scene = CreateFrame("ModelScene", nil, tile)
        scene:SetPoint("TOPLEFT", 2, -18)
        scene:SetPoint("BOTTOMRIGHT", -2, 34)
        scene:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
        scene:SetCameraFieldOfView(0.55)
        scene:SetCameraNearClip(0.1)
        scene:SetCameraFarClip(100)
        pcall(scene.SetLightVisible, scene, true)
        pcall(scene.SetLightAmbientColor, scene, 0.7, 0.7, 0.7)
        pcall(scene.SetLightDiffuseColor, scene, 0.8, 0.8, 0.8)
        pcall(scene.SetLightDirection, scene, -1, 0.3, -0.5)
        local actor = scene:CreateActor()
        actor:SetPosition(0, 0, 0)
        actor:SetYaw(0)
        tile.scene, tile.target, tile.camDistance = scene, actor, grid.camDistance
        placeCamera(tile)
        view = scene
    else
        local m = CreateFrame("DressUpModel", nil, tile)
        m:SetPoint("TOPLEFT", 2, -18)
        m:SetPoint("BOTTOMRIGHT", -2, 34)
        tile.target = m
        view = m
    end

    -- Drag turns the model, the mouse wheel zooms.
    view:EnableMouse(true)
    view:EnableMouseWheel(true)
    view:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    view:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    view:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = GetCursorPosition()
        local turn = (x - self.dragX) * 0.02
        self.dragX = x
        if tile.scene then
            tile.target:SetYaw(tile.target:GetYaw() + turn)
        else
            tile.target:SetFacing((tile.target:GetFacing() or 0) + turn)
        end
    end)
    view:SetScript("OnMouseWheel", function(_, delta)
        if tile.scene then
            tile.camDistance = math.max(1.5, math.min(12, tile.camDistance - delta * 0.4))
            placeCamera(tile)
        else
            tile.zoom = math.max(0.3, math.min(3, (tile.zoom or 1) - delta * 0.1))
            pcall(tile.target.SetCamDistanceScale, tile.target, tile.zoom)
        end
    end)
    return tile
end

local function gridSetup(grid, tile)
    local ok, result = pcall(tile.def[3], tile.target)
    tile.setupText = ok and ("returned " .. tostring(result)) or ("error: " .. tostring(result))
    tile.actionText = "loading..."
    tileStatus(tile)
    C_Timer.After(1, function()
        local _, file = pcall(tile.target.GetModelFileID, tile.target)
        tile.setupText = tile.setupText .. ", file " .. tostring(file)
        tile.actionText = ""
        tileStatus(tile)
        put(grid.key, tile.def[1], tile.setupText)
    end)
end

local function gridEach(grid, fn)
    for _, tile in ipairs(grid.tileFrames) do
        local ok, text = pcall(fn, tile)
        tile.actionText = ok and text or ("error: " .. tostring(text))
        tileStatus(tile)
    end
end

local function gridUndress(grid)
    gridEach(grid, function(tile)
        tile.target:Undress()
        return "undressed"
    end)
end

local function gridTryOn(grid, set)
    gridEach(grid, function(tile)
        local counts, order = {}, {}
        for _, id in ipairs(set[2]) do
            local ok, reason = pcall(tile.target.TryOn, tile.target, "item:" .. id)
            local name = ok and enumName(Enum and Enum.ItemTryOnReason, reason) or "error"
            if not counts[name] then
                counts[name] = 0
                order[#order + 1] = name
            end
            counts[name] = counts[name] + 1
        end
        local parts = {}
        for _, name in ipairs(order) do parts[#parts + 1] = counts[name] .. " " .. name end
        local text = set[1] .. ": " .. table.concat(parts, ", ")
        put(grid.key, tile.def[1] .. " / " .. set[1], text)
        return text
    end)
end

local function gridAnim(grid, anim)
    gridEach(grid, function(tile)
        if tile.scene then
            tile.target:SetAnimation(anim[2], 0, 1, 0)
        else
            tile.target:SetAnimation(anim[2])
        end
        return anim[1]
    end)
end

local function gridReload(grid)
    for _, tile in ipairs(grid.tileFrames) do gridSetup(grid, tile) end
    C_Timer.After(1.5, function()
        local good = 0
        for i, tile in ipairs(grid.tileFrames) do
            if (tile.setupText or ""):find("^returned true") then
                good = good + 1
            else
                say("%s %d. %s: %s", grid.key, i, tile.def[1], tostring(tile.setupText))
            end
        end
        say("%s: %d of %d tiles returned true (unit: %s)", grid.title, good, #grid.tileFrames, raceUnit)
    end)
end

local function buildGrid(key)
    local grid = GRIDS[key]
    if grid.frame then
        grid.frame:Show()
        return grid
    end
    grid.key = key
    local rows = math.ceil(#grid.tiles / grid.cols)
    local name = "AzerBuddyProbe_" .. key
    local ok, f = pcall(CreateFrame, "Frame", name, UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", name, UIParent, "BackdropTemplate") end
    f:SetSize(24 + grid.cols * grid.tileW + (grid.cols - 1) * GAP, 30 + rows * grid.tileH + (rows - 1) * GAP + 76)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText(grid.title) end
    grid.frame = f

    grid.tileFrames = {}
    for i, def in ipairs(grid.tiles) do
        grid.tileFrames[i] = createTile(grid, i, def)
    end

    local function row(y, specs)
        local x = 12
        for _, spec in ipairs(specs) do
            local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            b:SetSize(spec[2], 22)
            b:SetPoint("BOTTOMLEFT", x, y)
            b:SetText(spec[1])
            b:SetScript("OnClick", spec[3])
            x = x + spec[2] + 4
        end
    end
    row(40, {
        { "Reload all", 90, function() gridReload(grid) end },
        { "Undress", 80, function() gridUndress(grid) end },
        { LAB_SETS[1][1], 100, function() gridTryOn(grid, LAB_SETS[1]) end },
        { LAB_SETS[2][1], 100, function() gridTryOn(grid, LAB_SETS[2]) end },
        { LAB_SETS[3][1], 140, function() gridTryOn(grid, LAB_SETS[3]) end },
    })
    local bottom = {}
    for i, anim in ipairs(LAB_ANIMS) do
        bottom[i] = { anim[1], 80, function() gridAnim(grid, anim) end }
    end
    if key == "races" then
        bottom[#bottom + 1] = { "Use target", 120, function(button)
            if raceUnit == "player" then
                if not UnitExists("target") then return say("Target a player first, ideally a woman of any race.") end
                raceUnit = "target"
                button:SetText("Use me")
            else
                raceUnit = "player"
                button:SetText("Use target")
            end
            gridReload(grid)
        end }
    end
    row(12, bottom)

    for _, set in ipairs(LAB_SETS) do
        for _, id in ipairs(set[2]) do
            if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
        end
    end
    gridReload(grid)
    return grid
end

-- Dress test -----------------------------------------------------------------------
-- The race-swapped gnome wears your gear and undresses, but bare "item:ID"
-- strings did not dress it. This tries each way Blizzard's UI dresses an
-- actor: full item links (the dressing room), item modified appearance IDs
-- (the shop) and ItemTransmogInfo (the collections UI). Afterwards the
-- actor's own slot data says whether it took the item, which "Success" does
-- not.

local DRESS_ITEMS = {
    { 10545, "Gnomish Goggles" }, { 6219, "Arclight Spanner" },
    { 16866, "Helm of Might" }, { 16868, "Pauldrons of Might" }, { 16865, "Breastplate of Might" },
    { 16867, "Legplates of Might" }, { 16863, "Gauntlets of Might" }, { 16862, "Sabatons of Might" },
}

local SLOT_FOR = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5, INVTYPE_ROBE = 5, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_CLOAK = 15,
    INVTYPE_WEAPON = 16, INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_RANGED = 16, INVTYPE_RANGEDRIGHT = 16, INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_SHIELD = 17, INVTYPE_HOLDABLE = 17, INVTYPE_TABARD = 19,
}

local dress

local function itemFacts(item)
    local facts = { id = item }
    local ok, itemID, _, _, equipLoc = pcall(C_Item.GetItemInfoInstant, item)
    facts.exists = ok and itemID ~= nil
    facts.equipLoc = ok and equipLoc or nil
    local okN, name, link = pcall(C_Item.GetItemInfo, item)
    if okN then facts.name, facts.link = name, link end
    if C_TransmogCollection and C_TransmogCollection.GetItemInfo then
        local okT, appearanceID, sourceID = pcall(C_TransmogCollection.GetItemInfo, item)
        if okT then facts.appearanceID, facts.sourceID = appearanceID, sourceID end
    end
    return facts
end

local function factsText(f)
    if not f.exists then return tostring(f.id) .. ": not in this client's item data" end
    return ("%s %s [%s] appearance %s, source %s%s"):format(tostring(f.id), tostring(f.name or "?"),
        tostring(f.equipLoc), tostring(f.appearanceID), tostring(f.sourceID), f.link and "" or ", no link yet")
end

local function slotAppearance(actor, slot)
    if not slot then return nil end
    local ok, info = pcall(actor.GetItemTransmogInfo, actor, slot)
    return ok and type(info) == "table" and info.appearanceID or nil
end

local function makeTransmogInfo(sourceID)
    if ItemUtil and ItemUtil.CreateItemTransmogInfo then return ItemUtil.CreateItemTransmogInfo(sourceID) end
    return CreateAndInitFromMixin(ItemTransmogInfoMixin, sourceID, 0, 0)
end

local DRESS_METHODS = {
    { "item ID", function(a, f) return a:TryOn("item:" .. f.id) end },
    { "item link", function(a, f)
        if not f.link then return "no link (item not loaded)" end
        return a:TryOn(f.link)
    end },
    { "appearance ID", function(a, f)
        if not f.sourceID then return "no appearance" end
        return a:TryOn(f.sourceID)
    end },
    { "transmog info", function(a, f)
        if not f.sourceID then return "no appearance" end
        return a:SetItemTransmogInfo(makeTransmogInfo(f.sourceID), nil, true)
    end },
}

local function dressLog(label, lines, took, tried)
    local summary = ("%s: %d of %d slots took an item"):format(label, took, tried)
    say(summary)
    for _, line in ipairs(lines) do say("   %s", line) end
    put("dress", label, summary .. " | " .. table.concat(lines, " | "))
    dress.tile.actionText = summary
    tileStatus(dress.tile)
end

-- Applies items (facts tables) with a method and checks each target slot.
local function dressApply(label, method, factsList)
    local a = dress.actor
    pcall(a.Undress, a, true)
    local took, lines = 0, {}
    for _, f in ipairs(factsList) do
        local slot = SLOT_FOR[f.equipLoc or ""]
        local ok, result = pcall(method, a, f)
        local reason
        if not ok then
            reason = "error: " .. tostring(result)
        elseif type(result) == "number" then
            reason = enumName(Enum and Enum.ItemTryOnReason, result)
        else
            reason = tostring(result)
        end
        local after = slotAppearance(a, slot)
        if after and after ~= 0 then took = took + 1 end
        lines[#lines + 1] = ("%s: %s, slot %s now %s"):format(tostring(f.name or f.id), reason, tostring(slot), tostring(after))
    end
    dressLog(label, lines, took, #factsList)
end

local function equippedFacts()
    local list = {}
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then list[#list + 1] = itemFacts(link) end
    end
    return list
end

local function bagFacts()
    local list = {}
    for bag = 0, 4 do
        local okN, slots = pcall(C_Container.GetContainerNumSlots, bag)
        for slot = 1, (okN and slots or 0) do
            local okL, link = pcall(C_Container.GetContainerItemLink, bag, slot)
            if okL and link then
                local f = itemFacts(link)
                if SLOT_FOR[f.equipLoc or ""] then list[#list + 1] = f end
            end
        end
    end
    return list
end

local function linkMethod(a, f)
    return a:TryOn(f.link)
end

local function buildDress()
    if dress then
        dress.frame:Show()
        return dress
    end
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbe_dress", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbe_dress", UIParent, "BackdropTemplate") end
    f:SetSize(556, 470)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("AzerBuddy Dress Test") end

    local grid = { key = "dress", frame = f, cols = 1, tileW = 300, tileH = 424, camDistance = 3.2 }
    local tile = createTile(grid, 1, { "Gnome (race 7, native)", "actor", function(a)
        return a:SetModelByUnit("player", false, true, false, true, false, gnomeRaceID)
    end })
    dress = { frame = f, grid = grid, tile = tile, actor = tile.target }

    local buttons = {
        { "Reset gnome", function() gridSetup(grid, tile) end },
        { "Undress", function()
            local okU, err = pcall(dress.actor.Undress, dress.actor, true)
            tile.actionText = okU and "undressed" or tostring(err)
            tileStatus(tile)
        end },
        { "My gear (links)", function() dressApply("My gear by link", linkMethod, equippedFacts()) end },
        { "Bag gear (links)", function() dressApply("Bag gear by link", linkMethod, bagFacts()) end },
    }
    for _, method in ipairs(DRESS_METHODS) do
        buttons[#buttons + 1] = { "Kit + T1 by " .. method[1], function()
            local list = {}
            for i, item in ipairs(DRESS_ITEMS) do list[i] = itemFacts(item[1]) end
            dressApply("Kit + T1 by " .. method[1], method[2], list)
        end }
    end
    buttons[#buttons + 1] = { "Item facts", function()
        for _, item in ipairs(DRESS_ITEMS) do
            local text = factsText(itemFacts(item[1]))
            say(text)
            put("dressFacts", tostring(item[1]), text)
        end
    end }

    for i, spec in ipairs(buttons) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(220, 22)
        b:SetPoint("TOPLEFT", 324, -30 - (i - 1) * 28)
        b:SetText(spec[1])
        b:SetScript("OnClick", spec[2])
    end

    for _, item in ipairs(DRESS_ITEMS) do
        if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, item[1]) end
    end
    gridSetup(grid, tile)
    return dress
end

-- Collect test ---------------------------------------------------------------------
-- NPC buddies: collecting a target saves its display ID, which lives in the
-- game's data, so the buddy can be rebuilt later with the NPC nowhere near.
-- The list is saved; after a /reload, Previous and Next rebuild each entry
-- from the saved display ID alone.

local COLLECT_HATS = {
    { 10545, "Gnomish Goggles" }, { 10726, "Gnomish Mind Control Cap" },
    { 4368, "Flying Tiger Goggles" }, { 16866, "Helm of Might" },
}

local collect
local scoutUnit   -- defined with the scout below; collecting logs to the roster too

local function secretSafe(v)
    if issecretvalue and issecretvalue(v) then return "<secret>" end
    return v
end

-- First return of a unit query, or nil if it errors or is secret.
local function read(fn, ...)
    if not fn then return nil end
    local ok, v = pcall(fn, ...)
    return ok and secretSafe(v) or nil
end

local function npcIDFromGUID(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" or kind == "Pet" then return tonumber(id) end
end

local function collectList()
    AzerBuddyProbeCharDB.collection = AzerBuddyProbeCharDB.collection or {}
    return AzerBuddyProbeCharDB.collection
end

local function collectShow()
    local list = collectList()
    local tile = collect.tile
    local e = list[collect.index]
    if not e then
        tile.setupText = "Nothing collected yet."
        tile.actionText = "Target an NPC, press Collect target."
        return tileStatus(tile)
    end
    if e.displayID then pcall(tile.target.SetDisplayInfo, tile.target, e.displayID) end
    tile.setupText = ("%d/%d %s (display %s)"):format(collect.index, #list, tostring(e.name), tostring(e.displayID))
    tile.actionText = ("%s %s, %s"):format(tostring(e.classification), tostring(e.creatureType), tostring(e.zone))
    tileStatus(tile)
end

local function collectTarget()
    if InCombatLockdown() then return say("Leave combat first.") end
    if not UnitExists("target") then return say("Target an NPC first.") end
    if UnitIsPlayer("target") then return say("Players can't be collected: their look can't be saved.") end
    -- Loading a unit whose model isn't in view crashes the client.
    if not UnitIsVisible("target") then return say("Get closer: the target's model isn't loaded.") end
    local _, _, raceFile = pcall(UnitRace, "target")
    local entry = {
        name = read(UnitName, "target"),
        npcID = npcIDFromGUID(read(UnitGUID, "target")),
        creatureType = read(UnitCreatureType, "target"),
        family = read(UnitCreatureFamily, "target"),
        classification = read(UnitClassification, "target"),
        sex = read(UnitSex, "target"),
        race = secretSafe(raceFile),
        level = read(UnitLevel, "target"),
        zone = GetZoneText(),
        when = date("%Y-%m-%d %H:%M"),
    }
    local lookup = collect.lookup
    local okSet, err = pcall(lookup.SetUnit, lookup, "target")
    entry.setUnit = okSet and "ok" or tostring(err)
    C_Timer.After(0.6, function()
        local okD, displayID = pcall(lookup.GetDisplayInfo, lookup)
        entry.displayID = okD and secretSafe(displayID) or nil
        local list = collectList()
        list[#list + 1] = entry
        collect.index = #list
        collectShow()
        -- The roster is the seen list; catching marks the entry as caught.
        if entry.npcID and scoutUnit then
            pcall(scoutUnit, "target")
            local rosterEntry = AzerBuddyProbeAccountDB.scout and AzerBuddyProbeAccountDB.scout[entry.npcID]
            if rosterEntry then rosterEntry.caught = (rosterEntry.caught or 0) + 1 end
        end
        say("Collected %s: display %s, npc %s, %s %s %s, sex %s, race %s, SetUnit %s",
            tostring(entry.name), tostring(entry.displayID), tostring(entry.npcID), tostring(entry.classification),
            tostring(entry.creatureType), tostring(entry.family or ""), tostring(entry.sex), tostring(entry.race), entry.setUnit)
    end)
end

local function collectStep(delta)
    local n = #collectList()
    if n == 0 then return collectShow() end
    collect.index = ((collect.index or 1) - 1 + delta) % n + 1
    collectShow()
end

local function buildCollect()
    if collect then
        collect.frame:Show()
        return collect
    end
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbe_collect", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbe_collect", UIParent, "BackdropTemplate") end
    f:SetSize(556, 434)
    f:SetPoint("CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("AzerBuddy Collect Test") end

    local grid = { key = "collect", frame = f, cols = 1, tileW = 300, tileH = 388, camDistance = 4 }
    local tile = createTile(grid, 1, { "Collected buddy", "model", function() end })

    -- Reads the target's display ID; never shown.
    local lookup = CreateFrame("DressUpModel", nil, f)
    lookup:SetSize(1, 1)
    lookup:SetPoint("TOPLEFT")
    lookup:SetAlpha(0)

    collect = { frame = f, tile = tile, lookup = lookup, index = #collectList() }

    local hat = 0
    local buttons = {
        { "Collect target", collectTarget },
        { "Previous", function() collectStep(-1) end },
        { "Next", function() collectStep(1) end },
        { "Try a hat", function()
            hat = hat % #COLLECT_HATS + 1
            local h = COLLECT_HATS[hat]
            local okT, reason = pcall(tile.target.TryOn, tile.target, "item:" .. h[1])
            tile.actionText = ("%s: %s"):format(h[2], okT and enumName(Enum and Enum.ItemTryOnReason, reason) or tostring(reason))
            tileStatus(tile)
        end },
        { "Animations", function()
            local supported = animSupport(tile.target)
            local e = collectList()[collect.index]
            say("%s has %d of %d animations: %s", tostring(e and e.name), #supported, #ANIMS, table.concat(supported, ", "))
            if e then e.animations = #supported end
        end },
        { "Wave", function() pcall(tile.target.SetAnimation, tile.target, 67) end },
        { "Dance", function() pcall(tile.target.SetAnimation, tile.target, 69) end },
        { "Forget this one", function()
            local list = collectList()
            if list[collect.index] then table.remove(list, collect.index) end
            collect.index = math.min(collect.index, #list)
            collectShow()
        end },
    }
    for i, spec in ipairs(buttons) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(220, 22)
        b:SetPoint("TOPLEFT", 324, -30 - (i - 1) * 28)
        b:SetText(spec[1])
        b:SetScript("OnClick", spec[2])
    end

    for _, h in ipairs(COLLECT_HATS) do
        if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, h[1]) end
    end
    collectShow()
    return collect
end

-- Scout --------------------------------------------------------------------------------
-- Logs every NPC you mouse over, target or see a nameplate for, account-wide
-- and keyed by NPC ID, so BuddyDex entries get written for the NPCs Forever
-- actually has. It reads unit and tooltip data only. Loading nameplate units
-- into a hidden model to read display IDs crashed the client ("Missing model
-- in GeosRenderPrep"): nameplates arrive before the NPC's model has loaded.
-- Display IDs come from collecting, which uses the loaded target.

local scoutFound          -- the scout window's live list, defined below
local scoutSession = {}   -- NPC IDs first logged this session, oldest first

-- The first tooltip line after the name that isn't the level line, if any.
local function scoutTitle(tip)
    for _, line in ipairs(tip) do
        if not line:find("^Level") and not line:find("^Lvl") then
            return (line:gsub("^<(.*)>$", "%1"))
        end
    end
end

function scoutUnit(unit)
    if not AzerBuddyProbeAccountDB or AzerBuddyProbeAccountDB.scoutOff then return end
    if InCombatLockdown() or not UnitExists(unit) or UnitIsPlayer(unit) then return end
    local npcID = npcIDFromGUID(read(UnitGUID, unit))
    if not npcID then return end
    AzerBuddyProbeAccountDB.scout = AzerBuddyProbeAccountDB.scout or {}
    local log = AzerBuddyProbeAccountDB.scout
    if log[npcID] then
        log[npcID].seen = (log[npcID].seen or 1) + 1
        return
    end

    -- Tooltip lines after the name hold the title ("Auctioneer") and level.
    local tip = {}
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            for i = 2, math.min(#data.lines, 4) do
                local text = data.lines[i] and data.lines[i].leftText
                if type(text) == "string" and not (issecretvalue and issecretvalue(text)) then tip[#tip + 1] = text end
            end
        end
    end
    local _, _, raceFile = pcall(UnitRace, unit)
    log[npcID] = {
        name = read(UnitName, unit),
        title = scoutTitle(tip),
        tip = tip,
        type = read(UnitCreatureType, unit),
        family = read(UnitCreatureFamily, unit),
        class = read(UnitClassification, unit),
        sex = read(UnitSex, unit),
        race = secretSafe(raceFile),
        level = read(UnitLevel, unit),
        reaction = read(UnitReaction, unit, "player"),
        zone = GetZoneText(),
        subzone = GetSubZoneText(),
        first = date("%Y-%m-%d"),
        seen = 1,
    }
    scoutSession[#scoutSession + 1] = npcID
    if scoutFound then scoutFound(npcID) end
end

local function scoutStatus()
    local n, caught, zones = 0, 0, {}
    for _, e in pairs(AzerBuddyProbeAccountDB.scout or {}) do
        n = n + 1
        if e.caught then caught = caught + 1 end
        zones[e.zone or "?"] = (zones[e.zone or "?"] or 0) + 1
    end
    local parts = {}
    for zone, count in pairs(zones) do parts[#parts + 1] = zone .. " " .. count end
    table.sort(parts)
    say("Scout is %s%s: %d NPCs seen, %d caught. %s", AzerBuddyProbeAccountDB.scoutOff and "off" or "on",
        AzerBuddyProbeAccountDB.sweepRestore and " (sweeping)" or "", n, caught, table.concat(parts, ", "))
end

-- Sweep shows friendly NPC nameplates so every NPC in range gets logged, and
-- puts the setting back afterwards.
local SWEEP_CVAR = "nameplateShowFriendlyNPCs"

local function getCVar(name)
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
    return GetCVar(name)
end

local function setCVar(name, value)
    if C_CVar and C_CVar.SetCVar then return C_CVar.SetCVar(name, value) end
    return SetCVar(name, value)
end

local function sweep(on)
    local db = AzerBuddyProbeAccountDB
    if InCombatLockdown() then return say("Leave combat first.") end
    if on then
        if not db.sweepRestore then
            local ok, previous = pcall(getCVar, SWEEP_CVAR)
            db.sweepRestore = ok and tostring(previous) or "0"
        end
        local ok, err = pcall(setCVar, SWEEP_CVAR, "1")
        say(ok and "Sweep on: friendly NPC nameplates shown. Walk around, then /probe scout sweep off." or ("Sweep failed: " .. tostring(err)))
    elseif db.sweepRestore then
        pcall(setCVar, SWEEP_CVAR, db.sweepRestore)
        say("Sweep off: friendly NPC nameplates set back to %s.", db.sweepRestore)
        db.sweepRestore = nil
    end
    db.scoutOff = nil
end

-- Scout window: every NPC first logged this session, colored by rarity.

local scoutWindow

local RARITY_COLORS = {
    trivial = { 0.6, 0.6, 0.6 }, minus = { 0.6, 0.6, 0.6 }, normal = { 1, 1, 1 },
    elite = { 1, 0.82, 0 }, rare = { 0.55, 0.75, 1 }, rareelite = { 0.75, 0.4, 1 }, worldboss = { 1, 0.5, 0 },
}

local function scoutLine(e)
    local title = e.title and (" |cffaaaaaa<" .. e.title .. ">|r") or ""
    local place = (e.subzone and e.subzone ~= "") and e.subzone or e.zone or "?"
    local level = e.level and (" " .. tostring(e.level)) or ""
    return ("%s%s  |cff888888%s%s, %s|r"):format(tostring(e.name), title, tostring(e.type or "?"), level, place)
end

local function scoutHeader()
    local total, caught = 0, 0
    for _, e in pairs(AzerBuddyProbeAccountDB.scout or {}) do
        total = total + 1
        if e.caught then caught = caught + 1 end
    end
    scoutWindow.header:SetText(("Seen %d    New this session %d    Caught %d"):format(total, #scoutSession, caught))
    scoutWindow.sweepButton:SetText(AzerBuddyProbeAccountDB.sweepRestore and "Stop sweep" or "Start sweep")
end

local function scoutAddLine(npcID)
    local e = AzerBuddyProbeAccountDB.scout[npcID]
    if not e then return end
    local color = RARITY_COLORS[e.class] or RARITY_COLORS.normal
    scoutWindow.list:AddMessage(scoutLine(e), color[1], color[2], color[3])
end

function scoutFound(npcID)
    if not scoutWindow then return end
    scoutAddLine(npcID)
    scoutHeader()
end

local function buildScoutWindow()
    if scoutWindow then
        scoutWindow:Show()
        scoutHeader()
        return scoutWindow
    end
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbe_scout", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbe_scout", UIParent, "BackdropTemplate") end
    f:SetSize(480, 380)
    f:SetPoint("RIGHT", -40, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("AzerBuddy Scout") end

    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 14, -32)
    header:SetPoint("TOPRIGHT", -14, -32)
    header:SetJustifyH("LEFT")
    f.header = header

    local list = CreateFrame("ScrollingMessageFrame", nil, f)
    list:SetPoint("TOPLEFT", 14, -54)
    list:SetPoint("BOTTOMRIGHT", -14, 42)
    list:SetFontObject(GameFontHighlightSmall)
    list:SetJustifyH("LEFT")
    list:SetFading(false)
    list:SetMaxLines(2000)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    f.list = list

    local sweepButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sweepButton:SetSize(120, 22)
    sweepButton:SetPoint("BOTTOMLEFT", 12, 12)
    sweepButton:SetScript("OnClick", function()
        sweep(not AzerBuddyProbeAccountDB.sweepRestore)
        scoutHeader()
    end)
    f.sweepButton = sweepButton

    local save = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    save:SetSize(140, 22)
    save:SetPoint("BOTTOMRIGHT", -12, 12)
    save:SetText("Save (reload UI)")
    save:SetScript("OnClick", function() ReloadUI() end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", sweepButton, "RIGHT", 10, 0)
    hint:SetText("Mouse wheel scrolls the list.")

    scoutWindow = f
    for _, npcID in ipairs(scoutSession) do scoutAddLine(npcID) end
    scoutHeader()
    return f
end

local scoutEvents = CreateFrame("Frame")
pcall(scoutEvents.RegisterEvent, scoutEvents, "UPDATE_MOUSEOVER_UNIT")
pcall(scoutEvents.RegisterEvent, scoutEvents, "PLAYER_TARGET_CHANGED")
pcall(scoutEvents.RegisterEvent, scoutEvents, "NAME_PLATE_UNIT_ADDED")
scoutEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "UPDATE_MOUSEOVER_UNIT" then
        unit = "mouseover"
    elseif event == "PLAYER_TARGET_CHANGED" then
        unit = "target"
    end
    local ok, err = pcall(scoutUnit, unit)
    if not ok and not AzerBuddyProbeAccountDB.scoutErrorShown then
        AzerBuddyProbeAccountDB.scoutErrorShown = true
        say("Scout error (shown once): %s", tostring(err))
    end
end)

-- Tools ----------------------------------------------------------------------------------
-- Every tool behind a button. /probe or the minimap's addon menu opens
-- this window, so nothing else needs typing.

local hub
local ICON = "Interface\\Icons\\INV_Misc_Gear_01"

local function ensureReport()
    if not report then
        report = AzerBuddyProbeCharDB.report or { ranAt = date("%Y-%m-%d %H:%M:%S") }
        AzerBuddyProbeCharDB.report = report
    end
end

local function hubStatus()
    if not hub then return end
    local db = AzerBuddyProbeAccountDB
    local total, caught = 0, 0
    for _, e in pairs(db.scout or {}) do
        total = total + 1
        if e.caught then caught = caught + 1 end
    end
    hub.status:SetText(("Roster: %d seen, %d caught\nScout %s, sweep %s"):format(total, caught,
        db.scoutOff and "paused" or "on", db.sweepRestore and "on" or "off"))
    hub.sweepButton:SetText(db.sweepRestore and "Stop sweep" or "Start sweep")
    hub.scoutButton:SetText(db.scoutOff and "Resume scout" or "Pause scout")
end

-- Keep the counts current while the scout finds NPCs.
local scoutFoundInWindow = scoutFound
scoutFound = function(npcID)
    scoutFoundInWindow(npcID)
    if hub and hub:IsShown() then hubStatus() end
end

local HUB_W = 300

local function buildHub()
    if hub then
        hub:SetShown(not hub:IsShown())
        hubStatus()
        return hub
    end
    local db = AzerBuddyProbeAccountDB
    local ok, f = pcall(CreateFrame, "Frame", "AzerBuddyProbeHub", UIParent, "BasicFrameTemplateWithInset")
    if not ok then f = CreateFrame("Frame", "AzerBuddyProbeHub", UIParent, "BackdropTemplate") end
    f:SetSize(HUB_W, 470)
    f:SetPoint("LEFT", 60, 0)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    if f.TitleText then f.TitleText:SetText("AzerBuddy Probe") end
    tinsert(UISpecialFrames, "AzerBuddyProbeHub")   -- Esc closes it
    hub = f

    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    status:SetPoint("TOPLEFT", 16, -32)
    status:SetPoint("TOPRIGHT", -16, -32)
    status:SetJustifyH("LEFT")
    f.status = status

    local y = -72
    local function section(text)
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 16, y)
        fs:SetText(text)
        y = y - 20
    end
    local function button(text, tip, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(HUB_W - 32, 22)
        b:SetPoint("TOPLEFT", 16, y)
        b:SetText(text)
        b:SetScript("OnClick", function(self)
            onClick(self)
            hubStatus()
        end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        y = y - 26
        return b
    end

    section("Roster")
    button("Open scout list", "The live list of NPCs the scout finds.", function() buildScoutWindow() end)
    f.sweepButton = button("Start sweep", "Shows friendly NPC nameplates so every NPC in range is logged. Stopping puts your nameplate setting back.", function()
        local starting = not db.sweepRestore
        sweep(starting)
        if starting then buildScoutWindow() elseif scoutWindow then scoutHeader() end
    end)
    f.scoutButton = button("Pause scout", "Stops or restarts logging NPCs you mouse over, target or see.", function()
        db.scoutOff = (not db.scoutOff) or nil
        if scoutWindow then scoutHeader() end
    end)

    y = y - 6
    section("Model tests")
    button("Run full probe", "Checks the API, voice, races and models, and opens the model window. About 10 seconds.", function() runProbe() end)
    button("Gnome lab", "Ten ways to get a gnome body, side by side.", function() ensureReport(); buildGrid("lab") end)
    button("Race sweep", "You drawn as every race.", function() ensureReport(); buildGrid("races") end)
    button("Dress test", "Which way of putting gear on the gnome works.", function() ensureReport(); buildDress() end)
    button("Collect test", "Collect your target as an NPC buddy and rebuild it later.", function() ensureReport(); buildCollect() end)
    button("Actor test", "The 3D scene model on its own.", function() ensureReport(); buildActorWindow():Show() end)
    button("Model window", "The dressing-room model on its own.", function() buildWindow():Show() end)

    y = y - 6
    section("Save")
    button("Save (reload UI)", "Writes the roster and test results to disk.", function() ReloadUI() end)

    hubStatus()
    return f
end

local registered = false
local function registerCompartment()
    if registered then return end
    registered = true
    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        pcall(AddonCompartmentFrame.RegisterAddon, AddonCompartmentFrame, {
            text = "AzerBuddy Probe",
            icon = ICON,
            notCheckable = true,
            func = function() buildHub() end,
        })
    end
end

-- Events -----------------------------------------------------------------------

local events = CreateFrame("Frame")

local function listen(event)
    pcall(events.RegisterEvent, events, event)
end

listen("ADDON_LOADED")
listen("CHAT_MSG_ADDON")
listen("VOICE_CHAT_TTS_PLAYBACK_STARTED")
listen("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
listen("VOICE_CHAT_TTS_PLAYBACK_FAILED")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        -- Tests the reported beta bug where account-wide saved variables
        -- are written but never read back.
        AzerBuddyProbeAccountDB = AzerBuddyProbeAccountDB or {}
        AzerBuddyProbeCharDB = AzerBuddyProbeCharDB or {}
        local acc, chr = AzerBuddyProbeAccountDB, AzerBuddyProbeCharDB
        chr.persistence = {
            charReadBack = (chr.loads or 0) > 0 and "yes" or "first load",
            accountReadBack = (acc.loads or 0) > 0 and "yes" or ((chr.loads or 0) > 0 and "NO" or "first load"),
            accountLoads = acc.loads or 0,
            charLoads = chr.loads or 0,
        }
        acc.loads = (acc.loads or 0) + 1
        chr.loads = (chr.loads or 0) + 1
        acc.launcherHidden, acc.launcherPos = nil, nil   -- the old on-screen gear icon's settings
        registerCompartment()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix = ...
        if prefix == "AZBPROBE" then put("comms", "received", true) end
    elseif event:find("^VOICE_CHAT_TTS_PLAYBACK") then
        put("tts", "playback", event:gsub("VOICE_CHAT_TTS_PLAYBACK_", ""):lower())
    end
end)

SLASH_AZERBUDDYPROBE1 = "/probe"
SlashCmdList.AZERBUDDYPROBE = function(msg)
    msg = (msg or ""):lower()
    if msg == "scout sweep" or msg == "scout sweep off" then
        sweep(msg == "scout sweep")
        if msg == "scout sweep" then buildScoutWindow() elseif scoutWindow then scoutHeader() end
    elseif msg == "scout" or msg == "scout on" or msg == "scout off" then
        if msg == "scout off" then AzerBuddyProbeAccountDB.scoutOff = true end
        if msg == "scout on" then AzerBuddyProbeAccountDB.scoutOff = nil end
        scoutStatus()
        buildScoutWindow()
    elseif msg == "window" then
        buildWindow():Show()
    elseif msg == "actor" or msg == "lab" or msg == "races" or msg == "dress" or msg == "collect" then
        if not report then
            report = AzerBuddyProbeCharDB.report or { ranAt = date("%Y-%m-%d %H:%M:%S") }
            AzerBuddyProbeCharDB.report = report
        end
        if msg == "actor" then
            buildActorWindow():Show()
        elseif msg == "dress" then
            buildDress()
        elseif msg == "collect" then
            buildCollect()
        else
            buildGrid(msg)
        end
    elseif msg == "run" then
        runProbe()
    else
        buildHub()
    end
end
