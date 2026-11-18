--!strict
--[[
	Shelf: the rules for finds standing on your home's shelf (S5-03c1b, D-284), pure so Lune can
	test them. The moment: your door goes up after a climb and what you brought home stands on the
	shelf, sparkling; walk up and it answers with a soft tink; a kind you'd never owned chimes, turns
	once slowly and shows "New". Precedents: Animal Crossing's museum, Fortnite's locker marks.

	The server (Shelves) stands each spot's find in its cubby, fitted by `fit`, with the attributes
	below; every screen (ShelfView) sparkles the new ones and plays your own walk-up, then tells the
	server (`Remote`), which checks the spot (`spot`) and that you're near before marking it seen.
]]
local Shelf = {}

Shelf.Tag = "ShelfFind" -- on each find standing on a shelf, for every screen
Shelf.FreshAttribute = "Fresh" -- how new it is, as Save.Fresh: 0 seen, 1 new, 2 a kind never owned
Shelf.SpotAttribute = "Spot" -- its spot on the shelf, from 1 (Home.Specs.Shelf.Spots' order)
Shelf.OwnerAttribute = "Owner" -- the UserId whose shelf it stands on
Shelf.FindAttribute = "Find" -- the find's name as saved ("Teddy:Gold" for a Gold), for Arrange's lift
Shelf.RemoteFolder = "Remotes"
-- client → server: Seen(spot), you walked up to the new find on your shelf's spot `spot`
Shelf.Remote = "ShelfSeen"

Shelf.Reach = 7 -- studs from you to a new find that count as walking up to it: in the room, near
Shelf.Every = 0.2 -- seconds between your screen's looks for one in reach (never every frame)
Shelf.Slack = 4 -- the server's extra studs on Reach: you kept walking while the word was on its way
-- Seen asks a player may make: a whole new shelf at once, never a flood
Shelf.Limit = { perSecond = 4, burst = 8 }
Shelf.Lift = 0.02 -- studs a find stands above its board, so its bottom never flickers into it

-- How a new find sparkles until you walk up (the kept glint's texture, slowed to a twinkle).
Shelf.Sparkle = {
	Rate = 3, -- glints a second: enough to catch your eye from the door, never a fountain (1.4 was lost)
	Size = 0.5, -- studs across at its biggest (0.32 vanished at phone size from the door)
	Burst = 12, -- glints thrown as you walk up, before it stops
}
-- A kind you'd never owned, as you walk up: one slow turn on its spot and a small "New" over it.
Shelf.Turn = {
	Seconds = 1.8, -- one whole turn, eased in and out: slow enough to look it over
}
Shelf.Word = {
	Text = "New",
	Height = 0.55, -- studs tall: small, a label on the find, not a headline
	Above = 0.45, -- studs over the find's top
	Pop = 0.3, -- seconds it takes to pop in
	Hold = 2.4, -- seconds it stays
	Fade = 0.6, -- seconds it takes to fade
}

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
-- A new find, as you walk up: a soft tink (the coin's chink, pitched up and quiet: a glass ting).
Shelf.Tink = {
	id = "rbxassetid://9113849162",
	from = 1.08,
	length = 0.4,
	volume = 0.4,
	pitch = 1.4,
} :: Sound
-- A kind you'd never owned: the box reveal's falling twinkles ("Magic Tone Falling Shimmer Flanged
-- 3", loudest from 0.85 s), softer than a box's Rare burst.
Shelf.Chime = {
	id = "rbxassetid://9116418035",
	from = 0.65,
	length = 1.9,
	volume = 0.55,
	pitch = 1.1,
} :: Sound
Shelf.Hearing = 30 -- studs either sound carries: your own room and the hall just outside

-- How a find stands in its cubby: turned about its up by `turn` degrees, `scale` its own size
-- (never grown), its pivot at `offset` from the spot in the turned frame (its bottom's middle on
-- the spot).
export type Fit = { turn: number, scale: number, offset: { number } }

-- How a find whose parts' box in its pivot's frame runs from `low` to `high` (across, up, deep)
-- fits a cubby's `room`: square to the shelf, or a quarter turn when that lets it stand bigger (a
-- long thing lying deep), shrunk to fit and never grown.
function Shelf.fit(low: { number }, high: { number }, room: { number }): Fit
	local tiny = 1e-3
	local across = math.max(high[1] - low[1], tiny)
	local tall = math.max(high[2] - low[2], tiny)
	local deep = math.max(high[3] - low[3], tiny)
	local function scale(a: number, d: number): number
		return math.min(1, room[1] / a, room[2] / tall, room[3] / d)
	end
	local square = scale(across, deep)
	local turned = scale(deep, across)
	local turn = if turned > square + 1e-6 then 90 else 0
	local s = math.max(square, turned)
	return {
		turn = turn,
		scale = s,
		offset = { -(low[1] + high[1]) / 2 * s, -low[2] * s, -(low[3] + high[3]) / 2 * s },
	}
end

-- The spot a Seen ask names, if it names one: a whole number from 1 to `spots`. Anything else
-- (another type, a fraction, NaN, out of range) is nil.
function Shelf.spot(value: unknown, spots: number): number?
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
		return nil
	end
	if value < 1 or value > spots then
		return nil
	end
	return value
end

-- How far along a ray a find's box is first met (S5-03i2b, D-352: in Arrange a tap on a cubby's
-- find lifts the find, not its shelf; the finds stand unpickable, so the screen tests their boxes).
-- The ray runs from `o` along `d`, both in the box's own frame, the box `half` its size each way
-- about its middle. Nil when it misses or the box is behind; 0 when the ray starts inside it.
function Shelf.hit(o: { number }, d: { number }, half: { number }): number?
	local near, far = -math.huge, math.huge
	for k = 1, 3 do
		if math.abs(d[k]) < 1e-9 then
			if math.abs(o[k]) > half[k] then
				return nil -- running alongside, outside it
			end
		else
			local a = (-half[k] - o[k]) / d[k]
			local b = (half[k] - o[k]) / d[k]
			if a > b then
				a, b = b, a
			end
			near = math.max(near, a)
			far = math.min(far, b)
			if near > far then
				return nil
			end
		end
	end
	if far < 0 then
		return nil
	end
	return math.max(near, 0)
end

return Shelf
