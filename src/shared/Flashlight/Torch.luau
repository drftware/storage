--!strict
--[[
	Pure: the flashlight's feel (L-11a, D-047). Everyone carries one (GDD, the tools table): a
	small warm cone you thumb on when the hall's light clicks off behind you, held low on the right
	of your view and shaking a little as you walk; a friend's beam swinging round a corner tells you
	where they are. Tapping it off and on is a signal: three blinks means "it's me" (GDD).

	Proven mechanic: DOORS' and Lethal Company's flashlights, a held light every player carries
	and switches with one button, whose beam other players see.

	Numbers only, so Lune tests it: the client builds CFrames from what this returns. Angles are in
	radians unless a name says degrees.
]]

local Torch = {}

-- The beam: a SpotLight with shadows, leaving the lens.
Torch.BeamAngle = 54 -- the cone's full width, degrees: a small pool you aim, never a floodlight
Torch.BeamRange = 42 -- studs: the far end of a hall leg, so a keeper there shows as a shape
Torch.BeamBrightness = 2.4 -- bright in its middle; the edge falls off by itself
Torch.BeamColor = { 255, 228, 188 } -- the warm yellow of an old filament bulb on two tired cells
-- The light spilling round the bezel: a soft warm ring round the beam's pool and the torch lit in
-- your hand. It also lights a wall close in front of you at low graphics, where a spotlight is
-- worked out in 4-stud blocks and lights nothing nearer than about 3 studs (docs/STUDIO.md).
-- Yours only, with no shadows: a friend's torch shows by its lit lens.
Torch.SpillRange = 5
Torch.SpillBrightness = 0.35
Torch.SpillOffset = { 0, 0.3, -0.7 } -- from the grip: just above the head, behind the lens
-- The lens lit: near-white with the bulb's warmth; off, grey glass you can see the reflector in.
Torch.LensOn = { 255, 238, 210 }
Torch.LensOff = { 176, 186, 188 }
Torch.LensOffTransparency = 0.25

-- Where your torch sits in first person: the camera's right, down and forward in studs, then its
-- turn in degrees (yaw left, pitch up, roll). Low on the right, angled a little in and up so the
-- beam meets the middle of the screen a few steps ahead. The look sheets use the same numbers
-- (art/flashlight/build.py, HOLD).
Torch.Hold = { 0.62, -0.58, -1.25 }
Torch.HoldTurn = { 8, 4, -6 }

-- The walk sway: a step's bob, side to side and down, with a roll and a nod of the beam.
Torch.WalkSpeed = 16 -- the stride's full sway at this speed (studs/s); Roblox's default walk
Torch.StepRate = 1.9 -- steps a second at that speed: the bob's beat
Torch.BobAcross = 0.03 -- studs side to side over a stride
Torch.BobDown = 0.038 -- studs it dips at each footfall
Torch.BobRoll = 1.4 -- degrees it rolls with the stride
Torch.BobNod = 0.8 -- degrees the beam nods at each footfall: the shake you see in the pool
Torch.SwayRise = 6 -- how fast the sway grows to the walk (per second): a few steps to settle in
Torch.SwayFall = 4 -- how fast it fades when you stop: it rocks once more, then stills
-- Breathing while you stand: a slow rise and fall so the beam is never dead still.
Torch.BreathRate = 0.28 -- breaths a second
Torch.BreathDown = 0.006 -- studs
Torch.BreathNod = 0.25 -- degrees
-- The look lag: the torch trails when you turn, as an arm would, and catches up.
Torch.LagPerTurn = 0.3 -- of each frame's turn the torch is left behind by
Torch.LagMost = 7 -- degrees: the furthest it trails in a hard turn
Torch.LagReturn = 11 -- how fast it catches up (per second)
-- The click: the torch dips as your thumb presses its button, and comes back.
Torch.ClickDip = 2.6 -- degrees down at the press
Torch.ClickDrop = 0.018 -- studs down at the press
Torch.ClickSeconds = 0.18 -- gone by then
-- Let down (owner, Nov 18; D-435): off, your torch drops out of the bottom of your view, as your
-- arm drops it on a friend's screen (`ArmBlend`); on, it comes straight back up, its beam swinging
-- up off the floor with it. The bottom of the drop, added to the hold: studs right, up, back, then
-- degrees yaw, pitch, roll. Worked out on the torch's box to clear a 70 degree view by 5 degrees;
-- your screen also hides it once it's all the way down, for a wider view.
Torch.Down = { 0.12, -0.75, 0.3 }
Torch.DownTurn = { 6, -38, -14 } -- pointing at the floor, tipped out as it hangs at your side
Torch.DownAfter = 0.12 -- seconds after your thumb clicks it off: you see the lens go dark first
Torch.DownSeconds = 0.32 -- to drop out of view, gathering pace like an arm let fall
Torch.UpSeconds = 0.2 -- to come back up: quick, then settling into the hold
Torch.DeadLook = 0.7 -- dead in your hand: you look at it a beat before you let it down
Torch.DeadLift = 0.6 -- pressed while dead and down: it comes up, clicks dully, goes back down
Torch.CatchLift = 0.5 -- a battery flying in brings it up to take it, held up this long after

-- The switch's sounds (Pro Sound Effects, "Flashlight On Off Clicks"; measured, docs/STUDIO.md):
-- one plastic click each, cut from its recording. On is the brighter of the two.
Torch.OnSound = { id = "rbxassetid://9114480271", from = 0.38, length = 0.14 }
Torch.OffSound = { id = "rbxassetid://9114480269", from = 0.1, length = 0.14 }
Torch.ClickVolume = 1.4 -- both recordings sit about 20 dB down
Torch.ClickNear = 4 -- full volume within this many studs
Torch.ClickReach = 22 -- heard to here: a friend round the corner hears you switch

-- The switch's rules.
Torch.SwitchGap = 0.08 -- seconds between switches: three blinks in under a second, no faster
Torch.Burst = 4 -- switches the server takes back to back before the gap applies
Torch.Resend = 0.4 -- seconds the server may disagree with your torch before it's told again
-- Your aim: where you look, up and round, for friends' screens (their arm raises your torch to
-- it) and for keepers that freeze in light (the server tests your beam along it, L-06b4b3).
Torch.AimMost = 80 -- degrees up or down
Torch.AimStep = 1.5 -- degrees it must move before it's sent again
Torch.AimEvery = 0.1 -- seconds between sends while you look about
-- A swing this big (degrees), or your screen seeing your beam land on a keeper, is sent after
-- only `AimSoon`: the server hears your beam land within a frame or two, not a tenth of a second
-- later, so the keeper it catches walks no further there than it does on your screen.
Torch.AimSwing = 10
Torch.AimSoon = 0.05
-- The server takes an aim no sooner than this after the last (seconds): half the client's
-- soonest, so two sent `AimSoon` apart that arrive bunched up both count.
Torch.AimTake = 0.025
Torch.AimFollow = 12 -- how fast a friend's arm follows their aim on your screen (per second)
Torch.ArmBlend = 0.2 -- seconds a friend's arm takes to raise the torch or drop it
-- The phone's switch (owner, Nov 18; D-435): beside the jump button on its right, at the screen's
-- edge. Above the jump button it sat where the right thumb drags the camera round, and got
-- pressed by mistake. Roblox sets the jump button too near the edge for one there, so the jump
-- button moves left just far enough to make room (on a phone, about two thirds of its width).
Torch.ButtonOfJump = 0.74 -- its size, of the jump button's
Torch.ButtonMin, Torch.ButtonMax = 52, 92 -- pixels: a thumb's target, never a slab
Torch.ButtonGap = 0.14 -- of the button, between it and the jump button
Torch.ButtonEdge = 0.2 -- of the button, between it and the screen's right edge
-- The light budget on a low-end phone: your beam and the nearest friends' cast real, shadowed
-- light; past that a friend's torch shows only its lit lens (GDD tech plan: cap real lights).
Torch.RealBeams = 4
Torch.BeamSeen = 140 -- studs: a friend's beam further than this is never lit

-- The remotes, under ReplicatedStorage.Remotes (a stand-in for Brix ENG-09).
Torch.RemoteFolder = "Remotes"
Torch.SwitchRemote = "Flashlight"
Torch.AimRemote = "FlashlightAim"
-- The torch in a character: its model's name, and the attributes the server writes on it.
Torch.ModelName = "Flashlight"
Torch.OnAttribute = "On"
Torch.AimAttribute = "Aim" -- degrees, whole

local TAU = 2 * math.pi
local RAD = math.pi / 180
local BEAM_REACH2 = Torch.BeamRange * Torch.BeamRange
local BEAM_COS2 = math.cos(math.rad(Torch.BeamAngle / 2)) ^ 2

-- What the sway carries from frame to frame.
export type Sway = {
	phase: number, -- through the stride, 0 to 2 pi
	walk: number, -- how much of the walk's sway is in, 0 to 1
	breath: number, -- through the breath
	lagYaw: number, -- how far the torch trails your turn, radians
	lagPitch: number,
	click: number, -- seconds since the last click
}

-- A lit beam as a screen draws it this frame: where it leaves, which way its middle points (a
-- unit vector), and the light it gives (0 to 1: a dying torch flickers and sags). Yours leaves
-- your eye along your view; a friend's leaves their drawn lens along their raised arm.
export type Sight = {
	eye: vector,
	aim: vector,
	light: number,
}

-- Where the torch is this frame, on top of the hold: studs right, up, back; radians yaw, pitch,
-- roll.
export type Pose = {
	x: number,
	y: number,
	z: number,
	yaw: number,
	pitch: number,
	roll: number,
}

function Torch.sway(): Sway
	return {
		phase = 0,
		walk = 0,
		breath = 0,
		lagYaw = 0,
		lagPitch = 0,
		click = math.huge,
	}
end

function Torch.pose(): Pose
	return { x = 0, y = 0, z = 0, yaw = 0, pitch = 0, roll = 0 }
end

-- Moves toward `to` at `rate` per second, frame-rate independent.
local function approach(from: number, to: number, rate: number, dt: number): number
	return to + (from - to) * math.exp(-rate * dt)
end

-- The click: your thumb pressed the button.
function Torch.click(s: Sway)
	s.click = 0
end

-- How far your torch is let down: 0 held up, 1 out of view.
export type Drop = {
	at: number, -- this frame, eased
	from: number, -- where it set off from
	goal: number, -- 0 or 1
	since: number, -- seconds since it set off
}

-- Down: a torch starts off.
function Torch.drop(): Drop
	return { at = 1, from = 1, goal = 1, since = math.huge }
end

-- Sends it down (true) or up (false). Turned back partway, it sets off from where it is.
function Torch.letDown(d: Drop, down: boolean)
	local goal = if down then 1 else 0
	if goal ~= d.goal then
		d.from, d.goal, d.since = d.at, goal, 0
	end
end

-- One frame of the drop; returns how far down it is. Down gathers pace and up slows into the
-- hold, each taking its full time only from one end to the other.
function Torch.stepDrop(d: Drop, dt: number): number
	d.since += math.clamp(dt, 0, 0.1)
	local span = math.abs(d.goal - d.from)
		* (if d.goal == 1 then Torch.DownSeconds else Torch.UpSeconds)
	local k = if span > 0 then math.min(d.since / span, 1) else 1
	if k >= 1 then
		d.at = d.goal
		return d.at
	end
	local eased = if d.goal == 1 then k * k else 1 - (1 - k) * (1 - k)
	d.at = d.from + (d.goal - d.from) * eased
	return d.at
end

--[[
	One frame of the sway. `speed` is how fast you walk over the ground (studs/s; 0 in the air),
	`turnYaw` and `turnPitch` how far the camera turned this frame (radians, left and up positive).
	Writes the pose into `into` (no tables made) and returns it. A long frame (a hitch) moves the
	sway on by at most a tenth of a second, so nothing jumps.
]]
function Torch.step(
	s: Sway,
	dt: number,
	speed: number,
	turnYaw: number,
	turnPitch: number,
	into: Pose
): Pose
	dt = math.clamp(dt, 0, 0.1)
	local pace = math.clamp(speed / Torch.WalkSpeed, 0, 1.6)
	-- the stride's beat follows your speed; its sway eases in and out
	s.phase = (s.phase + TAU * Torch.StepRate * pace * dt) % TAU
	local target = math.min(pace, 1)
	s.walk =
		approach(s.walk, target, if target > s.walk then Torch.SwayRise else Torch.SwayFall, dt)
	s.breath = (s.breath + TAU * Torch.BreathRate * dt) % TAU
	-- the lag: left behind by part of each turn, then caught up
	local most = Torch.LagMost * RAD
	s.lagYaw = math.clamp(
		approach(s.lagYaw, 0, Torch.LagReturn, dt) - turnYaw * Torch.LagPerTurn,
		-most,
		most
	)
	s.lagPitch = math.clamp(
		approach(s.lagPitch, 0, Torch.LagReturn, dt) - turnPitch * Torch.LagPerTurn,
		-most,
		most
	)
	s.click += dt

	local w = s.walk
	local still = 1 - w
	-- a figure of eight: across once a stride, down at each footfall
	local across = math.sin(s.phase) * Torch.BobAcross * w
	local down = -math.abs(math.cos(s.phase)) * Torch.BobDown * w
	local breathe = math.sin(s.breath)
	-- the click's dip: in at once, out on an ease
	local k = math.clamp(1 - s.click / Torch.ClickSeconds, 0, 1)
	local dip = k * k
	into.x = across
	into.y = down - (breathe * 0.5 + 0.5) * Torch.BreathDown * still - dip * Torch.ClickDrop
	into.z = 0
	into.yaw = s.lagYaw
	into.pitch = s.lagPitch
		+ (
				math.cos(2 * s.phase) * Torch.BobNod * w
				+ breathe * Torch.BreathNod * still
				- dip * Torch.ClickDip
			)
			* RAD
	into.roll = -math.sin(s.phase) * Torch.BobRoll * w * RAD
	return into
end

--[[
	The phone's switch beside a jump button whose left edge Roblox put `jumpLeft` pixels across a
	touch screen `width` wide, `jumpSize` square: the switch's size, how far left the jump button
	moves to make room for it (0 when there's room already), and the switch's middle across.
]]
function Torch.besideJump(
	width: number,
	jumpLeft: number,
	jumpSize: number
): (number, number, number)
	local size =
		math.clamp(math.round(jumpSize * Torch.ButtonOfJump), Torch.ButtonMin, Torch.ButtonMax)
	local gap = math.round(size * Torch.ButtonGap)
	local edge = math.round(size * Torch.ButtonEdge)
	local room = width - (jumpLeft + jumpSize)
	local shift = math.max(0, size + gap + edge - room)
	return size, shift, jumpLeft - shift + jumpSize + gap + size / 2
end

-- The switch: may a switch at `now` go through after the last ones? `burst` is how many are left
-- in hand; returns whether it may and what's left. Each gap of `SwitchGap` earns one back.
function Torch.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Torch.Burst - 1
	end
	local earned = math.floor((now - last) / Torch.SwitchGap)
	local have = math.min(Torch.Burst, burst + math.max(earned, 0))
	if have <= 0 then
		return false, 0
	end
	return true, have - 1
end

-- A pitch from a client, in degrees: a real number, clamped to how far you can look. Nil if it
-- isn't one.
function Torch.aim(value: unknown): number?
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return nil
	end
	return math.clamp(math.round(value), -Torch.AimMost, Torch.AimMost)
end

-- A heading from a client, in degrees round from looking down -Z (Roblox's yaw, turning left):
-- a real number, rounded and brought into -180 to under 180. Nil if it isn't one.
function Torch.heading(value: unknown): number?
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return nil
	end
	return (math.round(value) + 180) % 360 - 180
end

-- How far an aim has moved, in degrees: the larger of its change up and its turn round.
function Torch.moved(pitch: number, yaw: number, wasPitch: number, wasYaw: number): number
	local turn = math.abs((yaw - wasYaw + 180) % 360 - 180)
	return math.max(math.abs(pitch - wasPitch), turn)
end

-- Whether to send your aim now, `since` seconds after the last send, having `moved` degrees
-- (Torch.moved; nil if none was sent since the torch went on). `soon` says your screen just saw
-- your beam land on a keeper: then it goes as soon as the server takes it.
function Torch.shouldSend(moved: number?, since: number, soon: boolean): boolean
	if moved == nil then
		return since >= Torch.AimSoon
	elseif soon then
		return since >= Torch.AimSoon and moved > 0
	elseif moved >= Torch.AimSwing then
		return since >= Torch.AimSoon
	end
	return since >= Torch.AimEvery and moved >= Torch.AimStep
end

-- The way a torch aimed `pitch` degrees up and `yaw` degrees round (Torch.heading's) points:
-- length 1, as a camera at that orientation looks.
function Torch.look(pitch: number, yaw: number): vector
	local p, y = pitch * RAD, yaw * RAD
	local c = math.cos(p)
	return vector.create(-math.sin(y) * c, math.sin(p), -math.cos(y) * c)
end

-- Whether a beam leaving `eye` along `aim` (length 1) lights `point`: within its reach and its
-- cone (the cone players see). The one test the server's keepers (Keeper.inTorch) and your
-- screen's prediction (KeeperView) both use, so they agree on everything but the line to it.
-- Allocates nothing.
function Torch.lights(eye: vector, aim: vector, point: vector): boolean
	local d = point - eye
	local d2 = vector.dot(d, d)
	if d2 > BEAM_REACH2 then
		return false
	end
	local along = vector.dot(d, aim)
	return along > 0 and along * along >= BEAM_COS2 * d2
end

-- A friend's shoulder for a torch aimed at `pitch` degrees: the arm, hanging down, swung forward
-- a quarter turn and on up to the aim (radians about the shoulder's X).
function Torch.raise(pitch: number): number
	return (90 + math.clamp(pitch, -Torch.AimMost, Torch.AimMost)) * RAD
end

-- Which friends' torches get real light: the nearest lit ones within `BeamSeen`, up to
-- `RealBeams - 1` (your own takes one). `distances[i]` is friend i's distance (math.huge when
-- their torch is off). Fills `into` with true or false for each and returns it. `most` and
-- `seen` give another light's own cap (the headlamps', Finds/Headlamp).
function Torch.budget(
	distances: { number },
	into: { boolean },
	most: number?,
	seen: number?
): { boolean }
	local n = #distances
	table.clear(into)
	for i = 1, n do
		into[i] = false
	end
	for _ = 1, most or (Torch.RealBeams - 1) do
		local best, bestAt = seen or Torch.BeamSeen, 0
		for i = 1, n do
			if not into[i] and distances[i] <= best then
				best, bestAt = distances[i], i
			end
		end
		if bestAt == 0 then
			break
		end
		into[bestAt] = true
	end
	return into
end

return Torch
