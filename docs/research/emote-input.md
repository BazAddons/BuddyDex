# Chat emotes and NPC unit menus

Checked November 8, 2026 after `/hi`, `/kiss`, `/bow` and `/hug` did not introduce Jenn Langston. Her saved Scout entry identifies NPC 3626 as a friendly human NPC in Stormwind. No live client command was executed by the agent.

## Cause and source

The old tests invoked only `DoEmote`. Forever's [ChatFrameEditBox.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua) instead calls `C_ChatInfo.PerformEmote(hash_EmoteTokenList[command], msg)` directly. The slash alias is resolved before the API receives it, and an empty message leaves the recipient as the current target.

`Util.HookEmotes` now registers secure post-hooks for the current namespace API and the legacy function. Friendship daily caps and companion mirror cooldowns prevent a forwarding legacy call from counting twice. No Blizzard function is replaced by addon code. The mock models secure post-hooks and namespace forwarding so the direct chat path is exercised.

The [API contract](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua) accepts an emote name and optional recipient name. Explicit recipients are resolved against available unit tokens or exact plain names on target, focus, mouseover and npc. Unavailable names never credit an unrelated selected unit.

## Right-click submenu

[UnitPopupShared.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitPopupShared/UnitPopupShared.lua) tags unit popups with `MENU_UNIT_` plus their menu type and passes the actual unit in context. [UnitPopupSharedMenus.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitPopupShared/UnitPopupSharedMenus.lua) registers the non-player TARGET menu. BazUI's unit frames also call `UnitPopup_OpenMenu("TARGET", { unit = ... })` for these units.

`UI/NpcMenu.lua` uses `Menu.ModifyMenu("MENU_UNIT_TARGET", ...)` to add a **BuddyDex Emotes** hover submenu. Choices come from the actual friendship whitelist, with a scrolling submenu for smaller screens. Generic units, players, hostile/owned units and restricted combat identities are excluded. Opening the menu never creates friendship. Actions validate the captured NPC ID and GUID again before sending the emote to that NPC by name; stale target/focus menus cannot credit another unit. Caps do not disable social actions: an already capped emote can still be performed without more friendship.

Smoke tests cover direct chat greetings, daily limits across chat and legacy forwarding, menu-based introductions, focus recipients, stale menus, generic and player rejection, combat, and the Mini Me's response to untargeted chat emotes. In-game menu appearance and live taint behavior still require client verification. A full client restart is recommended after installing the new TOC file entry.
