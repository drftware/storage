--!strict
-- The Mannequin's poses (GDD Keepers): it moves only while no light is on it, so players never
-- see it walk. They see where it stopped: the next time a light finds it, it's a step closer and
-- standing differently, as Five Nights at Freddy's animatronics are somewhere new each time the
-- camera comes back, and SCP-173 in SCP: Containment Breach moves only while unseen.
--
-- So its walk is stop-motion: it holds each of four strong key poses, then snaps to the next,
-- and a light that catches it freezes it on a key, never in a blur between two (`freeze`). Those
-- keys are what players remember: mid-step, an arm reaching for whoever is holding the light.
--
-- And it walks wrong (L-06c1): it limps on a stiff left leg it drags through each stride, its
-- steps land unevenly, and its head lolls a beat behind its body, as if loose on its neck, as
-- Silent Hill's mannequins and Doors' Figure move like something that shouldn't walk at all.
--
-- Pure: no Roblox types, so Lune checks every pose stands on the floor, stays inside its joints'
-- limits and never puts one part through another (tests/mannequin.spec.luau). Angles are degrees
-- about the figure's own axes at rest (X its right, Y up, Z behind it): +X swings a hanging limb
-- forward and tips the head back, +Y turns to its left, +Z swings a hanging limb to its right.

local Specs = require("./Specs")

export type Angles = { x: number?, y: number?, z: number? }
export type Pose = { [string]: Angles } -- by R15 joint name; a joint left out stands at rest
export type Transform = { number } -- 12 numbers: a rotation row by row, then a position

local Pose = {}

-- How far each joint turns, in degrees, low to high on each axis, for the middle and the right
-- side; the left side's are these mirrored. A pose outside them would read as broken rather
-- than as a mannequin standing wrong.
local LIMITS: { [string]: { [string]: { number } } } = {
	Root = { x = { -20, 20 }, y = { -30, 30 }, z = { -15, 15 } },
	Waist = { x = { -40, 20 }, y = { -35, 35 }, z = { -20, 20 } },
	Neck = { x = { -45, 35 }, y = { -75, 75 }, z = { -35, 35 } },
	RightShoulder = { x = { -60, 170 }, y = { -80, 80 }, z = { -30, 170 } },
	RightElbow = { x = { 0, 145 }, y = { -60, 60 }, z = { -5, 5 } },
	RightWrist = { x = { -30, 30 }, y = { -20, 20 }, z = { -70, 70 } },
	RightHip = { x = { -35, 120 }, y = { -40, 40 }, z = { -25, 50 } },
	RightKnee = { x = { -150, 0 }, y = { -10, 10 }, z = { -5, 5 } },
	RightAnkle = { x = { -50, 25 }, y = { -20, 20 }, z = { -20, 20 } },
}

-- The walk (feel). How fast it goes is the hunt's (L-06b), never faster than a player; this is
-- how each stride looks and sounds.
Pose.Walk = {
	Keys = { "StepRight", "PassRight", "StepLeft", "PassLeft" },
	-- Studs one key carries it, on average: four keys make a stride of 10.8, about its legs' reach,
	-- so its feet don't skate far.
	Step = 2.7,
	-- How far each key carries it, as shares of `Step` (one each, on average): a short plant on
	-- its good right foot, a long drag of the stiff left one, a short stiff heel, then the good
	-- leg swinging through. Its beats land unevenly, so you hear the limp: thud, scrape, tock.
	Spans = { 0.8, 1.4, 0.7, 1.1 },
	-- How much of each key's span it stands still on that key before snapping to the next. It
	-- holds the plant long and then jerks; the drag starts almost at once and is slow, the one
	-- smooth thing it does. More hold, a jerkier and more mannequin-like walk.
	Holds = { 0.7, 0.15, 0.55, 0.5 },
	-- Its head lands a beat late: it swings into each key's place over this much of the key's
	-- span after the body lands (never past the hold), so it lolls after every step. At its
	-- roaming pace that's 0.06 to 0.18 s, enough to see; at 0.35 it was about 0.1 s, too quick.
	Lag = 0.5,
	-- How many steps each screen shows a snap from one key to the next in (`Pose.frame`): at its
	-- top speed its quickest snap takes about 0.04 s and its drag about 0.22 s, so 10 never shows
	-- a stutter inside one. Fewer would read as a twitch, more costs nothing seen.
	Snaps = 10,
	-- How many steps a screen shows its head settling in: it's a short loll, so few.
	Settle = 3,
}

-- A stride, in `Step`s: the spans added up.
local STRIDE = 0
for _, span in Pose.Walk.Spans do
	STRIDE += span
end

local function mirrorName(name: string): string
	if string.sub(name, 1, 4) == "Left" then
		return "Right" .. string.sub(name, 5)
	elseif string.sub(name, 1, 5) == "Right" then
		return "Left" .. string.sub(name, 6)
	end
	return name
end

-- The same pose for the other side: left and right swap, and turns about Y and Z reverse.
function Pose.mirror(pose: Pose): Pose
	local out: Pose = {}
	for joint, a in pose do
		out[mirrorName(joint)] =
			{ x = a.x, y = if a.y then -a.y else nil, z = if a.z then -a.z else nil }
	end
	return out
end

Pose.Limits = {} :: { [string]: { [string]: { number } } }
for joint, axes in LIMITS do
	Pose.Limits[joint] = axes
	if string.sub(joint, 1, 5) == "Right" then
		local y, z = axes.y, axes.z
		Pose.Limits[mirrorName(joint)] = { x = axes.x, y = { -y[2], -y[1] }, z = { -z[2], -z[1] } }
	end
end

local Poses: { [string]: Pose } = {
	-- As it's found: standing where it was left, its weight on one leg, its head hung and cocked
	-- to one side, one elbow bent: a shop's display pose gone slack.
	Still = {
		Root = { z = -3 },
		Waist = { y = 8, z = 4 },
		Neck = { x = -20, y = -18, z = 14 },
		RightShoulder = { x = 10, z = 10 },
		RightElbow = { x = 18 },
		RightWrist = { z = -8 },
		LeftShoulder = { x = -6, z = -8 },
		LeftElbow = { x = 35, y = -25 },
		LeftWrist = { z = 12 },
		RightHip = { x = 8, z = 5 },
		RightKnee = { x = -16 },
		RightAnkle = { x = 8, z = -5 },
		LeftHip = { z = -4 },
		LeftAnkle = { z = 4 },
	},
	-- Its good right foot planted ahead, all its weight thrown onto it: leaning in, its head
	-- dropped and lolled over, the stiff left leg trailing straight behind on its toe, its left
	-- arm out level at you, palm down, fingers drooping.
	StepRight = {
		Root = { x = -8, z = 3 },
		Waist = { x = -8, y = -12, z = -3 },
		Neck = { x = -22, y = 14, z = 30 },
		RightHip = { x = 28, z = 2 },
		RightKnee = { x = -6 },
		RightAnkle = { x = -14 },
		LeftHip = { x = -24, z = -4 },
		LeftKnee = { x = -4 },
		LeftAnkle = { x = -6 },
		LeftShoulder = { x = 95, y = -75, z = -4 },
		LeftElbow = { x = 8 },
		LeftWrist = { z = 25 },
		RightShoulder = { x = -20, z = 8 },
		RightElbow = { x = 30 },
		RightWrist = { z = -10 },
	},
	-- On its right foot, its left hip hitched up to swing the stiff leg out and round, the foot
	-- dragging on its toe, the reaching arm still up.
	PassRight = {
		Root = { x = -5, z = -6 },
		Waist = { x = -6, y = -4, z = 5 },
		Neck = { x = 6, y = 8, z = -6 },
		RightHip = { x = 4, z = -2 },
		RightKnee = { x = -6 },
		RightAnkle = { x = 4 },
		LeftHip = { x = -8, z = -10 },
		LeftKnee = { x = -3 },
		LeftAnkle = { x = -14 },
		LeftShoulder = { x = 80, y = -68, z = -4 },
		LeftElbow = { x = 14 },
		LeftWrist = { z = 18 },
		RightShoulder = { x = 6, z = 10 },
		RightElbow = { x = 26 },
	},
	-- The stiff left leg landed ahead, straight as a post, a short stride; its head lolled the
	-- other way.
	StepLeft = {
		Root = { x = -4, z = 4 },
		Waist = { x = -5, y = 9, z = -2 },
		Neck = { x = -14, y = -12, z = -30 },
		LeftHip = { x = 22, z = -3 },
		LeftKnee = { x = -2 },
		LeftAnkle = { x = -6 },
		RightHip = { x = -22, z = 2 },
		RightKnee = { x = -12 },
		RightAnkle = { x = -6 },
		LeftShoulder = { x = 100, y = -72, z = -6 },
		LeftElbow = { x = 6 },
		LeftWrist = { z = 28 },
		RightShoulder = { x = 18, z = 8 },
		RightElbow = { x = 20 },
	},
	-- Rocked up over the stiff leg, its good leg swinging through bent, its head tipped back.
	PassLeft = {
		Root = { x = -6, z = 3 },
		Waist = { x = -6, y = 3 },
		Neck = { x = 10, y = -4, z = 6 },
		LeftHip = { x = 2, z = -2 },
		LeftKnee = { x = -2 },
		LeftAnkle = { x = 0 },
		RightHip = { x = 26, z = 2 },
		RightKnee = { x = -52 },
		RightAnkle = { x = 10 },
		LeftShoulder = { x = 88, y = -70, z = -4 },
		LeftElbow = { x = 10 },
		LeftWrist = { z = 20 },
		RightShoulder = { x = -16, z = 8 },
		RightElbow = { x = 28 },
	},
	-- The catch (L-06c2): thrown forward at you off its good leg, both arms out wide and low,
	-- elbows bent, hands clawing in from either side of you, its head cocked hard over. The arms
	-- frame its face rather than cover it. Only the caught player sees it, for the half second its
	-- face rushes their eyes (CaughtLunge).
	Lunge = {
		Root = { x = -12, z = 4 },
		Waist = { x = -18, y = 6, z = -4 },
		Neck = { x = 10, y = -10, z = 30 },
		LeftShoulder = { x = 62, y = -40, z = -48 },
		LeftElbow = { x = 40 },
		LeftWrist = { z = 22 },
		RightShoulder = { x = 56, y = 40, z = 44 },
		RightElbow = { x = 46 },
		RightWrist = { z = -18 },
		RightHip = { x = 32, z = 3 },
		RightKnee = { x = -28 },
		RightAnkle = { x = -8 },
		LeftHip = { x = -26, z = -4 },
		LeftKnee = { x = -4 },
		LeftAnkle = { x = -18 },
	},
	-- Cutting the power (S2-02d2), as the security camera shows it: at the breaker box, square in
	-- front of the lever (`Breaker.stand`), its right hand up on the grip, elbow out and bent, its
	-- head tipped back and lolled over as if looking up at it; the other arm hangs slack. Its
	-- hand sits on the grip's middle with the lever up (`Breaker.Specs.GripUp`, 2.6 out from the
	-- wall: 1.3 ahead of its feet, 6 up).
	Reach = {
		Root = { z = -2 },
		Waist = { y = 10, z = 3 },
		Neck = { x = 18, y = -12, z = 16 },
		RightShoulder = { x = 70, z = -30 },
		RightElbow = { x = 90 },
		LeftShoulder = { x = -4, z = -6 },
		LeftElbow = { x = 20 },
		LeftWrist = { z = 10 },
		RightHip = { x = 4, z = 3 },
		RightKnee = { x = -6 },
		LeftHip = { x = -6, z = -3 },
		LeftAnkle = { x = 4 },
	},
	-- The lever down: the hand dragged it down with it to the grip's low end (`GripDown`), the
	-- elbow tucked at its side, its weight thrown onto that side, its body turned into the pull
	-- and its head dropped hard over the box.
	Pull = {
		Root = { x = -4, z = -2 },
		Waist = { x = -2, y = 35, z = -10 },
		Neck = { x = -35, y = -24, z = 20 },
		RightShoulder = { x = 0, z = -20 },
		RightElbow = { x = 120 },
		LeftShoulder = { x = -4, z = -6 },
		LeftElbow = { x = 20 },
		LeftWrist = { z = 10 },
		RightHip = { x = 4, z = 3 },
		RightKnee = { x = -6 },
		LeftHip = { x = -6, z = -3 },
		LeftAnkle = { x = 4 },
	},
}
Pose.Poses = Poses
Pose.Names = { "Still", "StepRight", "PassRight", "StepLeft", "PassLeft", "Lunge", "Reach", "Pull" }

-- What's wrong with a pose, if anything: joints it doesn't have, turns past a joint's limits.
function Pose.check(pose: Pose): { string }
	local out = {}
	for joint, a in pose do
		local lim = Pose.Limits[joint]
		if not lim then
			table.insert(out, `no joint {joint}`)
			continue
		end
		for _, axis in { "x", "y", "z" } do
			local v = (a :: any)[axis] :: number? -- any: indexing the record by a key from a list
			local r = lim[axis]
			if v and (v < r[1] or v > r[2]) then
				table.insert(out, `{joint}.{axis} {v} outside {r[1]}..{r[2]}`)
			end
		end
	end
	return out
end

-- Part way from one pose to another, every joint's angles straight between the two.
function Pose.blend(a: Pose, b: Pose, t: number): Pose
	local out: Pose = {}
	for joint in Pose.Limits do
		local p, q = a[joint], b[joint]
		if p or q then
			local p0: Angles, q0: Angles = p or {}, q or {}
			out[joint] = {
				x = (p0.x or 0) + ((q0.x or 0) - (p0.x or 0)) * t,
				y = (p0.y or 0) + ((q0.y or 0) - (p0.y or 0)) * t,
				z = (p0.z or 0) + ((q0.z or 0) - (p0.z or 0)) * t,
			}
		end
	end
	return out
end

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

-- The key it's on after `travelled` studs, counted from its first (0) and never going back, and
-- how far through that key's span it is, from 0 up to (not including) 1.
local function keyAt(travelled: number): (number, number)
	local spans = Pose.Walk.Spans
	local q = travelled / Pose.Walk.Step
	local stride = math.floor(q / STRIDE)
	local r = q - stride * STRIDE
	for i, span in spans do
		if r < span then
			return stride * #spans + i - 1, r / span
		end
		r -= span
	end
	return (stride + 1) * #spans, 0 -- rounding at a stride's very end: the next one's first key
end

-- Which of the walk's keys (1 to 4) a key counted from its first is.
local function keyIndex(k: number): number
	return k % #Pose.Walk.Keys + 1
end

-- Key `i` posed with its body `t` of the way into the next key and its head `h` of the way from
-- the last key's place to its own (each already eased): exactly the key's own pose when t is 0
-- and h is 1.
local function posed(i: number, t: number, h: number): Pose
	local keys = Pose.Walk.Keys
	local a = Poses[keys[i]]
	if t == 0 and h == 1 then
		return a
	end
	local out = Pose.blend(a, Poses[keys[i % #keys + 1]], t)
	local was: Angles = Poses[keys[(i - 2) % #keys + 1]].Neck or {}
	local to: Angles = a.Neck or {}
	out.Neck = {
		x = (was.x or 0) + ((to.x or 0) - (was.x or 0)) * h,
		y = (was.y or 0) + ((to.y or 0) - (was.y or 0)) * h,
		z = (was.z or 0) + ((to.z or 0) - (was.z or 0)) * h,
	}
	return out
end

-- How much of key `i`'s span its head takes to settle: `Walk.Lag`, never past its hold.
local function lagOf(i: number): number
	return math.min(Pose.Walk.Lag, Pose.Walk.Holds[i])
end

-- Its walk once it has gone `travelled` studs: landing on a key while its head catches up,
-- holding it, or snapping to the next.
function Pose.at(travelled: number): Pose
	local k, f = keyAt(travelled)
	local i = keyIndex(k)
	local hold, lag = Pose.Walk.Holds[i], lagOf(i)
	local t = if f <= hold then 0 else smooth((f - hold) / (1 - hold))
	local h = if f >= lag then 1 else smooth(f / lag)
	return posed(i, t, h)
end

-- The key a light freezes it on after `travelled` studs: the one it holds, or, caught mid-snap,
-- the one it was snapping into, so it's always a step closer and never a blur.
function Pose.freeze(travelled: number): string
	local k, f = keyAt(travelled)
	local i = keyIndex(k)
	return Pose.Walk.Keys[if f <= Pose.Walk.Holds[i] then i else keyIndex(k + 1)]
end

-- How a screen poses a keeper: slack as it's found (Still), walking (Walk), stopped mid-stride
-- (Stop: frozen on a key, as `freeze` says), or at a breaker box with its hand up on the grip
-- (Reach) or dragging the lever down (Pull), S2-02d2.
export type How = "Still" | "Walk" | "Stop" | "Reach" | "Pull"

-- Every pose a screen shows is one of these frames (L-06b4a), so each screen works each one out
-- once and turns a body's joints only when its frame changes. Frame 1 is Still; then, for each of
-- the walk's keys, `Walk.Settle` frames of it landed with its head catching up, the key held,
-- and the `Walk.Snaps - 1` steps of the snap into the next; last, Reach and Pull. It snaps
-- straight into those two, stop-motion, never easing.
local PER_KEY = Pose.Walk.Settle + Pose.Walk.Snaps
local REACH = 2 + #Pose.Walk.Keys * PER_KEY
local PULL = REACH + 1
Pose.Frames = PULL

-- The frame a body shows standing in one place, not on its walk: Still, Reach or Pull (nil for
-- Walk and Stop, which `frame` works out from how far it has walked).
function Pose.held(how: How): number?
	if how == "Still" then
		return 1
	elseif how == "Reach" then
		return REACH
	elseif how == "Pull" then
		return PULL
	end
	return nil
end

-- The key a walking or stopped body shows after `travelled` studs, counted from its first key
-- (0) and never going back, and which of that key's frames: under `Walk.Settle` its head is
-- still settling, `Walk.Settle` holds the key, more is the snap into the next. Stopped, it shows
-- a key held, its head settled: the one it holds, or mid-snap the one it was snapping into, as
-- `freeze` says.
local function shown(travelled: number, how: How): (number, number)
	local snaps, settle = Pose.Walk.Snaps, Pose.Walk.Settle
	local k, f = keyAt(travelled)
	local i = keyIndex(k)
	local hold = Pose.Walk.Holds[i]
	if f > hold then
		if how == "Stop" then
			return k + 1, settle
		end
		local s = math.floor((f - hold) / (1 - hold) * snaps + 0.5)
		if s >= snaps then
			return k + 1, 0
		end
		return k, settle + s
	end
	local lag = lagOf(i)
	if how == "Stop" or f >= lag then
		return k, settle
	end
	return k, math.min(math.floor(f / lag * settle + 0.5), settle)
end

-- How far along its walk a walking or stopped body shows after `travelled` studs, in frames: the
-- key (counted from its first, 0) times its frames per key, plus which of them. A screen shows
-- the furthest it has shown (L-06b4b3): stopped mid-snap, it showed the key it was snapping into,
-- so as it walks on it holds that key until its walk reaches it, never flicking back into the
-- snap.
function Pose.along(travelled: number, how: How): number
	local k, j = shown(travelled, how)
	return k * PER_KEY + j
end

-- The frame for a walk shown `along` its keys (Pose.along).
function Pose.frameAt(along: number): number
	return 2 + along % (#Pose.Walk.Keys * PER_KEY)
end

-- The frame it shows after `travelled` studs: Still; its walk (landing, the key held, or the
-- nearest step of the snap to the next); or stopped, on the key `freeze` says.
function Pose.frame(travelled: number, how: How): number
	local held = Pose.held(how)
	if held then
		return held
	end
	return Pose.frameAt(Pose.along(travelled, how))
end

-- What its walk sounds like (L-06b4b2, L-06c1), each key as it lands: its good foot planted (a
-- footfall), its stiff foot starting its drag (a scrape), the stiff heel landing (a lighter,
-- harder knock), and nothing as the good leg swings through; its body creaks as it jerks out of
-- its slack pose into a stride.
export type Sound = "Footfall" | "Drag" | "Heel" | "Creak"

local LANDS: { [string]: Sound } = { StepRight = "Footfall", PassRight = "Drag", StepLeft = "Heel" }

local SLACK = -1 -- what `tell` remembers of a body standing slack (Still)
local REACHED = -2 -- or with its hand up on a breaker's grip (Reach)
local PULLED = -3 -- or dragging its lever down (Pull)

-- The sound a body makes as a screen poses it after `travelled` studs, if any, and what to pass
-- as `last` next time. `last` is what this returned the last time, nil before the body's first
-- pose on this screen (which is silent: it streamed in, it didn't move). Each key is heard once,
-- the moment the screen shows it landing: a late record that jumps several keys makes one sound,
-- the last key's, and a snap a light froze early (`freeze`) isn't heard again as it walks on.
function Pose.tell(last: number?, travelled: number, how: How): (Sound?, number)
	if how == "Still" then
		return nil, SLACK
	elseif how == "Reach" or how == "Pull" then
		-- its arm creaks up to the grip; the lever's slam is the box's own (BreakerView)
		local now = if how == "Reach" then REACHED else PULLED
		if last == nil or last == now or how == "Pull" then
			return nil, now
		end
		return "Creak", now
	end
	local k = shown(travelled, how)
	if last == nil then
		return nil, k
	elseif last < 0 then
		return "Creak", k -- it jerks out of a slack or held pose into a stride
	elseif k <= last then
		return nil, last
	end
	return LANDS[Pose.Walk.Keys[keyIndex(k)]], k
end

-- The pose a frame shows.
function Pose.ofFrame(frame: number): Pose
	if frame <= 1 then
		return Poses.Still
	elseif frame == REACH then
		return Poses.Reach
	elseif frame == PULL then
		return Poses.Pull
	end
	local settle = Pose.Walk.Settle
	local n = frame - 2
	local i, j = n // PER_KEY + 1, n % PER_KEY
	if j < settle then
		return posed(i, 0, smooth(j / settle))
	end
	return posed(i, smooth((j - settle) / Pose.Walk.Snaps), 1)
end

-- A rotation from angles, applied about Z, then Y, then X (Roblox's CFrame.Angles), row by row.
function Pose.rotation(a: Angles): Transform
	local rx, ry, rz = math.rad(a.x or 0), math.rad(a.y or 0), math.rad(a.z or 0)
	local cx, sx, cy, sy, cz, sz =
		math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	-- Rx * Ry * Rz
	return {
		cy * cz,
		-cy * sz,
		sy,
		sx * sy * cz + cx * sz,
		-sx * sy * sz + cx * cz,
		-sx * cy,
		-cx * sy * cz + sx * sz,
		cx * sy * sz + sx * cz,
		cx * cy,
		0,
		0,
		0,
	}
end

-- a then b, as CFrames multiply (a * b).
local function mul(a: Transform, b: Transform): Transform
	local out = table.create(12, 0)
	for r = 0, 2 do
		for c = 1, 3 do
			out[r * 3 + c] = a[r * 3 + 1] * b[c] + a[r * 3 + 2] * b[3 + c] + a[r * 3 + 3] * b[6 + c]
		end
		out[10 + r] = a[r * 3 + 1] * b[10] + a[r * 3 + 2] * b[11] + a[r * 3 + 3] * b[12] + a[10 + r]
	end
	return out
end

-- A point moved by a transform.
function Pose.apply(t: Transform, p: { number }): { number }
	return {
		t[1] * p[1] + t[2] * p[2] + t[3] * p[3] + t[10],
		t[4] * p[1] + t[5] * p[2] + t[6] * p[3] + t[11],
		t[7] * p[1] + t[8] * p[2] + t[9] * p[3] + t[12],
	}
end

local REST: Angles = {}
local IDENTITY: Transform = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 }

-- Each joint's turn about its own pivot: the rotation, and where that leaves the pivot's centre.
local function turn(pose: Pose, joint: Specs.Joint): Transform
	local t = Pose.rotation(pose[joint.Name] or REST)
	local at = joint.At
	local moved = Pose.apply(t, at)
	t[10], t[11], t[12] = at[1] - moved[1], at[2] - moved[2], at[3] - moved[3]
	return t
end

-- Every part's place in the figure's frame for a pose, moved from where it stands at rest, and
-- how far the whole body was lifted (or dropped) so its lowest sole sits on the floor.
function Pose.solve(pose: Pose): ({ [string]: Transform }, number)
	local parts: { [string]: Transform } = { HumanoidRootPart = IDENTITY }
	for _, joint in Specs.Joints do
		parts[joint.Part1] = mul(parts[joint.Part0], turn(pose, joint))
	end
	local low = math.huge
	for foot, points in Specs.Soles do
		for _, p in points do
			low = math.min(low, Pose.apply(parts[foot], p)[2])
		end
	end
	for name, t in parts do
		if name ~= "HumanoidRootPart" then
			t[11] -= low
		end
	end
	return parts, -low
end

-- Each Motor6D's turn for a pose (C0 = its RigAttachment's CFrame * this), the root's carrying
-- the lift that keeps its feet on the floor.
function Pose.turns(pose: Pose): { [string]: Transform }
	local _, lift = Pose.solve(pose)
	local out: { [string]: Transform } = {}
	for _, joint in Specs.Joints do
		local t = Pose.rotation(pose[joint.Name] or REST)
		if joint.Name == "Root" then
			t[11] = lift
		end
		out[joint.Name] = t
	end
	return out
end

return Pose
