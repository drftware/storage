--!strict
-- Prints a floor's deal (L-04d): lune run scripts/floor-deal [seed] [floor] [mood]
-- (seed 1, floor 1 and Build by default; mood is Build, Peak or Relief). The floor is the one
-- `scripts/floor-map` draws for the same seed and floor. Its code and the notes that carry it,
-- the padlocked doors, then what each door holds, dealt in number order (the way you'd meet them
-- walking out from the lobby) with the director in that mood. A keeper dealt awake counts toward
-- the floor's cap, so past it they're dealt asleep.
local process = require("@lune/process")

local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")

local seed = tonumber(process.args[1]) or 1
local number = tonumber(process.args[2]) or 1
local mood = (process.args[3] or "Build") :: Deal.Mood
assert(Deal.Odds[mood], "mood: Build, Peak or Relief")

-- The deal draws from its own Random, seeded apart from the layout's (as tests/deal.spec does).
local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
local deck = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
local units = Deal.units(floor)

local function num(i: number): string
	return floor.slots[i].number or "?"
end

print(
	`Floor {number}, seed {seed}: {#units} units ({num(units[1])} to {num(units[#units])}), {floor.paint} doors`
)
print(`The code: {table.concat(deck.code, " ")}`)
local notes, noteAt = {}, {}
for _, note in deck.notes do
	local zone = floor.cells[floor.slots[note.slot].cell].zone
	local where = if zone == "Lobby" then "the lobby's hall" else `wing {zone}`
	local lock = if deck.padlocked[note.slot] then ", padlocked" else ""
	table.insert(notes, `{num(note.slot)} shows {Deal.noteText(deck, note)} ({where}{lock})`)
	noteAt[note.slot] = true
end
print(`Notes: {table.concat(notes, " · ")}`)
local locks = {}
for _, i in units do
	if deck.padlocked[i] then
		table.insert(locks, num(i))
	end
end
print(`Padlocked ({#locks}): {table.concat(locks, " ")}`)

print(`\nBehind the doors in {mood} (* padlocked, n a note; up to {Deal.awakeCap(number)} awake):`)
local counts = { Nothing = 0, Find = 0, Tool = 0, Asleep = 0, Awake = 0 } :: { [string]: number }
local tools = {} :: { [string]: number }
local line, awake = {}, 0
for _, i in units do
	local got = Deal.open(deck, i, { mood = mood, awake = awake })
	counts[got.kind] += 1
	local label = if got.kind == "Tool"
		then got.tool :: string
		elseif got.kind == "Asleep" then `{got.keeper} asleep`
		elseif got.kind == "Awake" then `{got.keeper} AWAKE`
		elseif got.kind == "Find" then "a find"
		else "nothing"
	if got.kind == "Tool" then
		tools[label] = (tools[label] or 0) + 1
	elseif got.kind == "Awake" then
		awake += 1
	end
	local flag = (if deck.padlocked[i] then "*" else " ") .. (if noteAt[i] then "n" else " ")
	table.insert(line, string.format("%s%s %-17s", num(i), flag, label))
	if #line == 4 then
		print("  " .. table.concat(line, ""))
		line = {}
	end
end
if #line > 0 then
	print("  " .. table.concat(line, ""))
end

local toolText = {}
for _, tool in Deal.Tools do
	if tools[tool] then
		table.insert(toolText, `{tool} {tools[tool]}`)
	end
end
print(
	`\n{counts.Nothing} nothing, {counts.Find} finds, {counts.Tool} tools ({table.concat(toolText, ", ")}), `
		.. `{counts.Asleep} keepers asleep, {counts.Awake} awake`
)
