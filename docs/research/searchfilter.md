# BuddyDex header widgets: search box, filter dropdown (with reset X), "N/M seen" count/progress, plus small buttons, checkboxes and tooltips, as used by this Camelot (WoW Forever) client build

## Summary

Answer: everything the BuddyDex header needs is in addons that are always loaded, so BuddyDex can build it without loading Blizzard_Collections.

**How file paths resolve for Camelot.** The client loads `[Family]` paths from the Mainline folder and `[Game]` paths from the Camelot folder. Evidence:
- The Camelot toy tracker (isCount) is only consumed by Mainline/Blizzard_ToyBox.lua.
- The Camelot COUNT_DISPLAY_STYLE constant is only consumed by Mainline/Blizzard_MountCollection.lua.
- Blizzard_Menu only gets a MenuVariants file for "mainline".

So the Mount Journal comes from Blizzard_Collections/Mainline/*. The Pet Journal is the exception: it comes from Blizzard_Collections/Classic/* (wrath, cata, camelot only).

**1. Search box.** `SearchBoxTemplate` is defined in Blizzard_SharedXML (always loaded, both game and glue).
- It provides a magnifier icon, gray Instructions text (global SEARCH) and a clear button that only shows while focused or holding text.
- Its OnTextChanged handler, `SearchBoxTemplate_OnTextChanged`, ignores the `userInput` argument. It only toggles the icon, clear button and instructions.
- The journals keep that handler and then apply the search themselves (`MountJournal_OnSearchTextChanged`). They clear the search on OnHide.
- The Settings panel uses `HookScript("OnTextChanged")` and skips the update when the text hasn't changed.

**2. Filter dropdown.** The journals use the new Menu system, not UIDropDownMenu.
- XML: `<DropdownButton parentKey="FilterDropdown" inherits="WowStyle1FilterDropdownTemplate">` with `resizeToText=false` and `SetWidth(90)`.
- Lua: `SetIsDefaultCallback`, `SetDefaultCallback`, then `SetupMenu(function(dropdown, rootDescription) ... end)`. Inside it they call `CreateCheckbox`, `CreateTitle`, `CreateDivider`, `CreateSpacer`, `CreateButton` (submenus and Check All / Uncheck All) and `CreateRadio` (sort order).
- The template (Blizzard_Menu, LoadFirst, always loaded) includes a hidden ResetButton (`UIResetButtonTemplate`, red-X atlas `auctionhouse-ui-filter-redx`).
- `WowDropdownFilterBehaviorMixin` shows that button whenever `isDefaultCallback()` returns false. It re-checks on OnShow, on menu assignment and after every menu pick. Clicking it calls `defaultCallback` and hides it.
- `SetUpdateCallback` fires after any pick, which is a convenient place to refresh the list.
- Response defaults: checkboxes return Refresh, so the menu stays open. Radios and buttons have no default, so the whole menu closes unless the responder returns `MenuResponse.Refresh`.

**3. Count / progress.** In Camelot the journals show a count, not a progress bar.
- They use `CollectionsCountTemplate`: an `InsetFrameTemplate3` box with a Label and a Count FontString, written with `.Count:SetText(n)` and positioned `TOP, 16, -35` (Camelot uses the CENTER style).
- Camelot also replaces the Toy Box progress bar with a count and hides the Wardrobe progress bar.
- `CollectionsProgressBarTemplate` (StatusBar: `SetMinMaxValues`, `SetValue`, `.text:SetFormattedText`) and `CollectionsCountTemplate` both live in Blizzard_Collections, which is load-on-demand. Copy them rather than depend on them.
- A Camelot-only, always-loaded bar exists: `ColoredProgressBarTemplate` in Blizzard_SharedXML/Camelot, used by the Forever Skills, Reputation and Pet XP bars. It is set with `SetFillPercent` and `SetText`.

**4. Other widgets.** All always loaded:
- `UIPanelButtonTemplate` or `MagicButtonTemplate` (the journal look; `.tooltipText` gives an automatic tooltip).
- `SharedButtonSmallTemplate` (modern red three-slice button).
- `UICheckButtonTemplate`, `MinimalCheckboxTemplate`, `CheckboxWithLabelTemplate`, `SettingsCheckboxTemplate` (Blizzard_Settings_Shared, also always loaded).
- `NewFeatureLabelTemplate` ("NEW" badge) and `SquareIconButtonTemplate`.
- `GameTooltip_SetTitle` / `GameTooltip_Add*Line` helpers and `GetAppropriateTooltip()`.

## Recommended approach

Build the header in Lua using only always-loaded templates. Do not load Blizzard_Collections; copy its count and progress-bar look instead.

```lua
local _, ns = ...
local Dex = ns.DexFrame          -- your journal window, with a LeftInset frame
local DB                          -- = BuddyDexDB.dex, assigned on ADDON_LOADED

local CREATURE_TYPES = { "Beast","Critter","Demon","Dragonkin","Elemental","Giant","Humanoid","Mechanical","Undead","Not specified" }
local SORTS = { {"name", NAME or "Name"}, {"level", LEVEL or "Level"}, {"seen", "Times Seen"}, {"zone", ZONE or "Zone"} }

local function ResetFilters()
  DB.types = {}
  for _, t in ipairs(CREATURE_TYPES) do DB.types[t] = true end
  DB.sort, DB.caughtOnly = "name", false
end

local function IsDefaultFilters()
  if DB.sort ~= "name" or DB.caughtOnly then return false end
  for _, t in ipairs(CREATURE_TYPES) do
    if not DB.types[t] then return false end
  end
  return true
end

------------------------------------------------------------------
-- 1) Search box (Blizzard_SharedXML)
------------------------------------------------------------------
local search = CreateFrame("EditBox", nil, Dex, "SearchBoxTemplate")
search:SetSize(145, 20)                                   -- the template has no size
search:SetPoint("TOPLEFT", Dex.LeftInset, "TOPLEFT", 15, -9)
search:SetMaxLetters(40)
search.Instructions:SetText("Search NPCs")                -- OnLoad already applied SEARCH

-- HookScript keeps SearchBoxTemplate_OnTextChanged (icon / clear button / instructions).
-- Do not gate on userInput: the clear button changes the text from script.
search:HookScript("OnTextChanged", function(self)
  local q = strtrim(self:GetText() or ""):lower()
  if q == Dex.searchText then return end
  Dex.searchText = q
  Dex:RefreshList()
end)

-- Optional, like MountJournal_ClearSearch: clear the search when the window hides.
search:SetScript("OnHide", function(self) self:SetText("") end)

function Dex:Matches(e, q)       -- plain-text find, no patterns
  if q == nil or q == "" then return true end
  for _, s in ipairs({ e.name, e.title, e.zone, e.subzone }) do
    if type(s) == "string" and not (issecretvalue and issecretvalue(s))
       and s:lower():find(q, 1, true) then
      return true
    end
  end
end

------------------------------------------------------------------
-- 2) Filter dropdown (Blizzard_Menu, new Menu system)
------------------------------------------------------------------
local filter = CreateFrame("DropdownButton", nil, Dex, "WowStyle1FilterDropdownTemplate")
filter.resizeToText = false      -- template default is true (+60 px); the journals turn it off
filter:SetWidth(90)
filter:SetPoint("TOPRIGHT", Dex.LeftInset, "TOPRIGHT", -5, -10)
-- Text defaults to FILTER; filter:SetText("Filter") also works.

filter:SetIsDefaultCallback(IsDefaultFilters)               -- shows/hides the red-X ResetButton
filter:SetDefaultCallback(function()                        -- red-X click (it hides itself)
  ResetFilters()
  Dex:RefreshList()
end)
filter:SetUpdateCallback(function() Dex:RefreshList() end)  -- after any pick in the menu

local function IsType(t) return DB.types[t] end
local function ToggleType(t) DB.types[t] = not DB.types[t] end   -- checkbox default response = Refresh
local function SetAllTypes(v)
  for _, t in ipairs(CREATURE_TYPES) do DB.types[t] = v end
  return MenuResponse.Refresh
end
local function IsSort(key) return DB.sort == key end
local function SetSort(key)
  DB.sort = key
  return MenuResponse.Refresh     -- omit to close the menu (the radio default)
end

filter:SetupMenu(function(dropdown, root)
  root:SetTag("MENU_BUDDYDEX_DEX_FILTER")

  root:CreateCheckbox("Caught only",
    function() return DB.caughtOnly end,
    function() DB.caughtOnly = not DB.caughtOnly end)

  root:CreateDivider()
  root:CreateTitle("Creature Type")
  for _, t in ipairs(CREATURE_TYPES) do
    root:CreateCheckbox(t, IsType, ToggleType, t)
  end
  local bulk = root:CreateButton("Select")               -- a submenu, like the journal's SOURCES
  bulk:CreateButton(CHECK_ALL or "Check All", SetAllTypes, true)
  bulk:CreateButton(UNCHECK_ALL or "Uncheck All", SetAllTypes, false)

  root:CreateDivider()
  local sort = root:CreateButton(RAID_FRAME_SORT_LABEL or "Sort By")
  for _, s in ipairs(SORTS) do
    sort:CreateRadio(s[2], IsSort, SetSort, s[1])
  end

  root:CreateDivider()
  root:CreateButton(RESET or "Reset", function()
    ResetFilters()
    return MenuResponse.Refresh
  end)
  -- For very long lists: root:SetScrollMode(20 * 12)
end)
-- If filters change outside the menu (slash command, load): filter:ValidateResetState()

------------------------------------------------------------------
-- 3) "N/M seen" count, Camelot journal style (rebuilt CollectionsCountTemplate)
------------------------------------------------------------------
local count = CreateFrame("Frame", nil, Dex, "InsetFrameTemplate3")   -- Blizzard_UIPanelTemplates
count:SetSize(130, 20)
count:SetPoint("TOP", 16, -35)                                         -- Camelot CENTER style

count.Count = count:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
count.Count:SetPoint("RIGHT", -10, 0)
count.Count:SetJustifyH("RIGHT")

count.Label = count:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
count.Label:SetPoint("LEFT", 10, 0)
count.Label:SetPoint("RIGHT", count.Count, "LEFT", -3, 0)
count.Label:SetJustifyH("LEFT")
count.Label:SetText("Seen")

count:EnableMouse(true)
count:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip_SetTitle(GameTooltip, "BuddyDex")
  GameTooltip_AddNormalLine(GameTooltip, "NPCs you have seen out of all NPCs logged.")
  GameTooltip:Show()
end)
count:SetScript("OnLeave", GameTooltip_Hide)

-- Optional bar in the Forever skills/reputation style (Camelot-only template, always loaded)
local bar
if C_XMLUtil.GetTemplateInfo("ColoredProgressBarTemplate") then
  bar = CreateFrame("Frame", nil, Dex, "ColoredProgressBarTemplate")
  bar:SetSize(160, 29)
  bar:SetFillTextureByColorType(ColoredProgressBarMixin.ColorType.Green)  -- before SetFillPercent
end

function Dex:UpdateProgress(seen, total)
  count.Count:SetFormattedText("%d/%d", seen, total)
  if bar then
    bar:SetFillPercent(total > 0 and seen / total or 0)
    bar:SetText(("%d/%d"):format(seen, total))
  end
end

------------------------------------------------------------------
-- 4) Action buttons and settings checkbox
------------------------------------------------------------------
local makeBuddy = CreateFrame("Button", nil, Dex.Display, "UIPanelButtonTemplate")  -- journal look
makeBuddy:SetSize(140, 22)
makeBuddy:SetText("Make Buddy")
makeBuddy:SetMotionScriptsWhileDisabled(true)
makeBuddy:SetScript("OnClick", function() ns.SetBuddy(Dex.selected) end)

function Dex:UpdateButtons(entry)
  local ok = entry and entry.caught
  makeBuddy:SetEnabled(ok)
  -- tooltipText would override the disabled tooltip, so set only one of them
  makeBuddy.tooltipText = ok and "Summon this NPC as your buddy" or nil
  makeBuddy:SetDisabledTooltip(not ok and "Catch this NPC first" or nil)
end

local cb = CreateFrame("CheckButton", nil, ns.SettingsPanel, "UICheckButtonTemplate")  -- or CheckboxWithLabelTemplate
cb.Text:SetText("Announce newly seen NPCs")
cb:SetChecked(DB.announce)
cb:SetScript("OnClick", function(self)
  DB.announce = self:GetChecked()
  PlaySound(self:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
                               or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
end)

-- "NEW" badge on a list row: CreateFrame("Frame", nil, row, "NewFeatureLabelNoAnimateTemplate")
```

If you'd rather use the exact Blizzard templates (CollectionsCountTemplate, CollectionsProgressBarTemplate), call `C_AddOns.LoadAddOn("Blizzard_Collections")` (or wait with `EventUtil.ContinueOnAddOnLoaded`) before CreateFrame. That loads the whole journal, so copying the look is recommended.

## Pitfalls

- SearchBoxTemplate_OnTextChanged ignores userInput, and the clear button changes the text with a script SetText(""), which fires OnTextChanged with userInput=false. If you only refresh on userInput, clicking the clear button won't reset the list.
- Calling SetScript("OnTextChanged") on a SearchBoxTemplate replaces SearchBoxTemplate_OnTextChanged. The clear button, icon tint and instructions then stop updating unless you call it yourself, as the Mount Journal does. HookScript avoids this.
- SearchBoxTemplate has no Size; size it yourself (the journals use 145x20). instructionText is read only in OnLoad, so with CreateFrame use search.Instructions:SetText(). Escape and Enter only clear focus; they don't clear the text.
- Create the dropdown with CreateFrame("DropdownButton", ...), not "Button". The template's OnLoad asserts the DropdownButton intrinsic.
- WowStyle1FilterDropdownTemplate defaults to resizeToText=true (text width + 60). UpdateText runs after every menu pick, so a plain SetWidth(90) gets overwritten. Set dropdown.resizeToText = false first, as the journals do through a KeyValue.
- The red-X ResetButton only appears if SetIsDefaultCallback is set. It re-checks only on OnShow, when the menu is assigned and after menu picks. Call dropdown:ValidateResetState() after changing filters from code. A red-X click calls defaultCallback but not SetUpdateCallback, so refresh the list inside defaultCallback.
- Response defaults: checkboxes refresh and stay open. Radios and plain buttons close the whole menu unless the responder returns MenuResponse.Refresh. 'Check All' and 'Reset' buttons should return MenuResponse.Refresh, otherwise the open checkmarks look stale.
- The menu is rebuilt on every open. isSelected and responders must read live state; don't capture values when the generator runs.
- Responders receive (data, menuInputData, menu), and isSelected receives (data). Pass the creature type or sort key as the 4th argument to CreateCheckbox or CreateRadio, or the 3rd to CreateButton.
- CollectionsCountTemplate, CollectionsProgressBarTemplate and CollectionsCountTemplateMixin live in load-on-demand Blizzard_Collections. Inheriting them without LoadAddOn fails at CreateFrame.
- BLIZZARD_COLLECTIONS_* constants come from Blizzard_Collections too, and Camelot overrides them (CENTER count style, side tabs). Copy the values, don't reference them.
- The Mainline pet journal file (Shared/Blizzard_PetCollection.*, with the CreateRadio sort menu) is excluded for camelot. Camelot loads Classic/Blizzard_PetCollection.*, so use the Mainline file only as a pattern reference.
- In Forever, the journals hide the filter dropdown when CVar onlyShowCollectedItemsInJournal is true. Don't mistake the journal's missing filter for a missing API.
- ColoredProgressBarTemplate exists only for game type camelot; check C_XMLUtil.GetTemplateInfo before using it. It is a Frame, not a StatusBar: no SetMinMaxValues/SetValue, use SetFillPercent(0..1).
- ColoredProgressBarTemplate's SetFillPercent multiplies by GetWidth(), so size the frame first and call it again after resizing. SetFillTextureByColorType calls SetAtlas with UseAtlasSize, which resets the fill width, so call SetFillPercent after it.
- UIPanelButtonMixin:OnEnter shows .tooltipText even when the button is disabled, and falls back to the disabled tooltip only when tooltipText is nil. Disabled tooltips also need SetMotionScriptsWhileDisabled(true), like the journal's MountButton.
- MagicButtonTemplate's OnLoad adjusts its anchors only if they exist at OnLoad time. With CreateFrame they don't, so position it manually; UIPanelButtonTemplate works the same.
- SharedButtonSmallTemplate is the modern red three-slice style and does not match the journals' UIPanelButtonTemplate/MagicButtonTemplate buttons. Pick one style for the whole window.
- SettingsCheckboxTemplate shows SettingsTooltip, not GameTooltip. Its Init() overwrites OnClick. OnValueChanged callbacks receive (owner, checked); with a nil owner, owner is a generated number. For a simple settings tab, UICheckButtonTemplate or CheckboxWithLabelTemplate is less work.
- Frames whose template defines no OnEnter (such as InsetFrameTemplate3) need EnableMouse(true) or SetMouseMotionEnabled(true) before a SetScript("OnEnter") tooltip will fire.
- Globals such as FILTER, SEARCH, CHECK_ALL, UNCHECK_ALL, RAID_FRAME_SORT_LABEL, NAME and LEVEL come from client GlobalStrings, not Lua files. Use `or` fallbacks.
- The legacy UIDropDownMenu (UIDropDownMenu_Initialize) is still loaded but taint-prone and not what the journals use. Use the Menu system.
- Under 12.x restrictions, values read from unit APIs in combat may be secret. Guard string.lower/find over roster names with issecretvalue, or store only non-secret values when logging NPCs.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **SearchBoxTemplate is defined in Blizzard_SharedXML (always loaded, AllowLoad Both, no LoadOnDemand). It inherits InputBoxInstructionsTemplate and has a magnifier icon (parentKey searchIcon) and a hidden clear button (parentKey clearButton, ClearButtonMixin).**  
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml:206-254; loaded at Blizzard_SharedXML/Blizzard_SharedXML.toc:212-213`
  ```
  <EditBox name="SearchBoxTemplate" mixin="NarrationSearchBoxMixin" inherits="InputBoxInstructionsTemplate" autoFocus="false" virtual="true"> ... <Button name="$parentClearButton" parentKey="clearButton" mixin="ClearButtonMixin" hidden="true">
  ```
- **The instruction text comes from KeyValue instructionText (default global SEARCH) and is applied once in OnLoad. With CreateFrame you must set search.Instructions:SetText(...) afterwards. The template has TextInsets 16/20 and no Size, so you must size it (the journals use 145x20).**  
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml:207-209,245; Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.lua:175-178; Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:411-412`
  ```
  function SearchBoxTemplate_OnLoad(self)
  	self.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
  	self.Instructions:SetText(self.instructionText);
  end
  ```
- **SearchBoxTemplate_OnTextChanged ignores userInput. It shows the clear button and bright icon when the box is focused or non-empty, and toggles the Instructions text. The template wires it as its OnTextChanged handler.**  
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.lua:192-201; InputBoxTemplates.xml:252`
  ```
  function SearchBoxTemplate_OnTextChanged(self)
  	if ( not self:HasFocus() and self:GetText() == "" ) then ... self.clearButton:Hide();
  	else ... self.clearButton:Show(); end
  	InputBoxInstructions_OnTextChanged(self);
  end
  ```
- **Clicking the clear button plays a sound, calls SetText("") and clears focus. Because that is a script SetText, OnTextChanged fires with userInput=false. Escape and Enter only clear focus; they do not clear the text.**  
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.lua:203-211,233-235; InputBoxTemplates.xml:248-249`
  ```
  function SearchBoxTemplate_ClearText(self)
  	self:SetText("");
  	self:ClearFocus();
  end
  ```
- **Journal pattern: replace OnTextChanged, call SearchBoxTemplate_OnTextChanged(self) first, then apply the search. The search text is cleared OnHide.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:905-912; Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:418-420`
  ```
  function MountJournal_OnSearchTextChanged(self)
  	SearchBoxTemplate_OnTextChanged(self);
  	C_MountJournal.SetSearch(self:GetText());
  end
  ```
- **Alternative pattern: the Settings panel keeps the template handler with HookScript and ignores updates where the text hasn't changed.**  
  `Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua:83,686-692`
  ```
  self.SearchBox:HookScript("OnTextChanged", GenerateClosure(self.OnSearchTextChanged, self));
  ```
- **SearchBoxNineSliceTemplate is an always-loaded variant with the newer 'common-searchbar-a' background and 22px insets.**  
  `Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml:438-488`
  ```
  <EditBox name="SearchBoxNineSliceTemplate" ... inherits="InputBoxInstructionsNineSliceTemplate"> <Texture parentKey="Background" atlas="common-searchbar-a" .../>
  ```
- **Blizzard_Collections is load-on-demand. For Camelot it loads the Mount Journal from the [Family] folder (Mainline) and the Pet Journal from the Classic folder, explicitly allowed for camelot.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3,13,25-31`
  ```
  ## LoadOnDemand: 1 ... [Family]\Blizzard_MountCollection.lua ... Classic\Blizzard_PetCollection.lua [AllowLoadGameType wrath, cata, camelot] ... Shared\Blizzard_PetCollection.lua [AllowLoadGameType mists, mainline] [ExcludeLoadGameType camelot]
  ```
- **[Family] resolves to Mainline for Camelot. The Camelot ToyProgressTracker (isCount) is only read by Mainline/Blizzard_ToyBox.lua (Classic ToyBox uses self.progressBar instead). Blizzard_Menu also only provides a family MenuVariants file for 'mainline'.**  
  `Blizzard_Collections/Camelot/Blizzard_ToyBoxProgressTracker.xml:4-9; Blizzard_Collections/Mainline/Blizzard_ToyBox.lua:454-462; Blizzard_Collections/Classic/Blizzard_ToyBox.lua:367-370; Blizzard_Menu/Blizzard_Menu.toc:7-10`
  ```
  if self.ProgressTracker.isCount then
  	self.ProgressTracker.Count:SetText(currentProgress);
  end
  ```
- **The Mount Journal (the Camelot-loaded Mainline file) uses the new Menu system: a DropdownButton inheriting WowStyle1FilterDropdownTemplate with resizeToText=false, anchored TOPRIGHT of the LeftInset.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:403-410`
  ```
  <DropdownButton parentKey="FilterDropdown" inherits="WowStyle1FilterDropdownTemplate">
  	<KeyValues><KeyValue key="resizeToText" type="boolean" value="false"/></KeyValues>
  	<Anchors><Anchor point="TOPRIGHT" relativeKey="$parent.LeftInset" x="-5" y="-10"/></Anchors>
  ```
- **Exact journal filter pattern: SetWidth(90), SetIsDefaultCallback, SetDefaultCallback, then SetupMenu with SetTag, CreateCheckbox(text, isSelected, setSelected[, data]), CreateSpacer, CreateTitle, and a CreateButton submenu holding CHECK_ALL/UNCHECK_ALL buttons plus per-index checkboxes.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:951-1006`
  ```
  self.FilterDropdown:SetIsDefaultCallback(function() return C_MountJournal.IsUsingDefaultFilters(); end);
  self.FilterDropdown:SetDefaultCallback(function() C_MountJournal.SetDefaultFilters(); end);
  self.FilterDropdown:SetupMenu(function(dropdown, rootDescription)
  	rootDescription:SetTag("MENU_MOUNT_COLLECTION_FILTER");
  	rootDescription:CreateCheckbox(COLLECTED, MountJournal_GetCollectedFilter, function() ... end);
  	...
  	local sourceSubmenu = rootDescription:CreateButton(SOURCES);
  	sourceSubmenu:CreateButton(CHECK_ALL, MountJournal_SetAllSourceFilters, true);
  ```
- **The Camelot-loaded Pet Journal (Classic file) uses the same SetIsDefaultCallback, SetDefaultCallback and SetupMenu pattern, but only with Collected/Not Collected checkboxes. It also hides the filter when the CVar onlyShowCollectedItemsInJournal is set.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:37-45,89-110`
  ```
  if C_CVar.GetCVarBool("onlyShowCollectedItemsInJournal") then
  	self.FilterDropdown:Hide();
  else
  	PetJournal_InitFilterDropdown(self);
  end
  ```
- **Radio sort pattern (Mainline pet journal, which Camelot does not load but shows the canonical usage): a 'Sort' submenu built from CreateRadio(text, isSelected, setSelected, value), plus CreateDivider and CreateTitle.**  
  `Blizzard_Collections/Shared/Blizzard_PetCollection.lua:180-182,208-212`
  ```
  local sortBySubmenu = rootDescription:CreateButton(RAID_FRAME_SORT_LABEL);
  sortBySubmenu:CreateRadio(NAME, IsSortByChecked, SetSortByChecked, LE_SORT_BY_NAME);
  ```
- **Bulk-toggle buttons return MenuResponse.Refresh so the open menu redraws its checkmarks without closing.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:938-941; Blizzard_Menu/MenuConstants.lua:17-23`
  ```
  function MountJournal_SetAllSourceFilters(value)
  	C_MountJournal.SetAllSourceFilters(value); 
  	return MenuResponse.Refresh;
  end
  ```
- **The WowStyle1FilterDropdownTemplate loaded for Camelot is the Mainline version. Its defaults: text = global FILTER, resizeToText = true with +60 padding, size 135x18. It includes a hidden ResetButton (UIResetButtonTemplate) centered on its TOPRIGHT corner.**  
  `Blizzard_Menu/Mainline/MenuTemplates.xml:66-88; Blizzard_Menu/Blizzard_Menu.toc:20-21`
  ```
  <KeyValue key="text" type="global" value="FILTER"/> ... <KeyValue key="resizeToText" type="boolean" value="true"/>
  <KeyValue key="resizeToTextPadding" type="number" value="60"/> ...
  <Button parentKey="ResetButton" inherits="UIResetButtonTemplate" hidden="true"><Anchors><Anchor point="CENTER" relativePoint="TOPRIGHT" x="-3" y="0"/>
  ```
- **How the red-X reset works: clicking ResetButton calls defaultCallback, hides itself and plays a sound. ValidateResetState shows it when isDefaultCallback() is false. It runs on OnShow, on OnMenuAssigned, and on OnMenuResponse (any pick), which also calls the optional SetUpdateCallback function.**  
  `Blizzard_Menu/MenuTemplates.lua:910-969`
  ```
  function WowDropdownFilterBehaviorMixin:ValidateResetState()
  	if self.isDefaultCallback then
  		self.ResetButton:SetShown(not self.isDefaultCallback());
  	end
  end
  ...
  function WowDropdownFilterBehaviorMixin:OnMenuResponse(menu, description)
  	self:ValidateResetState();
  	self:NotifyUpdate(description);
  end
  ```
- **UIResetButtonTemplate (the red X) lives in the always-loaded Mainline SharedUIPanelTemplates.xml.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:867-871`
  ```
  <Button name="UIResetButtonTemplate" hidden="true" virtual="true"><Size x="23" y="23"/><NormalTexture atlas="auctionhouse-ui-filter-redx" setAllPoints="true"/>
  ```
- **WowStyle1FilterDropdownMixin combines ButtonStateBehaviorMixin, DropdownTextMixin and WowFilterButtonMixin. Its fixed text is set with SetText. When resizeToText is true, UpdateText resizes the width on every update, including after each menu pick.**  
  `Blizzard_Menu/MenuTemplates.lua:1005,718-761`
  ```
  function DropdownTextMixin:UpdateText()
  	self.Text:SetText(self:GetUpdateText());
  	if self.resizeToText then
  		local newWidth = self.Text:GetUnboundedStringWidth(); ... self:SetWidth(newWidth);
  ```
- **In Lua the dropdown must be created as the 'DropdownButton' intrinsic, not as a 'Button'. The template's OnLoad asserts this.**  
  `Blizzard_Menu/11_0_0_MenuImplementationGuide.lua:104-110; Blizzard_Menu/DropdownButton.xml:3-17; Blizzard_Menu/DropdownButton.lua:9-11`
  ```
  local dropdown = CreateFrame("DropdownButton", nil, MyParentFrame, "WowStyle1DropdownTemplate");
  dropdown:SetDefaultText("My Dropdown");
  dropdown:SetupMenu(GeneratorFunction);
  ```
- **The generator runs again every time the menu opens, so it should read live state.**  
  `Blizzard_Menu/DropdownButton.lua:108-131,237-249`
  ```
  -- Always regenerate the menu. This is important to avoid bugs related to stale menu state.
  self:GenerateMenu();
  ```
- **Default responses: CreateCheckbox uses Refresh, so the menu stays open. CreateRadio and CreateButton set none, so the responder's return value decides. A nil response closes all menus.**  
  `Blizzard_Menu/MenuTemplates.lua:369-395; Blizzard_Menu/Menu.lua:2296-2307`
  ```
  elementDescription:SetCheckbox(true); ... elementDescription:SetResponse(MenuResponse.Refresh);
  ```
- **Responders are called with (data, menuInputData, menu), where data is the 4th argument passed to CreateCheckbox or CreateRadio, or the 3rd for CreateButton.**  
  `Blizzard_Menu/Menu.lua:888-894`
  ```
  return descriptionProxy.responder(descriptionProxy:GetData(), menuInputData, menuProxy);
  ```
- **Methods available on menu descriptions: CreateFrame, CreateTemplate, CreateButton, CreateTitle, CreateCheckbox, CreateRadio, CreateHighlightButton, CreateRedHighlightButton, CreateHighlightRadio, CreateDivider, CreateSpacer, CreateColorSwatch, CreateSearchEntry. Plus utilities SetTooltip, SetTitleAndTextTooltip, QueueTitle, QueueDivider, QueueSpacer.**  
  `Blizzard_Menu/MenuUtil.lua:84-96,275-289,337-343`
  ```
  MenuUtilPrivate.Inserters = { CreateFrame = ..., CreateButton = MenuUtil.CreateButton, CreateTitle = ..., CreateCheckbox = ..., CreateRadio = ..., CreateDivider = ..., CreateSpacer = ..., ... }
  ```
- **Long menus can scroll with SetScrollMode(maxExtent), which requires a number.**  
  `Blizzard_Menu/Menu.lua:227-231; Blizzard_Menu/11_0_0_MenuImplementationGuide.lua:345-351`
  ```
  function BaseMenuDescriptionMixin:SetScrollMode(maxScrollExtent)
  	assert(type(maxScrollExtent) == "number");
  ```
- **Blizzard_Menu is always loaded (LoadFirst, AllowLoad Both, and a dependency of Blizzard_SharedXML). Camelot swaps in Camelot\Menu.xml, which adds focus/gamepad frames, but the API is the same.**  
  `Blizzard_Menu/Blizzard_Menu.toc:1-22; Blizzard_SharedXML/Blizzard_SharedXML.toc:3`
  ```
  ## LoadFirst: 1
  ## AllowLoad: Both
  ...
  Menu.xml [ExcludeLoadGameType camelot]
  Camelot\Menu.xml [AllowLoadGameType camelot]
  ```
- **The legacy UIDropDownMenu is still loaded through the [Family] Mainline files but is not used by the journals.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:216-219`
  ```
  [Family]\UIDropDownMenu.lua
  [Family]\UIDropDownMenuTemplates.lua
  ```
- **The journals' 'Total: N' display is CollectionsCountTemplate: an InsetFrameTemplate3 (130x20) with a Count FontString (GameFontHighlightSmall, right-aligned) and a Label FontString (GameFontNormalSmall) taken from the labelText KeyValue. It is defined in load-on-demand Blizzard_Collections.**  
  `Blizzard_Collections/Shared/Blizzard_CollectionTemplates.xml:38-62; Blizzard_Collections/Shared/Blizzard_CollectionTemplates.lua:144-159`
  ```
  <Frame name="CollectionsCountTemplate" useParentLevel="true" inherits="InsetFrameTemplate3" virtual="true" mixin="CollectionsCountTemplateMixin">
  ```
- **Camelot sets the CENTER count style, which places the count at SetPoint("TOP", 16, -35). The journals set the value with .Count:SetText(n).**  
  `Blizzard_Collections/Camelot/Blizzard_CollectionsConstants.lua:6; Blizzard_Collections/Shared/Blizzard_CollectionTemplates.lua:156-158; Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:596,642`
  ```
  BLIZZARD_COLLECTIONS_COUNT_DISPLAY_STYLE = BLIZZARD_COLLECTIONS_COUNT_DISPLAY_STYLE_CENTER;
  ...
  MountJournal.MountCount.Count:SetText(MountJournal.numOwned);
  ```
- **CollectionsProgressBarTemplate is a StatusBar (196x13) with the UI-Character-Skills-Bar texture, a BarBorder texture, a black background and a .text FontString (TextStatusBarText). It is also in load-on-demand Blizzard_Collections.**  
  `Blizzard_Collections/Shared/Blizzard_CollectionTemplates.xml:4-36`
  ```
  <StatusBar name="CollectionsProgressBarTemplate" virtual="true"> ... <BarTexture file="Interface\PaperDollInfoFrame\UI-Character-Skills-Bar"/> <BarColor r="0.03125" g="0.85" b="0.0" />
  ```
- **How the progress bar is set: SetMinMaxValues(0, max), SetValue(cur), text:SetFormattedText(FORMAT, cur, max).**  
  `Blizzard_Collections/Mainline/Blizzard_HeirloomCollection.lua:657-663`
  ```
  self.progressBar:SetMinMaxValues(0, maxProgress);
  self.progressBar:SetValue(currentProgress);
  self.progressBar.text:SetFormattedText(HEIRLOOMS_PROGRESS_FORMAT, currentProgress, maxProgress);
  ```
- **Camelot deliberately swaps progress bars for counts: the Toy Box uses CollectionsCountTemplate (isCount) instead of the Mainline StatusBar, and the Wardrobe progress bar is hidden.**  
  `Blizzard_Collections/Camelot/Blizzard_ToyBoxProgressTracker.xml:4-9; Blizzard_Collections/Mainline/Blizzard_ToyBoxProgressTracker.xml:4-8; Blizzard_Collections/Camelot/Blizzard_Wardrobe.lua:14-21`
  ```
  <Frame name="ToyProgressTracker" inherits="CollectionsCountTemplate" virtual="true"><KeyValues><KeyValue key="isCount" value="true" type="boolean"/>
  ```
- **ColoredProgressBarTemplate is a Camelot-only Frame template in always-loaded Blizzard_SharedXML. Its API: SetFillPercent(0..1) (width-based), SetText, and SetFillTextureByColorType(Red/Green/Blue/White). The Forever Skills, Reputation and Pet XP bars use it.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:204-205; Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.xml:3-39; Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.lua:1-40; Blizzard_UIPanels_Game/Camelot/PaperDollFrame.lua:3643-3661`
  ```
  function ColoredProgressBarMixin:SetFillPercent(percent)
  	local p = math.min(1, math.max(0, percent));
  	self:SetFillWidth(p * self:GetWidth());
  	self.Fill:SetTexCoord(0, p, 1, 0);
  end
  ```
- **InsetFrameTemplate3 (the count box frame) is in Blizzard_UIPanelTemplates, which is always loaded as a dependency of Blizzard_FrameXML. A third-party addon can therefore rebuild CollectionsCountTemplate.**  
  `Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml:724; Blizzard_UIPanelTemplates/Blizzard_UIPanelTemplates.toc:9-10; Blizzard_FrameXML/Blizzard_FrameXML.toc:11`
  ```
  <Frame name="InsetFrameTemplate3" virtual="true">
  ```
- **UIPanelButtonTemplate (the classic red panel button) and MagicButtonTemplate (80x22, the journal's 'Mount' button) are always loaded. UIPanelButtonMixin:OnEnter shows self.tooltipText automatically and otherwise falls back to the disabled tooltip.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:315-320,749-754; Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:221-235; Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:568`
  ```
  if self.tooltipText then
  	local tooltip = GetAppropriateTooltip();
  	tooltip:SetOwner(self, self.tooltipAnchor or defaultTooltipAnchor);
  	GameTooltip_SetTitle(tooltip, self.tooltipText);
  ```
- **DisabledTooltipButtonMixin provides SetDisabledTooltip and SetDisabledState for tooltips on disabled buttons. The journal's MountButton uses motionScriptsWhileDisabled="true" so those tooltips can show.**  
  `Blizzard_SharedXML/SharedTooltipTemplates.lua:320-350; Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:568`
  ```
  function DisabledTooltipButtonMixin:SetDisabledState(disabled, disabledTooltip, disabledTooltipAnchor)
  	self:SetEnabled(not disabled);
  	self:SetDisabledTooltip(disabledTooltip, disabledTooltipAnchor);
  ```
- **SharedButtonSmallTemplate (138x28) is a modern red three-slice button ('128-RedButton' atlas). It is always loaded but looks different from the journals' UIPanelButtonTemplate.**  
  `Blizzard_SharedXML/Shared/Button/ThreeSliceButtonTemplate.xml:60-92`
  ```
  <Button name="SharedButtonSmallTemplate" inherits="BigRedThreeSliceButtonTemplate" virtual="true"><Size x="138" y="28"/>
  ```
- **Always-loaded check button templates: UICheckButtonTemplate (32x32, .Text plus a .text alias), MinimalCheckboxTemplate, CheckboxWithLabelTemplate (modern 'checkbox-minimal' art with .Text), and UIRadialButtonTemplate (modern radio).**  
  `Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml:26-89; Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:1071-1074`
  ```
  <CheckButton name="CheckboxWithLabelTemplate" inherits="MinimalCheckboxArtTemplate" virtual="true"> ... <FontString inherits="GameFontNormalSmall" parentKey="Text">
  ```
- **SettingsCheckboxTemplate lives in Blizzard_Settings_Shared, which is not load-on-demand and is reached through FrameXML, SettingsDefinitions_Frame, SettingsDefinitions_Shared and then Settings_Shared. It is driven by Init(value, tooltipFunc) plus an OnValueChanged callback, and shows SettingsTooltip.**  
  `Blizzard_Settings_Shared/Blizzard_SettingControls.xml:79-96; Blizzard_Settings_Shared/Blizzard_SettingControls.lua:557-585; Blizzard_SettingsDefinitions_Frame/Blizzard_SettingsDefinitions_Frame.toc:2; Blizzard_Settings_Shared/Blizzard_SettingsPanel.xml:115`
  ```
  function SettingsCheckboxMixin:Init(value, initTooltip)
  	self:SetValue(value);
  	self:SetTooltipFunc(initTooltip);
  	self:SetScript("OnClick", function(button) self:TriggerEvent(SettingsCheckboxMixin.Event.OnValueChanged, button:GetChecked()); end);
  ```
- **Tooltip helpers are always loaded: GameTooltip_SetTitle (clears lines), GameTooltip_AddNormalLine, AddHighlightLine, AddInstructionLine (green), AddErrorLine, AddDisabledLine, AddColoredLine, GameTooltip_AddBlankLineToTooltip, GetAppropriateTooltip() and GameTooltip_Hide.**  
  `Blizzard_SharedXML/SharedTooltipTemplates.lua:124-171; Blizzard_SharedXMLBase/FrameUtil.lua:318-320; Blizzard_GameTooltip/Mainline/GameTooltip.lua:627-631`
  ```
  function GameTooltip_SetTitle(tooltip, text, overrideColor, wrap)
  	tooltip:ClearLines();
  	GameTooltip_AddColoredLine(tooltip, text, overrideColor or HIGHLIGHT_FONT_COLOR, wrap)
  end
  ```
- **Journal count tooltip pattern: SetOwner ANCHOR_RIGHT, SetText in white, a wrapped AddLine, then Show.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:734-740`
  ```
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
  GameTooltip:SetText(BATTLE_PETS_TOTAL_PETS, 1, 1, 1);
  GameTooltip:AddLine(BATTLE_PETS_TOTAL_PETS_TOOLTIP, nil, nil, nil, true);
  ```
- **Menu elements can carry their own tooltip through the SetTooltip utility, called as func(tooltip, elementDescription).**  
  `Blizzard_Menu/MenuUtil.lua:299-304; Blizzard_Menu/11_0_0_MenuImplementationGuide.lua:317-320`
  ```
  local button = rootDescription:CreateButton("Button", OnClick);
  button:SetTooltip(function(tooltip, elementDescription)
  	GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
  ```
- **NewFeatureLabelTemplate is an always-loaded 'NEW' badge with a pulsing glow. Use NewFeatureLabelNoAnimateTemplate for no pulse. It is useful for newly seen NPCs.**  
  `Blizzard_SharedXML/NewFeatureLabel.xml:6-58; Blizzard_SharedXML/Blizzard_SharedXML.toc:61`
  ```
  <Frame name="NewFeatureLabelTemplate" inherits="ResizeLayoutFrame" mixin="NewFeatureLabelMixin" virtual="true" hidden="true">
  ```
- **SquareIconButtonTemplate and UIButtonMixin are always loaded. They support tooltipTitle and tooltipText fields, disabledTooltip, and SetOnClickHandler(fn, soundKit).**  
  `Blizzard_SharedXML/Shared/Button/IconButtonTemplate.xml:40-57; Blizzard_SharedXML/Shared/Button/UIButtonTemplate.lua:11-77`
  ```
  function UIButtonMixin:SetOnClickHandler(onClickHandler, onClickSoundKit)
  	self.onClickHandler = onClickHandler;
  ```
- **MIN_CHARACTER_SEARCH = 3 is a global constant. Blizzard search boxes skip searching below that length.**  
  `Blizzard_FrameXMLBase/Constants.lua:281; Blizzard_HousingTemplates/Blizzard_HousingCatalogFilters.lua:280-291`
  ```
  if numSearchChars >= MIN_CHARACTER_SEARCH then self:UpdateTextSearch(currentText); else self:UpdateTextSearch(""); end
  ```
- **issecretvalue() exists in this build. It can guard string operations on any NPC data that came from unit APIs while restrictions apply.**  
  `Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:287`
  ```
  Name = "issecretvalue",
  ```
