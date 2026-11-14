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

return Breaker
