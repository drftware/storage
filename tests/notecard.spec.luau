--!strict
-- lune run tests/notecard.spec
-- A code note held up on the screen (L-05b1d): on the Galaxy A16 the card sits whole below
-- Roblox's top bar, crooked or not, clear of the jump button, its digit several millimetres tall;
-- its four slots lie side by side over the note's writing area, as on the wall, each wide and
-- tall enough for its mark; on other screens it still fits and still reads; a note's writing
-- splits into its slots; and the Read button shows a step or two into a unit, never from the hall.
local Deal = require("../src/shared/Deal")
local NoteCard = require("../src/shared/Elevator/NoteCard")
local NoteSpot = require("../src/shared/Elevator/NoteSpot")
local ElevatorSpecs = require("../src/shared/Elevator/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

-- The Galaxy A16 in Studio's Device Simulator, held sideways (docs/STUDIO.md): a 685 by 338 view,
-- 58 of it Roblox's top bar. The phone shows about 5.05 of these points a millimetre (1080 by
-- 2340 pixels at 385 a inch, three to a point).
local A16 = { width = 685, height = 338, top = 58 }
local POINTS_PER_MM = 385 / 25.4 / 3
-- Room kept clear on the right for the jump button (as KeypadPad keeps it).
local JUMP_ROOM = 110

-- How far a card of `side` reaches from its middle, turned `degrees` either way.
local function reach(side: number, degrees: number): number
	local a = math.rad(math.abs(degrees))
	return side / 2 * (math.cos(a) + math.sin(a))
end

local function fits(screen: { width: number, height: number, top: number }, what: string)
	local layout = NoteCard.layout(screen.width, screen.height, screen.top, 4)
	local half = reach(layout.side, NoteSpot.Tilt)
	ok(
		layout.side >= NoteCard.MinSide and layout.side <= NoteCard.MaxSide,
		`{what}: side {layout.side} in bounds`
	)
	ok(
		layout.x - half >= 0 and layout.x + half <= screen.width,
		`{what}: the card's width on screen`
	)
	ok(layout.y - half >= screen.top, `{what}: the card below the top bar`)
	ok(layout.y + half <= screen.height, `{what}: the card above the screen's foot`)
	ok(layout.text <= NoteCard.MaxText, `{what}: text {layout.text} no larger than Roblox draws`)
	ok(layout.text >= 40, `{what}: text {layout.text} big enough to read at a glance`)
	ok(#layout.slots == 4, `{what}: four slots`)

	-- The slots: side by side, the same size, over the note's writing area, inside the paper.
	local perStud = layout.side / layout.studs
	local write = ElevatorSpecs.Note.Write
	local paperEdge = layout.side * (1 - NoteCard.Paper) / 2
	for i, slot in layout.slots do
		ok(
			slot.x >= paperEdge and slot.x + slot.w <= layout.side - paperEdge,
			`{what}: slot {i} across the paper`
		)
		ok(
			slot.y >= paperEdge and slot.y + slot.h <= layout.side - paperEdge,
			`{what}: slot {i} down the paper`
		)
		ok(
			layout.text * NoteCard.Advance <= slot.w + 1e-9,
			`{what}: slot {i}'s mark fits its width`
		)
		ok(layout.text * NoteCard.Line <= slot.h + 1e-9, `{what}: slot {i}'s line fits its height`)
		ok(
			math.abs(slot.h - write.Size[2] * perStud) < 1e-6,
			`{what}: slot {i} as tall as the writing area`
		)
		local first = layout.slots[1]
		ok(
			math.abs(slot.w - first.w) < 1e-9 and slot.y == first.y,
			`{what}: slot {i} like the first`
		)
		if i > 1 then
			local before = layout.slots[i - 1]
			ok(
				math.abs(before.x + before.w - slot.x) < 1e-9,
				`{what}: slot {i} right after slot {i - 1}`
			)
		end
	end
	local left, last = layout.slots[1], layout.slots[#layout.slots]
	local across = last.x + last.w - left.x
	ok(
		math.abs(across - write.Size[1] * perStud * (1 - 2 * NoteCard.Pad)) < 1e-6,
		`{what}: the slots span the writing as the wall's do`
	)
	ok(
		math.abs((left.x + last.x + last.w) / 2 - layout.side / 2) < 1e-6,
		`{what}: the slots centred across`
	)
	-- the writing sits above the note's middle, as on the wall (its curled foot is blank)
	ok(left.y + left.h / 2 < layout.side / 2, `{what}: the slots above the card's middle`)
	return layout
end

-- On the A16: the card's digit several millimetres tall (on the wall it's about 2 mm from five
-- studs, tests/notespot.spec), and the card clear of the jump button.
local a16 = fits(A16, "Galaxy A16")
local digitMm = a16.text * NoteCard.DigitShare / POINTS_PER_MM
ok(digitMm >= 6, `A16: the digit {digitMm} mm tall, at least 6`)
ok(
	a16.x + reach(a16.side, NoteSpot.Tilt) <= A16.width - JUMP_ROOM,
	"A16: the card clear of the jump button"
)
ok(a16.side >= 200, `A16: the card {a16.side} points across, most of the phone's height`)

-- Other screens it must fit and read on.
fits({ width = 568, height = 320, top = 36 }, "a small phone sideways")
fits({ width = 705, height = 338, top = 58 }, "Galaxy A06")
fits({ width = 750, height = 362, top = 58 }, "iPhone 17 Pro")
fits({ width = 338, height = 685, top = 58 }, "a phone upright")
fits({ width = 1024, height = 768, top = 36 }, "a tablet")
fits({ width = 1920, height = 1080, top = 58 }, "a computer")
fits({ width = 1280, height = 720, top = 36 }, "a console at 720")

-- The paper's camera frames the paper with room to spare.
ok(NoteCard.Studs > ElevatorSpecs.Note.Side, "the card frames the whole note")
local paper = ElevatorSpecs.Parts.Note
ok(math.abs(NoteCard.Middle - paper.Centre[2]) < 1e-9, "the camera on the paper's middle")
ok(
	paper.Size[2] / 2 + math.abs(paper.Centre[2] - NoteCard.Middle) <= NoteCard.Studs / 2,
	"the note's height framed"
)

-- A note's writing splits into its slots, as Deal writes it.
local function same(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end
ok(same(NoteCard.slots("_ 7 _ _"), { "_", "7", "_", "_" }), "slots of _ 7 _ _")
ok(same(NoteCard.slots("5 _ _ _"), { "5", "_", "_", "_" }), "slots of 5 _ _ _")
ok(same(NoteCard.slots("  1 2  3 4 "), { "1", "2", "3", "4" }), "slots ignore extra spaces")
ok(#NoteCard.slots("") == 0, "no writing, no slots")
local code = { 5, 0, 6, 2 }
for mask = 1, 15 do
	local places = {}
	for p = 1, 4 do
		if bit32.btest(mask, bit32.lshift(1, p - 1)) then
			table.insert(places, p)
		end
	end
	-- Deal only reads the deck's code and the note's places here
	local marks = NoteCard.slots(Deal.noteText({ code = code } :: any, { places = places } :: any))
	ok(#marks == 4, `note {mask}: four slots`)
	for p = 1, 4 do
		local shown = table.find(places, p) ~= nil
		ok(marks[p] == (if shown then tostring(code[p]) else "_"), `note {mask}: slot {p}`)
	end
end

-- Where Read shows, in each unit size: the button's point is under the note, a little out from
-- the wall; a standing player's root rides 3 studs up. Never from the hall or the doorway; by a
-- couple of steps into a small unit and halfway into a big one; and walking back out to the
-- doorway drops the card.
local ROOT = 3
local half = ElevatorSpecs.Note.Side * NoteSpot.Scale / 2
for size, depth in { S = 8, M = 12 } do
	local spot = NoteSpot.inUnit(depth, "214")
	local buttonZ = spot.z - NoteCard.ButtonOut
	local buttonY = spot.y - half - NoteCard.ButtonBelow
	local function toButton(z: number): number
		return math.sqrt((buttonZ - z) ^ 2 + (buttonY - ROOT) ^ 2 + spot.x ^ 2)
	end
	local function toNote(z: number): number
		return math.sqrt((spot.z - z) ^ 2 + (spot.y - ROOT) ^ 2 + spot.x ^ 2)
	end
	ok(toButton(0) > NoteCard.Reach, `{size}: no Read from the doorway`)
	ok(toButton(-1) > NoteCard.Reach, `{size}: no Read from the hall`)
	ok(toButton(depth / 2) <= NoteCard.Reach, `{size}: Read by halfway in`)
	if size == "S" then
		ok(toButton(3) <= NoteCard.Reach, "S: Read two steps in")
	end
	ok(toNote(0) > NoteCard.LetGo, `{size}: the card drops by the doorway`)
	ok(toNote(depth - 1.5) <= NoteCard.LetGo, `{size}: the card stays up at the note`)
	ok(buttonY <= spot.y - half - 0.4, `{size}: the button's point well under the note's foot`)
end
ok(NoteCard.Reach < NoteCard.LetGo, "the card stays up a little past where Read shows")

print(
	`notecard: {checks - failures}/{checks} checks passed (A16: the digit {string.format(
		"%.1f",
		digitMm
	)} mm)`
)
if failures > 0 then
	error(`{failures} failed`)
end
