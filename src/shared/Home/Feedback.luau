--!strict
--[[
	How Arrange answers what you do with a thing (S5-03j4b; the plan's "Every action answers"
	table, as The Sims 4's build mode answers in hand and ear): how heavy a thing lands, and the
	phone tap each action gives.

	A thing's weight is its catalog row's `heft` (0 to 1): a find's from the finds' rows
	(`Tools.Catalog`), a piece of furniture's from its counter row (`Furniture`). Never its name,
	so a new find or piece lands right with no code. The weights fall into a few bands; each band
	is a thud, a puff of dust and a phone tap, heavier the heavier the thing.

	Pure (Lune specs: tests/feedback.spec.luau). ArrangeHand plays the bands; ArrangeTaps plays the
	taps on a phone.
]]
local Catalog = require("../Tools/Catalog")
local Furniture = require("./Furniture")

local Feedback = {}

-- A sound as Arrange plays it (`Arrange.Sound`'s shape; kept here so this stays pure).
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }

-- A phone tap: a short pulse this strong (0 to 1) over this long (seconds). Played through
-- Roblox's HapticEffect with a custom waveform (docs/STUDIO.md "Phone taps").
export type Tap = { strength: number, length: number }

-- The taps, by the plan's names. Felt, never heard: a light tap is a brush, a firm tap a knock.
Feedback.Taps = table.freeze({
	-- Each grid step of a drag and each quarter of a turn: the faintest, so a long drag never buzzes.
	Tick = table.freeze({ strength = 0.25, length = 0.012 }) :: Tap,
	-- A thing lifted under your finger: it lets go of the floor.
	Light = table.freeze({ strength = 0.4, length = 0.02 }) :: Tap,
	-- Onto a table, into its tray card: a clear tap.
	Tap = table.freeze({ strength = 0.6, length = 0.03 }) :: Tap,
	-- Set down: firm, and the heavy bands firmer still (their own taps below).
	Firm = table.freeze({ strength = 0.85, length = 0.045 }) :: Tap,
	Heavy = table.freeze({ strength = 1, length = 0.07 }) :: Tap,
})

-- The set-down knock every band is pitched from: the job box lid's clack (`Arrange.Knock`).
local KNOCK = "rbxassetid://9116436662"

-- One weight band: everything up to `upTo` heft lands with this thud, this many motes of dust
-- spreading this big (times the light band's), and this tap.
export type Band = {
	name: string,
	upTo: number,
	thud: Sound,
	motes: number,
	spread: number,
	tap: Tap,
}

local function band(
	name: string,
	upTo: number,
	pitch: number,
	volume: number,
	motes: number,
	spread: number,
	tap: Tap
): Band
	return table.freeze({
		name = name,
		upTo = upTo,
		thud = table.freeze({
			id = KNOCK,
			from = 1.45,
			length = 0.5,
			volume = volume,
			pitch = pitch,
		}) :: Sound,
		motes = motes,
		spread = spread,
		tap = tap,
	})
end

-- The bands, lightest first; the last takes everything heavier. A cup ticks down high and quiet
-- with a wisp of dust; the job box thumps down low and loud in a cloud, as you'd expect from what
-- they weigh. Pitch and volume are the knock's own at Medium (1.05, 0.4).
Feedback.Bands = table.freeze({
	band("Light", 0.2, 1.3, 0.28, 5, 0.7, Feedback.Taps.Tap), -- a mug, a teddy, a blanket
	band("Medium", 0.45, 1.05, 0.4, 10, 1, Feedback.Taps.Firm), -- a radio, a crate, the beanbag
	band("Heavy", 0.75, 0.74, 0.52, 16, 1.3, Feedback.Taps.Firm), -- the TV, a folding table
	band("Hefty", math.huge, 0.6, 0.62, 24, 1.6, Feedback.Taps.Heavy), -- the steel shelf, the job box
}) :: { Band }

-- A thing with no heft on its row lands as Medium.
Feedback.Unweighed = 0.3

-- How heavy the thing named `name` is (0 to 1): a placed piece of furniture by its name
-- ("CampBed:Furniture"), else a find by its catalog key.
function Feedback.heft(name: string): number
	local piece = Furniture.ofPlaced(name)
	if piece then
		return piece.heft
	end
	local row = Catalog[name]
	return if row and row.heft then row.heft else Feedback.Unweighed
end

-- The band a thing of `heft` lands in.
function Feedback.band(heft: number): Band
	for _, b in Feedback.Bands do
		if heft <= b.upTo then
			return b
		end
	end
	return Feedback.Bands[#Feedback.Bands]
end

-- The band the thing named `name` lands in.
function Feedback.landing(name: string): Band
	return Feedback.band(Feedback.heft(name))
end

-- Put away: the thing pops into its tray card. The panel's click, low and round.
Feedback.Pop = table.freeze({
	id = "rbxassetid://15675059323",
	from = 0,
	length = 0.15,
	volume = 0.3,
	pitch = 0.8,
}) :: Sound

-- Put away: how long (seconds) the thing takes to fly from where it stands into its tray card,
-- and how small (share of its size) it is when it gets there. Quick enough that a row of put
-- aways never queues; slow enough that you see where it went.
Feedback.Fly = 0.32
Feedback.FlyEnd = 0.12
-- How far in front of the camera (studs) the card's point is taken for the flight's end: near
-- enough that the thing reads as dropping into the tray, far enough not to fill the screen.
Feedback.FlyDepth = 6
-- The card bumps as the thing lands in it: up to this many times its size, and back.
Feedback.Bump = 1.18

return Feedback
