--!strict
--[[
	KeeperTell: how a keeper gives itself away by sound (L-06b4b2, L-06c1), the rules every screen
	plays it by. Each keeper's numbers are on its row (`KeeperRows`, `tell`); the client's
	KeeperSounds plays them from the body.

	The moment: you hear it before you see it, and what you hear is heavy and wrong. Each beat of
	its walk is a few recordings at once (its layers): a hollow fibreglass thunk on the concrete
	that carries down the halls, and under it the body's weight, which only comes in as it nears,
	so its steps get heavier the closer it is, as Five Nights at Freddy's footsteps swell as an
	animatronic comes down the hall. Its dragged foot scrapes the concrete between steps, as
	SCP-173 grinds across the floor whenever no one is looking; its body creaks as it turns. When
	it stands still it is dead quiet. And a door lifted on one standing in a unit answers with a
	thunk and a creak as the curtain's edge clears its feet: the peek's answer before your light
	finds it.

	Pure: no Roblox types, so Lune checks it (tests/tell.spec.luau).
]]
local Motion = require("./StorageUnit/Motion")

-- A stretch of one recording.
export type Take = {
	id: string,
	start: number, -- seconds into the recording: just before its hit
	stop: number, -- and where it's cut, before anything else in the recording
}

-- One recording it plays from its body, in any number of beats.
export type Sound = {
	takes: { Take }, -- each play picks one other than the last, so a walk never repeats a clip
	fade: number, -- seconds it fades out over before its stop, so the cut never clicks
	volume: number,
	pitchMin: number, -- each play picks a pitch in this range
	pitchMax: number,
	near: number, -- full volume within this many studs
	reach: number, -- silent beyond this many studs, and not played at all
	-- How much of it is left at the far end of its heft (`Tell.heavyFar` and beyond): its volume
	-- and its pitch there, each as a share of its own. 1 and 1 sound the same at any distance;
	-- the body's weight is 0.1 and a higher pitch, so it only lands heavy up close.
	farGain: number,
	farPitch: number,
}

-- The beats a keeper's body makes. Its walk's beats come from its pose (`Pose.tell`): a foot
-- planted, its dragged foot scraping, its stiff heel landing, a creak as it jerks out of its slack
-- pose. Creak is also its body turning (`turned`); Reveal is a lifted door showing its feet.
-- Lunge and Catch are its catch (L-06c2), heard only by the one it caught, as their own sound
-- (CaughtView): its body throwing itself at you, and its head hitting you.
export type Beat = "Footfall" | "Drag" | "Heel" | "Creak" | "Reveal" | "Lunge" | "Catch"

-- One recording in a beat, its volume and pitch as shares of the recording's own.
export type Layer = { sound: string, gain: number, pitch: number }

export type Tell = {
	sounds: { [string]: Sound }, -- by name
	beats: { [Beat]: { Layer } }, -- what each beat plays, all at once
	-- Nearer, heavier: within `heavyNear` studs every layer plays as itself; out at `heavyFar` and
	-- beyond, at its `farGain` and `farPitch`; smoothly between (`heft`).
	heavyNear: number,
	heavyFar: number,
	gap: number, -- no two beats of its walk from one body closer than this many seconds
	turn: number, -- degrees its facing turns before its body creaks
	turnGap: number, -- seconds before its body creaks again
	revealRise: number, -- studs a door lifts before the feet of one standing behind it show
	revealGap: number, -- seconds before a door lifted again on it answers again
}

local KeeperTell = {}

local BEATS: { Beat } = { "Footfall", "Drag", "Heel", "Creak", "Reveal", "Lunge", "Catch" }
KeeperTell.Beats = BEATS

-- The keeper states a body stands in a unit in (Keeper): dealt asleep, or awake and watching.
local STANDING = { Asleep = true, Watching = true }

-- The door motions that lift a curtain on whatever stands behind it: a slam, a close, a padlocked
-- rattle or a trapped keeper's blows never do, and a trapped keeper bursting out isn't standing.
local LIFTS = { Peek = true, Open = true, LiftInside = true }

-- How sure `reveal` is of the moment, in seconds: far finer than a frame.
local REVEAL_PRECISION = 0.001

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

-- How heavy it sounds `distance` studs from you: 1 within `heavyNear`, 0 at `heavyFar` and
-- beyond, easing between so no step lands suddenly heavier than the last.
function KeeperTell.heft(tell: Tell, distance: number): number
	local t = (tell.heavyFar - distance) / (tell.heavyFar - tell.heavyNear)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- A sound's volume and pitch, as shares of its own, at a heft (`heft`).
function KeeperTell.weigh(sound: Sound, heft: number): (number, number)
	return sound.farGain + (1 - sound.farGain) * heft, sound.farPitch + (1 - sound.farPitch) * heft
end

-- The fastest a sound can ever play (its top pitch, its loudest layer's pitch, its far pitch),
-- so the fade before its cut is timed for it and never clicks.
function KeeperTell.fastest(tell: Tell, name: string): number
	local sound = tell.sounds[name]
	local layer = 0
	for _, layers in tell.beats do
		for _, l in layers do
			if l.sound == name then
				layer = math.max(layer, l.pitch)
			end
		end
	end
	return sound.pitchMax * layer * math.max(sound.farPitch, 1)
end

-- Whether a body facing (bx, bz) has turned more than `degrees` from facing (ax, az): its body
-- creaks then, and (bx, bz) is what it measures the next turn from.
function KeeperTell.turned(ax: number, az: number, bx: number, bz: number, degrees: number): boolean
	local a, b = math.sqrt(ax * ax + az * az), math.sqrt(bx * bx + bz * bz)
	if a < 1e-6 or b < 1e-6 then
		return false
	end
	return (ax * bx + az * bz) / (a * b) < math.cos(math.rad(degrees))
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
	for name, s in tell.sounds do
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
		if s.farGain < 0 or s.farGain > 1 then
			table.insert(out, `{name}: farGain {s.farGain} outside 0..1`)
		end
		if s.farPitch <= 0 then
			table.insert(out, `{name}: farPitch must be over 0`)
		end
	end
	for _, beat: Beat in BEATS do
		local layers = tell.beats[beat]
		if not layers or #layers == 0 then
			table.insert(out, `{beat}: plays nothing`)
			continue
		end
		for _, l in layers do
			local s = tell.sounds[l.sound]
			if not s then
				table.insert(out, `{beat}: no sound {l.sound}`)
			elseif l.gain <= 0 or s.volume * l.gain > 1 then
				table.insert(out, `{beat}: {l.sound} at gain {l.gain} isn't 0..full volume`)
			elseif l.pitch <= 0 then
				table.insert(out, `{beat}: {l.sound} pitch must be over 0`)
			end
		end
	end
	if tell.heavyNear < 0 or tell.heavyNear >= tell.heavyFar then
		table.insert(out, `heavyNear {tell.heavyNear} not inside heavyFar {tell.heavyFar}`)
	end
	if tell.gap <= 0 then
		table.insert(out, "gap must be over 0")
	end
	if tell.turn <= 0 or tell.turn >= 180 then
		table.insert(out, `turn {tell.turn} outside 0..180 degrees`)
	end
	if tell.turnGap <= tell.gap then
		table.insert(out, "turnGap must be over gap")
	end
	if tell.revealRise <= 0 then
		table.insert(out, "revealRise must be over 0")
	end
	if tell.revealGap <= tell.gap then
		table.insert(out, "revealGap must be over gap")
	end
	return out
end

return KeeperTell
