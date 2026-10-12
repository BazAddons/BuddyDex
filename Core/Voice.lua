-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Core/Voice.lua: buddies' voices (ns.Voice). The Mini Me's is recorded
-- for BuddyDex with ElevenLabs and shipped in the optional BuddyDex Voice
-- addon (BuddyDexVoicePack: clips keyed by each line's exact text, in a
-- male and a female gnome voice; tools/voice/generate.py makes them). The
-- goal is every line recorded; until then a line without a clip speaks in
-- the chat bubble alone. A friend of a race with recorded voices
-- (RACE_VOICES: humans, dwarves, night elves, Skyborne, and gnomes in the
-- Mini Me's own two voices) speaks their lines the same way. Any other friend, or any friend without the pack, speaks in
-- the voice the game gives their model (Data/NpcSounds.lua): their own
-- greetings, farewells and annoyed lines, with the words in the bubble. With the voice
-- off (settings voiceMode "off") everyone speaks in the bubble alone. All
-- of it plays on the Dialog channel, so the game's dialog volume sets how
-- loud.

local Voice = {}
ns.Voice = Voice

local clipHandle   -- the clip playing, cut off for the next line

local function Settings()
    return ns.db and ns.db.settings or {}
end

-- Whether the BuddyDex Voice addon is installed.
function Voice.HasPack()
    local pack = BuddyDexVoicePack
    return type(pack) == "table" and type(pack.voices) == "table" and type(pack.path) == "string"
end

-- "recorded" with the voice on and the pack installed, else "off".
function Voice.Mode()
    if Settings().voiceMode == "off" or not Voice.HasPack() then return "off" end
    return "recorded"
end

function Voice.Stop()
    if clipHandle and StopSound then pcall(StopSound, clipHandle) end
    clipHandle = nil
end

-- A voice's clips: voice is the pack's name for it ("male", "female"), or
-- the Mini Me's sex (0 male, 1 female).
local function Clips(voice)
    if type(voice) ~= "string" then voice = voice == 1 and "female" or "male" end
    local clips = BuddyDexVoicePack.voices[voice]
    return type(clips) == "table" and clips or nil
end

-- Plays the clip for a line (its exact text, before fill-ins) in a voice
-- (as Clips takes it). Returns true if there was one.
function Voice.PlayClip(line, voice)
    if type(line) ~= "string" or not Voice.HasPack() or not PlaySoundFile then return false end
    local clips = Clips(voice)
    local file = clips and clips[line]
    if type(file) ~= "string" then return false end
    Voice.Stop()
    local ok, willPlay, handle = pcall(PlaySoundFile, BuddyDexVoicePack.path .. file, "Dialog")
    if not ok or willPlay == false then return false end
    clipHandle = handle
    return true
end

-- Friends -------------------------------------------------------------------

-- The pack's voice for a race's NPCs, by sex (0 male, 1 female), for the
-- races whose lines are recorded, by ChrRaces ID (tools/data/npc_sounds.py
-- keeps their displays). Gnome friends share the Mini Me's voices.
Voice.RACE_VOICES = {
    [1] = { [0] = "human-male", [1] = "human-female" },
    [3] = { [0] = "dwarf-male", [1] = "dwarf-female" },
    [4] = { [0] = "nightelf-male", [1] = "nightelf-female" },
    [7] = { [0] = "male", [1] = "female" },
    -- Forever's Skyborne (the shen'dorei): High Order and Windshaper, one people.
    [95] = { [0] = "skyborne-male", [1] = "skyborne-female" },
    [96] = { [0] = "skyborne-male", [1] = "skyborne-female" },
}

-- The recorded voice for a creature display, or nil if its race has none.
function Voice.NpcVoice(display)
    display = tonumber(display)
    local data = ns.NpcSounds
    if not (display and data and type(data.bodies) == "string") then return nil end
    local race, sex = data.bodies:match("%s" .. display .. ":(%d+):(%d)")
    local voices = race and Voice.RACE_VOICES[tonumber(race)]
    return voices and voices[tonumber(sex)] or nil
end

local GREETING, FAREWELL, ANNOYED = 1, 2, 3
Voice.GREETING, Voice.FAREWELL, Voice.ANNOYED = GREETING, FAREWELL, ANNOYED

-- Which of their sounds a friend makes for a moment, as an NPC does when
-- clicked: a greeting when they arrive or are poked, the annoyed lines when
-- poked too often, a farewell when the player steps away. The rest of what
-- they say comes with a greeting now and then (NPC_CHATTER of the time), so
-- they don't say hello before every line.
local NPC_MOMENTS = {
    greet = GREETING, reload = GREETING, befriended = GREETING, poke = GREETING,
    buddy = GREETING, back = GREETING, seeFriend = GREETING, waveBack = GREETING,
    pokeMany = ANNOYED, away = FAREWELL,
}
Voice.NPC_CHATTER = 0.5

-- The sound kits for a creature display, { greeting, farewell, annoyed },
-- or nil if the game gives it no voice.
function Voice.NpcKits(display)
    display = tonumber(display)
    local data = ns.NpcSounds
    if not (display and data and type(data.displays) == "string") then return nil end
    local set = data.displays:match("%s" .. display .. ":(%d+)")
    return set and data.sets[tonumber(set)] or nil
end

-- Plays one of a friend's sounds (GREETING, FAREWELL or ANNOYED); the game
-- picks the line from the kit. A farewell is left to finish whoever speaks
-- next, since it is said on the way out. Returns true if it played.
function Voice.PlayNpc(display, kind)
    if Settings().voiceMode == "off" or not PlaySound then return false end
    local kits = Voice.NpcKits(display)
    local kit = kits and kits[kind]
    if not kit or kit == 0 then return false end
    if kind ~= FAREWELL then Voice.Stop() end
    local ok, willPlay, handle = pcall(PlaySound, kit, "Dialog")
    if not ok or willPlay == false then return false end
    if kind ~= FAREWELL then clipHandle = handle end
    return true
end

-- The recorded voice a friend speaks in: their race's, when the voice is on
-- and the installed pack has it (an older pack may not), else nil.
local function RecordedVoice(display)
    if Voice.Mode() ~= "recorded" then return nil end
    local voice = Voice.NpcVoice(display)
    return voice and Clips(voice) and voice or nil
end

-- A friend going home says goodbye the game's way, unless they speak in a
-- recorded voice (a stranger's farewell would break it).
function Voice.Farewell(display)
    if RecordedVoice(display) then return false end
    return Voice.PlayNpc(display, FAREWELL)
end

-- Says a line aloud if it can. opts: line (its text before fill-ins), sex
-- (0 male, 1 female), miniMe (the Mini Me's recorded voice), or display
-- and moment (a friend). A friend with a recorded voice says the line in
-- it, or nothing when it isn't recorded (as the Mini Me does); any other
-- friend makes the game's sound for the moment. Returns true if something
-- played.
function Voice.Speak(opts)
    if not opts then return false end
    if opts.display then
        local recorded = RecordedVoice(opts.display)
        if recorded then return Voice.PlayClip(opts.line, recorded) end
        local kind = NPC_MOMENTS[opts.moment]
        if not kind then
            if math.random() >= Voice.NPC_CHATTER then return false end
            kind = GREETING
        end
        return Voice.PlayNpc(opts.display, kind)
    end
    if not opts.miniMe or Voice.Mode() ~= "recorded" then return false end
    return Voice.PlayClip(opts.line, opts.sex)
end

-- A random clip, for the options page's Test voice.
function Voice.Test(sex)
    if not Voice.HasPack() then return false end
    local clips = Clips(sex)
    if not clips then return false end
    local lines = {}
    for line in pairs(clips) do lines[#lines + 1] = line end
    return #lines > 0 and Voice.PlayClip(lines[math.random(#lines)], sex)
end
