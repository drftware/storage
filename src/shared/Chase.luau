--!strict
--[[
	Chase: what the hunted player hears while a keeper hunts them (L-06b4b1), as numbers and the
	one pure rule their screen follows. Pure, so Lune tests it (tests/chase.spec.luau).

	The moment: a keeper turns its head your way, and a sting cuts in the instant it sees you, as
	Granny's chase music does; a low bed runs under the chase and fades as it loses you. Only the
	hunted player hears it: friends hear the keeper, not your music.

	The server tells the hunted player's screen how many keepers hunt them, once each time that
	changes (Remotes.Hunted, from Keepers). A rise is a sighting, and it stings only if it's a fresh
	one: not a glance back within `Regain` of a keeper losing you, and not within `StingGap` of the
	last sting. While any keeper hunts you the bed fades up over `BedIn`; once none does, it fades
	out over `BedOut`. Caught, the bed and the sting cut at once and nothing plays until the
	blackout is over (`Hush`); the next sighting after that is a fresh one.
]]
local Caught = require("./Caught")

local Chase = {}

-- Where the server tells a player's screen how many keepers hunt them: ReplicatedStorage.Remotes.
-- Hunted, fired to that player alone with one whole number, only when it changes. Server to
-- client only.
Chase.RemoteFolder = "Remotes"
Chase.Remote = "Hunted"
-- The most keepers the screen believes hunt you at once; anything else it's told is ignored.
Chase.MostHunters = 16

-- A recording and how it plays: its id, its loudness (Sound.Volume) and, for the bed, the
-- stretch it loops (seconds into the recording).
export type Clip = { id: string, volume: number, from: number, to: number }

-- The sting: APM's "Rising Fear Hit 1", 7.55 s. It hits at once (full by 0.1 s), stays loud for
-- 0.8 s and rings down to nothing by 7 s; a low boom with a bright edge (a third of it 500 Hz to
-- 2 kHz), so it cuts through a phone's speaker. Near the loudest thing in the game: it should
-- make you jump, once.
Chase.Sting = { id = "rbxassetid://1841353894", volume = 0.8, from = 0, to = 7.55 } :: Clip
-- The bed: APM's "Tension Repeat Drones 39", 128.6 s, a steady drone that swells every five
-- seconds or so. Of the beds measured it's the one with most of its sound (82%) between 150 and
-- 500 Hz, where a phone's speaker still plays it; the others sat under 150 Hz and went quiet on a
-- phone. Looped over its steady stretch (it fades out from about 120 s). Under the sting and the
-- keeper's own sounds, never over them.
Chase.Bed = { id = "rbxassetid://1843739491", volume = 0.45, from = 0, to = 118 } :: Clip

-- Seconds the bed takes to rise as a keeper sees you: it swells under the sting's hit, so the
-- chase has its music by the time the hit rings down.
Chase.BedIn = 0.8
-- Seconds the bed takes to fade once no keeper hunts you: the chase hangs on a breath after it
-- loses you (it's rushing to where it saw you), then lets you go.
Chase.BedOut = 4
-- Seconds after a keeper loses you in which its seeing you again is a glance back: the bed comes
-- back up with no second sting, so ducking out of sight for a moment doesn't sting every time.
Chase.Regain = 4
-- Seconds after a sting before another can play: a second keeper that sees you just after the
-- first only adds to the chase, it doesn't hit you again.
Chase.StingGap = 8
-- Seconds of silence after you're caught: the whole blackout (`Caught.Out`). No bed and no sting
-- in the black.
Chase.Hush = Caught.Out

-- What one player's screen keeps of the chase. All times are the screen's clock (seconds).
export type Music = {
	hunters: number, -- keepers hunting you now, as last told
	fellAt: number, -- when a keeper last lost you (the number fell), -inf if never
	stungAt: number, -- when the last sting played, -inf if never
	hushUntil: number, -- nothing plays before this (a catch's blackout), -inf if none
	level: number, -- how far up the bed is, 0 (silent) to 1 (full), as of `at`
	at: number, -- when `level` was last brought up to date
}

function Chase.new(): Music
	return {
		hunters = 0,
		fellAt = -math.huge,
		stungAt = -math.huge,
		hushUntil = -math.huge,
		level = 0,
		at = -math.huge,
	}
end

-- Brings the bed's level up to `now`: rising while a keeper hunts you (once any hush is over),
-- falling while none does.
local function settle(m: Music, now: number)
	local from = m.at
	if not (now > from) then
		return
	end
	m.at = now
	if m.hunters > 0 then
		local start = math.max(from, m.hushUntil)
		if now > start then
			m.level = math.min(m.level + (now - start) / Chase.BedIn, 1)
		end
	elseif from > -math.huge then
		m.level = math.max(m.level - (now - from) / Chase.BedOut, 0)
	end
end

--- The server says `hunters` keepers hunt you as of `now`. Returns whether the sting plays now:
--- only on a rise (a keeper has seen you) that's a fresh sighting, outside any hush, at least
--- `StingGap` after the last sting and `Regain` after a keeper last lost you.
function Chase.hunted(m: Music, hunters: number, now: number): boolean
	settle(m, now)
	local was = m.hunters
	if hunters == was then
		return false
	end
	m.hunters = hunters
	if hunters < was then
		if now >= m.hushUntil then -- the blackout's own loss isn't a keeper losing you
			m.fellAt = now
		end
		return false
	end
	if now < m.hushUntil or now - m.fellAt < Chase.Regain or now - m.stungAt < Chase.StingGap then
		return false
	end
	m.stungAt = now
	return true
end

--- You were caught at `now`: the bed drops to nothing at once and stays there for `Hush`, and the
--- next sighting after it is a fresh one (it stings).
function Chase.caught(m: Music, now: number)
	settle(m, now)
	m.level = 0
	m.hushUntil = now + Chase.Hush
	m.fellAt = -math.huge
	m.stungAt = -math.huge
end

--- How loud the bed is at `now`, 0 to 1 (times `Bed.volume`). The level moves evenly; its square
--- is what's heard, so a fade sounds like a sound dying away rather than cut off at the end.
function Chase.bed(m: Music, now: number): number
	settle(m, now)
	return m.level * m.level
end

--- Whether there's nothing to play: no keeper hunts you and the bed has faded out (as of the last
--- `bed`, `hunted` or `caught`). The screen stops the bed and stops stepping then.
function Chase.quiet(m: Music): boolean
	return m.hunters == 0 and m.level == 0
end

return Chase
