--!strict
--[[
	Kept: getting kept (L-07a, the GDD's "Getting kept"), as pure rules the server's KeptPlayers
	uses. Pure, so Lune tests it (tests/kept.spec.luau).

	The moment: the keeper's hands close, the screen goes dark through the 2-second wrap (`Caught`),
	and you wake wrapped in a unit somewhere on the floor, the door down in front of you, until a
	friend lets you out. Dead by Daylight's hook and Flee the Facility's freeze pods are the
	precedent: caught, stored, a teammate frees you. Stored in a random unit and never the nearest
	is the GDD's own twist on the hook, so friends have to look.

	Which unit: one whose door is all the way down (not padlocked, not open), with no keeper in it
	(nor the guard's place, D-072) and nobody kept in it already. Never the nearest of those to
	where you were caught while another will do. One nobody has seen into ahead of one that's been
	opened, so you're behind a door friends haven't tried yet, and it holds only you.
]]

local Kept = {}

-- The player attribute the server sets while they're kept (true) and clears when they're let
-- out: keepers leave them alone, and doors, tools, crawls and ladders refuse them. Only the
-- server sets it, so a screen can read it but never fake it.
Kept.Attribute = "Kept"

-- How far into the unit you wake, a share of its depth from the door: past the middle, so the
-- door fills your view and the dark sits between you and it, and off the back wall.
Kept.Back = 0.62

-- Banging (L-07c): alone in the dark, wrapped, you hammer on your door. Down the hall your
-- friends hear it thud and see which door, and so might a keeper. Dead by Daylight's hook is the
-- precedent: everyone sees where you hang, and a teammate comes.

-- Where a kept player's press reaches the server: ReplicatedStorage.Remotes.Bang. It carries
-- nothing; the server knows who's kept and where.
Kept.BangRemote = "Bang"
-- Seconds between bangs that land: the door's own jolt (0.5 s, `Motion`) plays out whole each
-- time, so mashing the button gives two heavy thuds a second, never a rattle.
Kept.BangEvery = 0.55
-- Seconds of that gap the server forgives: presses sent a full gap apart can arrive closer on a
-- jittery connection. Anything faster is a spam and is refused.
Kept.BangSlack = 0.15
-- Seconds each bang marks your unit on friends' screens and the corner map: long enough for a
-- friend mid-hall to look up, find it and set off. The last `BangFade` of it fades out.
Kept.BangMark = 8
Kept.BangFade = 2
-- How hard each press jolts your own view, at once; the door's own shake follows with its thud.
Kept.BangKick = 0.14
-- Seconds the Bang button takes to come up once the screen has opened on the inside.
Kept.BangIn = 1
-- A keeper hears a kept player's bang as far as it hears a trapped keeper's: the same door's
-- thud (DoorSound's Bang, 70 studs along the halls, D-092's hearing).

-- On a laid floor's model (the one the corner map reads, `Minimap.Tag`), from the server: its
-- units' latest bangs (`encodeBangs`), so every screen marks them however far off they are.
Kept.BangsAttribute = "KeptBangs"
-- Under a kept player, from the server once they're inside their unit: an ObjectValue holding
-- it, so their own screen can draw the hall's light under its door.
Kept.InsideValue = "KeptIn"

-- One unit's latest bang: its slot on the floor (what the corner map names it by), who banged
-- (a UserId), when (the server's clock) and where its door's outer face meets the floor.
export type Bang = { slot: number, user: number, at: number, x: number, y: number, z: number }

--- Whether a bang may land at `now` after the last one at `last` (nil: none yet). `slack` (the
--- server's `BangSlack`) forgives a little; a screen asks with none, so it never sends early.
function Kept.ready(last: number?, now: number, slack: number?): boolean
	return last == nil or now - last >= Kept.BangEvery - (slack or 0)
end

--- How strongly a unit is marked `since` seconds after its latest bang: 1, then fading to 0
--- over the last `BangFade` of `BangMark`. A clock a little behind the server's reads as fresh.
function Kept.mark(since: number): number
	if since >= Kept.BangMark then
		return 0
	end
	return math.clamp((Kept.BangMark - since) / Kept.BangFade, 0, 1)
end

--- The bangs still marking units at `now`, as text for the floor's attribute, in slot order:
--- `slot,user,at,x,y,z` joined by `;`.
function Kept.encodeBangs(bangs: { [number]: Bang }, now: number): string
	local slots: { number } = {}
	for slot, b in bangs do
		if Kept.mark(now - b.at) > 0 then
			table.insert(slots, slot)
		end
	end
	table.sort(slots)
	local parts: { string } = {}
	for _, slot in slots do
		local b = bangs[slot]
		table.insert(
			parts,
			string.format("%d,%d,%.2f,%.1f,%.1f,%.1f", b.slot, b.user, b.at, b.x, b.y, b.z)
		)
	end
	return table.concat(parts, ";")
end

--- The bangs in `text` (`encodeBangs`'), skipping any that don't read.
function Kept.decodeBangs(text: string): { Bang }
	local out: { Bang } = {}
	for _, part in string.split(text, ";") do
		local f = string.split(part, ",")
		if #f == 6 then
			local n: { number } = {}
			for i = 1, 6 do
				local v = tonumber(f[i])
				if v == nil or v ~= v then
					break
				end
				n[i] = v
			end
			if #n == 6 and n[1] >= 1 and n[1] % 1 == 0 then
				table.insert(
					out,
					{ slot = n[1], user = n[2], at = n[3], x = n[4], y = n[5], z = n[6] }
				)
			end
		end
	end
	return out
end

-- A unit as the choice sees it: where it stands on the floor (x, z: any one frame, the catch's
-- too), whether its door is all the way down and not padlocked (`shut`), whether anyone has seen
-- into it (`dealt`), whether a keeper is in it or the guard's place is kept there (`keeper`), and
-- whether someone is kept in it now (`holding`).
export type Unit = {
	x: number,
	z: number,
	shut: boolean,
	dealt: boolean,
	keeper: boolean,
	holding: boolean,
}

-- Brix's Random, as `Floor` takes it.
export type Random = {
	nextNumber: (self: any) -> number,
	nextInteger: (self: any, min: number, max: number) -> number,
}

-- The wrap you can see (L-07b): clear stretch film in bands round you head to foot, drawn in
-- Blender round Roblox's default R15 body (art/keptwrap, its numbers in `KeptWrap.Specs`) and
-- scaled per axis to the kept one's box, so friends who open your unit find you wrapped.

-- The film's part in a kept character, and its template's name under ReplicatedStorage.Props.
Kept.Wrap = "KeptWrap"

-- The film's part Transparency. Its see-through look is its colour map's alpha (AlphaMode
-- Transparency), but Roblox only blends that alpha on a part above 0 Transparency; at 0 it cuts
-- the film into hard white shreds (seen in Studio, docs/STUDIO.md). Just above 0, so it blends.
Kept.WrapBlend = 0.02

-- A box as the wrap's fit reads it: its size and its middle (x, y, z, studs), from the
-- character's root, in the root's frame.
export type Box = { size: { number }, centre: { number } }

-- How far the wrap stretches or shrinks on any one axis to fit a body. Past these a body is
-- something odd (a part as wide as a hall, or none at all), and the wrap keeps a person's shape.
Kept.FitMin = 0.5
Kept.FitMax = 2.5

--- The wrap's box for a kept `body` at rest: the wrap as drawn (`wrap`) round the body it was
--- drawn round (`drawn`), stretched on each axis by how much bigger `body` is, and moved with it.
function Kept.fit(body: Box, drawn: Box, wrap: Box): Box
	local size: { number }, centre: { number } = {}, {}
	for i = 1, 3 do
		local s = if body.size[i] > 0 and drawn.size[i] > 0
			then math.clamp(body.size[i] / drawn.size[i], Kept.FitMin, Kept.FitMax)
			else 1
		size[i] = wrap.size[i] * s
		centre[i] = (if body.size[i] > 0 then body.centre[i] else drawn.centre[i])
			+ (wrap.centre[i] - drawn.centre[i]) * s
	end
	return { size = size, centre = centre }
end

-- The film's squeal as the keeper wraps you (L-07b), through the black: a tape screeching off
-- its roll, heard by you in the dark and from where you stood by anyone near. Pro Sound
-- Effects' "Duct Tape Richard Epilates Himself 2": a steady peel from 0.6 to 2.6 s at -24 to
-- -12 dB, centred near 1.5 kHz (measured, docs/STUDIO.md); a touch slow, so it drags.
Kept.Squeal = {
	id = "rbxassetid://9114200236",
	from = 0.6,
	length = 1.9,
	volume = 1.6,
	pitch = 0.92,
}
-- Studs the squeal carries from where you were caught: down your stretch of hall, not the floor.
Kept.SquealReach = 45

--- Whether unit `u` can hold a kept player now.
function Kept.free(u: Unit): boolean
	return u.shut and not u.keeper and not u.holding
end

--- Which of `units` the building stores someone caught at (`x`, `z`) in: its index, or nil when
--- none is free. Never the nearest free one while another will do; an unopened one ahead of one
--- that's been seen into; at random among those.
function Kept.choose(units: { Unit }, x: number, z: number, random: Random): number?
	local free: { number } = {}
	local nearest, best = 0, math.huge
	for i, u in units do
		if Kept.free(u) then
			table.insert(free, i)
			local dx, dz = u.x - x, u.z - z
			local d = dx * dx + dz * dz
			if d < best then
				nearest, best = i, d
			end
		end
	end
	if #free == 0 then
		return nil
	elseif #free == 1 then
		return free[1]
	end
	local unopened: { number } = {}
	local opened: { number } = {}
	for _, i in free do
		if i ~= nearest then
			table.insert(if units[i].dealt then opened else unopened, i)
		end
	end
	local pool = if #unopened > 0 then unopened else opened
	return pool[random:nextInteger(1, #pool)]
end

return table.freeze(Kept)
