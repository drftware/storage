--!strict
-- lune run tests/chip.spec
-- Fragile finds (F-G1e5e, Finds/Chip): a find with glass cracks when it's let go running, falling
-- or from high up, never when set down standing; it cracks once; cracked, it's worth half, and
-- the oil lamp and the glass lamp are the fragile ones, each naming its glass.
local Chip = require("../src/shared/Finds/Chip")
local Rows = require("../src/shared/Finds/Rows")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local GLASS = "OilLamp_Chimney"

-- when it cracks: set down standing, never; let go at a run, at a fall, from high up, it does
ok(not Chip.hard(0, 2), "set down standing: soft")
ok(not Chip.hard(6, 2), "set down at a creep: soft")
ok(Chip.hard(16, 2), "let go at a full run: hard")
ok(Chip.hard(Chip.HardSpeed, 2), "at the speed itself: hard")
ok(Chip.hard(0, 6), "let go from high up: hard")
ok(not Chip.hard(0 / 0, 0 / 0), "a bad number is never hard")
ok(Chip.HardSpeed < 16, "a full run (Roblox's walk, 16) is always hard")
ok(Chip.HardFall > 2.5, "your hand standing (about 2 studs up) is never hard")

-- once only, and only a fragile find
ok(Chip.cracks(GLASS, false, 16, 2), "a fragile find let go running cracks")
ok(not Chip.cracks(GLASS, true, 16, 2), "a cracked one never cracks twice")
ok(not Chip.cracks(nil, false, 16, 2), "a find with no glass never cracks")
ok(not Chip.cracks("", false, 16, 2), "an empty part name never cracks")
ok(not Chip.cracks(GLASS, false, 0, 2), "set down gently, it doesn't")

-- the worth after: half, rounded down, at least 1
ok(Chip.worth(40, true) == 20, "the oil lamp cracked: 40 to 20")
ok(Chip.worth(480, true) == 240, "the glass lamp cracked: 480 to 240")
ok(Chip.worth(40, false) == 40, "uncracked: its worth")
ok(Chip.worth(5, true) == 2, "odd worth rounds down")
ok(Chip.worth(1, true) == 1, "never below 1")
ok(Chip.worth(0, true) == 0, "nothing stays nothing")

-- the fragile rows: the oil lamp and the glass lamp, each naming its own glass
local fragile: { [string]: string } = {}
for _, row in Rows do
	if row.fragile then
		fragile[row.key] = row.fragile
	end
end
ok(fragile.OilLamp == "OilLamp_Chimney", "the oil lamp's chimney is its glass")
ok(fragile.StainedGlassLamp == "StainedGlassLamp_Shade", "the glass lamp's shade is its glass")
local count = 0
for _ in fragile do
	count += 1
end
ok(count == 2, `two fragile finds ({count})`)

print(`chip.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
