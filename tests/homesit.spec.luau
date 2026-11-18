--!strict
-- lune run tests/homesit.spec
-- Sit on the furniture (S5-03i4, D-353): the crate, the beanbag, the blanket and the camp bed each
-- have seats; every seat lies inside its piece's box, at or over its top and under the piece's
-- highest point, facing out its front; the bed seats two side by side, clear of its pillow; the
-- blanket is the one you sit on cross-legged; every seat's landing has a sound.
local Sit = require("../src/shared/Home/Sit")
local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- A piece's half width, top and half depth from its parts' boxes, in its frame.
local function box(kind: string): (number, number, number)
	local hx, top, hz = 0, 0, 0
	for _, name in Specs.Pieces[kind] do
		local p = Specs.Parts[name]
		hx = math.max(hx, math.abs(p.Centre[1]) + p.Size[1] / 2)
		top = math.max(top, p.Centre[2] + p.Size[2] / 2)
		hz = math.max(hz, math.abs(p.Centre[3]) + p.Size[3] / 2)
	end
	return hx, top, hz
end

for _, kind in { "MilkCrate", "Beanbag", "Blanket", "CampBed" } do
	local seats = Sit.Seats[kind]
	ok(seats ~= nil and #seats > 0, `{kind} has a seat`)
	local hx, highest, hz = box(kind)
	local tops = Specs.Tops[kind]
	for i, s in seats or {} do
		ok(math.abs(s.x) <= hx and math.abs(s.z) <= hz, `{kind} seat {i} is on the piece`)
		ok(s.top <= highest + 0.01, `{kind} seat {i} is under the piece's top`)
		if tops then
			ok(s.top >= tops[1].At[2] - 0.01, `{kind} seat {i} is at or over its top`)
		end
		ok(s.turn == 0, `{kind} seat {i} faces out its front`)
		ok(Sit.Sounds[s.sound] ~= nil, `{kind} seat {i} sounds as you land`)
		ok(s.squash >= 0 and s.squash < 0.5, `{kind} seat {i} gives a little or not at all`)
		if s.give then
			ok(table.find(Specs.Pieces[kind], s.give) ~= nil, `{kind} seat {i} gives its own part`)
		end
		ok(Sit.row(kind, i) == s, `{kind} seat {i} is found by its index`)
	end
end

-- The crate is hard: no give. A seat's height keeps your feet on the floor (homefurniture's
-- bounds for the crate); the bed's edge sits a little under the crate, the beanbag lower still.
local crate = Sit.Seats.MilkCrate[1]
ok(crate.give == nil and crate.squash == 0 and crate.sound == "Wood", "the crate is wood")
local bed = Sit.Seats.CampBed
ok(#bed == 2, "the camp bed seats two")
ok(math.abs(bed[1].x - bed[2].x) >= 1.9, "the two on the bed sit shoulder to shoulder")
ok(bed[1].top > 1.3 and bed[1].top < crate.top, "the bed's edge is a seat's height")
local pillow = Specs.Parts.CampBedPillow
local pillowEnd = pillow.Centre[1] + pillow.Size[1] / 2
ok(math.min(bed[1].x, bed[2].x) - 0.5 > pillowEnd, "nobody sits on the pillow")
ok(bed[1].z < 0 and bed[2].z < 0, "the bed's seats are along its front")
ok(Sit.Seats.Beanbag[1].top < bed[1].top, "the beanbag sinks you lower")

-- Cross-legged on the blanket, and only there.
ok(Sit.Seats.Blanket[1].pose == "Floor", "on the blanket you sit cross-legged")
for _, kind in { "MilkCrate", "Beanbag", "CampBed" } do
	for i, s in Sit.Seats[kind] do
		ok(s.pose == "Chair", `{kind} seat {i} is a chair's sit`)
	end
end
ok(Sit.row("Rug", 1) == nil and Sit.row("MilkCrate", 2) == nil, "no seat where there's none")
ok(Sit.Up > 0 and Sit.Up < 1, "getting up is softer than landing")

print(`homesit: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
