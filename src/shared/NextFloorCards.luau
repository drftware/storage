--!strict
--[[
	NextFloorCards: the next-floor cards on a rider's screen (S4-03b2), the rules alone, so Lune
	tests them (tests/nextfloorcards.spec.luau). The screen that draws them is the client's
	NextFloorView; the vote itself is `NextFloor` and the server's NextFloors.

	The moment: the car lurches off and three cards slide up from the bottom of your screen, each a
	picture of a version of the floor you're riding to and the coins it pays. You tap one: it
	clunks, lights in its own colour and your head drops onto it; your friends' heads drop onto
	theirs, so you watch the vote move and can jump to the card your friends are on. On the
	cable's second knock the losers go dark and sink away, and the winner flares and stays lit
	until the gate opens on the floor it picked. Proven: Hades shows each door's reward before you
	pick; a lobby's map vote shows who voted for which map.

	- `layout` sizes and places the three for a screen: a share of its height, so they're big
	  enough to tap on a phone, between the thumbstick and the jump button.
	- `heads` sorts who pressed which, yours first, so each card knows the heads it carries.
	- `headX` spaces a card's heads along its top edge, overlapping when many crowd one card.
	- `phase` says what the cards are doing `since` seconds into the ride.
]]
local NextFloor = require("./NextFloor")
local Ride = require("./Elevator/Ride")

-- The three cards laid out for one screen, in pixels.
export type Layout = {
	-- One card: its picture on top, its coin strip under it.
	cardW: number,
	cardH: number,
	faceH: number,
	-- Between two cards.
	gap: number,
	-- From the screen's bottom edge to the cards' bottom edges.
	bottom: number,
	-- A rider's head dropped on a card, across.
	head: number,
	-- Each card's middle, in pixels right of the screen's middle.
	xs: { number },
}

-- What the cards are doing on a ride: under the floor before the lurch, up for the vote, up
-- after the knock before the server's pick lands, the winner lit, and gone as the gate opens.
export type Phase = "waiting" | "voting" | "closed" | "picked" | "gone"

local Cards = {}

-- A card's height, face and coin strip together, as a share of the screen's height: big enough
-- that the picture reads and a thumb can't miss it on a Galaxy A16 (about 123 of its 280), with
-- the top half of the screen left for the shaft and the car.
Cards.Tall = 0.44
-- A card never shorter or taller than these, in pixels: a tiny window still gets a tappable card,
-- a big monitor doesn't get a wall of them.
Cards.MinTall = 96
Cards.MaxTall = 210
-- Of a card's height, the picture; the rest is the coin strip under it.
Cards.Face = 0.8
-- The picture's width over its height: the faces are rendered 512 by 640 (D-404).
Cards.Aspect = 0.8
-- Between two cards, of a card's width: apart enough that a thumb lands on one.
Cards.Gap = 0.12
-- Under the cards, of the screen's height: off the very edge, where a phone's corners round.
Cards.Bottom = 0.04
-- A rider's head on a card, of a card's width; never under or over these pixels.
Cards.Head = 0.34
Cards.MinHead = 18
Cards.MaxHead = 40
-- Pixels kept clear on each side for the jump button (as the car's panel and the machine's menu
-- keep), so the three stay centred between the thumbstick and the jump.
Cards.Clear = 110
-- The narrowest a card gets on a narrow screen before it may reach into that room, in pixels.
Cards.MinWide = 56
-- Pixels between two heads on a card with room for them all.
Cards.HeadGap = 2

-- The three cards laid out for a screen `width` by `height` pixels (the gui, under the top bar).
function Cards.layout(width: number, height: number): Layout
	local cardH = math.clamp(height * Cards.Tall, Cards.MinTall, Cards.MaxTall)
	local faceH = cardH * Cards.Face
	local cardW = faceH * Cards.Aspect
	local gap = cardW * Cards.Gap
	local n = NextFloor.Offered
	local across = n * cardW + (n - 1) * gap
	local room = width - 2 * Cards.Clear
	if across > room then
		local k = math.max(room / across, Cards.MinWide / cardW)
		if k < 1 then
			cardW, cardH, faceH, gap = cardW * k, cardH * k, faceH * k, gap * k
		end
	end
	cardW, cardH, faceH, gap =
		math.floor(cardW), math.floor(cardH), math.floor(faceH), math.floor(gap)
	local xs = table.create(n)
	for i = 1, n do
		xs[i] = (i - (n + 1) / 2) * (cardW + gap)
	end
	return {
		cardW = cardW,
		cardH = cardH,
		faceH = faceH,
		gap = gap,
		bottom = math.floor(height * Cards.Bottom),
		head = math.floor(math.clamp(cardW * Cards.Head, Cards.MinHead, Cards.MaxHead)),
		xs = xs,
	}
end

-- Who pressed each of `offered`, from `presses` (each rider's press, by UserId): `me` first on
-- the card I'm on, then by UserId, so heads keep their places as others come and go. A press for
-- anything not offered is left out; every offered version has a list, empty if nobody's on it.
function Cards.heads(
	presses: { [number]: string },
	offered: { string },
	me: number
): { [string]: { number } }
	local on: { [string]: { number } } = {}
	for _, name in offered do
		on[name] = {}
	end
	for id, name in presses do
		local list = on[name]
		if list then
			table.insert(list, id)
		end
	end
	for _, list in on do
		table.sort(list, function(a: number, b: number): boolean
			if a == me or b == me then
				return a == me and b ~= me
			end
			return a < b
		end)
	end
	return on
end

-- The middle of head `i` of `n` on a card `cardW` wide, in pixels right of the card's middle:
-- side by side `HeadGap` apart while they fit, closer and overlapping when they don't.
function Cards.headX(i: number, n: number, cardW: number, head: number): number
	if n <= 1 then
		return 0
	end
	local step = math.min(head + Cards.HeadGap, math.max(0, cardW - head) / (n - 1))
	return (i - (n + 1) / 2) * step
end

-- What the cards are doing `since` seconds into the ride, `picked` once the server has named the
-- winner. They come up with the lurch (a car that came back with its pick shows it from there),
-- take presses until the cable's second knock, and go as the gate starts to open.
function Cards.phase(since: number, picked: boolean): Phase
	if since >= Ride.opens() then
		return "gone"
	elseif since < Ride.moves() then
		return "waiting"
	elseif picked then
		return "picked"
	elseif since < NextFloor.Closes then
		return "voting"
	end
	return "closed"
end

return table.freeze(Cards)
