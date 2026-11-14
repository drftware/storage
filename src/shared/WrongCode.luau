--!strict
--[[
	What a wrong code lets out (S2-04, GDD "A wrong code"; the owner settled it in D-127). Each
	wrong code on a floor rolls up the doors of units with monsters in them, by themselves: one on
	the first, three on the second, five on every one after. So a team can't stand at the keypad
	and try all ten numbers for the last digit: every guess costs them, and the alarm brings what
	it let out straight to them. The keypad's own lock growing with each wrong code is the
	keypad's rule (`Keypad.dead`).

	Which units: the ones whose monster still sleeps first (nobody has lifted their door), then
	ones holding a monster already awake behind a shut door (pounding, or shut back in). A
	padlocked door holds, as it holds a pounding monster (S2-03b): it is never picked. Sleepers
	wake to come out, so they count against the floor's cap on monsters on their feet
	(`Waking.AwakeMost`, for low-end phones); an awake one shut in is already counted.

	Pure: the keepers' brain asks it which units on a wrong code (Keepers' `letOut`).
	The numbers are feel numbers; each says what it does to the player.
]]

local WrongCode = {}

-- Units rolled up by the first wrong code on a floor, the second, and the third and every one
-- after: one is a sting you can still run from, three is a floor turning on you, five says stop
-- guessing.
WrongCode.Opens = { 1, 3, 5 }

-- Seconds after a wrong code before the first door starts rolling: the buzz and the bell land
-- first, then somewhere down the halls a door goes up by itself.
WrongCode.FirstAfter = 1.2
-- Seconds between one door starting to roll and the next: a ripple of doors across the floor,
-- each heard on its own, never one chord.
WrongCode.Between = 0.7

-- How many units the `nth` wrong code on a floor rolls up (1 for the first).
function WrongCode.opens(nth: number): number
	if nth < 1 then
		return 0
	end
	return WrongCode.Opens[math.min(math.floor(nth), #WrongCode.Opens)]
end

-- Seconds after the wrong code that the `i`th door picked (1 for the first) starts to roll.
function WrongCode.rollAt(i: number): number
	return WrongCode.FirstAfter + (i - 1) * WrongCode.Between
end

--[[
	Which units the `nth` wrong code rolls up: up to `opens(nth)` of them, `asleep` (each a unit
	whose monster still sleeps, padlocked ones left out by the caller) picked first, then `held`
	(units holding one awake behind a shut door), each group a fair random pick (`roll(k)` gives
	1 to k). No more than `room` sleepers wake: the monsters still allowed on their feet on the
	floor. Returns the picked sleepers' units, then the held ones', in rolling order.
]]
function WrongCode.pick(
	asleep: { number },
	held: { number },
	nth: number,
	room: number,
	roll: (number) -> number
): { number }
	local n = WrongCode.opens(nth)
	local picked: { number } = {}
	local function from(pool: { number }, most: number)
		local left = table.clone(pool)
		for _ = 1, math.min(most, #left) do
			local i = roll(#left)
			table.insert(picked, left[i])
			left[i] = left[#left]
			left[#left] = nil
		end
	end
	from(asleep, math.min(n, math.max(room, 0)))
	from(held, n - #picked)
	return picked
end

return WrongCode
