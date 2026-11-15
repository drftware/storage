--!strict
-- lune run tests/packed.spec
-- The packed unit's stacks (B-05a): every block stands under a medium unit's steel top, side by
-- side at the kit's pitch without two neighbours' boxes running into each other, its front on its
-- front line (a box a hair proud or sunk, never more), and cheap enough for a unit full of them.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

-- The generated Specs build Vector3s, which Lune lacks as a global: load them with Lune's own.
local function load(path: string): any -- any: a generated table, read field by field below
	return luau.load(fs.readFile(path), {
		environment = { Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame },
	})()
end

local Specs = load("src/shared/Packed/Specs.luau")
local Medium = load("src/shared/StorageUnit/Specs/M.luau")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- A box may sit this far proud of (or sunk behind) its block's front line, askew corners and all.
local PROUD = 0.15
-- Triangles a block may cost: a medium unit packed full is about twenty blocks.
local MOST_TRIS = 400

ok(Specs.Ceiling == Medium.WallHeight, "the kit's ceiling is the unit's steel top")
ok(#Specs.Order == 7, "seven blocks")
for _, name in Specs.Order do
	local b = Specs.Blocks[name]
	ok(b ~= nil, `{name} has a row`)
	if b then
		ok(b.Tall <= Specs.Ceiling - 0.3, `{name} stops short of the steel top ({b.Tall})`)
		ok(b.Lo.Y >= -0.001 and math.abs(b.Hi.Y - b.Tall) < 0.01, `{name} stands on the floor`)
		ok(b.Tris > 0 and b.Tris <= MOST_TRIS, `{name} is cheap ({b.Tris} triangles)`)
		ok(-b.Lo.Z <= b.Depth / 2 + PROUD, `{name}'s front stays on its line ({-b.Lo.Z})`)
		if b.Kind ~= "Toppled" then
			-- Stood side by side at their widths, two blocks' boxes never meet.
			ok(b.Hi.X - b.Lo.X <= b.Width + 0.01, `{name} keeps within its width`)
			ok(-b.Lo.X <= b.Width / 2 + 0.01 and b.Hi.X <= b.Width / 2 + 0.01, `{name} is centred`)
		end
		if b.Kind == "Column" or b.Kind == "Wide" then
			ok(b.Tall >= Specs.Ceiling - 1.3, `{name} reaches near the ceiling ({b.Tall})`)
		end
	end
end
ok(Specs.Blocks.ColumnA.Width == Specs.Pitch, "a column is one pitch wide")
ok(Specs.Blocks.WideA.Width == 2 * Specs.Pitch, "a wide block is two")

print(`packed: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} packed check(s) failed`)
end
