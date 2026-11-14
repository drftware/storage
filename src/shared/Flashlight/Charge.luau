--!strict
--[[
	Pure: the flashlight runs down (S1-09, D-142; GDD "The flashlight runs down"). It drains only
	while it's switched on; a full one gives about five minutes of light; for its last half minute
	the beam flickers, the stutters coming closer together and the light browning as it starves,
	until it dies with a click; a battery fills it at once (S1-07b). What's left carries from floor
	to floor, and everyone's is full again as each climb begins. The numbers are the owner's
	defaults (OWNER.md "The flashlight's details").

	Proven mechanic: DOORS' flashlight runs down and the batteries you find in drawers keep it
	going; Lethal Company's flashlight shows its charge on its own slot and dies when it's spent.

	The server owns the charge (Flashlights) and writes what's left on the Player in whole seconds
	as they tick (`Attribute`); each screen follows it smoothly between ticks (`follow`) and draws
	the flicker from it (`glow`), so the server only ever says how much is left.
]]

local Charge = {}

Charge.Full = 300 -- seconds of light in a full torch: about five minutes switched on
Charge.Flicker = 30 -- the last seconds it flickers: half a minute to find a battery or a friend
-- The bulb browns out to nothing over its last moments (seconds), so it's already dark as it dies.
-- Switched off with less than `Spent` left it's dead: it was browning out, and your screen puts it
-- out on its own up to a second before the server's tick says so.
Charge.Fade = 1.2
Charge.Spent = 1.5
-- On the Player: whole seconds left, rounded up, so it reads 0 only when it's dead.
Charge.Attribute = "Charge"
-- Studio only: a number on Workspace makes a full torch hold that many seconds (to see the flicker
-- without waiting five minutes).
Charge.Dev = "DevTorchSeconds"

-- The flicker: steady light that sags and browns, broken by stutters (a burst of quick dips).
Charge.Sag = 0.45 -- of its light the bulb has lost by the end: it dims as it starves
Charge.Brown = { 255, 166, 92 } -- the colour the warm beam browns to by the end
Charge.FirstStutter = 0.75 -- seconds: the first stutter as the half minute begins, the one you notice
Charge.GapFirst = 7 -- seconds between stutters as the flicker begins: now and then
Charge.GapLast = 0.35 -- and at the very end: it barely holds (they close in fast, then faster)
Charge.GapJitter = 0.5 -- each gap up to half again longer or shorter, so you can't count it
Charge.StutterFirst = 0.25 -- seconds a stutter lasts as the flicker begins
Charge.StutterLast = 1.3 -- and at the end
Charge.BlinkShort = 0.025 -- seconds each blink of a stutter holds its level, from
Charge.BlinkLong = 0.1 -- to
Charge.Low = 0.25 -- the brightest a dip gets, of the steady light
Charge.Dead = 0.6 -- by the end, the chance a dip goes fully dark
Charge.DarkLonger = 6 -- by the end, a dip lasts up to this many times longer: moments of black
Charge.CatchLow = 0.7 -- a stutter's bright blinks: the bulb catching at this much of its light,
Charge.CatchHigh = 1.08 -- up to a little over it

-- The filament fighting during a stutter (Pro Sound Effects "Light Bulb Buzz 2", a 60 W bulb; its
-- steady stretch, looped; measured, docs/STUDIO.md): heard only while the light stutters.
Charge.Buzz = { id = "rbxassetid://9116267264", from = 0.25, length = 1.3 }
Charge.BuzzVolume = 3.2 -- the recording sits about 20 dB under the torch's click
Charge.BuzzPitchLow = 0.85 -- each blink retunes it a little, so it crackles instead of humming
Charge.BuzzPitchHigh = 1.2
Charge.BuzzNear = 3 -- full volume within this many studs (it's in your hand)
Charge.BuzzReach = 16 -- a friend's dying torch is heard to here
-- The click as it dies: the off click, a touch slower and duller, with no thumb on it.
Charge.DeadSpeed = 0.8
-- Pressing a dead torch's button: the off click, slow and soft, and the torch dips in your hand.
Charge.RefuseSpeed = 0.55
Charge.RefuseVolume = 0.55

-- The meter: a ring of ticks round the flashlight's button like a clock face; a full turn is a
-- full torch, and the lit ones go out one by one as it drains, red for its last half minute.
Charge.Ticks = 12

-- A flicker's state, carried from frame to frame on each screen that draws a torch.
export type Flicker = {
	began: boolean, -- the first stutter of this half minute has started
	wait: number, -- seconds to the next stutter
	stutter: number, -- seconds left of the stutter under way (0: none)
	blink: number, -- seconds left of this blink
	dark: boolean, -- this blink is a dip
	level: number, -- this blink's light, of the steady light
	seed: number, -- its own random numbers, so two torches never stutter together
}

local MODULUS = 2147483647

local function random(f: Flicker): number
	f.seed = f.seed * 16807 % MODULUS
	return f.seed / MODULUS
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Seconds of light in a full torch: `Full`, or the Studio dev number (`Dev`'s value) when that's
-- a real number over zero.
function Charge.full(dev: unknown): number
	if type(dev) == "number" and dev == dev and dev > 0 and dev < math.huge then
		return dev
	end
	return Charge.Full
end

-- What's left after `dt` seconds switched on.
function Charge.drain(left: number, dt: number): number
	return math.max(0, left - math.max(dt, 0))
end

-- What's left once it's switched off: a dying torch is dead (`Spent`).
function Charge.off(left: number): number
	return if left < Charge.Spent then 0 else left
end

-- What the server writes on the Player: whole seconds, rounded up.
function Charge.written(left: number): number
	return math.max(0, math.ceil(left))
end

--[[
	A screen's own reckoning of what's left: `estimate` drained by `dt` while it's `on`, kept within
	the second the server last wrote (`written`, rounded up, so the true charge is above
	`written - 1`). A fill (a battery, a new climb) lifts it at once.
]]
function Charge.follow(estimate: number, written: number, dt: number, on: boolean): number
	local e = if on then estimate - math.max(dt, 0) else estimate
	return math.clamp(e, math.max(written - 1, 0), math.max(written, 0))
end

-- Whether a torch with `left` flickers: in its last half minute, and not yet dead.
function Charge.flickering(left: number): boolean
	return left > 0 and left <= Charge.Flicker
end

-- How far through its last half minute a torch is: 0 as the flicker begins (or before), 1 dead.
function Charge.urgency(left: number): number
	return math.clamp(1 - left / Charge.Flicker, 0, 1)
end

-- The ring's lit ticks for `left` of a `full` torch: a tick for any part of its share left, so
-- the last goes out only as the torch dies.
function Charge.lit(left: number, full: number): number
	if left <= 0 or full <= 0 then
		return 0
	end
	return math.clamp(math.ceil(left / full * Charge.Ticks - 1e-9), 1, Charge.Ticks)
end

-- A fresh flicker; `seed` picks its random numbers (a whole number over zero).
function Charge.flicker(seed: number): Flicker
	return {
		began = false,
		wait = 0,
		stutter = 0,
		blink = 0,
		dark = false,
		level = 1,
		seed = math.clamp(math.floor(math.abs(seed)), 1, MODULUS - 1),
	}
end

-- Starts it over: the next frame in the flicker's half minute begins with the long first stutter
-- (switched back on, a dying torch sputters as it catches).
function Charge.rewind(f: Flicker)
	f.began = false
	f.stutter = 0
	f.dark = false
end

--[[
	One frame of a lit torch with `left` seconds: how much of its full light it gives (0 to 1), and
	whether it's stuttering (the buzz). Steady above the last half minute. In it: the light sags
	and, over its last `Fade` seconds, dies to nothing; stutters break it, a long one first, then
	short and far apart, then longer, closer and darker until it barely holds. Allocates nothing.
]]
function Charge.glow(f: Flicker, left: number, dt: number): (number, boolean)
	if left <= 0 then
		return 0, false
	end
	if left > Charge.Flicker then
		if f.began then
			Charge.rewind(f)
		end
		return 1, false
	end
	dt = math.clamp(dt, 0, 0.1)
	local u = Charge.urgency(left)
	local steady = 1 - Charge.Sag * u * u
	if left < Charge.Fade then
		steady *= left / Charge.Fade
	end
	if not f.began then
		f.began = true
		f.stutter = Charge.FirstStutter
		f.blink = 0
		f.dark = false
	elseif f.stutter <= 0 then
		f.wait -= dt
		if f.wait > 0 then
			return steady, false
		end
		f.stutter = lerp(Charge.StutterFirst, Charge.StutterLast, u) * (0.6 + 0.8 * random(f))
		f.blink = 0
		f.dark = false
	end
	f.stutter -= dt
	f.blink -= dt
	if f.blink <= 0 then
		f.dark = not f.dark
		local hold = lerp(Charge.BlinkShort, Charge.BlinkLong, random(f))
		if f.dark then
			f.level = if random(f) < Charge.Dead * u then 0 else random(f) * Charge.Low
			f.blink = hold * (1 + (Charge.DarkLonger - 1) * u * u)
		else
			f.level = lerp(Charge.CatchLow, Charge.CatchHigh, random(f))
			f.blink = hold
		end
	end
	if f.stutter <= 0 then
		f.stutter = 0
		f.dark = false
		local closing = 1 - (1 - u) * (1 - u)
		f.wait = lerp(Charge.GapFirst, Charge.GapLast, closing)
			* (1 + Charge.GapJitter * (2 * random(f) - 1))
		return steady, false
	end
	return math.min(steady * f.level, 1), true
end

-- The buzz's pitch for this blink: a new one each time the level changes.
function Charge.buzzPitch(f: Flicker): number
	return lerp(Charge.BuzzPitchLow, Charge.BuzzPitchHigh, (f.seed % 1000) / 1000)
end

return Charge
