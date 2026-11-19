--!strict
--[[
	A kit find's game row (F-G1f, D-265): what its art spec says the game deals and plays. Each set's
	GAME rows (art/finds/<set>/spec.py) are written into `Finds/Rows` by art/finds/rows.py, a
	generated module; `Tools.Catalog` makes each judged one a catalog row and `Finds/Use` plays its
	press. Types only.
]]

local Grades = require("../Grades")

-- A tune that slows as a music box's spring runs down, its pitch held as a real box's comb holds
-- it (F-G1e5f): full speed until `at` seconds into its step, then its speed falls as
-- (1 - s) ^ `fade` across to nothing at `stop` (`Use.pace`, `Use.through`).
export type Slows = { at: number, stop: number, fade: number }

-- A sound a step plays as it starts (the Catalog's Sound: an id, where in the recording, how
-- long, how loud, its pitch), and how it slows if it does.
export type Sound = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number?,
	slows: Slows?,
}

export type Step = {
	motion: string, -- the find's motion (its set's Motions name)
	-- seconds it plays its motion over and over (the flame flickering, the fireflies drifting);
	-- `Use.Forever` until the light runs out. None: it plays once through.
	loop: number?,
	sound: Sound?, -- heard at the find as the step starts
	-- a sound at every beat of the step's motion: each key where `part`'s `channel` (none: its
	-- turn) peaks on the side it reaches furthest (the cymbal monkey's every clash, as its arms
	-- swing in; the chattering teeth's every snap, as the body jolts forward), `Use.beats`
	hit: { part: string, channel: string?, sound: Sound }?,
	-- sounds at moments into the step's motion (seconds in), for a sound that comes after the
	-- press starts: the kazoo's hum once it's at your lips, the spinner's animal as its arrow
	-- stops (`Use.timeline`)
	cues: { { at: number, sound: Sound } }?,
	-- an arrow that lands on a new stop each press, the server's pick (the farm spinner, F-G1e3d):
	-- `part` turns `every` degrees a stop, and `calls` are each stop's sound in the face's order
	-- from the one it's made pointing at, the landed one's played `at` seconds in as it stops
	-- (`Use.bend`, `Use.timeline`)
	lands: { part: string, every: number, at: number, calls: { Sound } }?,
}

export type Press = {
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
	-- a light with more to it: each later press, once the last one's motions are over, plays the
	-- next of these, and it stays lit on (the glow sticks' second and third stick, three to a
	-- bundle, F-G1e5b: each a crack, a shake and a glow, as DOORS' lighter is used again)
	more: { Step }?,
	-- played before `on` when it's pressed again once `on` has finished (the jack pushed back
	-- into its box and the lid shut, before it's wound again)
	reset: Step?,
	-- the motion whose start every monster on the floor hears, as an air horn's blast (the jack's
	-- Pop): a noisy find draws monsters only when it's used (D-188)
	noise: string?,
	-- how far along the halls monsters hear its noise, in studs: its loudness (F-G1e1). The duck's
	-- squeak carries down the hall you're in; none: as far as the air horn (`Use.LureReach`), the
	-- cymbal monkey's and the jack's
	heard: number?,
	-- seconds between hearings for as long as the `noise` step plays: monsters keep coming to the
	-- find all through it, not just at its start (the cymbal monkey, Call of Duty Zombies' Monkey
	-- Bomb)
	lure: number?,
	-- a toy: its press is over once its motions end, and it takes another (the monkey wound again,
	-- the toy car pushed again). The jack is one by its `reset`.
	toy: boolean?,
	-- set down to play: the press takes it out of your hand and stands it on the floor in front of
	-- you, and it plays there, travelling as its motion travels (the toy car let go to roll off)
	down: boolean?,
	-- a wind-up set down that walks on its spring (the chattering teeth): a wall stops it going
	-- forward, not its going. It plays on where it stands, chattering against the wall, and its
	-- lure with it. None: it holds the frame it stopped short in, as the toy car does.
	walks: boolean?,
	-- a string of lights laid along the floor when it's set down lit (the fairy lights, F-G1e5c,
	-- as Minecraft's torches light a tunnel): it runs out `length` studs from where it lands, the
	-- longest clear way along the hall, with `sound`; a Mannequin in that line of light can't move
	-- (`Finds/Strand`). Picked up again, it's the coil in your hand, still lit.
	lays: { length: number, sound: Sound }?,
}

export type Row = {
	key: string, -- its catalog key, and its template's name in ReplicatedStorage.Props.Finds
	set: string, -- the set its art is in (`Finds/Sets`), and the texture set it wears
	-- its line in art/finds/WAVES.md is ticked built: its art was judged, so the deal may take it
	judged: boolean,
	name: string, -- on screen: the prompt's object, the slot's label
	grade: Grades.Grade, -- the item catalog's: how rare it is (`Grades`, D-188)
	worth: number, -- the item catalog's, in cash
	from: number?, -- the lowest floor it's dealt on; none: from floor 1
	-- the catalog says loose only: it stands on the unit's floor, never in the marked box
	loose: boolean?,
	-- found lit: on as it's found and never runs down, with no press (the Old lamp, D-229). Lying
	-- anywhere it holds a Mannequin for good, as a pressed light lying lit does (D-234, F-G1e5d)
	lit: boolean?,
	-- fragile (the catalog's word, F-G1e5e): the glass part that cracks when it's dropped hard,
	-- by its name in the art ("OilLamp_Chimney"); cracked, it's worth half (`Finds/Chip`)
	fragile: string?,
	grip: { number }, -- where your hand closes, studs from the middle of its bottom
	heft: number, -- how heavy it feels in your hand, 0 to 1
	-- where it sits in your view (`Tools.Catalog`'s HOLD); Big, a floor's big find (S4-05b2a):
	-- held low in both arms, its top just under your eyes, with a walk of its own (`walkSpeed`)
	size: "Small" | "Medium" | "Large" | "Big",
	-- the catalog says both hands: hugged to your chest, centred low in your view; no switching
	-- slots or picking anything up till you drop it (`Tools.Catalog`'s `bothHands`)
	bothHands: boolean?,
	-- your walk while it's in your hands, studs a second (a Big find's; Roblox's own is 16)
	walkSpeed: number?,
	pickUp: Sound, -- your hand closing on it
	drop: Sound, -- it landing on the concrete
	-- its press's one word (the RC car's Drive, whose press is `Finds/Drive`); none: no press
	verb: string?,
	press: Press?, -- what its press plays (`Finds/Use`)
	-- plain words a recipe matches it by ("egg"; `Home/RecipeRows`, D-476): a find joins every
	-- recipe its tags name with no new row; none: it joins only recipes that name it
	tags: { string }?,
}

return {}
