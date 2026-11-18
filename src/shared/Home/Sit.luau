--!strict
--[[
	Sit: where you sit on a home's furniture (S5-03i4, D-353). The moment: you walk up to the milk
	crate in your home and sit on it, the beanbag gives under you, you sit low on the blanket by
	the pallet, and you sit on the camp bed's edge with a friend beside you. As Adopt
	Me's and Bloxburg's furniture: walk up, press Sit, jump to get up.

	Each seat is a Roblox Seat in its piece's own frame (its front toward -Z), turned to face out
	the way the piece does: x, the seat's top and z in studs, and its turn about Y in degrees. You
	sit by its button, never by walking into it, so crossing a blanket on the floor never drops you
	onto it. The seat's top is where you sit, from the piece's top (`Specs.Tops`): the crate's lid,
	the folded blanket, the camp bed's canvas where it rises to its rail at the edge.

	Each seat also says how you sit (`pose`: a chair's sit, or on the floor, where cross-legged
	waits on an animation of our own, D-353), what you
	hear as you land (`sound`), and which part gives under you and how far (`give`: a cushion's
	squash; the crate is wood and doesn't).

	Pure: Lune tests it (tests/homesit.spec).
]]
local Specs = require("./Specs")

export type Pose = "Chair" | "Floor"
export type SoundKind = "Wood" | "Cushion" | "Canvas"
export type Row = {
	x: number,
	top: number,
	z: number,
	turn: number,
	pose: Pose,
	sound: SoundKind,
	give: string?, -- the part that squashes as you land
	squash: number, -- how much of its height it gives, 0 for none
}

local Sit = {}

-- The button's word, its attachment's and prompt's name, and the seat's attributes: the piece
-- it's on (a `Seats` key) and which of that piece's seats it is.
Sit.Verb = "Sit"
Sit.Name = "Sit"
Sit.KindAttribute = "SitKind"
Sit.IndexAttribute = "SitIndex"

-- Studs: how near you stand to press Sit, as near as a find's own button (`Press.Reach`).
-- What it does to the player: walk up to the crate and Sit is there.
Sit.Reach = 8
-- Studs past it the server allows, for a screen a beat behind (`Press.Slack`).
Sit.Slack = 3
-- Studs over the seat's top its button floats: about a seated player's chest, so it shows over
-- the piece, not inside it.
Sit.Above = 1.5

-- Studs the camp bed's canvas rises from its slung middle (its top, `Specs.Tops`) to where you
-- sit on its edge by the rail. What it does to the player: sat on the bed's edge your feet reach
-- the floor, as on the crate.
Sit.Edge = 0.3
-- Studs between the two places on the camp bed: shoulder to shoulder, a friend beside you.
Sit.Apart = 2
-- Studs in from the camp bed's front edge you sit: on the canvas, clear of the rail.
Sit.In = 0.8

-- Seconds your view glides down into the seat (and the cushion's squash takes): the camera eases
-- instead of dropping. What it does to the player: sitting reads as settling in, not a teleport.
Sit.Ease = 0.35
-- Seconds the cushion takes to give under you and to come back up to rest.
Sit.Down = 0.1
Sit.Back = 0.4

local function top(kind: string): Specs.Top
	local tops = Specs.Tops[kind]
	assert(tops and tops[1], `Sit: {kind} has no top`)
	return tops[1]
end

local function row(
	x: number,
	height: number,
	z: number,
	pose: Pose,
	sound: SoundKind,
	give: string?,
	squash: number
): Row
	return table.freeze({
		x = x,
		top = height,
		z = z,
		turn = 0,
		pose = pose,
		sound = sound,
		give = give,
		squash = squash,
	})
end

-- The seats on each piece you can sit on, by piece kind (a `Specs.Pieces` key).
Sit.Seats = table.freeze((function(): { [string]: { Row } }
	local crate = top("MilkCrate")
	local blanket = top("Blanket")
	local bed = top("CampBed")
	local canvas = Specs.Parts.CampBed
	local bedFront = canvas.Centre[3] - canvas.Size[3] / 2 -- the canvas's front edge (-Z)
	local bedZ = bedFront + Sit.In
	local bedTop = bed.At[2] + Sit.Edge
	return {
		-- on the lid, a seat's height: your feet on the floor (tests/homefurniture.spec)
		MilkCrate = { row(crate.At[1], crate.At[2], crate.At[3], "Chair", "Wood", nil, 0) },
		-- sunk low into the bag, a little back from its front: it swallows you
		Beanbag = { row(0, 1.25, 0.1, "Chair", "Cushion", "Beanbag", 0.12) },
		-- on the folded blanket, low: a floor cushion round the coffee table
		Blanket = {
			row(blanket.At[1], blanket.At[2], blanket.At[3], "Floor", "Cushion", "Blanket", 0.25),
		},
		-- two along the bed's front edge, either side of the top's middle, clear of the pillow
		CampBed = {
			row(bed.At[1] - Sit.Apart / 2, bedTop, bedZ, "Chair", "Canvas", "CampBed", 0.1),
			row(bed.At[1] + Sit.Apart / 2, bedTop, bedZ, "Chair", "Canvas", "CampBed", 0.1),
		},
	}
end)())

-- Seat `index` of piece `kind`, nil if it has none.
function Sit.row(kind: string, index: number): Row?
	local seats = Sit.Seats[kind]
	return if seats then seats[index] else nil
end

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }
-- What you hear as you land, at the seat, close by only (a friend beside you hears it). Getting
-- up plays the same, softer (`Sit.Up`).
Sit.Sounds = table.freeze({
	-- the crate: the job box lid's clack, low and short, a hollow wood knock
	Wood = table.freeze({
		id = "rbxassetid://9116436662",
		from = 1.45,
		length = 0.35,
		volume = 0.45,
		pitch = 0.8,
	}),
	-- the beanbag and the blanket: a cloth rub, low, a soft puff of a cushion taking you
	Cushion = table.freeze({
		id = "rbxassetid://9113837381",
		from = 0.55,
		length = 0.4,
		volume = 0.6,
		pitch = 0.7,
	}),
	-- the camp bed: the cloth rub higher and shorter, the canvas taking up the slack
	Canvas = table.freeze({
		id = "rbxassetid://9113837381",
		from = 0.6,
		length = 0.3,
		volume = 0.5,
		pitch = 0.95,
	}),
}) :: { [string]: Sound }
-- Getting up: the landing's sound at this share of its volume.
Sit.Up = 0.5

return Sit
