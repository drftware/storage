--!strict
--[[
	Arrival: a press made the moment you arrive counts (L-16b2, D-113), pure so Lune checks it
	(tests/arrival.spec.luau). The moment: you sprint into a unit and press Saw at the wall, or
	reach the ladder and press Climb, and it just works, first time.

	The server sees your run late: D-084 measured 0.06 to 0.13 s, eased in over another 0.15 to
	0.4 s, and in Studio a press made on arrival came with the server seeing you 3.5 to 4.3 studs
	back at a full run (L-12c's Crawl, L-16b2's Climb and Saw). So the press reached it while it
	saw you short of the ladder's reach, or still out in the hall, and was dropped without a word.

	So every server check of where you stand for a press asks here: does it pass where the server
	sees you, or where you'll be a moment on at the speed it sees you moving, out to `Lag`. It gives
	a cheat nothing: your own screen already moves your character, so it could simply be there.

	The checks are in seconds on, not places, so the server's Vector3s and the pure modules'
	vectors both use it as they are: a check works out its own place from the seconds it's given.
]]

local Arrival = {}

-- Seconds the server's view of you may trail your own screen: past the 0.22 to 0.27 s seen in
-- Studio, for a live server's longer ease. Longer lets a press count from further back.
Arrival.Lag = 0.4
-- How many moments past where the server sees you a press is judged at, evenly out to `Lag`:
-- enough that running past a button can't step over its reach (1.6 studs apart at a full run).
Arrival.Steps = 4

--- Seconds on of the `i`th moment a press is judged at: 0 is where the server sees you, `Steps`
--- a whole `Lag` on. For a check run every frame, loop `0..Steps` with this and make no closure.
function Arrival.ahead(i: number): number
	return Arrival.Lag * i / Arrival.Steps
end

--- Whether a press counts: `check(seconds)` says whether it would where you'll be that many
--- seconds on from where the server sees you, at the speed it sees you moving. Judged where it
--- sees you first, then each moment on; the first that passes counts.
function Arrival.counts(check: (seconds: number) -> boolean): boolean
	for i = 0, Arrival.Steps do
		if check(Arrival.ahead(i)) then
			return true
		end
	end
	return false
end

return Arrival
