-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- UI/MiniMe.lua: buddies in 3D (ns.MiniMe). The Mini Me is the player
-- drawn as a gnome in their own armor, for the Buddy page and the buddy on
-- screen (UI/Companion.lua). It is the route the in-game shop uses to show
-- an outfit on another race, proven in the probe's Gnome Lab:
-- SetModelByUnit("player", sheathe, autoDress, hideWeapons,
-- usePlayerNativeForm = true, holdBowString, customRaceID). "player" is
-- always loaded, so this is never the nameplate crash (DESIGN.md).
--
-- A friend who comes along stands on the same kind of stage, drawn from
-- their creature display (SetModelByCreatureDisplayID, as Blizzard's own
-- pet and encounter screens do). Both stages measure the model and aim
-- the camera from its real height, and say how tall it is, so the buddy
-- on screen can draw everyone at one scale: a human friend twice the Mini
-- Me's height, as in the world.

local MiniMe = {}
ns.MiniMe = MiniMe

local GNOME_RACE_ID = 7
local MINIME_FOV = 0.5
local REDRESS_DELAY = 0.4   -- seconds of quiet after the last gear event
local AIM_RETRY, AIM_TRIES = 0.15, 6   -- re-measuring a fresh model until it holds still

-- A stage: a ModelScene with one actor, the camera and light every buddy
-- shares, the camera aimed from the model's own size once it holds still,
-- and a fade-in once it is aimed. opts:
--   load(actor)        sets the model; returns false if it can't
--   framing            "head" for portraits, "body" for the whole buddy
--   yaw                the turn, in radians
--   onLoaded(scene), onFailed(scene)
--   onMeasured(scene, height)  the model's height once it holds still
-- Returns the scene (scene.actor, scene.Reload()) and its Load function,
-- or nil if this client can't make an actor.
local function Stage(parent, opts)
    local scene = CreateFrame("ModelScene", nil, parent)
    scene:SetCameraOrientationByYawPitchRoll(math.pi, 0, 0)
    scene:SetCameraFieldOfView(MINIME_FOV)
    scene:SetCameraNearClip(0.05)
    scene:SetCameraFarClip(100)
    pcall(scene.SetLightVisible, scene, true)
    pcall(scene.SetLightAmbientColor, scene, 0.75, 0.75, 0.75)
    pcall(scene.SetLightDiffuseColor, scene, 0.8, 0.8, 0.8)
    pcall(scene.SetLightDirection, scene, -1, 0.3, -0.5)

    local okActor, actor = pcall(scene.CreateActor, scene)
    if not (okActor and actor) then
        -- No actor, no model: the caller keeps its icon.
        scene:Hide()
        return nil
    end
    actor:SetPosition(0, 0, 0)
    actor:SetYaw(opts.yaw or 0)
    scene.actor = actor

    -- Points the camera (on +x, looking back at the actor) at the head or
    -- the whole body, from the model's own height, so anyone fits: visible
    -- is how much of the model's height the frame's height should show.
    -- Whether the field of view spans the frame's width or its height
    -- depends on the frame's shape, so the first aim is a guess that
    -- Calibrate corrects (scene.zoom) by looking at where the model lands.
    scene.zoom = 1
    local aimedAt   -- bottom, top, visible: the last aim, for Calibrate
    local function Aim(bottom, top)
        local height = top - bottom
        if height <= 0 then return end
        local visible, target
        if opts.framing == "body" then
            visible, target = height * 1.2, bottom + height * 0.5
        else
            visible, target = height * 0.45, top - height * 0.22
        end
        aimedAt = { bottom, top, visible }
        scene:SetCameraPosition(scene.zoom * visible / (2 * math.tan(MINIME_FOV / 2)), 0, target)
    end
    Aim(0, 1)   -- a gnome is about a yard tall, until the model says otherwise

    -- Projects the model's feet and head onto the frame and moves the camera
    -- so the model fills the share of the frame's height it should. The
    -- model sits at the camera's target distance, so its size on screen
    -- goes as one over the distance, and one correction lands it. Returns
    -- true when the aim was already right (or can't be checked).
    local function Calibrate()
        if not aimedAt then return true end
        local bottom, top, visible = aimedAt[1], aimedAt[2], aimedAt[3]
        local ok1, _, yBottom = pcall(scene.Project3DPointTo2D, scene, 0, 0, bottom)
        local ok2, _, yTop = pcall(scene.Project3DPointTo2D, scene, 0, 0, top)
        local okScale, scale = pcall(scene.GetEffectiveScale, scene)
        local frameHeight = scene:GetHeight()
        if not (ok1 and ok2 and okScale) or type(yBottom) ~= "number" or type(yTop) ~= "number"
            or type(scale) ~= "number" or type(frameHeight) ~= "number" or scale <= 0 or frameHeight <= 0 then
            return true
        end
        local shown = math.abs(yTop - yBottom) / scale / frameHeight
        local wanted = (top - bottom) / visible
        if shown <= 0 or math.abs(shown / wanted - 1) < 0.02 then return true end
        scene.zoom = scene.zoom * shown / wanted
        Aim(bottom, top)
        return false
    end

    -- Until the model has said how tall it is, the camera is a guess: the
    -- scene stays invisible and fades in once it is aimed, so nobody sees
    -- it jump from the guess to the real framing. A redress keeps the aim
    -- it has and stays visible.
    local fadeIn = scene:CreateAnimationGroup()
    local fade = fadeIn:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.2)
    fadeIn:SetScript("OnFinished", function() scene:SetAlpha(1) end)

    -- The model's height as it reports it now, or nil while it can't say.
    local function Measure()
        local ok, _, _, bottom, _, _, top = pcall(actor.GetActiveBoundingBox, actor)
        if ok and type(bottom) == "number" and type(top) == "number" and top - bottom > 0.2 then
            return bottom, top
        end
        return nil
    end

    -- A freshly loaded model can report its size before its body is on it
    -- (the gnome body on the Mini Me), so the aim waits until two readings
    -- agree (or it runs out of tries), and only then fades the scene in.
    local function Settle(tries, lastBottom, lastTop)
        local bottom, top = Measure()
        if bottom then Aim(bottom, top) end
        local steady = bottom and lastBottom and math.abs(bottom - lastBottom) < 0.01
            and math.abs(top - lastTop) < 0.01
        -- Held still: check the aim on screen, and look again if it moved.
        if steady and not Calibrate() then steady = false end
        if steady or tries <= 0 then
            local finalBottom, finalTop = bottom or lastBottom, top or lastTop
            if finalBottom and opts.onMeasured then opts.onMeasured(scene, finalTop - finalBottom) end
            if not scene.aimed then
                scene.aimed = true
                fadeIn:Play()
            end
            return
        end
        C_Timer.After(AIM_RETRY, function() Settle(tries - 1, bottom, top) end)
    end

    local function OnLoaded()
        if scene.loaded then return end
        pcall(actor.SetAnimation, actor, 0)
        scene.loaded = true
        Settle(AIM_TRIES)
        if opts.onLoaded then opts.onLoaded(scene) end
    end

    local function Load()
        scene.loaded = false
        if not scene.aimed then scene:SetAlpha(0) end
        local ok, result = pcall(opts.load, actor)
        if not ok or result == false then
            if opts.onFailed then opts.onFailed(scene) end
            return
        end
        -- A model already cached may load without calling OnModelLoaded.
        C_Timer.After(0.5, function()
            if scene.loaded or not scene:IsVisible() then return end
            local okLoaded, isLoaded = pcall(actor.IsLoaded, actor)
            if okLoaded and isLoaded then OnLoaded() end
        end)
        -- Never invisible for good: shown at the guess if it never says it loaded.
        C_Timer.After(2, function()
            if not scene.aimed then scene:SetAlpha(1) end
        end)
    end

    -- Loads the model again (hiding weapons, another friend). A new model
    -- is measured and aimed afresh.
    function scene.Reload(fresh)
        if fresh then scene.aimed = false end
        if not scene:IsVisible() then return end
        pcall(actor.ClearModel, actor)
        Load()
    end

    pcall(actor.SetScript, actor, "OnModelLoaded", OnLoaded)
    scene:SetScript("OnShow", Load)
    scene:SetScript("OnHide", function()
        scene.loaded = false
        pcall(actor.ClearModel, actor)
    end)
    return scene, Load
end

-- The Mini Me. opts as Stage, plus hideWeapons: true, or a function asked
-- at every load (the buddy's option).
function MiniMe.Create(parent, opts)
    opts = opts or {}
    opts.load = function(actor)
        local hideWeapons = opts.hideWeapons
        if type(hideWeapons) == "function" then hideWeapons = hideWeapons() end
        return actor:SetModelByUnit("player", true, true, hideWeapons and true or false, true, false, GNOME_RACE_ID)
    end
    local scene, Load = Stage(parent, opts)
    if not scene then return nil end

    -- The Mini Me wears what the player wears. PLAYER_EQUIPMENT_CHANGED comes
    -- before the player's own model has changed (reloading then dressed the
    -- Mini Me in the old gear), and a swap of several pieces sends one per
    -- slot. So it waits until the events stop, UNIT_MODEL_CHANGED usually
    -- last, and redresses once. Clearing first makes the actor read the
    -- gear again instead of keeping the model it has.
    local redressTimer
    local function Redress()
        if redressTimer then redressTimer:Cancel() end
        redressTimer = C_Timer.NewTimer(REDRESS_DELAY, function()
            redressTimer = nil
            if not scene:IsVisible() then return end
            pcall(scene.actor.ClearModel, scene.actor)
            Load()
        end)
    end
    scene:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    pcall(scene.RegisterUnitEvent, scene, "UNIT_MODEL_CHANGED", "player")
    scene:SetScript("OnEvent", Redress)
    if scene:IsVisible() then Load() end
    return scene
end

-- A friend, from a creature display ID. opts as Stage, plus display: a
-- function returning the display to load (asked at every load, so the
-- same stage can show one friend, then another).
function MiniMe.CreateNpc(parent, opts)
    opts = opts or {}
    opts.load = function(actor)
        local display = opts.display and opts.display()
        if type(display) ~= "number" then return false end
        return actor:SetModelByCreatureDisplayID(display)
    end
    local scene = Stage(parent, opts)
    return scene
end
