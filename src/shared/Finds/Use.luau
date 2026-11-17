--!strict
--[[
	Using a find (F-G1b, D-229): its one press while it's in your hand, as the air horn's Blow, and
	what that press plays. The moment: you take something you've never seen, press its one word,
	and it does the thing it is: the lantern clicks on and lights the hall, the tea light catches
	and flickers, the glow stick cracks green, the jar opens and its fireflies drift out, the
	jack-in-the-box cranks out its tune and bangs open, and every monster on the floor hears it.

	A row is a find's press: its word, the motions it plays in order (each find's own, from its set
	in Finds/Sets), how long it stays lit and how it runs down. The server keeps one stamp on the
	find's model (what the last press started, when, and how much light was left), so a lantern
	dropped lit stays lit on the floor, and every screen works out from the stamp where the find
	is in its motions (`frame`). Pure numbers: Lune tests it (tests/finduse.spec); the motions'
	lengths come in as `durations` (a find's set's Duration by motion name).

	Not here: the Secret lamp is found lit and never runs down, so it has no press (D-229). The
	lamps the catalog once kept for home switch on anywhere now (D-250).
]]

local Art = require("./Art")
local Game = require("./Game")
local OneMesh = require("./OneMesh")
local Rows = require("./Rows")

local Use = {}

-- A find's press and what it plays: the types are `Finds/Game`'s, beside the game rows they're
-- written in.
export type Sound = Game.Sound
export type Step = Game.Step
export type Row = Game.Press

-- What the last press started: "On" plays `on`, "Again" plays `reset` then `on`, "Off" plays
-- `off`.
export type State = "On" | "Again" | "Off"
-- The stamp the server keeps on a used find: its state, the server clock when it began (`at`,
-- Workspace:GetServerTimeNow()), and the seconds of light left as it began (`Use.Forever` for a
-- find that never runs down).
export type Stamp = { state: State, at: number, left: number }

-- Where a find is in its motions, `elapsed` seconds after its stamp.
export type Frame = {
	motion: string?, -- the motion it stands in (nil: never pressed, it stands at rest)
	t: number, -- seconds into that motion
	step: number, -- which step: the press's steps counted on into `out`'s (0 before any)
	lit: boolean, -- still going: lit (a light), or still playing (the jack)
	spent: boolean, -- run down for good: it takes no more presses
}

-- A loop that goes on until the light runs out (or for good).
Use.Forever = math.huge

-- The least seconds between one player's presses on the server, a little under a click's
-- repeat so a quick double press of a switch (on, off) still lands. What it does to the player:
-- mashing the button can't spam a monster-drawing bang or flicker a light for everyone.
Use.Gap = 0.35

-- How far a find's sounds carry, in studs (the music box down a hall, a click across a unit).
-- What it does to the player: a friend round the corner hears the jack winding before its bang.
Use.Reach = 60

-- The most pressed finds whose real lights shine at once on a screen, the nearest to its camera
-- (your own in hand first); the rest still glow. What it does: a hall of lit finds stays smooth
-- on a low-end phone (the GDD's cap on real lights).
Use.LightsShown = 2

-- Seconds your own press shows before the server's word must land: a click with no wait, and a
-- refused press (another's bang, a lag spike) falls back within a breath.
Use.Predict = 1.5

-- How far a lure is heard along the halls, in studs: as far as the air horn's blast (`Horn`), the
-- loudest thing on a floor. What it does to the player: a cymbal monkey left in a unit draws
-- every monster two halls round to it, again and again, while you work somewhere else.
Use.LureReach = 130

-- The least seconds between monsters hearing one find again (F-G1e1): a duck squeezed as fast as
-- you can press squeaks every press, but monsters hear it once in this at most, and a lure's
-- beat is never quicker. What it does to the player: mashing a noisy toy draws monsters no more
-- than squeezing it now and then; and on a low-end phone's server, the halls are searched for a
-- noise every second or two, not on every press.
Use.HearGap = 1.5

-- The most lures heard at once on a server (the cymbal monkey's cymbals, later the wind-ups that
-- travel): a new one past it takes the place of the oldest, which plays on unheard (monsters go
-- to the newest noise anyway). What it does to the player: a pile of wound monkeys still pulls
-- every monster to the last one wound, and never sets a crowd of them flipping between noises.
Use.LuresAtOnce = 3

-- Studs in front of your middle a find set down to play is stood (the toy car let go): just past
-- your feet, so it rolls away from in front of you, never out from under you.
Use.SetAhead = 1.6

--[[
	The presses, by catalog key: each find's press is in its game row, in its art spec
	(art/finds/<set>/spec.py, generated into `Finds/Rows`; art/finds/PIPELINE.md). Only finds
	ticked built in art/finds/WAVES.md (`judged`) are here. Each find's one line is the item
	catalog's: how long a light lasts is D-188's "about a minute" unless the catalog says otherwise.
]]
Use.Rows = {} :: { [string]: Row }
for _, row in Rows do
	if row.judged and row.press then
		Use.Rows[row.key] = row.press
	end
end
-- the one-mesh finds' presses (the boombox's Play, the teddy's Hug), written by hand as their
-- catalog rows are (F-G1e5a)
for key, entry in OneMesh do
	Use.Rows[key] = entry.press
end

-- Whether `row` is a toy: pressed again once its motions end (`toy`, or the jack's `reset`).
function Use.toy(row: Row): boolean
	return row.toy == true or row.reset ~= nil
end

-- The steps a state plays, in order.
function Use.chain(row: Row, state: State): { Step }
	if state == "Off" then
		return if row.off then { row.off } else {}
	end
	if state == "Again" and row.reset then
		local steps = { row.reset }
		for _, s in row.on do
			table.insert(steps, s)
		end
		return steps
	end
	return row.on
end

-- How long a step plays: its loop's seconds, or its motion once through.
function Use.length(step: Step, durations: { [string]: number }): number
	return step.loop or durations[step.motion] or 0
end

-- `steps` at `e` seconds in: the step, its number and the seconds into its motion; past the end,
-- the last step held at its end (nil, 0 for no steps).
local function walk(
	steps: { Step },
	e: number,
	durations: { [string]: number }
): (Step?, number, number, boolean)
	for i, step in steps do
		local length = Use.length(step, durations)
		if e < length then
			local d = durations[step.motion] or 0
			local t = if step.loop and d > 0 then e % d else e
			return step, i, t, false
		end
		e -= length
	end
	local last = steps[#steps]
	if not last then
		return nil, 0, 0, true
	end
	return last, #steps, durations[last.motion] or 0, true
end

-- Where a find stamped `stamp` is, `elapsed` seconds after it (nil stamp: never pressed).
function Use.frame(row: Row, stamp: Stamp?, elapsed: number, durations: { [string]: number }): Frame
	if not stamp then
		return { motion = nil, t = 0, step = 0, lit = false, spent = false }
	end
	local e = math.max(elapsed, 0)
	local steps = Use.chain(row, stamp.state)
	if stamp.state == "Off" then
		local step, i, t = walk(steps, e, durations)
		return {
			motion = if step then step.motion else nil,
			t = t,
			step = i,
			lit = false,
			spent = false,
		}
	end
	local out = row.out
	if out and e >= stamp.left then
		local step, j, t, ended = walk(out, e - stamp.left, durations)
		return {
			motion = if step then step.motion else nil,
			t = t,
			step = #steps + j,
			lit = false,
			spent = ended,
		}
	end
	local step, i, t, ended = walk(steps, e, durations)
	return {
		motion = if step then step.motion else nil,
		t = t,
		step = i,
		-- a light stays lit after its press's motions; a toy's press is over once they end
		lit = not ended or row.lasts ~= nil or row.off ~= nil or not Use.toy(row),
		spent = false,
	}
end

--[[
	What a press does to a find stamped `stamp`, `elapsed` seconds after it: the new state and the
	light it starts with (the server stamps it with its clock), or nil if the press does nothing
	now (still burning, running down, spent, or the jack still mid-tune). Your screen asks the
	same, to show the button only when a press would do something.
]]
function Use.press(
	row: Row,
	stamp: Stamp?,
	elapsed: number,
	durations: { [string]: number }
): (State?, number)
	if not stamp then
		return "On", row.lasts or Use.Forever
	end
	local now = Use.frame(row, stamp, elapsed, durations)
	if now.spent then
		return nil, 0
	end
	if row.off then
		if stamp.state == "Off" then
			return if stamp.left > 0 then "On" else nil, stamp.left
		end
		local left = stamp.left - math.max(elapsed, 0)
		-- running down already: too late to save it
		if left <= 0 then
			return nil, 0
		end
		return "Off", left
	end
	-- not a switch: once its press's motions are over, a toy is pressed again; a light isn't
	local steps = Use.chain(row, stamp.state)
	local length = 0
	for _, step in steps do
		length += Use.length(step, durations)
	end
	if Use.toy(row) and elapsed >= length then
		return "Again", stamp.left
	end
	return nil, 0
end

-- A step's sound at least this long (seconds, as heard) is a tune, not a click: a find come into
-- view part way through it (walked up to, dropped from a hand, which hands every screen a new
-- copy) joins it where it is now, so a boombox you walk toward is already playing.
Use.JoinLong = 2
-- Less than this left of a tune (seconds) isn't worth starting: it would only blip.
Use.JoinLeft = 0.5

-- Seconds after a press in state `state` that its step `n` starts (`Frame.step`); nil for a
-- step of `out` or none.
function Use.started(row: Row, state: State, n: number, durations: { [string]: number }): number?
	local steps = Use.chain(row, state)
	if n < 1 or n > #steps then
		return nil
	end
	local at = 0
	for i = 1, n - 1 do
		at += Use.length(steps[i], durations)
	end
	return at
end

-- `sound` joined `into` seconds after its step started: the rest of a tune from where it is now,
-- or nil for a click (shorter than `JoinLong`) or a tune nearly over (`JoinLeft`).
function Use.join(sound: Sound, into: number): Sound?
	local pitch = sound.pitch or 1
	local gone = math.max(into, 0) * pitch -- seconds of the recording already played
	if sound.length / pitch < Use.JoinLong or (sound.length - gone) / pitch < Use.JoinLeft then
		return nil
	end
	return {
		id = sound.id,
		from = sound.from + gone,
		length = sound.length - gone,
		volume = sound.volume,
		pitch = sound.pitch,
	}
end

-- The step numbered `n` in a frame (`Frame.step`): the press's steps, then `out`'s; nil for 0.
function Use.stepAt(row: Row, state: State, n: number): Step?
	local steps = Use.chain(row, state)
	if n <= #steps then
		return steps[n]
	end
	local out = row.out
	return if out and state ~= "Off" then out[n - #steps] else nil
end

--[[
	The stamp on a used find's model, as attributes (the server writes them, every screen reads
	them, and they ride the model from hand to floor): the state, the server clock it began, and
	the light left (-1 for `Use.Forever`, which an attribute can't be trusted to carry). The
	catalog key rides along so a screen knows the find whatever the model is named (a held one is
	`HeldTool`), and the tag marks the models to watch.
]]
Use.StateAttribute = "UseState"
Use.AtAttribute = "UseAt"
Use.LeftAttribute = "UseLeft"
Use.KeyAttribute = "UseKey"
Use.Tag = "FindUsed"
-- A find set down to play (`down`): where its frame stood as it was set down (a CFrame), so
-- every screen plays its travel from there to where the server laid it; and, if it rolled into
-- something, the seconds into its press it stopped short (it holds that frame from then on).
Use.FromAttribute = "UseFrom"
Use.StopAttribute = "UseStop"

-- The channels of its root a find that `walks` holds once a wall stops it short (where it is
-- over the floor and which way it faces): it chatters, clanks or hops on where it stands.
Use.Holds = { "x", "z", "yaw" }

-- Where a find is in its press as every screen plays it, `elapsed` after its stamp, then how far
-- its travel over the floor has gone (the seconds of its press whose travel it has reached). At a
-- stop short the toy car holds the frame it stopped in; a wind-up that `walks` plays on, its
-- travel held at the stop (`Use.Holds`).
function Use.played(row: Row, elapsed: number, stop: number?): (number, number)
	local travel = if stop then math.min(elapsed, stop) else elapsed
	return if row.walks then elapsed else travel, travel
end

-- Of a hit's furthest swing, how big a peak must be to beat: the teeth's last weak snaps as they
-- run down still clack, a wobble as a part settles doesn't.
Use.BeatShare = 0.15

--[[
	The beats of `motion` that sound a step's `hit` (seconds into it): each key where `part`'s
	`channel` (none: its turn) peaks on the side it swings furthest, and at least `Use.BeatShare`
	of that far (the cymbal monkey's every clash as its arms swing in; the teeth's every snap as
	the body jolts forward, slowing as the spring runs down). A peak held over keys beats once; a
	part's last key is where it comes to rest, never a beat (the spinner's arrow settling into the
	notch it has just ticked into, F-G1e3b).
]]
function Use.beats(motion: Art.Motion?, part: string, channel: string?): { number }
	local out: { number } = {}
	if not motion then
		return out
	end
	local ch = channel or "turn"
	for _, track in motion.Tracks do
		if track.Part == part and track.Channel == ch then
			local keys = track.Keys
			local far = 0
			for _, k in keys do
				if math.abs(k[2]) > math.abs(far) then
					far = k[2]
				end
			end
			if far == 0 then
				continue
			end
			local side = math.sign(far)
			for i, k in keys do
				local v = k[2] * side -- how far out on the far side
				local before = if i > 1 then keys[i - 1][2] * side else -math.huge
				local after = if i < #keys then keys[i + 1][2] * side else v
				if v >= Use.BeatShare * math.abs(far) and v >= before and v > after then
					table.insert(out, k[1])
				end
			end
		end
	end
	return out
end

-- A sound at a moment into a step's motion (seconds in): a beat of its `hit`, or one of its `cues`.
export type Cue = { t: number, sound: Sound }

--[[
	Every sound a step plays after it starts, in time order (`step.sound` plays as it starts): its
	`hit` on each beat of `motion` (`Use.beats`) and its `cues` (the kazoo's hum once it's at your
	lips; the spinner's ticks into each notch) and, for an arrow that `lands`, the call of the
	`stop` it lands on as it stops.
]]
function Use.timeline(step: Step, motion: Art.Motion?, stop: number?): { Cue }
	local out: { Cue } = {}
	local hit = step.hit
	if hit then
		for _, t in Use.beats(motion, hit.part, hit.channel) do
			table.insert(out, { t = t, sound = hit.sound })
		end
	end
	local cues = step.cues
	if cues then
		for _, c in cues do
			table.insert(out, { t = c.at, sound = c.sound })
		end
	end
	-- the animal the arrow lands on, as it stops: known once the stop is (`Use.bend`)
	local lands = step.lands
	local call = lands and stop and lands.calls[stop + 1]
	if lands and call then
		table.insert(out, { t = lands.at, sound = call })
	end
	table.sort(out, function(a: Cue, b: Cue)
		return a.t < b.t
	end)
	return out
end

--[[
	An arrow that lands on a new stop each press (the farm spinner, F-G1e3d), as a prize wheel
	does: the server picks the stop beside its stamp and every screen bends the art's one spin to
	end there, so you pull again and again to see which animal it is.
]]
export type Lands = { part: string, every: number, at: number, calls: { Sound } }

-- The stop an arrow that lands rests on (0, the first call, is where it's made pointing), and the
-- one it set off from on its last press: the server's, written before its stamp's clock.
Use.LandAttribute = "UseLand"
Use.LandFromAttribute = "UseLandFrom"

-- The step of `row` whose arrow lands, if any.
function Use.lands(row: Row): Step?
	for _, s in row.on do
		if s.lands then
			return s
		end
	end
	return nil
end

local function arrow(motion: Art.Motion, part: string): Art.Track?
	for _, track in motion.Tracks do
		if track.Part == part and track.Channel == "turn" then
			return track
		end
	end
	return nil
end

-- How many stops the art's own spin turns its arrow (the spinner's 1305 degrees: 29 eighths).
function Use.spins(lands: Lands, motion: Art.Motion?): number
	local track = if motion then arrow(motion, lands.part) else nil
	if not track or #track.Keys == 0 then
		return 0
	end
	local keys = track.Keys
	return math.round((keys[#keys][2] - keys[1][2]) / lands.every)
end

-- The stop it lands on next from the one it's `on`: any of the others, never that one again, so
-- every pull shows a new animal (`roll` from 0 up to 1, the server's random number).
function Use.pick(stops: number, on: number, roll: number): number
	local k = math.clamp(math.floor(roll * (stops - 1)), 0, stops - 2)
	return (on + 1 + k) % stops
end

-- A stop as its attribute carries it: a whole number below `stops`, else the first (never pressed).
function Use.stop(v: unknown, stops: number): number
	if type(v) == "number" and v == math.floor(v) and v >= 0 and v < stops then
		return v
	end
	return 0
end

--[[
	`motion` bent so its arrow sets off from stop `from` and lands on stop `to`: every key of the
	arrow's turn on by `from` stops, and the keys from its first move on by the whole stops more
	that bring its end round to `to` (none to all but one more: it spins a little further, never
	back). Its hops into each notch stay where the art has them, so the ticks do too. A new motion
	sharing the art's other tracks; the art is untouched. Once a press, not each frame.
]]
function Use.bend(motion: Art.Motion, lands: Lands, from: number, to: number): Art.Motion
	local track = arrow(motion, lands.part)
	if not track or #track.Keys == 0 then
		return motion
	end
	local stops = #lands.calls
	local more = (to - from - Use.spins(lands, motion)) % stops
	local keys: { Art.Key } = {}
	local first = track.Keys[1][2]
	local moved = false
	for i, k in track.Keys do
		moved = moved or k[2] ~= first
		local by = (from + if moved then more else 0) * lands.every
		keys[i] = { k[1], k[2] + by, k[3], k[4] }
	end
	local tracks: { Art.Track } = {}
	for i, t in motion.Tracks do
		tracks[i] = if t == track then { Part = t.Part, Channel = t.Channel, Keys = keys } else t
	end
	return { Duration = motion.Duration, Tracks = tracks }
end

-- `left` as the attribute carries it.
function Use.encode(left: number): number
	return if left == Use.Forever then -1 else left
end

-- A stamp from the three attributes' values, nil unless they make one.
function Use.read(state: unknown, at: unknown, left: unknown): Stamp?
	if state ~= "On" and state ~= "Again" and state ~= "Off" then
		return nil
	end
	if type(at) ~= "number" or type(left) ~= "number" or at ~= at or left ~= left then
		return nil
	end
	return { state = state :: State, at = at, left = if left < 0 then Use.Forever else left }
end

-- Seconds after a press in state `state` that its lure stops being heard (its `noise` step's
-- end), nil if it's no lure.
function Use.lureUntil(row: Row, state: State, durations: { [string]: number }): number?
	local start = Use.noiseAt(row, state, durations)
	if not (start and row.lure) then
		return nil
	end
	for _, step in Use.chain(row, state) do
		if step.motion == row.noise then
			return start + Use.length(step, durations)
		end
	end
	return nil
end

-- Seconds after a press in state `state` that its noise starts (the jack's bang), nil if it
-- makes none.
function Use.noiseAt(row: Row, state: State, durations: { [string]: number }): number?
	local noise = row.noise
	if not noise then
		return nil
	end
	local at = 0
	for _, step in Use.chain(row, state) do
		if step.motion == noise then
			return at
		end
		at += Use.length(step, durations)
	end
	return nil
end

-- How far along the halls monsters hear `row`'s noise (studs): its loudness, the row's `heard`
-- (the duck's squeak down the hall), or as far as the air horn (the monkey's cymbals, the jack's
-- bang).
function Use.loudness(row: Row): number
	return row.heard or Use.LureReach
end

-- Seconds between a lure's hearings while it plays: its row's `lure`, never quicker than
-- `Use.HearGap`.
function Use.lureBeat(row: Row): number
	return math.max(row.lure or Use.HearGap, Use.HearGap)
end

--[[
	The noises monsters hear on a server (F-G1e1): the finds whose lures sound now, oldest first,
	and when each find was last heard. One per server; `K` is a find's model there (plain values
	in the specs). Every hearing asks `Use.hear` first, and a lure starts with `Use.startLure`.
]]
export type Din<K> = { lures: { K }, last: { [K]: number } }

function Use.din<K>(): Din<K>
	return { lures = {}, last = {} }
end

-- Whether `id` is a lure monsters still hear.
function Use.luring<K>(din: Din<K>, id: K): boolean
	return table.find(din.lures, id) ~= nil
end

-- `id`'s lure stops being heard (its play ended, it was taken away).
function Use.stopLure<K>(din: Din<K>, id: K)
	local i = table.find(din.lures, id)
	if i then
		table.remove(din.lures, i)
	end
end

-- `id`'s lure starts (wound again: it becomes the newest, counted once). Past
-- `Use.LuresAtOnce`, the oldest stops being heard: that one is returned.
function Use.startLure<K>(din: Din<K>, id: K): K?
	Use.stopLure(din, id)
	local dropped: K? = nil
	if #din.lures >= Use.LuresAtOnce then
		dropped = table.remove(din.lures, 1)
	end
	table.insert(din.lures, id)
	return dropped
end

-- Whether monsters hear `id`'s noise at `now` (seconds on one clock), marking it heard: not if it
-- was heard less than `Use.HearGap` before. Finds heard longer ago than that are let go.
function Use.hear<K>(din: Din<K>, id: K, now: number): boolean
	for k, at in din.last do
		if now - at >= Use.HearGap then
			din.last[k] = nil
		end
	end
	if din.last[id] ~= nil then
		return false
	end
	din.last[id] = now
	return true
end

-- A found light lying lit holds a Mannequin this share of its light's range from it (F-G1b3b):
-- past that the glow on its body is too faint to read as lit, and it would seem to stop in the
-- dark. A camp lantern's 12 holds it about 10 studs off, a tea light's 9 about 7.
Use.LightShare = 0.8

--[[
	Found lights hold a Mannequin (F-G1b3b, D-188): one lying lit on the floor is a light it stops
	in, as it stops under a hall light or in a torch beam. The server clock until which a find
	stamped `stamp` is lit: from its press for as long as its light lasts (`left`), for good if it
	never runs down (math.huge); nil if it isn't lit (never pressed, switched off) or isn't a light
	(a toy plays, it doesn't glow).
]]
function Use.litUntil(row: Row, stamp: Stamp?): number?
	if not stamp or stamp.state == "Off" or Use.toy(row) then
		return nil
	end
	return stamp.at + stamp.left
end

-- How far a found light lying lit holds a Mannequin, along the floor (studs): its widest point
-- light's range (a spot's only if it has no point light: a beam that points away is no pool
-- round it), times `LightShare`; 0 for a find with no light.
function Use.reach(find: Art.Find?): number
	if not find then
		return 0
	end
	local point, other = 0, 0
	for _, light in find.Lights do
		if light.Kind == "Point" then
			point = math.max(point, light.Range)
		else
			other = math.max(other, light.Range)
		end
	end
	return (if point > 0 then point else other) * Use.LightShare
end

return Use
