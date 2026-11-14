--!strict
-- lune run tests/machine.spec
-- The machine waking on a ride (S1-10b2): dark the whole first ride, from the lobby; on a later
-- ride every tube flickers then catches, bottom row first, after the lurch and before the first
-- cable clank, then the sign; it dips with the car's lamp; it's all dark again just after the
-- gate starts to fold. Every share stays between 0 and 1, and each starter's click lands on its
-- tube's flash.
local Ride = require("../src/shared/Elevator/Ride")
local Wake = require("../src/shared/Machine/Wake")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local ROWS = #Wake.Tubes
ok(ROWS == 3, `a tube for each of the three rows: {ROWS}`)

-- the first ride, from the lobby: dark from the slam to the gate folding
local lobbyLit = false
for since = -1, Wake.over() + 1, 0.01 do
	for row = 1, ROWS do
		lobbyLit = lobbyLit or Wake.tube(row, since, Ride.Lobby) > 0
	end
	lobbyLit = lobbyLit or Wake.sign(since, Ride.Lobby) > 0 or Wake.hum(since, Ride.Lobby) > 0
	lobbyLit = lobbyLit or Wake.changing(since, Ride.Lobby)
end
ok(not lobbyLit, "the first ride, from the lobby, never wakes it")

-- every share between 0 and 1, on rides from floors 1 and 7
local inRange = true
for _, from in { 1, 7 } do
	for since = -1, Wake.over() + 1, 0.005 do
		for row = 1, ROWS do
			local s = Wake.tube(row, since, from)
			inRange = inRange and s >= 0 and s <= 1
		end
		local s, h = Wake.sign(since, from), Wake.hum(since, from)
		inRange = inRange and s >= 0 and s <= 1 and h >= 0 and h <= 1
	end
end
ok(inRange, "every light and the hum stay between 0 and 1")

-- dark through the slam and the lurch: the first starter waits until the lamp's flicker is over
local first = Wake.Clicks[1].At
ok(first > Ride.moves() + 0.3, `the first tink comes after the lurch: {first}`)
for since = -0.5, first - 0.01, 0.01 do
	ok(Wake.hum(since, 1) == 0, `dark before the first tink, at {since}`)
end

-- each tube flickers before it catches: lit at some moments, dark at others, then holding
for light = 0, ROWS do
	local start = if light == 0 then Wake.Sign else Wake.Tubes[light]
	local share = function(since: number): number
		return if light == 0 then Wake.sign(since, 1) else Wake.tube(light, since, 1)
	end
	local on, off = false, false
	for since = start.At, Wake.catches(light) - 0.005, 0.005 do
		local s = share(since)
		on = on or s > 0
		off = off or s == 0
	end
	ok(on and off, `light {light} flickers before it catches`)
	local held = true
	for since = Wake.catches(light) + 0.001, Wake.catches(light) + 0.4, 0.01 do
		held = held and share(since) >= Wake.Warm * Wake.power(since) - 1e-6
	end
	ok(held, `light {light} holds once it catches`)
	ok(
		share(Wake.catches(light) + Wake.WarmUp + 0.05)
			> 0.94 * Wake.power(Wake.catches(light) + Wake.WarmUp + 0.05),
		`light {light} is warm a moment after it catches`
	)
end

-- bottom row first, then up the glass, then the sign; all of it before the first clank
for row = 2, ROWS do
	ok(
		Wake.Tubes[row].At > Wake.catches(row - 1) - 0.3,
		`row {row} starts as row {row - 1} catches`
	)
	ok(Wake.catches(row) > Wake.catches(row - 1), `row {row} catches after row {row - 1}`)
end
ok(Wake.catches(0) > Wake.catches(ROWS), "the sign comes on after the top row")
ok(Wake.catches(0) < Ride.Clanks[1], `all awake before the first clank: {Wake.catches(0)}`)

-- awake through the cruise, dipping at each clank with the lamp
local cruise = (Ride.Clanks[1] + Ride.Clanks[2]) / 2
for row = 1, ROWS do
	ok(Wake.tube(row, cruise, 1) > 0.99, `row {row} full in the cruise`)
end
ok(Wake.sign(cruise, 1) > 0.99, "the sign full in the cruise")
ok(Wake.hum(cruise, 1) > 0.99, "the hum full in the cruise")
for _, at in Ride.Clanks do
	ok(Wake.tube(2, at + 0.005, 1) < 0.9, `it dips at the clank at {at}`)
	ok(Wake.tube(2, at + 0.4, 1) > 0.99, `it comes back after the clank at {at}`)
end
ok(Wake.tube(1, Ride.arrives() + 0.01, 1) < 0.8, "it dips as the brakes bite at the top")

-- still lit as the car levels, cut as the gate starts to fold, dark for good after
ok(Wake.tube(1, Ride.opens() - 0.05, 1) > 0.9, "lit until the gate starts to fold")
ok(Wake.sign(Ride.opens() + Wake.Fade, 1) > 0, "the sign outlasts the tubes a beat")
for row = 1, ROWS do
	ok(Wake.tube(row, Ride.opens() + Wake.Fade, 1) == 0, `row {row} out once the power drops`)
end
for since = Wake.over(), Wake.over() + 30, 0.25 do
	ok(Wake.hum(since, 1) == 0, `dark at {since}`)
end
ok(Wake.changing(cruise, 1), "stepped through the ride")
ok(not Wake.changing(Wake.over() + 0.01, 1), "not stepped once it's dark")
ok(Wake.changing(-0.1, 1), "stepped from a hair before the slam")

-- the clicks: in time order, one per flash, each landing on its light's flash
local flashes = #Wake.Sign.Flashes
for _, start in Wake.Tubes do
	flashes += #start.Flashes
end
ok(#Wake.Clicks == flashes, `a click per flash: {#Wake.Clicks} of {flashes}`)
for i, click in Wake.Clicks do
	if i > 1 then
		ok(click.At >= Wake.Clicks[i - 1].At, `click {i} in time order`)
	end
	local s = if click.Light == 0
		then Wake.sign(click.At + 0.01, 1)
		else Wake.tube(click.Light, click.At + 0.01, 1)
	ok(s > 0, `click {i} lands on light {click.Light}'s flash`)
end

if failures > 0 then
	print(`machine: {failures} of {checks} checks failed`)
	error("machine spec failed")
end
print(`machine: {checks} checks passed`)
