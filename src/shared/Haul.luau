--!strict
--[[
	Haul (S4-05b2a, D-416): hauling a floor's big find, its numbers and the step count alone. The
	moment it serves: one friend staggers out of the unit with the jukebox held low in both arms,
	every step slow and heavy, a thud and the rattle of its insides on each, while the others
	watch the halls, as Lethal Company's crew hauls the apparatus to the ship at a crawl.

	A big find (a finds row of size "Big", art/finds/big) takes both hands and slows your walk
	under every monster's hunt (its row's `walkSpeed`, which Slots sets). Each `Stride` studs
	walked lands a heavy step (`Haul.step`): HaulSteps plays its thud and a rattle at the hauler,
	heard by everyone near, and the hauler's own view dips. A press of a tool while you haul it
	answers with the slot box's shake and a `Thunk` in your arms, never words: the jukebox
	filling the bottom of your screen says why. Nothing here touches an Instance, so Lune tests it
	(tests/haul.spec.luau).
]]
local Rows = require("./Finds/Rows")

local Haul = {}

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }

Haul.Stride = 4.2 -- studs walked between two heavy steps: at the jukebox's 9 a second, about two a second, a stagger
Haul.Still = 1.5 -- studs a second under which you're standing, so no step lands
Haul.Reach = 45 -- studs away a hauler's steps are heard: down the hall, so friends know where
Haul.Jolt = 0.12 -- your view's dip as each step lands (CameraShake's trauma; a tool breaking is 0.5)
Haul.Bump = 0.18 -- your view's knock as a tool's press thunks into the find in your arms

-- Each step's weight: "Body Impact 2" (a body's hard thump, the Packrat's laden step), pitched
-- down for something heavier than you.
Haul.Thud =
	{ id = "rbxassetid://9113524237", from = 0.02, length = 0.28, volume = 0.6, pitch = 0.72 }

-- Its insides rattling, one take a step in turn: "Ammo Box Movement 2" (metal knocking about in a
-- box: the record and the changer) and "Chair Impact 12" (plastic knocked: its arch).
Haul.Rattles = {
	{ id = "rbxassetid://9113103014", from = 0.24, length = 0.24, volume = 0.4, pitch = 0.85 },
	{ id = "rbxassetid://9113771767", from = 0.51, length = 0.2, volume = 0.32, pitch = 0.8 },
	{ id = "rbxassetid://9113103014", from = 0.24, length = 0.24, volume = 0.4, pitch = 0.95 },
	{ id = "rbxassetid://9113771767", from = 0.74, length = 0.14, volume = 0.32, pitch = 0.85 },
} :: { Sound }

-- A tool's press while you haul it: the thump of your hand on its cabinet, low and dull.
Haul.Thunk =
	{ id = "rbxassetid://9113524237", from = 0.02, length = 0.22, volume = 0.5, pitch = 0.55 }

-- The big finds' keys (rows of size "Big"), for screens that treat them as hauled.
local big: { [string]: boolean } = {}
for _, row in Rows do
	if row.size == "Big" then
		big[row.key] = true
	end
end

-- Whether catalog key `key` is a big find: hauled, not carried.
function Haul.big(key: string): boolean
	return big[key] == true
end

-- `walked` studs since the last step, plus `moved` more at `speed` studs a second: the studs
-- since the last step after this, and whether a step lands now. Standing (under `Haul.Still`)
-- walks nothing, so a step never lands while you stand still or turn on the spot.
function Haul.step(walked: number, moved: number, speed: number): (number, boolean)
	if speed < Haul.Still then
		return walked, false
	end
	local now = walked + moved
	if now >= Haul.Stride then
		return now % Haul.Stride, true
	end
	return now, false
end

-- The rattle of step `n` (counting from 1): each take in turn.
function Haul.rattle(n: number): Sound
	return Haul.Rattles[(n - 1) % #Haul.Rattles + 1]
end

return table.freeze(Haul)
