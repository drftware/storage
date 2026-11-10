--!strict
--[[
	Dent: how badly a trapped keeper has beaten its door out toward the hall (L-06b3d2, D-079).

	The moment: the door you slammed on it starts to bow out toward you, worse with each blow, so
	from the hall you can see how close it is to coming through (Amnesia's battered doors).

	The server keeps one number on the unit, its `DoorDent` attribute: the share of the keeper's
	break-out time gone at its latest blow, 0 to 1, never going back (`RollUpDoor.dent`). Every
	screen turns it into one of the door's baked steps (`step`; the steps are art/unit/dent.py's,
	listed in the unit's Specs as `Dent`) and RollUpDoor's rig swaps that step's bowed ribs into
	the chain. Pure: no Roblox, so Lune checks it.
]]

local Dent = {}

-- The unit's attribute the server sets and every screen reads.
Dent.Attribute = "DoorDent"

--[[
	Where each step lands, as a share of the keeper's break-out time gone, worst last. The first
	blow already shows (a fist-sized pocket at chest height: the slam's answer is on the door
	itself); bowed from guide to guide by about 36 s of its 90; buckling, out past the hall wall's
	face, by about 68 s. So a player peeking from the hall every half minute sees it worse each
	time, and the last step says the burst is near.
]]
Dent.Lands = { 0, 0.4, 0.75 }

-- The share of `breakOut` seconds gone after `trapped` seconds shut in, 0 to 1.
function Dent.share(trapped: number, breakOut: number): number
	if breakOut <= 0 then
		return 1
	end
	return math.clamp(trapped / breakOut, 0, 1)
end

-- The door's dent after a blow at `share`, from `was`: it only ever gets worse.
function Dent.raise(was: number, share: number): number
	return math.max(math.clamp(was, 0, 1), math.clamp(share, 0, 1))
end

-- The baked step a dent of `share` shows, 0 (none) to `steps`: none before the first blow,
-- the last step once its time is up.
function Dent.step(share: number, steps: number): number
	if not (share > 0) or steps < 1 then -- also NaN
		return 0
	end
	local at = 0
	for i, from in Dent.Lands do
		if i > steps then
			break
		end
		if share >= from then
			at = i
		end
	end
	return at
end

return Dent
