--!strict
-- lune run tests/boxdeal.spec
-- What comes in the marked box (B-03a, `Deal.packs`): a find or tool waits in the box when it
-- packs into one turned any way, the cardboard's `Deal.BoxWall` off every side; anything bigger
-- or longer stands loose. Checked on the rule, then on the real box and the real art's sizes, so
-- a resized find or box that moves something in or out of a box shows here.
local fs = require("@lune/fs")
local Catalog = require("../src/shared/Tools/Catalog")
local Deal = require("../src/shared/Deal")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local wall = Deal.BoxWall
local box = { 1.8, 1.6, 1.8 }

do -- the rule
	ok(Deal.packs({ 0.5, 0.5, 0.5 }, box), "a small thing packs")
	ok(Deal.packs({ 1.8 - 2 * wall, 1.6 - 2 * wall, 1.8 - 2 * wall }, box), "a snug fit packs")
	ok(not Deal.packs({ 1.8 - 2 * wall + 0.01, 0.5, 0.5 }, box), "a hair too wide stands loose")
	ok(Deal.packs({ 0.5, 1.7, 0.5 }, box), "too tall standing, it packs lying down")
	ok(Deal.packs({ 1.7, 0.4, 1.5 }, box), "any order of sizes")
	ok(not Deal.packs({ 0.3, 0.3, 2.0 }, box), "too long every way stands loose")
	ok(not Deal.packs({ 1.6, 1.6, 1.6 }, box), "fits the floor of it but not its height")
	ok(Deal.packs({ 1.5, 1.6, 1.6 }, box), "its smallest side goes up")
	ok(#box == 3 and box[1] == 1.8, "the box's sizes are left as they were")
end

-- A thing's size read from generated Specs (they build Vector3s, which Lune lacks).
local function sizes(path: string, out: { [string]: { number } })
	local text = fs.readFile(path)
	local pattern = "\n\t(%w+) = {%s*Size = Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)"
	for name, x, y, z in string.gmatch(text, pattern) do
		out[name] = { tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number }
	end
end

-- the marked box as built (art/boxes)
local boxText = fs.readFile("src/shared/Boxes/Specs.luau")
local bx, by, bz = string.match(
	boxText,
	"local Marked: Marked = {%s*Size = Vector3%.new%(([%d%.]+), ([%d%.]+), ([%d%.]+)%)"
)
local marked = { assert(tonumber(bx), "no Marked"), tonumber(by) :: number, tonumber(bz) :: number }

local art: { [string]: { number } } = {}
sizes("src/shared/Finds/Specs.luau", art)
for _, file in fs.readDir("src/shared/Finds/Sets") do
	sizes("src/shared/Finds/Sets/" .. file, art)
end

local function find(key: string): { number }
	local row = Catalog[key]
	return assert(art[row.template], `no art size for {key}`)
end
local function tool(key: string): { number }
	local text = fs.readFile(`src/shared/Tools/Specs/{key}.luau`)
	local x, y, z = string.match(
		text,
		"Bounds = {%s*Size = Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)"
	)
	if not x then
		x, y, z = string.match(
			text,
			"Body = {%s*Size = Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)"
		)
	end
	return { assert(tonumber(x), `no size for {key}`), tonumber(y) :: number, tonumber(z) :: number }
end

do -- the real box and art (sizes as built on Nov 15)
	for _, key in { "NightLight", "Teddy", "FireflyJar", "DiscoBall", "Skates", "HardHat", "RCCar" } do
		ok(Deal.packs(find(key), marked), `the {key} comes in a box`)
	end
	for _, key in { "OilLamp", "StainedGlassLamp", "UnpluggedLamp", "Television", "NeonSign" } do
		ok(not Deal.packs(find(key), marked), `the {key} stands loose`)
	end
	ok(Deal.packs(tool("Padlock"), marked), "the padlock comes in a box")
	for _, key in { "Saw", "BoltCutters", "Ladder", "BubbleWrap", "AirHorn" } do
		ok(not Deal.packs(tool(key), marked), `the {key} stands loose`)
	end
	-- every find has art to measure, so the deal can always tell
	for key, row in Catalog do
		if row.find then
			ok(art[row.template] ~= nil, `{key} has a size`)
		end
	end
end

print(`boxdeal: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
