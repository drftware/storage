--!strict
--[[
	Hauling a floor's big find (S4-05b2a, D-416, src/shared/Haul.luau): every big find takes both
	hands and walks under every monster's hunt and the ladder's walk, yet over a monster's walk
	going to look; it's held low enough that its top sits under your eyes; and its heavy steps
	land a stride apart, never while you stand.

		lune run tests/haul.spec
]]
local fs = require("@lune/fs")
local Catalog = require("../src/shared/Tools/Catalog")
local Haul = require("../src/shared/Haul")
local KeeperRows = require("../src/shared/KeeperRows")
local Rows = require("../src/shared/Finds/Rows")

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

local RUN = 16 -- a player's full run, studs a second: Roblox's own walk, the place's (StarterPlayer)

-- The monsters' paces: the slowest hunt, and the quickest walk going to look (arms empty).
local slowestHunt, quickestLook = math.huge, 0
for _, row in KeeperRows do
	slowestHunt = math.min(slowestHunt, row.speed * RUN)
	quickestLook = math.max(quickestLook, row.speed * row.looking * RUN)
end
ok(slowestHunt < math.huge and quickestLook > 0, "the monsters' paces read")

local art = fs.readFile("src/shared/Finds/Sets/Big.luau")
local bigs = 0
for _, row in Rows do
	if row.size ~= "Big" then
		continue
	end
	bigs += 1
	local key = row.key
	ok(Haul.big(key), `{key}: hauled`)
	local c = Catalog[key]
	ok(c ~= nil and c.bothHands == true, `{key}: both hands`)
	local walk = if c then c.walkSpeed else nil
	ok(walk ~= nil, `{key}: a walk of its own`)
	if not (c and walk) then
		continue
	end
	local ladder = assert(Catalog.Ladder.walkSpeed)
	ok(walk < slowestHunt, `{key}: slower than every monster's hunt ({walk} < {slowestHunt})`)
	ok(walk < ladder, `{key}: slower than the ladder ({walk} < {ladder})`)
	ok(walk > quickestLook, `{key}: quicker than a monster going to look ({walk} > {quickestLook})`)
	-- held low: its top under your eyes in your view (the hold's up, from the camera, plus its
	-- height over its grip), its foot under the screen
	local tall = tonumber(
		string.match(art, key .. " = {%s*Size = Vector3%.new%([%-%d%.]+, ([%-%d%.]+), [%-%d%.]+%)")
	)
	ok(tall ~= nil, `{key}: its height from its art`)
	if tall then
		local top = c.hold[2] + (tall - assert(c.grip)[2])
		ok(top < 0 and top > -0.6, `{key}: its top just under your eyes ({top} studs)`)
	end
	-- friends: hugged in front, low, its foot just off the floor (the upper torso's middle stands
	-- about 3.4 studs up on a standard body)
	local hug = assert(c.shoulder)
	local foot = 3.4 + hug[2] - assert(c.grip)[2]
	ok(hug[3] < -1.3 and foot > -0.05 and foot < 0.5, `{key}: hugged low in front ({foot} up)`)
end
ok(bigs >= 1 and Haul.big("Jukebox"), "the jukebox is hauled")
ok(not Haul.big("Boombox") and not Haul.big("Ladder"), "a boombox and the ladder aren't")

-- Steps: a stride apart, about two a second at the jukebox's walk, none standing still.
local walked, steps = 0, 0
for _ = 1, 600 do -- ten seconds at 60 a second
	local lands
	walked, lands = Haul.step(walked, 9 / 60, 9)
	if lands then
		steps += 1
	end
end
ok(steps == math.floor(90 / Haul.Stride), `ten seconds at 9 studs a second: {steps} steps`)
ok(steps / 10 >= 1.6 and steps / 10 <= 2.6, "about two steps a second: heavy, not a shuffle")
local still, landed = 0, false
for _ = 1, 600 do
	local lands
	still, lands = Haul.step(still, 0.5 / 60, 0.5)
	landed = landed or lands
end
ok(not landed and still == 0, "standing still lands no step")
local _, now = Haul.step(Haul.Stride - 0.01, 0.02, 9)
ok(now, "a step lands as a stride is walked")
ok(
	Haul.rattle(1) ~= Haul.rattle(2) and Haul.rattle(1) == Haul.rattle(#Haul.Rattles + 1),
	"rattles in turn"
)

print(`haul.spec: {checks - failures}/{checks} passed ({steps} steps in ten seconds)`)
if failures > 0 then
	error(`{failures} failed`)
end
