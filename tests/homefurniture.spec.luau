--!strict
-- lune run tests/homefurniture.spec
-- The counter's furniture, part one (S5-03g1c1, Home.Specs.Tops, D-323): every new piece's parts
-- are in Home.fbx; the crate's top is a seat (a little under the bench's 1.7, high enough that a
-- sitting avatar's feet stay on the floor), the pallets' top a coffee table's under it, the folding
-- table's a table's over it; the steel shelf's four tiers leave a find's room (1.7) between them;
-- each top lies on its piece, inside its parts' boxes.
local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function box(kind: string): (number, number, number, number)
	local hx, top, hz = 0, 0, 0
	for _, name in Specs.Pieces[kind] do
		local p = Specs.Parts[name]
		ok(p ~= nil, `{kind}: {name} is in Home.fbx`)
		if p then
			hx = math.max(hx, math.abs(p.Centre[1]) + p.Size[1] / 2)
			top = math.max(top, p.Centre[2] + p.Size[2] / 2)
			hz = math.max(hz, math.abs(p.Centre[3]) + p.Size[3] / 2)
		end
	end
	return hx, top, hz, 0
end

for _, kind in { "MilkCrate", "Pallet", "FoldingTable", "SteelShelf" } do
	ok(Specs.Pieces[kind] ~= nil, `{kind} is a piece`)
	local tops = Specs.Tops[kind]
	ok(tops ~= nil and #tops > 0, `{kind} has a top`)
	local hx, top, hz = box(kind)
	for i, t in tops or {} do
		ok(t.At[2] <= top + 0.01, `{kind} top {i} is on the piece`)
		ok(t.Size[1] / 2 <= hx + 0.01 and t.Size[2] / 2 <= hz + 0.01, `{kind} top {i} fits it`)
	end
end

local function height(kind: string, i: number?): number
	return Specs.Tops[kind][i or 1].At[2]
end
ok(height("MilkCrate") >= 1.5 and height("MilkCrate") <= 1.75, "the crate is a seat")
ok(height("Pallet") < height("MilkCrate"), "the coffee table is under the seat")
ok(height("FoldingTable") > height("MilkCrate") + 0.8, "the folding table is a table")
local tiers = Specs.Tops.SteelShelf
ok(#tiers == 4, "the steel shelf has four tiers")
for i = 2, #tiers do
	ok(tiers[i].At[2] - tiers[i - 1].At[2] >= 1.7, `tier {i} leaves a find's room under it`)
end

print(`homefurniture: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
