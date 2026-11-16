--!strict
-- Prints a floor's deal (L-04d): lune run scripts/floor-deal [seed] [floor] [mood]
-- (seed 1, floor 1 and Build by default; mood is Build, Peak or Relief). The floor is the one
-- `scripts/floor-map` draws for the same seed and floor, dealt as the climb deals it (Studio's
-- "Walk a floor" floor, Workspace's DevFloorSeed and DevFloorNumber: `DevCorridor`, `Climbs`). Its code
-- and the notes that carry it, the padlocked doors, the guarded note (its keeper always awake:
-- on floors 1 and 2, the floor's one awake keeper), then what each door holds, dealt in number
-- order (the way you'd meet them walking out from the lobby) with the director in that mood. A
-- keeper dealt awake counts toward the floor's cap, so past it they're dealt asleep. Only which
-- tool a door holds depends on the order: open them in another order in Studio and the tools
-- move between doors, nothing else does.
local process = require("@lune/process")

local Brix = require("../vendor/brix/src")
local Climb = require("../src/shared/Climb")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")
local FloorRules = require("../src/shared/FloorRules")

local seed = tonumber(process.args[1]) or 1
local number = tonumber(process.args[2]) or 1
local mood = (process.args[3] or "Build") :: Deal.Mood
assert(Deal.Odds[mood], "mood: Build, Peak or Relief")

-- The deal carries on from the layout's Random, as the climb lays it, from the floor's own seed
-- (`Climb.seedOf`; tests/deal.spec seeds its own apart instead: either way a seed deals the same
-- every time).
local random = Brix.Random.new({ seed = Climb.seedOf(seed, number) })
local floor = Floor.generate(number, random)
local deck = Deal.new(floor, random)
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
	local guard = if deck.guarded == note.slot then ", guarded" else ""
	table.insert(
		notes,
		`{num(note.slot)} shows {Deal.noteText(deck, note)} ({where}{lock}{guard})`
	)
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

print(`\nBehind the doors in {mood} (* padlocked, n a note; up to {FloorRules.at(number).awake} awake):`)
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
