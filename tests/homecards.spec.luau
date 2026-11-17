--!strict
-- lune run tests/homecards.spec
-- The name card's styles (S5-03g1b, Home.Specs.Cards, D-322): a home's save will keep these ids,
-- so they're unique, and the list starts with the stencil every home has; neon is the Robux one.
-- Every style's parts are in Home.fbx (Specs.Parts), each plate fits between the units' cap and
-- the deck over the door (the lobby's card middle at 11.4, so 10.3 to 13.6), stands out from the
-- wall, and its writing sits inside it. Each font is a family Studio ships (Font.fromName).
local fs = require("@lune/fs")

local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function hex(c: string?): boolean
	return c ~= nil and string.match(c, "^#%x%x%x%x%x%x$") ~= nil
end

local Cards = Specs.Cards
ok(#Cards == 4, "four styles")
ok(Cards[1].Id == "Stencil" and Cards[1].Sold == "Starter", "every home starts stencilled")

local seen: { [string]: boolean } = {}
local robux = 0
for _, c in Cards do
	ok(not seen[c.Id], `{c.Id} appears once`)
	seen[c.Id] = true
	ok(
		c.Sold == "Starter" or c.Sold == "Cash" or c.Sold == "Robux",
		`{c.Id}: sold as Starter, Cash or Robux`
	)
	if c.Sold == "Robux" then
		robux += 1
	end
	ok(hex(c.Ink), `{c.Id}: its ink is #RRGGBB`)
	ok(c.Paint == nil or hex(c.Paint), `{c.Id}: its paint is #RRGGBB or baked`)
	ok(c.Glow == nil or hex(c.Glow), `{c.Id}: its glow is #RRGGBB`)
	ok(c.Weight == "Regular" or c.Weight == "Bold", `{c.Id}: a weight Studio has on disk`)
	-- the font: a family Studio ships, so Font.fromName finds it (STUDIO.md)
	ok(string.match(c.Font, "^%a+$") ~= nil, `{c.Id}: font {c.Font} is a family name`)

	-- the plate: every part exported, inside the band over the door, out from the wall
	local lo, hi = math.huge, -math.huge
	local front = 0
	for _, name in c.Parts do
		local p = Specs.Parts[name]
		ok(p ~= nil, `{c.Id}: {name} is in Home.fbx`)
		if p then
			lo = math.min(lo, p.Centre[2] - p.Size[2] / 2)
			hi = math.max(hi, p.Centre[2] + p.Size[2] / 2)
			front = math.min(front, p.Centre[3] - p.Size[3] / 2)
			ok(p.Centre[3] + p.Size[3] / 2 <= 0.001, `{c.Id}: {name} stays in front of the wall`)
		end
	end
	ok(
		11.4 + lo >= 10.3 and 11.4 + hi <= 13.6,
		`{c.Id}: the plate fits between the cap and the deck`
	)
	ok(front < -0.1, `{c.Id}: the plate stands off the wall`)

	-- the writing: on the plate's face, inside the plate
	ok(c.Face[3] < 0 and c.Face[3] >= front - 0.01, `{c.Id}: the writing is on the plate's face`)
	ok(c.FaceSize[1] > 4 and c.FaceSize[1] < 6.4, `{c.Id}: the writing is most of the card across`)
	ok(
		c.FaceSize[2] > 0.8 and c.Face[2] - c.FaceSize[2] / 2 >= lo,
		`{c.Id}: the writing sits inside it`
	)
end
ok(robux == 1 and seen.Neon and Cards[4].Sold == "Robux", "neon is the one for Robux")
local neon = Cards[4]
ok(neon.Glow ~= nil, "neon glows")
ok(
	Specs.CardLight.Range > 4 and Specs.CardLight.Range <= 12,
	"the neon lights the wall round it, not the hall"
)

-- the bakes the plates wear: art/home/looks.py's LOOKS table
local looks = fs.readFile("art/home/looks.py")
for _, set in { "SignBoard", "Chalkboard" } do
	ok(string.find(looks, `"{set}": (`, 1, true) ~= nil, `{set} is baked`)
end

print(`homecards.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
