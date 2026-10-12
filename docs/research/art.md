# BuddyDex art, icons and polish assets (WoW Forever / Camelot build 1.60.1.70338)

## Summary

Camelot belongs to the "mainline" load family. Each .toc says "[AllowLoadGameType mainline] [ExcludeLoadGameType camelot]" whenever a Mainline file must be kept out, so mainline-tagged and [Family]=Mainline files do load for Camelot. Inside the load-on-demand Blizzard_Collections, Camelot loads Mainline/Blizzard_MountCollection.* and Classic/Blizzard_PetCollection.*. Everything below either appears in code this client loads or exists as a file in the art export. BuddyDex can copy the journal look without loading Blizzard_Collections.

1) Creature-type icons. PET_TYPE_SUFFIX is defined in always-loaded Blizzard_FrameXMLBase. The 10 pet families each have two textures:
- Interface/PetBattles/PetIcon-<Suffix>: a 128x256 sheet. The round badge is at TexCoord 0.4921875–0.796875 by 0.50390625–0.65625. The banner stripe used in pet list rows is at 0.0078125–0.7109375 by 0.74609375–0.91796875.
- Interface/TargetingFrame/PetBadge-<Suffix>: a self-contained 32x32 round badge.
The suffixes are Humanoid, Dragon, Flying, Undead, Critter, Magical, Elemental, Beast, Water and Mechanical. There is no Demon, Giant or Aberration family, so those use spell icons: hunter tracking icons Spell_Shadow_SummonFelHunter and Ability_Racial_Avatar, plus INV_Misc_Eye_01 and INV_Misc_QuestionMark. All of these exist in Interface/ICONS. PetIcon-NO_TYPE is referenced in code but missing from the export. The EncounterJournal's UI-EJ-GenericSearchCreature and UI-EJ-BOSS-Default exist as files, but the EncounterJournal addon itself does not load on Camelot.

2) Rarity. Use ColorManager.GetColorDataForItemQuality(q) from Blizzard_Colors, which is always loaded; the fallback is C_Item.GetItemQualityColor. Camelot's own target-frame convention:
- Boss: UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged
- Rare or rare-elite: UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged
- Elite: UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold
- Rare frame body: UI-HUD-UnitFrame-Target-Rare-PortraitOn
Small row-sized markers: nameplates-icon-elite-gold, nameplates-icon-elite-silver, UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star, VignetteKill and VignetteKillElite, and the file Interface/TargetingFrame/UI-TargetingFrame-Skull. Star options: PetJournal-FavoritesIcon, collections-icon-favorites, campcollection-icon-star, auctionhouse-icon-favorite, and the file Interface/Common/ReputationStar (bottom-right quadrant). The classic dragon target-frame files (UI-TargetingFrame-Elite, -Rare, -Rare-Elite) exist but no code in this build references them.

3) List rows (same in the mount and pet journals). Each row is 208x46 with a 38x38 icon hanging 42px to the left, and the scroll view uses left padding 44.
- Atlases: PetList-ButtonBackground, PetList-ButtonHighlight, PetList-ButtonSelect, collections-newglow
- Files: Interface/Common/WhiteIconFrame (tinted by quality), Interface/PetBattles/MountJournalEmptyIcon
- Seen-not-owned styling: icon desaturated, name in GameFontDisable.

4) Backgrounds.
- CollectionsBackgroundTemplate (collections-background-tile plus shadow and corner atlases) is defined in always-loaded Blizzard_SharedXML/Mainline.
- Model pane: Interface/PetBattles/MountJournal-BG (512x512, use TexCoord 0–0.78515625), with MountJournal-NoMounts for the empty state, ShadowOverlayTemplate on top, and the perks-char-shadow ground shadow from Camelot's stable UI.
- Alternatives: the hunter-stable-bg-art_* atlases, Camelot's 4-tile Interface/DressUpFrame/DressUpBackground-Gnome1..4, the QuestBG-Parchment atlas, and UI-Background-Rock (the frame background).
- Caught marker: checkmark-minimal (used by always-loaded CollectionsUtil), common-icon-checkmark (used in Camelot glue code), ui-questtracker-tracker-check, and the files Interface/RaidFrame/ReadyCheck-Ready and Interface/Buttons/UI-CheckBox-Check.

5) Window portrait. Interface/Icons/Achievement_Character_Gnome_Male and _Female (64x64) exist; so do INV_Misc_Head_Gnome_01/02, INV_Gizmo_03 (Blizzard uses it as a portrait) and INV_Misc_Gear_01..08. Interface/CharacterFrame/TemporaryPortrait-Male-Gnome.blp also exists. PortraitFrameTemplate masks the portrait into a circle automatically; set it with SetPortraitToAsset.

6) Fonts. All are in Blizzard_Fonts_Shared/Shared:
- Row name: GameFontNormal (12pt gold); dimmed rows use GameFontDisable.
- Row subtitle: GameFontNormalSmall or GameFontHighlightSmall (10pt).
- Detail name: GameFontHighlightLarge (16pt); lore: GameFontNormal; source: GameFontHighlight.
- Count bar: GameFontHighlightSmall and GameFontNormalSmall.
- Larger options: GameFontNormalMed2/Med3 (14pt), GameFontNormalLarge2 (18pt).
- Game13Font, Game15Font_o1, Fancy16Font (Morpheus) and QuestFont_Large (Morpheus 15) all exist.

## Recommended approach

Use only always-loaded templates (PortraitFrameTemplate, InsetFrameTemplate, CollectionsBackgroundTemplate, ShadowOverlayTemplate, ColoredProgressBarTemplate) and raw atlas or file names. Re-create the journal row yourself; do NOT inherit MountListButtonTemplate or CompanionListButtonTemplate, which live in load-on-demand Blizzard_Collections.

```lua
local _, ns = ...
local ART = {
  RowBG="PetList-ButtonBackground", RowHL="PetList-ButtonHighlight", RowSel="PetList-ButtonSelect",
  NewGlow="collections-newglow", Fav="PetJournal-FavoritesIcon", Caught="checkmark-minimal",
  EliteGold="nameplates-icon-elite-gold", EliteSilver="nameplates-icon-elite-silver",
  RareStar="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star",
  RingElite="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",
  RingRare="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged",
  RingBoss="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
  LevelRing="UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing", ModelShadow="perks-char-shadow",
}
local FILE = {
  ModelBG=[[Interface\PetBattles\MountJournal-BG]], ModelEmpty=[[Interface\PetBattles\MountJournal-NoMounts]],
  IconBorder=[[Interface\Common\WhiteIconFrame]], EmptyIcon=[[Interface\PetBattles\MountJournalEmptyIcon]],
  Skull=[[Interface\TargetingFrame\UI-TargetingFrame-Skull]], Unknown=[[Interface\Icons\INV_Misc_QuestionMark]],
  Portrait=[[Interface\Icons\Achievement_Character_Gnome_Male]],
}
local function SafeAtlas(tex, atlas, useSize)  -- a missing atlas fails silently, so guard it
  if C_Texture.GetAtlasExists(atlas) then tex:SetAtlas(atlas, useSize) return true end
end

-- Creature type -> pet-family badge.
-- The id is UnitCreatureType's 2nd return. The ids below are the standard CreatureType ids;
-- they are not in the exported code, so confirm each with C_CreatureInfo.GetCreatureTypeInfo(id).name.
local TYPE_TO_PETTYPE = { [1]=8 --[[Beast]], [2]=2 --[[Dragonkin->Dragon]], [4]=7 --[[Elemental]], [6]=4 --[[Undead]],
  [7]=1 --[[Humanoid]], [8]=5 --[[Critter]], [9]=10 --[[Mechanical]], [12]=5, [14]=5 }
local TYPE_ICON = { [3]=[[Interface\Icons\Spell_Shadow_SummonFelHunter]] --[[Demon]], [5]=[[Interface\Icons\Ability_Racial_Avatar]] --[[Giant]],
  [10]=FILE.Unknown, [11]=[[Interface\Icons\Spell_Nature_StoneSkinTotem]], [13]=[[Interface\Icons\Spell_Nature_Cyclone]],
  [15]=[[Interface\Icons\INV_Misc_Eye_01]] --[[Aberration]] }
function ns.SetTypeBadge(tex, typeID)          -- tex ~20-32px
  local pt = TYPE_TO_PETTYPE[typeID]
  if pt and PET_TYPE_SUFFIX and PET_TYPE_SUFFIX[pt] then
    tex:SetTexture([[Interface\TargetingFrame\PetBadge-]]..PET_TYPE_SUFFIX[pt]); tex:SetTexCoord(0,1,0,1)
    -- alternative: [[Interface\PetBattles\PetIcon-]]..suffix with SetTexCoord(0.4921875,0.796875,0.50390625,0.65625)
  else
    tex:SetTexture(TYPE_ICON[typeID] or FILE.Unknown); tex:SetTexCoord(0.07,0.93,0.07,0.93)
  end
end

-- Rarity: color the name by quality, put a marker on the icon, and use Camelot's dragon ring for the big portrait
local CLASS_Q = { minus=0, trivial=0, normal=1, elite=2, rare=3, rareelite=4, worldboss=5 } -- design choice
function ns.QualityColor(classification)
  local q = CLASS_Q[classification] or 1
  local cd = ColorManager and ColorManager.GetColorDataForItemQuality(q)
  if cd then return cd.r, cd.g, cd.b end
  local r, g, b = C_Item.GetItemQualityColor(q); return r, g, b
end
function ns.ClassMarker(tex, c)
  local a = (c=="elite" or c=="worldboss") and ART.EliteGold or (c=="rareelite" and ART.EliteSilver) or (c=="rare" and ART.RareStar)
  tex:SetShown(a and SafeAtlas(tex, a, true) or false)
end

-- List row in the journal style (208x46, icon hangs 42px left; view padding-left 44)
local function InitRow(b, npc)
  if not b.bd then b.bd = true
    b:SetSize(208, 46)
    b.BG = b:CreateTexture(nil, "BACKGROUND"); b.BG:SetAllPoints(); b.BG:SetAtlas(ART.RowBG)
    b.Icon = b:CreateTexture(nil, "BORDER"); b.Icon:SetSize(38, 38); b.Icon:SetPoint("LEFT", -42, 0)
    b.Border = b:CreateTexture(nil, "ARTWORK", nil, -1); b.Border:SetTexture(FILE.IconBorder); b.Border:SetAllPoints(b.Icon)
    b.Name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.Name:SetJustifyH("LEFT"); b.Name:SetSize(147, 0)
    b.Name:SetPoint("LEFT", b.Icon, "RIGHT", 10, 6); b.Name:SetMaxLines(2)
    b.Sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.Sub:SetPoint("TOPLEFT", b.Name, "BOTTOMLEFT", 0, -2)
    b.Type = b:CreateTexture(nil, "OVERLAY"); b.Type:SetSize(20, 20); b.Type:SetPoint("BOTTOMRIGHT", -4, 4)
    b.Class = b:CreateTexture(nil, "OVERLAY", nil, 1); b.Class:SetPoint("TOPLEFT", b.Icon, -6, 6)
    b.Caught = b:CreateTexture(nil, "OVERLAY", nil, 2); b.Caught:SetAtlas(ART.Caught, true); b.Caught:SetPoint("TOPRIGHT", -6, -6)
    b.Sel = b:CreateTexture(nil, "OVERLAY", nil, 1); b.Sel:SetAllPoints(); b.Sel:SetAtlas(ART.RowSel); b.Sel:Hide()
    b:SetHighlightAtlas(ART.RowHL)
  end
  b.Icon:SetTexture(npc.icon or FILE.EmptyIcon)
  b.Name:SetText(npc.name); b.Sub:SetText(npc.title or npc.zone or "")
  ns.SetTypeBadge(b.Type, npc.creatureTypeID); ns.ClassMarker(b.Class, npc.classification)
  b.Border:SetVertexColor(ns.QualityColor(npc.classification))
  local caught = npc.caught
  b.Caught:SetShown(caught); b.Border:SetShown(caught); b.Icon:SetDesaturated(not caught)
  b.Name:SetFontObject(caught and "GameFontNormal" or "GameFontDisable")   -- the journal's owned vs unowned styling
  b.Sel:SetShown(ns.selectedID == npc.npcID)
end
local view = CreateScrollBoxListLinearView(0, 0, 44, 0, 0)
view:SetElementInitializer("Button", InitRow)
view:SetElementExtent(46)  -- required when the initializer is passed a frame type instead of a template

-- Window shell + model pane art
local f = CreateFrame("Frame", "BuddyDexFrame", UIParent, "PortraitFrameTemplate")
f:SetSize(703, 606); f:SetPortraitToAsset(FILE.Portrait); f:SetTitle("BuddyDex")
local right = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
local bg = right:CreateTexture(nil, "BACKGROUND"); bg:SetPoint("TOPLEFT", 3, -3); bg:SetPoint("BOTTOMRIGHT", -3, 3)
bg:SetTexture(FILE.ModelBG); bg:SetTexCoord(0, 0.78515625, 0, 1)
CreateFrame("Frame", nil, right, "ShadowOverlayTemplate"):SetAllPoints(bg)
-- Optional: f.Grid = CreateFrame("Frame", nil, f, "CollectionsBackgroundTemplate") for a tiled collections panel.
-- Optional: a progress bar using the Camelot-only template:
local bar = CreateFrame("Frame", nil, f, "ColoredProgressBarTemplate"); bar:SetSize(180, 29)
bar:SetFillTextureByColorType(ColoredProgressBarMixin.ColorType.Green); bar:SetFillPercent(seen/total); bar:SetText(("%d/%d"):format(seen, total))
-- Big portrait ring by classification: ringTex:SetAtlas(ART.RingElite / ART.RingRare / ART.RingBoss, true)
-- Font picks: detail name GameFontHighlightLarge, subtitle GameFontNormalSmall, body GameFontHighlight, lore GameFontNormal, headers GameFontNormalMed3 or Fancy16Font.
```

## Pitfalls

- Do not call GetPetTypeTexture, CollectionItemListButton_SetRedOverlayShown or CollectionsCountTemplate, and do not inherit MountListButtonTemplate or CompanionListButtonTemplate: they are defined in Blizzard_Collections, which is LoadOnDemand (Blizzard_Collections.toc:3). Use PET_TYPE_SUFFIX (FrameXMLBase, always loaded) and build the path yourself, or call C_AddOns.LoadAddOn('Blizzard_Collections') explicitly. Loading it also builds the CollectionsJournal frame.
- Interface\PetBattles\PetIcon-NO_TYPE is referenced by Blizzard code (Classic/Blizzard_PetCollection.lua:706) but is absent from the art export. Fall back to Interface\Icons\INV_Misc_QuestionMark instead.
- Pet families are not creature types. The suffix is 'Dragon', not 'Dragonkin', and 'Water', not 'Aquatic'. 'Flying' and 'Magical' have no creature-type match. There is no Demon, Giant, Aberration, Totem or Gas Cloud family, so those need spell icons, which are file-verified only.
- Key icons by the numeric id from UnitCreatureType (2nd return), not the localized name. The id-to-type mapping (1=Beast ... 15=Aberration) comes from client DB data that is not in the exported code; verify it in-game with C_CreatureInfo.GetCreatureTypeInfo(id). UnitCreatureType is SecretWhenUnitIdentityRestricted, so read it out of combat and log it.
- Atlas names are client data. An unknown name passed to SetAtlas fails silently (blank texture). Guard with C_Texture.GetAtlasExists. Mainline and Camelot spell the silver dragon differently: Mainline uses 'ui-hud-unitframe-target-portraiton-boss-rare-silver', Camelot uses 'UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged'. The rare star appears as 'UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star' in XML but as 'UnitFrame-Target-PortraitOn-Boss-Rare-Star' in Mainline TargetFrame.lua:462. Prefer the names used by Camelot or XML.
- Camelot's own UI intentionally hides classification icons: ShouldShowStar returns false, nameplate showClassificationIndicator is false, and the damage meter's ShouldShowClassification returns false. For a native Camelot look, signal rarity with the target-frame dragon rings (gold = elite, silver winged = rare or rare-elite, gold winged = boss) rather than stars.
- Don't index ITEM_QUALITY_COLORS directly. It is rebuilt by ColorManager.UpdateColorData on VARIABLES_LOADED and ACCOUNT_CVARS_LOADED, and Blizzard comments say to use the ColorManager accessors. Use ColorManager.GetColorDataForItemQuality(q), which respects colorblind and color overrides.
- The EncounterJournal addon is not loadable in Camelot (AllowLoadGameType: standard, classic). Its textures (UI-EJ-GenericSearchCreature, UI-EJ-BOSS-Default, UI-EJ-JournalBG) are usable only as plain file paths; don't rely on EJ templates or atlases.
- Several pet-battle templates (SharedPetBattleTemplates.xml, FloatingPetBattleTooltip.xml) load via [AllowLoadGameType mists, mainline], i.e. through Camelot's membership in the mainline family. Don't inherit them; just copy the TexCoords.
- MountJournal-BG is 512x512 but the art covers only the left 0.78515625. Always apply TexCoord(0, 0.78515625, 0, 1) or the right edge shows garbage or a seam.
- The DressUpBackground-<Race>1..4 files are 4 tiles of different sizes (256x256, 64x256, 256x128, 64x128) and need 4 textures laid out like DressUpFrames.xml:324-348. They are not one stretchable image.
- PortraitFrameTemplate circle-masks the portrait. Square icons such as Achievement_Character_Gnome_Male look right; pre-round textures (TemporaryPortrait-*) get masked twice and lose their edges.
- The art export folder casing differs from code paths on case-insensitive macOS (PETBATTLES vs PetBattles, BUTTONS vs Buttons). In-game paths are case-insensitive, so use the code's canonical casing (Interface\PetBattles\...).
- Camelot's CollectionsJournal uses side tabs (LargeSideTabButtonTemplate with common-sidetab atlases). PanelTabButtonTemplate bottom tabs still exist in SharedXML, but side tabs look more native to this client.
- When SetElementInitializer is given a frame type ('Button') instead of a template, the ScrollBox cannot infer the row height. Call view:SetElementExtent(46).
- The ColoredProgressBarTemplate is Camelot-only (SharedXML toc:204-205 [AllowLoadGameType camelot]). Guard with `if ColoredProgressBarMixin then` if the addon must also run on other flavors.

## Facts (evidence: exported Forever UI code, paths relative to Interface/AddOns)

- **Camelot counts as part of the 'mainline' load family: tocs explicitly exclude camelot from mainline-tagged lines and substitute [Game]=Camelot files, so mainline-tagged and [Family] (=Mainline) files load for Camelot unless excluded.**  
  `Blizzard_UnitFrame/Blizzard_UnitFrame.toc:20-21`
  ```
  [Family]\UnitFramePvPIndicatorStyle.lua [AllowLoadGameType mainline] [ExcludeLoadGameType camelot]
  [Game]\UnitFramePvPIndicatorStyle.lua [AllowLoadGameType camelot]
  ```
- **Blizzard_Collections is LoadOnDemand. For Camelot it loads the [Family] (Mainline) MountCollection and the Classic PetCollection, and excludes the Shared PetCollection.**  
  `Blizzard_Collections/Blizzard_Collections.toc:3,13,26,28-31`
  ```
  ## LoadOnDemand: 1 ... [Family]\Blizzard_MountCollection.xml ... Classic\Blizzard_PetCollection.xml [AllowLoadGameType wrath, cata, camelot]
  Shared\Blizzard_PetCollection.xml [AllowLoadGameType mists, mainline] [ExcludeLoadGameType camelot]
  ```
- **PET_TYPE_SUFFIX (pet family -> texture suffix) is a global defined in always-loaded Blizzard_FrameXMLBase (root Constants.lua is loaded for mainline, including Camelot).**  
  `Blizzard_FrameXMLBase/Constants.lua:381-392; Blizzard_FrameXMLBase/Blizzard_FrameXMLBase.toc:18`
  ```
  PET_TYPE_SUFFIX = { [1] = "Humanoid", [2] = "Dragon", [3] = "Flying", [4] = "Undead", [5] = "Critter", [6] = "Magical", [7] = "Elemental", [8] = "Beast", [9] = "Water", [10] = "Mechanical", };
  ```
- **Pet-type icon sheets live at Interface\PetBattles\PetIcon-<Suffix>. All 10 exist in the art export (128x256). Blizzard builds the path from PET_TYPE_SUFFIX.**  
  `Blizzard_PetBattleUI/Shared/Blizzard_PetBattleUI.lua:1206; BlizzardInterfaceArt/Interface/PETBATTLES/PetIcon-{Beast,Critter,Dragon,Elemental,Flying,Humanoid,Magical,Mechanical,Undead,Water}.blp`
  ```
  self.PetType.Icon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType]);
  ```
- **The round type badge inside PetIcon-* is cut with these TexCoords: 0.4921875-0.796875 by 0.50390625-0.65625, mirrored in most places. The template that defines them is in Blizzard_FrameXML, which loads for mists and mainline.**  
  `Blizzard_FrameXML/SharedPetBattleTemplates.xml:3-6; Blizzard_PetBattleUI/Shared/Blizzard_PetBattleUI.xml:1026`
  ```
  <Texture name="SharedPetBattleStrengthPetTypeTemplate" virtual="true"><Size x="32" y="32"/><TexCoords left="0.79687500" right="0.49218750" top="0.50390625" bottom="0.65625000"/>
  ```
- **The pet-list row (loaded by Camelot) shows the pet type as a wide banner stripe from PetIcon-*, using a different TexCoord.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:18-24`
  ```
  <Texture parentKey="petTypeIcon"> ... <Size x="90" y="44"/><TexCoords left="0.00781250" right="0.71093750" top="0.74609375" bottom="0.91796875"/>
  ```
- **Each family also has a self-contained 32x32 round badge, Interface\TargetingFrame\PetBadge-<Suffix>, used whole with no TexCoords. All 10 files exist (32x32).**  
  `Blizzard_UnitFrame/Mainline/TargetFrame.xml:316-321; Blizzard_UnitFrame/Mainline/TargetFrame.lua:375; BlizzardInterfaceArt/Interface/TARGETINGFRAME/PetBadge-*.blp`
  ```
  <Texture parentKey="PetBattleIcon" file="Interface\TargetingFrame\PetBadge-Beast" hidden="true"><Size x="32" y="32"/>
  ```
- **PetIcon-NO_TYPE is referenced as the fallback, but the file is NOT in the art export. GetPetTypeTexture is a global inside load-on-demand Blizzard_Collections.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:702-707`
  ```
  function GetPetTypeTexture(petType) ... return "Interface\\PetBattles\\PetIcon-NO_TYPE";
  ```
- **Spell icons for creature types with no pet family exist as files in the art export: Demon, Giant, Aberration, Totem, Gas Cloud, Not specified, plus Dragonkin alternatives. No Blizzard code maps them; they are file-verified only.**  
  `BlizzardInterfaceArt/Interface/ICONS/{Spell_Shadow_SummonFelHunter,Ability_Racial_Avatar,INV_Misc_Eye_01,Spell_Nature_StoneSkinTotem,Spell_Nature_Cyclone,INV_Misc_QuestionMark,INV_Misc_Head_Dragon_01,Ability_Tracking,Spell_Shadow_DarkSummoning,Spell_Frost_SummonWaterElemental}.blp`
  ```
  ls ICONS -> Spell_Shadow_SummonFelHunter.blp, Ability_Racial_Avatar.blp, INV_Misc_Eye_01.blp, INV_Misc_QuestionMark.blp ...
  ```
- **UnitCreatureType returns a localized name AND a numeric id; it is secret when unit identity is restricted. C_CreatureInfo also provides GetCreatureTypeIDs/GetCreatureTypeInfo (localized names) and GetCreatureFamilyInfo(...).iconFile (a native creature-family icon). These are API-doc only; no Blizzard code calls them.**  
  `Blizzard_APIDocumentationGenerated/UnitDocumentation.lua:1030-1043; Blizzard_APIDocumentationGenerated/CreatureInfoDocumentation.lua:65-85,136-146`
  ```
  Name = "UnitCreatureType", SecretWhenUnitIdentityRestricted = true ... { Name = "name" }, { Name = "id", Type = "number" }; CreatureFamilyInfo: id, name, iconFile (fileID)
  ```
- **ColorManager and ITEM_QUALITY_COLORS live in Blizzard_Colors. Blizzard_FrameXML depends on it, so it is always loaded in-game. Blizzard says to use the accessors, not the tables.**  
  `Blizzard_Colors/Mainline/ColorConstants.lua:1-2,15; Blizzard_Colors/Mainline/ColorManager.lua:19-25,52-61; Blizzard_FrameXML/Blizzard_FrameXML.toc:14`
  ```
  -- Avoid directly referencing these tables outside of Blizzard_Colors, instead preferring the various accessor methods in ColorManager.
  function ColorManager.GetColorDataForItemQuality(quality) ... return colorData; -- {r,g,b,hex,color}
  ```
- **ColorManager also offers a |cnIQ<q>: color token that respects color overrides. Enum.ItemQuality runs Poor=0 through Heirloom=7 (WoWToken=8).**  
  `Blizzard_Colors/Mainline/ColorManager.lua:289-292; Blizzard_APIDocumentationGenerated/ItemQualitiesDocumentation.lua:13-21`
  ```
  function ColorManager.GetFormattedStringForItemQuality(text, quality) return string.format("|cnIQ%d:%s|r", quality, text);
  ```
- **Quality-colored icon borders: the AH border atlases are tabled in always-loaded ColorConstants, and the pet journal tints WhiteIconFrame with the quality color.**  
  `Blizzard_Colors/Mainline/ColorConstants.lua:32-42; Blizzard_Collections/Shared/Blizzard_PetCollection.lua:810-812`
  ```
  [Enum.ItemQuality.Rare] = "auctionhouse-itemicon-border-blue", [Enum.ItemQuality.Epic] = "auctionhouse-itemicon-border-purple" ... pet.iconBorder:SetVertexColor(colorData.r, colorData.g, colorData.b);
  ```
- **Camelot's own classification art (the only TargetFrameUtils loaded for Camelot): boss gets the gold winged dragon, rare and rareelite get the silver winged dragon, elite gets the gold dragon. Camelot never shows the rare star.**  
  `Blizzard_UnitFrame/Camelot/TargetFrameUtils.lua:1-19; Blizzard_UnitFrame/Blizzard_UnitFrame.toc:137-138`
  ```
  return "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged", 11, -4; ... "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged", 8, -7; ... "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold", 0, 1;
  function ShouldShowStar(classification) return false; end
  ```
- **The Mainline TargetFrame (loaded for Camelot via [Family]) swaps the whole frame to a rare variant atlas, and defines a rare-star atlas on BossIcon.**  
  `Blizzard_UnitFrame/Mainline/TargetFrame.lua:419-420; Blizzard_UnitFrame/Mainline/TargetFrame.xml:295`
  ```
  self.TargetFrameContainer.FrameTexture:SetAtlas("UI-HUD-UnitFrame-Target-Rare-PortraitOn", ...)
  <Texture parentKey="BossIcon" atlas="UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star" useAtlasSize="true" hidden="true">
  ```
- **Small classification icons for rows are in loaded nameplate code. Camelot turns the nameplate indicator off but the atlas names are present.**  
  `Blizzard_NamePlates/Blizzard_NamePlateClassificationFrame.lua:120-126; Blizzard_NamePlates/Camelot/Blizzard_NamePlateFrameOptionsOverrides.lua:1`
  ```
  if classification == "elite" or classification == "worldboss" then return "nameplates-icon-elite-gold"; elseif classification == "rare" then return "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star"; elseif classification == "rareelite" then return "nameplates-icon-elite-silver";
  ```
- **Rare-mob map atlases appear in the Mainline map legend data, which loads for Camelot.**  
  `Blizzard_UIPanels_Game/Mainline/MapLegendFrameData.lua:24-25,30; Blizzard_UIPanels_Game/Blizzard_UIPanels_Game.toc:167`
  ```
  RareCreature = {Atlas = "VignetteKill" ...}, RareEliteCreature = {Atlas = "VignetteKillElite" ...}, PetBattle = {Atlas = "WildBattlePetCapturable" ...}
  ```
- **Skull texture (boss / ?? level) is used by Camelot code and exists (32x32).**  
  `Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua:89; BlizzardInterfaceArt/Interface/TARGETINGFRAME/UI-TargetingFrame-Skull.blp`
  ```
  enemyLevel = enemyLevel.." / |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:0|t";
  ```
- **Classic dragon target-frame files exist (256x128 each) but no code in this build references them.**  
  `BlizzardInterfaceArt/Interface/TARGETINGFRAME/UI-TARGETINGFRAME-ELITE.BLP, UI-TARGETINGFRAME-RARE.BLP, UI-TARGETINGFRAME-RARE-ELITE.BLP, TargetFrameElite.BLP, TargetFrameRare.BLP, TargetFrameRareElite.BLP`
  ```
  grep for UI-TargetingFrame-Elite/Rare in AddOns: no matches
  ```
- **A small round level ring and a model ground shadow are both used by Camelot's stable UI.**  
  `Blizzard_StableUI/Camelot/Blizzard_StableUI.xml:63,157`
  ```
  <Texture atlas="UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing"/> ... <Texture parentKey="PetShadow" atlas="perks-char-shadow" alpha="0.6"><Size x="410" y="90"/>
  ```
- **Star and favorite markers in loaded code: PetJournal-FavoritesIcon (Camelot pet rows) and campcollection-icon-star (always-loaded SharedXML), plus the file Interface\Common\ReputationStar, which Camelot's reputation frame crops to its bottom-right quadrant.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:85; Blizzard_SharedXML/Mainline/SharedCollectionTemplates.xml:35; Blizzard_UIPanels_Game/Camelot/ReputationFrame.xml:66-68`
  ```
  <Texture parentKey="Texture" file="Interface\Common\ReputationStar" setAllPoints="true"><TexCoords left="0.5" right="1" top="0.5" bottom="1"/>
  ```
- **Mount list row art (Camelot loads Mainline): a 208x46 button with the PetList-ButtonBackground atlas behind it, a 38x38 icon hanging off the left, WhiteIconFrame border, GameFontNormal name, PetList-ButtonSelect overlay, collections-newglow, and the PetList-ButtonHighlight atlas as highlight.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:80-128,139,183`
  ```
  <Button name="MountListButtonTemplate" ...><Size x="208" y="46"/> ... <Texture atlas="PetList-ButtonBackground" parentKey="background"/> ... <Anchor point="LEFT" x="-42" y="0"/> ... <Texture parentKey="selectedTexture" atlas="PetList-ButtonSelect" hidden="true"/> ... <HighlightTexture atlas="PetList-ButtonHighlight"/>
  ```
- **Camelot's pet list row uses the same row atlases plus a GameFontNormalSmall subtitle.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:9,27,35,41,56,68,115`
  ```
  atlas="PetList-ButtonBackground" ... file="Interface\Common\WhiteIconFrame" ... inherits="GameFontNormal" parentKey="name" ... inherits="GameFontNormalSmall" parentKey="subName" ... atlas="PetList-ButtonSelect" ... <HighlightTexture atlas="PetList-ButtonHighlight"/>
  ```
- **Journal scroll lists use CreateScrollBoxListLinearView with 44px left padding, leaving room for the icon that hangs off the left.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:143-149; Blizzard_SharedXML/Shared/Scroll/ScrollBoxLinearView.lua:3,246`
  ```
  local view = CreateScrollBoxListLinearView(); view:SetElementInitializer("MountListButtonTemplate", ...); view:SetPadding(0,0,44,0,0); ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
  ```
- **Owned vs not-owned row styling (seen vs caught pattern): owned rows use GameFontNormal with the border shown; unowned rows get a desaturated icon, hidden border, and GameFontDisable. Selection shows or hides selectedTexture.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.lua:280-298; Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:290-320`
  ```
  else pet.icon:SetDesaturated(true); pet.iconBorder:Hide(); pet.name:SetFontObject("GameFontDisable");
  ```
- **Model-pane background: Interface\PetBattles\MountJournal-BG (512x512, file exists) cropped to the left 78.5%. MountJournal-NoMounts is the empty state. Covered by ShadowOverlayTemplate (always-loaded SharedXML).**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:435-441,452; Blizzard_Collections/Classic/Blizzard_PetCollection.xml:197-205; Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:163`
  ```
  <Texture parentKey="YesMountsTex" file="Interface\PetBattles\MountJournal-BG" setAllPoints="true"><TexCoords left="0" right="0.78515625" top="0" bottom="1"/> ... <Frame parentKey="ShadowOverlay" inherits="ShadowOverlayTemplate" useParentLevel="true" setAllPoints="true"/>
  ```
- **CollectionsBackgroundTemplate (the collections tile background with shadow and corner atlases) is defined in ALWAYS-LOADED Blizzard_SharedXML (Mainline, mainline-only). A third-party addon can inherit it directly.**  
  `Blizzard_SharedXML/Mainline/SharedCollectionTemplates.xml:56-63; Blizzard_SharedXML/Blizzard_SharedXML.toc:196`
  ```
  <Frame name="CollectionsBackgroundTemplate" inherits="InsetFrameTemplate" virtual="true"> ... <Texture parentKey="BackgroundTile" atlas="collections-background-tile" useAtlasSize="true" vertTile="true" horizTile="true">  (also collections-background-shadow-large/-small, collections-background-corner)
  ```
- **Camelot uses the classic 4-tile race DressUp backgrounds. The Gnome set exists: Gnome1 256x256, Gnome2 64x256, Gnome3 256x128, Gnome4 64x128.**  
  `Blizzard_UIPanels_Game/Camelot/DressUpFramesOverrides.lua:1-3; Blizzard_UIPanels_Game/Mainline/DressUpFrames.lua:303,317-332; BlizzardInterfaceArt/Interface/DRESSUPFRAME/DRESSUPBACKGROUND-GNOME1..3.BLP, DressUpBackground-Gnome4.blp`
  ```
  function DressUpFrames_UsesClassBackgrounds() return false; end ... backgroundHost.BGTopLeft:SetTexture(texture..1); ... BGBottomRight:SetTexture(texture..4);
  ```
- **Other themed model or panel backgrounds in loaded code: the hunter-stable spec art atlases (Camelot stable UI) and the QuestBG-Parchment atlas (Mainline quest templates, loaded for Camelot).**  
  `Blizzard_StableUI/Shared/Blizzard_StableUI_Shared.lua:3-7; Blizzard_UIPanels_Game/Mainline/QuestFrameTemplates.xml:10; Blizzard_UIPanels_Game/Blizzard_UIPanels_Game.toc:87`
  ```
  [STABLE_PET_SPEC_CUNNING] = "hunter-stable-bg-art_cunning", ... "hunter-stable-bg-art_ferocity", ... "hunter-stable-bg-art_tenacity"; <Texture parentKey="Bg" atlas="QuestBG-Parchment" useAtlasSize="true">
  ```
- **Caught or checkmark atlas used by ALWAYS-LOADED collections code (Blizzard_FrameXMLUtil, a FrameXML dependency).**  
  `Blizzard_FrameXMLUtil/CollectionsUtil.lua:350; Blizzard_FrameXML/Blizzard_FrameXML.toc:9`
  ```
  name = name..CreateAtlasMarkup("checkmark-minimal", 15, 15, 0, -2);
  ```
- **Other checkmark options: the common-icon-checkmark atlas (used in Camelot CharacterCreate, a glue screen), ui-questtracker-tracker-check (objective tracker), and the files ReadyCheck-Ready (64x64) and UI-CheckBox-Check (32x32).**  
  `Blizzard_CharacterCreate/Camelot/Blizzard_CharacterCreate.lua:2975-2976; Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerAnimTemplates.xml:6; Blizzard_Calendar/Mainline/Blizzard_CalendarTemplates.xml:325`
  ```
  self:SetNormalAtlas("common-icon-checkmark"); self:SetHighlightAtlas("common-icon-checkmark", "ADD");
  ```
- **Collections 'NEW' badge pattern: a NEW_CAPS GameFontHighlight label with a collections-newglow halo.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:130-144`
  ```
  <FontString parentKey="new" inherits="GameFontHighlight" text="NEW_CAPS" hidden="true"> ... <Texture parentKey="newGlow" atlas="collections-newglow" hidden="true">
  ```
- **Camelot-only themed progress bar ColoredProgressBarTemplate (common-stat-bar-* atlases) lives in always-loaded SharedXML. It suits the 'N/M seen' bar.**  
  `Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.xml:3-26; Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.lua:23-39; Blizzard_SharedXML/Blizzard_SharedXML.toc:204-205`
  ```
  <Frame name="ColoredProgressBarTemplate" mixin="ColoredProgressBarMixin" virtual="true"> <Texture atlas="common-stat-bar-BG"/> ... SetFillPercent(p) ... SetFillTextureByColorType -> "common-stat-bar-green"/"-blue"/"-red"/"-white"
  ```
- **The collections count box (load-on-demand) is just InsetFrameTemplate3 (always-loaded UIPanelTemplates) with GameFontNormalSmall label and GameFontHighlightSmall count.**  
  `Blizzard_Collections/Shared/Blizzard_CollectionTemplates.xml:38-56; Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml:724`
  ```
  <Frame name="CollectionsCountTemplate" ... inherits="InsetFrameTemplate3"> <FontString parentKey="Count" inherits="GameFontHighlightSmall" .../> <FontString parentKey="Label" inherits="GameFontNormalSmall" .../>
  ```
- **PortraitFrameTemplate (always-loaded SharedXML) circle-masks a 62x62 portrait with TempPortraitAlphaMask and exposes SetPortraitToAsset/SetTitle. Its frame background is UI-Background-Rock.**  
  `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:565-597,617-620,658; Blizzard_SharedXML/PortraitFrame.lua:47-49`
  ```
  <MaskTexture parentKey="CircleMask" file="Interface\CharacterFrame\TempPortraitAlphaMask" ...> ... function PortraitFrameMixin:SetPortraitToAsset(texture) self:GetPortrait():SetTexture(texture); end
  ```
- **Blizzard journals set icon-file portraits this way; CollectionsJournal changes its portrait per tab. Camelot's pet tab uses the polymorph-chicken icon.**  
  `Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:599; Blizzard_Collections/Classic/Blizzard_PetCollection.lua:117; Blizzard_ScrappingMachineUI/Blizzard_ScrappingMachineUI.lua:50`
  ```
  CollectionsJournal:SetPortraitToAsset("Interface\\ICONS\\Spell_Magic_PolymorphChicken"); ... self:SetPortraitToAsset("Interface\\Icons\\inv_gizmo_03");
  ```
- **Gnome portrait candidates exist in the art export: Achievement_Character_Gnome_Male and _Female (64x64), INV_Misc_Head_Gnome_01/02, INV_Misc_Head_ClockworkGnome_01, INV_GnomeToy, INV_Gizmo_03, INV_Misc_Gear_01..08 and Trade_Engineering in ICONS, plus TemporaryPortrait-Male/Female-Gnome (64x64) in CharacterFrame.**  
  `BlizzardInterfaceArt/Interface/ICONS/Achievement_Character_Gnome_Male.blp; BlizzardInterfaceArt/Interface/CharacterFrame/TemporaryPortrait-Male-Gnome.blp`
  ```
  ICONS/Achievement_Character_Gnome_Male.blp 64 64
  ```
- **Camelot's Collections uses side tabs (LargeSideTabButtonTemplate with common-sidetab atlases, always-loaded SharedXML) instead of bottom PanelTabButtonTemplate tabs. Tab icons are Interface/ICONS files.**  
  `Blizzard_Collections/Camelot/Blizzard_CollectionsTabs.xml:4; Blizzard_Collections/Camelot/Blizzard_CollectionsConstants.lua:4; Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:932,1008-1047; Blizzard_Collections/Shared/Blizzard_Collections.lua:75-81`
  ```
  <Button name="CollectionsJournalTab" inherits="LargeSideTabButtonTemplate" ...> ; BLIZZARD_COLLECTIONS_TAB_STYLE = BLIZZARD_COLLECTIONS_TAB_STYLE_SIDE; atlas="common-sidetab" / "common-sidetab-selected" / "common-sidetab-hover"
  ```
- **Journal font objects: GameFontNormal is 12pt gold (FRIZQT, built on SystemFont_Shadow_Med1), GameFontNormalSmall is 10pt, GameFontHighlight/HighlightSmall are white, GameFontDisable is gray, and GameFontNormalLarge/HighlightLarge are 16pt.**  
  `Blizzard_Fonts_Shared/Shared/FontStyles.xml:50,56,62,86,92,112,172,196; Blizzard_Fonts_Shared/Shared/Fonts.xml:277,41,599`
  ```
  <Font name="GameFontNormal" inherits="SystemFont_Shadow_Med1" virtual="true"><Color color="NORMAL_FONT_COLOR"/> ... <Font name="GameFontHighlightSmall" inherits="GameFontNormalSmall"><Color color="WHITE_FONT_COLOR"/>
  ```
- **Mid and large sizes and fancy fonts exist: GameFontNormalMed2/Med3 (14pt), GameFontNormalLarge2 (18pt), GameFontNormalHuge (20pt), Game13Font (FRIZQT 13), Game15Font_o1, Fancy16Font (MORPHEUS 16), QuestFont_Large (MORPHEUS 15). Game*/Fancy* are loaded only in-game, via the [AllowLoad Game] GameFonts.xml.**  
  `Blizzard_Fonts_Shared/Shared/FontStyles.xml:180,212,251,278; Blizzard_Fonts_Shared/Shared/GameFonts.xml:715-718,1091,1146-1148; Blizzard_Fonts_Shared/Shared/Fonts.xml:1309-1311; Blizzard_Fonts_Shared/Blizzard_Fonts_Shared.toc`
  ```
  <FontFamily name="Game13Font" virtual="true"><Member alphabet="roman"><Font font="Fonts\FRIZQT__.ttf" height="13"/> ... <FontFamily name="Fancy16Font"><Font font="Fonts\MORPHEUS.TTF" height="16"/>
  ```
- **Fonts the Blizzard journals use for the detail pane: name GameFontHighlightLarge, subtitle GameFontNormalSmall, source GameFontHighlight, lore GameFontNormal. Font objects are also usable as Lua globals.**  
  `Blizzard_Collections/Classic/Blizzard_PetCollection.xml:219,225; Blizzard_Collections/Mainline/Blizzard_MountCollection.xml:471,477,483; Blizzard_Collections/Mainline/Blizzard_MountCollection.lua:446`
  ```
  self.SlotLabel:SetTextColor(GameFontNormal:GetTextColor());
  ```
- **Runtime atlas checking is available, and texture/atlas markup helpers live in always-loaded SharedXMLBase.**  
  `Blizzard_APIDocumentationGenerated/TextureUtilsDocumentation.lua:5,45-57; Blizzard_SharedXMLBase/TextureUtil.lua:289,325`
  ```
  Namespace = "C_Texture" ... Name = "GetAtlasExists" ... function CreateAtlasMarkup(atlasName, width, height, offsetX, offsetY, ...) ... TextureKitConstants = {
  ```
- **The EncounterJournal addon does NOT load for Camelot. Its creature art exists only as plain files: UI-EJ-GenericSearchCreature 64x64, UI-EJ-BOSS-Default 128x64, UI-EJ-JournalBG 1024x512 parchment, UI-EJ-BOSSMODELPAPERFRAME 512x512.**  
  `Blizzard_EncounterJournal/Blizzard_EncounterJournal.toc:6; Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua:2467`
  ```
  ## AllowLoadGameType: standard, classic ... icon = "Interface\\EncounterJournal\\UI-EJ-GenericSearchCreature"
  ```
- **Camelot hides the classification icon in the damage meter, the same way it does on nameplates.**  
  `Blizzard_DamageMeter/Camelot/DamageMeterEntryOverrides.lua:1-3`
  ```
  function DamageMeterEntryMixin:ShouldShowClassification() return false; end
  ```
- **Classic-era list highlight used by Camelot's FriendsFrame, suitable for compact rows. The listbox highlight files also exist.**  
  `Blizzard_FriendsFrame/Camelot/FriendsFrame.xml:358; BlizzardInterfaceArt/Interface/BUTTONS/UI-Listbox-Highlight.blp, UI-Listbox-Highlight2.blp`
  ```
  <HighlightTexture file="Interface\QuestFrame\UI-QuestLogTitleHighlight" alphaMode="ADD" parentKey="highlight">
  ```
