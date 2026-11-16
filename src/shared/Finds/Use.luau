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

	Not here (D-229): the lamps the catalog says work at home (the desk lamp, the night-light, the
	moon, blob and glass lamps, the neon sign) have no press in the building; the Secret lamp is
	found lit and never runs down, so it has none either.
]]

local Use = {}

-- A sound a step plays as it starts (the Catalog's Sound: an id, where in the recording, how
-- long, how loud, its pitch).
export type Sound = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number?,
}

export type Step = {
	motion: string, -- the find's motion (its set's Motions name)
	-- seconds it plays its motion over and over (the flame flickering, the fireflies drifting);
	-- `Use.Forever` until the light runs out. None: it plays once through.
	loop: number?,
	sound: Sound?, -- heard at the find as the step starts
}

export type Row = {
	verb: string, -- the press's one word (the button says it)
	on: { Step }, -- what a press plays, in order; the last step's last frame holds after it
	-- seconds it stays lit in all, the press's motions included, before `out` plays (none: it
	-- never runs down: a glow stick cracked lights the rest of the floor)
	lasts: number?,
	-- running down once `lasts` is spent; after it the find is spent: it takes no more presses
	out: { Step }?,
	-- a switch: a press while it's lit plays this and keeps what's left of `lasts` for the next
	-- press, as Lethal Company's flashlight keeps its battery
	off: Step?,
	-- played before `on` when it's pressed again once `on` has finished (the jack pushed back
	-- into its box and the lid shut, before it's wound again)
	reset: Step?,
	-- the motion whose start every monster on the floor hears, as an air horn's blast (the jack's
	-- Pop): a noisy find draws monsters only when it's used (D-188)
	noise: string?,
}

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

-- The torch's own switch (`Torch.OnSound`, `OffSound`): a lantern, the fairy lights' box and the
-- hard hat's lamp click as a torch does.
local CLICK_ON: Sound = { id = "rbxassetid://9114480271", from = 0.38, length = 0.14, volume = 1.4 }
local CLICK_OFF: Sound = { id = "rbxassetid://9114480269", from = 0.1, length = 0.14, volume = 1.4 }
-- Pro Sound Effects' "Music Box Wind Up 1" (19.6 s): a small music box wound and playing
-- "Frère Jacques"; its first 9 seconds under the jack's Wind (the crank turning). Not yet
-- measured against the motion: F-G1b2 judges where the winding ends and the tune starts.
local MUSIC_BOX: Sound = { id = "rbxassetid://9117044359", from = 0, length = 9, volume = 1.1 }

--[[
	The rows, by catalog key. Each find's one line is the item catalog's (art/finds/WAVES.md):
	how long a light lasts is D-188's "about a minute" unless the catalog says otherwise.
]]
Use.Rows = {
	-- "Light: a small glow for about a minute": the wick catches, flickers, then gutters out.
	TeaLight = {
		verb = "Light",
		on = { { motion = "Light" }, { motion = "Flicker", loop = Use.Forever } },
		lasts = 60,
		out = { { motion = "GoOut" } },
	},
	-- "Light: warm light that runs down slowly": longer than any other found light.
	OilLamp = {
		verb = "Light",
		on = { { motion = "Light" }, { motion = "Burn", loop = Use.Forever } },
		lasts = 150,
		out = { { motion = "RunDown" } },
	},
	-- "Crack: one stick lights a small spot for the rest of the floor".
	GlowSticks = {
		verb = "Crack",
		on = { { motion = "Crack" } },
	},
	-- "Switch on: a dim line of light"; on a battery box that doesn't run down.
	FairyLights = {
		verb = "Switch",
		on = { { motion = "SwitchOn", sound = CLICK_ON } },
		off = { motion = "SwitchOff", sound = CLICK_OFF },
	},
	-- "Switch on: a wide light for 90 seconds"; switched off, it keeps what's left.
	CampLantern = {
		verb = "Switch",
		on = { { motion = "SwitchOn", sound = CLICK_ON } },
		lasts = 90,
		out = { { motion = "RunDown" } },
		off = { motion = "SwitchOff", sound = CLICK_OFF },
	},
	-- "A lamp on your head lights whatever you look at, for a minute"; worn later (D-188's worn
	-- finds), switched on in your hand for now.
	HardHat = {
		verb = "Switch",
		on = { { motion = "SwitchOn", sound = CLICK_ON } },
		lasts = 60,
		out = { { motion = "RunDown" } },
		off = { motion = "SwitchOff", sound = CLICK_OFF },
	},
	-- "Open: fireflies drift out and light the unit for a minute, then they're gone".
	FireflyJar = {
		verb = "Open",
		on = { { motion = "Open" }, { motion = "Drift", loop = Use.Forever } },
		lasts = 60,
		out = { { motion = "Gone" } },
	},
	-- "Spin: spots of light race round the walls"; a battery motor that spins until stopped.
	DiscoBall = {
		verb = "Spin",
		on = { { motion = "Spin" }, { motion = "Spinning", loop = Use.Forever } },
		off = { motion = "SpinDown" },
	},
	-- "Wind: a tune, then a bang as it pops. The bang comes a few seconds after you let go": wind
	-- it, set it down, walk away, and see what comes to look.
	JackInTheBox = {
		verb = "Wind",
		on = { { motion = "Wind", sound = MUSIC_BOX }, { motion = "Pop" } },
		reset = { motion = "Shut" },
		noise = "Pop",
	},
} :: { [string]: Row }

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
		lit = not ended or row.lasts ~= nil or row.off ~= nil or row.reset == nil,
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
	if row.reset and elapsed >= length then
		return "Again", stamp.left
	end
	return nil, 0
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

return Use
