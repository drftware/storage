--!strict
-- lune run tests/homepick.spec
-- A home's look picked and kept (S5-03g2b, Home.Looks, D-326): a new home starts in the first
-- of each list; a pick is judged against Specs.Looks (a floor colour must be the floor's own); a
-- save holding a look no longer offered falls back to the start's; and the wipe that carries a
-- new look round the room covers each wall's stretch in order, the front wall's two halves last.
local Looks = require("../src/shared/Home/Looks")
local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- A new home: warm white plaster over oak boards, whose colour is their own.
local start = Looks.start()
ok(
	start.paint == "WarmWhite" and start.paper == "Plain" and start.floor == "Boards",
	"a new home is warm white plaster on boards"
)
ok(start.floorColour == "", "the boards' colour is baked")
local walls, floor = Looks.wear(start)
ok(walls.set == "Plaster" and walls.colour == "#E8DFCF", "the walls wear warm white plaster")
ok(floor.set == "Wood" and floor.colour == "", "the floor wears the oak, untinted")

-- Picks: each kind's own ids only.
local leaves = Looks.pick(start, "paper", "Leaves")
ok(leaves ~= nil and leaves.paper == "Leaves" and leaves.paint == "WarmWhite", "paper picked")
ok(start.paper == "Plain", "a pick never changes what it was given")
ok(Looks.pick(start, "paper", "Sage") == nil, "a paint isn't a paper")
ok(Looks.pick(start, "paint", "Lavender") ~= nil, "a paint picked")
ok(Looks.pick(start, "paint", "Gold") == nil, "a paint not offered is refused")
local carpet = Looks.pick(start, "floor", "Carpet") :: Looks.Chosen
ok(
	carpet.floor == "Carpet" and carpet.floorColour == "Oatmeal",
	"a new floor takes its first colour"
)
local sage = Looks.pick(carpet, "floorColour", "Sage") :: Looks.Chosen
ok(sage.floorColour == "Sage", "a floor colour of the floor's own")
local checker = Looks.pick(sage, "floor", "Checker") :: Looks.Chosen
ok(checker.floorColour == "Sage", "sage carpet to checker keeps the sage")
local mats = Looks.pick(checker, "floor", "Matting") :: Looks.Chosen
ok(mats.floorColour == "Charcoal", "matting has no sage: its first colour")
ok(Looks.pick(mats, "floorColour", "Cherry") == nil, "cherry is the checker's, not the matting's")
ok(Looks.pick(start, "floorColour", "Oatmeal") == nil, "the boards take no colour")
local back = Looks.pick(mats, "floor", "Boards") :: Looks.Chosen
ok(back.floorColour == "", "back to boards drops the colour")
local _, matsFloor = Looks.wear(mats)
ok(matsFloor.set == "FloorMatting" and matsFloor.colour == "#3D3B39", "matting worn in charcoal")

-- The remote's ask: type and length first.
ok(Looks.ask("paper", "Leaves") == "paper", "a fair ask")
ok(Looks.ask("door", "Clay") == "door", "a door colour is a fair ask")
ok(Looks.ask("card", "Neon") == "card", "a card style is a fair ask (the pick judges it)")
ok(Looks.ask("paper", 4) == nil and Looks.ask(nil, "Leaves") == nil, "wrong types refused")
ok(Looks.ask("paper", string.rep("a", 33)) == nil and Looks.ask("paper", "") == nil, "lengths")

-- A save's look, tidied and carried on the unit.
local odd =
	Looks.tidy({ paint = "Neon", paper = "Leaves", floor = "Carpet", floorColour = "Cherry" })
ok(
	odd.paint == "WarmWhite" and odd.paper == "Leaves" and odd.floorColour == "Oatmeal",
	"a dropped paint goes back to warm white, a stray colour to the floor's first"
)
local gone = Looks.tidy({ paint = "Sage", paper = "Gone", floor = "Gone", floorColour = "Sage" })
ok(gone.paper == "Plain" and gone.floor == "Boards" and gone.floorColour == "", "dropped looks")
local text = Looks.encode(sage)
local again = Looks.decode(text) :: Looks.Chosen
ok(
	again.floor == "Carpet" and again.floorColour == "Sage" and again.paint == "WarmWhite",
	"encoded"
)
ok(Looks.decode("a|b") == nil and Looks.decode(7) == nil, "only a whole look decodes")
local wallsChanged, floorChanged = Looks.changes(start, leaves :: Looks.Chosen)
ok(wallsChanged and not floorChanged, "a paper changes the walls only")
wallsChanged, floorChanged = Looks.changes(start, carpet)
ok(floorChanged and not wallsChanged, "a floor changes the floor only")

-- The door's colour (S5-03g3a): clay to start, any of the eight, kept apart from the room's look.
ok(start.door == "Clay", "a new home's door is clay")
local mustard = Looks.pick(start, "door", "Mustard") :: Looks.Chosen
ok(mustard.door == "Mustard" and mustard.paint == start.paint, "a door colour picked")
ok(start.door == "Clay", "a door pick never changes what it was given")
ok(Looks.pick(start, "door", "Sage") == nil, "a paint isn't a door colour")
ok(Looks.pick(sage, "door", "Plum").floorColour == "Sage", "a door pick keeps the floor")
ok(Looks.doorOf("Mustard") == "#CF9F3C" and Looks.doorOf("Gone") == "#B5684E", "door hexes")
ok(Looks.tidy(table.clone(mustard)).door == "Mustard", "a door colour kept")
local lost = table.clone(mustard)
lost.door = "Gone"
ok(Looks.tidy(lost).door == "Clay", "a dropped door colour goes back to clay")
local wallsDoor, floorDoor = Looks.changes(start, mustard)
ok(not wallsDoor and not floorDoor, "a door colour changes neither the walls nor the floor")
ok(not Looks.same(start, mustard) and Looks.same(start, Looks.start()), "same looks")
ok(Looks.encode(mustard) == Looks.encode(start), "the room's look carries no door")
local withDoor = Looks.decode(Looks.encode(sage), "Plum") :: Looks.Chosen
ok(withDoor.door == "Plum" and withDoor.floorColour == "Sage", "decoded with the unit's door")
ok((Looks.decode(Looks.encode(sage)) :: Looks.Chosen).door == "Clay", "no door: clay")

-- The name card's style (S5-03g3b, D-331): the stencil to start; only Starter styles picked
-- until the counter sells the rest; apart from the room's look, as the door is.
ok(start.card == "Stencil", "a new home's card is stencilled steel")
ok(Looks.pick(start, "card", "Neon") == nil, "a Robux card isn't picked from the paint tab")
ok(Looks.pick(start, "card", "Chalk") == nil, "a cash card isn't picked before it's sold")
ok(Looks.pick(start, "card", "Mustard") == nil, "a door colour isn't a card style")
ok((Looks.pick(start, "card", "Stencil") :: Looks.Chosen).card == "Stencil", "the stencil picked")
local chalked = table.clone(start)
chalked.card = "Chalk"
ok(not Looks.same(chalked, start), "a card style tells two looks apart")
ok(Looks.tidy(table.clone(chalked)).card == "Chalk", "an owned card style kept")
local gone = table.clone(start)
gone.card = "Gone"
ok(Looks.tidy(gone).card == "Stencil", "a dropped card style goes back to the stencil")
ok(Looks.encode(chalked) == Looks.encode(start), "the room's look carries no card")
ok(
	(Looks.decode(Looks.encode(sage), "Plum", "Neon") :: Looks.Chosen).card == "Neon",
	"decoded card"
)
ok((Looks.decode(Looks.encode(sage)) :: Looks.Chosen).card == "Stencil", "no card: the stencil")
ok(Looks.cardOf("Neon") ~= nil and Looks.cardOf("Gone") == nil, "card styles by id")

-- The colour's roll down the slats (slat 1 at the foot): top first, the coil's with the top,
-- an open door's coil round from its outside wrap; every slat turned by the roll's end.
local roll = Looks.DoorRoll
ok(Looks.rollShare(30, 30, 0) == 0, "nothing turned at the start")
ok(Looks.rollShare(30, 30, roll.Fade) == 1 and Looks.rollShare(1, 30, roll.Fade) == 0, "top first")
ok(Looks.rollShare(36, 30, 0.1) == Looks.rollShare(30, 30, 0.1), "the coil turns with the top")
local mid = roll.Seconds / 2
ok(Looks.rollShare(20, 30, mid) > Looks.rollShare(10, 30, mid), "it runs down the door")
ok(Looks.rollShare(1, 0, roll.Fade) == 1 and Looks.rollShare(roll.Coil, 0, roll.Fade) == 0, "coil")
local all = true
for slat = 1, 40 do
	for _, hanging in { 0, 1, 2, 30 } do
		all = all and Looks.rollShare(slat, hanging, roll.Seconds) == 1
	end
end
ok(all, "every slat turned by the roll's end")
ok(Looks.DoorAfter > roll.Seconds, "the server paints the door after every screen's roll")

-- Every look has a swatch to wear.
for _, f in Specs.Looks.Floors do
	ok(Specs.Swatches[f.Set] ~= nil, `floor {f.Id} has a swatch`)
end
for _, p in Specs.Looks.Papers do
	ok(Specs.Swatches[p.Set] ~= nil, `paper {p.Id} has a swatch`)
end

-- The wipe: eased from nothing to the whole way, and round the room in order. A room 20 wide
-- and 30 deep: 100 studs round; the back wall -10 to 10, the right wall 10 to 40, the left
-- -40 to -10, the front wall 40 to 60 (its left half, 50 to 60, reached past the left wall).
ok(Looks.reach(0) == 0 and Looks.reach(Looks.Wipe) == 1, "a wipe runs from none to all")
ok(Looks.reach(Looks.Wipe / 2) == 0.5 and Looks.reach(Looks.Wipe * 2) == 1, "eased, then held")
local function spans(from: number, to: number, r: number): string
	local out = {}
	for _, s in Looks.covered(from, to, r, 100) do
		table.insert(out, `{s[1]}:{s[2]}`)
	end
	return table.concat(out, " ")
end
ok(spans(-10, 10, 4) == "-4:4", "the back wall first, out from its middle")
ok(spans(10, 40, 4) == "" and spans(-40, -10, 4) == "", "the side walls not yet")
ok(spans(10, 40, 25) == "10:25" and spans(-40, -10, 25) == "-25:-10", "the sides from the back")
ok(spans(40, 60, 45) == "40:45 55:60", "the front from both its corners")
ok(spans(40, 60, 50) == "40:50 50:60", "the front met at the door")
ok(spans(40, 60, 80) == "40:50 50:60", "never past the door the long way round")
ok(Looks.offset(-9.875, 4) == 1.875 and Looks.offset(8, 4) == 0, "tiles lined up from an edge")

print(`homepick.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
