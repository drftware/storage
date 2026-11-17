--!strict
--[[
	The presses of the one-mesh finds (F-G1e5a): the bedroom set is one mesh each, with no parts,
	joints or kit motions (`Finds/Specs`), so what its press plays is written here by hand, as its
	catalog row is (`Tools/Catalog`, art/finds/PIPELINE.md "Not here"). Each moves its one mesh as
	a whole: squashed and swelled about its middle in your hand (a squishy's squash, F-G1e1b) and
	tipped and lifted about `pivot` by its grip (the kazoo's carry, F-G1e3c). `Finds.art` makes
	each a one-part find from this, so `Finds/Use`, `FindUses` and `FindUseView` play it as any
	kit find's press.

	The moments: you press Play and the boombox's key clacks down, then loud 80s electro booms
	out, the case thumping on every beat and swaying from its handle, and every monster on the
	floor comes to look, wherever you carry it or leave it; fifteen seconds on, the stop key
	clacks and it's quiet. You hug the teddy and it squashes in your arms, gives a tiny muffled
	squeak and wiggles back into shape.

	Keys are the kit's (`Art.Key`): seconds in, the value, and how it eases from the key before.
	Every track starts where the find rests (the stretch and scale at 1, the rest at 0).
]]

local Art = require("./Art")
local Game = require("./Game")

export type Entry = {
	-- where it tips and lifts about, studs from the middle of its bottom (x, y, z): its grip, so
	-- the boombox sways from the handle in your fist. Plain numbers, so Lune reads this module.
	pivot: { number },
	motions: { [string]: Art.Motion },
	press: Game.Press,
}

-- One beat of the boombox's song (seconds): Electroboogie runs at about 113 beats a minute
-- (measured in Play, F-G1e5a), so the case thumps with the kick drum.
local BEAT = 0.532
-- How long the boombox plays before its stop key clacks: 28 beats, about 15 seconds, so the
-- song stops on a beat and the case comes to rest. A monkey's 20 seconds is still the longest.
local PLAYS = 28 * BEAT

-- Pro Sound Effects' "Switch Portable Plastic Radio Tape Player 6": a key snapping down at
-- 0.14 s and its spring's ring: the Play key under your thumb.
local PLAY_KEY: Game.Sound =
	{ id = "rbxassetid://9119730203", from = 0, length = 0.42, volume = 1.4 }
-- APM's "Electroboogie" (139 s): 80s electro, loud from 8 s in, a beat landing at 8.06 s; from
-- 8.04 the first thump lands on the kick. Cut half a second short, as `Tools.play` lets a sound
-- run half a second past its length, so it stops as the stop key clacks.
local SONG: Game.Sound = {
	id = "rbxassetid://1842805228",
	from = 8.04,
	length = PLAYS - 0.35,
	volume = 0.5,
}
-- Pro Sound Effects' "Switch Portable Plastic Radio Tape Player 7": a tick, then the key's
-- clack at 0.14 s: the stop key, the song cut under it.
local STOP_KEY: Game.Sound =
	{ id = "rbxassetid://9119730202", from = 0, length = 0.6, volume = 1.6 }

-- Pro Sound Effects' "Pillow Blanket 1" from just before its grab on the cloth: arms closing
-- round plush.
local HUG: Game.Sound = { id = "rbxassetid://9117373366", from = 0.5, length = 0.45, volume = 0.5 }
-- The rubber duck's squeak ("Squeeze Toy Squeaky Rubber With Noisemaker Hits 10"), higher and
-- quiet: a tiny squeaker deep in the stuffing.
local SQUEAKER: Game.Sound = {
	id = "rbxassetid://9125994570",
	from = 0,
	length = 0.3,
	volume = 0.35,
	pitch = 1.35,
}

-- A thump on each of two beats (the case swelling with the kick and hopping in your fist) and a
-- sway from the handle across them, one way and back.
local function thumping(part: string): Art.Motion
	local b = BEAT
	return {
		Duration = 2 * b,
		Tracks = {
			{
				Part = part,
				Channel = "scale",
				Keys = {
					{ 0, 1, "Sine", "InOut" },
					{ 0.06, 1.04, "Quad", "Out" },
					{ b, 1, "Sine", "InOut" },
					{ b + 0.06, 1.04, "Quad", "Out" },
					{ 2 * b, 1, "Sine", "InOut" },
				},
			},
			{
				Part = part,
				Channel = "y",
				Keys = {
					{ 0, 0, "Sine", "InOut" },
					{ 0.06, 0.035, "Quad", "Out" },
					{ b, 0, "Sine", "InOut" },
					{ b + 0.06, 0.035, "Quad", "Out" },
					{ 2 * b, 0, "Sine", "InOut" },
				},
			},
			{
				Part = part,
				Channel = "roll",
				Keys = {
					{ 0, 0, "Sine", "InOut" },
					{ b / 2, 2.5, "Sine", "InOut" },
					{ b, 0, "Sine", "InOut" },
					{ 1.5 * b, -2.5, "Sine", "InOut" },
					{ 2 * b, 0, "Sine", "InOut" },
				},
			},
		},
	}
end

-- A key pressed on top of the case: it dips under your thumb and tips toward the key.
local function keyed(part: string): Art.Motion
	return {
		Duration = 0.3,
		Tracks = {
			{
				Part = part,
				Channel = "stretch",
				Keys = {
					{ 0, 1, "Sine", "InOut" },
					{ 0.12, 0.97, "Quad", "Out" },
					{ 0.3, 1, "Sine", "InOut" },
				},
			},
			{
				Part = part,
				Channel = "pitch",
				Keys = {
					{ 0, 0, "Sine", "InOut" },
					{ 0.12, -3, "Quad", "Out" },
					{ 0.3, 0, "Sine", "InOut" },
				},
			},
		},
	}
end

local OneMesh: { [string]: Entry } = {
	-- "Play: loud music wherever you leave it; monsters come to look" (R.E.P.O.'s music box): the
	-- cymbal monkey's lure (D-233), heard as far as the air horn every 2 seconds while it plays,
	-- in your hand or where you left it. The case thumps to the beat, as Fortnite's Boom Box
	-- pulses with its music. At home it plays your tapes (the home chain).
	Boombox = {
		pivot = { 0, 1.33, 0 }, -- the handle (its catalog grip)
		motions = {
			Key = keyed("Boombox"),
			Play = thumping("Boombox"),
			Stop = keyed("Boombox"),
		},
		press = {
			verb = "Play",
			on = {
				{ motion = "Key", sound = PLAY_KEY },
				{ motion = "Play", loop = PLAYS, sound = SONG },
				{ motion = "Stop", sound = STOP_KEY },
			},
			noise = "Play",
			lure = 2,
			toy = true,
		},
	},
	-- "Hug: a tiny squeak" (quiet): the squishies' Squeeze (V1), a squash and a sound, hugged
	-- again once it has sprung back. No monster hears it.
	Teddy = {
		pivot = { 0, 0.72, 0 }, -- its middle, so it wiggles about its tummy
		motions = {
			Hug = {
				Duration = 1.0,
				Tracks = {
					{
						Part = "Teddy",
						Channel = "stretch",
						Keys = {
							{ 0, 1, "Sine", "InOut" },
							{ 0.14, 0.78, "Quad", "Out" },
							{ 0.42, 0.8, "Sine", "InOut" },
							{ 0.6, 1.07, "Quad", "Out" },
							{ 0.76, 0.97, "Sine", "InOut" },
							{ 1.0, 1, "Sine", "InOut" },
						},
					},
					{
						Part = "Teddy",
						Channel = "roll",
						Keys = {
							{ 0, 0, "Sine", "InOut" },
							{ 0.14, -6, "Quad", "Out" },
							{ 0.42, -5, "Sine", "InOut" },
							{ 0.62, 4, "Sine", "Out" },
							{ 0.82, -1.5, "Sine", "InOut" },
							{ 1.0, 0, "Sine", "InOut" },
						},
					},
				},
			},
		},
		press = {
			verb = "Hug",
			on = { { motion = "Hug", sound = HUG, cues = { { at = 0.12, sound = SQUEAKER } } } },
			toy = true,
		},
	},
}

return OneMesh
