--!strict
--[[
	Breaker: the rules of a floor's one breaker box (S2-02, GDD "The breaker"; the precedent is
	Phasmophobia's fuse box, D-153). Pure, so Lune tests it; the server's Breakers places and runs
	it, each screen's BreakerView draws it. The box's art and numbers are `Breaker.Specs`.

	Where it hangs: on a plain wall along a straight hall, or on a dead end's face, never in the
	lobby's hall (the halls from the lobby to the first fork), so finding it means going out into
	the floor in the dark. The deal draws its spot last (`Deal.new`), so seeds keep their floors.

	Thrown, every hall light on its floor goes out and stays deaf to motion; the elevator keeps its
	own light. A one-second hold on the lever's grip switches it back on, the same hold as cutting
	a friend free, and the server judges it (`Breaker.judge`) before the power comes back.
]]
local Floor = require("./Floor")
local Specs = require("./Breaker/Specs")

local Breaker = {}
Breaker.Specs = Specs

-- Where the box hangs: the middle of a wall's hall face, on the floor, looking into the hall
-- along Dir `facing` (a plain wall's slot frame or a dead end's). `cell` is the hall piece it's in.
export type Spot = { x: number, z: number, facing: number, cell: number }

-- The tag the server puts on every placed box, and the attributes it writes for every screen.
Breaker.Tag = "Breaker"
Breaker.OnAttribute = "PowerOn" -- true while the power is on, false thrown
Breaker.StrainAttribute = "Straining" -- true while someone holds the lever
-- On the floor the box hangs on (its parent): its power, false while the box is thrown, so a
-- screen reads it without the box streamed in (S4-03c3: the power-out floor's unit bulbs).
Breaker.FloorAttribute = "FloorPower"
-- The power zones the box cuts, comma-separated (MotionLights' names, `FloorBuilder.powerZone`).
Breaker.ZonesAttribute = "PowerZones"

-- Seconds a player holds the grip to switch the power back on: a beat long enough that you
-- stand there in the dark with your back to the hall, as long as cutting a friend free.
Breaker.HoldSeconds = 1
-- Seconds of that hold the server forgives: the hold's start and end both reach it with lag.
Breaker.HoldSlack = 0.25
-- Studs from the grip a hand reaches it (the button's reach); the server forgives `ReachSlack`
-- more for a body still moving when the hold lands.
Breaker.Reach = 6
Breaker.ReachSlack = 2
-- Seconds after a switch before the same player's next press counts: a rate limit on the remote.
Breaker.PressGap = 0.5

-- How far up the lever creeps while it's held, 0 to 1 of the way from off to on: it strains up
-- under your hand, then snaps the rest when the power catches.
Breaker.Strain = 0.55
-- Seconds the lever takes to snap down when the box is thrown, and up when the power catches.
Breaker.ThrowSeconds = 0.09
Breaker.CatchSeconds = 0.12
-- Seconds a let-go lever takes to drop back down: it falls, it doesn't snap.
Breaker.FallSeconds = 0.18

-- The sounds (Pro Sound Effects, free on the Creator Store). The throw: one heavy clunk, a
-- circuit breaker's handle slammed ("Switch Circuit Breaker Clicks 1", slowed to sound bigger),
-- carried across the floor so everyone knows what just happened. The catch: a lighter click as
-- the handle seats ("Clicks 9"). Then the hum: a lit bulb's buzz (UnitLight's), low and loud at
-- the box, swelling in and dying off as the lights come back.
Breaker.ClunkSound = "rbxassetid://9119716652"
Breaker.ClunkVolume = 1.4
Breaker.ClunkSpeed = 0.72
Breaker.ClunkReach = 320 -- studs it carries: a whole floor
-- Studs along the halls keepers hear it from (`Keepers`), a slam's: the ones near the box come
-- to look, so going back to switch it on means walking toward them, not the whole floor.
Breaker.ClunkHeard = 110
Breaker.CatchSound = "rbxassetid://9119717286"
Breaker.CatchVolume = 0.9
Breaker.CatchSpeed = 0.85
Breaker.HumSound = "rbxassetid://9112823813"
Breaker.HumVolume = 0.7
Breaker.HumSpeed = 0.55 -- low: a building's mains, not a bulb
Breaker.HumIn = 0.3 -- seconds it swells
Breaker.HumOut = 2.6 -- seconds it dies away
-- A camera kick on the clunk for whoever stands near the box (0 to 1), and how near.
Breaker.ClunkShake = 0.35
Breaker.ShakeReach = 28

-- The pilot lamp: red while thrown, pulsing slowly so it reads down a dark hall; green, calmer,
-- with the power on. Colours as RGB 0 to 255; the pulse's seconds and its faintest moment.
Breaker.LampOff = { 255, 36, 24 }
Breaker.LampOn = { 70, 255, 110 }
Breaker.LampOnFaint = 0.35 -- the green lamp's transparency: lit, not shouting
Breaker.PulseSeconds = 1.4
Breaker.PulseFaint = 0.45 -- the red lamp's transparency at the bottom of its pulse
-- The red lamp's glow while thrown: one shadowless light washing the box's face red, so its
-- shape reads from down a dark hall on a phone. Only while thrown, when every hall light on the
-- floor is out, so the floor's light count only drops. Its range in studs and brightness at the
-- top of the pulse.
Breaker.GlowRange = 4 -- short: Studio's eye adapts to the dark, so reach, not brightness, keeps it on the box
Breaker.GlowBrightness = 1.5
Breaker.GlowOut = 1.6 -- studs in front of the lens it hangs: a light on a surface only grazes it

--- The red lamp's transparency `t` seconds into its pulse: full, fading to `PulseFaint` and back.
function Breaker.pulse(t: number): number
	local phase = (t % Breaker.PulseSeconds) / Breaker.PulseSeconds
	return Breaker.PulseFaint * (1 - math.cos(phase * 2 * math.pi)) / 2
end

--- Every place on `floor` a box may hang: each plain wall along a straight hall and each dead
--- end's face, outside the lobby's hall. In the floor's own order, so a seed picks the same one.
function Breaker.spots(floor: Floor.Floor): { Spot }
	local spots: { Spot } = {}
	for _, s in floor.slots do
		local cell = floor.cells[s.cell]
		-- a junction's wall is the junction piece's own, not a plain wall's panel
		if s.kind == "Wall" and cell.kind == "Straight" and cell.zone ~= "Lobby" then
			table.insert(spots, { x = s.x, z = s.z, facing = s.facing, cell = s.cell })
		end
	end
	for _, e in floor.deadEnds do
		if floor.cells[e.cell].zone ~= "Lobby" then
			table.insert(spots, { x = e.x, z = e.z, facing = e.facing, cell = e.cell })
		end
	end
	return spots
end

--- The spot `roll` (0 to 1) picks from `spots`, or nil when there are none.
function Breaker.pick(spots: { Spot }, roll: number): Spot?
	if #spots == 0 then
		return nil
	end
	return spots[math.clamp(math.floor(roll * #spots) + 1, 1, #spots)]
end

--- The power zones the floor's lights hang in, each once, in the floor's order (local names:
--- "Lobby", "A", ...; the server prefixes its floor's).
function Breaker.zones(floor: Floor.Floor): { string }
	local zones: { string } = {}
	for _, f in floor.fixtures do
		if not table.find(zones, f.zone) then
			table.insert(zones, f.zone)
		end
	end
	return zones
end

export type Refusal = "On" | "Wrapped" | "Dead" | "Short" | "Far" | "Soon"

export type Press = {
	on: boolean, -- the power is on already
	wrapped: boolean, -- the presser is wrapped and kept
	alive: boolean, -- the presser's body stands, its health above 0
	held: number?, -- seconds since the presser's hold began, nil with none
	since: number?, -- seconds since this presser's last counted press, nil with none
	reach: number, -- studs from the presser's body (its root) to the grip
}

--- Whether switch-on `p` may go: nil when it may, else what stops it.
function Breaker.judge(p: Press): Refusal?
	if p.on then
		return "On"
	elseif p.wrapped then
		return "Wrapped"
	elseif not p.alive then
		return "Dead"
	elseif p.since ~= nil and p.since < Breaker.PressGap then
		return "Soon"
	elseif p.held == nil or p.held < Breaker.HoldSeconds - Breaker.HoldSlack then
		return "Short"
	elseif p.reach > Breaker.Reach + Breaker.ReachSlack then
		return "Far"
	end
	return nil
end

--- The lever's angle in degrees (`Specs.Down` off to `Specs.Up` on) `t` seconds into a hold:
--- it creeps up under the hand, eased out, to `Strain` of the way at the hold's end.
function Breaker.strained(t: number): number
	local a = math.clamp(t / Breaker.HoldSeconds, 0, 1)
	local eased = 1 - (1 - a) * (1 - a)
	return Specs.Down + (Specs.Up - Specs.Down) * Breaker.Strain * eased
end

--[[
	The Mannequin's errand (S2-02c, GDD "The Mannequin cuts the power"). A loose Mannequin with no
	light on it, picking where to wander next, sometimes heads for the box instead and throws it,
	as Phasmophobia's ghost switches off the fuse box (D-153). Nothing tells the players: the clunk
	comes from somewhere behind you and the halls die. More keen the higher the floor.
]]
-- Floor 1's chance, each time a Mannequin picks where to wander next (about every 14 seconds of
-- wandering, measured in Lune), that it heads for the box: one loose Mannequin left alone cuts
-- the power about every three minutes on floor 1.
Breaker.ErrandChance = 0.08
-- Added for each floor above the first: higher up, the dark comes more often (about every
-- minute and a half by floor 5).
Breaker.ErrandPerFloor = 0.02
-- The most it ever gets (floor 12 up, about every 48 seconds): most of its wanders are still
-- about you.
Breaker.ErrandMost = 0.3
-- Until the power has been cut once on a floor, the chance at each pick is at least this: the
-- first loose Mannequin cuts it within half a minute or so of wandering (owner, Nov 14: at the
-- old odds it seldom happened at all on the first floors, where few Mannequins are loose). After
-- the first cut, the floor's own chance above.
Breaker.ErrandFirst = 0.5
-- Seconds after the power comes on (the floor laid, or switched back) before any Mannequin may
-- head for the box: the floor gets a lit start, and a switch back on buys a real breather.
Breaker.ErrandGap = 45
-- Studs out from the wall, in front of the lever, where a Mannequin stands to throw it: its hand
-- up on the grip (its Reach pose) is 1.3 ahead of its feet.
Breaker.ErrandStand = 2.6
-- Seconds a Mannequin stands with its hand up on the grip before it drags the lever down
-- (S2-02d2): long enough for the security camera to show the hand go up and the players watching
-- to see what it's about to do, short enough that nobody can run there and stop it.
Breaker.Grip = 0.6

--- The chance a Mannequin on floor `floor` heads for its box as it picks where to wander next:
--- 0 while the box is thrown (`on` false) or within `ErrandGap` seconds (`sinceOn`) of the power
--- coming on, else `ErrandChance` and `ErrandPerFloor` a floor up to `ErrandMost`; at least
--- `ErrandFirst` until the power has been cut once on the floor (`cut` false).
function Breaker.errand(floor: number, on: boolean, sinceOn: number, cut: boolean?): number
	if not on or sinceOn < Breaker.ErrandGap then
		return 0
	end
	local keen = Breaker.ErrandChance + Breaker.ErrandPerFloor * math.max(floor - 1, 0)
	keen = math.min(keen, Breaker.ErrandMost)
	if cut == false then
		return math.max(keen, Breaker.ErrandFirst)
	end
	return keen
end

--- Where a Mannequin stands to throw a box hung at (`x`, `z`) on its floor, looking into the hall
--- along (`fx`, `fz`), length 1 (a spot's `Floor.dir(facing)`, or the box's LookVector): on the
--- floor, `ErrandStand` out from the wall, square in front of the lever's grip.
function Breaker.stand(x: number, z: number, fx: number, fz: number): vector
	local side = Specs.GripDown[1] -- the grip's way along the wall, the box's right being (-fz, fx)
	return vector.create(
		x + fx * Breaker.ErrandStand - fz * side,
		0,
		z + fz * Breaker.ErrandStand + fx * side
	)
end

return Breaker
