--!strict
--[[
	JobBox: the rules for your home's job box (S5-03c2a, D-287), pure so Lune can test them. The
	moment: the shelf's full, you keep one more at the gate, and when you come home the job box's
	lid sparkles; press Open and the lid swings up with a soft steel creak. Precedents: Resident
	Evil's item box (one box holds everything), Animal Crossing's house storage, Fortnite's locker
	marks (what's new shows until you look).

	The server (JobBoxes) puts the box's button in front of it for its holder only, keeps the box's
	attributes below and closes it when its holder walks away or leaves; every screen (JobBoxView)
	swings the lid by `angle` and sparkles it while something new is in it.
]]
local JobBox = {}

JobBox.Tag = "JobBox" -- on each home's JobBox piece, for every screen
-- The lid: 0 shut; up, 1 plus how new what was in it as it opened (Save.Fresh), so the opener's
-- screen chimes for a kind they'd never owned. One attribute: never the lid up without what it found.
JobBox.LidAttribute = "Lid"
JobBox.FreshAttribute = "Fresh" -- how new what went in since it was opened is, as Save.Fresh
JobBox.Spot = "JobBoxSpot" -- the button's spot, a child of the unit (HomeCards shows it to its holder)

-- The Open button: in front of the lid's middle, into the room, at a standing hand's height.
JobBox.Button = {
	Out = 1.0, -- studs in front of the box's front face
	Up = 2.4, -- studs above the floor
	Reach = 7, -- studs it can be pressed from
	Cooldown = 0.4, -- seconds between presses that count: mashing never rattles the lid
}
JobBox.Away = 14 -- studs from the box its holder may wander before the lid closes by itself
JobBox.Every = 0.5 -- seconds between the server's looks at who's near an open box

-- The lid's swing about its hinge (Home.Specs.JobBox.Hinge).
JobBox.Lid = {
	Lift = 88, -- degrees up when open: just short of upright, clear of the wall behind
	Open = 1.1, -- seconds a full lift takes, eased in and out: a slow, heavy, creaking swing
	Close = 0.42, -- seconds a full drop takes, gathering speed: it falls shut
	Bounce = { Degrees = 2.5, Seconds = 0.16 }, -- the little kick as it lands, from a full drop
}

-- How the lid sparkles while something new is in the box (Shelf's twinkle, spread over the lid).
JobBox.Sparkle = {
	Rate = 5, -- glints a second over the whole lid: one find's 3, spread wider
	Burst = 18, -- thrown as the lid opens, before it stops
}

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
-- The lid lifting: Pro Sound Effects' "Creaks And Squeaks 6" (heavy metal creaks, 1.3 to 2 kHz,
-- no squeal), quiet and a touch higher: a steel lid, not a car on a winch.
JobBox.Creak = {
	id = "rbxassetid://9113969124",
	from = 0.2,
	length = 0.9,
	volume = 0.35,
	pitch = 1.1,
} :: Sound
-- The lid landing: the clack of Pro Sound Effects' "Mail Box Lid Open Close Metal Flap 10",
-- pitched down to a heavier steel lid. Its hit is `Hit` seconds in (0.15 s at its own pitch).
JobBox.Clunk = {
	id = "rbxassetid://9116436662",
	from = 1.45,
	length = 0.6,
	volume = 0.6,
	pitch = 0.7,
} :: Sound
JobBox.Hit = 0.15 / 0.7
JobBox.Hearing = 30 -- studs either sound carries: your own room and the hall just outside

-- How long a drop from `from` degrees takes to land: a fall's time grows as the root of its height.
function JobBox.landing(from: number): number
	return JobBox.Lid.Close * math.sqrt(math.clamp(from / JobBox.Lid.Lift, 0, 1))
end

--[[
	The lid's angle (degrees up) `elapsed` seconds after it began to open (`open`) or close from
	`from` degrees, and whether it's come to rest. Opening eases in and out over the part of a full
	lift left; closing falls, gathering speed, then kicks up a little as it lands (less from a
	short drop).
]]
function JobBox.angle(open: boolean, from: number, elapsed: number): (number, boolean)
	local lid = JobBox.Lid
	if open then
		local seconds = lid.Open * math.max(lid.Lift - from, 0) / lid.Lift
		if elapsed >= seconds then
			return lid.Lift, true
		end
		local k = elapsed / seconds
		return from + (lid.Lift - from) * (1 - math.cos(math.pi * k)) / 2, false
	end
	local seconds = JobBox.landing(from)
	if elapsed < seconds then
		local k = elapsed / seconds
		return from * (1 - k * k), false
	end
	local after = elapsed - seconds
	local bounce = lid.Bounce
	if from <= 0 or after >= bounce.Seconds then
		return 0, true
	end
	return bounce.Degrees * math.min(from / lid.Lift, 1) * math.sin(
		math.pi * after / bounce.Seconds
	),
		false
end

return table.freeze(JobBox)
