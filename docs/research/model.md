# BuddyDex 3D model pane: showing an NPC from its npcID (and displayID when known) in the Camelot client, build 1.60.1.70338

## Summary

How Blizzard shows creatures in this client:
- **Mount Journal** (Mainline file; [Family] resolves to Mainline for Camelot) and **Pet Journal** (Camelot loads Classic\Blizzard_PetCollection): both use a ModelScene that inherits WrappedAndUnwrappedModelScene. Each calls TransitionToModelSceneID with a scene ID that comes from data for that specific mount or pet species, takes the actor tagged "unwrapped" and calls SetModelByCreatureDisplayID on it.
- **Encounter Journal**: uses a ModelSceneMixinTemplate scene, calls SetFromModelSceneID with each creature's uiModelSceneID, and loads the model on the actor tagged "creature". Its toc limits it to "standard, classic", and Camelot is listed separately from both in other tocs, so it very likely does not load in this client. Treat it as reference only.
- **Closest match to the BuddyDex pane**: the Camelot Stable UI. It is a PanningModelSceneMixinTemplate scene with a ModelSceneControlFrameTemplate on top. It transitions to the pet's uiModelSceneID (default 718), uses the actor tagged "pet", hides the actor, sets a model-loaded callback to show it again, then calls SetModelByCreatureDisplayID.
- **Other generic scene IDs in code this client loads**: 1156 (hunter pet on the character sheet, actor "pet") and 309 (quest NPC portrait, actors "mount" and "rider").
- **PlayerModel examples**: the Tutorial frame calls SetCreature(npcID), the Guild News boss popup calls SetDisplayInfo, and the TalkingHead frame calls SetDisplayInfo and adjusts its camera in OnModelLoaded. These just call SetPortraitZoom(0.6) and rely on the engine's built-in camera framing.

Always-loaded templates you can use (no load-on-demand dependency):
- **Blizzard_SharedXML**: ModelSceneMixinTemplate, PanningModelSceneMixinTemplate, NoZoomModelSceneMixinTemplate, ModelSceneControlFrameTemplate, the WrappedAndUnwrappedModelScene templates, RotateOrbitCameraLeft/RightButtonTemplate, ModelSceneActorTemplate, OrbitCameraMixin and CameraRegistry.
- **Mainline family files in Blizzard_SharedXML**: ModelTemplate, ModelWithZoomTemplate, ModelWithControlsTemplate, ModelFrameMixin, Model_ApplyUICamera and the global ModelPanningFrame.

How sizing works:
- **OrbitCamera** never fits the camera to the model. Its zoom distances come from the scene's camera record.
- **Size fitting in a ModelScene** comes from the actor's normalizeScaleAggressiveness. That is Lua in SharedXML: it measures the model's bounding box and rescales it toward a human-male-sized box.
- **PlayerModel** relies on the engine's own camera, which frames the whole model.
- **HasAnimation exists only on PlayerModel-type frames.** ModelScene actors have SetAnimation but no HasAnimation.

Recommendation, in short: use a PanningModelSceneMixinTemplate scene with a ModelSceneControlFrameTemplate for the visible pane, built on a scene ID you check at runtime (718, then 1156, then 309), and force normalized scaling. A small, invisible but shown PlayerModel turns an npcID into a displayID with SetCreature, then GetDisplayInfo inside OnModelLoaded, and answers HasAnimation. Cache both results per npcID in SavedVariables.

## Recommended approach

Use a ModelScene for what the player sees, and a small invisible PlayerModel to turn an npcID into a displayID and answer HasAnimation. This combination is needed because:
- Only PlayerModel can take an npcID (SetCreature) and answer HasAnimation.
- ModelScene gives the Mount Journal / Stable look: an orbit camera, the standard control frame, right-drag panning, and predictable size fitting through actor normalization.

Everything below comes from always-loaded Blizzard_SharedXML. Nothing depends on a load-on-demand addon.

```lua
local _, ns = ...
local Dex = {}; ns.DexModel = Dex

-- Scene IDs that code loaded by this client references. Each one is checked at runtime.
local SCENES = {
  { id = 718,  tag = "pet"   }, -- C_StableInfo default (StableInfoDocumentation.lua:231), Camelot Stable UI
  { id = 1156, tag = "pet"   }, -- DEFAULT_PET_MODEL_SCENE_ID (Camelot/PaperDollFrame.lua:68)
  { id = 309,  tag = "mount" }, -- QUEST_FRAME_MODEL_SCENE_ID; "mount" holds the NPC when there is no mount
}
local NORMALIZE = 1.0 -- 0 = true size, 1 = every creature fitted to a human-sized box (ModelSceneActorMixin:85-108)
ns.DEX_ANIMS = { 0, 6 } -- 0 = Stand, 6 = Dead (used by Blizzard); add more IDs, each gated by HasAnimation

local function FindScene()
  for _, s in ipairs(SCENES) do
    local sceneType, cams, actors = C_ModelInfo.GetModelSceneInfoByID(s.id)
    if sceneType and cams and #cams > 0 and actors and #actors > 0 then return s.id, s.tag end
  end
end

function Dex:Create(pane) -- pane = the right-hand detail frame
  local scene = CreateFrame("ModelScene", nil, pane, "PanningModelSceneMixinTemplate")
  scene:SetPoint("TOPLEFT"); scene:SetPoint("BOTTOMRIGHT", 0, 60)
  scene:EnableMouse(true); scene:EnableMouseWheel(true)
  local shadow = CreateFrame("Frame", nil, scene, "ShadowOverlayTemplate"); shadow:SetAllPoints()
  -- Must be stored as scene.ControlFrame: ModelSceneMixin:OnEnter/OnLeave shows and hides self.ControlFrame
  scene.ControlFrame = CreateFrame("Frame", nil, scene, "ModelSceneControlFrameTemplate")
  scene.ControlFrame:SetPoint("BOTTOM", 0, 10)
  scene.ControlFrame:SetFrameLevel(scene:GetFrameLevel() + 20)
  scene.ControlFrame:SetModelScene(scene)
  scene:SetResetCallback(function() Dex:ApplyActorSettings() end)
  scene:HookScript("OnHide", function() Dex:Release() end)
  self.scene, self.sceneID, self.tag = scene, FindScene()

  -- Resolver: kept "shown" but invisible. Verify in-game that OnModelLoaded also fires while hidden before relying on that.
  local probe = CreateFrame("PlayerModel", nil, pane)
  probe:SetSize(1, 1); probe:SetPoint("BOTTOMLEFT"); probe:SetAlpha(0); probe:SetKeepModelOnHide(true)
  probe:SetScript("OnModelLoaded", function(m)
    local job = Dex.job; if not job then return end
    local displayID = m:GetDisplayInfo(); if not displayID or displayID == 0 then return end
    Dex.job = nil; job.timer:Cancel()
    local anims = {}
    for _, a in ipairs(job.anims) do anims[a] = m:HasAnimation(a) end
    m:ClearModel()
    job.cb(displayID, anims)
  end)
  self.probe = probe
end

function Dex:Release() -- frees models when the Dex closes or changes tab
  if self.job then self.job.timer:Cancel(); self.job = nil end
  self.probe:ClearModel(); self.scene:ClearScene()
end

function Dex:GetActor()
  local a = self.scene:GetActorByTag(self.tag)
  if not a then for x in self.scene:EnumerateActiveActors() do a = x; break end end
  return a
end

function Dex:EnsureScene()
  if not self.sceneID then return false end
  if self.scene:GetModelSceneID() ~= self.sceneID then
    -- force=true, otherwise Reset() does nothing; DISCARD makes Reset really reset the camera
    self.scene:TransitionToModelSceneID(self.sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
    local cam = self.scene:GetActiveCamera()
    if cam and cam.SetAlignLightToOrbitDelta then cam:SetAlignLightToOrbitDelta(true) end -- light follows rotation
  end
  return self:GetActor() ~= nil
end

function Dex:ApplyActorSettings() -- also runs after each transition or reset, which re-apply the DB values
  local a = self:GetActor(); if not a then return end
  if a:GetNormalizedScaleAggressiveness() == 0 then a:SetNormalizedScaleAggressiveness(NORMALIZE) end
  a:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
  a:SetAnimation(self.animID or 0, 0, 1)
end

function Dex:ShowDisplayID(displayID)
  if not self:EnsureScene() then return false end
  local a = self:GetActor()
  local token = (self.token or 0) + 1; self.token = token
  a:Hide() -- Mount Journal / Stable pattern: no flash of the previous model
  a:SetOnModelLoadedCallback(function(actor)
    if self.token ~= token then return end -- a newer selection won
    self:ApplyActorSettings(); actor:Show()
  end)
  if not a:SetModelByCreatureDisplayID(displayID) then a:ClearModel(); return false end
  C_Timer.After(1, function() -- safety net if OnModelLoaded does not fire again
    if self.token == token and not a:IsShown() and a:IsLoaded() then self:ApplyActorSettings(); a:Show() end
  end)
  return true
end

function Dex:ResolveNPC(npcID, cb)
  if issecretvalue(npcID) then return cb(nil) end
  if self.job then self.job.timer:Cancel() end
  local job = { npcID = npcID, anims = ns.DEX_ANIMS, cb = cb }
  job.timer = C_Timer.NewTimer(5, function() -- unknown, invalid or never-answered creature
    if self.job == job then self.job = nil; self.probe:ClearModel(); cb(nil) end
  end)
  self.job = job
  self.probe:SetCreature(npcID) -- never SetUnit / SetModelByUnit for world units
end

-- rec = roster row { npcID=, displayID=? }; cache = BuddyDexDB.dexModels[npcID] = {displayID=, anims={}}
function Dex:Select(rec)
  if self.selTimer then self.selTimer:Cancel() end
  self.selTimer = C_Timer.NewTimer(0.1, function() -- debounce fast list scrolling
    self.selected, self.animID = rec.npcID, 0
    local c = BuddyDexDB.dexModels[rec.npcID]
    local known = rec.displayID or (c and c.displayID)
    if known then self:ShowDisplayID(known) end
    if not (c and c.anims) then
      self:ResolveNPC(rec.npcID, function(displayID, anims)
        if not displayID then if not known then self:ShowMissing() end return end
        BuddyDexDB.dexModels[rec.npcID] = { displayID = displayID, anims = anims }
        if self.selected == rec.npcID and not known then self:ShowDisplayID(displayID) end
      end)
    end
  end)
end

function Dex:PlayAnimation(animID) -- for the action buttons under the model
  local c = BuddyDexDB.dexModels[self.selected]
  if c and c.anims and c.anims[animID] == false then return false end -- HasAnimation said no
  self.animID = animID
  local a = self:GetActor(); if a then a:SetAnimation(animID, 0, 1) end
  return true
end

function Dex:ShowMissing() end -- stub: show your "no model" placeholder here
```

List row icons: once a displayID is cached, call `SetPortraitTextureFromCreatureDisplayID(row.Icon, displayID)` instead of creating a model per row.

Fallback when FindScene() returns nil: make the probe the visible model.
1. Anchor it to fill the pane, alpha 1.
2. Call `SetCreature(npcID, displayID or 0)`.
3. In OnModelLoaded, call `RefreshCamera()`, then `SetPortraitZoom(0)` and `SetRotation(0)`.
4. Zoom with the mouse wheel via `Model_OnMouseWheel(self, delta)` (SetPortraitZoom 0..0.7).
5. Rotate with left-drag by setting OnMouseDown/OnMouseUp/OnUpdate to `ModelFrameMixin.OnMouseDown/OnMouseUp/OnUpdate`. Write your own right-drag pan, because the built-in one uses the player's race.

One-time check to run in-game: `/dump C_ModelInfo.GetModelSceneActorInfoByID(select(3, C_ModelInfo.GetModelSceneInfoByID(718))[1])`. It shows the scriptTag and whether the scene already normalizes size. Adjust NORMALIZE, or the camera through `scene:GetActiveCamera():SetZoomDistance/SetTarget`, to suit.

## Pitfalls

- Unit models (crash): never call Model:SetUnit or actor:SetModelByUnit from nameplate or any world-unit event. In this exported code Blizzard only calls SetUnit for 'player' (and SetModelByUnitCreatureDisplayID for 'pet'), and only when the frame is shown and IsUnitModelReadyForUI(unit) is true (TransmogShared.lua:837). SetUnit and SetModelByUnit also require a declassified unit identity. For BuddyDex, use SetCreature(npcID) and SetModelByCreatureDisplayID only.
- Secret values: SetCreature, SetDisplayInfo and SetModelByCreatureDisplayID are marked SecretArguments='AllowedWhenUntainted'. Addon code is tainted, so it cannot pass a secret npcID, for example one parsed from a combat-time GUID. Check with issecretvalue or canaccessvalue first, or defer until after combat.
- No HasAnimation on ModelScene actors: the actor API has SetAnimation but no HasAnimation. Ask a PlayerModel, inside OnModelLoaded (Blizzard's ArtifactPerks pattern), and cache the answer.
- GetDisplayInfo before load: the value is only reliable after OnModelLoaded. Uncached creatures need a reply from the server first. Bad or nonexistent creature IDs never load, so always use a timeout (the code uses 5 s) and show a 'no model' placeholder. This timeout behavior is inferred; Lua cannot prove it.
- Overlapping probes: if you call SetCreature again before the previous OnModelLoaded fires, a late event can attach the new creature's display ID to the wrong npc. Run only one probe job at a time (cancel and replace, or a queue) and debounce list selection.
- Multi-display NPCs: SetCreature picks one of the creature's display IDs. If the roster recorded a specific display ID, prefer it, or pass it as SetCreature's second argument.
- Missing scene IDs: TransitionToModelSceneID and SetFromModelSceneID silently do nothing for a scene ID this client's data lacks (ModelSceneMixin.lua:31-33,72-75). Check with C_ModelInfo.GetModelSceneInfoByID first and keep the PlayerModel fallback. Actor tags come from the data: 718/1156 use 'pet', 309 uses 'mount'/'rider', Mount and Pet Journal scenes use 'unwrapped', EJ uses 'creature'. Fall back to EnumerateActiveActors().
- Per-item scene IDs: Mount Journal and Pet Journal scene IDs are per mount and per species (C_MountJournal.GetMountInfoExtraByID, C_PetJournal.GetPetModelSceneInfoBySpeciesID), and EJ's come from EJ_GetCreatureInfo. None of them works for an arbitrary npcID. No generic 'creature' constant exists in C_ModelInfo or in the docs.
- Reset button: ModelSceneMixin:Reset re-transitions with the stored forceEvenIfSame and modification type. Enter the scene with forceEvenIfSame=true and CAMERA_MODIFICATION_TYPE_DISCARD, or Reset does nothing. Every transition re-applies the DB actor values (animation 0, normalizeScaleAggressiveness), so re-apply your settings in SetResetCallback.
- Normalization limits: it only takes effect once the actor IsLoaded and GetActiveBoundingBox returns data (invisible models return nil, giving scale 1). Models with huge bounding boxes from particles or long tails can still look small; long creatures are fitted by depth.
- Hand-made cameras: do not create an OrbitCamera with CameraRegistry and AddCamera without calling ApplyFromModelSceneCameraInfo. UpdateLight reads self.modelSceneCameraInfo.flags every frame and raises an error. If you build your own camera record, include target and zoomedTargetOffset (Vector3D), the zoom values, yaw/pitch/roll, the zoomed offsets and flags.
- ActorInfo nil: ModelSceneMixin:CreateOrTransitionActorFromScene reads actorInfo.scriptTag without a nil check. A scene that lists a missing actor ID raises a Lua error, so wrap your first transition in pcall if you try unvalidated IDs.
- ModelSceneControlFrameTemplate: it starts hidden at alpha 0.5. It only appears on hover if stored as scene.ControlFrame, and you must call SetModelScene(scene). Without it, zoom clicks hit an assertsafe with a 'fale' typo (ModelSceneControlFrame.lua:196). Zoom buttons are hidden when the camera's min and max zoom are equal.
- Panning: PanningModelSceneMixinTemplate only enables right-drag pan inside TransitionToModelSceneID, not SetFromModelSceneID.
- WrappedAndUnwrappedModelScene is meant for gift-wrap fanfare and adds a 'wrapped' present actor (display 71933). Use PanningModelSceneMixinTemplate or ModelSceneMixinTemplate for BuddyDex.
- ModelWithControlsTemplate: it uses $parent-named children and relativeTo anchors, so give the PlayerModel a unique global name. Its right-drag pan uses bounds for the player's race and sex (ModelFrameMixin.lua:158-171), so pan feels wrong for creatures and errors if the player's race key is missing. It also uses the older UI-ModelControlPanel art instead of the journal-style square buttons.
- Load-on-demand and game-only code: Blizzard_Collections (Mount and Pet Journal) is load-on-demand. Blizzard_EncounterJournal is load-on-demand and its toc excludes Camelot ('standard, classic'). StablePetModelSceneMixin lives in Blizzard_StableUI ('standard, camelot', game-only). CharacterModelSceneMixin auto-equips the cursor item on click. Copy the patterns rather than these mixins.
- Memory and performance: reuse one scene, one actor and one probe. Never create PlayerModels per list row; use SetPortraitTextureFromCreatureDisplayID for row icons. Debounce selection about 0.1 s. Call scene:ClearScene() and probe:ClearModel() when the Dex closes or leaves the Dex tab, because ModelScene and actor OnUpdate run every frame while shown. Pool release calls ClearModel (Pools.lua:562-565).
- Camera refresh: if you go the PlayerModel route, call RefreshCamera() in OnModelLoaded and on UI_SCALE_CHANGED and DISPLAY_SIZE_CHANGED (ModelFrameMixin:OnLoad/OnEvent, TalkingHead). Otherwise framing breaks after resizing the window.
- SetModelByCreatureDisplayID's second argument is useActivePlayerCustomizations, not a force flag. EJ passes forceUpdate there by mistake. Pass nothing or false for NPCs.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **Camelot belongs to the 'mainline' load family and is listed separately from 'standard' and 'classic'. Blizzard_Collections is load-on-demand: it loads the Mainline Mount Journal through [Family] and the Classic Pet Journal through an explicit camelot entry.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3,25-30`
  ```
  ## LoadOnDemand: 1 ... [Family]\Blizzard_MountCollection.lua ... Classic\Blizzard_PetCollection.lua [AllowLoadGameType wrath, cata, camelot] / Shared\Blizzard_PetCollection.lua [AllowLoadGameType mists, mainline] [ExcludeLoadGameType camelot]
  ```
- **The Encounter Journal addon is load-on-demand and restricted to 'standard, classic'. Camelot is not one of these (other tocs list e.g. 'standard, camelot' and 'classic, camelot'), so the EJ UI very likely does not load in this client.**  
  `Blizzard_EncounterJournal/Blizzard_EncounterJournal.toc:2,7`
  ```
  ## LoadOnDemand: 1
  ## AllowLoadGameType: standard, classic
  ```
- **The Mount Journal's model pane is a ModelScene that inherits WrappedAndUnwrappedModelScene, with a ModelSceneControlFrameTemplate child under parentKey 'ControlFrame'.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:509,515`
  ```
  <ModelScene parentKey="ModelScene" useParentLevel="true" inherits="WrappedAndUnwrappedModelScene"> ... <Frame parentKey="ControlFrame" frameLevel="500" inherits="ModelSceneControlFrameTemplate" >
  ```
- **Mount Journal flow: it gets a scene ID per mount, transitions with IMMEDIATE/DISCARD, takes the 'unwrapped' actor, hides it, sets a model-loaded callback that shows it, then calls SetModelByCreatureDisplayID.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:676-678,686,715,720-724,732`
  ```
  MountJournal.MountDisplay.ModelScene:TransitionToModelSceneID(modelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, forceSceneChange);
  local mountActor = ...:GetActorByTag("unwrapped");
  mountActor:Hide();
  mountActor:SetOnModelLoadedCallback(GenerateClosure(MountJournal_OnModelLoaded, mountActor));
  mountActor:SetModelByCreatureDisplayID(creatureDisplayID, true);
  ```
- **The Mount Journal wires the control frame to its scene and sets a reset callback that re-applies the scene with force.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:158-159,416-419`
  ```
  MountJournal.MountDisplay.ModelScene:SetResetCallback(MountJournal_ModelScene_OnReset);
  MountJournal.MountDisplay.ModelScene.ControlFrame:SetModelScene(MountJournal.MountDisplay.ModelScene);
  ```
- **The Camelot Pet Journal gets a scene ID per species and transitions with MAINTAIN, so user zoom and rotation carry over between pets. It uses the 'unwrapped' actor and animation 0 for stand or 6 for dead.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:643-650,657-663`
  ```
  local cardModelSceneID, loadoutModelSceneID = C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID);
  self.modelScene:TransitionToModelSceneID(cardModelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, forceSceneChange);
  battlePetActor:SetModelByCreatureDisplayID(displayID);
  battlePetActor:SetAnimation(6, -1) / SetAnimation(0, -1)
  ```
- **The Camelot Pet Journal scene uses SharedXML rotate-button templates instead of the control frame, plus ViewInsets.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:290,296-297,306`
  ```
  <ModelScene parentKey="modelScene" useParentLevel="true" inherits="WrappedAndUnwrappedModelScene"> <Button parentKey="RotateLeftButton" inherits="RotateOrbitCameraLeftButtonTemplate" /> ... <ViewInsets left="0" right="0" top="300" bottom="-50"/>
  ```
- **The Encounter Journal's boss model calls SetFromModelSceneID with the creature's uiModelSceneID (no transition) and loads the display ID on the actor tagged 'creature'. Its second argument is forceUpdate, but that parameter is actually useActivePlayerCustomizations.**  
  `Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua:1413,1455-1468; Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.xml:1969`
  ```
  id, name, description, displayInfo, iconImage, uiModelSceneID = EJ_GetCreatureInfo(i);
  modelScene:SetFromModelSceneID(self.uiModelSceneID, forceUpdate);
  local creature = modelScene:GetActorByTag("creature");
  creature:SetModelByCreatureDisplayID(self.displayInfo, forceUpdate);
  <ModelScene name="$parentModelFrame" parentKey="model" inherits="ModelSceneMixinTemplate">
  ```
- **The Camelot Stable UI, the closest analogue to a creature viewer, uses PanningModelSceneMixinTemplate plus ModelSceneControlFrameTemplate.**  
  `Blizzard_StableUI/Camelot/Blizzard_StableUI.xml:141,166; Blizzard_StableUI/Blizzard_StableUI.toc:2`
  ```
  <ModelScene parentKey="modelScene" inherits="PanningModelSceneMixinTemplate"  mixin="StablePetModelSceneMixin"> ... <Frame parentKey="ControlFrame" inherits="ModelSceneControlFrameTemplate">  /  ## AllowLoadGameType: standard, camelot
  ```
- **The Stable UI's model code uses the actor tag 'pet', forces the transition with DISCARD, and hides the actor until its model loads.**  
  `Blizzard_StableUI/Shared/Blizzard_StableUI_Shared.lua:3,27-30,51-68`
  ```
  local PET_STABLE_DEFAULT_ACTOR_TAG = "pet";
  self:TransitionToModelSceneID(pet.uiModelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, forceSceneChange);
  actor:Hide();
  actor:SetOnModelLoadedCallback(GenerateClosure(self.OnModelLoaded, actor));
  actor:SetModelByCreatureDisplayID(pet.displayID);
  ```
- **In this build's API data, the stable pet's uiModelSceneID defaults to 718, which makes 718 a generic hunter-pet creature scene.**  
  `Blizzard_APIDocumentationGenerated/StableInfoDocumentation.lua:231`
  ```
  { Name = "uiModelSceneID", Type = "number", Nilable = false, Default = 718 },
  ```
- **The Camelot character sheet shows the hunter pet with DEFAULT_PET_MODEL_SCENE_ID 1156 and actor tag 'pet', using the same hide-until-loaded pattern.**  
  `Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua:68,3426-3444`
  ```
  DEFAULT_PET_MODEL_SCENE_ID = 1156;
  ... CharacterModelScene:TransitionToModelSceneID(modelScene, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, forceSceneChange);
  local actor = CharacterModelScene:GetActorByTag("pet");
  ```
- **The quest giver portrait (the Mainline QuestFrame, loaded for Camelot) shows any NPC by display ID through scene 309. Its actors are tagged 'mount' and 'rider', and 'mount' holds the NPC when there is no mount.**  
  `Blizzard_UIPanels_Game/Mainline/QuestFrame.lua:7,506-507,531-544; Blizzard_UIPanels_Game/Blizzard_UIPanels_Game.toc:88`
  ```
  local QUEST_FRAME_MODEL_SCENE_ID = 309;
  QuestModelScene:ClearScene();
  QuestModelScene:TransitionToModelSceneID(modelSceneID or QUEST_FRAME_MODEL_SCENE_ID, ...);
  riderTag = mountTag; ... rider:SetModelByCreatureDisplayID(portraitDisplayID);
  ```
- **Blizzard_SharedXML is always loaded (no LoadOnDemand flag, AllowLoad: Both) and provides all the ModelScene templates, cameras and mixins.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:2,149-159`
  ```
  ## AllowLoad: Both ... ModelSceneControlFrame.xml / ModelSceneTemplates.xml / Shared\ModelSceneCameras\OrbitCameraMixin.lua / ModelSceneMixin.xml / ModelSceneActorMixin.xml
  ```
- **The always-loaded ModelScene templates are NonInteractableModelSceneMixinTemplate, ModelSceneMixinTemplate (mouse and wheel), NoZoomModelSceneMixinTemplate, PanningModelSceneMixinTemplate, NoCameraControlModelSceneMixinTemplate and ModelSceneDropShadowTemplate.**  
  `Blizzard_SharedXML/ModelSceneMixin.xml:3-27`
  ```
  <ModelScene name="PanningModelSceneMixinTemplate" inherits="ModelSceneMixinTemplate" mixin="PanningModelSceneMixin" virtual="true" />
  ```
- **WrappedModelSceneTemplate, WrappedAndUnwrappedModelScene (with its gift-box 'wrapped' actor and fanfare), RotateOrbitCameraLeftButtonTemplate and RotateOrbitCameraRightButtonTemplate are always loaded.**  
  `Blizzard_SharedXML/ModelSceneTemplates.xml:15,30,45,87; Blizzard_SharedXML/ModelSceneTemplates.lua:27,59-61`
  ```
  <ModelScene name="WrappedAndUnwrappedModelScene" inherits="WrappedModelSceneTemplate" mixin="WrappedAndUnwrappedModelSceneMixin" virtual="true">
  WRAPPED_PRESENT_CREATURE_DISPLAY_ID = 71933;
  ```
- **ModelSceneControlFrameTemplate starts hidden at alpha 0.5. It offers zoom, rotate and reset buttons, and it needs SetModelScene(scene) before use.**  
  `Blizzard_SharedXML/ModelSceneControlFrame.xml:38-61; Blizzard_SharedXML/ModelSceneControlFrame.lua:67-75`
  ```
  <Frame name="ModelSceneControlFrameTemplate" virtual="true" mixin="ModelSceneControlFrameMixin" alpha="0.5" hidden="true">
  function ModelSceneControlFrameMixin:SetModelScene(modelScene)
  ```
- **The control frame hides its zoom buttons when the active camera's minimum and maximum zoom are equal. The zoom button only forwards the click to the scene's OnMouseWheel.**  
  `Blizzard_SharedXML/ModelSceneControlFrame.lua:96-103,192-199`
  ```
  self.canZoom = camera ~= nil and camera:GetZoomAvailable();
  ... self.modelScene:OnMouseWheel(self.zoomAmount);
  ```
- **The scene only shows and hides the control frame on hover when it is stored at self.ControlFrame.**  
  `Blizzard_SharedXML/ModelSceneMixin.lua:347-359`
  ```
  function ModelSceneMixin:OnEnter(button)
  	if self.ControlFrame then
  		self.ControlFrame:Show();
  ```
- **PanningModelSceneMixin turns on right-drag panning only inside TransitionToModelSceneID, not SetFromModelSceneID.**  
  `Blizzard_SharedXML/ModelSceneMixin.lua:537-546`
  ```
  camera:SetRightMouseButtonXMode(ORBIT_CAMERA_MOUSE_PAN_HORIZONTAL, true);
  camera:SetRightMouseButtonYMode(ORBIT_CAMERA_MOUSE_PAN_VERTICAL, true);
  ```
- **TransitionToModelSceneID silently does nothing when the scene ID has no cameras or actors in this client's data, and the scene keeps its previous state.**  
  `Blizzard_SharedXML/ModelSceneMixin.lua:71-75`
  ```
  local modelSceneType, cameraIDs, actorIDs = C_ModelInfo.GetModelSceneInfoByID(modelSceneID);
  if not modelSceneType or #cameraIDs == 0 or #actorIDs == 0 then
  	return;
  end
  ```
- **Reset() re-transitions with the stored forceEvenIfSame. If the scene was first entered without force, the Reset button does nothing.**  
  `Blizzard_SharedXML/ModelSceneMixin.lua:60-67,77`
  ```
  self:TransitionToModelSceneID(self.modelSceneID, self.cameraTransitionType, self.cameraModificationType, self.forceEvenIfSame);
  ...
  if self.modelSceneID ~= modelSceneID or forceEvenIfSame then
  ```
- **OrbitCamera does not fit itself to the model. Its distances come from the scene's camera record, with hard-coded fallbacks of 6-10 (default 8) when it is added to a scene. Left-drag rotates (yaw) and the wheel zooms.**  
  `Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua:33-58,430-466`
  ```
  self:SetMinZoomDistance(transitionalCameraInfo.minZoomDistance); ...
  self:SetMinZoomDistance(6); self:SetMaxZoomDistance(10); self:SetZoomDistance(8);
  self:SetLeftMouseButtonXMode(ORBIT_CAMERA_MOUSE_MODE_YAW_ROTATION, true);
  ```
- **In a ModelScene, fitting creatures of any size comes from actor scale normalization: once the model loads, its bounding box is scaled toward a human-male box. The DB value is re-applied on every transition.**  
  `Blizzard_SharedXML/ModelSceneActorMixin.lua:35,85-108,120-138`
  ```
  self:SetNormalizedScaleAggressiveness(actorInfo.normalizeScaleAggressiveness or 0.0);
  MODEL_SCENE_ACTOR_DIMENSIONS_FOR_NORMALIZATION = { width = .9984, depth = 1.121, height = 2.118 };
  return 1 / Lerp(1.0, maxScale, normalizedScaleAggressiveness);
  ```
- **normalizeScaleAggressiveness is a nilable field of the actor record, so you can read it at runtime to see whether a scene already normalizes.**  
  `Blizzard_APIDocumentationGenerated/UIModelInfoDocumentation.lua:105-121,152-167`
  ```
  { Name = "normalizeScaleAggressiveness", Type = "number", Nilable = true },
  ```
- **An actor's model-loaded callback receives the actor itself. Releasing an actor through the scene pool clears its model.**  
  `Blizzard_SharedXML/ModelSceneActorMixin.lua:55-57,120-126; Blizzard_SharedXMLBase/Pools.lua:562-565`
  ```
  self.onModelLoadedCallback(self);
  function ActorPool_HideAndClearModel(actorPool, actor)
  	actor:ClearModel();
  	actor:Hide();
  ```
- **Actor API: SetModelByCreatureDisplayID(displayID, useActivePlayerCustomizations=false) returns success, SetAnimation(anim, variation, speed, offset) and IsLoaded exist, and there is no HasAnimation on ModelScene actors.**  
  `Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua:252,341-352,399-413`
  ```
  Name = "SetModelByCreatureDisplayID" ... { Name = "useActivePlayerCustomizations", Type = "bool", Nilable = false, Default = false }, Returns success
  ```
- **PlayerModel and DressUpModel (CharacterModelBase) have SetCreature(creatureID, displayID=0), GetDisplayInfo, HasAnimation, SetAnimation, SetPortraitZoom, SetCamDistanceScale and SetKeepModelOnHide. SetUnit requires a declassified unit identity (a Midnight-style restriction).**  
  `Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua:43,82,143,153-161,209,219,240-256`
  ```
  Name = "SetCreature" ... { Name = "creatureID" }, { Name = "displayID", Type = "number", Nilable = false, Default = 0 }
  Name = "SetUnit", RequiresDeclassifiedUnitIdentity = true,
  ```
- **Blizzard's own pattern is to call HasAnimation inside a PlayerModel's OnModelLoaded and then SetAnimation. The same handler shows the table form of SetLight.**  
  `Blizzard_ArtifactUI/Blizzard_ArtifactPerks.lua:140-154`
  ```
  function ArtifactsModelTemplate_OnModelLoaded(self)
  	local animationSequence = self:HasAnimation(CUSTOM_ANIMATION_SEQUENCE) and CUSTOM_ANIMATION_SEQUENCE or 0;
  	self:SetLight(enabled, lightValues); ... self:SetAnimation(animationSequence, 0);
  ```
- **An always-loaded Blizzard UI calls PlayerModel:SetCreature with a creature ID (npcID), with no camera adjustment beyond SetPortraitZoom(0.6).**  
  `Blizzard_FrameXML/Mainline/TutorialFrame.xml:245,252; Blizzard_FrameXML/Mainline/TutorialFrame.lua:84,470; Blizzard_FrameXML/Blizzard_FrameXML.toc:32-33`
  ```
  <PlayerModel name="TutorialNPCModel" hidden="true"> ... self:SetPortraitZoom(0.6);
  TutorialNPCModel:SetCreature(displayNPC);  -- displayNPC = 197
  ```
- **The Guild News boss popup shows any boss display ID in a PlayerModel using only Model_OnLoad, SetPortraitZoom(0.6) and SetRotation(0). This shows Blizzard relies on the engine's own framing.**  
  `Blizzard_Communities/GuildNews.xml:87,240-245; Blizzard_Communities/GuildNews.lua:198`
  ```
  Model_OnLoad(self);
  self:SetPortraitZoom(0.6);
  ...
  bossModel:SetDisplayInfo(self.newsInfo.data[2]);
  ```
- **The TalkingHead PlayerModel reapplies its camera inside OnModelLoaded and on UI scale or display size changes.**  
  `Blizzard_FrameXML/TalkingHeadUI.lua:172-173,255-272; Blizzard_FrameXML/TalkingHeadUI.xml:130`
  ```
  function TalkingHeadFrameModelMixin:OnModelLoaded()
  	self:RefreshCamera();
  	if self.uiCameraID then Model_ApplyUICamera(self, self.uiCameraID); end
  ```
- **The PlayerModel templates (ModelTemplate, ModelWithZoomTemplate, ModelWithControlsTemplate) are always loaded for Camelot because they are Mainline-family files in SharedXML.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:225-229; Blizzard_SharedXML/ModelFrameTemplates.xml:44,52,59,65`
  ```
  <PlayerModel name="ModelWithControlsTemplate"  mixin="ModelFrameMixin" virtual="true">
  ```
- **ModelWithControlsTemplate builds children from $parent-relative names and anchors them with relativeTo, so the PlayerModel needs a unique global name.**  
  `Blizzard_SharedXML/ModelFrameTemplates.xml:67,100,109-111`
  ```
  <Frame name="$parentControlFrame" parentKey="controlFrame" ...>
  <Anchor point="LEFT" relativeTo="$parentZoomInButton" relativePoint="RIGHT"/>
  ```
- **ModelFrameMixin's right-drag panning uses bounds tuned to the PLAYER's race and sex, which is wrong for creatures. Its zoom is SetPortraitZoom, clamped to 0..0.7.**  
  `Blizzard_SharedXML/Mainline/ModelFrameMixin.lua:5-7,64-77,158-171,273-282; Blizzard_SharedXML/Mainline/ModelFrames.lua:2-4`
  ```
  settings = ModelSettings[playerRaceSex];
  local transformationRatio = settings.panValue * 2 ^ (zoom * 2) * scale / modelScale;
  MODELFRAME_MAX_ZOOM = 0.7;
  ```
- **Blizzard's own hidden probe model is a DressUpModel that is hidden and set to keep its model while hidden.**  
  `Blizzard_TransmogShared/Blizzard_TransmogShared.lua:101-103`
  ```
  TransmogUtil.HiddenModelFrame = CreateFrame("DressUpModel", nil, UIParent);
  TransmogUtil.HiddenModelFrame:Hide();
  TransmogUtil.HiddenModelFrame:SetKeepModelOnHide(true);
  ```
- **Blizzard only loads unit models when the frame is shown and IsUnitModelReadyForUI(unit) returns true. In this exported code it only calls SetUnit for 'player' and SetModelByUnitCreatureDisplayID for 'pet', never for nameplate units.**  
  `Blizzard_TransmogShared/Blizzard_TransmogShared.lua:837; Blizzard_Transmog/Blizzard_TransmogTemplates.lua:1111-1113; Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:480`
  ```
  if self:IsShown() and IsUnitModelReadyForUI("player") then
  -- Catches edge cases where if for any reason the unit model was not yet ready for UI, tries again here.
  ```
- **No API turns an npcID into a displayID. SetPortraitTextureFromCreatureDisplayID can draw a 2D portrait for list rows from a display ID.**  
  `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:584-592; Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua:1417`
  ```
  Name = "SetPortraitTextureFromCreatureDisplayID" ... { Name = "textureObject" }, { Name = "creatureDisplayID" }
  ```
- **A manually created OrbitCamera that never received a camera record raises an error every frame, because UpdateLight reads self.modelSceneCameraInfo.flags.**  
  `Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua:230-232,503-509,567-572`
  ```
  return bit.band(self.modelSceneCameraInfo.flags, Enum.ModelSceneSetting.AlignLightToOrbitDelta) == ...
  ```
- **The actor-from-scene helper reads actorInfo.scriptTag without a nil check.**  
  `Blizzard_SharedXML/ModelSceneMixin.lua:418-420`
  ```
  local actorInfo = C_ModelInfo.GetModelSceneActorInfoByID(actorID);
  local existingActor = oldTagToActor[actorInfo.scriptTag];
  ```
- **ModelScene light setters exist. Blizzard's wrapped scenes set ambient light to 0.75, and the camera can make the light follow orbit rotation.**  
  `Blizzard_SharedXML/ModelSceneTemplates.xml:46-47; Blizzard_SharedXML/ModelSceneTemplates.lua:40-42; Blizzard_SharedXML/Shared/ModelSceneCameras/OrbitCameraMixin.lua:222-228`
  ```
  self:SetLightAmbientColor(self.normalIntensity, ...);  -- normalIntensity 0.75
  function OrbitCameraMixin:SetAlignLightToOrbitDelta(alignLightToOrbitDelta)
  ```
- **The issecretvalue and canaccessvalue globals exist in this build. Model setters are marked SecretArguments='AllowedWhenUntainted', so secret values cannot be passed from addon (tainted) code.**  
  `Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:65,287; Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua:155`
  ```
  Name = "issecretvalue" ... SecretArguments = "AllowedWhenUntainted"
  ```
- **OnModelLoaded is a valid script for model frames and for ModelScene actors.**  
  `Blizzard_SharedXML/UI.xsd:424,1224`
  ```
  <xs:element name="OnModelLoaded" type="ScriptType"/>
  ```
