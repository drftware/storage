--!strict
-- lune run tests/feedback.spec
-- How Arrange answers (S5-03j4b): every thing's weight comes from its catalog row, never its name;
-- the bands run lightest to heaviest, each landing louder, lower, dustier and firmer than the one
-- before; every find and piece has a weight in 0 to 1; and the taps are pulses a phone can play.
local Catalog = require("../src/shared/Tools/Catalog")
local Feedback = require("../src/shared/Home/Feedback")
local Furniture = require("../src/shared/Home/Furniture")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The bands climb: each takes heavier things and lands harder than the last.
local bands = Feedback.Bands
ok(#bands >= 3, "a few bands")
ok(bands[#bands].upTo == math.huge, "the last band takes everything heavier")
for i = 2, #bands do
	local a, b = bands[i - 1], bands[i]
	ok(b.upTo > a.upTo, `{b.name} takes heavier things than {a.name}`)
	ok((b.thud.pitch or 1) < (a.thud.pitch or 1), `{b.name} thuds lower than {a.name}`)
	ok(b.thud.volume > a.thud.volume, `{b.name} thuds louder than {a.name}`)
	ok(b.motes > a.motes and b.spread > a.spread, `{b.name} raises more dust than {a.name}`)
	ok(b.tap.strength >= a.tap.strength, `{b.name} taps no softer than {a.name}`)
end

-- A heft lands in the first band that takes it; the edges are the lighter band's.
ok(Feedback.band(0).name == bands[1].name, "nothing at all is the lightest band")
ok(Feedback.band(bands[1].upTo).name == bands[1].name, "a band's edge is its own")
ok(Feedback.band(bands[1].upTo + 0.001).name == bands[2].name, "just past it is the next")
ok(Feedback.band(1).name == bands[#bands].name, "the heaviest is the last band")
ok(Feedback.band(5).name == bands[#bands].name, "past 1 stays in the last band")

-- Every piece of furniture has a weight, read by its placed name.
for _, list in { Furniture.Pieces, Furniture.Starter } do
	for _, p in list do
		ok(p.heft >= 0 and p.heft <= 1, `{p.id}'s heft is 0 to 1`)
		ok(Feedback.heft(Furniture.placed(p.id)) == p.heft, `{p.id} weighs its row's heft`)
	end
end
-- The job box outweighs a blanket, so it lands in a heavier band.
local box = Feedback.landing(Furniture.placed("JobBox"))
local blanket = Feedback.landing(Furniture.placed("Blanket"))
ok(box.thud.volume > blanket.thud.volume, "the job box lands heavier than a blanket")

-- Every find weighs its catalog row's heft.
local finds = 0
for key, row in Catalog do
	if row.find then
		finds += 1
		local h = row.heft or Feedback.Unweighed
		ok(h >= 0 and h <= 1, `{key}'s heft is 0 to 1`)
		ok(Feedback.heft(key) == h, `{key} weighs its row's heft`)
	end
end
ok(finds > 0, "the catalog has finds")
-- Anything unknown lands as the middle.
ok(Feedback.heft("NoSuchThing") == Feedback.Unweighed, "an unknown thing is unweighed")

-- The taps are pulses a phone can play: a strength in 0 to 1, a few hundredths of a second.
for name, tap in Feedback.Taps do
	ok(tap.strength > 0 and tap.strength <= 1, `{name}'s strength is in 0 to 1`)
	ok(tap.length > 0 and tap.length <= 0.1, `{name} is a short pulse`)
end

-- The flight into the tray ends small and quick.
ok(Feedback.FlyEnd > 0 and Feedback.FlyEnd < 0.5, "it arrives small")
ok(Feedback.Fly > 0 and Feedback.Fly < 0.6, "it flies quickly")

print(`feedback: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
