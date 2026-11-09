-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Unit-frame NPC menus, including BazUI's UnitPopup_OpenMenu integration,
-- carry MENU_UNIT_TARGET and their actual unit in the menu context.
local Util, Friendship = ns.Util, ns.Friendship

local function AddEmotes(_, root, context)
    local unit = context and Util.Plain(context.unit)
    if type(unit) ~= "string" then return end
    local npcID = Friendship.EligibleNpcID(unit)
    local guid = npcID and Util.Read(UnitGUID, unit)
    if not npcID or type(guid) ~= "string" then return end

    root:CreateDivider()
    local submenu = root:CreateButton("BuddyDex Emotes")
    submenu:SetScrollMode(420)
    for _, emote in ipairs(Friendship.EMOTES) do
        local token = emote.token
        submenu:CreateButton(emote.label, function()
            -- A target/focus can change while its menu remains open.
            if Friendship.EligibleNpcID(unit) ~= npcID or Util.Read(UnitGUID, unit) ~= guid then
                ns.Print("That NPC is no longer available. Open their menu again.")
                return
            end
            local name = Util.Read(UnitName, unit)
            if type(name) ~= "string" then return end
            if C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function" then
                C_ChatInfo.PerformEmote(token, name)
            elseif type(DoEmote) == "function" then
                DoEmote(token, name)
            end
        end)
    end
end

if Menu and type(Menu.ModifyMenu) == "function" then
    Menu.ModifyMenu("MENU_UNIT_TARGET", AddEmotes)
end
