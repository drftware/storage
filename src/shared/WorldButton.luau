--!strict
--[[
	WorldButton: the one look every button in the world wears (L-19a, D-114), as numbers and the pure
	maths of its motion. ButtonView (client) draws every ProximityPrompt this way; the server's
	`Prompts` and the client's own prompts set `Style` Custom so Roblox's box never shows.

	The look: a small round key chip with the verb beside it, no box, the thing's name small above
	the verb only where it's news (which unit lies behind a wall, who is under the film, which tool
	lies there). On a computer the chip carries the key (E) or the pad's button picture; on a phone
	it is the thumb's target, at least 44 points, with nothing written on it. It swells in the
	moment you're near and is gone in a blink when you're not; a hold fills a ring round the chip
	(as Fortnite's hold-to-interact ring fills); a press pops it; a refusal shakes it and turns the
	verb into the refusal's few words in red.

	A refusal reaches only the player who pressed: the server fires `Remotes.Refused` to them with
	the button and its words (`Prompts.refuser`).
]]

local WorldButton = {}

-- ReplicatedStorage.Remotes.Refused: the server tells one player's screen that their press on a
-- button was refused, with the words to show (server to client only).
WorldButton.RemoteFolder = "Remotes"
WorldButton.Remote = "Refused"
-- The longest refusal a screen draws; anything longer from the wire is cut.
WorldButton.MaxWords = 40

-- Sizes, in screen points (a phone's UI points, so a thumb's target holds on any screen).
WorldButton.Chip = 38 -- the key chip on a computer: a key cap, read at a glance
WorldButton.TouchChip = 48 -- on a phone: a thumb's target, over Apple's and Google's 44
WorldButton.Hit = 8 -- extra points round the chip a tap still lands in
WorldButton.Ring = 10 -- the hold ring is this much wider than the chip
WorldButton.Gap = 9 -- between the chip and the verb
WorldButton.Verb = 20 -- the verb's text height
WorldButton.Name = 14 -- the name's, smaller and dimmer: it's a footnote to the verb
WorldButton.Key = 17 -- the key's letter in the chip
-- The chip sits this far left of the button's point, so a chip and a short verb ("Open") sit
-- centred on it together. Fixed, so a refusal's longer words never move the chip.
WorldButton.Shift = 30
-- The whole button's canvas: wide enough for the longest refusal right of the chip.
WorldButton.Width = 520
WorldButton.Height = 96

-- Timings, in seconds.
WorldButton.In = 0.12 -- swelling in as you come near: there the instant you are
WorldButton.Out = 0.08 -- gone as you leave: no trail
-- Seconds every button takes to fade aside while the inventory wheel is open over them, and to
-- come back as it folds: quick enough that the wheel owns the screen the moment it fans out.
WorldButton.Aside = 0.1
WorldButton.InScale = 0.72 -- how small it starts as it swells in
WorldButton.OutScale = 0.9 -- how small it ends as it goes
WorldButton.Pop = 0.22 -- a press's pop, squashed and springing back
WorldButton.PopScale = 0.82 -- how far a press squashes it
WorldButton.Held = 0.93 -- its size while a key or thumb is down on a hold
WorldButton.Drain = 0.16 -- a let-go hold's ring emptying
WorldButton.Refusal = 1.2 -- a refusal's red words held before the verb comes back
WorldButton.Calm = 0.2 -- the red easing back to the verb's colour after that
WorldButton.Shake = 0.38 -- a refusal's shake, side to side, dying away
WorldButton.ShakePoints = 7 -- how far its first swing goes
WorldButton.ShakeSwings = 3.5 -- whole swings over the shake
WorldButton.Slide = 0.14 -- a button moving along its row as its neighbours change (a door's Slam)

local function clamp01(x: number): number
	return if x < 0 then 0 elseif x > 1 then 1 else x
end

-- Eased out with a little overshoot: a spring settling (the standard "back" curve).
function WorldButton.spring(p: number): number
	local t = clamp01(p) - 1
	local s = 1.9
	return 1 + t * t * ((s + 1) * t + s)
end

--- How far in a button is, from `level` 0 (gone) to 1 (fully shown), and whether it is coming
--- in (else going): its opacity and its scale. Coming in it swells with a spring; going it only
--- shrinks a touch as it fades.
function WorldButton.presence(level: number, coming: boolean): (number, number)
	local l = clamp01(level)
	if coming then
		return l, WorldButton.InScale + (1 - WorldButton.InScale) * WorldButton.spring(l)
	end
	return l, WorldButton.OutScale + (1 - WorldButton.OutScale) * l
end

--- A press's pop `seconds` after it: the scale it multiplies by (1 when over) and the flash of
--- light in the chip (1 at the press, 0 when over).
function WorldButton.pop(seconds: number): (number, number)
	if seconds < 0 or seconds >= WorldButton.Pop then
		return 1, 0
	end
	local p = seconds / WorldButton.Pop
	local flash = (1 - p) * (1 - p)
	return WorldButton.PopScale + (1 - WorldButton.PopScale) * WorldButton.spring(p), flash
end

--- How far along its slide a button is `seconds` after its place on the row changed: 0 at the
--- old place, 1 at the new, eased out so it lands softly.
function WorldButton.slide(seconds: number): number
	local p = clamp01(seconds / WorldButton.Slide)
	local t = 1 - p
	return 1 - t * t * t
end

--- A refusal's sideways shove `seconds` after it, in points: a swing that dies away.
function WorldButton.shake(seconds: number): number
	if seconds < 0 or seconds >= WorldButton.Shake then
		return 0
	end
	local p = seconds / WorldButton.Shake
	local fade = (1 - p) * (1 - p)
	return WorldButton.ShakePoints * math.sin(p * WorldButton.ShakeSwings * 2 * math.pi) * fade
end

--- How red a refused button is `seconds` after the refusal (1 red, 0 its own colour), and whether
--- its refusal's words still show in place of the verb.
function WorldButton.red(seconds: number): (number, boolean)
	if seconds < 0 then
		return 0, false
	end
	if seconds < WorldButton.Refusal then
		return 1, true
	end
	return 1 - clamp01((seconds - WorldButton.Refusal) / WorldButton.Calm), false
end

--- Whether a refusal `seconds` old is still moving (shaking, red, or easing back).
function WorldButton.refusing(seconds: number): boolean
	return seconds >= 0 and seconds < WorldButton.Refusal + WorldButton.Calm
end

--- The hold ring for a ring `fill` full (0 to 1), as the rotations of the gradients that clip its
--- left and right halves (Roblox's own prompt draws its ring this way): it fills clockwise from
--- twelve o'clock, the right half first.
function WorldButton.halves(fill: number): (number, number)
	local angle = clamp01(fill) * 360
	local right = math.clamp(angle, 0, 180)
	local left = math.clamp(angle, 180, 360)
	return left, right
end

--- The ring's fill `seconds` into a hold of `duration` seconds.
function WorldButton.holding(seconds: number, duration: number): number
	if duration <= 0 then
		return 1
	end
	return clamp01(seconds / duration)
end

--- The ring's fill `seconds` after a hold that had reached `from` was let go (or fired).
function WorldButton.draining(from: number, seconds: number): number
	return clamp01(from) * (1 - clamp01(seconds / WorldButton.Drain))
end

-- Crowding (S5-03j7a): two things side by side whose buttons land on top of each other on a
-- small screen (an "Open" on one crate over a "Sit" on the next) would read as one smear and take
-- the wrong tap. Only the nearest thing's buttons show there; the farther thing's fade out until
-- the camera or the player moves them apart, as Roblox's own prompts show one per key.
WorldButton.CrowdEvery = 0.1 -- seconds between looks for crowding: quick enough to feel instant
WorldButton.CrowdGap = 4 -- points two things' rows must stay apart to both show
WorldButton.CrowdClear = 14 -- points a hidden row must clear by to come back: no flicker at the edge
WorldButton.Crowd = 0.1 -- seconds a crowded row takes to fade out or back

-- One thing's row of buttons on the screen: its box in screen points, how near it is to the
-- player (smaller is nearer), and whether it yields to a nearer row now.
export type Row = {
	left: number,
	top: number,
	right: number,
	bottom: number,
	near: number,
	crowded: boolean,
}

local function byNear(a: Row, b: Row): boolean
	return a.near < b.near
end

--- Decides which of `rows` yield: nearest first, a row overlapping one that shows (within
--- `CrowdGap`, or `CrowdClear` while it already yields) yields too. Sets each row's `crowded`;
--- sorts `rows` in place; allocates nothing.
function WorldButton.crowd(rows: { Row })
	table.sort(rows, byNear)
	for i, r in rows do
		local gap = if r.crowded then WorldButton.CrowdClear else WorldButton.CrowdGap
		local yields = false
		for j = 1, i - 1 do
			local o = rows[j]
			if
				not o.crowded
				and r.left < o.right + gap
				and o.left < r.right + gap
				and r.top < o.bottom + gap
				and o.top < r.bottom + gap
			then
				yields = true
				break
			end
		end
		r.crowded = yields
	end
end

--- Words safe to draw from the wire: a string, trimmed to `MaxWords`; nil for anything else.
function WorldButton.words(text: unknown): string?
	if type(text) ~= "string" or text == "" then
		return nil
	end
	if #text > WorldButton.MaxWords then
		return string.sub(text, 1, WorldButton.MaxWords)
	end
	return text
end

return WorldButton
