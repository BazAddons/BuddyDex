# BuddyDex plumbing and house style: TOC fields, addon compartment, Settings panel, event bus and secret-safe unit scouting, and the BazUI/Downtime conventions (WoW Forever 1.60.1.70338, interface 16001, Camelot)

## Summary

Everything BuddyDex needs for its plumbing is in Blizzard addons that are always loaded for Camelot, so it can be used without load-on-demand tricks.

**How this client loads Blizzard files.** Camelot is a game type inside the "mainline" family. "standard" means retail only.
- In TOC file lists, [Family] resolves to Mainline/ and [Game] resolves to Camelot/.
- So a line tagged [AllowLoadGameType mainline] loads in this client unless it also carries [ExcludeLoadGameType camelot].
- WOW_PROJECT_ID is 18 (WOW_PROJECT_CAMELOT). The AzerBuddyProbe run on this build measured it.

**1. TOC fields.** The client reads the standard header fields. Blizzard Lua reads only these metadata keys: IconTexture, IconAtlas, Category, Group, Version, AddonCompartmentFunc, AddonCompartmentFuncOnEnter and AddonCompartmentFuncOnLeave.
- X-Category is never read by the client; it is only for the packager and CurseForge.
- A multi-value "## Interface: 16001, 120100" line loads here. BazUI and TomTom both use one and have saved variables in WTF.
- ForeverCompanion.toc is no longer on disk, only its saved variables remain. I used the installed AzerBuddyProbe, BazUI and Downtime TOCs as working evidence instead.

**2. Addon compartment.** It loads for Camelot: Blizzard_Minimap's Mainline AddonCompartment files are tagged mainline. There are two ways to register:
- **TOC route:** global function names, called as fn(addonName, buttonName). Works for load-on-demand addons too. Entries are registered once, at the first PLAYER_ENTERING_WORLD.
- **AddonCompartmentFrame:RegisterAddon({text, icon, func, funcOnEnter, funcOnLeave}):** func is called as func(data, menuInputData, menu). Entries are not de-duplicated and there is no unregister.

**3. Settings.** The API lives in Blizzard_Settings_Shared, which is always loaded through FrameXML. Blizzard_Settings is only a load-on-demand tracking stub.
- RegisterVerticalLayoutCategory and RegisterCanvasLayoutCategory return (category, layout).
- RegisterAddOnSetting(category, variable, key, tbl, type, name, default) writes the default into your saved-variable table. That table must already exist when you call it.
- OpenToCategory takes category:GetID().
- InterfaceOptions_AddCategory does not exist in this build.

**4. Events and secret values.**
- **Event bus:** CallbackRegistryMixin and EventRegistry are in Blizzard_SharedXMLBase, which is always loaded. You must call :OnLoad() yourself. TriggerEvent only accepts events declared with GenerateCallbackEvents. Each owner can hold one callback per event.
- **Scouting events:** NAME_PLATE_UNIT_ADDED(unitToken), UPDATE_MOUSEOVER_UNIT and PLAYER_TARGET_CHANGED (the last two carry no payload).
- **Secret per the API docs:**
  - SecretWhenUnitIdentityRestricted: UnitGUID, UnitCreatureType, UnitCreatureFamily, UnitSex, UnitRace, UnitCreatureID (which also has RequiresUnitIdentityAccess).
  - UnitName uses the separate SecretWhenUnitNameIdentityRestricted flag.
  - Never secret: UnitClassification, UnitLevel, UnitReaction, UnitIsVisible.
  - RequiresDeclassifiedUnitIdentity is on no Unit* function. It is only on model SetUnit, ModelSceneActor SetModelByUnit and CombatText SetActiveUnit.
  - C_TooltipInfo.GetUnit has no SecretWhen flag but is MayReturnNothing.
- **Checking before you read:** C_Secrets.ShouldUnitIdentityBeSecret(unit) and C_RestrictedActions.IsAddOnRestrictionActive(type) tell you in advance. The probe's out-of-combat scout in Ironforge logged clean names, sex, type, level and class, and showed issecretvalue(nil) is safe.

**5. House style.**
- **Namespacing and layout:** BazUI uses a global BazUI table with a module registry, one account-wide BazUIDB, and profiles stored as profiles[profile][module][key]. Downtime and the probe use a private namespace (local _, S = ... or local ADDON_NAME = ...) with an explicit ADDON_LOADED frame. Files are grouped in Core/, Game/, UI/ and Data/ folders listed in the TOC.
- **Formatting and comments:** 4-space indent, no tabs. BazUI files open with an SPDX header and dashed banner blocks, and comments are prose explaining why.
- **Deploy:** tools/deploy.sh uses rsync --delete with the .pkgmeta ignore list.
- **Release:** the BigWigs packager runs on a tag push.
- **Tests:** Python unittest plus lupa (Lua 5.1). A MOCK Lua prelude fakes frames through a metatable, then the test loads each file listed in the TOC with ("AddonName", S) as `...` and drives OnEvent, OnClick and slash handlers directly.

## Recommended approach

Below is a skeleton that follows Downtime and the probe (private namespace, explicit ADDON_LOADED frame) and uses only always-loaded Blizzard code.

### BuddyDex.toc
```
## Interface: 16001
## Title: BuddyDex
## Notes: A pocket companion that keeps a BuddyDex of every NPC you meet.
## Author: Baz4k
## Version: 0.1.0
## Category: Baz Studios
## X-Category: Interface Enhancements
## IconTexture: Interface\Icons\INV_Misc_Book_09
## SavedVariables: BuddyDexDB
## SavedVariablesPerCharacter: BuddyDexCharDB
## AddonCompartmentFunc: BuddyDex_OnAddonCompartmentClick
## AddonCompartmentFuncOnEnter: BuddyDex_OnAddonCompartmentEnter
## AddonCompartmentFuncOnLeave: BuddyDex_OnAddonCompartmentLeave

Core\Namespace.lua
Core\Database.lua
Core\Compartment.lua
Scout\Scout.lua
Settings\Settings.lua
UI\Dex.lua
```
Use the TOC route for the compartment, not RegisterAddon. Using both creates duplicate entries.

### Core\Namespace.lua
```lua
-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...
ns.NAME = ADDON_NAME
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
ns.IsForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT   -- 18, measured on 70338

-- A private bus, not EventRegistry: TriggerEvent then rejects typos.
local Bus = CreateFromMixins(CallbackRegistryMixin)
Bus:OnLoad()                                  -- CreateFromMixins does not init
Bus:GenerateCallbackEvents({ "VariablesReady", "NpcSeen", "NpcUpdated",
    "NpcCaught", "SelectionChanged", "SettingChanged" })
ns.Bus, ns.Event = Bus, Bus.Event
-- Listen: ns.Bus:RegisterCallback(ns.Event.NpcSeen, function(owner, npcID, entry) end, ownerTable)
--   One callback per owner per event; the owner must be a table or string, never a number.
-- Fire:   ns.Bus:TriggerEvent(ns.Event.NpcSeen, npcID, entry)
```

### Core\Database.lua
```lua
local ADDON_NAME, ns = ...
local DEFAULTS = { version = 1, roster = {}, settings = { scout = true, modelScale = 1 } }

local function fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then dst[k] = type(v) == "table" and CopyTable(v) or v end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")
    BuddyDexDB = type(BuddyDexDB) == "table" and BuddyDexDB or {}
    BuddyDexCharDB = type(BuddyDexCharDB) == "table" and BuddyDexCharDB or {}
    fill(BuddyDexDB, DEFAULTS); fill(BuddyDexDB.settings, DEFAULTS.settings)
    ns.db = BuddyDexDB
    ns.Bus:TriggerEvent(ns.Event.VariablesReady)
end)
```
The roster is keyed by npcID: `{ name, title, type, family, class, level, sex, zone, subzone, seen, first, caught }`. Store only plain values; never store a secret.

### Core\Compartment.lua
These are globals because the TOC names them; they close over `ns`.
```lua
local _, ns = ...
function BuddyDex_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then ns.OpenSettings() else ns.Dex:Toggle() end
end
function BuddyDex_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("BuddyDex")
    GameTooltip:AddLine("Click to open the BuddyDex. Right-click for settings.", 1, 1, 1)
    GameTooltip:Show()
end
function BuddyDex_OnAddonCompartmentLeave() GameTooltip:Hide() end
```

### Settings\Settings.lua
A vertical layout bound to the saved-variable table. Register after VariablesReady, because the table must already exist.
```lua
local _, ns = ...
ns.Bus:RegisterCallback(ns.Event.VariablesReady, function()
    local s = BuddyDexDB.settings
    local category = Settings.RegisterVerticalLayoutCategory("BuddyDex")

    local scout = Settings.RegisterAddOnSetting(category, "BUDDYDEX_SCOUT", "scout", s,
        Settings.VarType.Boolean, "Log NPCs I meet", Settings.Default.True)
    scout:SetValueChangedCallback(function(_, value)
        ns.Bus:TriggerEvent(ns.Event.SettingChanged, "scout", value) end)
    Settings.CreateCheckbox(category, scout,
        "Adds NPCs you mouse over, target or see a nameplate for to the BuddyDex.")

    local scale = Settings.RegisterAddOnSetting(category, "BUDDYDEX_MODEL_SCALE", "modelScale", s,
        Settings.VarType.Number, "Model size", 1)
    local options = Settings.CreateSliderOptions(0.5, 2, 0.05)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatPercentageRounded)
    Settings.CreateSlider(category, scale, options, "How large the selected NPC is drawn.")

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end, "BuddyDex.Settings")

function ns.OpenSettings()
    if ns.settingsCategory and not InCombatLockdown() then
        Settings.OpenToCategory(ns.settingsCategory:GetID())
    end
end
```

### Scout\Scout.lua
Secret-safe and logs out of combat only.
```lua
local _, ns = ...
local function plain(v) if issecretvalue and issecretvalue(v) then return nil end return v end
local function read(fn, ...)
    if not fn then return end
    local ok, a, b = pcall(fn, ...)
    if ok then return plain(a), plain(b) end
end

local function restricted(unit)
    if InCombatLockdown() then return true end
    local R, T = C_RestrictedActions, Enum.AddOnRestrictionType
    if R and T and (R.IsAddOnRestrictionActive(T.Combat) or R.IsAddOnRestrictionActive(T.Map)) then return true end
    return C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret
        and C_Secrets.ShouldUnitIdentityBeSecret(unit) or false
end

local function npcID(unit)
    local id = read(UnitCreatureID, unit)
    if id then return id end
    local guid = read(UnitGUID, unit)
    if type(guid) ~= "string" then return end
    local kind, _, _, _, _, rawID = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then return tonumber(rawID) end
end

local function title(unit)
    local data = read(C_TooltipInfo and C_TooltipInfo.GetUnit, unit)
    if type(data) ~= "table" or type(data.lines) ~= "table" then return end
    for i = 2, math.min(#data.lines, 4) do
        local t = data.lines[i] and plain(data.lines[i].leftText)
        if type(t) == "string" and not t:find("^Level") then return (t:gsub("^<(.*)>$", "%1")) end
    end
end

local function scout(unit)
    if not ns.db or not ns.db.settings.scout or not unit then return end
    if not UnitExists(unit) or UnitIsPlayer(unit) or UnitPlayerControlled(unit) or restricted(unit) then return end
    local id = npcID(unit); if not id then return end
    local roster, e = ns.db.roster, ns.db.roster[id]
    if e then
        e.seen = (e.seen or 1) + 1
        ns.Bus:TriggerEvent(ns.Event.NpcUpdated, id, e)
        return
    end
    e = {
        name = read(UnitName, unit), title = title(unit),
        type = read(UnitCreatureType, unit), family = read(UnitCreatureFamily, unit),
        class = read(UnitClassification, unit), level = read(UnitLevel, unit),
        sex = read(UnitSex, unit), zone = GetZoneText(), subzone = GetSubZoneText(),
        first = date("%Y-%m-%d"), seen = 1,
    }
    roster[id] = e
    ns.Bus:TriggerEvent(ns.Event.NpcSeen, id, e)
end

local f = CreateFrame("Frame")
for _, ev in ipairs({ "UPDATE_MOUSEOVER_UNIT", "PLAYER_TARGET_CHANGED", "NAME_PLATE_UNIT_ADDED" }) do
    f:RegisterEvent(ev)
end
f:SetScript("OnEvent", function(_, event, unit)
    if event == "UPDATE_MOUSEOVER_UNIT" then unit = "mouseover"
    elseif event == "PLAYER_TARGET_CHANGED" then unit = "target" end
    local ok, err = pcall(scout, unit)
    if not ok then geterrorhandler()(err) end
end)
```
Never feed nameplate tokens to model:SetUnit. It needs declassified identity, and doing it from nameplates crashed the client in the probe. Show the 3D model from stored display or creature IDs instead.

### Project tooling
- **Deploy:** copy BazUI's `tools/deploy.sh` and `.pkgmeta`. Change `package-as`, the default `DEST`, and the safety `case` pattern to `*/Interface/AddOns/BuddyDex`.
- **Tests:** copy Spellbound's lupa pattern, which loads the TOC file list with `assert(loadstring(src))("BuddyDex", ns)`. The mock must provide everything the files call: `CreateFromMixins`, a minimal `CallbackRegistryMixin` (OnLoad, GenerateCallbackEvents, RegisterCallback, TriggerEvent), `Settings.*` stubs, `C_AddOns.GetAddOnMetadata`, `issecretvalue`, `InCombatLockdown`, `UnitExists`/`UnitName`/…, `GetZoneText`, `CopyTable` and `date`. Then drive `frames[i].scripts.OnEvent(f, "ADDON_LOADED", "BuddyDex")` and `OnEvent(f, "UPDATE_MOUSEOVER_UNIT")` and assert on `BuddyDexDB.roster`.

## Pitfalls

- ForeverCompanion.toc is no longer on disk; only its saved variables remain in WTF (they look AceDB-shaped: profileKeys). TOC evidence comes from the installed AzerBuddyProbe, BazUI, Downtime, TomTom and Auctionator TOCs instead.
- Camelot is in the 'mainline' family but is not 'standard'. A Blizzard file tagged [AllowLoadGameType mainline] [ExcludeLoadGameType camelot], or [AllowLoadGameType standard], does not load here. Always check the .toc line, not just whether the file exists in the export.
- X-Category is never read by the client; only ## Category groups the AddOns list. Locale-suffixed Category-xxXX lines (as Auctionator uses) could not be verified from the exported Lua.
- There is no InterfaceOptions_AddCategory or InterfaceOptionsFrame_OpenToCategory in this build. Use Settings.*.
- Settings.RegisterAddOnSetting needs the real saved-variable table at registration time, so register after ADDON_LOADED. It rejects function-valued arguments, the defaultValue type must match variableType, and it writes the default into the table when the key is nil.
- Setting 'variable' IDs are global across every addon, so prefix them (BUDDYDEX_*). Settings.OpenToCategory takes the numeric category:GetID(), not a name.
- C_SettingsUtil.OpenSettingsPanel is HasRestrictions. Do not open settings in combat; guard with InCombatLockdown.
- AddonCompartmentFrame:RegisterAddon has no de-duplication and no unregister. Registering twice, or using it together with the TOC AddonCompartmentFunc, shows duplicate entries. The callback shapes also differ: TOC globals get (addonName, buttonName) and (addonName, frame), while RegisterAddon's func gets (nil, menuInputData, menu) and must read menuInputData.buttonName.
- Compartment TOC globals are called after forceinsecure(), so they always run tainted. They must be real globals, so pick unique names.
- CallbackRegistryMixin: you must call :OnLoad() yourself. TriggerEvent errors on undeclared events, and each owner can hold only one callback per event; a second RegisterCallback with the same owner silently replaces the first (BazUI's Events.lua documents hitting exactly this). Numeric owners raise an error. Function callbacks receive the owner as their first argument.
- EventRegistry is shared by every addon and accepts any event name. If you put custom events on it, namespace them ('BuddyDex.NpcSeen'); better, keep a private CallbackRegistry.
- EventUtil.ContinueOnAddOnLoaded was observed by the BazUI author to fire during file load, before saved variables existed, on this client. Use an explicit ADDON_LOADED frame with a name check, as Downtime and the probe do.
- Identity APIs (UnitGUID, UnitName, UnitCreatureType, UnitCreatureFamily, UnitSex, UnitRace, UnitCreatureID) can return secret values. Never boolean-test, compare, concatenate, use as a table key, or save a value before issecretvalue() says it is plain. Skip scouting when C_Secrets.ShouldUnitIdentityBeSecret(unit) is true or a Combat/Map restriction is active.
- UnitCreatureID also has RequiresUnitIdentityAccess, so it returns nothing when access is denied. Fall back to parsing UnitGUID (Creature/Vehicle prefixes only).
- C_TooltipInfo.GetUnit is MayReturnNothing and individual leftText lines may be secret, so wrap it in pcall and check each line. NAME_PLATE_UNIT_ADDED fires before the NPC model loads.
- Model:SetUnit and ModelSceneActor:SetModelByUnit require declassified unit identity, and the probe crashed the client ('Missing model in GeosRenderPrep') loading nameplate units into a hidden model. For the BuddyDex 3D view use stored creature or display IDs; only use SetUnit on a loaded 'target' outside restrictions.
- Blizzard_Collections (the Pet/Mount Journal templates) is LoadOnDemand. A BuddyDex built on its templates must call C_AddOns.LoadAddOn('Blizzard_Collections') first or reimplement the look from always-loaded SharedXML templates. BazUI's DEVELOPERS.md warns that templates present in the source tree may not be loaded (the TabSystemTemplate example).
- The roster grows without bound: SAVED_VARIABLES_TOO_LARGE shows a popup to the user. Keep entries small (no raw tooltip arrays) and consider a compact encoding.
- WOW_PROJECT_ID is now measured (18 == WOW_PROJECT_CAMELOT), so BazUI's comment saying it was unmeasured is out of date. BazUI.IsRetail (build major >= 10) remains a valid alternative.
- deploy.sh hard-codes the BazUI destination in its safety case-pattern (because --delete empties the target), so adjust it for BuddyDex. TOC edits and new textures or fonts need a full client restart, not /reload.
- Python lupa is not installed for system python3 on this machine. Spellbound's notes ran tests with ~/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 (`python3 -m unittest discover -s tests -v`). Mixin and CreateFromMixins are C-side globals in this build, so lupa mocks must define them, plus CallbackRegistryMixin and Settings stubs.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **Camelot (WoW Forever) has WOW_PROJECT_ID 18; the Camelot file is loaded only for the camelot game type.**  
  `Blizzard_ProjectConstants/Camelot/ProjectConstants.lua:1-2 and Blizzard_ProjectConstants/Blizzard_ProjectConstants.toc:7`
  ```
  WOW_PROJECT_CAMELOT = 18; WOW_PROJECT_ID = WOW_PROJECT_CAMELOT;  |  Camelot\ProjectConstants.lua [AllowLoadGameType camelot]
  ```
- **Runtime confirmation on this build: toc 16001, build 70338, projectID 18, and the globals issecretvalue, canaccessvalue, canaccesssecrets, AddonCompartmentFrame, Settings.RegisterCanvasLayoutCategory and C_AddOns.LoadAddOn all exist.**  
  `/Applications/World of Warcraft/_classic_beta_/WTF/Account/<account>/70/<character>/SavedVariables/AzerBuddyProbe.lua:315-326 (env), :34,:39,:45,:52,:53,:62 (globals)`
  ```
  ["projectID"] = 18, ["toc"] = 16001, ["build"] = "70338" ... ["AddonCompartmentFrame"] = "table"
  ```
- **Camelot belongs to the 'mainline' family: Blizzard has to explicitly exclude camelot from mainline lines, and 'standard' means retail-only. [Family] resolves to the Mainline/ folder and [Game] to the Camelot/ folder.**  
  `Blizzard_Minimap/Blizzard_Minimap.toc:13-14; Blizzard_Settings_Shared/Blizzard_Settings_Shared.toc:11-12; Blizzard_DamageMeter/Blizzard_DamageMeter.toc:2`
  ```
  [Family]\MinimapConstants.lua [AllowLoadGameType mainline] [ExcludeLoadGameType camelot]
  [Game]\MinimapConstants.lua [AllowLoadGameType camelot]
  Mainline\NewDefinitions.lua [AllowLoadGameType standard]
  ```
- **Blizzard TOCs carry no ## Interface line; their directives are Title, Notes, Author, Version, Dep/Dependencies, OptionalDep(s), LoadOnDemand, LoadWith, SavedVariables, SavedVariablesPerCharacter, SavedVariablesMachine, LoadSavedVariablesFirst, IconTexture, Category, AllowAddOnTableAccess and AllowLoad/AllowLoadGameType.**  
  `Blizzard_EventTrace/Blizzard_EventTrace.toc:3,6,7; Blizzard_AccountSaveUI/Blizzard_AccountSaveUI.toc:6; Blizzard_DamageMeter/Blizzard_DamageMeter.toc:3-4; Blizzard_CombatAudioAlerts/Blizzard_CombatAudioAlerts.toc:6`
  ```
  ## LoadOnDemand: 1 / ## SavedVariables: EventTraceSavedVars / ## IconTexture: Interface\ICONS\inv_misc_note_06 / ## Category: Character Utils / ## LoadSavedVariablesFirst: 1 / ## AllowAddOnTableAccess: 1
  ```
- **The only TOC metadata keys Blizzard Lua reads via C_AddOns.GetAddOnMetadata are AddonCompartmentFunc, AddonCompartmentFuncOnEnter, AddonCompartmentFuncOnLeave, Category, Group, IconAtlas, IconTexture and Version. X-Category is never read by the client.**  
  `Blizzard_AddOnList/AddonList.lua:390-391,453,456 and Blizzard_Minimap/Mainline/AddonCompartment.lua:81,86,106,113`
  ```
  local category = C_AddOns.GetAddOnMetadata(i, "Category");  -- Category is an addon defined field that allows for tree view organization
  ```
- **The AddOn list shows IconTexture (or IconAtlas) next to the title and falls back to a question-mark icon. It groups addons under ## Category; addons without a category stay ungrouped, and secure addons without one go under 'Uncategorized'.**  
  `Blizzard_AddOnList/AddonList.lua:390-401, 456, 475-490`
  ```
  if not iconTexture and not iconAtlas then iconTexture = [[Interface\ICONS\INV_Misc_QuestionMark]]; end
  ```
- **Interface version mismatches surface as reason 'INTERFACE_VERSION' in C_AddOns.GetAddOnInfo, and the user can disable the version check. A comma-separated multi-version Interface line works in this client: BazUI ('16001, 120100') and TomTom (a list that includes 16001) both load and have saved variables in WTF.**  
  `Blizzard_AddOnList/AddonList.lua:261; /Applications/World of Warcraft/_classic_beta_/Interface/AddOns/BazUI/BazUI.toc:16; /Applications/World of Warcraft/_classic_beta_/Interface/AddOns/TomTom/TomTom.toc:1`
  ```
  if (select(5, C_AddOns.GetAddOnInfo(i)) == "INTERFACE_VERSION") then
  ```
- **Known-working third-party TOC in this client (AzerBuddyProbe) uses Interface 16001 with SavedVariables plus SavedVariablesPerCharacter, and both persisted across 17 loads. ForeverCompanion.toc is no longer on disk, though its saved variables are still in WTF.**  
  `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/AzerBuddyProbe/AzerBuddyProbe.toc:1-7; WTF/.../<character>/SavedVariables/AzerBuddyProbe.lua:370-375`
  ```
  ## SavedVariables: AzerBuddyProbeAccountDB / ## SavedVariablesPerCharacter: AzerBuddyProbeCharDB  -> ["charReadBack"] = "yes", ["accountReadBack"] = "yes"
  ```
- **C_AddOns surface in this build: GetAddOnMetadata(name, variable), IsAddOnLoaded -> (loadedOrLoading, loaded), LoadAddOn, ADDON_LOADED(addOnName, containsBindings), SAVED_VARIABLES_TOO_LARGE(addOnName), and GetAddOnLocalTable, which reads another addon's private `...` table if it opts in with '## AllowAddOnTableAccess: 1'.**  
  `Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua:149-163, 165-179, 322-335, 347-361, 389-398, 410-418`
  ```
  Documentation = { "Returns the addon table (passed as the second argument of ... to files) for any addon that opts in through setting AllowAddOnTableAccess: 1 in the toc file." }
  ```
- **SAVED_VARIABLES_TOO_LARGE shows a static popup to the user. This matters for an ever-growing NPC roster.**  
  `Blizzard_Game/Shared/EventImplementation.lua:201 and Blizzard_StaticPopup_Game/GameDialogDefs.lua:3034`
  ```
  StaticPopup_Show("SAVED_VARIABLES_TOO_LARGE", arg1);
  ```
- **The addon compartment (AddonCompartmentFrame) loads for Camelot: the Mainline AddonCompartment files are tagged mainline with no camelot exclusion. It is a DropdownButton parented to MinimapCluster.**  
  `Blizzard_Minimap/Blizzard_Minimap.toc:32-33; Blizzard_Minimap/Mainline/AddonCompartment.xml:3`
  ```
  [Family]\AddonCompartment.lua [AllowLoadGameType mainline]
  <DropdownButton name="AddonCompartmentFrame" parent="MinimapCluster" mixin="AddonCompartmentMixin">
  ```
- **TOC route: at the first PLAYER_ENTERING_WORLD, every enabled addon that has AddonCompartmentFunc and is loadable or DEMAND_LOADED gets an entry. The icon comes from IconTexture or IconAtlas. On click the addon is loaded if needed, forceinsecure() is applied, and _G[funcName](addonName, buttonName) is called. OnEnter and OnLeave globals receive (addonName, menuButtonFrame).**  
  `Blizzard_Minimap/Mainline/AddonCompartment.lua:66-75, 77-104, 106-118`
  ```
  _G[addonCompartmentFunc](addonName, ...);  ...  CallAddonGlobalFunc(addonCompartmentFunc, name, menuInputData.buttonName);
  ```
- **Custom route: AddonCompartmentFrame:RegisterAddon(addonData) accepts the keys text, icon, func, funcOnEnter and funcOnLeave. It is a plain table.insert with no de-duplication and no unregister. icon may be an atlas name or a texture. The frame hides itself when there are 0 entries.**  
  `Blizzard_Minimap/Mainline/AddonCompartment.lua:127-139, 40-50, 141-148`
  ```
  text: Name of your addon / icon: Icon to appear to the right of the name / func: Click callback / funcOnEnter / funcOnLeave ... function AddonCompartmentMixin:RegisterAddon(addonData) table.insert(self.registeredAddons, addonData);
  ```
- **With RegisterAddon, func is used as a Menu responder, called func(data, menuInputData, menu): data is nil and menuInputData.buttonName is the mouse button. funcOnEnter and funcOnLeave are called (frame, elementDescription).**  
  `Blizzard_Minimap/Mainline/AddonCompartment.lua:33,61-62; Blizzard_Menu/Menu.lua:885-892, 781-788`
  ```
  local menuInputData = { context = menuInputContext, buttonName = menuInputButtonName, }; return descriptionProxy.responder(descriptionProxy:GetData(), menuInputData, menuProxy);
  ```
- **The probe registered with the compartment at ADDON_LOADED via RegisterAddon in this client. Its 'notCheckable' field is ignored by AddonCompartmentMixin.**  
  `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/AzerBuddyProbe/AzerBuddyProbe.lua:1876-1883`
  ```
  pcall(AddonCompartmentFrame.RegisterAddon, AddonCompartmentFrame, { text = "BuddyDex Probe", icon = ICON, notCheckable = true, func = function() buildHub() end, })
  ```
- **The Settings API is defined in Blizzard_Settings_Shared (AllowLoad Both, not load-on-demand). It is always loaded in-game through FrameXML -> SettingsDefinitions_Frame -> SettingsDefinitions_Shared -> Settings_Shared. Blizzard_Settings is a load-on-demand tracking stub that the panel loads itself when opened.**  
  `Blizzard_Settings_Shared/Blizzard_Settings_Shared.toc:7,14; Blizzard_FrameXML/Blizzard_FrameXML.toc:6; Blizzard_SettingsDefinitions_Shared/Blizzard_SettingsDefinitions_Shared.toc:2; Blizzard_Settings/Blizzard_Settings.toc:3; Blizzard_Settings/Blizzard_Settings.lua:1; Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua:305-311`
  ```
  SettingsAddonLoaded = true;  |  if not SettingsAddonLoaded then C_AddOns.LoadAddOn("Blizzard_Settings"); -- Loaded for tracking
  ```
- **Settings function signatures in this build: RegisterAddOnCategory(category), OpenToCategory(categoryID, scrollToElementName), RegisterVerticalLayoutCategory(name), RegisterVerticalLayoutSubcategory(parent, name), RegisterCanvasLayoutCategory(frame, name), RegisterCanvasLayoutSubcategory(parent, frame, name), RegisterAddOnSetting(categoryTbl, variable, variableKey, variableTbl, variableType, name, defaultValue) and RegisterProxySetting(categoryTbl, variable, variableType, name, defaultValue, getValue, setValue).**  
  `Blizzard_Settings_Shared/Blizzard_Settings.lua:134-138, 144-146, 154-168, 174-180`
  ```
  function Settings.RegisterAddOnSetting(categoryTbl, variable, variableKey, variableTbl, variableType, name, defaultValue)
  ```
- **The Register*LayoutCategory functions return (category, layout). Each category is created through the secure attribute delegate.**  
  `Blizzard_Settings_Shared/Blizzard_SettingsInbound.lua:176-181, 189-194`
  ```
  local category = CreateAndInitFromMixin(PrivateSettingsCategoryMixin, value); local layout = CreateVerticalLayout(); ... self:SetSecureAttributeResults(category, layout);
  ```
- **RegisterAddOnSetting arguments may not be functions (SecureUnpackArgs errors on them). variableTbl must be a table, and the default is written into variableTbl[variableKey] when that key is nil. defaultValue's type must match variableType.**  
  `Blizzard_Settings_Shared/Blizzard_SettingsInbound.lua:18-31, 207-211; Blizzard_Settings_Shared/Blizzard_Setting.lua:398-403, 417, 427, 23-29`
  ```
  error("Function values are not allowed for settings APIs") ... assert(type(variableTbl) == "table", "'variableTbl' argument must be a table."); ... if variableTbl[variableKey] == nil then variableTbl[variableKey] = defaultValue;
  ```
- **Control helpers: CreateCheckbox(category, setting, tooltip) asserts a boolean setting. CreateSlider(category, setting, options, tooltip) asserts a number setting with options. CreateDropdown(category, setting, optionsFunc, tooltip). CreateSliderOptions(min, max, step) computes steps = (max-min)/step. setting:SetValueChangedCallback(fn(setting, value)).**  
  `Blizzard_Settings_Shared/Blizzard_Settings.lua:309-315, 364-372, 388-414; Blizzard_Settings_Shared/Blizzard_Setting.lua:265-269`
  ```
  options.steps = (rate and (maxValue - minValue) / rate) or 100;  ...  assert((setting:GetVariableType() == "number") and (options ~= nil));
  ```
- **The slider label formatter enum and FormatPercentageRounded are in always-loaded SharedXML.**  
  `Blizzard_SharedXML/Shared/Slider/MinimalSlider.lua:43; Blizzard_SharedXML/FormattingUtil.lua:123-136; Blizzard_Settings_Shared/Blizzard_Settings.lua:302-307`
  ```
  MinimalSliderWithSteppersMixin.Label = EnumUtil.MakeEnum("Left", "Right", "Top", "Min", "Max");
  ```
- **Blizzard's own guide gives a complete checkbox example with RegisterAddOnSetting plus RegisterAddOnCategory, and says OpenToCategory takes category:GetID() with an optional setting display name to scroll to.**  
  `Blizzard_Settings_Shared/Blizzard_ImplementationReadme.lua:57-98, 199-210`
  ```
  Settings.OpenToCategory(category:GetID()); or Settings.OpenToCategory(category:GetID(), settingName);
  ```
- **OpenToCategory forwards to C_SettingsUtil.OpenSettingsPanel, which is flagged HasRestrictions. SETTINGS_LOADED is the event to wait on if needed.**  
  `Blizzard_Settings_Shared/Blizzard_Settings.lua:144-146; Blizzard_APIDocumentationGenerated/SettingsUtilDocumentation.lua:15-24, 31-34`
  ```
  Name = "OpenSettingsPanel", HasRestrictions = true, Arguments = { openToCategoryID: number?, scrollToElementName: stringView? }
  ```
- **The legacy InterfaceOptions_AddCategory / InterfaceOptionsFrame_OpenToCategory API is absent from the whole export, and the Settings Deprecated file is empty.**  
  `Blizzard_Settings_Shared/Blizzard_Deprecated.lua:1`
  ```
  (grep for InterfaceOptions_AddCategory over all AddOns returns nothing)
  ```
- **BazUI already uses canvas categories on Forever: RegisterCanvasLayoutCategory + RegisterAddOnCategory, subcategories for modules, and OpenToCategory(category:GetID()).**  
  `~/Code/BazUI/Core/Options/Registration.lua:571-578, 594, 655`
  ```
  rootCategory = Settings.RegisterCanvasLayoutCategory(canvas, "BazUI") ... Settings.RegisterAddOnCategory(rootCategory) ... Settings.OpenToCategory(category:GetID())
  ```
- **CallbackRegistryMixin and the global EventRegistry live in Blizzard_SharedXMLBase (AllowLoad Both), so a third-party addon can always use them.**  
  `Blizzard_SharedXMLBase/Blizzard_SharedXMLBase.toc:2,19,22; Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua:1-13, 94`
  ```
  EventRegistry = CreateFromMixins(CallbackRegistryMixin); ... EventRegistry:OnLoad();
  ```
- **CreateFromMixins does not initialize the registry; you must call CallbackRegistryMixin.OnLoad(self) yourself, as Blizzard's DataProvider does. GenerateCallbackEvents fills self.Event[name] = name and errors on duplicates.**  
  `Blizzard_SharedXMLBase/CallbackRegistry.lua:54-64, 269-284; Blizzard_SharedXML/DataProvider.lua:1-14`
  ```
  DataProviderMixin = CreateFromMixins(CallbackRegistryMixin); DataProviderMixin:GenerateCallbackEvents({...}); function DataProviderMixin:Init(tbl) CallbackRegistryMixin.OnLoad(self);
  ```
- **RegisterCallback(event, func, owner, ...) keeps only one callback per owner per event (it unregisters the old one first). A nil owner gets an auto-generated ID that is returned; numeric owners are reserved. Callbacks without extra args are called func(owner, ...payload). With extra args they are closures called as func(owner, extra..., payload...). Every call goes through securecallfunction.**  
  `Blizzard_SharedXMLBase/CallbackRegistry.lua:112-142, 198-214`
  ```
  self:UnregisterCallback(event, owner); ... callbacks[owner] = GenerateClosure(func, owner, ...); ... securecallfunction(func, owner, ...);
  ```
- **TriggerEvent errors on any event not declared with GenerateCallbackEvents unless SetUndefinedEventsAllowed(true) was called. EventRegistry allows undeclared events and is shared by every addon.**  
  `Blizzard_SharedXMLBase/CallbackRegistry.lua:184-189; Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua:5`
  ```
  elseif not self.isUndefinedEventAllowed and not self.Event[event] then error(string.format("CallbackRegistryMixin:TriggerEvent event '%s' doesn't exist.", event));
  ```
- **EventUtil.ContinueOnAddOnLoaded runs the callback immediately if C_AddOns.IsAddOnLoaded's second return is true, otherwise once on ADDON_LOADED. The BazUI author saw it fire during file load, before saved variables existed, on this client, and replaced it with an explicit event frame.**  
  `Blizzard_SharedXML/EventUtil.lua:67-75; ~/Code/BazUI/Core/Core.lua:28-43`
  ```
  -- Not EventUtil.ContinueOnAddOnLoaded. On this client C_AddOns.IsAddOnLoaded already answers true for BazUI while BazUI's own files are still running
  ```
- **Mixin and CreateFromMixins are C-side FrameScript globals in this build. Blizzard_SharedXMLBase/Mixin.lua only captures them and adds CreateAndInitFromMixin.**  
  `Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:97, 322; Blizzard_SharedXMLBase/Mixin.lua:4-12`
  ```
  local PrivateMixin = Mixin; local PrivateCreateFromMixins = CreateFromMixins; function CreateAndInitFromMixin(mixin, ...)
  ```
- **Scouting events: NAME_PLATE_UNIT_ADDED and NAME_PLATE_UNIT_REMOVED carry (unitToken). UPDATE_MOUSEOVER_UNIT and PLAYER_TARGET_CHANGED have no payload, so read the 'mouseover' or 'target' token yourself.**  
  `Blizzard_APIDocumentationGenerated/NamePlateManagerDocumentation.lua:118-127, 139-148; Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:3973-3977, 4916-4920`
  ```
  LiteralName = "NAME_PLATE_UNIT_ADDED", Payload = { { Name = "unitToken", Type = "UnitTokenType" } }
  ```
- **Secret flags on the unit APIs. SecretWhenUnitIdentityRestricted: UnitGUID (argument type UnitTokenPvPRestrictedForAddOns), UnitCreatureType, UnitCreatureFamily, UnitSex, UnitRace, UnitNameUnmodified, UnitTokenFromGUID and UnitCreatureID (which also has RequiresUnitIdentityAccess). UnitName instead has SecretWhenUnitNameIdentityRestricted.**  
  `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:1241-1248 (UnitGUID), 1030-1032 (UnitCreatureType), 996-998 (UnitCreatureFamily), 3069-3071 (UnitSex), 2925-2928 (UnitRace), 1013-1016 (UnitCreatureID), 2489-2492 (UnitName)`
  ```
  Name = "UnitName", SecretWhenUnitNameIdentityRestricted = true, SecretArguments = "AllowedWhenTainted" ... Name = "UnitGUID", SecretWhenUnitIdentityRestricted = true
  ```
- **UnitClassification, UnitLevel, UnitReaction, UnitIsVisible, UnitExists, UnitIsPlayer and UnitPlayerControlled have no SecretWhen flag (only SecretArguments=AllowedWhenUntainted), so their results are never secret. UnitLevel's documented argument is named 'name' of type cstring.**  
  `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:966-978, 2474-2486, 2983-2996, 2428-2440, 1192-1203, 2271-2283, 2667-2678`
  ```
  Name = "UnitClassification", Type = "Function", SecretArguments = "AllowedWhenUntainted",
  ```
- **No Unit* query function is marked RequiresDeclassifiedUnitIdentity. Only three APIs are: the Model/PlayerModel SetUnit, ModelSceneActor SetModelByUnit and CombatText SetActiveUnit. The predicate fails with ReturnWithError.**  
  `Blizzard_APIDocumentationGenerated/FrameAPICharacterModelBaseDocumentation.lua:240-243; Blizzard_APIDocumentationGenerated/FrameAPIModelSceneFrameActorBaseDocumentation.lua:447-450; Blizzard_APIDocumentationGenerated/CombatTextDocumentation.lua:30-32; Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua:16-19`
  ```
  Name = "SetUnit", RequiresDeclassifiedUnitIdentity = true ... Documentation = { "Guarded APIs and events require that callers have access to the identity of a supplied unit token." }
  ```
- **Definitions of the predicates: identity-restricted results are secret when the unit is not player-controlled and not in the party/raid. UnitName follows the same rules except for player units in PvP. RequiresUnitIdentityAccess returns no values instead of raising an error.**  
  `Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua:54-58, 125-133`
  ```
  "Guarded APIs and events produce secret values when the unit isn't player-controlled or in the party/raid. For compound tokens (eg. 'boss1target'), results are secret if any unit in the chain fails this."
  ```
- **You can ask before reading: C_Secrets.ShouldUnitIdentityBeSecret(unit) answers per unit, and C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.X) answers per restriction (Combat=0, Encounter=1, ChallengeMode=2, PvPMatch=3, Map=4, Chat=5). ADDON_RESTRICTION_STATE_CHANGED(type, state) fires before a restriction activates and after it deactivates.**  
  `Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua:305-318; Blizzard_APIDocumentationGenerated/RestrictedActionsDocumentation.lua:29-69, 97-107; Blizzard_APIDocumentationGenerated/RestrictedActionsConstantsDocumentation.lua:19-34`
  ```
  Name = "ShouldUnitIdentityBeSecret", Documentation = { "Returns true if queries for unit identity (such as name or GUID) will produce secret values." }
  ```
- **Secret-value helper globals: issecretvalue(v), canaccessvalue(v), canaccessallvalues(...), canaccesssecrets(), issecrettable(t), hasanysecretvalues(...), scrubsecretvalues(...) (secrets become nil) and scrub(...) (secrets and any non string/number/boolean value become nil).**  
  `Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:20-80, 253-301, 374-405`
  ```
  Name = "scrubsecretvalues", Documentation = { "Returns a transformed list of values with inputs that are secret values replaced by nil values." }
  ```
- **C_TooltipInfo.GetUnit(unit, hideStatus) has no SecretWhen flag, but it is MayReturnNothing and its unit argument has the PvP-restricted type. Individual line text can still be secret, so the probe checks issecretvalue on each leftText.**  
  `Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua:1181-1196; /Applications/World of Warcraft/_classic_beta_/Interface/AddOns/AzerBuddyProbe/AzerBuddyProbe.lua:1518-1526`
  ```
  Name = "GetUnit", MayReturnNothing = true, SecretArguments = "AllowedWhenUntainted", Arguments = { unit: UnitTokenPvPRestrictedForAddOns, hideStatus: bool? }
  ```
- **Observed in this client: scouting out of combat in Ironforge stored clean (non-secret) name, sex, creature type, classification, level and reaction for NPCs. issecretvalue(nil) is safe to call: entries with a nil family were written without error.**  
  `/Applications/World of Warcraft/_classic_beta_/WTF/Account/<account>/SavedVariables/AzerBuddyProbe.lua:9-27; /Applications/World of Warcraft/_classic_beta_/Interface/AddOns/AzerBuddyProbe/AzerBuddyProbe.lua:1328-1338, 1527-1541`
  ```
  [5164] = { ["name"] = "Grumnus Steelshaper", ["title"] = "Armor Crafter", ["class"] = "normal", ["sex"] = 2, ["level"] = 60, ["type"] = "Humanoid", ["reaction"] = 5, ... }
  ```
- **Crash found by the probe: loading nameplate units into a hidden model crashed the client ('Missing model in GeosRenderPrep'), because nameplates arrive before the NPC's model has loaded.**  
  `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/AzerBuddyProbe/AzerBuddyProbe.lua:1486-1492`
  ```
  -- Loading nameplate units into a hidden model to read display IDs crashed the client ("Missing model in GeosRenderPrep"): nameplates arrive before the NPC's model has loaded.
  ```
- **Blizzard_Collections is load-on-demand; the BuddyDex must not assume any of its templates are present.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3,13`
  ```
  ## LoadOnDemand: 1 ... ## AllowLoadGameType: wrath, cata, mists, mainline
  ```
- **House style, BazUI (DEVELOPERS.md): Forever first, retail kept working. Test for features, with BazUI.IsRetail as the one client switch. Check the TOC, not the source tree, before using a Blizzard template. Global frame names use a BazUI<Name> prefix. One saved variable, BazUIDB. The options UI is Blizzard Settings, and labels are short sentence-case sentences.**  
  `~/Code/BazUI/DEVELOPERS.md:53-60, 90-98, 106`
  ```
  Before using a Blizzard template, confirm it is loaded; `Core/TabStrip.lua` exists because the TabSystem is not.
  ```
- **House style, BazUI profiles: BazUIDB.profiles[profileName][moduleName][key], plus assignments[charKey], defaultProfile and activeProfile. Defaults are copied in with CopyTable for tables. Modules read and write through addon.db.profile, a metatable proxy, via addon:GetSetting/SetSetting. Saved variables are declared ready at PLAYER_LOGIN through BazUI:QueueForVariables.**  
  `~/Code/BazUI/Core/Profiles.lua:5, 68-79, 225-269, 823-855; ~/Code/BazUI/Core/Core.lua:45-93`
  ```
  -- Profiles stored in BazUIDB.profiles[profileName][addonName] = { ... }
  ```
- **House style, formatting: BazUI files open with an SPDX header and dashed banner blocks, and comments are full-sentence prose explaining history and why (about 22% of Core.lua lines are comments). Indentation is 4 spaces with no tabs. The Downtime and probe code uses a private namespace (local _, S = ... / local ADDON_NAME = ...) with short one-line comments and explicit ADDON_LOADED frames.**  
  `~/Code/BazUI/Core/Core.lua:1-23; ~/Code/Spellbound/Downtime/Core/Namespace.lua:1-3; ~/Code/Spellbound/Downtime/Core/Bootstrap.lua:1, 67-80; ~/Code/BuddyDex/tools/AzerBuddyProbe/AzerBuddyProbe.lua:6, 126`
  ```
  -- SPDX-License-Identifier: GPL-2.0-or-later
  ---------------------------------------------------------------------------
  -- BazUI: Core Module
  ```
- **deploy.sh uses bash with set -euo pipefail. It refuses any destination that does not end in /Interface/AddOns/BazUI, builds rsync --exclude rules from the .pkgmeta ignore list (plus .DS_Store), runs rsync -a --delete, and prints the version, short commit and a dirty flag. It never touches saved variables; TOC changes and new textures need a client restart.**  
  `~/Code/BazUI/tools/deploy.sh:12-42; ~/Code/BazUI/.pkgmeta:1-18`
  ```
  case "$DEST" in */Interface/AddOns/BazUI) ;; *) echo "deploy: refusing..."; exit 1 ;; esac ... rsync -a --delete "${EXCLUDES[@]}" "$ROOT/" "$DEST/"
  ```
- **Tests use Python unittest with lupa.lua51.LuaRuntime. A MOCK Lua string defines the WoW globals, including a 'combat' flag behind InCombatLockdown and GetBuildInfo returning 16001. object() returns a frame whose metatable serves real methods and a no-op for any capitalized method name. CreateFrame records frames and sets globals, with template-specific children such as PortraitFrameTemplate's TitleContainer.TitleText and CloseButton. Each test loads the files listed in the TOC in order with assert(loadstring(src))('Downtime', S) to fake `...`, then drives scripts.OnEvent, SlashCmdList, OnClick and OnUpdate and asserts in Lua.**  
  `~/Code/Spellbound/tests/test_addon.py:4-71, 74-85, 86-90`
  ```
  lua.execute('assert(loadstring(...))("Downtime",S)', source) ... event.scripts.OnEvent(event,'ADDON_LOADED','Downtime')
  ```
