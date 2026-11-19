--!strict
--[[
	HandPlace: setting a held find down where you look in your own home, without opening Arrange
	(S5-03j5a, D-463). The moment: holding the teddy, you look at the job box's top and a faint
	teddy sits there, snapped and turned to the room; Drop reads Place, and one press sets it down
	with the landing's knock. Precedents: Grow a Garden's held egg or seed shown where it will go in
	your garden, Minecraft's outline of the block before you place it, Animal Crossing's and The
	Sims' place-from-hand.

	Shared by the screen (HandPlaceView, which aims and judges with `PlaceAim`, as Arrange does)
	and the server (Arranging's `onHandPlace`, which judges the ask again as it judges a Place).
	The ask names no find: what's in your hand is the server's to know (`Slots:heldFromBox`).
]]
local HandPlace = {}

HandPlace.Remote = "HandPlace" -- in Spots.RemoteFolder: (on, x, y, turn), the held find set there
HandPlace.Verb = "Place" -- Drop's word while the faint copy shows
-- Studs from you to where it would stand: how far a look still sets a thing down. A step past a
-- find's Take reach (8), so a top across a small room is in reach from the door.
HandPlace.Reach = 10
HandPlace.Slack = 3 -- studs past it the server allows, for a screen a beat behind

-- The faint copy: how see-through it is (0 solid, 1 gone) and how quickly it fades in or out,
-- and how quickly it glides to a new spot (seconds); it never turns green or red (the plan's
-- "green-free": nowhere it fits, it simply isn't there).
-- Seen in Studio at phone size (S5-03j5a2): 0.6 washed out on a grey-green top, 0.4 read as the
-- find already standing there. A white outline was tried and dropped: Roblox draws a Highlight
-- only on opaque parts (STUDIO.md).
HandPlace.Faint = 0.5
-- It breathes, a little more and less see-through, so it reads as where it'd go rather than a
-- find set out: how far (in transparency, each way) and one breath's length (seconds).
HandPlace.Breathe = 0.08
HandPlace.Breath = 1.6
HandPlace.Fade = 0.12
HandPlace.Glide = 0.08

-- The player attribute that says slot `i` holds a find out of their own job box that they may
-- set down by hand (true, or absent), written by Slots beside the slot's key.
function HandPlace.slotAttribute(i: number): string
	return `ToolOwnBox{i}`
end

--[[
	The kept spot (S5-03j5b1, D-465). The moment: you take the lamp off the job box to carry it
	about; a fainter, still lamp stays where it stood; change your mind, look back at it, and the
	copy clicks into that very spot. Precedent: The Sims' and Animal Crossing's picked-up furniture
	leaving its footprint to drop back into.

	The server keeps where a find stood when you Take it (Slots, with the find in your hand) and
	writes it beside the slot's mark (`keptAttribute`, `encode`); it's gone once the find is set
	down anywhere, put away, dropped, given, or you step out of your home (Arranging). It's only a
	pose to aim at: a Place into it is judged again as any Place is, so a stale one is refused as
	any far or bad ask is.
]]

-- How see-through the kept spot's copy is: fainter than the copy where you look (`Faint`) and
-- still, so it reads as where it stood, not where it would go.
HandPlace.KeptFaint = 0.78
-- Studs from the look to the kept spot's middle that still snap the copy into it: a step either
-- way, so a glance back at it is enough, never so wide it steals a spot beside it.
HandPlace.Snap = 1.25

-- The player attribute holding slot `i`'s kept spot (`encode`'s text, or absent).
function HandPlace.keptAttribute(i: number): string
	return `ToolKept{i}`
end

export type Pose = { on: string, x: number, y: number, turn: number, top: number? }

-- A pose as an attribute's text: "on|x|y|turn".
function HandPlace.encode(pose: Pose): string
	return string.format("%s|%.3f|%.3f|%.1f", pose.on, pose.x, pose.y, pose.turn)
end

local function finite(n: number?): boolean
	return n ~= nil and n == n and math.abs(n) < 1e4
end

-- `encode`'s text back to a pose, or nil for anything else (an attribute is read as it comes).
function HandPlace.decode(text: unknown): Pose?
	if type(text) ~= "string" or #text > 120 then
		return nil
	end
	local on, x, y, turn = string.match(text, "^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
	local nx, ny, nt = tonumber(x), tonumber(y), tonumber(turn)
	if not (on and finite(nx) and finite(ny) and finite(nt)) then
		return nil
	end
	return { on = on, x = nx :: number, y = ny :: number, turn = nt :: number }
end

-- Whether a look from `origin` along unit `dir`, seeing as far as `far` studs, passes within
-- `Snap` of `at` (the kept spot's middle) in front of you and not behind what you see.
function HandPlace.snaps(origin: Vector3, dir: Vector3, far: number, at: Vector3): boolean
	local to = at - origin
	local along = to:Dot(dir)
	if along <= 0 or along > far + HandPlace.Snap then
		return false
	end
	return (to - dir * along).Magnitude <= HandPlace.Snap
end

-- Whether `at` stands inside a room laid at `face` (its middle `centre` and `size` in the face's
-- own space), counting a little headroom: where you are "in your home" for the kept spot and
-- for placing by hand.
function HandPlace.inside(face: CFrame, centre: Vector3, size: Vector3, at: Vector3): boolean
	local p = face:PointToObjectSpace(at) - centre
	local h = size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Z) <= h.Z and math.abs(p.Y) <= h.Y + 2
end

return table.freeze(HandPlace)
