# BuddyDex slice: the window frame, portrait and title, insets, bottom and side tabs, Escape and drag handling, and Collections-style art for WoW Forever (Camelot, retail 12.x engine)

## Summary

All the frame building blocks BuddyDex needs are in always-loaded Blizzard code. Load order in this client is: Blizzard_SharedXML (Mainline family files plus Camelot overrides), then Blizzard_UIPanelTemplates, then Blizzard_UIParentPanelManager. Blizzard_FrameXML is LoadFirst and depends on the last two. So a third-party addon can use these directly:
- PortraitFrameTemplate, ButtonFrameTemplate, DefaultPanelTemplate and their Flat variants.
- PortraitFrameMixin and TitledPanelMixin (SetTitle, SetPortraitToAsset, SetPortraitTextureRaw, SetPortraitAtlasRaw, SetBorder).
- ButtonFrameTemplate_HidePortrait, ButtonFrameTemplate_HideButtonBar and ButtonFrameTemplate_HideAttic.
- InsetFrameTemplate (SharedXML) and InsetFrameTemplate2/3/4 (UIPanelTemplates).
- ShadowOverlayTemplate, and CollectionsBackgroundTemplate from SharedXML's Mainline SharedCollectionTemplates.
- PanelTabButtonTemplate with the PanelTemplates_* helpers.
- TabSystemTemplate with TabSystemOwnerTemplate.
- LargeSideTabButtonTemplate.
- PanelDragBarTemplate and ClickToDragTemplate.
- The Camelot-only ColoredProgressBarTemplate.

Camelot belongs to the "mainline" game-type family. The tocs gate many mainline lines with an explicit "[ExcludeLoadGameType camelot]", so [Family] resolves to Mainline\ and [Game] to Camelot\.

Blizzard_Collections is LoadOnDemand. Its Camelot variant does NOT use bottom tabs. The toc excludes Shared\Blizzard_CollectionsTabs.xml for camelot and loads Camelot\Blizzard_CollectionsTabs.xml instead. That file builds right-side icon tabs from LargeSideTabButtonTemplate, with BLIZZARD_COLLECTIONS_TAB_STYLE = SIDE. Clicks go through SetCustomOnMouseUpHandler, and selection uses tab:SetChecked() instead of PanelTemplates_SetTab. The Camelot CharacterFrame uses the same side-tab style.

Bottom text tabs are still the native Camelot style elsewhere:
- FriendsFrame (Camelot) uses PanelTabButtonTemplate with PanelTemplates_*.
- PlayerSpellsFrame (Camelot) uses PortraitFrameTemplate plus TabSystemOwnerTemplate, with a TabSystemTemplate anchored TOPLEFT to BOTTOMLEFT at (22, 2).

Escape and panels:
- UISpecialFrames is the safe Escape route. Escape runs ToggleGameMenu, then the registered CloseAllWindows handler, then CloseWindows, which calls securecall("CloseSpecialWindows"). That function hides every frame named in UISpecialFrames.
- ShowUIPanel and HideUIPanel refuse to run in combat for insecure callers (CheckProtectedFunctionsAllowed). UIPanelWindows registration ties the frame to Blizzard's left/center panel layout. Third-party frames should use plain Show/Hide plus UISpecialFrames.
- The stock close button's OnClick calls HideUIPanel, so override it with a plain Hide.

Art used by Collections:
- Main frame: Interface\FrameGeneral\UI-Background-Rock, the _UI-Frame-TopTileStreaks atlas, and the metal NineSlice layout "PortraitFrameTemplate". Camelot only adjusts the NineSlice offsets.
- Insets: Interface\FrameGeneral\UI-Background-Marble.
- Model pane: Interface\PetBattles\MountJournal-BG with TexCoord right = 0.78515625, plus ShadowOverlayTemplate.
- List rows: the PetList-ButtonBackground, PetList-ButtonSelect and PetList-ButtonHighlight atlases.
- Count box: InsetFrameTemplate3, centered at TOP (16, -35) in Camelot.

All texture files cited here exist in the BlizzardInterfaceArt export.

## Recommended approach

Build BuddyDex entirely from always-loaded templates: no XML, no dependency on Blizzard_Collections. The layout copies Camelot's PetJournal: a PortraitFrameTemplate window at 703x606, two InsetFrameTemplate panes, and the MountJournal-BG backdrop with ShadowOverlay. Use TabSystemTemplate for Dex/Buddy/Settings bottom text tabs, the way the Camelot PlayerSpellsFrame does. Close with plain Show/Hide plus UISpecialFrames, drag with PanelDragBarTemplate, and keep the position in SavedVariables.

```lua
-- BuddyDex / BuddyDexFrame.lua  (all templates: Blizzard_SharedXML / Blizzard_UIPanelTemplates, always loaded)
local DEX_NAME = "BuddyDexFrame"

-- 1) Window: portrait + title + close button + tab-owner behavior
local f = CreateFrame("Frame", DEX_NAME, UIParent, "PortraitFrameTemplate, TabSystemOwnerTemplate")
f:SetSize(703, 606)               -- CollectionsJournal size
f:SetFrameStrata("HIGH")
f:SetToplevel(true)
f:EnableMouse(true)
f:SetMovable(true)
f:SetClampedToScreen(true)
f:SetDontSavePosition(true)       -- we persist the position ourselves
f:Hide()

f:SetTitle("BuddyDex")
f:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Spyglass_03")   -- circle-masked automatically
-- per-NPC alternative: SetPortraitTextureFromCreatureDisplayID(f:GetPortrait(), displayID)

-- Close button: avoid UIPanelCloseButton_OnClick -> HideUIPanel (refused in combat when tainted)
f.CloseButton:SetScript("OnClick", function(btn) btn:GetParent():Hide() end)

-- Escape closes it: CloseAllWindows -> securecall("CloseSpecialWindows")
tinsert(UISpecialFrames, DEX_NAME)

f:SetScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
f:SetScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)

-- 2) Drag by the title strip only (keeps model-rotate and list clicks working) + remember position
local drag = CreateFrame("Button", nil, f, "PanelDragBarTemplate")  -- target = parent (f)
drag:SetPoint("TOPLEFT", f, "TOPLEFT", 58, 0)
drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -26, 0)
drag:SetHeight(22)
drag:HookScript("OnDragStop", function()       -- runs after StopMovingOrSizing
  local point, _, relPoint, x, y = f:GetPoint(1)
  BuddyDexDB = BuddyDexDB or {}
  BuddyDexDB.dexPos = { point, relPoint, x, y }
end)
local function RestoreDexPosition()
  f:ClearAllPoints()
  local p = BuddyDexDB and BuddyDexDB.dexPos
  if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else f:SetPoint("CENTER") end
end
-- call RestoreDexPosition() on PLAYER_LOGIN (after SavedVariables load)

-- 3) Pages (the tab owner shows exactly one)
local function NewPage() local p = CreateFrame("Frame", nil, f); p:SetAllPoints(); return p end
f.DexPage, f.BuddyPage, f.SettingsPage = NewPage(), NewPage(), NewPage()
local page = f.DexPage

-- 4) Dex page layout = Camelot PetJournal (Classic/Blizzard_PetCollection.xml:150-203)
local left = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
left:SetWidth(260)
left:SetPoint("TOPLEFT", 4, -60)
left:SetPoint("BOTTOMLEFT", 4, 26)
page.LeftInset = left

local right = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
right:SetPoint("TOPRIGHT", -6, -60)
right:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 20, 0)
page.RightInset = right

local card = CreateFrame("Frame", nil, right)
card:SetPoint("TOPLEFT", 3, -3); card:SetPoint("BOTTOMRIGHT", -3, 3)
card.Bg = card:CreateTexture(nil, "BACKGROUND")
card.Bg:SetAllPoints()
card.Bg:SetTexture("Interface\\PetBattles\\MountJournal-BG")
card.Bg:SetTexCoord(0, 0.78515625, 0, 1)
-- create the ModelScene here (child of card), THEN the shadow so it draws on top:
card.Shadow = CreateFrame("Frame", nil, card, "ShadowOverlayTemplate")
card.Shadow:SetAllPoints()
page.Card = card

local search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
search:SetSize(145, 20)
search:SetPoint("TOPLEFT", left, "TOPLEFT", 15, -9)
-- filter dropdown (WowStyle1FilterDropdownTemplate) goes at TOPRIGHT of left, (-5, -10)
-- list ScrollBox goes at left (3, -36) / (-2, 3)

-- "N/M seen" box, Camelot-centered like CollectionsCountTemplate (InsetFrameTemplate3 is always loaded)
local count = CreateFrame("Frame", nil, page, "InsetFrameTemplate3")
count:SetSize(130, 20)
count:SetPoint("TOP", 16, -35)
count.Label = count:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
count.Label:SetPoint("LEFT", 10, 0); count.Label:SetText("Seen")
count.Count = count:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
count.Count:SetPoint("RIGHT", -10, 0)
page.Count = count
-- (alt, Camelot-only: CreateFrame("Frame", nil, page, "ColoredProgressBarTemplate"):SetFillPercent(n/m))

-- action buttons under the model: MagicButtonTemplate with explicit offsets (MagicButton_OnLoad already ran)
local act = CreateFrame("Button", nil, page, "MagicButtonTemplate")
act:SetSize(160, 22); act:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 4); act:SetText("Mark Caught")

-- 5) Bottom tabs: TabSystemTemplate (Camelot PlayerSpellsFrame pattern)
local ts = CreateFrame("Frame", nil, f, "TabSystemTemplate")
ts.minTabWidth, ts.maxTabWidth = 100, 150     -- set before AddTab
ts:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 22, 2)
f.TabSystem = ts
f:SetTabSystem(ts)
f.DexTabID      = f:AddNamedTab("Dex", f.DexPage)
f.BuddyTabID    = f:AddNamedTab("Buddy", f.BuddyPage)
f.SettingsTabID = f:AddNamedTab("Settings", f.SettingsPage)
f:SetTabCallback(f.DexTabID,      function() f:SetTitle("BuddyDex") end)
f:SetTabCallback(f.BuddyTabID,    function() f:SetTitle("Buddy") end)
f:SetTabCallback(f.SettingsTabID, function() f:SetTitle("Settings") end)
f:SetTab(f.DexTabID)

function BuddyDex_ToggleDex() f:SetShown(not f:IsShown()) end   -- never ShowUIPanel
```

Alternative A: classic PanelTabButtonTemplate tabs, as in the Camelot FriendsFrame. Create the window with "PortraitFrameTemplate" only.
```lua
local names = { "Dex", "Buddy", "Settings" }
local pages = { f.DexPage, f.BuddyPage, f.SettingsPage }
local function SelectTab(id)
  PanelTemplates_SetTab(f, id)
  for i, p in ipairs(pages) do p:SetShown(i == id) end
end
for i, text in ipairs(names) do
  local tab = CreateFrame("Button", DEX_NAME.."Tab"..i, f, "PanelTabButtonTemplate") -- name = GetTabByIndex fallback
  tab:SetID(i); tab:SetText(text)
  tab:SetScript("OnClick", function(self) SelectTab(self:GetID()); PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end)
  PanelTemplates_TabResize(tab, 0)
end
_G[DEX_NAME.."Tab1"]:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 5, 2)  -- only tab 1; SetNumTabs anchors 2..n
PanelTemplates_SetNumTabs(f, #names)
SelectTab(1)
```

Alternative B: Camelot Collections-style right-side icon tabs.
```lua
local rail = CreateFrame("Frame", nil, f)
rail:SetWidth(55)
rail:SetPoint("TOPLEFT", f, "TOPRIGHT"); rail:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT")
rail.Tabs = {}
local icons = { "Interface\\Icons\\INV_Misc_Spyglass_03", "Interface\\Icons\\Ability_Hunter_BeastTraining", "Interface\\Icons\\INV_Misc_Book_09" }
local SelectSideTab
for i, text in ipairs({ "Dex", "Buddy", "Settings" }) do
  local tab = CreateFrame("Frame", nil, rail, "LargeSideTabButtonTemplate")
  tab:SetID(i); tab.tooltipText = text
  tab.Icon:SetTexture(icons[i]); tab:SetFillToInterior(true)    -- else Icon has no size
  tab:SetCustomOnMouseUpHandler(function(t, button, upInside)
    if button == "LeftButton" and upInside then SelectSideTab(t:GetID()) end   -- mixin already plays the tab sound
  end)
  tab:SetPoint("TOPLEFT", i == 1 and rail or rail.Tabs[i-1], i == 1 and "TOPLEFT" or "BOTTOMLEFT", 0, i == 1 and -60 or -2)
  rail.Tabs[i] = tab
end
SelectSideTab = function(id)
  for _, t in ipairs(rail.Tabs) do t:SetChecked(t:GetID() == id) end
  -- show/hide pages + f:SetTitle(...)
end
SelectSideTab(1)
```

The side rail sits outside the 703px frame. The Blizzard panel manager budgets 733px for CollectionsJournal, so leave about 30px of right-hand screen room.

## Pitfalls

- Do not reuse anything defined only in Blizzard_Collections from a third-party addon: CollectionsJournal, CollectionsJournalTab, CollectionsJournalTabContainer, CollectionsCountTemplate, CollectionsProgressBarTemplate, CollectionsSpellButtonTemplate and the CollectionsJournal_* functions. The addon is LoadOnDemand (Blizzard_Collections.toc:3). Camelot also rewrites the global CollectionsJournal_SetTab_Internal and related wrappers (Camelot/Blizzard_CollectionsOverrides.lua:21-50), and they are hard-wired to the CollectionsJournal frame. Recreate the look from SharedXML templates instead.
- In this client CollectionsJournal does NOT use bottom tabs. The Camelot build swaps in right-side LargeSideTabButtonTemplate icon tabs (toc lines 22-23, Camelot/Blizzard_CollectionsTabs.xml). Bottom text tabs are still native Camelot style (FriendsFrame, PlayerSpellsFrame). Pick deliberately: bottom tabs match the requested design; side tabs match Collections.
- PanelTemplates_* only works with tabs that have Text, Left, Middle, Right, LeftActive, MiddleActive and RightActive keys, which means PanelTabButtonTemplate. LargeSideTabButtonTemplate is a Frame with no OnClick and none of those keys; Camelot had to override the wrappers to use SetChecked. Drive side tabs with SetCustomOnMouseUpHandler and SetChecked.
- PanelTemplates_SetNumTabs must run before PanelTemplates_SetTab, because UpdateTabs loops over frame.numTabs. SetNumTabs anchors only tabs 2..n, so anchor tab 1 yourself. PanelTemplates_SelectTab disables the selected tab, so it gets no further OnClick.
- PanelTabButtonTemplate declares parentArray="Tabs". GetTabByIndex prefers frame.Tabs and falls back to the global <FrameName>Tab<i>. Name the tabs that way so lookups work whether or not parentArray filled f.Tabs. Run /dump #BuddyDexFrame.Tabs once in game to confirm.
- PanelTabButtonMixin:OnShow resizes using the PARENT's tabPadding, minTabWidth and maxTabWidth. Set those fields on the frame the tabs are parented to, not on the tabs.
- TabSystemTemplate: set ts.minTabWidth and maxTabWidth before AddTab. The owner must be created WITH TabSystemOwnerTemplate so its OnLoad builds internalTabTracker; adding the mixin after CreateFrame is too late. Create the page frames before AddNamedTab. TabSystem uses CreateFramePool, which aliases the secure, proxy-based pool (Blizzard_SharedXMLBase/Pools.lua:857); that is addon-safe but harder to inspect.
- The stock close button (UIPanelCloseButton_OnClick) calls HideUIPanel. If the call path is tainted in combat, CheckProtectedFunctionsAllowed blocks it with 'Interface action blocked'. Setting parent.onCloseCallback from addon code introduces exactly that taint. Override CloseButton's OnClick with a plain :Hide().
- Do not open BuddyDex with ShowUIPanel, ToggleUIPanel or SetUIPanelShown, and do not add it to UIPanelWindows or RegisterUIPanel. Addon calls are refused in combat (UIParentPanelManager.lua:853-888). The frame would also join Blizzard's left/center layout and get pushed, repositioned or closed alongside Character, Collections and other panels by a forbidden delegate. Plain Show/Hide works in combat for an unprotected frame.
- Escape: use tinsert(UISpecialFrames, "GlobalFrameName"); the frame MUST have a global name, since CloseSpecialWindows does _G[value]. Avoid RegisterGameMenuEscHandler: every registrant in the export is Blizzard code, and an insecure insert/table.sort into its handler list risks tainting the Escape chain (this is an inference, not tested). Avoid OnKeyDown plus SetPropagateKeyboardInput, which is flagged HasRestrictions.
- Keep the window unprotected. Show, Hide, StartMoving and StopMovingOrSizing are flagged IsProtectedFunction and become combat-blocked if the frame or a child is protected. Never place secure templates in it, for example CollectionsSpellButtonTemplate, which inherits SecureFrameTemplate (Shared/Blizzard_CollectionTemplates.xml:64), or SecureActionButtonTemplate.
- Frame levels: the NineSlice border is at +500, the portrait at +400, title and close at +510. Content frames get parent+1 by default and correctly draw under the border. Do not raise content above about 499. If you re-level the window, use PortraitFrameMixin:SetFrameLevelsFromBaseLevel.
- MagicButtonTemplate: MagicButton_OnLoad applies its 4/4 and -6/4 corner offsets only to anchors that exist during OnLoad. With CreateFrame there are none yet, so give explicit offsets or call MagicButton_OnLoad(btn) after SetPoint.
- LargeSideTabButtonTemplate's Icon has no size. Call tab:SetFillToInterior(true) (50px, trimmed texcoords) or tab.Icon:SetSize(); otherwise the icon is invisible. The tab size comes from C_Texture.GetAtlasInfo("common-sidetab").
- PanelDragBarMixin runs onDragStopCallback BEFORE StopMovingOrSizing. Save the position in a HookScript('OnDragStop') instead. StartMoving can also mark the frame user-placed in the client layout cache; SetDontSavePosition(true) plus your own SavedVariables avoids a conflict between the two sources. Client layout-cache behavior cannot be verified from the Lua export.
- Use [Family]=Mainline definitions. Classic\ files load for Camelot only where a line explicitly tags camelot. Example: Blizzard_Collections/Classic/Blizzard_CollectionTemplates.xml has its own CollectionsBackgroundTemplate that does NOT load; use the SharedXML Mainline one.
- Atlas names (common-sidetab, uiframe-tab-*, PetList-*, collections-background-*, common-stat-bar-*) live in client DB data, not in the exported Lua/XML. Camelot may remap them to Forever art. Check at runtime with C_Texture.GetAtlasInfo before relying on exact pixel sizes.
- Blizzard_GlueCollections is AllowLoad: Glue (login screen only), so nothing in it is usable in game.
- The PortraitFrameTemplate portrait is always circle-masked (TempPortraitAlphaMask). Square icons get cropped to a circle; use SetPortraitAtlasRaw or SetPortraitTexCoord to tune. SetPortraitToUnit only accepts unit tokens; for roster NPCs use SetPortraitTextureFromCreatureDisplayID with a stored displayID.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **Camelot counts as the 'mainline' game type, so [Family] resolves to Mainline\ and [Game] to Camelot\. Blizzard_Collections' toc only allows wrath, cata, mists and mainline, yet it has camelot-specific lines. It must explicitly exclude camelot from mainline-allowed lines.**  
  `Blizzard_Collections/Blizzard_Collections.toc:13`
  ```
  ## AllowLoadGameType: wrath, cata, mists, mainline ... (line 30) Shared\Blizzard_PetCollection.lua [AllowLoadGameType mists, mainline] [ExcludeLoadGameType camelot]
  ```
- **The same Mainline-vs-Camelot override pattern appears in Blizzard_UIPanels_Game, confirming that [Family] means Mainline for this client.**  
  `Blizzard_UIPanels_Game/Blizzard_UIPanels_Game.toc:44`
  ```
  [Family]\CharacterFrame.lua [AllowLoadGameType mainline] [ExcludeLoadGameType camelot] / [Game]\CharacterFrame.lua [AllowLoadGameType camelot]
  ```
- **The Camelot project ID is 18.**  
  `Blizzard_ProjectConstants/Camelot/ProjectConstants.lua:1`
  ```
  WOW_PROJECT_CAMELOT = 18; WOW_PROJECT_ID = WOW_PROJECT_CAMELOT;
  ```
- **Blizzard_Collections (CollectionsJournal, CollectionsCountTemplate, CollectionsJournalTab...) is load-on-demand. Third-party code must not rely on it unless it calls C_AddOns.LoadAddOn first.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3`
  ```
  ## LoadOnDemand: 1
  ```
- **Blizzard_FrameXML is LoadFirst and depends on Blizzard_UIParentPanelManager and Blizzard_UIPanelTemplates, so both are always loaded in game. Blizzard_SharedXML is AllowLoad: Both and has no LoadOnDemand.**  
  `Blizzard_FrameXML/Blizzard_FrameXML.toc:5`
  ```
  ## Dep: Blizzard_UIParentPanelManager [AllowLoadGameType mainline] ... ## Dep: Blizzard_UIPanelTemplates ... ## LoadFirst: 1
  ```
- **SharedXML loads the Mainline panel-template Lua, then a Camelot override, then PortraitFrame.lua, then the Mainline panel-template XML. These are the always-available definitions.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:190`
  ```
  [Family]\SharedUIPanelTemplates.lua / Camelot\SharedUIPanelTemplates.lua [AllowLoadGameType camelot] / PortraitFrame.lua / [Family]\SharedUIPanelTemplates.xml
  ```
- **PortraitFrameBaseTemplate provides a NineSlice border, a 62x62 portrait texture masked to a circle (PortraitContainer.portrait, TempPortraitAlphaMask) and TitleContainer.TitleText. Its default size is 338x424.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:566`
  ```
  <Frame name="PortraitFrameBaseTemplate" mixin="PortraitFrameMixin, FocusFramesInterfaceMixin" virtual="true"> ... <Texture name="$parentPortrait" parentKey="portrait"><Size x="62" y="62"/> ... <MaskTexture parentKey="CircleMask" file="Interface\CharacterFrame\TempPortraitAlphaMask"
  ```
- **PortraitFrameTexturedBaseTemplate adds the rock background and the top tile streaks. PortraitFrameTemplate adds a CloseButton on top of that.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:624`
  ```
  <Texture name="$parentBg" file="Interface\FrameGeneral\UI-Background-Rock" ... parentKey="Bg"> ... <Texture parentKey="TopTileStreaks" inherits="_UI-Frame-TopTileStreaks"> ... (658) <Frame name="PortraitFrameTemplate" inherits="PortraitFrameTemplateNoCloseButton"> <Button name="$parentCloseButton" parentKey="CloseButton" inherits="UIPanelCloseButtonDefaultAnchors"/>
  ```
- **Flat variants (PortraitFrameFlatTemplate, DefaultPanelFlatTemplate) use FlatPanelBackgroundTemplate instead of rock art. DefaultPanelTemplate is a titled panel with no portrait (layoutType ButtonFrameTemplateNoPortrait).**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:478`
  ```
  <Frame name="DefaultPanelBaseTemplate" mixin="DefaultPanelMixin, FocusFramesInterfaceMixin" virtual="true"><KeyValues><KeyValue key="layoutType" value="ButtonFrameTemplateNoPortrait" .../> ... (670) <Frame name="PortraitFrameFlatTemplate" inherits="PortraitFrameFlatBaseTemplate" virtual="true">
  ```
- **ButtonFrameTemplate is PortraitFrameBase plus a close button plus an Inset (InsetFrameTemplate) at TOPLEFT (4, -60) / BOTTOMRIGHT (-6, 26). That leaves a 60px 'attic' for search/filter and a 26px button bar.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:711`
  ```
  <Frame name="ButtonFrameTemplate" inherits="ButtonFrameBaseTemplate" virtual="true"> <Frame name="$parentInset" parentKey="Inset" useParentLevel="true" inherits="InsetFrameTemplate"> <Anchor point="TOPLEFT" x="4" y="-60" /> <Anchor point="BOTTOMRIGHT" x="-6" y="26" />
  ```
- **Title API comes from TitledPanelMixin, which both PortraitFrameMixin and DefaultPanelMixin inherit: SetTitle, SetTitleFormatted, SetTitleColor, SetTitleOffsets and GetTitleText.**  
  `Blizzard_SharedXML/PortraitFrame.lua:2`
  ```
  TitledPanelMixin = {}; ... function TitledPanelMixin:SetTitle(title) self:GetTitleText():SetText(title); end ... PortraitFrameMixin = CreateFromMixins(TitledPanelMixin);
  ```
- **Portrait API on PortraitFrameMixin: GetPortrait, SetPortraitToAsset, SetPortraitToUnit, SetPortraitTextureRaw, SetPortraitAtlasRaw, SetPortraitToClassIcon, SetPortraitTexCoord, SetPortraitShown, SetPortraitTextureSizeAndOffset, SetBorder(layoutName) and SetFrameLevelsFromBaseLevel.**  
  `Blizzard_SharedXML/PortraitFrame.lua:34`
  ```
  function PortraitFrameMixin:SetPortraitToAsset(texture) self:GetPortrait():SetTexture(texture); end ... function PortraitFrameMixin:SetPortraitAtlasRaw(atlas, ...) self:GetPortrait():SetAtlas(atlas, ...); end
  ```
- **Frame levels are fixed by layer: NineSlice is base+500, PortraitContainer base+400, TitleContainer and CloseButton base+510. Content must stay below 500 or it draws over the metal border.**  
  `Blizzard_SharedXML/PortraitFrame.lua:110`
  ```
  SetFrameLevelInternal(self.NineSlice, baseLevel + 500); SetFrameLevelInternal(self.PortraitContainer, baseLevel + 400); SetFrameLevelInternal(self.TitleContainer, baseLevel + 510); SetFrameLevelInternal(self.CloseButton, baseLevel + 510);
  ```
- **The always-loaded helpers ButtonFrameTemplate_HidePortrait/ShowPortrait swap the NineSlice layout and re-anchor Bg, Inset and title. HideButtonBar/ShowButtonBar and HideAttic/ShowAttic move the Inset edges.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:111`
  ```
  function ButtonFrameTemplate_HidePortrait(self) self:SetBorder("ButtonFrameTemplateNoPortrait"); self:SetPortraitShown(false); ... ButtonFrameTemplate_UpdateAnchors(self, isPortraitMode);
  ```
- **The stock close button's OnClick routes through HideUIPanel and honors an optional parent.onCloseCallback veto.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:150`
  ```
  function UIPanelCloseButton_OnClick(self) local parent = self:GetParent(); ... if parent.onCloseCallback then continueHide = parent.onCloseCallback(self); end if continueHide then HideUIPanel(parent); end
  ```
- **Camelot overrides the close-button anchor to TOPRIGHT (-2, 1); Mainline uses (1, 0). Camelot also shifts the side-tab icon because its tab art is wider.**  
  `Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua:3`
  ```
  function UIPanelCloseButtonDefaultAnchorsMixin:OnLoad() self:SetPoint("TOPRIGHT", -2, 1); end ... function SidePanelTabButtonMixin:GetIconAnchorOffsetsForTabArt() return -4, 0; end
  ```
- **The portrait frame border is the NineSlice layout 'PortraitFrameTemplate' (UI-Frame-PortraitMetal and UI-Frame-Metal atlases). Camelot keeps the atlas names and only adjusts offsets for its own art.**  
  `Blizzard_SharedXML/Mainline/NineSliceLayouts.lua:17`
  ```
  PortraitFrameTemplate = { disableSharpening = true, TopLeftCorner = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16, }, ...
  ```
- **Camelot NineSlice offset overrides are applied to every layout at load.**  
  `Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua:49`
  ```
  -- In some places the art made for Camelot doesn't match the exact size of the Mainline Standard art ... for _layoutName, layout in pairs(NineSliceLayouts) do ApplyOffsetOverrides(layout); end
  ```
- **InsetFrameTemplate (always loaded) has a marble background plus the InsetFrameTemplate NineSlice. useParentLevel keeps it at the parent's level.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:389`
  ```
  <Frame name="InsetFrameTemplate" useParentLevel="true" virtual="true"> ... <Texture parentKey="Bg" file="Interface\FrameGeneral\UI-Background-Marble" horizTile="true" vertTile="true" setAllPoints="true"/> ... <Frame parentKey="NineSlice" useParentLevel="true" inherits="NineSlicePanelTemplate"/>
  ```
- **InsetFrameTemplate2/3/4 live in always-loaded Blizzard_UIPanelTemplates. InsetFrameTemplate3 is the dark input-border box that the Collections count box uses.**  
  `Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml:724`
  ```
  <Frame name="InsetFrameTemplate3" virtual="true"> ... <Texture parentKey="BorderTopRight" file="Interface\Common\Common-Input-Border">
  ```
- **CollectionsJournal is a PortraitFrameTemplate frame, 703x606, frameStrata HIGH, toplevel, centered, with a TabContainer child.**  
  `Blizzard_Collections/Shared/Blizzard_Collections.xml:4`
  ```
  <Frame name="CollectionsJournal" inherits="PortraitFrameTemplate" mixin="CollectionsJournalMixin" toplevel="true" frameStrata="HIGH" enableMouse="true" parent="UIParent" hidden="true"> <Size x="703" y="606"/> ... <Frame parentKey="TabContainer" inherits="CollectionsJournalTabContainer"/>
  ```
- **For Camelot, the bottom-tab XML is excluded and replaced by the Camelot tab XML.**  
  `Blizzard_Collections/Blizzard_Collections.toc:22`
  ```
  Shared\Blizzard_CollectionsTabs.xml [ExcludeLoadGameType camelot] / [Game]\Blizzard_CollectionsTabs.xml [AllowLoadGameType camelot]
  ```
- **Camelot CollectionsJournal tabs are right-side icon tabs (LargeSideTabButtonTemplate) in a 55px-wide container anchored to the journal's right edge. Each tab has a tooltipText.**  
  `Blizzard_Collections/Camelot/Blizzard_CollectionsTabs.xml:4`
  ```
  <Button name="CollectionsJournalTab" inherits="LargeSideTabButtonTemplate" parentArray="Tabs" mixin="CollectionsJournalTabMixin" virtual="true"> <KeyValue key="fillToInterior" value="true" type="boolean"/> ... <Frame name="CollectionsJournalTabContainer" virtual="true"> <Size x="55" y="1"/> <Anchor point="TOPLEFT" relativePoint="TOPRIGHT"/>
  ```
- **The Camelot constants force side-tab style and a centered count display.**  
  `Blizzard_Collections/Camelot/Blizzard_CollectionsConstants.lua:4`
  ```
  BLIZZARD_COLLECTIONS_TAB_STYLE = BLIZZARD_COLLECTIONS_TAB_STYLE_SIDE; BLIZZARD_COLLECTIONS_COUNT_DISPLAY_STYLE = BLIZZARD_COLLECTIONS_COUNT_DISPLAY_STYLE_CENTER;
  ```
- **In Camelot a side tab is clicked via SetCustomOnMouseUpHandler and gets its icon from TABS_DATA. Selection uses SetChecked, so PanelTemplates_* is not used.**  
  `Blizzard_Collections/Camelot/Blizzard_CollectionsOverrides.lua:3`
  ```
  function CollectionsJournalTabMixin:OnLoad() SidePanelTabButtonMixin.OnLoad(self); self:SetCustomOnMouseUpHandler(function(tab, button, upInside) if button == "LeftButton" and upInside then CollectionsJournal_ClickTab(self); end end); end ... function CollectionsJournal_SetTab_Internal(tabContainer, selectedTabID) ... tab:SetChecked(isSelected);
  ```
- **Shared tab-switch flow: ClickTab, then SetTab (stores the petJournalTab CVar), then UpdateSelectedTab. UpdateSelectedTab shows exactly one sub-frame, sets the window title for that tab and fires an EventRegistry event.**  
  `Blizzard_Collections/Shared/Blizzard_Collections.lua:3`
  ```
  function CollectionsJournal_ClickTab(self) CollectionsJournal_SetTab(CollectionsJournal, self:GetID()); PlaySound(SOUNDKIT.UI_TOYBOX_TABS); end ... (103) MountJournal:SetShown(selectedID == 1); PetJournal:SetShown(selectedID == 2); ... self:SetTitle(self:GetPageTitleText(selectedID));
  ```
- **Tab anchoring: side tabs start at (0, -60) in the container with 2px vertical gaps. Bottom tabs start at (11, 2) and continue LEFT to RIGHT with a 3px gap.**  
  `Blizzard_Collections/Shared/Blizzard_Collections.lua:127`
  ```
  if(BLIZZARD_COLLECTIONS_TAB_STYLE == BLIZZARD_COLLECTIONS_TAB_STYLE_SIDE) then tab:SetPoint("TOPLEFT", previousShownTab, "BOTTOMLEFT", 0, -2); else tab:SetPoint("LEFT", previousShownTab, "RIGHT", 3, 0); end ... tab:SetPoint("TOPLEFT", CollectionsJournal.TabContainer, "TOPLEFT", 0, -60);
  ```
- **Non-Camelot (Shared) Collections tab wrappers use PanelTemplates_SetTab, GetSelectedTab, ShowTab, HideTab and SetNumTabs, with PanelTabButtonTemplate tabs in a container hanging below the frame.**  
  `Blizzard_Collections/Shared/Blizzard_Collections.lua:51`
  ```
  function CollectionsJournal_SetTab_Internal(tabContainer, tab) PanelTemplates_SetTab(tabContainer, tab); end ... function CollectionsJournal_SetNumTabs_Internal(tabContainer, numTabs) PanelTemplates_SetNumTabs(tabContainer, numTabs); end
  ```
- **Journal OnLoad sets the title, configures tabs, sets the tab count and restores the last tab from a CVar.**  
  `Blizzard_Collections/Shared/Blizzard_Collections.lua:151`
  ```
  function CollectionsJournal_OnLoad(self) self:SetTitle(COLLECTIONS); self:SetupTabs(); CollectionsJournal_SetNumTabs_Internal(self.TabContainer, #self.TabContainer.Tabs); CollectionsJournal_SetTab_Internal(self.TabContainer, tonumber(GetCVar("petJournalTab")) or 1); end
  ```
- **PanelTabButtonTemplate (always loaded) is a bottom tab built from the uiframe-tab-* and uiframe-activetab-* atlases. It auto-appends to parent.Tabs (parentArray) and has no OnClick of its own.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:932`
  ```
  <Button name="PanelTabButtonTemplate" mixin="PanelTabButtonMixin" motionScriptsWhileDisabled="true" parentArray="Tabs" virtual="true" > <Size x="10" y="32"/> ... atlas="uiframe-activetab-left" ... atlas="_uiframe-tab-center"
  ```
- **PanelTabButtonMixin auto-resizes each tab on show using the parent's tabPadding, minTabWidth and maxTabWidth fields.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:262`
  ```
  function PanelTabButtonMixin:OnShow() PanelTemplates_TabResize(self, self:GetParent().tabPadding, nil, self:GetParent().minTabWidth, self:GetParent().maxTabWidth); end
  ```
- **PanelTemplates helpers find tabs through frame.Tabs[i], falling back to the global <FrameName>Tab<i>. SetTab stores selectedTab and refreshes visuals. UpdateTabs only iterates frame.numTabs, which SetNumTabs sets.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:439`
  ```
  function PanelTemplates_SetTab(frame, id) frame.selectedTab = id; PanelTemplates_UpdateTabs(frame); end ... local function GetTabByIndex(frame, index) return frame.Tabs and frame.Tabs[index] or envTable[frame:GetName().."Tab"..index]; end
  ```
- **PanelTemplates_SetNumTabs anchors only tabs 2..n, each to the previous tab (TOPLEFT to TOPRIGHT, +3). Tab 1 must be anchored manually.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:540`
  ```
  function PanelTemplates_SetNumTabs(frame, numTabs) frame.numTabs = numTabs; PanelTemplates_AnchorTabs(frame); end function PanelTemplates_AnchorTabs(frame, numTabs) for i = 2, frame.numTabs do ... thisTab:SetPoint("TOPLEFT", lastTab, "TOPRIGHT", 3, 0);
  ```
- **Other helpers: TabResize, ResizeTabsToFit, Enable/DisableTab, SetTabEnabled, Show/HideTab, SetTabShown, GetSelectedTab. SelectTab disables the selected tab button and swaps to the active art.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:616`
  ```
  function PanelTemplates_SelectTab(tab) tab.Left:Hide(); tab.Middle:Hide(); tab.Right:Hide(); tab:Disable(); tab:SetDisabledFontObject(GameFontHighlightSmall); ... tab.LeftActive:Show();
  ```
- **Camelot FriendsFrame is a working in-client example of bottom tabs: ButtonFrameTemplate plus PanelTabButtonTemplate, Tab1 anchored to the frame's bottom-left, then PanelTemplates_SetNumTabs, PanelTemplates_UpdateTabs and an OnClick that calls PanelTemplates_Tab_OnClick.**  
  `Blizzard_FriendsFrame/Camelot/FriendsFrame.xml:822`
  ```
  <Button name="FriendsFrameTab1" inherits="FriendsFrameTabTemplate" id="1" text="CONTACTS_TAB_TITLE" collapsesLayout="true"> <Anchor point="TOPLEFT" relativePoint="BOTTOMLEFT" x="5" y="2"/>  [Camelot/FriendsFrame.lua:284 PanelTemplates_SetNumTabs(self, FRIEND_TAB_COUNT); :677 PanelTemplates_Tab_OnClick(self, FriendsFrame);]
  ```
- **LargeSideTabButtonTemplate (always loaded) is a Frame, not a Button. It has common-sidetab, -selected, -hover and -mask art plus a masked Icon with no fixed size, and is clicked via OnMouseDown/OnMouseUp.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:1008`
  ```
  <Frame name="LargeSideTabButtonTemplate" mixin="SidePanelTabButtonMixin" virtual="true"> ... <Texture parentKey="Background" atlas="common-sidetab" useAtlasSize="true"> ... <Texture parentKey="Icon"> <!-- Anchored in SidePanelTabButtonMixin:InitializeIconAnchoring because Camelot tabs are wider -->
  ```
- **SidePanelTabButtonMixin API: SetChecked (shows SelectedTexture), SetCustomOnMouseUpHandler, SetFillToInterior (sizes the icon, default 50px) and a tooltip from self.tooltipText. OnMouseUp plays IG_CHARACTER_INFO_TAB.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:359`
  ```
  function SidePanelTabButtonMixin:OnMouseUp(button, upInside) if button == "LeftButton" then ... PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB); end if self.customMouseUpHandler then self.customMouseUpHandler(self, button, upInside); end end
  ```
- **The Camelot CharacterFrame uses the same side-tab style: LargeSideTabButtonTemplate tabs with fillToInterior, in a container anchored to the frame's TOPRIGHT.**  
  `Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml:394`
  ```
  <Frame name="CharacterFrameModeSideTabTemplate" inherits="LargeSideTabButtonTemplate" mixin="CharacterModeTabButtonMixin" virtual="true"> ... (568) <Frame name="CharacterFrameModeTabs" parentKey="ModeTabs"> <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" y="-30"/>
  ```
- **TabSystemTemplate (always loaded except on vanilla and tbc) is a HorizontalLayoutFrame that pools TabSystemButtonTemplate tabs. Its KeyValues are minTabWidth, maxTabWidth, tabSelectSound and tabTemplate.**  
  `Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.xml:144`
  ```
  <Frame name="TabSystemTemplate" mixin="TabSystemMixin" inherits="HorizontalLayoutFrame" virtual="true"> <KeyValue key="tabTemplate" value="TabSystemButtonTemplate" type="string"/> <KeyValue key="spacing" value="1" type="number"/> <KeyValue key="tabSelectSound" value="SOUNDKIT.IG_CHARACTER_INFO_TAB" type="global"/>
  ```
- **TabSystemMixin API: AddTab(text, icon) returns a tabID; SetTabSelectedCallback; SetTab; SetTabEnabled(tabID, enabled, errorReason); SetTabShown; SetTabNotification; GetTabButton. Its pool is created in OnLoad from self.tabTemplate.**  
  `Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua:283`
  ```
  function TabSystemMixin:OnLoad() self.tabs = {}; self.tabPool = CreateFramePool("BUTTON", self, self.tabTemplate); end function TabSystemMixin:AddTab(tabText, tabIcon) local tabID = #self.tabs + 1; ...
  ```
- **TabSystemOwnerMixin pairs tab IDs with content frames. AddNamedTab(name, ...frames) registers the frames, and SetTab shows only that tab's frames and runs the per-tab callbacks.**  
  `Blizzard_SharedXML/Shared/TabSystem/TabSystemOwner.lua:72`
  ```
  function TabSystemOwnerMixin:SetTabSystem(tabSystem) self.tabSystem = tabSystem; tabSystem:SetTabSelectedCallback(GenerateClosure(self.SetTab, self)); end function TabSystemOwnerMixin:AddNamedTab(tabName, ...) local tabID = self.tabSystem:AddTab(tabName); self.internalTabTracker:AddTab(tabID, ...);
  ```
- **The Camelot PlayerSpellsFrame is the in-client example of a PortraitFrameTemplate window with TabSystemOwnerTemplate bottom tabs, anchored TOPLEFT to BOTTOMLEFT at (22, 2), minTabWidth 100 and maxTabWidth 150.**  
  `Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml:4`
  ```
  <Frame name="PlayerSpellsFrame" mixin="PlayerSpellsFrameMixin" inherits="PortraitFrameTemplate, TabSystemOwnerTemplate" ...> ... <Frame parentKey="TabSystem" inherits="TabSystemTemplate"> <KeyValue key="minTabWidth" value="100" type="number"/> ... <Anchor point="TOPLEFT" relativeKey="$parent" relativePoint="BOTTOMLEFT" x="22" y="2"/>
  ```
- **PlayerSpellsFrame tab setup in Lua: call TabSystemOwnerMixin.OnLoad, then SetTabSystem, then AddNamedTab with the page frame for each tab.**  
  `Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua:11`
  ```
  function PlayerSpellsFrameMixin:OnLoad() TabSystemOwnerMixin.OnLoad(self); self:SetTabSystem(self.TabSystem); self.specTabID = self:AddNamedTab(TALENT_FRAME_TAB_LABEL_SPEC, self.SpecFrame); ...
  ```
- **CollectionsJournal is registered as a left-area UI panel, with width 733 (the 703px frame plus room for the side tabs).**  
  `Blizzard_UIParentPanelManager/Mainline/UIPanelWindows.lua:15`
  ```
  UIPanelWindows["CollectionsJournal"] = { area = "left", pushable = 0, whileDead = 1, width = 733};
  ```
- **ShowUIPanel and HideUIPanel refuse insecure calls in combat. A frame without a UIPanelWindows 'area' attribute just gets frame:Show()/Hide(); a registered frame is dispatched to the forbidden FramePositionDelegate.**  
  `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:853`
  ```
  -- We no longer allow addons to show or hide UI panels in combat. local function CheckProtectedFunctionsAllowed() if ( InCombatLockdown() and not issecure() ) then DisplayInterfaceActionBlockedMessage(); return false; ... (890) if ( frame.editModeManuallyShown or not GetUIPanelAttribute(frame, "area") ) then frame:Show();
  ```
- **RegisterUIPanel(frame, attributes) exists for adding a named frame to UIPanelWindows. The delegate is a forbidden frame.**  
  `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:92`
  ```
  function RegisterUIPanel(frame, attributes) local name = frame:GetName(); if not UIPanelWindows[name] then UIPanelWindows[name] = attributes; ... (152) local FramePositionDelegate = CreateFrame("FRAME"); FramePositionDelegate:SetForbidden();
  ```
- **UISpecialFrames is a global list of frame names. CloseSpecialWindows hides each named frame that is shown and is designed to be called through securecall because it handles tainted values.**  
  `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:21`
  ```
  UISpecialFrames = { "ItemRefTooltip", "ColorPickerFrame", ... }; ... (1104) -- this function handles possibly tainted values and so should always be called from secure code using securecall() function CloseSpecialWindows() ... local frame = _G[value]; if ( frame and frame:IsShown() ) then frame:Hide();
  ```
- **The Escape chain: CloseWindows runs securecall("CloseSpecialWindows"), and CloseAllWindows is registered as the AddOnPost Escape handler.**  
  `Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua:1168`
  ```
  found = securecall("CloseSpecialWindows") or found; ... (1190) RegisterGameMenuEscHandler(GameMenuEscPriority.AddOnPost, CloseAllWindows);
  ```
- **The Camelot Escape binding calls ToggleGameMenu. ToggleGameMenu walks the prioritized handlers with securecallfunction and opens the game menu only if none handled the key. Every RegisterGameMenuEscHandler caller in the export is Blizzard code.**  
  `Blizzard_GameMenuEsc/Blizzard_GameMenuEsc.lua:99`
  ```
  local function TryHandleGameMenuEsc() for _, entry in ipairs(handlers) do if securecallfunction(entry.handler) then return true; end end return false; end function ToggleGameMenu() if not TryHandleGameMenuEsc() and GameMenuFrame_Show then GameMenuFrame_Show(); end end  [binding: Blizzard_FrameXML/Bindings_Camelot.xml:1173]
  ```
- **Drag helpers (always loaded): ClickToDragTemplate drags the whole frame. PanelDragBarTemplate is a sub-frame (title bar) that moves GetParent() and has onDragStart/onDragStop callbacks.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:1628`
  ```
  <Button name="PanelDragBarTemplate" mixin="PanelDragBarMixin" virtual="true"> ... <OnDragStart method="OnDragStart"/> <OnDragStop method="OnDragStop"/> ... (1655) <Frame name="ClickToDragTemplate" mixin="ClickToDragMixin" movable="true" virtual="true">
  ```
- **PanelDragBarMixin targets the parent frame, then calls target:StartMoving() and target:StopMovingOrSizing(). The stop callbacks run before StopMovingOrSizing, so save the position with HookScript('OnDragStop').**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:1523`
  ```
  function PanelDragBarMixin:OnLoad() self:RegisterForDrag("LeftButton"); self:SetTarget(self:GetParent()); ... (1574) if target.onDragStopCallback then continueDragStop = target.onDragStopCallback(self); end ... target:StopMovingOrSizing();
  ```
- **Frame API flags: Show, Hide, StartMoving and StopMovingOrSizing are IsProtectedFunction, so they matter only if the frame is protected. SetPropagateKeyboardInput HasRestrictions. SetMovable, SetUserPlaced, SetDontSavePosition, SetClampedToScreen and SetToplevel exist.**  
  `Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua:1548`
  ```
  Name = "StartMoving", Type = "Function", IsProtectedFunction = true, ... (1426) Name = "SetPropagateKeyboardInput", Type = "Function", HasRestrictions = true, ... (1228) Name = "SetDontSavePosition"
  ```
- **MountJournal model pane art (Mainline MountCollection is loaded for Camelot through [Family]): MountJournal-BG cropped with TexCoord right = 0.78515625, plus ShadowOverlayTemplate, inside RightInset with a 3px pad.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:428`
  ```
  <Frame parentKey="MountDisplay"> <Anchor point="TOPLEFT" relativeKey="$parent.RightInset" relativePoint="TOPLEFT" x="3" y="-3"/> ... <Texture parentKey="YesMountsTex" file="Interface\PetBattles\MountJournal-BG" setAllPoints="true"> <TexCoords left="0" right="0.78515625" top="0" bottom="1"/> ... <Frame parentKey="ShadowOverlay" inherits="ShadowOverlayTemplate" useParentLevel="true" setAllPoints="true"/>
  ```
- **Camelot's PetJournal (the Classic file, explicitly allowed for camelot) has the exact BuddyDex layout. LeftInset is 260 wide at (4, -60), bottom at y 26. RightInset sits 20px to its right. The search box is at LeftInset (15, -9), the filter dropdown at TOPRIGHT (-5, -10), the ScrollBox at (3, -36)/(-2, 3), and the PetCard uses the MountJournal-BG and ShadowOverlay art.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:150`
  ```
  <Frame name="$parentLeftInset" useParentLevel="true" inherits="InsetFrameTemplate" parentKey="LeftInset"> <Size x="260" y="496"/> <Anchor point="TOPLEFT" x="4" y="-60" /> <Anchor point="BOTTOMLEFT" x="4" y="26" /> ... <Anchor point="BOTTOMLEFT" relativeTo="$parentLeftInset" relativePoint="BOTTOMRIGHT" x="20" y="0"/>  [toc line 29: Classic\Blizzard_PetCollection.xml [AllowLoadGameType wrath, cata, camelot]]
  ```
- **List-row art used by the journals: PetList-ButtonBackground, PetList-ButtonSelect (selected) and PetList-ButtonHighlight (hover). Rows are 208x46 with a 38px icon.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:80`
  ```
  <Button name="MountListButtonTemplate" ...> <Size x="208" y="46"/> ... <Texture atlas="PetList-ButtonBackground" parentKey="background"/> ... <Texture parentKey="selectedTexture" atlas="PetList-ButtonSelect" hidden="true"/> ... (183) <HighlightTexture atlas="PetList-ButtonHighlight"/>
  ```
- **CollectionsBackgroundTemplate (the grid/tile background with shadows) is ALSO defined in always-loaded SharedXML (Mainline, mainline game type). It is reusable without loading Blizzard_Collections.**  
  `Blizzard_SharedXML/Mainline/SharedCollectionTemplates.xml:56`
  ```
  <Frame name="CollectionsBackgroundTemplate" inherits="InsetFrameTemplate" virtual="true"> ... <Texture parentKey="BackgroundTile" atlas="collections-background-tile" useAtlasSize="true" vertTile="true" horizTile="true"> ... atlas="collections-background-shadow-large"  [toc: Blizzard_SharedXML.toc:196 Mainline\SharedCollectionTemplates.xml [AllowLoadGameType mainline]]
  ```
- **The Collections count box (LOD) is InsetFrameTemplate3, 130x20, with a Label (GameFontNormalSmall) and a Count (GameFontHighlightSmall). In Camelot's CENTER style it sits at TOP (16, -35).**  
  `Blizzard_Collections/Shared/Blizzard_CollectionTemplates.xml:38`
  ```
  <Frame name="CollectionsCountTemplate" useParentLevel="true" inherits="InsetFrameTemplate3" virtual="true" mixin="CollectionsCountTemplateMixin"> <Size x="130" y="20"/>  [Shared/Blizzard_CollectionTemplates.lua:156 self:SetPoint("TOP", 16, -35);]
  ```
- **Camelot-only, always-loaded progress bar template with the common-stat-bar atlases and SetFillPercent/SetText. Useful for the 'N/M seen' bar.**  
  `Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.xml:3`
  ```
  <Frame name="ColoredProgressBarTemplate" mixin="ColoredProgressBarMixin" virtual="true"> <Size x="67" y="29"/> <Texture atlas="common-stat-bar-BG"/> ...  [Blizzard_SharedXML.toc:204 Camelot\ProgressBars\ColoredProgressBar.xml [AllowLoadGameType camelot]]
  ```
- **Collections sets its portrait per tab with SetPortraitToAsset. The Camelot pet journal uses the Polymorph Chicken icon and mounts use MountJournalPortrait (both files exist in the art export).**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:117`
  ```
  CollectionsJournal:SetPortraitToAsset("Interface\\ICONS\\Spell_Magic_PolymorphChicken");  [Mainline/Blizzard_MountCollection.lua:599 CollectionsJournal:SetPortraitToAsset("Interface\\Icons\\MountJournalPortrait");]
  ```
- **An NPC-specific portrait can come from a creature display ID, not only a unit token.**  
  `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:584`
  ```
  Name = "SetPortraitTextureFromCreatureDisplayID", ... { Name = "textureObject", Type = "SimpleTexture" }, { Name = "creatureDisplayID", Type = "number" }
  ```
- **The action buttons under the model in the journals are MagicButtonTemplate (160x22, anchored BOTTOMLEFT). MagicButton_OnLoad adjusts offsets from the anchors that exist when OnLoad runs.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:12`
  ```
  function MagicButton_OnLoad(self) for i=1, self:GetNumPoints() do ... elseif (point == "BOTTOMLEFT") then if (offsetX == 0 and offsetY == 0) then self:SetPoint(point, relativeTo, relativePoint, 4, 4);  [used at Classic/Blizzard_PetCollection.xml:312 SummonButton]
  ```
- **These sound kits exist for the window and its tabs.**  
  `Blizzard_SharedXML/Mainline/SoundKitConstants.lua:36`
  ```
  IG_CHARACTER_INFO_OPEN = 839, IG_CHARACTER_INFO_CLOSE = 840, IG_CHARACTER_INFO_TAB = 841, ... (153) UI_TOYBOX_TABS = 43938,
  ```
- **Blizzard_GlueCollections (PortraitFrameTemplate-based) is glue-only and unavailable in game.**  
  `Blizzard_GlueCollections/Blizzard_GlueCollections.toc:4`
  ```
  ## AllowLoad: Glue
  ```
