-- SPDX-License-Identifier: GPL-2.0-or-later
local ADDON_NAME, ns = ...

-- Data/Moves.lua: the "moves" the BuddyDex can play on an NPC's model, and
-- the check that finds which of them a given model really has. The emote
-- IDs were each confirmed by HasAnimation on a gnome model in this client.
-- The creature moves at the end are standard AnimationData IDs that no
-- model has confirmed yet, which is safe because nothing is offered until
-- the model in hand says it has the animation (Moves.Probe).

local Moves = {}
ns.Moves = Moves

-- The resting animation (Stand) a model goes back to after a move.
Moves.IDLE = 0

-- Same secret guard as Data/Art.lua: ns.Util.Plain when Core/Namespace.lua
-- loaded, a local copy of the check otherwise.
local function Plain(v)
    local util = ns.Util
    if util and util.Plain then return util.Plain(v) end
    if issecretvalue and issecretvalue(v) then return nil end
    return v
end

-- The contract writes an entry as { id, label }, so each one carries both
-- the named fields and the same values by position: move.id is move[1]
-- and move.label is move[2].
local function Move(id, label)
    return { id = id, label = label, id, label }
end

-- In the order the Dex offers them. Emotes come first, so a humanoid's
-- buttons fill with emotes before attacks; beasts support few emotes,
-- which leaves room for the creature moves after them. Labels are short
-- because they sit on 64 px buttons.
Moves.LIST = {
    Move(60, "Talk"),
    Move(66, "Bow"),
    Move(67, "Wave"),
    Move(68, "Cheer"),
    Move(69, "Dance"),
    Move(70, "Laugh"),
    Move(73, "Rude"),
    Move(74, "Roar"),
    Move(75, "Kneel"),
    Move(76, "Kiss"),
    Move(77, "Cry"),
    Move(78, "Chicken"),
    Move(79, "Beg"),
    Move(80, "Applaud"),
    Move(81, "Shout"),
    Move(82, "Flex"),
    Move(83, "Shy"),
    Move(84, "Point"),
    Move(97, "Sit"),          -- SitGround, the sitting loop
    Move(100, "Sleep"),       -- the sleeping loop
    Move(113, "Salute"),
    -- Creature moves, unconfirmed. AnimationData puts SpellCastOmni, the
    -- cast itself, at 54; 52 is ReadySpellOmni, the pose held before it.
    Move(16, "Attack"),       -- AttackUnarmed: claws, bites and fists
    Move(17, "Swing"),        -- Attack1H: a one-handed weapon swing
    Move(54, "Cast"),         -- SpellCastOmni
}

local LABELS = { [Moves.IDLE] = "Idle" }
for _, move in ipairs(Moves.LIST) do
    LABELS[move.id] = move.label
end

-- The button label for an animation ID. A cached moves list can outlive a
-- change to LIST, so an ID this file no longer knows still gets a usable
-- name rather than a blank button.
function Moves.Label(id)
    id = Plain(id)
    if type(id) ~= "number" then return nil end
    return LABELS[id] or ("Move %d"):format(id)
end

-- The IDs from LIST the model can play, in LIST order. HasAnimation only
-- answers for a model whose file has loaded, so call this from the
-- model's OnModelLoaded. HasAnimation exists on PlayerModel and
-- DressUpModel frames, not on ModelScene actors; anything without it gets
-- an empty list. Each question is asked under pcall so one bad answer
-- cannot cost the rest.
function Moves.Probe(model)
    local found = {}
    local hasAnimation = model and model.HasAnimation
    if type(hasAnimation) ~= "function" then return found end
    for _, move in ipairs(Moves.LIST) do
        local ok, has = pcall(hasAnimation, model, move.id)
        if ok and Plain(has) then
            found[#found + 1] = move.id
        end
    end
    return found
end
