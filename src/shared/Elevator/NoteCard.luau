--!strict
--[[
	NoteCard: a code note held up on your screen (L-05b1d; owner, Nov 8, D-044), the numbers alone
	so Lune checks them (tests/notecard.spec.luau). The moment it serves: the door lifts, the yellow
	square on the back wall, two steps in, tap Read, and the note fills the middle of the screen,
	its digit big and plain: "I've got a 0, second!" As DOORS holds a library book's hint up to you.

	The card is the note itself: its paper drawn face on (the client renders the real mesh), and
	its four slots written in the note's own hand over the note's own writing area, as on the wall,
	only as tall as the phone allows. A layout is in the card's points: x right, y down, from its
	top-left corner; the screen's points for where the card sits.
]]
local Specs = require("./Specs")

local NoteCard = {}

-- The Read button shows within this many studs of the note: two steps into a small unit, most of
-- the way into a big one, never from the hall. You go in to read it.
NoteCard.Reach = 6
-- Walking this far from the note drops the card: about a small unit's doorway, so you can back
-- out reading it but not carry it down the hall.
NoteCard.LetGo = 8
-- The button's point stands this far out from the wall and this far under the note's bottom edge
-- (studs), so the button sits below the note instead of over the digit you came for.
NoteCard.ButtonOut = 0.25
NoteCard.ButtonBelow = 0.45

-- The card fills this share of the screen's height below Roblox's top bar: as big as a phone held
-- sideways allows, with a little room round it for its tilt and its lift.
NoteCard.Fill = 0.84
-- and no more than this share of the screen's width, so the thumbstick and jump button stay clear
NoteCard.Wide = 0.48
-- never smaller or bigger than these (points), so a tablet's note isn't a poster
NoteCard.MinSide = 160
NoteCard.MaxSide = 480
-- The paper fills this share of the card's side; the rest keeps its corners clear of the edge.
NoteCard.Paper = 0.94
-- So the paper's camera frames this many studs of note across the card, centred on the paper's
-- own middle (its curled foot makes it a little shorter than it is wide).
NoteCard.Studs = Specs.Note.Side / NoteCard.Paper
NoteCard.Middle = Specs.Parts.Note.Centre[2]

-- Kalam (bold), the note's hand, measured with TextService:GetTextBoundsAsync in Studio
-- (L-05b1d): its line is exactly as tall as its TextSize, and its widest slot mark ("_") is 0.39
-- of it wide. A digit's ink stands 0.415 of the TextSize (L-05b1b's 0.107-stud digit on the
-- wall's 0.258-stud line).
NoteCard.Line = 1
NoteCard.Advance = 0.39
NoteCard.DigitShare = 0.415
-- Roblox draws no text larger than this.
NoteCard.MaxText = 100
-- The wall's writing leaves this share of its area's width clear at each end (`Elevator.prepare`'s
-- padding); the card keeps the same margins, so the slots sit where the wall's do.
NoteCard.Pad = 0.04

export type Box = {
	x: number, -- left, from the card's left edge (points)
	y: number, -- top, from the card's top edge
	w: number,
	h: number,
}

export type Layout = {
	side: number, -- the card's side (points); it's square, as the note is
	x: number, -- its middle on the screen (points from the screen's left)
	y: number, -- and from the screen's top (Roblox's top bar included)
	studs: number, -- studs of note across the card: what the paper's camera frames
	middle: number, -- the height in the note's own frame at the card's middle (studs)
	text: number, -- TextSize for every slot, so a blank and a digit are written alike
	slots: { Box }, -- left to right, as the note's slots read
}

--[[
	Notes in your pocket (B-04a). A note taken out of its box is the taker's: the server keeps
	what each player holds and mirrors it on them in one attribute, each note's writing ("_ 7 _ _")
	in the order taken, joined by `Join`, so their screen can show and hold up every one. Notes
	ride apart from your hands, as DOORS keeps its hint paper in a slot of its own, so taking one
	never costs a find. A floor has at most four.
]]
NoteCard.Held = "HeldNotes"
NoteCard.Join = "|"
NoteCard.Pocket = 4

-- The notes an attribute's `value` holds, in the order taken (none if it isn't one).
function NoteCard.held(value: unknown): { string }
	local out: { string } = {}
	if type(value) ~= "string" then
		return out
	end
	for text in string.gmatch(value, "[^|]+") do
		if #out < NoteCard.Pocket then
			table.insert(out, text)
		end
	end
	return out
end

-- The attribute for `notes`, in order: what `held` reads back.
function NoteCard.pocket(notes: { string }): string
	return table.concat(notes, NoteCard.Join, 1, math.min(#notes, NoteCard.Pocket))
end

--[[
	Carrying a note to the car (B-04b, D-214). Walk up to the elevator's keypad holding notes and
	they leave your pocket and fly onto the wall beside it, each slapped up with a tack's tap, so
	the team's clues gather where the code goes in and anyone at the keypad reads them there. As a
	Roblox simulator's sell pad takes your bag the moment you step on it: no button to find.
	Caught or gone holding notes, they tumble out where you were, to lie flat on the floor until a
	friend taps Take.

	A placed note carries `Placed` ("Pinned" or "Dropped"), `PlacedAt` (server time) and
	`PlacedFrom` (where it left the hand, a Vector3), so every screen near flies it there or
	tumbles it down once (NotePlaces); a note that streams in later just lies where it is.
]]
NoteCard.Placed = "Placed"
NoteCard.PlacedAt = "PlacedAt"
NoteCard.PlacedFrom = "PlacedFrom"

-- Within this many studs of the keypad's face your notes go up: standing at it, or a step off.
NoteCard.PinReach = 5
-- The pinned notes' row on the lobby wall, in the elevator's frame (studs): the first one's
-- middle beside the keypad (just past its edge, away from the opening), then each next one a
-- note's width and a sliver further along; a fifth starts a row below. Eye level, a touch over
-- the keypad's middle, so the camera at the keypad has them in view beside it. Four fit before
-- the lobby's side wall (x -12, seen in Studio).
NoteCard.PinFirst = -8.85
NoteCard.PinStep = -0.8
NoteCard.PinHeight = 4.25
NoteCard.PinRowDrop = 0.95
NoteCard.PinPerRow = 4
-- Each slapped up crooked by up to this many degrees, as a hand in a hurry pins it.
NoteCard.PinTilt = 7
-- Off the wall's face (studs), clear of it at any distance.
NoteCard.PinOut = 0.006

-- Dropped notes land within this many studs of where you stood, spread so each shows.
NoteCard.DropSpread = 1.2
-- The Take button: within this many studs (a step off the paper), at most one press this often.
NoteCard.TakeReach = 6
NoteCard.TakeSeconds = 0.3
-- The Take button floats this far over the paper lying on the floor.
NoteCard.TakeUp = 0.5

-- The flight to the wall: this long, rising this far over the straight line, a quarter turn
-- spun off as it lands; then the tack's tap.
NoteCard.PinFly = 0.34
NoteCard.PinArc = 0.6
-- The tumble to the floor: this long, rocking side to side this many times and this far
-- (studs), as a loose sheet does; the flap as it leaves the hand.
NoteCard.DropFall = 0.75
NoteCard.DropRocks = 2.5
NoteCard.DropSway = 0.35
-- A placed note older than this when a screen first sees it just lies there (streamed in late).
NoteCard.PlacedFresh = 1.5

-- Where the `i`th note pinned beside a keypad goes, in the elevator's frame: its middle's x and
-- y on the lobby wall, and its crook in degrees (a fixed spread, so every server agrees).
function NoteCard.pinAt(i: number): (number, number, number)
	local k = math.max(1, math.floor(i)) - 1
	local col = k % NoteCard.PinPerRow
	local row = k // NoteCard.PinPerRow
	local crook = ({ -0.6, 0.85, -0.25, 0.5 })[col + 1] * NoteCard.PinTilt
	return NoteCard.PinFirst + col * NoteCard.PinStep,
		NoteCard.PinHeight - row * NoteCard.PinRowDrop,
		if row % 2 == 1 then -crook else crook
end

-- Where the `i`th of `count` dropped notes lands, from where its holder stood (studs, across
-- the floor's x and z): one in the middle, more spread round a circle so none hides another.
function NoteCard.scatter(i: number, count: number): (number, number)
	if count <= 1 then
		return 0, 0
	end
	local turn = (i - 1) / count * 2 * math.pi + 0.4
	local r = NoteCard.DropSpread * (0.55 + 0.45 * ((i * 7) % 5) / 4)
	return math.cos(turn) * r, math.sin(turn) * r
end

-- The slots a note's writing shows, left to right: "_ 7 _ _" is { "_", "7", "_", "_" }.
function NoteCard.slots(text: string): { string }
	local out = {}
	for mark in string.gmatch(text, "%S+") do
		table.insert(out, mark)
	end
	return out
end

-- The card on a screen `width` by `height` points whose top `top` points are Roblox's bar, with
-- `count` slots on the note.
function NoteCard.layout(width: number, height: number, top: number, count: number): Layout
	local below = height - top
	local side = math.clamp(
		math.min(below * NoteCard.Fill, width * NoteCard.Wide),
		NoteCard.MinSide,
		NoteCard.MaxSide
	)
	local studs, middle = NoteCard.Studs, NoteCard.Middle
	local perStud = side / studs

	-- The writing area, seen face on: the note's +X is the viewer's left (its face looks back at
	-- you), and its +Y is up the screen.
	local write = Specs.Note.Write
	local cx = side / 2 - write.Centre[1] * perStud
	local cy = side / 2 - (write.Centre[2] - middle) * perStud
	local w, h = write.Size[1] * perStud, write.Size[2] * perStud
	local inner = w * (1 - 2 * NoteCard.Pad)
	local each = inner / math.max(count, 1)

	local slots: { Box } = {}
	for i = 1, count do
		table.insert(
			slots,
			{ x = cx - inner / 2 + (i - 1) * each, y = cy - h / 2, w = each, h = h }
		)
	end
	local text = math.floor(math.min(h / NoteCard.Line, each / NoteCard.Advance, NoteCard.MaxText))

	return {
		side = side,
		x = width / 2,
		y = top + below / 2,
		studs = studs,
		middle = middle,
		text = text,
		slots = slots,
	}
end

return NoteCard
