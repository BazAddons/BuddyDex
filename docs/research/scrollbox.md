# BuddyDex slice: the scrolling selectable list (ScrollBox + DataProvider + ScrollBar + SelectionBehavior), for the WoW Forever / Camelot client, build 1.60.1.70338

## Summary

This build uses the retail 12.x list stack, and all of it is always loaded. The pieces are the WowScrollBoxList, MinimalScrollBar and WowTrimScrollBar templates, CreateScrollBoxListLinearView, ScrollUtil.InitScrollBoxListWithScrollBar, CreateDataProvider, ScrollBoxConstants and ScrollUtil.AddSelectionBehavior with SelectionBehaviorMixin. They are defined in Blizzard_SharedXML (`## AllowLoad: Both`, not load-on-demand), with a few helpers in Blizzard_SharedXMLBase. A third-party addon can use them directly. Camelot counts as a "mainline" game type, and `[Family]` resolves to `Mainline` for this client.

The examples a player sees in Camelot all live in Blizzard_Collections, which is load-on-demand:
- **Mount Journal:** `Mainline/Blizzard_MountCollection`.
- **Pet Journal:** `Classic/Blizzard_PetCollection` plus a Camelot override that swaps its WowTrimScrollBar for MinimalScrollBar.
- **Wardrobe Sets list:** `Shared/Blizzard_Wardrobe_Sets`. This is the closest model for BuddyDex: two-line rows, an icon, and SelectionBehavior.

All three build rows the same way:
- A 208x46 Button with the PetList-ButtonBackground atlas behind it.
- A 38x38 icon hung outside the row's left edge at x=-42, with Interface\Common\WhiteIconFrame as its border.
- The PetList-ButtonHighlight atlas as the HighlightTexture (shown on hover).
- A hidden PetList-ButtonSelect overlay that is shown for the selected row.
- `view:SetPadding(0,0,44,0,0)` so the icon stays inside the ScrollBox's clipped area.
- A MinimalScrollBar anchored 8px to the right of the ScrollBox.

None of those row templates is always loaded. Their OnClick scripts are also wired to Blizzard globals, so BuddyDex should rebuild the same look itself rather than inherit them. It can do that in Lua with frame type "Button" plus `SetElementExtent(46)`, or with its own XML template.

There are two ways to keep one row selected:
- **SelectionBehavior:** extrusive mode (the default) keys the selection by element-table identity and clears it on every SetDataProvider or Rebuild, so it has to be re-applied by ID after each refresh. This is the Wardrobe Sets pattern.
- **Manual:** keep a `selectedID` and compare it in the row initializer, then re-initialize the old and new rows. This is the Mount and Pet Journal pattern.

To refresh while keeping the scroll position, build a sorted Lua table, then call `scrollBox:SetDataProvider(CreateDataProvider(tbl), ScrollBoxConstants.RetainScrollPosition)`.

## Recommended approach

Use only the always-loaded stack: a WowScrollBoxList, a MinimalScrollBar (the scrollbar Camelot's own journals use), a linear view, a DataProvider and SelectionBehavior in its default extrusive mode. Copy the Blizzard journal row look (208x46 PetList atlases, icon hung at x=-42, left padding 44) instead of inheriting load-on-demand templates. Keep the selected npcID in your own state and re-select by ID after every refresh, because a provider swap clears extrusive selection.

-- BuddyDex/UI/DexList.lua
-- Depends only on always-loaded code: Blizzard_SharedXML, Blizzard_SharedXMLBase, Blizzard_FrameXMLBase and Blizzard_Fonts_Shared.
local ADDON, ns = ...

local ROW_HEIGHT  = 46   -- same height as MountListButtonTemplate / CompanionListButtonTemplate
local ICON_SIZE   = 38
local ICON_X      = -42  -- the icon hangs off the row's left edge, as in the Blizzard journals
local LEFT_GUTTER = 44   -- view left padding so the clipped ScrollBox still shows the icon

local function HasAtlas(name) return C_Texture.GetAtlasInfo(name) ~= nil end

local DexList = {}
DexList.__index = DexList
ns.DexList = DexList

-- One-time construction of a pooled row (frame type "Button", no XML needed)
local function BuildRow(row, list)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetMotionScriptsWhileDisabled(true)

	row.Background = row:CreateTexture(nil, "BACKGROUND")
	row.Background:SetAllPoints()
	if HasAtlas("PetList-ButtonBackground") then row.Background:SetAtlas("PetList-ButtonBackground")
	else row.Background:SetColorTexture(0, 0, 0, 0.35) end

	row.Icon = row:CreateTexture(nil, "BORDER")
	row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.Icon:SetPoint("LEFT", ICON_X, 0)

	row.IconBorder = row:CreateTexture(nil, "ARTWORK", nil, -1)
	row.IconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
	row.IconBorder:SetAllPoints(row.Icon)

	row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	row.Name:SetJustifyH("LEFT"); row.Name:SetWordWrap(false)
	row.Name:SetPoint("TOPLEFT", 8, -8); row.Name:SetPoint("RIGHT", -8, 0)

	row.Sub = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallLeft")
	row.Sub:SetWordWrap(false)
	row.Sub:SetPoint("TOPLEFT", row.Name, "BOTTOMLEFT", 0, -3); row.Sub:SetPoint("RIGHT", -8, 0)

	row.Selected = row:CreateTexture(nil, "OVERLAY")
	row.Selected:SetAllPoints()
	if HasAtlas("PetList-ButtonSelect") then row.Selected:SetAtlas("PetList-ButtonSelect")
	else row.Selected:SetColorTexture(1, 0.82, 0, 0.18) end
	row.Selected:Hide()

	if HasAtlas("PetList-ButtonHighlight") then row:SetHighlightAtlas("PetList-ButtonHighlight")
	else row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD") end

	row:SetScript("OnClick", function(self, button) list:OnRowClick(self, button) end)
	row:SetScript("OnEnter", function(self) list:OnRowEnter(self) end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.isBuilt = true
end

-- parent: the left inset, e.g. CreateFrame("Frame", nil, dex, "InsetFrameTemplate") about 260px wide.
-- Leave about 20px between the inset and the model panel: the scrollbar sits 8px outside the ScrollBox.
function DexList:Create(parent, onSelect)
	local list = setmetatable({ onSelect = onSelect }, DexList)

	local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", 3, -3)
	scrollBox:SetPoint("BOTTOMRIGHT", -2, 3)

	local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 8, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 8, 0)

	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("Button", function(row, elementData) list:InitRow(row, elementData) end)
	view:SetElementExtent(ROW_HEIGHT)          -- REQUIRED when the initializer uses a bare frame type
	view:SetPadding(0, 0, LEFT_GUTTER, 0, 0)   -- top, bottom, left, right, spacing

	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
	scrollBar:SetHideIfUnscrollable(true)      -- optional
	-- scrollBox.wheelPanScalar = 1            -- optional: one row per wheel notch (default is 2)

	local selection = ScrollUtil.AddSelectionBehavior(scrollBox)  -- one row at a time; clicking it again does not unselect
	selection:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, function(owner, elementData, selected)
		local row = scrollBox:FindFrame(elementData)          -- only rows on screen have frames
		if row then row.Selected:SetShown(selected) end
		if selected and elementData.npcID ~= list.selectedNpcID then
			list.selectedNpcID = elementData.npcID
			if list.onSelect then list.onSelect(elementData.npcID, elementData.entry) end
		end
	end, list)

	scrollBox:SetDataProvider(CreateDataProvider())  -- never leave it nil (Find*/ScrollTo* would error)

	list.scrollBox, list.scrollBar, list.view, list.selection = scrollBox, scrollBar, view, selection
	return list
end

-- Rows are pooled and reused, so set every visual every time
function DexList:InitRow(row, data)
	if not row.isBuilt then BuildRow(row, self) end
	local e = data.entry
	row.Name:SetText(e.name or "?")
	row.Sub:SetText(data.subtitle or "")
	row.Icon:SetTexture(data.icon or QUESTION_MARK_ICON)
	local caught = e.caught and true or false
	row.Icon:SetDesaturated(not caught)
	row.IconBorder:SetShown(caught)
	row.Name:SetFontObject(caught and "GameFontNormal" or "GameFontHighlight")
	row.Selected:SetShown(self.selection:IsElementDataSelected(data))
end

function DexList:OnRowClick(row, button)
	if button == "LeftButton" then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		self.selection:Select(row)
	elseif button == "RightButton" and self.onContext then
		self.onContext(row, row:GetElementData())  -- e.g. MenuUtil.CreateContextMenu(row, ...)
	end
end

function DexList:OnRowEnter(row)
	if not row.GetElementData then return end  -- accessors are removed when a row is released
	local data = row:GetElementData()
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip_SetTitle(GameTooltip, data.entry.name or "?")
	if data.subtitle and data.subtitle ~= "" then GameTooltip_AddNormalLine(GameTooltip, data.subtitle) end
	GameTooltip:Show()
end

-- roster: { [npcID] = { name=, title=, level=, creatureType=, zone=, seen=, caught=, icon=? } } (plain, non-secret values)
-- filter(entry, npcID) returns a boolean; comparator(a, b) compares element tables
function DexList:Refresh(roster, filter, comparator)
	local rows = {}
	for npcID, e in pairs(roster) do
		if not filter or filter(e, npcID) then
			rows[#rows + 1] = {
				npcID = npcID,
				entry = e,  -- read-only reference; nothing is ever written into SavedVariables
				subtitle = ns.FormatDexSubtitle and ns.FormatDexSubtitle(e) or (e.title or ""),
				icon = e.icon,
			}
		end
	end
	table.sort(rows, comparator or function(a, b)
		local an, bn = a.entry.name or "", b.entry.name or ""
		if an ~= bn then return an < bn end
		return a.npcID < b.npcID
	end)

	-- One provider swap means one layout pass and one OnSizeChanged; the scroll position is kept
	self.scrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)

	-- The swap cleared the (extrusive) selection, so restore it by ID; restoring does not call onSelect again
	local id = self.selectedNpcID
	local restored = id and self.selection:SelectElementDataByPredicate(function(d) return d.npcID == id end)
	if not restored and not id and #rows > 0 then
		self.selection:SelectFirstElementData()  -- first open: pick the top row
	end
	return #rows, restored ~= nil
end

-- Cheap update when the set of rows is unchanged (seen count or caught flag changed)
function DexList:RefreshVisibleRows() self.scrollBox:ReinitializeFrames() end

function DexList:SelectNpc(npcID)
	local pred = function(d) return d.npcID == npcID end
	if self.selection:SelectElementDataByPredicate(pred) then
		self.scrollBox:ScrollToElementDataByPredicate(pred, ScrollBoxConstants.AlignNearest)
	end
end

function DexList:Step(delta)  -- arrow keys: +1 / -1
	if not self.selection:HasSelection() then self.selection:SelectFirstElementData(); return end
	local data = self.selection:SelectOffsetElementData(delta)
	if data then self.scrollBox:ScrollToElementData(data, ScrollBoxConstants.AlignNearest) end
end

-- Usage:
-- local inset = CreateFrame("Frame", nil, BuddyDexFrame, "InsetFrameTemplate")
-- inset:SetPoint("TOPLEFT", 4, -60); inset:SetPoint("BOTTOMLEFT", 4, 26); inset:SetWidth(260)
-- local list = ns.DexList:Create(inset, function(npcID, entry) BuddyDexFrame:ShowNpc(npcID, entry) end)
-- list:Refresh(BuddyDexDB.roster, ns.CurrentFilterFn)  -- call again on search, filter or roster change

Optional XML version of the row (put it in an .xml file listed in the toc). With it, the extent comes from <Size>, so drop SetElementExtent and pass "BuddyDexDexRowTemplate" to SetElementInitializer instead of "Button":
<Button name="BuddyDexDexRowTemplate" registerForClicks="LeftButtonUp,RightButtonUp" motionScriptsWhileDisabled="true" virtual="true">
  <Size x="208" y="46"/>
  <Layers>
    <Layer level="BACKGROUND"><Texture parentKey="Background" atlas="PetList-ButtonBackground"/></Layer>
    <Layer level="BORDER"><Texture parentKey="Icon"><Size x="38" y="38"/><Anchors><Anchor point="LEFT" x="-42" y="0"/></Anchors></Texture></Layer>
    <Layer level="ARTWORK" textureSubLevel="-1"><Texture parentKey="IconBorder" file="Interface\Common\WhiteIconFrame"><Anchors><Anchor point="TOPLEFT" relativeKey="$parent.Icon"/><Anchor point="BOTTOMRIGHT" relativeKey="$parent.Icon"/></Anchors></Texture></Layer>
    <Layer level="ARTWORK">
      <FontString parentKey="Name" inherits="GameFontNormal" justifyH="LEFT" maxLines="1"><Anchors><Anchor point="TOPLEFT" x="8" y="-8"/><Anchor point="RIGHT" x="-8"/></Anchors></FontString>
      <FontString parentKey="Sub" inherits="GameFontHighlightSmallLeft" maxLines="1"><Anchors><Anchor point="TOPLEFT" relativeKey="$parent.Name" relativePoint="BOTTOMLEFT" y="-3"/><Anchor point="RIGHT" x="-8"/></Anchors></FontString>
    </Layer>
    <Layer level="OVERLAY"><Texture parentKey="Selected" atlas="PetList-ButtonSelect" hidden="true"/></Layer>
  </Layers>
  <HighlightTexture atlas="PetList-ButtonHighlight"/>
</Button>
With the XML version, set row.isBuilt = true and attach the OnClick, OnEnter and OnLeave scripts on first init, or use ScrollUtil.AddAcquiredFrameCallback.

Optional extras, all always loaded: the "collections-newglow" atlas plus NEW_CAPS text to mark newly seen NPCs (as in the pet and mount rows), ScrollUtil.RegisterAlternateRowBehavior for striped rows, and view:SetElementResetter for clean-up when a row is released.

## Pitfalls

- Do not inherit CompanionListButtonTemplate, MountListButtonTemplate, WardrobeSetsScrollFrameButtonTemplate or PetJournalScrollBar. They live in Blizzard_Collections, which is load-on-demand (Blizzard_Collections.toc:3). Their scripts are also wired to Blizzard globals (PetJournalListItem_OnClick, MountListItem_OnClick, the file-local g_selectionBehavior), so even after C_AddOns.LoadAddOn they would call into Blizzard's journal. Copy their structure and atlases instead.
- A bare frame type such as "Button" or "Frame" in SetElementInitializer has no template info. You must call view:SetElementExtent(n) or SetElementExtentCalculator, or RecalculateExtent errors with 'GetTemplateExtent: Failed to obtain template info' (ScrollBoxListView.lua:602-606).
- Order matters. Call SetElementInitializer or SetElementFactory before SetDataProvider (otherwise: 'elementFactory was nil', ScrollBoxListView.lua:308-310). Call ScrollUtil.InitScrollBoxListWithScrollBar before SetDataProvider (otherwise: 'A view is required', ScrollBox.lua:705-707).
- Always attach a provider, even an empty CreateDataProvider(), before calling FindElementDataByPredicate, ScrollToElementDataByPredicate or any selection query. The view calls self:GetDataProvider():... with no nil check (ScrollBoxListView.lua:210-212).
- Extrusive (default) selection is keyed by element-table identity and is wiped on every SetDataProvider and on Rebuild() (ScrollUtil.lua:414-421, :609; ScrollBox.lua:732-737). Keep your own selectedNpcID and re-select by predicate after each refresh, as Wardrobe Sets does at Blizzard_Wardrobe_Sets.lua:724-742.
- Never use SelectionBehaviorFlags.Intrusive on your SavedVariables roster tables. It writes elementData.selected = true into the data (ScrollUtil.lua:606-607), which would persist to disk. DeselectByPredicate also only walks the current provider, so rows that are filtered out keep a stale selected=true.
- Do not fill a live provider with repeated Insert() calls. Each call fires OnSizeChanged and Sort(), which re-sorts the whole table if a comparator is set (DataProvider.lua:77-89, :208-214). On an attached provider it also triggers an immediate FullUpdate (ScrollBox.lua:724-726). Build a Lua table, sort it once, then call SetDataProvider(CreateDataProvider(tbl), ScrollBoxConstants.RetainScrollPosition).
- ScrollToNearestByPredicate(pred, offset, noInterpolation) has a bug: it passes noInterpolation in the offset slot (ScrollBox.lua:817-819), so passing true can cause arithmetic on a boolean. Call ScrollToElementDataByPredicate(pred, ScrollBoxConstants.AlignNearest) instead.
- SelectOffsetElementData, SelectNextElementData and SelectPreviousElementData raise an error when nothing is selected (ScrollUtil.lua:547-550). Check HasSelection() first.
- Rows are pooled and reused. The initializer must set every visual every time: selected overlay, desaturation, font object and icon border. The GetElementData and GetElementDataIndex accessors are removed when a row is released (ScrollBoxListView.lua:120-126), so guard OnEnter and OnClick handlers that might run on a released frame.
- Never change the data provider from inside a row initializer or acquire callback. That raises 'ScrollBoxListViewMixin:Acquire was reentrant' (ScrollBoxListView.lua:361-366). Initializers run inside secureexecuterange, so an error in one row is reported but the other rows still initialize.
- WowScrollBoxList has clipChildren="true" (ScrollBox.xml:20). The journal icon hangs at x=-42 outside the row, so the view needs SetPadding(0,0,44,0,0) or the icons are clipped away.
- MinimalScrollBar is what Camelot's journals use. The Classic pet journal used WowTrimScrollBar, but the Camelot override replaces it (Camelot/Blizzard_PetCollectionScrollBar.xml:4). The bar is anchored 8px outside the ScrollBox, so leave about 18-20px between the list inset and the model panel (Blizzard uses 20 at Classic/Blizzard_PetCollection.xml:160).
- Do not use HybridScrollFrame (deprecated per Blizzard_SharedXML.toc:239) or FauxScrollFrame for new lists.
- Do not modify, override or hooksecurefunc the global shared mixins or utilities (ScrollBoxListMixin, ScrollBoxBaseMixin, SelectionBehaviorMixin, DataProviderMixin, ScrollUtil). Secure Blizzard UI shares them (selection uses securecallfunction and secureexecuterange), so changing them risks tainting the default UI. Wrap them in your own local table, as DexList does.
- The atlas database is not in the export, so presence of PetList-ButtonBackground, PetList-ButtonHighlight and PetList-ButtonSelect cannot be proven from files. They are used by Camelot-loaded Collections code and by the always-loaded Blizzard_UIWidgets, but check C_Texture.GetAtlasInfo at runtime and fall back to a color texture or the exported Interface\QuestFrame\UI-QuestTitleHighlight.
- Secret values under Midnight rules: the list should only show data from the addon's own saved roster. Never store, sort, compare or concatenate values that may be secret (unit names and the like captured in combat). Check issecretvalue or canaccessvalue at capture time (FrameScriptDocumentation.lua:65, :287), and if needed defer roster writes and Refresh() until out of combat. FontString:SetText accepts secrets, but a table.sort comparator using them will not work.
- FindFrame and FindFrameByPredicate only see rows currently on screen. Use FindElementDataByPredicate or ScrollToElementDataByPredicate for data that may be scrolled out of view, as the Mount Journal does at Mainline/Blizzard_MountCollection.lua:806-815.
- Do not enable the mouse wheel or set OnMouseWheel on row buttons. The ScrollBox's own OnMouseWheel (ScrollBox.xml:48) does the scrolling, and a row handling the wheel would swallow it. By default one notch scrolls two rows (wheelPanScalar=2, ScrollController.lua:80); set scrollBox.wheelPanScalar = 1 for one row per notch.
- Blizzard's journals set frameStrata="HIGH" on their ScrollBox and ScrollBar (Mainline/Blizzard_MountCollection.xml:554, :561). Do not copy this into an addon window unless you need it, because it can draw the list above other UI.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **Blizzard_SharedXML is not load-on-demand and loads in both glue and game, so its scroll stack can always be used by addons. Its toc loads DataProvider, ScrollUtil, the views, ScrollBox and the scroll templates, including MinimalScrollBar and TrimScrollBar.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:2 (also :92, :99, :106, :111-112, :116, :118, :122)`
  ```
  ## AllowLoad: Both ... DataProvider.lua ... Shared\Scroll\ScrollUtil.lua ... Shared\Scroll\ScrollTemplates.xml ... Shared\Scroll\TrimScrollBar.xml ... Shared\Scroll\MinimalScrollBar.xml
  ```
- **Blizzard_FrameXML depends on the shared layers, so all of this is present in-game before any third-party addon loads.**  
  `Blizzard_FrameXML/Blizzard_FrameXML.toc:1-12`
  ```
  ## Dep: Blizzard_FrameXMLBase ... ## Dep: Blizzard_GameTooltip
  ```
- **WowScrollBoxList is the ScrollBox template meant for data-provider lists. It inherits ScrollBoxBaseTemplate and uses ScrollBoxListMixin.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollTemplates.xml:4`
  ```
  <Frame name="WowScrollBoxList" inherits="ScrollBoxBaseTemplate" mixin="ScrollBoxListMixin" virtual="true">
  ```
- **ScrollBoxBaseTemplate clips its children and already handles OnMouseWheel, so mouse-wheel scrolling works without extra code.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.xml:20 and :48`
  ```
  <Frame name="ScrollBoxBaseTemplate" clipChildren="true" mixin="ScrollBoxBaseMixin" virtual="true"> ... <OnMouseWheel method="OnMouseWheel"/>
  ```
- **MinimalScrollBar is an EventFrame template, 8px wide, drawn with the minimal-scrollbar-* atlases.**  
  `Blizzard_SharedXML/Shared/Scroll/MinimalScrollBar.xml:15-16`
  ```
  <EventFrame name="MinimalScrollBar" inherits="VerticalScrollBarTemplate" virtual="true"> <Size x="8" y="560"/>
  ```
- **WowTrimScrollBar (25px wide, with a framed track) also exists and is always loaded.**  
  `Blizzard_SharedXML/Shared/Scroll/TrimScrollBar.xml:25-26`
  ```
  <EventFrame name="WowTrimScrollBar" inherits="VerticalScrollBarTemplate" mixin="WowTrimScrollBarMixin" virtual="true"> <Size x="25" y="560"/>
  ```
- **For Camelot, [Family] resolves to Mainline. EraScrollBarTemplate is just an alias for MinimalScrollBar, and it exists only in Mainline/ScrollDefine.xml, which the toc loads as [Family]. A scan of every toc found that each [Family] file present only under Classic/ is gated to classic game types.**  
  `Blizzard_SharedXML/Mainline/ScrollDefine.xml:3; Blizzard_SharedXML/Blizzard_SharedXML.toc:183`
  ```
  <EventFrame name="EraScrollBarTemplate" inherits="MinimalScrollBar" virtual="true"/>
  ```
- **Camelot counts as a mainline game type. Blizzard_Collections loads only for wrath, cata, mists or mainline, yet carries Camelot-specific files, and it has to explicitly exclude camelot from a mainline-only file.**  
  `Blizzard_Collections/Blizzard_Collections.toc:13, :30`
  ```
  ## AllowLoadGameType: wrath, cata, mists, mainline ... Shared\Blizzard_PetCollection.lua [AllowLoadGameType mists, mainline] [ExcludeLoadGameType camelot]
  ```
- **Blizzard_Collections is load-on-demand, so its row templates are not available unless something loads the addon.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3`
  ```
  ## LoadOnDemand: 1
  ```
- **The Camelot Pet Journal uses the Classic pet collection files plus a Camelot scrollbar override that uses MinimalScrollBar. The Classic version of that override used WowTrimScrollBar.**  
  `Blizzard_Collections/Blizzard_Collections.toc:27-29; Blizzard_Collections/Camelot/Blizzard_PetCollectionScrollBar.xml:4; Blizzard_Collections/Classic/Blizzard_PetCollectionScrollBar.xml:4`
  ```
  Camelot: <EventFrame name="PetJournalScrollBar" inherits="MinimalScrollBar" .../>  Classic: inherits="WowTrimScrollBar"
  ```
- **CreateScrollBoxListLinearView(top, bottom, left, right, spacing) creates and initializes a linear list view. Missing arguments default to 0.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxLinearView.lua:246-248`
  ```
  function CreateScrollBoxListLinearView(top, bottom, left, right, spacing) return CreateAndInitFromMixin(ScrollBoxListLinearViewMixin, top or 0, ...)
  ```
- **view:SetPadding takes its arguments in the order top, bottom, left, right, spacing. The padding insets the ScrollTarget inside the ScrollBox.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxLinearView.lua:3-6; Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:271-273`
  ```
  function ScrollBoxLinearBaseViewMixin:SetPadding(top, bottom, left, right, spacing) ... scrollTarget:SetPoint("TOPLEFT", self, "TOPLEFT", self:GetLeftPadding(), offset)
  ```
- **SetElementInitializer(templateOrFrameType, initializer) is a shortcut for SetElementFactory. Use SetElementFactory directly when rows need different templates.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:496-507, :535-537 (usage comment at :509-534)`
  ```
  function ScrollBoxListViewMixin:SetElementInitializer(frameTemplateOrFrameType, initializer) self:SetElementFactory(function(factory, elementData) factory(frameTemplateOrFrameType, initializer); end);
  ```
- **The frame factory accepts a native frame type such as "Button" or "Frame" in place of an XML template, so rows can be built entirely in Lua.**  
  `Blizzard_SharedXMLBase/FrameFactory.lua:17-26`
  ```
  else -- Couldn't obtain template info, so the presumption is that this is a native frame type. frameTemplate = ""; frameType = frameTemplateOrFrameType;
  ```
- **Row height comes from SetElementExtent, from an extent calculator, or from the template's XML size. A bare frame type has no template info, so without SetElementExtent the view raises a 'Failed to obtain template info' error.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxLinearView.lua:102-110, :153-163; Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:602-608`
  ```
  error(string.format("GetTemplateExtent: Failed to obtain template info for frame template '%s'", frameTemplate));
  ```
- **ScrollUtil.InitScrollBoxListWithScrollBar connects the ScrollBox and ScrollBar both ways, calls scrollBox:Init(view), and initializes the bar.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:130-139`
  ```
  BindScrollBoxWithScrollBar(scrollBox, scrollBar); scrollBox:Init(scrollBoxView); InitializeScrollBar(scrollBox, scrollBar);
  ```
- **scrollBox:SetDataProvider(dp, retainScrollPosition) requires a view and an element factory to be set first. Unless the second argument is true it scrolls back to the top.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:703-714; Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:308-310`
  ```
  view:SetDataProvider(dataProvider); if not retainScrollPosition then self:ScrollToBegin(ScrollBoxConstants.NoScrollInterpolation); end
  ```
- **ScrollBoxConstants defines RetainScrollPosition, the alignment values (including AlignNearest) and NoScrollInterpolation.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:12-28`
  ```
  RetainScrollPosition = true, DiscardScrollPosition = false, AlignBegin = 0, AlignCenter = .5, AlignEnd = 1, AlignNearest = -1,
  ```
- **A full update records the old scroll offset and corrects for it after the content size changes. That is why swapping in a new provider with RetainScrollPosition does not make the list jump.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:170-184`
  ```
  local oldScrollOffset = self:GetDerivedScrollOffset(); ... local scrollPercentage = self:GetScrollPercentage() - (deltaScrollOffset / scrollRange);
  ```
- **CreateDataProvider(tbl) inserts the whole table at once, firing one size event and one sort. By contrast, every Insert() call fires OnSizeChanged and runs Sort(), which sorts the whole collection if a comparator is set.**  
  `Blizzard_SharedXML/DataProvider.lua:77-89, :95-107, :208-214, :277-281`
  ```
  function DataProviderMixin:Insert(...) ... self:TriggerEvent(DataProviderMixin.Event.OnSizeChanged, ...); self:Sort(); end
  ```
- **Changing a provider that is already attached triggers an immediate FullUpdate of the ScrollBox.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:333-351; Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:724-726`
  ```
  function ScrollBoxListMixin:OnViewDataChanged() self:FullUpdate(ScrollBoxConstants.UpdateImmediately); end
  ```
- **The DataProvider supports Flush, SetSortComparator(comparator, skipSort), FindElementDataByPredicate and FindIndexByPredicate.**  
  `Blizzard_SharedXML/DataProvider.lua:193-198, :240-248, :267-275`
  ```
  function DataProviderMixin:SetSortComparator(sortComparator, skipSort) self.sortComparator = sortComparator; if not skipSort then self:Sort(); end end
  ```
- **scrollBox:FindElementDataByPredicate passes straight through the view to the provider, with no nil check. It errors if no provider has been set yet.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:642-644; Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:210-212`
  ```
  function ScrollBoxListViewMixin:FindElementDataByPredicate(predicate) return self:GetDataProvider():FindElementDataByPredicate(predicate); end
  ```
- **The scroll-to API is ScrollToElementDataIndex(dataIndex, alignment, offset, noInterpolation), plus ScrollToElementData and ScrollToElementDataByPredicate. AlignNearest only scrolls when the row is not already fully visible.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:821-889`
  ```
  if alignment == ScrollBoxConstants.AlignNearest then ... else -- Already fully in view return; end
  ```
- **Bug: ScrollToNearestByPredicate(predicate, offset, noInterpolation) passes noInterpolation into the offset parameter of ScrollToElementDataByPredicate.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:817-819`
  ```
  self:ScrollToElementDataByPredicate(predicate, ScrollBoxConstants.AlignNearest, noInterpolation);
  ```
- **FindFrameByPredicate calls the predicate as (frame, elementData) and only searches rows currently on screen. FindFrame(elementData) matches by table identity.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxView.lua:128-137; Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:173-179`
  ```
  if predicate(frame, frame:GetElementData()) then return frame; end
  ```
- **The view adds GetElementData, GetData and GetElementDataIndex to a row when it is acquired and removes them when the row is released back to the pool.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:81-96, :120-126`
  ```
  frame.GetElementData = function(self) return elementData; end; ... function ScrollBoxListViewMixin:UnassignAccessors(frame) frame.GetElementData = nil;
  ```
- **Row initializers run after layout through secureexecuterange. Changing the data provider from inside an initializer raises a reentrancy error.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:361-366, :416-422`
  ```
  error("ScrollBoxListViewMixin:Acquire was reentrant."); ... secureexecuterange(self.initializers, SecureInvokeInitializer);
  ```
- **ReinitializeFrames re-runs the initializers on visible rows without replacing the provider. Rebuild re-assigns the current provider instead.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBox.lua:614-616, :732-737; Blizzard_SharedXML/Shared/Scroll/ScrollBoxListView.lua:449-457`
  ```
  function ScrollBoxListMixin:Rebuild(retainScrollPosition) ... self:SetDataProvider(view:GetDataProvider(), retainScrollPosition);
  ```
- **The mouse wheel scrolls by pan extent times wheelPanScalar, which defaults to 2.0, so each notch moves about two rows.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollController.lua:77-100, :152-154`
  ```
  WheelPanScalar = 2.0, ... return Saturate(self:GetPanExtentPercentage() * self.wheelPanScalar);
  ```
- **The scrollbar can hide itself when the list fits, either with SetHideIfUnscrollable(true) or with ScrollUtil.AddManagedScrollBarVisibilityBehavior.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollBar.lua:209-212, :263-265; Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:350-354`
  ```
  if self.hideIfUnscrollable then self:SetShown(hasScrollableExtent); end
  ```
- **ScrollUtil.AddSelectionBehavior(scrollBox, ...flags) creates a SelectionBehaviorMixin. The flags are Deselectable, Intrusive and MultiSelect, and the only event is OnSelectionChanged.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:356-364, :635-639`
  ```
  SelectionBehaviorFlags = FlagsUtil.MakeFlags("Deselectable", "Intrusive", "MultiSelect"); ... GenerateCallbackEvents({ "OnSelectionChanged" })
  ```
- **In the default (extrusive) mode, selection is stored as selections[elementData], keyed by table identity, and it is wiped whenever the data provider is reassigned.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:410-421, :609`
  ```
  scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnDataProviderReassigned, self.OnScrollBoxDataProviderReassigned, self); ... self.selections = {};
  ```
- **Intrusive mode writes the selection into your data as elementData.selected.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:606-607`
  ```
  if self.selectionFlags:IsSet(SelectionBehaviorFlags.Intrusive) then elementData.selected = newSelected;
  ```
- **Without MultiSelect, selecting a row deselects every other row and fires OnSelectionChanged(data, false) for each, then (data, true) for the new one. Without the Deselectable flag, ToggleSelect will not unselect a row.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:480-489, :595-621`
  ```
  if not self.selectionFlags:IsSet(SelectionBehaviorFlags.MultiSelect) then deselected = self:DeselectByPredicate(...)
  ```
- **Useful selection helpers include Select(frame), SelectElementData, SelectElementDataByPredicate (which returns the element data), SelectFirstElementData, SelectOffsetElementData, IsElementDataSelected and GetFirstSelectedElementData. SelectOffsetElementData errors if nothing is selected.**  
  `Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua:393-398, :433-436, :491-499, :543-550, :575-593, :623-625`
  ```
  error("Attempted to select an adjacent element without an existing selection.")
  ```
- **CallbackRegistry callbacks receive the owner as their first argument, followed by the event payload.**  
  `Blizzard_SharedXMLBase/CallbackRegistry.lua:112-141, :207-213`
  ```
  securecallfunction(func, owner, ...);
  ```
- **Wardrobe Sets is a real Camelot-loaded example of SelectionBehavior on two-line icon rows. It uses Intrusive selection, updates the row from OnSelectionChanged, re-applies the selection by ID after each provider swap, and has the row initializer read the selection state.**  
  `Blizzard_Collections/Shared/Blizzard_Wardrobe_Sets.lua:676-697, :724-742, :553-563`
  ```
  g_selectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox, SelectionBehaviorFlags.Intrusive); g_selectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, function(o, elementData, selected) local button = self.ScrollBox:FindFrame(elementData); if button then button:SetSelected(selected) ...
  ```
- **The Wardrobe Sets row template is a 208x46 Button with an icon frame at x=-42, a Name line and a small Label line, and the three PetList atlases for background, selection and highlight.**  
  `Blizzard_Collections/Shared/Blizzard_Wardrobe_Sets.xml:4-77`
  ```
  <Texture atlas="PetList-ButtonBackground" parentKey="Background"/> ... <Texture parentKey="SelectedTexture" atlas="PetList-ButtonSelect" hidden="true"/> ... <Texture parentKey="HighlightTexture" atlas="PetList-ButtonHighlight" setAllPoints="true"/>
  ```
- **Wardrobe Sets puts a WowScrollBoxList and a MinimalScrollBar in its list container, with the bar anchored 8px to the right of the box.**  
  `Blizzard_Collections/Mainline/Blizzard_Wardrobe.xml:573-578`
  ```
  <Frame parentKey="ScrollBox" setAllPoints="true" inherits="WowScrollBoxList"/> <EventFrame parentKey="ScrollBar" inherits="MinimalScrollBar"> ... x="8"
  ```
- **The Mount Journal list, the Camelot one since [Family] is Mainline, is set up as a linear view with MountListButtonTemplate, SetPadding(0,0,44,0,0) and InitScrollBoxListWithScrollBar.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:143-149`
  ```
  local view = CreateScrollBoxListLinearView(); view:SetElementInitializer("MountListButtonTemplate", ...); view:SetPadding(0,0,44,0,0); ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
  ```
- **The Mount Journal selects manually. It stores a selected ID, shows selectedTexture in the initializer when the ID matches, re-initializes the old and new rows, and scrolls only when the newly selected row is off-screen.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:290-296, :789-816`
  ```
  if ( MountJournal.selectedSpellID == spellID ) then button.selected = true; button.selectedTexture:Show(); ... if not foundFrame then MountJournal.ScrollBox:ScrollToElementDataByPredicate(...)
  ```
- **The Mount Journal refreshes by building a new DataProvider and swapping it in with RetainScrollPosition.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:615-621`
  ```
  local newDataProvider = CreateDataProvider(); ... MountJournal.ScrollBox:SetDataProvider(newDataProvider, ScrollBoxConstants.RetainScrollPosition);
  ```
- **MountListButtonTemplate is the reference native row. Its OnClick is wired to the Blizzard global MountListItem_OnClick.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:80-90, :128, :183-188`
  ```
  <Size x="208" y="46"/> ... <Texture atlas="PetList-ButtonBackground" parentKey="background"/> ... <Anchor point="LEFT" x="-42" y="0"/> ... <HighlightTexture atlas="PetList-ButtonHighlight"/> <OnClick function="MountListItem_OnClick"/>
  ```
- **The Mount Journal ScrollBox sits inside the left inset, and its MinimalScrollBar sits 8px to the right of it.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:554-566`
  ```
  <Frame parentKey="ScrollBox" inherits="WowScrollBoxList" ...> <Anchor point="TOPLEFT" relativeKey="$parent.LeftInset" x="3" y="-36"/> ... <EventFrame parentKey="ScrollBar" inherits="MinimalScrollBar" ...>
  ```
- **The Camelot Pet Journal follows the same pattern: CompanionListButtonTemplate, SetPadding(0,0,44,0,0), selection by ID in the initializer, and a provider swap with RetainScrollPosition.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:28-34, :315-321, :333-339`
  ```
  if PetJournalPetCard.petIndex == index then pet.selected = true; pet.selectedTexture:Show(); else ... pet.selectedTexture:Hide()
  ```
- **CompanionListButtonTemplate is a two-line row (name in GameFontNormal, subName in GameFontNormalSmall) built from the same atlases, and its OnClick is wired to a Blizzard global.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:5-56, :115, :121`
  ```
  <Texture parentKey="background" atlas="PetList-ButtonBackground"/> ... <Texture atlas="PetList-ButtonSelect" parentKey="selectedTexture" hidden="true"/> ... <OnClick function="PetJournalListItem_OnClick"/>
  ```
- **Both journals show collected and uncollected rows differently: GameFontNormal with a full-color icon versus GameFontDisable with a desaturated icon.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:280-299`
  ```
  pet.icon:SetDesaturated(false); pet.name:SetFontObject("GameFontNormal"); ... pet.icon:SetDesaturated(true); pet.name:SetFontObject("GameFontDisable");
  ```
- **The always-loaded Blizzard UI builds a ScrollBox entirely in Lua (no XML) in the Menu system, using a WowScrollBoxList, an EventFrame MinimalScrollBar and a bare frame-type initializer.**  
  `Blizzard_Menu/Menu.lua:1750-1778`
  ```
  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList"); self.ScrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar"); ... view:SetElementInitializer("Frame", ...)
  ```
- **The PetList atlas is also used by the always-loaded UIWidgets addon, which is good evidence the atlas exists in this client.**  
  `Blizzard_UIWidgets/Blizzard_UIWidgetTemplateBase.xml:451`
  ```
  <Texture parentKey="NameFrame" atlas="PetList-ButtonBackground" useAtlasSize="true" hidden="true">
  ```
- **InsetFrameTemplate, the inset the journals put their lists in, is always loaded through [Family]\SharedUIPanelTemplates.xml.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:389; Blizzard_SharedXML/Blizzard_SharedXML.toc:193`
  ```
  <Frame name="InsetFrameTemplate" useParentLevel="true" virtual="true">
  ```
- **C_Texture.GetAtlasInfo exists for checking atlases at runtime. The atlas database itself is not in the export.**  
  `Blizzard_APIDocumentationGenerated/TextureUtilsDocumentation.lua:75-78`
  ```
  Name = "GetAtlasInfo", Type = "Function", MayReturnNothing = true,
  ```
- **Button:SetHighlightAtlas(atlas, blendMode) exists. It is the Lua equivalent of <HighlightTexture atlas=...>.**  
  `Blizzard_APIDocumentationGenerated/SimpleButtonAPIDocumentation.lua:370-378`
  ```
  Name = "SetHighlightAtlas", ... { Name = "atlas", Type = "textureAtlas" }, { Name = "blendMode", Type = "BlendMode", Nilable = true },
  ```
- **HybridScrollFrame is marked deprecated in this build.**  
  `Blizzard_SharedXML/Blizzard_SharedXML.toc:239`
  ```
  ## HybridScrollFrame is deprecated. Retained only for addons and legacy content
  ```
- **The always-loaded globals used by the recommended code all exist in this build.**  
  `Blizzard_FrameXMLBase/Constants.lua:588; Blizzard_SharedXML/SharedTooltipTemplates.lua:128, :142; Blizzard_SharedXML/Mainline/SoundKitConstants.lua:48`
  ```
  QUESTION_MARK_ICON = "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP"; function GameTooltip_SetTitle(tooltip, text, ...); IG_MAINMENU_OPTION_CHECKBOX_ON = 856,
  ```
- **The secret-value guard functions issecretvalue and canaccessvalue exist in this build's API.**  
  `Blizzard_APIDocumentationGenerated/FrameScriptDocumentation.lua:65, :287`
  ```
  Name = "canaccessvalue" ... Name = "issecretvalue"
  ```
