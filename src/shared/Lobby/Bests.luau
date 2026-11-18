--!strict
--[[
	Bests (S6-01b, D-433): the best floors the lobby shows, as plain data. Each player's best floor
	is on them (`Badges.BestAttribute`, set by the server's BestFloors); this works out what the
	dial over a car and the plaque beside its gate show from those aboard, as DOORS' and
	Pressure's lobbies show your record where you queue.

	- The dial's line reads "Best N", the best of those aboard, once someone aboard has climbed.
	  It takes turns with "Full" or "Friends only" when the car has one of those to say. While
	  nobody's aboard, the dial and the plaque keep to the crew that last was (`shown`).
	- The plaque lists those aboard, best first; ties and anyone not loaded yet keep the order
	  they stepped in.
	- A best that rose while nobody on this screen saw it (the climb) flips up from what the car's
	  best was, digit by digit with a clack each, slowing as it settles, then a chime: an
	  odometer's roll, as a pinball table's score counts up to a new high score.

	Pure: no Roblox calls. The screens keep `before` (each player's best before a rise not yet
	shown) and clear it once the flip has played (`seen`).
]]
local Bests = {}

-- Best floor by UserId, as each player's attribute reads (missing: their save isn't loaded yet).
export type Bests = { [number]: number }
-- A plaque row: who, and their best floor (0: none yet).
export type Row = { id: number, floor: number }
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }

-- The digits' roll: the first clack this soon, slowing to this by the last (seconds), and at
-- most this many numbers passed through however far it rose (a long way skips evenly).
Bests.Roll = table.freeze({ First = 0.07, Last = 0.2, Most = 8 })
-- The line's turns when the car also has "Full" or "Friends only" to say: that line this long,
-- then the best this long (seconds, on the server's clock so every screen agrees).
Bests.Turn = table.freeze({ Other = 3, Best = 2 })

-- Each digit turning over: the vend flap's hollow plastic knock (Tally.Knock), short and quick,
-- a touch higher each step so the roll climbs.
Bests.Clack = table.freeze({
	id = "rbxassetid://9120089728",
	from = 0,
	length = 0.12,
	volume = 0.5,
	pitch = 0.8,
}) :: Sound
Bests.ClackRise = 0.03
-- The last digit landing: the battery's heavy clack as a cell seats (Battery.Clack), a shade
-- higher, so the roll stops with a thunk.
Bests.Land = table.freeze({
	id = "rbxassetid://9114480269",
	from = 0.1,
	length = 0.14,
	volume = 1.1,
	pitch = 0.75,
}) :: Sound
-- Then the chime: the board's bright chink for the best line (Tally.Shine), the climb's sound
-- for "your best".
Bests.Chime = table.freeze({
	id = "rbxassetid://9113849162",
	from = 1.08,
	length = 0.4,
	volume = 0.65,
	pitch = 1.35,
}) :: Sound

-- The best floor of those aboard, or nil while none of them has climbed (or none is loaded).
function Bests.top(group: { number }, best: Bests): number?
	local top = 0
	for _, id in group do
		local floor = best[id]
		if floor and floor > top then
			top = floor
		end
	end
	return if top >= 1 then top else nil
end

-- The plaque's rows: those aboard, best first; ties and anyone not loaded yet (0) keep the order
-- they stepped in.
function Bests.rows(group: { number }, best: Bests): { Row }
	local rows: { Row } = {}
	local at: { [number]: number } = {}
	for i, id in group do
		rows[i] = { id = id, floor = best[id] or 0 }
		at[id] = i
	end
	table.sort(rows, function(a: Row, b: Row): boolean
		if a.floor ~= b.floor then
			return a.floor > b.floor
		end
		return at[a.id] < at[b.id]
	end)
	return rows
end

-- Whose bests a car shows: those aboard; while nobody is, its crew, those who last were (S6-01c,
-- D-434). A team landing back walks out of the car and turns round to the dial over its gate:
-- from inside you can't see it, so its new best rolls up there, as they look, not while aboard.
function Bests.shown(group: { number }, crew: { number }): { number }
	return if #group > 0 then group else crew
end

-- `crew` less anyone in `group`: someone who boards another car is no longer this one's crew.
function Bests.without(crew: { number }, group: { number }): { number }
	local out: { number } = {}
	for _, id in crew do
		if not table.find(group, id) then
			table.insert(out, id)
		end
	end
	return out
end

-- What the car's best was before a rise not yet shown (`before`: each risen player's best before
-- it rose), when that's lower than its best now: the number its digits flip up from. Nil when
-- there's nothing to flip (no rise, or one that stays under someone else's best).
function Bests.risen(group: { number }, best: Bests, before: Bests): number?
	local now = Bests.top(group, best)
	if not now then
		return nil
	end
	local was = 0
	for _, id in group do
		local floor = before[id] or best[id] or 0
		if floor > was then
			was = floor
		end
	end
	return if was < now then was else nil
end

-- The flip for those aboard has played: their rises are shown.
function Bests.seen(group: { number }, before: Bests)
	for _, id in group do
		before[id] = nil
	end
end

-- The numbers the digits pass through from `from` up to `to`: each one while there are at most
-- `most`, else `most` of them spread evenly, always ending on `to`. Empty unless it rose.
function Bests.steps(from: number, to: number, most: number): { number }
	local out: { number } = {}
	local span = to - from
	if span <= 0 then
		return out
	end
	local n = math.min(span, most)
	for i = 1, n do
		table.insert(out, from + math.round(span * i / n))
	end
	return out
end

-- Seconds before the `i`th of `n` steps: quick at first, slowing as the digits settle.
function Bests.gap(i: number, n: number): number
	local r = Bests.Roll
	if n <= 1 then
		return r.Last
	end
	local k = (i - 1) / (n - 1)
	return r.First + (r.Last - r.First) * k * k
end

-- Whether the line shows the best now, at server time `t`, when the car also says Full or
-- Friends only: that line first, then the best, round again.
function Bests.turn(t: number): boolean
	local turn = Bests.Turn
	return t % (turn.Other + turn.Best) >= turn.Other
end

return table.freeze(Bests)
