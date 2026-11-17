--!strict
--[[
	Holding: a home each, handed out as players join (S5-03a3b, D-259, D-273, D-275). Brix's Plots
	keeps who holds which; this is the game's side of it, pure so the Lune tests cover it.

	The moment: you load in and one of the twelve homes is yours. A beat after you're standing
	there, your name sprays onto the card over its door through the building's stencil, with a
	hiss, and the door rolls up with its slow, loud open and warm light spilling out. Pull it
	down and only you get back in: anyone else's try rattles it against the lock (Door.decideHeld).
	Precedent: Grow a Garden's and Bee Swarm Simulator's plots, one handed to each player on join;
	Adopt Me's house locked against anyone but its owner.

	Pure: no Roblox services, so `lune run tests/holding.spec` loads it.
]]

export type Vec = { number }
export type Slot = { Number: number, Door: Vec }

local Holding = {}

-- A home's plot name in Brix's Plots: its slot's number, as the unit's own name has it.
function Holding.plot(number: number): string
	return `Unit{number}`
end

-- The slot number in a plot name, or nil if it isn't one.
function Holding.number(plot: string): number?
	local n = string.match(plot, "^Unit(%d+)$")
	return if n then tonumber(n) else nil
end

--[[
	The homes' plot names, nearest `spawn` first (the doors' distance across the floor, ignoring
	height), ties to the lower number: a half-full server's homes sit together by the front door
	and you walk the least to yours (D-273).
]]
function Holding.order(slots: { Slot }, spawn: Vec): { string }
	local sorted = table.clone(slots)
	local function far(s: Slot): number
		local dx, dz = s.Door[1] - spawn[1], s.Door[3] - spawn[3]
		return dx * dx + dz * dz
	end
	table.sort(sorted, function(a: Slot, b: Slot): boolean
		local fa, fb = far(a), far(b)
		if math.abs(fa - fb) > 1e-6 then
			return fa < fb
		end
		return a.Number < b.Number
	end)
	local names = {}
	for i, s in sorted do
		names[i] = Holding.plot(s.Number)
	end
	return names
end

-- The most letters a name card takes: a Roblox display name is at most 20, and the card's
-- lettering shrinks to fit (TextScaled), so this only guards against anything longer.
Holding.MostLetters = 20

-- The words on the card over a held home's door: its holder's display name in the building's
-- capitals, as the floor's other cards are lettered.
function Holding.words(displayName: string): string
	local name = string.gsub(displayName, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if utf8.len(name) == nil then
		return string.upper(string.sub(name, 1, Holding.MostLetters))
	end
	local cut = utf8.offset(name, Holding.MostLetters + 1)
	if cut then
		name = string.sub(name, 1, cut - 1)
	end
	return string.upper(name)
end

-- Feel numbers for a home handed out.
Holding.Arrive = {
	-- seconds after your character first stands in the lobby before your name goes up and your
	-- door rolls: long enough that your screen is up and you hear it, short enough it's a welcome
	After = 1.5,
	-- seconds between the name going up and the door starting to roll: the hiss, then the roll
	DoorAfter = 0.6,
}

-- How a name arrives on its card, on every screen within earshot (HomeCards): sprayed through
-- the stencil, the letters coming up from nothing over `Spray` seconds as the ink lands, bright
-- for a moment and settling to the card's own ink over `Settle`, with a short can's hiss.
Holding.Card = {
	Spray = 0.55, -- seconds the lettering takes to come up through the stencil
	Settle = 0.9, -- seconds the fresh ink takes to settle from bright to the card's own
	Swell = 1.12, -- how big the lettering starts (it shrinks onto the card as it lands)
	-- the hiss: Pro Sound Effects' "Spray Paint 4", the can's first burst
	Sound = "rbxassetid://9119522956",
	Volume = 0.45, -- soft: a welcome, not an alarm
	Start = 0, -- seconds into the recording
	Stop = 0.8,
	Near = 8, -- studs it's heard at full
	Reach = 60, -- studs it's heard to: across the floor, so friends hear a home taken
	-- A name blanked as its holder leaves fades over this many seconds.
	Fade = 0.6,
}

return Holding
