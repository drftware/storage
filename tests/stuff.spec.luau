--!strict
-- lune run tests/stuff.spec
-- The things to look at (S1-04b1): every piece and stack fits a small unit's floor and stands
-- under its bulb, and every stack's box is a moving box the place has (art/boxes). The art's own
-- spec checks that each box stands on the floor or square on the one below it.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

-- The generated Specs build Vector3s, which Lune lacks as a global: load them with Lune's own.
local function load(path: string): any -- any: a generated table, read field by field below
	return luau.load(fs.readFile(path), {
		environment = {
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Vector2 = roblox.Vector2,
		},
	})()
end

local BoxSpecs = load("src/shared/Boxes/Specs.luau")
local Small = load("src/shared/StorageUnit/Specs/S.luau")
local Specs = load("src/shared/Stuff/Specs.luau")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The bulb hangs a little under the steel top; nothing reaches it.
local UNDER_BULB = Small.WallHeight - 1.2

local function fits(name: string, size: Vector3)
	ok(size.X > 0 and size.Y > 0 and size.Z > 0, `{name} has a size`)
	ok(
		size.X <= Small.Width - 0.5 and size.Z <= Small.Depth - 0.5,
		`{name} fits a small unit's floor`
	)
	ok(size.Y <= UNDER_BULB, `{name} stands under the bulb`)
end

for _, name in Specs.PieceOrder do
	local piece = Specs.Pieces[name]
	ok(piece ~= nil, `{name} is a piece`)
	if piece then
		fits(name, piece.Size)
		ok(
			piece.Triangles <= 1000,
			`{name} is light enough for a phone ({piece.Triangles} triangles)`
		)
	end
end

for _, name in Specs.StackOrder do
	local stack = Specs.Stacks[name]
	ok(stack ~= nil, `{name} is a stack`)
	if stack then
		fits(name, stack.Size)
		ok(#stack.Boxes >= 2, `{name} is boxes on boxes`)
		for i, row in stack.Boxes do
			local box = BoxSpecs.Boxes[row.Box]
			ok(box ~= nil, `{name} box {i} is a moving box ({row.Box})`)
			if box then
				local top = row.Position.Y + box.Size.Y
				ok(top <= stack.Size.Y + 1e-3, `{name} box {i} is inside the stack's height`)
				ok(
					math.abs(row.Position.X) <= stack.Size.X / 2
						and math.abs(row.Position.Z) <= stack.Size.Z / 2,
					`{name} box {i} stands within the stack's footprint`
				)
			end
		end
	end
end

print(`stuff: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
