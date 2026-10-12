# BuddyDex: design for milestone 1 (BuddyDex + scout)

BuddyDex is a BonziBuddy-style companion addon for World of Warcraft: Forever (client 1.60.1, interface 16001, Blizzard's internal name for it is "Camelot"). Forever runs the retail 12.x UI engine with Midnight's restrictions: secret values in combat, no combat log for addons.

Milestone 1 ships the **scout**, which logs every NPC the player meets into a roster, and the **BuddyDex**, a Blizzard-journal-style window to browse that roster. The on-screen buddy, its voice and its levels come in milestone 2. The Buddy tab is a placeholder until then.

Read `docs/research/*.md` before writing UI code. Every template, mixin and atlas used here is verified there against the client's exported UI code, with file and line evidence. If you need something that is not listed in the research, verify it the same way in `/Applications/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns`. Check that the `.toc` line actually loads for Camelot, not just that the file exists.

## Hard rules (learned in the client; breaking them crashes or taints)

1. **Never load a unit into a model from an event.** `Model:SetUnit` on nameplate units crashed the client ("Missing model in GeosRenderPrep"). The Dex shows models with `DressUpModel:SetCreature(npcID[, displayID])` only. The single exception is not needed in milestone 1: nothing calls `SetUnit` or `SetModelByUnit` at all.
2. **Never store a secret value.** Every value read from a `Unit*` API or tooltip goes through `ns.Util.Plain()` (nil when `issecretvalue`) before it is compared, concatenated, used as a key or saved.
3. **Scout only when allowed:** out of combat (`InCombatLockdown()`), not restricted (`C_RestrictedActions.IsAddOnRestrictionActive` for Combat/Map, `C_Secrets.ShouldUnitIdentityBeSecret(unit)`; every call pcall-wrapped because they may not exist), unit exists, is not a player, is not player-controlled (pets, minions, companions), and `GetZoneText()` is not empty (loading screens).
4. **Unprotected window.** Plain `Show`/`Hide`; never `ShowUIPanel`/`UIPanelWindows`. Replace the template close button's OnClick with a plain `Hide`. Escape closes it through `UISpecialFrames` (the frame needs a global name). No secure templates anywhere.
5. **Do not touch shared Blizzard mixins** (`ScrollUtil`, `SelectionBehaviorMixin`, `DataProviderMixin`, `Menu`, ...): no overriding, no `hooksecurefunc`. Wrap them.
6. **Do not inherit templates from load-on-demand Blizzard addons** (Blizzard_Collections: `CollectionsCountTemplate`, `MountListButtonTemplate`, `CompanionListButtonTemplate`, `CollectionsProgressBarTemplate`, ...). Rebuild their look from always-loaded templates and atlases.
7. **Atlases are runtime data.** Every `SetAtlas` goes through `ns.Art.SetAtlas(tex, atlas, fallback, useAtlasSize)`, which checks `C_Texture.GetAtlasInfo` and falls back to a file or a color.
8. **Frames are built lazily** on first open, never at load time.
9. **Saved variables stay small.** No tooltip arrays, no per-frame data. The roster can grow to thousands of entries.

## House style (matches BazUI / Downtime by the same author)

- Private namespace: every file starts `local ADDON_NAME, ns = ...`. The only globals are the saved variables, the window name `BuddyDexFrame` (needed for Escape), slash tables, and the three compartment functions.
- 4-space indent, no tabs. Comments are prose that explain *why*, at about the density of the probe (`tools/AzerBuddyProbe/AzerBuddyProbe.lua`). Short banner comment at the top of each file saying what it owns.
- UI labels are short sentences in sentence case ("Caught only", "Start sweep").
- Each module is a table on `ns` (`ns.Scout`, `ns.Dex`, ...). Modules talk through the bus and the documented functions below, never through each other's internals.

## Files and load order (`BuddyDex.toc`)

```
## Interface: 16001
## Title: BuddyDex
## Notes: A pocket companion that keeps a BuddyDex of every NPC you meet.
## Author: Baz4k
## Version: 001
## IconTexture: Interface\Icons\Achievement_Character_Gnome_Male
## SavedVariables: BuddyDexDB
## SavedVariablesPerCharacter: BuddyDexCharDB
## AddonCompartmentFunc: BuddyDex_OnAddonCompartmentClick
## AddonCompartmentFuncOnEnter: BuddyDex_OnAddonCompartmentEnter
## AddonCompartmentFuncOnLeave: BuddyDex_OnAddonCompartmentLeave

Core\Namespace.lua
Data\Art.lua
Data\Moves.lua
Core\Database.lua
Scout\Scout.lua
Scout\Sweep.lua
UI\DexList.lua
UI\DexDetail.lua
UI\Pages.lua
UI\DexFrame.lua
Core\Commands.lua
```

## Core/Namespace.lua (owner: core)

- `ns.NAME`, `ns.VERSION` (from `C_AddOns.GetAddOnMetadata`, fallback "?").
- `ns.Print(fmt, ...)`: chat output prefixed `|cffd8b25c[BuddyDex]|r `.
- **Bus.** `ns.Bus = CreateFromMixins(CallbackRegistryMixin)`; call `ns.Bus:OnLoad()`; `ns.Bus:GenerateCallbackEvents({...})`; `ns.Event = ns.Bus.Event`. Events and payloads:
  - `VariablesReady()`: saved variables initialized (fired from Database on ADDON_LOADED).
  - `Login()`: PLAYER_LOGIN happened, after migration ran.
  - `NpcSeen(npcID, entry)`: a new roster entry.
  - `NpcUpdated(npcID, entry)`: an existing entry changed (seen count, caught, display, moves, removed fields).
  - `NpcRemoved(npcID)`
  - `SweepChanged(isActive)`
  - `SettingChanged(key, value)`
  Remember: one callback per owner per event; owners are tables or strings, never numbers. Each module registers with its own module table as owner.
- **Util** (`ns.Util`):
  - `Plain(v)` → v, or nil if `issecretvalue` says it's secret (guard `issecretvalue` may be nil).
  - `Read(fn, ...)` → pcall `fn(...)` and return up to 2 results passed through `Plain`; nil on error or missing fn.
  - `NpcIDFromGUID(guid)` → number for `Creature-` and `Vehicle-` GUIDs (6th dash field), else nil.
  - `Today()` → `date("%Y-%m-%d")`.
  - `Trim(s)`, `Lower(s)` (nil-safe).
  - `CopyDefaults(dst, src)`: deep-fill missing keys.

## Core/Database.lua (owner: core)

On `ADDON_LOADED` for `ADDON_NAME` (explicit frame, name check, unregister after):
- `BuddyDexDB` and `BuddyDexCharDB` become tables (keep existing), defaults deep-filled:

```lua
BuddyDexDB = {
    version = 1,
    roster = {},            -- [npcID] = entry, see below
    settings = { scout = true, announce = false },
    sweep = { restore = nil },  -- previous nameplateShowFriendlyNPCs value while a sweep runs
    dex = { point = nil, sort = "recent", caughtOnly = false, zoneOnly = false,
            hiddenTypes = {}, hiddenRarity = {}, tab = 1 },
    imported = {},          -- [source] = number of entries imported
}
BuddyDexCharDB = { version = 1 }   -- reserved for the buddy (milestone 2)
```
- `ns.db = BuddyDexDB`, `ns.char = BuddyDexCharDB`; fire `VariablesReady`.

On `PLAYER_LOGIN`: run `ns.Database.ImportProbe()`, then fire `Login`.

**Roster entry** (all plain values; omit nil fields):
```lua
{
    name = "Auctioneer Lympkin",
    title = "Auctioneer",          -- tooltip line above the level line, if any
    type = "Humanoid",             -- localized UnitCreatureType name
    typeID = 7,                    -- UnitCreatureType 2nd return when available
    family = nil,                  -- UnitCreatureFamily (beasts)
    class = "normal",              -- UnitClassification: normal/elite/rare/rareelite/worldboss/trivial/minus
    level = 45,                    -- -1 means "??"
    sex = 3,                       -- UnitSex: 1 unknown, 2 male, 3 female
    reaction = 5,                  -- UnitReaction(unit, "player")
    zone = "Ironforge", subzone = "The Commons", mapID = 1455,
    first = "2026-10-10", last = "2026-10-10",
    firstTime = 1791660000,        -- time() of first sighting, for "recently seen" sort
    seen = 3,                      -- sightings, counted once per unit appearance
    caught = nil,                  -- number of catches when caught
    display = nil,                 -- creature display ID, cached when the Dex first loads its model
    moves = nil,                   -- array of animation IDs the model supports, cached with display
}
```

`ns.Database` API:
- `GetRoster()` → `ns.db.roster`.
- `GetEntry(npcID)`.
- `Count()` → seen count, caught count (iterate; called rarely).
- `Remove(npcID)`: delete and fire `NpcRemoved`.
- `MarkCaught(npcID)`: `caught = (caught or 0) + 1`, fire `NpcUpdated`.
- `SetModelInfo(npcID, displayID, moves)`: cache, fire `NpcUpdated`.
- `ImportProbe()`: merge `AzerBuddyProbeAccountDB.scout` (the test addon's roster, a global only when that addon is loaded; it loads after BuddyDex alphabetically, which is why this runs on PLAYER_LOGIN). For every probe entry whose npcID is not already in the roster:
  - skip if `zone` is missing or empty;
  - skip player-controlled units, which the probe logged by mistake: any tooltip line containing `'s Pet`, `'s Minion`, `'s Companion` or `'s Guardian`, or `type == "Non-combat Pet"`;
  - the probe's `tip` is either a table of lines or one string joined with `" | "`. Title = the first line *before* the first line starting with `Level`; nil if the level line comes first. (The probe wrongly saved faction names such as "Ironforge" as titles.)
  - copy `name, type, family, class, level, sex, reaction, zone, subzone, first, seen, caught`, set `last = first`, `firstTime = 0`.
  - count imports into `ns.db.imported.probe` and `ns.Print` "Imported N NPCs from BuddyDex Probe." when N > 0.

## Scout/Scout.lua (owner: scout)

`ns.Scout`:
- Registers `UPDATE_MOUSEOVER_UNIT` (unit "mouseover"), `PLAYER_TARGET_CHANGED` ("target"), `NAME_PLATE_UNIT_ADDED` (payload unit) on its own frame after `VariablesReady`. Each handler runs `ns.Scout.Observe(unit)` inside pcall; errors go to `geterrorhandler()` once per session, never spam.
- `Observe(unit)`: apply hard rule 3 and `ns.db.settings.scout`. NPC ID: `UnitCreatureID(unit)` if it exists and returns a plain number, else `ns.Util.NpcIDFromGUID(UnitGUID(unit))`.
  - **Existing entry:** to avoid counting one NPC dozens of times as nameplates flicker, keep a session table `lastSeen[npcID] = GetTime()`; only increment `seen` and set `last` if more than 60 seconds have passed. Fill `title`, `typeID`, `mapID` if they were missing. Fire `NpcUpdated` only when something changed.
  - **New entry:** build per the schema. Title: `C_TooltipInfo.GetUnit(unit)` lines 2.., take the first plain line before the first line starting with `Level` (strip `<...>` brackets). `mapID = C_Map.GetBestMapForUnit("player")`. `firstTime = time()`. Store, fire `NpcSeen`. If `settings.announce`: `ns.Print("New BuddyDex entry: |cffffffff%s|r", name)`.
  - Never touch a model.
- `Observe` must be cheap: nameplates fire constantly in cities.

## Scout/Sweep.lua (owner: scout)

`ns.Sweep` shows friendly NPC nameplates (CVar `nameplateShowFriendlyNPCs`) so every NPC in range reaches the scout.
- `IsActive()` → `ns.db.sweep.restore ~= nil`.
- `Start()`: refuse in combat (print why); save the current CVar string in `ns.db.sweep.restore`, set it to "1", fire `SweepChanged(true)`.
- `Stop()`: set the CVar back to `restore`, clear it, fire `SweepChanged(false)`.
- `Toggle()`.
- Use `C_CVar.GetCVar/SetCVar` (fall back to `GetCVar/SetCVar`), pcall-wrapped.
- On `PLAYER_LOGOUT` while active: put the CVar back and clear `restore`, so a sweep never survives a logout. On the bus `Login` event: if `restore` is still set (the client crashed mid-sweep), put the CVar back and clear it.

## Data/Art.lua (owner: art)

`ns.Art`: every texture and color the UI uses, so other files never hard-code paths.
- `SetAtlas(tex, atlas, fallbackFile, useAtlasSize)`: atlas if `C_Texture.GetAtlasInfo(atlas)` is non-nil, else `fallbackFile` if given (string path), else hides the texture; returns true when the atlas was used.
- Constants (verified in `docs/research/art.md` / `frame.md` / `scrollbox.md`):
  - `PORTRAIT = "Interface\\Icons\\Achievement_Character_Gnome_Male"`
  - `MODEL_BG = "Interface\\PetBattles\\MountJournal-BG"`, `MODEL_BG_COORDS = {0, 0.78515625, 0, 1}`
  - `MODEL_EMPTY = "Interface\\PetBattles\\MountJournal-NoMounts"`
  - `ROW_BG = "PetList-ButtonBackground"`, `ROW_HIGHLIGHT = "PetList-ButtonHighlight"`, `ROW_SELECTED = "PetList-ButtonSelect"`, `NEW_GLOW = "collections-newglow"`
  - `ICON_BORDER = "Interface\\Common\\WhiteIconFrame"`, `EMPTY_ICON = "Interface\\PetBattles\\MountJournalEmptyIcon"`, `UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"`
  - `CAUGHT = "checkmark-minimal"` (fallback file `Interface\\RaidFrame\\ReadyCheck-Ready`)
  - rarity rings: `RING_ELITE = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold"`, `RING_RARE = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged"`, `RING_BOSS = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged"`
- `SetTypeIcon(tex, entry)`: creature-type badge. Map by `entry.type` name (localized names are English on this client; also accept `typeID`): Humanoid→`Interface\\TargetingFrame\\PetBadge-Humanoid`, Beast→`PetBadge-Beast`, Dragonkin→`PetBadge-Dragon`, Undead→`PetBadge-Undead`, Critter and Non-combat Pet→`PetBadge-Critter`, Elemental→`PetBadge-Elemental`, Mechanical→`PetBadge-Mechanical`; Demon→`Interface\\Icons\\Spell_Shadow_SummonFelHunter`, Giant→`Interface\\Icons\\Ability_Racial_Avatar`, Aberration→`Interface\\Icons\\INV_Misc_Eye_01`; anything else `UNKNOWN_ICON`. Icons (not badges) get TexCoord 0.07..0.93.
- `SetRowIcon(tex, entry)`: if `entry.display` and `SetPortraitTextureFromCreatureDisplayID` exist, use them (pcall); else `SetTypeIcon`.
- `Rarity(class)` → `{ key, label, quality }` for: trivial/minus ("Critter-level", quality 0), normal ("Common", 1), elite ("Elite", 2), rare ("Rare", 3), rareelite ("Rare elite", 4), worldboss ("Boss", 5). Unknown → normal.
- `RarityColor(class)` → r, g, b via `ColorManager.GetColorDataForItemQuality(q)` (pcall), fallback `C_Item.GetItemQualityColor(q)`, fallback white.
- `RARITY_ORDER` = `{ "worldboss", "rareelite", "rare", "elite", "normal", "trivial" }` for the filter menu.
- `TYPES` = `{ "Humanoid", "Beast", "Critter", "Demon", "Dragonkin", "Elemental", "Giant", "Mechanical", "Undead", "Aberration", "Not specified" }` for the filter menu (types missing from it but present in the roster are added by the list at runtime).

## Data/Moves.lua (owner: art)

`ns.Moves.LIST`: ordered `{ id, label }` emote animations the Dex offers as "moves". These IDs were all confirmed by `HasAnimation` in the client on a gnome model: Talk 60, Bow 66, Wave 67, Cheer 68, Dance 69, Laugh 70, Rude 73, Roar 74, Kneel 75, Kiss 76, Cry 77, Chicken 78, Beg 79, Applaud 80, Shout 81, Flex 82, Shy 83, Point 84, Sit 97, Sleep 100, Salute 113. Add for creatures: AttackUnarmed 16, Attack1H 17, SpellCastOmni 52 (unconfirmed; they only show when HasAnimation says yes). `ns.Moves.IDLE = 0`.
- `ns.Moves.Label(id)`.
- `ns.Moves.Probe(model)` → array of IDs from `LIST` for which `model:HasAnimation(id)` is true (pcall each).

## UI/DexFrame.lua (owner: frame)

`ns.Dex`, the window shell. Built on first `Open`.
- `CreateFrame("Frame", "BuddyDexFrame", UIParent, "PortraitFrameTemplate")`, size **760 x 606**, strata HIGH, `SetToplevel(true)`, movable, clamped, `SetDontSavePosition(true)`. `SetTitle("BuddyDex")`, `SetPortraitToAsset(ns.Art.PORTRAIT)`. Close button: plain Hide. `tinsert(UISpecialFrames, "BuddyDexFrame")`. Open and close sounds `SOUNDKIT.IG_CHARACTER_INFO_OPEN/CLOSE`.
- Drag strip: `PanelDragBarTemplate` across the title area (TOPLEFT 58,0 to TOPRIGHT -26,0, height 22). Save the position in a `HookScript("OnDragStop")` into `ns.db.dex.point = { point, relPoint, x, y }`; restore on build, default CENTER.
- Three pages (plain frames filling the window): `DexPage`, `BuddyPage`, `SettingsPage`.
- **Side tabs, Forever style.** Forever's own Legacy window (`Blizzard_LegacySystem/Blizzard_LegacySystem.xml`: `PortraitFrameTemplate` + `LegacySystemTabTemplate`, which inherits `LargeSideTabButtonTemplate` with `fillToInterior`) and its Collections window both use icon tabs down the right edge, and the user wants that look. So: three `LargeSideTabButtonTemplate` frames (created with `CreateFrame("Frame", nil, frame, "LargeSideTabButtonTemplate")`), each `tab:SetFillToInterior(true)` (otherwise the icon has no size), `tab.Icon:SetTexture(...)`, `tab.tooltipText = ...`. Tab 1 `TOPLEFT` to the frame's `TOPRIGHT` (0, -60); tabs 2 and 3 `TOPLEFT` to the previous tab's `BOTTOMLEFT` (0, -2). Icons: BuddyDex `Interface\\Icons\\INV_Misc_Book_09`, Buddy `Interface\\Icons\\Achievement_Character_Gnome_Male`, Settings `Interface\\Icons\\INV_Misc_Gear_01` (all verified in the art export). Clicks through `tab:SetCustomOnMouseUpHandler(function(t, button, upInside) if button == "LeftButton" and upInside then select(t.index) end end)` (the mixin plays the tab sound); selection through `tab:SetChecked(i == index)` on all three. Verify these mixin methods in `Blizzard_SharedXML` before use (see docs/research/frame.md, "Alternative B"). Selecting shows one page, sets the title ("BuddyDex", "Buddy", "Settings") and saves `ns.db.dex.tab`. No `PanelTemplates_*`, no bottom tabs. The tabs hang about 50 px outside the window's right edge; that is expected.
- **Copper frame.** `PortraitFrameTemplate` is drawn with Forever's copper art automatically (the Legacy and Options windows use it). Do not use `BasicFrameTemplate*`: that is the gray metal frame the probe used and the user does not want.
- Header ("attic", above the insets, on DexPage): one count box built from `InsetFrameTemplate3`, 200 x 20, at TOP (16, -35) like Camelot's journals. Left label `GameFontNormalSmall` "BuddyDex", right text `GameFontHighlightSmall` `"%d seen, |cffffd100%d caught|r"`. `EnableMouse(true)` and a tooltip: "NPCs you have met" / "Caught NPCs can become your buddy (coming soon)".
- Builds pages: `ns.DexList.Build(dexPage)`, `ns.DexDetail.Build(dexPage, list inset)`, `ns.Pages.BuildBuddy(buddyPage)`, `ns.Pages.BuildSettings(settingsPage)`.
- `ns.Dex.Open(npcID)` (optional npcID selects that NPC), `Close()`, `Toggle()`, `IsOpen()`, `ShowTab(index)`.
- `ns.Dex.Refresh()`: header counts + `ns.DexList.Refresh()`.
- Live updates: registers `NpcSeen`, `NpcUpdated`, `NpcRemoved` on the bus; when the window is shown, coalesce into one refresh at most every 0.5 s (C_Timer.After + dirty flag). When hidden, just mark dirty and refresh on next show.
- `OnHide`: `ns.DexDetail.Release()` (frees the model).

## UI/DexList.lua (owner: list)

`ns.DexList`, the left half of the Dex page.
- `Build(page)`: creates `page.LeftInset` (`InsetFrameTemplate`, width 280, TOPLEFT 4,-60 to BOTTOMLEFT 4,26), then:
  - **Search** (`SearchBoxTemplate`, 160 x 20) in the attic just above the inset: `search:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", 14, 6)`. `search.Instructions:SetText("Search NPCs")`. `HookScript("OnTextChanged")` (never SetScript), compare to the last text, refresh. Clear the text when the window hides.
  - **Filter** button in the attic aligned to the inset's right edge: `filter:SetPoint("BOTTOMRIGHT", inset, "TOPRIGHT", -2, 5)`.
  - **Filter menu** (`CreateFrame("DropdownButton", nil, page, "WowStyle1FilterDropdownTemplate")`, `resizeToText = false` before `SetWidth(90)`). `SetIsDefaultCallback`, `SetDefaultCallback` (reset + refresh), `SetUpdateCallback` (refresh), `SetupMenu` with: checkbox "Caught only"; checkbox "Current zone only"; divider; title "Creature type" + one checkbox per type (from `ns.Art.TYPES` plus any extra types in the roster), each bound to `ns.db.dex.hiddenTypes[type]` (checked = not hidden); "Select" submenu with "Check all" / "Uncheck all" returning `MenuResponse.Refresh`; divider; title "Rarity" + checkbox per `ns.Art.RARITY_ORDER` label bound to `hiddenRarity`; divider; "Sort by" submenu with radios: Recently seen (`recent`, default), Name (`name`), Zone (`zone`), Level (`level`), Times seen (`seen`), returning `MenuResponse.Refresh`; divider; button "Reset filters".
  - **List:** `WowScrollBoxList` filling the inset (TOPLEFT 3,-3 / BOTTOMRIGHT -2,3), `MinimalScrollBar` 8 px to its right (leave the 20 px gap the detail inset starts at), `CreateScrollBoxListLinearView()`, `SetElementInitializer("Button", init)`, `SetElementExtent(46)`, `SetPadding(0, 0, 44, 0, 0)`, `ScrollUtil.InitScrollBoxListWithScrollBar`, `ScrollUtil.AddSelectionBehavior` (extrusive, default), and an empty `CreateDataProvider()` attached before anything queries it.
  - **Row** (built once per pooled frame, every visual set on every init): `ns.Art.SetAtlas` ROW_BG background; 38x38 icon at LEFT -42 via `ns.Art.SetRowIcon`; `ICON_BORDER` over it tinted with `ns.Art.RarityColor`; name (`GameFontNormal`, rarity color, one line); subtitle (`GameFontHighlightSmall`, one line): title if any, else subzone/zone; small level text right-aligned on the name line (`GameFontNormalSmall`, "Lv 45" / "Lv ??"); caught check (`ns.Art.CAUGHT`, top right) shown when caught; `NEW_GLOW` shown when the NPC was first seen this session (ns.Scout keeps `ns.Scout.sessionNew[npcID] = true`); selected overlay `ROW_SELECTED`; highlight `ROW_HIGHLIGHT`. Left click selects (sound `SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON`); right click opens `MenuUtil.CreateContextMenu(row, ...)` with the name as title and "Remove from BuddyDex" (calls `ns.Database.Remove`). Tooltip on enter: name, title, "Zone - Subzone", "Seen N times". Guard handlers for released rows (`row.GetElementData` may be gone).
  - **Empty state:** a centered `GameFontDisable` string in the inset when no rows match: "No NPCs yet. Mouse over or target NPCs, or start a sweep." / "No NPCs match these filters." when the roster is not empty.
- `Refresh()`: build a plain array from the roster passing search + filters, sort once (ties broken by name then npcID), `scrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)`, then re-select `selectedNpcID` by predicate; if nothing was selected yet, select the first row. Element data: `{ npcID = id, entry = e }` (never write into `e` from the list).
- `SelectNpc(npcID)`: select and scroll to it (`ScrollToElementDataByPredicate(pred, ScrollBoxConstants.AlignNearest)`), clearing search/filters first if it is filtered out.
- `GetSelected()` → npcID.
- Selection changes call `ns.DexDetail.Show(npcID)` (and nil when the list is empty).
- Search matches lowercased plain substrings of name, title, zone, subzone, type (`string.find(s, q, 1, true)`).
- Sort keys: recent = `firstTime` desc (imported entries have 0 and fall back to name); name asc; zone = zone, subzone, name; level desc (-1 treated as 999); seen desc.

## UI/DexDetail.lua (owner: detail)

`ns.DexDetail`, the right half of the Dex page.
- `Build(page, leftInset)`: `page.RightInset` (`InsetFrameTemplate`, TOPRIGHT -6,-60, BOTTOMLEFT anchored to leftInset BOTTOMRIGHT +20,0).
  - **Model card**, top part of the inset (about 62% of its height): `MODEL_BG` with `MODEL_BG_COORDS`, then a `DressUpModel` filling the card, then `ShadowOverlayTemplate` on top. Left-drag rotates (`SetFacing`), mouse wheel zooms (`SetPortraitZoom` clamped 0..0.7, pcall), and a 90 x 20 `UIPanelButtonTemplate` "Reset view" at the card's bottom right resets facing and zoom. On the card's top: name (`GameFontHighlightLarge`) and subtitle (`GameFontNormal`, title or creature type) over a dark gradient (`SetGradient` on a white color texture, pcall) for legibility.
  - **Placeholder** when nothing is selected or the model failed: `MODEL_EMPTY` texture centered and a `GameFontDisable` line ("Pick an NPC" / "No model available for this NPC").
  - **Info panel** under the card: two columns of label/value rows (`GameFontNormalSmall` labels, `GameFontHighlightSmall` values): Type ("Humanoid" or "Beast (Wolf)"), Level, Rarity (colored), Found in ("Ironforge - The Great Forge"), Seen ("12 times"), First seen (date), Caught ("Yes (2)" / "Not yet"), NPC ID.
  - **Moves row:** label "Moves" and up to 8 small buttons (`UIPanelButtonTemplate`, 64 x 20, pooled) for the NPC's supported moves (`entry.moves`); clicking plays `SetAnimation(id)` once then the model returns to idle (set animation back to 0 after ~3 s via a token-guarded timer). If moves are unknown yet: "Moves: loading…"; none: "Moves: none".
  - **Lore box:** a framed area (`InsetFrameTemplate3` or a dark backdrop) with `GameFontNormal` text: `ns.Lore and ns.Lore[npcID]` if present (milestone 2 data), else "|cff808080No BuddyDex entry written yet.|r".
- `Show(npcID)`: debounce 0.1 s; update texts immediately; load the model with `model:SetCreature(npcID, entry.display)` (pcall; when `display` is nil call `SetCreature(npcID)`). Model loading is async: a token-guarded `OnModelLoaded` script reads `GetDisplayInfo()` (plain, non-zero) and `ns.Moves.Probe(model)`; if they differ from the cache, `ns.Database.SetModelInfo(npcID, displayID, moves)`. A 6 s token-guarded timeout shows the "No model" placeholder if `OnModelLoaded` never fired. Only one load in flight; a newer `Show` cancels the older (token).
- `Release()`: `ClearModel()`, cancel timers.
- Never `SetUnit`.

## UI/Pages.lua (owner: pages)

`ns.Pages`:
- `BuildBuddy(page)`: a friendly placeholder. Inset filling the page (60 top, 26 bottom), big gnome portrait icon (`ns.Art.PORTRAIT`, 96x96, circle via a mask or plain), headline `GameFontNormalHuge`/`GameFontNormalLarge` "Your buddy is on the way", body text: the buddy (a gnome built from your character, armor, levels, voice) arrives in the next version; meanwhile, every NPC you meet goes into the BuddyDex.
- `BuildSettings(page)`: inset, then sections with headers (`GameFontNormalLarge`) and `UICheckButtonTemplate` checkboxes (`.Text:SetText`) bound to `ns.db.settings`:
  - **Scout:** "Log NPCs I meet" (`scout`), description below in `GameFontHighlightSmall`: mouse over, target, or see a nameplate; "Announce new NPCs in chat" (`announce`).
  - **Sweep:** a `UIPanelButtonTemplate` "Start sweep"/"Stop sweep" (label tracks `SweepChanged`) and a line explaining it turns on friendly NPC nameplates and puts the setting back.
  - **BuddyDex data:** "N NPCs seen, M caught" (refresh on show and on bus events); button "Import from BuddyDex Probe" (runs `ns.Database.ImportProbe()`; disabled when the probe's data is not loaded).
  - **Commands:** `/bd` opens the BuddyDex, `/bd sweep`, `/bd scout`.
  Changing a setting fires `SettingChanged`.

## Core/Commands.lua (owner: core)

- Slash: `/buddydex` and `/bd` (`/ab`, the old AzerBuddy command, still works). Arguments: none → `ns.Dex.Toggle()`; `sweep` → `ns.Sweep.Toggle()`; `scout` → toggle `settings.scout` and print the state; `settings` → open the Dex on the Settings tab; `help` → list commands. Unknown → help.
- Compartment globals: `BuddyDex_OnAddonCompartmentClick(addonName, buttonName)` (left: toggle Dex; right: Settings tab), `BuddyDex_OnAddonCompartmentEnter(addonName, button)` (tooltip: "BuddyDex", "Click: BuddyDex", "Right-click: settings", "N NPCs seen"), `BuddyDex_OnAddonCompartmentLeave()`.

## Tooling (owner: tooling)

- `tools/deploy.sh`: BazUI's script adapted: default destination `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/BuddyDex`, safety case `*/Interface/AddOns/BuddyDex`, rsync with the `.pkgmeta` ignore list.
- `.pkgmeta` (`package-as: BuddyDex`, ignore `.git`, `.gitignore`, `.pkgmeta`, `docs`, `tools`, `DEVELOPERS.md`, `.venv`), `.gitignore` (`.DS_Store`, `*.bak`, `*.swp`, `.venv/`, `__pycache__/`).
- `tools/tests/`: Python `unittest` + `lupa` (Lua 5.1) harness: a Lua mock of the WoW API good enough to load every TOC file in order with `("BuddyDex", ns)` as `...`, and tests that drive events and UI handlers (see "Tests" below). Run with `.venv/bin/python -m unittest discover -s tools/tests -v` after `python3 -m venv .venv && .venv/bin/pip install lupa`.
- `DEVELOPERS.md`: layout, module contracts summary (point to this file), hard rules, how to test and deploy.

## Tests (must pass before deploy)

1. Loading every TOC file raises no error; `ADDON_LOADED` creates defaults; a second load keeps existing data.
2. `PLAYER_LOGIN` imports a fake probe roster: titles fixed (faction line not taken, `"Lord of Ironforge"` kept), pets/minions/companions and empty-zone entries skipped, existing entries untouched, count printed.
3. Scout: a nameplate NPC is added with all fields; players, player-controlled units, combat, secret values, restricted identity and empty zone are skipped; title parse; `seen` increments only after 60 s; announce prints.
4. Sweep: start sets the CVar and stores the old value; stop restores; logout restores; login after a crash restores; refuses in combat.
5. Dex: `/bd` builds and shows the window without error; tabs switch pages; search and every filter/sort narrow and order the rows; selecting a row calls `SetCreature` with the right ID; firing `OnModelLoaded` caches display and moves; a newer selection's token wins over a late load; remove via context menu; live `NpcSeen` refreshes the list once (coalesced).
6. Settings checkboxes change `ns.db.settings`; the sweep button tracks `SweepChanged`.

## Styling pass (by hand after integration; build agents and the integrator ignore this section)

The user's reference is **Forever's own Legacy window** (`Blizzard_LegacySystem`). Seen side by side with the Codex in BazUI, the user prefers its frame and background to the Codex's leather tile, and plans to move BazUI to it as well. Pieces that BazUI has already solved in this client (side tabs, template checks) are ported from BazUI, which is the same author's GPL code.

- **Window:** `PortraitFrameTemplate`, exactly as `LegacySystemFrame` does (`Blizzard_LegacySystem.xml:4`). Forever draws its NineSlice in copper. The size is free because the frame is a nine-slice.
- **Background:** the Legacy page background, the atlas `Legacy-Rewards-Tracker-background`, filling the window interior the way `LegacyRewardTrackPageTemplate` anchors it (`Blizzard_LegacyRewardTrack.xml:74-86`): page at TOPLEFT (5, 0) / BOTTOMRIGHT (-5, 6), texture at TOPLEFT (0, -2) / BOTTOMRIGHT (0, 0). Go through `ns.Art.SetAtlas` and keep the template's own background as the fallback. **No** Collections leather tile and **no** corner filigree.
- **Cards:** `TooltipBackdropTemplate` with backdrop color `{0.02, 0.02, 0.02, 0.62}` (BazUI's `Panel.CreateBox`) for the list, info, moves and lore panels, so they sit on the Legacy background like the Legacy reward cards do.
- **Section headers:** the carved plate atlas `UI-Character-Info-Title` at its own size. **Row stripes:** `UI-Character-Info-Line-Bounce` at alpha 0.55 under every other row.
- **Side tabs,** like the Legacy window's (`LegacySystemTabTemplate` inherits `LargeSideTabButtonTemplate` with `fillToInterior`): port `~/Code/BazUI/Core/SideTabs.lua` (`BazUI.CreateSideTabs`) without the drag-to-reorder part. It settles the Forever vs retail template differences: `SetFillToInterior`, selection drawn by hand, icon crop 0.03125. Custom tab paintings can live under `Textures/Tabs/` later, as the Codex does with `Textures/Codex/`.
- **Template checks:** test templates with `C_XMLUtil.GetTemplateInfo(name)`, as `BazUI.Has.Template` (`Core/Compat.lua`) does, and fall back gracefully.

## License (applied by hand after integration)

All of the author's addons are **GPL-2.0-or-later**. BuddyDex follows BazUI's convention:
- `LICENSE` at the repo root, which is the GPL v2 text copied from BazUI. It is **not** in the `.pkgmeta` ignore list, because the GPL requires shipping a copy.
- `## X-License: GPL-2.0-or-later` in `BuddyDex.toc`.
- `-- SPDX-License-Identifier: GPL-2.0-or-later` as the first line of every Lua file, the same for shell scripts (`#`), and the README states it.

## Polish pass: "AAA, wow people on first use" (after milestone 1 works in game)

The user wants BuddyDex to feel like a Blizzard feature: animation, sound where it helps, and a first open that impresses. Every animation uses `AnimationGroup`s on our own frames (Alpha, Scale, Translation, Rotation): no OnUpdate tweening where an AnimationGroup does the job, and nothing that taints or touches protected frames. Every sound comes from `SOUNDKIT` keys verified in `tools/tests/blizzard_api.lua`, and stays subtle and never spammy.

- **Window:** open with a quick fade-and-scale (0.15 s, 0.96 → 1.0) and close with a fade. Tab switches cross-fade the pages.
- **First open ("wow" moment):** a one-time welcome card over the Dex. The gnome portrait, then a typed-out line ("Welcome to your BuddyDex!"), then a count that rolls up to the NPCs already imported ("You've already met 162 NPCs!"), then rows that cascade in with a staggered fade and slide, a collection sound, and optionally a TTS greeting in the robotic voice the user loves.
- **List:** a hover glow; the selection's highlight pulses once; the "New" badge shimmers; rows that arrive live slide in rather than pop.
- **Model:** a fade-in once loaded, a small spin-in on selection (facing eases from about 0.6 rad to 0), and a gentle idle sway. The Moves buttons play with a click sound.
- **Discovery toasts:** a "New BuddyDex entry" toast, in the achievement-toast style with icon and sound, when a new NPC is logged. Throttled and aggregated during sweeps ("+12 new NPCs in Ironforge"). A setting turns it off.
- **Numbers:** the seen/caught counter rolls up when it changes.
- **Catching (milestone 2):** a capture animation and sound burst, the Capturinator gag, and a shiny sparkle.

## Milestone 2 decision: the Mini Me (user, 2026-10-10)

The player's own buddy is the **Mini Me**: a gnome version of the player, **wearing the same armor**.
- Body: `ModelSceneActor:SetModelByUnit("player", sheathe, autoDress = true, hideWeapons, usePlayerNativeForm = true, holdBowString, customRaceID = 7)`, which the Gnome Lab proved (tile 1). It takes the character's own face, hair and sex. `"player"` is always loaded, so this is not the nameplate crash pattern.
- Armor: autoDress mirrors the player's equipped gear (confirmed in game). Re-dress on `PLAYER_EQUIPMENT_CHANGED` (re-run SetModelByUnit, or `actor:Dress()`), so the Mini Me changes clothes when the player does. Do not rely on `TryOn` for race-swapped actors: it reported Success and drew nothing in the T1 test.
- Collected NPC buddies from the BuddyDex are the alternative forms (fixed outfits, hats via TryOn on DressUpModel).
- **One world scale:** friends stand on the same kind of stage as the Mini Me (`ns.MiniMe.CreateNpc`, SetModelByCreatureDisplayID), and the buddy's frame grows by their height over the Mini Me's (`BuddyDexCharDB.miniMeHeight`, each friend's `height` kept in their entry), feet kept in place, so a human friend stands twice the Mini Me's height. A friend whose display isn't known yet falls back to the Dex's DressUpModel at the Mini Me's size.

## Milestone 1.5: friendship (user decisions, 2026-10-10)

This supersedes the scouting parts above. The scout was a way to compile NPCs for writing lore, not a player feature.
- **BuddyDex Scout** (`tools/BuddyDexScout`, deployed with `tools/deploy-scout.sh`, `/bdscout`) is a separate developer addon. It holds the scraper (Scout.lua, Sweep.lua, copied with a namespace core so they run unchanged), its saved roster `BuddyDexScoutDB.roster`, and a list window. On login it takes over `BuddyDexDB.roster` from milestone 1. It also records `faction` and `attackable`.
- **BuddyDex** no longer logs NPCs. `BuddyDexDB.friends[npcID]` holds the NPCs the player has started a friendship with. They reach the Dex the way factions reach the reputation panel: on the first gain.
- **Friendship** (`Core/Friendship.lua`, `ns.Friendship`): tiers follow WoW's friendship reputations, Stranger 0 / Acquaintance 100 / Buddy 300 / Friend 600 / Good Friend 1000 / Best Friend 1500, scaled by rarity (elite ×1.5, rare ×2, rare elite ×2.5, boss ×3). **Buddy** befriends (it can join you); **Friend** unlocks the story.
  - **Gains, once per kind per NPC per day:** talk 40 (GOSSIP_SHOW, QUEST_GREETING), shop 60, train 60, service 50 (taxi, bank, auction house), quest 100 (QUEST_DETAIL/PROGRESS/COMPLETE), any friendly emote 25, favorite emote 150, rude emote −25. Emotes only count with NPCs already met: they deepen a friendship but never start one, so NPCs with nothing to say (guards, townsfolk) stay out of the Dex (user, 2026-10-10). Letting a lore entry opt such an NPC in was considered and declined: no exceptions. NPCs named for what they are rather than who (Stormwind City Guard, Ironforge Mountaineer, Protector of the People: the name ends in a role word, or has "of the") can't be befriended even when they can be talked to: the game gives every one of them the same NPC ID, so one friendship would cover them all (user, 2026-10-10). A named one (Guard Thomas) is someone; a lore entry makes anyone someone. `Friendship.IsSomeone`; old friends breaking the rule leave the Dex at login.
  - **Who counts:** the NPC is the `"npc"` unit for interactions. An `"npc"` unit that doesn't qualify counts for nobody, never for the target. Only when the client won't name an `"npc"` unit for a window only an NPC opens (merchant, trainer, taxi, bank, auction house) does the target stand in; gossip and quests also come from objects (a wanted poster), so they never fall back; for emotes, a `hooksecurefunc("DoEmote")` post-hook uses the named unit or the target. The NPC must be friendly: not a player, not player-controlled, `UnitReaction` ≥ 4, not `UnitCanAttack`, out of combat, identity not restricted.
  - **Favorite emotes** come from the title and type: guards /salute, merchants /thank, trainers and nobles /bow, cooks and engineers /cheer, priests /pray, performers /applaud, critters and beasts /pet, flight masters /wave, everyone else /wave. An entry in `Data/Lore.lua` can name its own (`favorite = { emote, hint }`). The Dex shows a hint until the player finds it.
- **Presentation** (`UI/Toast.lua`): a reputation-style chat line, a toast card with portrait and rep bar (an AnimationGroup fade), and sounds on tier-ups (`UI_GARRISON_TOAST_FOLLOWER_GAINED` for Buddy, `UI_70_ARTIFACT_FORGE_TRAIT_RANKUP` otherwise). Settings `announce`, `toasts` and `sounds` toggle each.
- **Dex:** rep-style list grouped by collapsible zone headers (current zone first). Rows show tier text and Forever's own rep bar (`ColoredProgressBarTemplate`; white, green, blue by tier). Filters: buddies only, current zone, type, rarity; sorts: last visited, name, friendship, level. The detail header shows tier and bar; Details shows Area with map coordinates, Met, Last visit, Visits and Favorite (hint or emote); the entry unlocks by tier (below).
- **Tests:** `tools/tests/smoke.py` runs both addons' sessions and the API audit against `blizzard_api.lua`.

## Lore and waypoints (user, 2026-10-10)

- **BuddyDex entries** (`Data/Lore.lua`, `ns.Lore[npcID]`): written for BuddyDex, since most NPCs have no official story. Parts unlock like rewards on a reputation track: `quote` at Acquaintance, `likes`, `dislikes` and `gossip` (Word Around Town) at Buddy, `bio` (Story) and `backstory` at Friend, `secret` at Good Friend, `bestFriend` at Best Friend. `favorite` and `lines` work from the start. Every entry fits a budget (user 2026-10-10: decide the size "before we mass create lore"): 3/6/6/4/3 lines, 21 in all, and about 15 lines of their own on top of 356 general ones ("the problem with too many lines is the sheer number of NPCs"); the tests check it. The writing guide, with Thor (NPC 523) as the worked example, is `docs/LORE.md`.
- **The entry cards** (`UI/DexDetail.lua`, user layout 2026-10-10): **Personality** under the model holds the quote (centered) and likes and dislikes side by side; the **Lore** column down the right of the window (360 wide, level with the friends list and headed like its zone rows: the book icon, "Lore", and "3 of 5 pages" on the right, with the Friends and Buddies cards above it the way search and filter sit above the list; the window is 1414 x 760 for it, and `FitToScreen` scales it down on screens too small) is a page of sections (Story, Secret, Just Between Friends), each with a gold header, the tier that opens it on the right in the friendship bar's color, and a fading gold rule; a locked section stays in place, dimmed, saying what it takes ("Reach Friend with Thor to hear his story."), the next one brighter. A footer shows a dot per page, gold once unlocked, and "Every page unlocked" at the end. Spoken lines (the quote, the best-friend line) are in the NPC-speech color. Both scroll (`ScrollUtil.InitScrollFrameWithScrollBar` with a `MinimalScrollBar` that hides when everything fits). `Detail.LoreParts(npcID, entry)` builds the text and is what the tests check. `/bd lore` (left out of the help) is the writers' preview: every part shows whatever the friendship, until it is turned off or the UI reloads.
- **Where friends are:** every gain saves the player's position (`C_Map.GetBestMapForUnit` and `C_Map.GetPlayerMapPosition`, four decimals) as `entry.mapID`, `entry.x` and `entry.y`, since the player is standing next to the NPC. Kept current, because some NPCs wander. Unavailable in instances.
- **Waypoints** (`Core/Waypoint.lua`, `ns.Waypoint.Set(npcID)`): TomTom's arrow when TomTom is loaded (`TomTom:AddWaypoint(mapID, x, y, { title, from = "BuddyDex", persistent = false, crazy = true })`), otherwise the game's own pin (`C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(...))` and `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`). It plays `UI_MAP_WAYPOINT_SUPER_TRACK_ON` and says in chat what it did. Reached from the "Set waypoint" button on the model card and the row's right-click menu, both grayed out until the friend's position is known.
- **Testing commands** (left out of `/bd help`): `/bd lore` (above), and `/bd give <amount or tier>` ("200", "-50", "buddy", "best friend"), which changes the friendship of the target (starting one if they qualify) or else of the NPC the Dex shows. It passes the daily caps and stops at 0 and at Best Friend (`Friendship.Meet`, `Friendship.Add`). It fires the real events, so chat lines, toasts and tier sounds play.

## Milestone 2, first slice: the Mini Me on screen (2026-10-10)

- **`UI/MiniMe.lua`** (`ns.MiniMe.Create`), moved out of Pages.lua: the gnome-in-your-armor ModelScene, used by the Buddy page and the companion.
- **`UI/Companion.lua`** (`ns.Companion`): `BuddyDexCompanion`, a 150 x 190 button on UIParent with the Mini Me in it. Drag to move (position per character, `BuddyDexCharDB.companionPoint`), click to poke (a line and a random emote), right-click for its menu (say something, dance, open the BuddyDex, voice and chatty toggles, a voice picker, hide). It turns to face the middle of the screen. It fades out in combat and back in after. Speech uses Blizzard's own `ChatBubbleTemplate` (Blizzard_ChatBubble, always loaded), sized for the whole line first, with the words fading in through `FontString:SetAlphaGradient` like quest text, then held for a reading time and faded out. Animations asked for before the model loads play once it does.
- **`Core/Voice.lua`** (`ns.Voice`): `C_VoiceChat.SpeakText(voiceID, text, rate, volume, overlap)` with the OS voices from `C_VoiceChat.GetTtsVoices`; the voice is chosen by name (`settings.voiceName`), else the first. Color codes and icons are stripped before speaking.
- **`Data/Lines.lua`** (`ns.Lines`): the Mini Me's lines by moment, with `{name}`, `{zone}`, `{level}`, `{friend}`, `{tier}`, `{friends}` tokens.
- **`Core/Reactions.lua`** (`ns.Reactions`): greeting after login (time of day) or reload; level up; death and coming back; quest turned in; new zone; new gear; resting; away (it sleeps, and wakes with a wave); new friend, new tier, new Buddy. Big moments (greeting, level, Buddy) always speak; the rest are small comments that need `chatty`, wait 10 s after a load, never talk over a line, keep 8 s apart and have per-kind cooldowns. Idle chatter every 4 to 8 minutes, sometimes just a dance or a flex.
- **Settings:** `companion`, `voice`, `chatty` (all on by default), on the settings page under "Your Mini Me" and in its menu. `/bd buddy` shows or hides it; the Buddy page has a Show/Hide button.
- **Bring along** (user, 2026-10-10): a friend at Buddy tier or better can stand in the Mini Me's place (`Companion.SetBuddy(npcID)`, saved per character as `companionNpc`). They are drawn with `DressUpModel:SetCreature`, as in the Dex, and play only animations their model has (else talk, else stand). They speak their own `lines` from `Data/Lore.lua` (any moment key), else the general `ns.NpcLines`. Chosen from the model card's Bring along / Send home button, the row menu, or the buddy's own menu (a Bring along list). A friend whose friendship falls below Buddy, or who is forgotten, goes home and the Mini Me returns.
- **Pinned friends:** "Pin to top" in a row's menu puts a friend in a Pinned group above every zone (`dex.pinned`, account-wide).
- **Model polish:** the Mini Me stays invisible until its camera is aimed from the real bounding box, then fades in (no zoom pop); gear changes redress it once the swap settles (`PLAYER_EQUIPMENT_CHANGED` and `UNIT_MODEL_CHANGED`, 0.4 s quiet, ClearModel first).
- **Next:** walking about, levels and XP, a recorded voice (below).

## Buddy options, voices and the line library (user, 2026-10-10)

- **Options live on the Buddy tab** (`UI/Pages.lua` `BuildBuddy`): who's out on the left (the Mini Me or the friend on a stage, a Who's out dropdown, Show/Hide, Say something, Reset position), then two columns. **Voice:** On or Off, and Test voice. **Chatter:** one Chattiness slider (Quiet to 100%, default 50%; it replaced the comments checkbox and the idle and fight chatter choices) and echo lines to chat. At Quiet it only answers pokes and emotes; low, big moments only; 50%, most comments, idle chatter every 4 to 8 minutes, some fights get words; 100%, every comment, idle chatter every 2 to 4 minutes, fights twice as talkative. The gap between comments (8 to 30 seconds) and each kind's cooldown stretch as it drops; below about 60% some comments go unsaid. **Behavior:** in combat (Stay on screen / Hide), hide in dungeons, raids and battlegrounds, nap when away, lock in place, let clicks pass through. **Look:** size (50 to 200%), opacity (20 to 100%), facing (toward the middle, left, right, straight out), hide weapons. Defaults in `Core/Database.lua`; older voice settings (on/off, text to speech, game voice) become `voiceMode` "recorded" or "off". The buddy's right-click menu keeps only Say something, Dance, Bring along, Open the BuddyDex, Buddy options and Hide (user: "keep most of the options in the options window"). `/bd options` opens the tab.
- **Voice** (`Core/Voice.lua`, user 2026-10-10: "The only voices we will use are the 11labs ones"): the Mini Me's own voice, recorded with ElevenLabs (below), from the optional BuddyDex Voice addon. Text to speech and the game's voice emotes were removed. Until every line is recorded (the goal), a line without a clip speaks in the bubble alone. Friends who come along speak in the voice the game gives their model (user: "NPCs should only have their normal in game sounds"): `Data/NpcSounds.lua`, made by `tools/data/npc_sounds.py` from the DB2 tables CreatureDisplayInfo (each display's NPCSoundID) and NPCSounds (greeting, farewell and annoyed sound kits), maps about 6,000 displays to 183 sets as one string. A greeting when they arrive or are poked, the annoyed kit when poked too often, a farewell when they go home or the player steps away, and a greeting with half their other lines. **Recorded friend voices** (user: "Gnomes first"): a friend whose display's race has recorded voices (`Voice.RACE_VOICES`: gnomes, sharing the Mini Me's two voices, and humans, "BuddyDex Human Male (Steady)" O7V4YABJUNMVqaNkOPe8 and "BuddyDex Human Female (Guard)" PlKpB8vhnGrFk9fhJGWb, and dwarves (Scottish, as in the game), "BuddyDex Dwarf Male (Mountaineer)" tNPIWbrnyCsbmVIg3tPK and "BuddyDex Dwarf Female (Barmaid)" aRtvtMA33YE3hteCIrqs, and night elves, "BuddyDex Night Elf Male (Druid)" I9kX73xcHhkTOd7JNhet and "BuddyDex Night Elf Female (Priestess)" XcBDzfqZip1cdcLC3B2W, and Forever's Skyborne (ChrRaces 95 High Order and 96 Windshaper, one voice pair), "BuddyDex Skyborne Male (Windshaper)" 8chV49fDd6WKeqeufgPU and "BuddyDex Skyborne Female (Scholar)" lQ79RJ1oEygPMVWvoXTH, all picked by the user from Voice Design samples; `bodies` in `Data/NpcSounds.lua` gives the race and sex of those displays) speaks each line in that voice when the installed pack has it, or in the bubble alone when the line isn't recorded, and leaves without the game's farewell. `tools/voice/generate.py --npc` records the general friend lines, `--lore <npcID>` a friend's own (in the voice for their race and sex); fill-in lines have `say` texts. Thor (display 3263) uses human male set 49, shared with Lawrence Schneider. Everything plays on the Dialog channel, so the game's dialog volume sets the level.
- **The line library:** `Data/Lines.lua` (the Mini Me, 441 lines over 60 moments) and `Data/NpcLines.lua` (friends who come along, 356 lines), a friend's own `lines` mixed in. Lines are strings or tables with `anim`, `voice`, and conditions (`time`, `zone`, `class`, `min`/`max` level, `after` seconds of session). Each moment draws from a shuffled deck: nothing repeats until its pile is used, and the last four of each are remembered across sessions (`BuddyDexCharDB.recentLines`). Animations never repeat back to back.
- **Moments** (`Core/Reactions.lua`): greetings by time of day, reload, poke (and too many pokes), idle, level up, max level, death, coming back, quest done and taken, zone, gear, rested, away and back, combat start (a battle cry or a stance) and end (a celebration, words sometimes), gryphon flights and landings, mounting, rare or better loot (the player's own, by looter GUID or name), mail, full bags, joining a group, entering a dungeon, hearthing, learning a skill, targeting a friend, and the player's own emotes with nothing targeted (it waves back, dances along, blushes at a kiss).

## Recorded voice (user 2026-10-10)

- The Mini Me's lines recorded with ElevenLabs text to speech, shipped as the optional BuddyDex Voice addon (like DBM's voice packs): the addon's only voice. Gnome voices: male `ouL9IsyrSnUkCmfnD02u` (Voice Library, Grimblewood Thornwhisker), female `syFkX6FF9X5Ae3tA21pD` ("Mini Me Gnome (Female)", designed for BuddyDex with Voice Design; library voices can't be remixed, and the game's own voice actress isn't ours to clone) (`--voice male|female` in `tools/voice/generate.py`). Eleven v3 with emotion tags: each moment has a default tone, a line can set its own (`tone` in `Data/Lines.lua`, never shown in the bubble).
- Size: the 380 lines are about 16,000 characters, about 20 minutes of speech per voice: about 5 to 7 MB as mono OGG at 32 to 48 kbps (19 MB as ElevenLabs' default 128 kbps MP3). Two voices double it.
- 75 lines have fill-ins ({name}, {friend}, {level}, {zone}, {item}...) that can't be recorded as written: record them without the fill-in (the bubble still shows it), skip their voice, or rewrite them.
- The API key is kept outside the repo and the AddOns folder; never commit or print it.
- **Goal (user):** every line recorded, in both voices: the fill-in lines get a `say` text to record without the fill-in, and friends who come along speak in their own in-game voices. Text to speech and the game voice are already gone.
- **Built:** `tools/voice/generate.py` records with Eleven v3 (user: "definitely v3"), skips fill-in lines and anything already recorded with the same model and text, and writes `voice/<voice>/manifest.json` plus `voice/Manifest.lua`. `voice/` is the **BuddyDex Voice** addon (`BuddyDex_Voice.toc`, `Dependencies: BuddyDex`), deployed by `tools/deploy-voice.sh`; `.pkgmeta` keeps it out of the main package. Its `BuddyDexVoicePack` maps each line's exact text to a clip, so an edited line never plays stale audio. With the pack installed and the voice on, the Mini Me plays the clip for the line it draws (`PlaySoundFile` on the Dialog channel, the last clip stopped first).

## Fights and the ghost walk (user, 2026-10-10)

- The buddy stays on screen in a fight (the default). Forever keeps combat details secret from addons, so it reacts to time rather than the fight: a battle cry or a stance at the start, a cheer from the sidelines 8 to 14 seconds in now and then (`combatMid`, many of them for the player's class: "Yeah! Hit him with a fireball!"), encouragement 30 seconds into a long fight (`combatLong`), a celebration at the end. A fight counter keeps a cheer meant for one fight out of the next.
- Releasing as a ghost has its own lines (`ghost`, the corpse run).
- At 15% health or less in a fight (`lowHealth`), once a fight at most, now and then: "We're gonna be running back from the graveyard, huh?" and class lines ("Ice block! Ice block!"). Forever may keep the player's health secret in combat; the first read is noted in `BuddyDexDB.probe.healthInCombat` ("readable" or "secret") to check in game.
- Fight words are rare on purpose (user: "Line shouldn't always fire"): the chance of a battle cry, a sideline cheer, encouragement, a low-health line and victory words (`Reactions.FIGHT_CHANCES`, at full chattiness) scales with the Chattiness slider, and long cooldowns space them out; otherwise the buddy just gestures.
