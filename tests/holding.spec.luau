--!strict
-- lune run tests/holding.spec
local Holding = require("../src/shared/Home/Holding")
local Specs = require("../src/shared/Lobby/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local order = Holding.order(Specs.Slots, Specs.Spawn)
ok(#order == 12, "every home is handed out")
ok(
	table.concat(order, ",", 1, 4) == "Unit1,Unit7,Unit2,Unit8",
	"nearest the front door first, left before right"
)
ok(order[12] == "Unit12", "the far right home last")
ok(Holding.number("Unit7") == 7 and Holding.number("Bay1") == nil, "a plot's slot number")
ok(Holding.words("  sam ") == "SAM", "a name in the building's capitals")
ok(Holding.words(string.rep("a", 30)) == string.rep("A", Holding.MostLetters), "a name cut to fit")

print(string.format("holding: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("holding spec failed")
end
