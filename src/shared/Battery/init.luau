--!strict
--[[
	Batteries (S1-07b): a battery lying in a unit, the rules alone, so Lune tests them
	(tests/battery.spec.luau). The moment: your beam is stuttering, you lift a door, and there's a
	battery on the floor; one tap, a clack and a click, and your light snaps back full with the
	ring sweeping round its button. While your ring is still full the battery shows you no button:
	it stays where it lies for the friend whose torch is dying (GDD "Your flashlight": a battery
	fills it at once and takes no slot; if yours is full you leave it).

	Proven mechanic: DOORS' batteries lie in drawers to keep its flashlight going and fill it at
	once; Lethal Company's flashlight shows its charge on its own slot and dies when it's spent.

	The deal says which units hold one (`Deal.BatteryShare`); the server's Batteries system lays it
	as the door first lifts, lying on its side in the bulb's pool clear of the unit's coins, and
	fills the taker's torch (`Flashlights:fill`). Its art is generated (`Battery.Specs`,
	art/battery/): this module doesn't require it, so it stays free of Roblox types for Lune.
]]

local Charge = require("./Flashlight/Charge")

local Battery = {}

Battery.Tag = "Battery" -- a battery lying on a unit's floor
Battery.Template = "Battery" -- its MeshPart in ReplicatedStorage.Props
Battery.TakenAttribute = "TakenBy" -- on a battery: the UserId of whoever took it, once taken

-- Studs from your middle to a battery's button: a coin pile's reach (`Coins.Reach`), so you step
-- into the unit to take it.
Battery.Reach = 8

-- Seconds a taken battery stays for every screen to throw it into its taker's torch before the
-- server removes it: the hop, the flight and a little room for a slow phone.
Battery.Linger = 0.9

-- Degrees it lies rolled about its length, either way, from the plus facing straight up: tipped
-- a little toward or away from you, as a thing that rolled to a stop does, the plus still showing.
Battery.Roll = 28

--[[
	The rate check: no more than `Rate` takes a second, `Burst` at once. Batteries are rare, so
	this only stops a script hammering the button. Returns whether this take may go ahead, and the
	burst left after it.
]]
Battery.Rate = 2
Battery.Burst = 2

function Battery.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Battery.Burst - 1
	end
	local left = math.min(Battery.Burst, burst + math.max(0, now - last) * Battery.Rate)
	if left < 1 then
		return false, left
	end
	return true, left - 1
end

--[[
	Whether a torch with `left` seconds of a `full` torch takes a battery: once its ring has lost a
	tick (`Charge.lit`). A full ring is a full torch to your eye, so the battery has no button for
	you then and stays for a friend; a battery is never spent on a few seconds of light.
]]
function Battery.wants(left: number, full: number): boolean
	return Charge.lit(left, full) < Charge.Ticks
end

-- The feel of a take, on every screen (the client's BatteryView).
Battery.Hop = 0.8 -- studs it jumps off the floor as it's taken
Battery.HopTime = 0.14 -- seconds to the top of the hop, turning end over end
Battery.Fly = 0.26 -- seconds from the top of the hop into its taker's torch, shrinking away
Battery.Turns = 1.25 -- turns end over end from the floor to the torch: a flash of amber
Battery.Shrink = 0.35 -- of its size as it reaches the torch, sliding in

-- The sounds, the torch's own two clicks (Pro Sound Effects' "Flashlight Switch", measured,
-- `Torch.OnSound`/`OffSound`): a heavy clack as the cell seats (the off click, slow and low), then
-- the bright click of the cap snapping home. Heard by friends close by; on the taker's own torch.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }
Battery.Clack = {
	id = "rbxassetid://9114480269",
	from = 0.1,
	length = 0.14,
	volume = 1.4,
	pitch = 0.62,
} :: Sound
Battery.Snap = {
	id = "rbxassetid://9114480271",
	from = 0.38,
	length = 0.14,
	volume = 1.1,
	pitch = 1.08,
} :: Sound
Battery.SnapAfter = 0.075 -- seconds from the clack to the snap: one quick clack-click
Battery.Heard = 24 -- studs a take is heard: friends in the same stretch of hall

-- The glint: now and then a spark on its steel button, so it reads from the doorway on a phone.
Battery.GlintRate = 0.55 -- sparks a second: rarer than a coin's, steel not gold

return Battery
