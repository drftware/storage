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
