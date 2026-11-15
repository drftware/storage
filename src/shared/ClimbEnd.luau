--!strict
--[[
	The climb ends (L-08d, the GDD's "Whole team kept"): one screen says how far the team got, and
	one button, "Again", starts the next climb, as DOORS' Play Again does (Gate 1 is friends asking
	for another run).

	It ends one of two ways:
	- **Kept** (a loss): nobody is left climbing, everyone kept in a unit, left behind watching the
	  ride or being carried up to the next floor's units (`look`, `over`). It ends as the last free
	  friend's catch cuts to black. The black comes down on every screen; the
	  building goes quiet (`Cover`: the server clears the climb under the black); a beat of
	  silence; far off in the building two doors come down; then "Kept" lands with a low hit, the
	  team's photos drop in one by one, each with the floor it was lost on, as the Missing board
	  will show them, and "Again" rises.
	- **Top** (an escape): the car leaves the top floor with friends aboard (`Climb.Top`, a stand-in
	  until Phase 2's top floor). The ride goes as any ride does until the cable's second knock,
	  where every other ride hands over to the next floor; here light floods down the shaft
	  instead, white and whole, and the motor is gone; the bell rings clear; the white settles into
	  the warm lamp light of the results, "Made it".

	Everyone's screen plays the same timeline from the same server time (`encode`), so friends see
	it land together; the server clears the climb at `Cover`, when every screen is covered.

	"Again": each press puts that friend in (their photo lights); the next climb starts as soon as
	everyone's in, or `AgainWait` after the first press, as DOORS' lobby elevators count down once
	the first player steps in, so one friend who has wandered off never holds the rest. It leads
	back to the lobby (L-08e2): the group standing in the car they left from, the results on its
	back wall (`encodeResults`), the car's count running for another go. Where no car waits (the
	test hall's climb in Studio) it starts floor 1 of a fresh building, everyone in its lobby.

	Pure numbers and words, so Lune checks them; the server ends the climb (ClimbEnds), each screen
	draws it (EndView).
]]
local Caught = require("./Caught")
local Climb = require("./Climb")

local ClimbEnd = {}

-- On Workspace while the climb's end shows: "<server time>|<how>|<floor>|<seconds>" (`encode`):
-- when it ended, how ("Kept" or "Top"), the floor the team reached, and how long the climb took.
-- Cleared once everyone has a character in the next climb's lobby.
ClimbEnd.Attribute = "ClimbEnd"
-- On each player in the end: "<how>|<floor>" (`encodeFate`): "Out" (rode off the top), "Kept"
-- or "Left", and the floor they were lost on, or reached.
ClimbEnd.FateAttribute = "ClimbFate"
-- On each player who has pressed Again (true), until the next climb starts.
ClimbEnd.InAttribute = "AgainIn"
-- On Workspace once someone has pressed Again: the server time the next climb starts.
ClimbEnd.StartAttribute = "AgainAt"
-- On Workspace once Again leads back to the lobby (L-08e2), until the next end: the screens lift
-- onto your car (or the front office) with no floor number.
ClimbEnd.LobbyAttribute = "EndsInLobby"
-- On a player from Again until the next end: where the server stood their new character (a
-- CFrame). As the black lifts their camera turns that way (in first person the body turns to the
-- camera, so the body's own facing can't be trusted by then).
ClimbEnd.StoodAttribute = "StoodAt"
-- ReplicatedStorage.Remotes.Again: a screen's press of Again (no arguments).
ClimbEnd.Remote = "Again"

export type How = "Kept" | "Top"
export type Fate = "Out" | "Kept" | "Left"
-- A player as the end sees them: still climbing, kept in a unit, or left behind.
export type State = "Climbing" | "Kept" | "Left"
-- Someone out of the climb, as the end notes them: how, and the floor that happened on.
export type Lost = { fate: Fate, floor: number }

-- Seconds after the first press of Again that the next climb starts anyway: long enough to read
-- the screen and find the button, short enough that nobody waits on a friend who has gone.
ClimbEnd.AgainWait = 10
-- Seconds between presses the server takes from one player.
ClimbEnd.AskEvery = 0.5
-- Seconds between the server's looks at who is still climbing: quick enough that the end lands
-- on the catch's black, not after the caught friend's eyes open.
ClimbEnd.CheckEvery = 0.1

-- A wipe's timeline, in seconds after the last friend's catch cut to black (the server's end).
ClimbEnd.Kept = {
	-- the black comes down on every screen (the caught friend's is black already)
	BlackIn = 1.2,
	-- whole: the server clears the climb, and the building goes quiet
	Cover = 1.3,
	-- far off in the building, two doors come down, the second further off
	Slams = { 2.35, 2.95 },
	-- "Kept" lands with a low hit
	TitleAt = 3.6,
	-- the photos drop in, one after another
	PhotosAt = 4.0,
	PhotoEvery = 0.14,
	-- how far you got, and how long it took
	StatsAt = 4.25,
	-- the one button
	AgainAt = 4.9,
}
-- An escape's timeline, in seconds after the car left the top floor (the gate hit its post).
ClimbEnd.Top = {
	-- light floods down the shaft as the cable knocks a second time, where any other ride hands
	-- the team over to the next floor (Climb.HandOff); slow to start, then all at once
	WhiteAt = Climb.HandOff,
	WhiteIn = 1.2,
	-- whole: the server clears the climb, and the motor is gone
	Cover = Climb.HandOff + 1.3,
	-- the bell rings clear in the white: the same bell that counted you out
	BellAt = Climb.HandOff + 1.8,
	-- the white settles into the results' warm dark
	SettleAt = Climb.HandOff + 2.1,
	SettleIn = 1.6,
	TitleAt = Climb.HandOff + 2.5,
	PhotosAt = Climb.HandOff + 2.9,
	PhotoEvery = 0.14,
	StatsAt = Climb.HandOff + 3.15,
	AgainAt = Climb.HandOff + 3.8,
}
-- How long the title takes to land: a wipe's slams down from `Slam` times its size, heavy and
-- quick; an escape's rises softly from `Rise`.
ClimbEnd.Land = 0.22
ClimbEnd.Slam = 1.28
ClimbEnd.Ease = 0.7
ClimbEnd.Rise = 0.94
-- Seconds a photo, the stats line and the button take to come in.
ClimbEnd.PhotoIn = 0.28
ClimbEnd.StatsIn = 0.5
ClimbEnd.AgainIn = 0.45
-- Pixels a photo drops as it lands, and the button rises.
ClimbEnd.PhotoDrop = 14
ClimbEnd.AgainRise = 22
-- The screen's jolt as "Kept" lands (pixels, dying away over `JoltOut` seconds).
ClimbEnd.Jolt = 9
ClimbEnd.JoltOut = 0.35

-- Back in: once your new character is in floor 1's lobby, the black lifts off it over `LiftIn`
-- with the bell, and the floor's number shows for `FloorHold` in the lamp's light.
ClimbEnd.LiftIn = 1.1
ClimbEnd.FloorHold = 1.6
-- Seconds the screen waits for your character before it lets go anyway.
ClimbEnd.LiftWait = 20

-- Where friends stand in the next climb's lobby, beside each other in front of the car: studs
-- apart, and how many to a row before the next row steps forward.
ClimbEnd.Apart = 3
ClimbEnd.Row = 5

-- The words. Few: the screen says how far you got and gives one button.
ClimbEnd.Copy = {
	Kept = "Kept",
	Top = "Made it",
	Floor = "Floor %d",
	Again = "Again",
	Waiting = "Waiting",
	Soon = "Back in %d",
	Going = "Going back",
}

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- What the two timelines share: when the climb is cleared, and when each part of the screen comes.
export type Timeline = {
	Cover: number,
	TitleAt: number,
	PhotosAt: number,
	PhotoEvery: number,
	StatsAt: number,
	AgainAt: number,
}

local function timeline(how: How): Timeline
	return if how == "Top" then ClimbEnd.Top else ClimbEnd.Kept
end
-- The timeline for an end of this kind.
ClimbEnd.timeline = timeline

-- When the server clears the climb, in seconds after the end (every screen is covered by then).
function ClimbEnd.cover(how: How): number
	return timeline(how).Cover
end

-- When the button comes up, in seconds after the end.
function ClimbEnd.againAt(how: How): number
	return timeline(how).AgainAt
end

-- Whether the climb is over: there's someone to end it for, and none of them is still climbing.
-- `standIns` (Studio) count as friends still climbing.
function ClimbEnd.over(states: { State }, standIns: number?): boolean
	if #states == 0 or (standIns or 0) > 0 then
		return false
	end
	for _, s in states do
		if s == "Climbing" then
			return false
		end
	end
	return true
end

-- One player at one of the server's looks (S3-01b), on `floor`, the one the climb is on: kept in
-- a unit, left behind watching the ride, or carried up to floor `carriedTo` (from the car's
-- arrival there until they're stood wrapped in one of its units). Carried counts as kept on the
-- floor they're carried to: nobody is out of the climb any more, so the black on the way to the
-- unit is a wrap like any other, and the end lands on the last free friend's catch rather than
-- waiting a few seconds for the unit to stream in; their photo names the floor they're kept on
-- now. Otherwise the floor is the one they were first lost on (kept, then left behind as the car
-- goes, is still that floor). `was` is what the last look noted (nil while climbing). Returns
-- their state and what to note now (nil while climbing: cut free, they start again).
function ClimbEnd.look(
	was: Lost?,
	floor: number,
	kept: boolean,
	out: boolean,
	carriedTo: number?
): (State, Lost?)
	if carriedTo then
		return "Kept", { fate = "Kept", floor = carriedTo }
	elseif kept then
		return "Kept", { fate = "Kept", floor = if was then was.floor else floor }
	elseif out then
		return "Left", { fate = "Left", floor = if was then was.floor else floor }
	end
	return "Climbing", nil
end

-- How dark the backdrop is `since` seconds into the end: for a wipe it comes down over the
-- world; for an escape it comes up under the white as the white settles (so it's whole by the
-- time the white has gone).
function ClimbEnd.black(how: How, since: number): number
	if how == "Top" then
		return if since >= ClimbEnd.Top.SettleAt then 1 else 0
	end
	return smooth(since / ClimbEnd.Kept.BlackIn)
end

-- How white the screen is `since` seconds into an escape: the light blooms (slow, then all at
-- once), holds while the bell rings, then settles away into the warm dark.
function ClimbEnd.white(how: How, since: number): number
	if how ~= "Top" then
		return 0
	end
	local t = ClimbEnd.Top
	if since < t.WhiteAt then
		return 0
	end
	local u = math.clamp((since - t.WhiteAt) / t.WhiteIn, 0, 1)
	local bloom = u * u * u -- light pours in faster and faster
	local settle = smooth((since - t.SettleAt) / t.SettleIn)
	return bloom * (1 - settle)
end

-- The title `since` seconds into the end: how visible (0 to 1) and its size (a share).
function ClimbEnd.title(how: How, since: number): (number, number)
	local at = timeline(how).TitleAt
	if since < at then
		return 0, if how == "Top" then ClimbEnd.Rise else ClimbEnd.Slam
	end
	if how == "Top" then
		local u = math.clamp((since - at) / ClimbEnd.Ease, 0, 1)
		return smooth(u), ClimbEnd.Rise + (1 - ClimbEnd.Rise) * smooth(u)
	end
	local u = math.clamp((since - at) / ClimbEnd.Land, 0, 1)
	local eased = u * u -- falls faster and faster, then stops dead: a weight landing
	return math.min(u * 2.5, 1), ClimbEnd.Slam + (1 - ClimbEnd.Slam) * eased
end

-- The screen's jolt (pixels) `since` seconds into a wipe, as the title lands: hard at once and
-- dying away. Nothing for an escape.
function ClimbEnd.jolt(how: How, since: number): number
	if how ~= "Kept" then
		return 0
	end
	local t = since - (ClimbEnd.Kept.TitleAt + ClimbEnd.Land)
	if t < 0 or t > ClimbEnd.JoltOut then
		return 0
	end
	local fade = 1 - t / ClimbEnd.JoltOut
	return ClimbEnd.Jolt * fade * fade * math.cos(t * 70)
end

-- The `i`th photo (from 1) `since` seconds into the end: how visible, and how far above its spot
-- it still is (pixels).
function ClimbEnd.photo(how: How, i: number, since: number): (number, number)
	local tl = timeline(how)
	local at = tl.PhotosAt + (i - 1) * tl.PhotoEvery
	local u = math.clamp((since - at) / ClimbEnd.PhotoIn, 0, 1)
	local fall = 1 - (1 - u) * (1 - u)
	return smooth(u * 1.6), ClimbEnd.PhotoDrop * (1 - fall)
end

-- When the `i`th photo lands, in seconds after the end.
function ClimbEnd.photoAt(how: How, i: number): number
	local tl = timeline(how)
	return tl.PhotosAt + (i - 1) * tl.PhotoEvery + ClimbEnd.PhotoIn * 0.6
end

-- How visible the stats line is `since` seconds into the end.
function ClimbEnd.stats(how: How, since: number): number
	return smooth((since - timeline(how).StatsAt) / ClimbEnd.StatsIn)
end

-- The button `since` seconds into the end: how visible, and how far below its spot (pixels).
function ClimbEnd.again(how: How, since: number): (number, number)
	local u = math.clamp((since - timeline(how).AgainAt) / ClimbEnd.AgainIn, 0, 1)
	local rise = 1 - (1 - u) * (1 - u) * (1 - u)
	return smooth(u), ClimbEnd.AgainRise * (1 - rise)
end

-- How black the screen still is `t` seconds after the lift onto the next climb began.
function ClimbEnd.lift(t: number): number
	return 1 - smooth(t / ClimbEnd.LiftIn)
end

-- The floor's number after the lift: how visible `t` seconds in.
function ClimbEnd.floorShown(t: number): number
	return smooth((t - 0.15) / 0.35) * (1 - smooth((t - ClimbEnd.FloorHold) / 0.6))
end

-- "6:42", or "1:02:09" past an hour.
function ClimbEnd.clock(seconds: number): string
	local s = math.max(math.floor(seconds), 0)
	local h, m = s // 3600, (s // 60) % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s % 60)
	end
	return string.format("%d:%02d", m, s % 60)
end

-- The seconds left to show on "Back in" (whole, never 0 while time's left).
function ClimbEnd.countdown(left: number): number
	return math.max(math.ceil(left - 1e-6), 0)
end

-- Whether the next climb should start now: everyone pressed Again, or the wait after the first
-- press has run out (`startAt`, nil before anyone pressed).
function ClimbEnd.ready(pressed: number, total: number, now: number, startAt: number?): boolean
	if total > 0 and pressed >= total then
		return true
	end
	return startAt ~= nil and now >= startAt
end

-- Where the `i`th friend (from 1) stands in the next climb's lobby, as an offset (studs) from the
-- lobby's arrival spot, in its own frame (it faces -Z, the car behind it at +Z): side by side,
-- the middle first, then a row further out.
function ClimbEnd.spot(i: number): (number, number)
	local k = (i - 1) % ClimbEnd.Row
	local row = (i - 1) // ClimbEnd.Row
	-- 0, 1, -1, 2, -2: the middle, then out either side
	local side = if k == 0 then 0 elseif k % 2 == 1 then (k + 1) // 2 else -(k // 2)
	return side * ClimbEnd.Apart, -row * ClimbEnd.Apart
end

function ClimbEnd.encode(at: number, how: How, floor: number, seconds: number): string
	return string.format("%.3f|%s|%d|%d", at, how, floor, math.max(math.floor(seconds), 0))
end

-- The end's value: when, how, the floor reached, and the climb's seconds; nil if it isn't one.
function ClimbEnd.decode(value: unknown): (number?, How, number, number)
	if type(value) ~= "string" then
		return nil, "Kept", 0, 0
	end
	local at, how, floor, seconds = string.match(value, "^([%d%.%-]+)|(%a+)|(%d+)|(%d+)$")
	local t = if at then tonumber(at) else nil
	if not t or (how ~= "Kept" and how ~= "Top") then
		return nil, "Kept", 0, 0
	end
	return t, how :: How, tonumber(floor) or 0, tonumber(seconds) or 0
end

function ClimbEnd.encodeFate(fate: Fate, floor: number): string
	return string.format("%s|%d", fate, floor)
end

-- A player's fate and the floor; nil if it isn't one.
function ClimbEnd.decodeFate(value: unknown): (Fate?, number)
	if type(value) ~= "string" then
		return nil, 0
	end
	local fate, floor = string.match(value, "^(%a+)|(%d+)$")
	if fate ~= "Out" and fate ~= "Kept" and fate ~= "Left" then
		return nil, 0
	end
	return fate :: Fate, tonumber(floor) or 0
end

-- One friend on a car's results board: who, how it went, the floor it was lost on (or reached), and
-- the cash their coins turned into as it ended (S1-12; nil for none).
export type Result = { userId: number, fate: Fate, floor: number, cash: number? }
-- How a climb went, on the back wall of the car its group came back to (L-08e2).
export type Results = { how: How, floor: number, seconds: number, rows: { Result } }

-- The most friends a board shows: a car's capacity (Boarding.Capacity).
ClimbEnd.BoardMost = 6

-- A car's results board value: "<how>|<floor>|<seconds>|<id>:<fate>:<floor>:<cash>,..." (the rows
-- in the group's order, at most `BoardMost`).
function ClimbEnd.encodeResults(how: How, floor: number, seconds: number, rows: { Result }): string
	local cells: { string } = {}
	for i, row in rows do
		if i > ClimbEnd.BoardMost then
			break
		end
		local cash = math.max(math.floor(row.cash or 0), 0)
		cells[i] = string.format("%d:%s:%d:%d", row.userId, row.fate, row.floor, cash)
	end
	return string.format(
		"%s|%d|%d|%s",
		how,
		floor,
		math.max(math.floor(seconds), 0),
		table.concat(cells, ",")
	)
end

-- A car's results board value read back; nil if it isn't one. A row that doesn't read is skipped.
function ClimbEnd.decodeResults(value: unknown): Results?
	if type(value) ~= "string" then
		return nil
	end
	local how, floor, seconds, cells = string.match(value, "^(%a+)|(%d+)|(%d+)|(.*)$")
	if how ~= "Kept" and how ~= "Top" then
		return nil
	end
	local rows: { Result } = {}
	for cell in string.gmatch(cells :: string, "[^,]+") do
		local id, fate, at, cash = string.match(cell, "^(%d+):(%a+):(%d+):?(%d*)$")
		local userId = if id then tonumber(id) else nil
		if userId and (fate == "Out" or fate == "Kept" or fate == "Left") then
			if #rows < ClimbEnd.BoardMost then
				table.insert(rows, {
					userId = userId,
					fate = fate :: Fate,
					floor = tonumber(at) or 0,
					cash = tonumber(cash) or 0,
				})
			end
		end
	end
	return {
		how = how :: How,
		floor = tonumber(floor) or 0,
		seconds = tonumber(seconds) or 0,
		rows = rows,
	}
end

-- The catch's black, when a wipe ends: the screen the last friend was caught on is black then.
ClimbEnd.AfterCatch = Caught.Dark

return ClimbEnd
