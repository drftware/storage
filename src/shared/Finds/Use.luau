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

-- Studs in front of your middle a find set down to play is stood (the toy car let go): just past
-- your feet, so it rolls away from in front of you, never out from under you.
Use.SetAhead = 1.6

-- The torch's own switch (`Torch.OnSound`, `OffSound`): a lantern, the fairy lights' box and the
-- hard hat's lamp click as a torch does.
local CLICK_ON: Sound = { id = "rbxassetid://9114480271", from = 0.38, length = 0.14, volume = 1.4 }
local CLICK_OFF: Sound = { id = "rbxassetid://9114480269", from = 0.1, length = 0.14, volume = 1.4 }
-- Pro Sound Effects' "Music Box Wind Up 1" (19.6 s): a small music box wound and playing
-- "Frère Jacques"; its first 9 seconds under the jack's Wind (the crank turning). Not yet
-- measured against the motion: F-G1b2 judges where the winding ends and the tune starts.
local MUSIC_BOX: Sound = { id = "rbxassetid://9117044359", from = 0, length = 9, volume = 1.1 }
-- "match strike/ignite" (Creator Store, 2.4 s): a match struck and catching, under the wick's
-- Light (the tea light's whole strike, the oil lamp's strike and its flame taking).
local MATCH_ID = "rbxassetid://71757268954484"
-- The jack's bang as its lid flies open: for now the catalog's "Metal Container 2" tin hit
-- (`CLANG`), lower and louder; a real spring bang is ROADMAP polish (F-G1b2's follow-up).
local POP: Sound =
	{ id = "rbxassetid://9116460746", from = 0, length = 0.42, volume = 1.3, pitch = 0.75 }
-- Pro Sound Effects' "Toy Plastic Feet Wind Up 1" (4.9 s, a key wound then a run): its winding
-- under the monkey's Wind (the key in its back turning).
local WIND: Sound = { id = "rbxassetid://9120219923", from = 0, length = 2.4, volume = 1 }
-- "Crash Cymbal" (Creator Store, one hit of a 17-inch crash, almost no silence before it),
-- pitched up and cut short into a small brass toy cymbal's clang: one each clash.
local CLASH: Sound =
	{ id = "rbxassetid://867306119", from = 0, length = 0.35, volume = 0.9, pitch = 1.9 }
-- "Rolling loop" (Creator Store, small wheels rolling): under the toy car's Push, cut as it
-- slows (a fade is ROADMAP polish).
local ROLL: Sound = { id = "rbxassetid://99838569349900", from = 0, length = 3.4, volume = 0.6 }

-- Seconds a lamp stays lit in all (D-250): about a minute, D-188's default for a found light,
-- so the lantern's 90 seconds is still the long one. Its switch keeps what's left.
Use.LampLasts = 60

-- A lamp's row: switched on by `on`, off by its SwitchOff with a click, and when its light is
-- spent it fades out by the same motion, silent.
local function lamp(on: { Step }): Row
	return {
		verb = "Switch",
		on = on,
		lasts = Use.LampLasts,
		out = { { motion = "SwitchOff" } },
		off = { motion = "SwitchOff", sound = CLICK_OFF },
	}
end

--[[
	The rows, by catalog key. Each find's one line is the item catalog's (art/finds/WAVES.md):
	how long a light lasts is D-188's "about a minute" unless the catalog says otherwise.
]]
Use.Rows = {
	-- "Light: a small glow for about a minute": the wick catches, flickers, then gutters out.
	TeaLight = {
		verb = "Light",
		on = {
			{ motion = "Light", sound = { id = MATCH_ID, from = 0, length = 1.3, volume = 0.9 } },
			{ motion = "Flicker", loop = Use.Forever },
		},
		lasts = 60,
		out = { { motion = "GoOut" } },
	},
	-- "Light: warm light that runs down slowly": longer than any other found light.
	OilLamp = {
		verb = "Light",
		on = {
			{ motion = "Light", sound = { id = MATCH_ID, from = 0, length = 2.4, volume = 0.9 } },
			{ motion = "Burn", loop = Use.Forever },
		},
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
	-- The lamps the catalog once kept for home (D-250, the owner, Nov 16): each switches on
	-- anywhere, stays lit about a minute (D-188's default for a light) and keeps what's left when
	-- switched off, as the lantern does. None has a motion of its own for running down yet, so
	-- each fades out by its switch-off, silent (ROADMAP polish: a flicker as each one dies).
	-- "Switch on: a warm pool of light".
	DeskLamp = lamp({ { motion = "SwitchOn", sound = CLICK_ON } }),
	-- "Switch on: a soft glow by the floor".
	NightLight = lamp({ { motion = "SwitchOn", sound = CLICK_ON } }),
	-- "It glows"; its tap to change the moon's phase stays at home for now.
	MoonLamp = lamp({ { motion = "SwitchOn", sound = CLICK_ON } }),
	-- "Coloured blobs rise and fall": it warms up, then flows for as long as it's lit.
	BlobLamp = lamp({
		{ motion = "SwitchOn", sound = CLICK_ON },
		{ motion = "Flow", loop = Use.Forever },
	}),
	-- "It buzzes and glows pink": it stutters on, then buzzes (a real neon hum is ROADMAP polish).
	NeonSign = lamp({
		{ motion = "SwitchOn", sound = CLICK_ON },
		{ motion = "Buzz", loop = Use.Forever },
	}),
	-- "It throws coloured patterns on your walls".
	StainedGlassLamp = lamp({ { motion = "SwitchOn", sound = CLICK_ON } }),
	-- "Wind: a tune, then a bang as it pops. The bang comes a few seconds after you let go": wind
	-- it, set it down, walk away, and see what comes to look.
	JackInTheBox = {
		verb = "Wind",
		on = { { motion = "Wind", sound = MUSIC_BOX }, { motion = "Pop", sound = POP } },
		reset = { motion = "Shut" },
		noise = "Pop",
	},
	-- "Wind: it bashes its cymbals for 20 seconds, loud", "the strongest lure in the set": wind it,
	-- set it down, and every monster on the floor keeps coming to it until it stalls.
	CymbalMonkey = {
		verb = "Wind",
		on = {
			{ motion = "Wind", sound = WIND },
			{ motion = "Play", hit = { part = "CymbalMonkey_ArmL", sound = CLASH } },
		},
		noise = "Play",
		lure = 2,
		toy = true,
	},
	-- "Push: it rolls off down the hall": let go in front of you, it rolls about seven studs,
	-- wandering, and slows to a stop where it can be picked up again.
	DiecastCar = {
		verb = "Push",
		on = { { motion = "Push", sound = ROLL } },
		toy = true,
		down = true,
	},
} :: { [string]: Row }

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

-- Where a find is in its press as every screen plays it: `elapsed`, held at a stop short.
function Use.played(elapsed: number, stop: number?): number
	return if stop then math.min(elapsed, stop) else elapsed
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
