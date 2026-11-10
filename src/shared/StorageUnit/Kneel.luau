--!strict
--[[
	Kneel: the peek's crouch, pure (L-06b5b). The GDD's peek: "Lift the door a foot and crouch. You
	see the floor first: feet, boxes, legs". Tap Peek and you drop low as the door lifts, your eye
	down by the foot of gap, as Rainbow Six Siege's players drop to look under a door; friends see
	you kneel and lean in. You stay down while the door stays peeked and you stay where you knelt.
	Step off, jump, press Open, Close or Slam, or the door moves under someone else's hand or a
	keeper's blow, and you stand back up with the same ease.

	Your screen and the server each keep one hold (`start`), tell it each move of the door
	(`doorMoved`) and ask it each step whether you're still down (`holds`). Your screen drops your
	view; the server tells every other screen to kneel your body.
]]
local Kneel = {}

-- Your view.
Kneel.Eye = 1 -- studs off the floor your eye drops to: just under the top of a peek's foot of
-- gap (1.15), so you see under the door to the back wall, a keeper's feet and shins on the floor
Kneel.Down = 0.35 -- seconds to drop low, and to stand back up: a quick duck, not a fall
-- Roblox's first-person camera rides 1.5 studs over the root's middle, raised by however much
-- taller than the standard 2 studs the root is (its BaseCamera): with a standard 2-stud root and a
-- 2-stud hip height, an eye 4.5 off the floor.
Kneel.CameraOverRoot = 1.5
Kneel.StandardRoot = 2

-- Staying down.
Kneel.MoveOff = 1 -- studs your feet may drift from where you knelt: a thumb's nudge keeps you
-- down, a step stands you up
Kneel.RiseOff = 1.5 -- studs up or down from where you knelt that stand you up: a jump, a fall
Kneel.Confirm = 1 -- seconds your screen waits for the door to start lifting after you tap Peek: no
-- lift (the server refused the press) and you stand back up

-- The door's buttons while you're down (only on your screen): a button shows only while its spot is
-- in view, and at the door's standing height (4) it's above a low gaze. So they come down with you
-- to sit this far above your level gaze, and never lower than just over the gap, so they never
-- hide what's under it.
Kneel.ButtonAngle = math.rad(16)
Kneel.ButtonLowest = 1.8 -- studs off the floor

-- How every screen kneels a body (R15 joints, radians about each joint's own across axis, as
-- CFrame.Angles' X turns it: a leg or arm hanging down swings forward for positive, the body over
-- the root pitches forward for negative): on both knees, chest down to the floor, forearms out
-- along it toward the door and the head lifted to look under it. `Sink` and `Back` are shares of
-- the hip height, so the knees meet the floor on any avatar's legs: the body drops and shifts back
-- so the head ends a little ahead of where the kneeler's own eye is. Tuned in Studio on a
-- standard avatar (hip height 2): knees, shins, chest and forearms within a tenth of a stud of the
-- floor, the head at about 1.2, two thirds of a stud ahead of the root.
Kneel.Pose = {
	Sink = 0.33,
	Back = 0.65,
	Lean = math.rad(-112), -- the body pitched past level from the root, chest down
	Waist = 0,
	Neck = math.rad(115), -- the head lifted back past the chest's pitch to look ahead
	Hip = math.rad(127), -- thighs about upright under the pitched hips
	Knee = math.rad(-105), -- shins back along the floor
	Ankle = math.rad(-90), -- feet laid flat behind, soles up
	Shoulder = math.rad(185), -- upper arms out ahead, elbows near the floor
	Elbow = math.rad(5), -- forearms along the floor toward the door
}

-- The rustle of your clothes as you drop and as you stand back up: Pro Sound Effects' "Cloth Rub,
-- Clothing Against Mic, Soft Rustle 3" (2.2 s), the stretch where it rubs. Heard close by only: a
-- friend beside you hears it, a keeper doesn't (the peek's latch is the noise the door makes).
Kneel.Rustle = {
	id = "rbxassetid://9113837381",
	from = 0.55, -- seconds into the clip
	length = 0.45, -- seconds played, the last `fade` of them faded out
	fade = 0.15,
	volume = 0.5,
	pitch = 1.1,
	near = 4, -- full volume within this many studs
	reach = 24, -- heard to this many
}

-- Characters kneeling (the server tags them; every screen kneels their bodies).
Kneel.Tag = "Kneeling"

export type Hold = {
	x: number, -- where your root was as you tapped Peek
	y: number,
	z: number,
	pressed: number, -- the clock at the tap
	lifted: boolean, -- the door has started its peek since the tap
}

-- A new hold: you tapped Peek with your root at (x, y, z) at `now`. `lifted` when the door is
-- already known to be lifting (the server, which lifts it).
function Kneel.start(x: number, y: number, z: number, now: number, lifted: boolean?): Hold
	return { x = x, y = y, z = z, pressed = now, lifted = lifted == true }
end

-- The door started a new move (`kind`, a Motion kind): whether you stay down. The first peek after
-- your tap is the door doing as you asked; anything else (a friend's Open, a Close, a keeper's
-- blow) stands you up.
function Kneel.doorMoved(h: Hold, kind: string): boolean
	if kind == "Peek" and not h.lifted then
		h.lifted = true
		return true
	end
	return false
end

-- Whether you're still down at `now` with your root at (x, y, z).
function Kneel.holds(h: Hold, now: number, x: number, y: number, z: number): boolean
	if not h.lifted and now - h.pressed > Kneel.Confirm then
		return false
	end
	local dx, dz = x - h.x, z - h.z
	if dx * dx + dz * dz > Kneel.MoveOff * Kneel.MoveOff then
		return false
	end
	return math.abs(y - h.y) <= Kneel.RiseOff
end

-- How far down you are (0 standing, 1 down) after `dt` more seconds heading down (`down`) or up:
-- the same pace both ways, so standing halfway through a drop turns straight back.
function Kneel.toward(level: number, down: boolean, dt: number): number
	local step = dt / Kneel.Down
	if down then
		return math.min(1, level + step)
	end
	return math.max(0, level - step)
end

-- How much of the drop shows at `level`: eased in and out, so you settle onto your knees.
function Kneel.weight(level: number): number
	local c = math.clamp(level, 0, 1)
	return c * c * (3 - 2 * c)
end

-- Studs your view drops, for an avatar of hip height `hipHeight` and root height `rootHeight`:
-- from Roblox's first-person eye down to `Eye`.
function Kneel.drop(hipHeight: number, rootHeight: number): number
	local eye = hipHeight
		+ rootHeight / 2
		+ Kneel.CameraOverRoot
		+ (rootHeight - Kneel.StandardRoot) / 2
	return math.max(0, eye - Kneel.Eye)
end

-- How high the door's buttons sit off the floor while you're all the way down, `distance` studs
-- out from the door: `ButtonAngle` over your level gaze, between `ButtonLowest` and `standing`.
function Kneel.buttonHeight(distance: number, standing: number): number
	local h = Kneel.Eye + math.max(distance, 0) * math.tan(Kneel.ButtonAngle)
	return math.clamp(h, math.min(Kneel.ButtonLowest, standing), standing)
end

return Kneel
