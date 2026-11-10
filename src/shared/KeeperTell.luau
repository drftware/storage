--!strict
--[[
	KeeperTell: how a keeper gives itself away by sound (L-06b4b2), the rules every screen plays
	it by. Each keeper's numbers are on its row (`KeeperRows`, `tell`); the client's KeeperSounds
	plays them from the body.

	The moment: in the dark you hear it before you see it. Each step its walk lands is a stiff
	clack of its foot on the concrete and each pass of its legs a hollow knock at its joints, as
	Five Nights at Freddy's footsteps tell you an animatronic moved. And a door lifted on one
	standing in a unit knocks once, as the curtain's edge clears its feet: the peek's answer
	before your light finds it.

	Pure: no Roblox types, so Lune checks it (tests/tell.spec.luau).
]]
local Motion = require("./StorageUnit/Motion")

-- A stretch of one recording.
export type Take = {
	id: string,
	start: number, -- seconds into the recording: just before its hit
	stop: number, -- and where it's cut, before anything else in the recording
}

-- One of its sounds, played from its body.
export type Sound = {
	takes: { Take }, -- each play picks one other than the last, so a walk never repeats a clip
	fade: number, -- seconds it fades out over before its stop, so the cut never clicks
	volume: number,
	pitchMin: number, -- each play picks a pitch in this range
	pitchMax: number,
	near: number, -- full volume within this many studs
	reach: number, -- silent beyond this many studs, and not played at all
}

export type Tell = {
	footfall: Sound, -- each step its walk lands (`Pose.tell`)
	knock: Sound, -- each pass of its legs, a jerk out of its slack pose, and a door's reveal
	gap: number, -- no two sounds from one body closer than this many seconds
	revealRise: number, -- studs a door lifts before the feet of one standing behind it show
	revealGain: number, -- the reveal's knock: its volume and pitch, times the knock's
	revealPitch: number,
	revealGap: number, -- seconds before a door lifted again on it knocks again
}

export type Name = "Footfall" | "Knock"

local KeeperTell = {}

local NAMES: { Name } = { "Footfall", "Knock" }

-- The keeper states a body stands in a unit in (Keeper): dealt asleep, or awake and watching.
local STANDING = { Asleep = true, Watching = true }

-- The door motions that lift a curtain on whatever stands behind it: a slam, a close, a padlocked
-- rattle or a trapped keeper's blows never do, and a trapped keeper bursting out isn't standing.
local LIFTS = { Peek = true, Open = true, LiftInside = true }

-- How sure `reveal` is of the moment, in seconds: far finer than a frame.
local REVEAL_PRECISION = 0.001

-- One of its sounds by name.
function KeeperTell.sound(tell: Tell, name: Name): Sound
	return if name == "Footfall" then tell.footfall else tell.knock
end

-- Whether a body may make a sound at `now` (seconds), its last at `last` (nil: never).
function KeeperTell.due(last: number?, now: number, gap: number): boolean
	return last == nil or now - last >= gap
end

-- Which of `count` takes to play next, never `last` again while there's another; `r` is a random
-- number from 0 up to (not including) 1.
function KeeperTell.take(count: number, last: number?, r: number): number
	if count <= 1 then
		return 1
	end
	if last == nil or last < 1 or last > count then
		return math.min(math.floor(r * count) + 1, count)
	end
	local i = math.min(math.floor(r * (count - 1)) + 1, count - 1)
	return if i >= last then i + 1 else i
end

-- Whether a keeper in state `state` stands in a unit, where a lifted door reveals it.
function KeeperTell.standing(state: any): boolean -- any: a body's attribute, maybe unset
	return type(state) == "string" and STANDING[state] == true
end

-- Whether a point (in a unit's door frame: x across the doorway, z back from the curtain into
-- the unit) is inside a unit `width` across and `depth` deep.
function KeeperTell.inside(x: number, z: number, width: number, depth: number): boolean
	return math.abs(x) <= width / 2 and z > 0 and z <= depth
end

-- Seconds after a door's motion starts when its curtain first clears `rise` studs, showing what
-- stands behind it; nil if this motion doesn't lift it there from below.
function KeeperTell.reveal(
	kind: Motion.Kind,
	from: number,
	to: number,
	fullStroke: number,
	rise: number
): number?
	if not LIFTS[kind] or from >= rise or to < rise then
		return nil
	end
	-- a lift only ever goes up, so halve the motion until the moment is pinned down
	local lo, hi = 0, Motion.duration(kind, from, to, fullStroke)
	while hi - lo > REVEAL_PRECISION do
		local mid = (lo + hi) / 2
		if Motion.sample(kind, from, to, mid, fullStroke) >= rise then
			hi = mid
		else
			lo = mid
		end
	end
	return hi
end

-- What's wrong with a keeper's tell, if anything: the numbers a screen couldn't play right.
function KeeperTell.check(tell: Tell): { string }
	local out = {}
	for _, name: Name in NAMES do
		local s = KeeperTell.sound(tell, name)
		if #s.takes == 0 then
			table.insert(out, `{name}: no takes`)
		end
		for i, take in s.takes do
			if string.match(take.id, "^rbxassetid://%d+$") == nil then
				table.insert(out, `{name} take {i}: {take.id} isn't an asset id`)
			end
			if take.start < 0 or take.stop - take.start <= s.fade then
				table.insert(out, `{name} take {i}: shorter than its fade`)
			end
		end
		if s.volume <= 0 or s.volume > 1 then
			table.insert(out, `{name}: volume {s.volume} outside 0..1`)
		end
		if s.pitchMin <= 0 or s.pitchMin > s.pitchMax then
			table.insert(out, `{name}: pitch range {s.pitchMin}..{s.pitchMax}`)
		end
		if s.near <= 0 or s.near >= s.reach then
			table.insert(out, `{name}: near {s.near} not inside reach {s.reach}`)
		end
	end
	if tell.gap <= 0 then
		table.insert(out, "gap must be over 0")
	end
	if tell.revealRise <= 0 then
		table.insert(out, "revealRise must be over 0")
	end
	if tell.knock.volume * tell.revealGain > 1 then
		table.insert(out, "the reveal's knock is over full volume")
	end
	if tell.revealGap <= tell.gap then
		table.insert(out, "revealGap must be over gap")
	end
	return out
end

return KeeperTell
