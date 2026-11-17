--!strict
--[[
	TryOn: trying a wrap colour on at a mirror (S5-03f4a, idea 24, D-318), as numbers and the pure
	maths of it. The moment: you press Try on at the mirror, turn once round as the film winds up
	you from the ankles, and there you are in the glass wrapped in pink film for a few seconds; then
	it loosens with a crinkle, slumps to a heap round your ankles and fades. Every Roblox avatar
	shop's try-on button, and DOORS' and Fortnite's look before you buy; the film and its wind are
	the catch's own (Kept), so the colour you try is the one a friend would find you in.

	Free, and nothing you own changes: no save is touched. Each press tries the next colour on the
	counter's shelf (WrapColours.Shelf), round and round, owned or not. The server makes the film
	(TryOns) and holds you still facing the glass while it's on; every screen winds it on and peels
	it off from when it went on (TryOnView), and the mirror shows it (MirrorView).
]]
local Kept = require("./Kept")
local WrapColours = require("./WrapColours")

local TryOn = {}

-- The film's tag (so every screen finds it however it streams in) and its attributes, set by the
-- server: when it went on (the server's clock) and which way the body faced before it turned to
-- the glass (radians about the up axis, as CFrame.Angles turns it).
TryOn.Tag = "TryOnFilm"
TryOn.WoundAttribute = "TriedAt"
TryOn.FromAttribute = "TriedFrom"
-- The glass's middle (a Vector3), set by the server too: your own view turns to it as the film
-- winds on, so a Try on pressed from the counter's shop, facing the counter, still shows you the
-- glass (S5-03f4b).
TryOn.LookAttribute = "TriedLook"

-- The mirror's button: one verb. On R (and the pad's Y), apart from the clothes rail's E beside it.
TryOn.Press = "Try on"
-- Studs from the glass you can press from, and the slack the server forgives a moving player.
TryOn.Reach = 7
TryOn.Slack = 3
-- Studs more to either side of a glass's half width that the server forgives a shop's Try on
-- (TryOn.inLine), for a body still settling as the press arrives.
TryOn.SideSlack = 1
-- The least distance across the floor from the glass's middle that still gives a way to face it.
TryOn.Closest = 0.5
-- Presses a second, and a short burst: one try-on runs for seconds anyway.
TryOn.Limit = { perSecond = 1, burst = 2 }

-- Seconds the film takes to wind on as you turn once round: quicker than the catch's, so the
-- funny part comes fast.
TryOn.Wind = 1.1
-- Seconds your own view takes to turn to the glass as the film starts up you (TryOnView): quick,
-- so you're looking before it's past your knees.
TryOn.Look = 0.45
-- Seconds you stand wrapped, looking: long enough to turn your camera about and laugh.
TryOn.Show = 3
-- The film coming off: as the catch's tear (Kept.Tear) but gentler and quicker, a loosening
-- rather than a rip, no lean, a short lie at your ankles and a quick fade.
TryOn.Peel = {
	yank = 0.1,
	bulge = 0.06,
	fall = 0.55,
	heap = 0.16,
	wide = 0.8,
	deep = 1.6,
	settle = 0.14,
	tilt = 0,
	rest = 0.3,
	fade = 0.45,
	see = 0.35,
} :: Kept.Peel

-- The film's sounds, heard round you to `Hearing` studs. The zip as it winds on: the catch's
-- squeal (Kept.Squeal) cut short and pitched up, a quick zzzip off the roll, not the dread of the
-- dark. The crinkle as it loosens: "Plastic Bag Handling Crunchy Cellophane 8" (Kept.Heap) pitched
-- up. The heap's soft crunch as it lands at your ankles: the same, as it is.
TryOn.Zip = { id = Kept.Squeal.id, from = 0.9, length = 0.8, volume = 0.9, pitch = 1.3 }
TryOn.Crinkle = { id = Kept.Heap.id, from = 0.36, length = 0.55, volume = 2.4, pitch = 1.15 }
TryOn.Land = { id = Kept.Heap.id, from = 0.36, length = 0.6, volume = 1.4, pitch = 0.9 }
TryOn.Hearing = 25

-- The film `t` seconds after it went on: its height from the feet, width and depth as shares of
-- its full size, its part Transparency, and how far the body has turned toward the glass (0 to 1).
export type Pose = { height: number, wide: number, deep: number, see: number, turned: number }

--- The colour a press tries after `last` (an offer name, or nil): the next on the shelf, the
--- first after the last, or after anything that isn't a colour.
function TryOn.next(last: string?): string
	local shelf = WrapColours.Shelf
	for i, colour in shelf do
		if colour.name == last then
			return shelf[i % #shelf + 1].name
		end
	end
	return shelf[1].name
end

--- Whether someone standing at `at` is in front of a glass whose picture's middle is `c` and which
--- looks along `n`: within `reach` of it across the floor, on its picture's side, and not in it.
function TryOn.before(c: Vector3, n: Vector3, at: Vector3, reach: number): boolean
	local to = at - c
	local flat = math.sqrt(to.X * to.X + to.Z * to.Z)
	return flat <= reach and flat >= TryOn.Closest and n:Dot(to) > 0
end

-- Whether someone at `at` sees themself in a glass whose middle is `c` and whose right (across
-- its face, level) is `right`: your reflection is straight out from you along the glass, so you
-- show in it only while you stand within `half` of its middle to either side. Half the glass's
-- width shows you at least half in it (S5-03f4b2: from the counter, 1.7 studs aside of the
-- 2.4-wide glass, you were a pink sliver at its edge).
function TryOn.inLine(c: Vector3, right: Vector3, at: Vector3, half: number): boolean
	return math.abs((at - c):Dot(right)) <= half
end

--- Seconds from the film going on until it's gone.
function TryOn.length(): number
	return TryOn.Wind + TryOn.Show + Kept.tearLength(TryOn.Peel)
end

--- Whether someone whose film went on at `wound` (nil for none) is still trying one on at `now`.
function TryOn.busy(wound: number?, now: number): boolean
	return wound ~= nil and now < wound + TryOn.length()
end

--- The film's pose `t` seconds after it went on (`Pose`).
function TryOn.pose(t: number): Pose
	if t < TryOn.Wind then
		local rise, turn, clear = Kept.wind(t / TryOn.Wind)
		return {
			height = rise,
			wide = 1,
			deep = 1,
			see = Kept.WrapBlend + (1 - Kept.WrapBlend) * clear,
			turned = turn / (2 * math.pi * Kept.WindTurns),
		}
	end
	local p = Kept.tearPose(t - TryOn.Wind - TryOn.Show, TryOn.Peel)
	return { height = p.squash, wide = p.wide, deep = p.deep, see = p.see, turned = 1 }
end

--- The body's facing (radians about the up axis), `turned` (0 to 1) of the way from `from` round
--- to `to`: once round, the way the shorter turn goes, so it ends facing `to`.
function TryOn.turn(from: number, to: number, turned: number): number
	local tau = 2 * math.pi
	local delta = (to - from + math.pi) % tau - math.pi -- the shorter way, -pi to pi
	local total = if delta >= 0 then delta + tau else delta - tau
	return from + total * turned
end

return table.freeze(TryOn)
