--!strict
--[[
	ShutTap: the tap when you pull a door down on a sleeping monster (S2-05, the GDD's "The tap").
	As Dead by Daylight's skill checks: a bar comes up by itself, unasked, a marker sweeps across it
	once, and one tap while it's in the bar's zone is a hit. Here a hit settles the door quietly and
	the monster sleeps on; a miss, or no tap at all, bangs the door, and the monster wakes shut in
	and pounds on it.

	Pure numbers and rules: when a pull earns the tap, where the marker is, where the zone falls,
	hit or miss from the tap's moment, and when the server believes a tap came. The door's own
	motions (its ease down to hang a foot up, then the soft settle or the drop) are `Motion`'s
	"Ease", "Settle" and "Drop". Every time here is seconds after the pull.
]]

export type Result = "Hit" | "Miss"

local ShutTap = {}

-- The tap's one remote, ReplicatedStorage.Remotes.ShutTap, both ways. The server to the puller
-- alone: "Open" (the unit, the pull's moment on the server's clock, the zone's left edge) as the
-- bar comes up, then "Done" (the unit, true on a hit, false on a miss) or "Gone" (the unit: the
-- door went another way first). The puller's screen to the server: the unit and the moment of
-- the tap on the server's clock (`Workspace:GetServerTimeNow`).
ShutTap.RemoteFolder = "Remotes"
ShutTap.Remote = "ShutTap"

-- Seconds from the pull to the marker setting off. The bar is up and the door is still coming
-- down most of the way: the beat to get your thumb over the screen, as Dead by Daylight's warning
-- tick comes just before its needle moves.
ShutTap.Lead = 0.45
-- Seconds the marker takes from one end of the bar to the other, once, never back. Dead by
-- Daylight's needle goes round in about 1.1 s: long enough to watch it come, short enough that
-- the door hanging over the monster is a held breath, not a wait.
ShutTap.Sweep = 1.1
-- The whole window from the pull to the marker's end: no tap by then is a miss.
ShutTap.Window = ShutTap.Lead + ShutTap.Sweep

-- The zone's width as a share of the bar: 0.15 is about a sixth of a second of the sweep, a fair
-- tap on a phone that still needs watching. Wider makes the door free; narrower, a coin toss.
ShutTap.ZoneWidth = 0.15
-- Where the zone's left edge may fall, as shares of the bar: never before 0.4, so you always see
-- the marker set off before it's due; never after 0.8, so the zone always ends short of the bar's
-- end. Anywhere between, so it can't be learned by count.
ShutTap.ZoneEarliest = 0.4
ShutTap.ZoneLatest = 0.8

-- How long ago a tap may say it came when the server gets it (s): a phone's trip to the server
-- and a frame. A tap claiming longer ago counts as that long ago. The server also waits this long
-- past the window for a tap still on its way before it calls it a miss, so the door hangs a beat
-- at the end of the bar before it bangs.
ShutTap.MaxLag = 0.25
-- How far ahead of the server's clock a tap may say it came (s): the two clocks agree only so well.
ShutTap.Ahead = 0.05
-- The door must be at least this far up (studs) for pulling it down to earn the tap: from all the
-- way up or most of it. A peek's short drop is quiet already (Motion's "Close" from 1.15).
ShutTap.MinRise = 3
-- Taps from one player closer together than this (s) are thrown away: one tap a window, and no
-- flood of them from a broken or cheating screen.
ShutTap.Gap = 0.2

--- Whether pulling a door down from `rise` studs up earns the tap: a monster stands in its unit
--- (`asleep` nil when none does) that is asleep, or awake but hasn't seen the puller (`sawPuller`:
--- it hunts them).
function ShutTap.earns(asleep: boolean?, sawPuller: boolean, rise: number): boolean
	if asleep == nil or rise < ShutTap.MinRise then
		return false
	end
	return asleep or not sawPuller
end

--- Where the marker is along the bar (0 to 1) `elapsed` seconds after the pull: still through the
--- lead, then at an even speed to the end, where it stays.
function ShutTap.marker(elapsed: number): number
	local t = (elapsed - ShutTap.Lead) / ShutTap.Sweep
	return if t < 0 then 0 elseif t > 1 then 1 else t
end

--- The zone's left edge along the bar for a roll from 0 to 1 (a fresh one each pull).
function ShutTap.zone(roll: number): number
	local r = if roll < 0 then 0 elseif roll > 1 then 1 else roll
	return ShutTap.ZoneEarliest + r * (ShutTap.ZoneLatest - ShutTap.ZoneEarliest)
end

--- Hit or miss for a tap `tapped` seconds after the pull (nil: no tap) against the zone starting at
--- `zone`: a hit only while the marker is moving and inside it.
function ShutTap.judge(zone: number, tapped: number?): Result
	if tapped == nil or tapped < ShutTap.Lead or tapped > ShutTap.Window then
		return "Miss"
	end
	local at = ShutTap.marker(tapped)
	return if at >= zone and at <= zone + ShutTap.ZoneWidth then "Hit" else "Miss"
end

--- When the server believes a tap came, on its clock: what the screen says (`claimed`), held to
--- no earlier than the pull (`start`) or `MaxLag` before `now`, and no later than `Ahead` past it.
--- Nil for a claim that isn't a finite number.
function ShutTap.heard(start: number, now: number, claimed: number): number?
	if claimed ~= claimed or claimed == math.huge or claimed == -math.huge then
		return nil
	end
	local earliest = math.max(start, now - ShutTap.MaxLag)
	local latest = now + ShutTap.Ahead
	return if claimed < earliest then earliest elseif claimed > latest then latest else claimed
end

--- Whether a window that began at `start` has run out with no tap by `now`: the bar's end, plus a
--- late tap's time to arrive.
function ShutTap.due(start: number, now: number): boolean
	return now - start >= ShutTap.Window + ShutTap.MaxLag - 1e-9
end

return ShutTap
