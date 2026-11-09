--!strict
-- lune run tests/leaning.spec
-- The ladder leaned on a unit's front and climbed (L-13b2a), on both unit sizes with the real
-- ladder's and units' numbers: it stands at the 4-to-1 rule with its feet on the floor and its back
-- on the top edge, beside the door, reaching past the edge only once its fly is out, under the
-- deck; every climber's lying spot is on the steel top inside the walls and under the deck; the
-- climb up and the climb down are smooth (no jumps), go the right way, start and end where they
-- should, and take about two seconds; raising it swings, then runs out; the sounds come in order.
local fs = require("@lune/fs")
local Leaning = require("../src/shared/Tools/Leaning")
local Tops = require("../src/shared/Tops")

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
local function near(a: number, b: number, by: number?): boolean
	return math.abs(a - b) < (by or 1e-6)
end

-- Numbers read from the generated Specs (they build Vector3s, which Lune lacks).
local function vec(text: string, pattern: string): (number, number, number)
	local x, y, z =
		string.match(text, pattern .. "Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)")
	assert(x and y and z, "no " .. pattern)
	return tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number
end
local function num(text: string, pattern: string): number
	local v = string.match(text, pattern .. "([%-%d%.]+)")
	assert(v, "no " .. pattern)
	return tonumber(v) :: number
end

local ladderText = fs.readFile("src/shared/Tools/Specs/Ladder.luau")
local _, _, feetZ = vec(ladderText, "Feet = ")
local _, boundsH = vec(ladderText, "Bounds = {%s*Size = ")
local boundsX, boundsY = vec(ladderText, "Bounds = {%s*Size = Vector3%.new%([^)]+%),%s*Centre = ")
local _, _, topZ = vec(ladderText, "Top = ")
local travel = num(ladderText, "Travel = ")
local ladderWidth = vec(ladderText, "Bounds = {%s*Size = ")
local shape: Leaning.Shape = {
	feetZ = feetZ,
	back = boundsY - boundsH / 2,
	centreX = boundsX,
	topZ = topZ,
	travel = travel,
}
local deck = num(fs.readFile("src/shared/CorridorKit/Specs.luau"), "DeckHeight = ")

local STAND_UP = 3 -- R15's default: hip height 2, half its root

-- A sawn top's hole (L-13b2d2c): its half width across, and how far out a lying root must be to
-- clear it (as Leaned.holeClear: the hole, the body's widest half, a hair).
local holeText = fs.readFile("src/shared/StorageUnit/TopHole/Specs.luau")
local holeRight = num(holeText, "\n\tRight = ")
local widest = 0
for _, p in Tops.Body do
	widest = math.max(widest, p.half)
end
local HOLE_CLEAR = holeRight + widest + 0.05
local STEP = 1 / 240

for _, size in { "S", "M" } do
	local text = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local curtain = num(text, "CurtainPlane = ")
	local width = num(text, "Width = ")
	local depth = num(text, "Depth = ")
	local doorWidth = num(text, "DoorWidth = ")
	local _, hy, hz = vec(text, "Header = { Position = ")
	local _, hh, hd = vec(text, "Header = { Position = Vector3%.new%([^)]+%), Size = ")
	local _, wy = vec(text, "Top = { Position = ")
	local _, wh = vec(text, "Top = { Position = Vector3%.new%([^)]+%), Size = ")
	local front: Leaning.Front = {
		edgeY = hy + hh / 2,
		faceZ = hz - hd / 2 - curtain,
		topY = wy + wh / 2,
		doorWidth = doorWidth,
		width = width,
		clear = HOLE_CLEAR,
	}
	local fit = Leaning.fit(shape, front)
	local s = math.sin(Leaning.Angle)

	-- standing
	local _, fy, fz = Leaning.point(fit, shape.centreX, 0, shape.feetZ)
	ok(near(fy, 0, 1e-4), `{size}: the feet on the floor`)
	local _, ey, ez = Leaning.point(fit, shape.centreX, shape.back, fit.contact)
	ok(near(ey, front.edgeY, 1e-4) and near(ez, front.faceZ, 1e-4), `{size}: its back on the edge`)
	local out = front.faceZ - fz
	ok(
		near(out, front.edgeY / Leaning.Ratio, 0.5),
		`{size}: the feet a quarter of the height out ({out})`
	)
	ok(out > 1.5 and out < 4, `{size}: the feet in the hall, room to pass them`)
	ok(fit.reach < fit.contact - 1, `{size}: run out, it reaches a stud past the edge`)
	ok(shape.topZ > fit.contact, `{size}: collapsed, it doesn't reach the edge`)
	local _, topY = Leaning.point(fit, shape.centreX, 0, fit.reach)
	ok(topY < deck - 1, `{size}: its top under the deck ({topY})`)
	ok(
		math.abs(fit.leanX) + ladderWidth / 2 <= width / 2,
		`{size}: the ladder inside the unit's width`
	)
	ok(fit.leanX - ladderWidth / 2 > 0, `{size}: beside the door, its middle clear`)
	ok(fit.leanX > 0 and fit.leanX < doorWidth / 2, `{size}: beside the door's edge`)

	-- the spots on the top
	ok(
		#fit.spots >= (if size == "S" then 3 else 4),
		`{size}: a team fits on the top ({#fit.spots})`
	)
	ok(
		near(fit.spots[1], fit.leanX, 0.3) and fit.spots[1] >= fit.leanX,
		`{size}: the first climber lies by the ladder ({fit.spots[1]}, the ladder {fit.leanX})`
	)
	ok(
		fit.spots[1] - widest >= holeRight,
		`{size}: the first climber's body clear of a sawn top's hole ({fit.spots[1]})`
	)
	for i, x in fit.spots do
		ok(math.abs(x) + 1 <= width / 2, `{size}: spot {i} inside the side walls`)
		if i > 1 then
			ok(fit.spots[i - 1] - x >= 2, `{size}: spot {i} a body from the last`)
		end
		local lx, ly, lz, lp = Leaning.lying(fit, i)
		ok(near(lx, x) and near(lp, -math.pi / 2), `{size}: spot {i} flat on the belly`)
		ok(near(ly - front.topY, Leaning.ProneUp), `{size}: spot {i} on the top`)
		ok(ly + 0.6 < deck - 2, `{size}: spot {i} well under the deck`)
		ok(lz - 3 > front.faceZ, `{size}: spot {i}'s feet on the top`)
		ok(lz + 2.3 < depth - curtain - 0.3, `{size}: spot {i}'s head inside the back wall`)
	end

	-- the climb up
	local foot, top = Leaning.span(fit, STAND_UP)
	ok(foot > top, `{size}: the top is up the ladder from the foot`)
	local up = Leaning.upSeconds(fit, STAND_UP)
	ok(up > 1.5 and up < 2.5, `{size}: up in about two seconds ({up})`)
	ok(Leaning.upBusy(fit, STAND_UP) < up, `{size}: the ladder free before you've rolled over`)
	local _, _, _, _, b0 = Leaning.up(0, fit, 1, STAND_UP)
	local _, _, _, _, b1 = Leaning.up(Leaning.Mount, fit, 1, STAND_UP)
	ok(near(b0, 0) and near(b1, 1), `{size}: onto the ladder from where you stood`)
	local _, sy = Leaning.up(Leaning.Mount, fit, 1, STAND_UP)
	ok(near(sy, STAND_UP, 1e-4), `{size}: on the ladder's foot at standing height`)
	for spot = 1, #fit.spots do
		local px, py, pz, pp = Leaning.up(Leaning.Mount, fit, spot, STAND_UP)
		local jumps, downs, header = 0, 0, 0
		local climbEnd = Leaning.upBusy(fit, STAND_UP)
		local t = Leaning.Mount + STEP
		while t <= up + 1e-9 do
			local x, y, z, p = Leaning.up(t, fit, spot, STAND_UP)
			local d = math.sqrt((x - px) ^ 2 + (y - py) ^ 2 + (z - pz) ^ 2)
			if d > 0.2 or math.abs(p - pp) > 0.05 then
				jumps += 1
			end
			if t < climbEnd and y < py - 1e-9 then
				downs += 1
			end
			if z > front.faceZ - 0.3 and z < front.faceZ + hd + 0.3 and y < front.edgeY + 0.3 then
				header += 1
			end
			px, py, pz, pp = x, y, z, p
			t += STEP
		end
		ok(jumps == 0, `{size} spot {spot}: up without a jump ({jumps})`)
		ok(downs == 0, `{size} spot {spot}: always up the rungs ({downs})`)
		ok(header == 0, `{size} spot {spot}: over the edge, never through it ({header})`)
		local ex, ey2, ez2, ep = Leaning.up(up, fit, spot, STAND_UP)
		local lx, ly, lz, lp = Leaning.lying(fit, spot)
		ok(
			near(ex, lx, 1e-3)
				and near(ey2, ly, 1e-3)
				and near(ez2, lz, 1e-3)
				and near(ep, lp, 1e-3),
			`{size} spot {spot}: the climb ends lying in the spot`
		)

		-- the climb down
		local down = Leaning.downSeconds(fit, STAND_UP)
		ok(down > 1.2 and down < 2.2, `{size}: down in under two seconds ({down})`)
		local dx, dy, dz, dp = Leaning.down(0, fit, spot, STAND_UP)
		ok(
			near(dx, lx, 1e-3) and near(dy, ly, 1e-3) and near(dz, lz, 1e-3) and near(dp, lp, 1e-3),
			`{size} spot {spot}: the climb down starts where you lie`
		)
		local djumps = 0
		t = STEP
		while t <= down + 1e-9 do
			local x, y, z, p = Leaning.down(t, fit, spot, STAND_UP)
			local d = math.sqrt((x - dx) ^ 2 + (y - dy) ^ 2 + (z - dz) ^ 2)
			if d > 0.2 or math.abs(p - dp) > 0.05 then
				djumps += 1
			end
			dx, dy, dz, dp = x, y, z, p
			t += STEP
		end
		ok(djumps == 0, `{size} spot {spot}: down without a jump ({djumps})`)
		local sx, sy2, sz, sp = Leaning.stood(fit, STAND_UP)
		local fx2, fy2, fz2, fp2 = Leaning.down(down, fit, spot, STAND_UP)
		ok(
			near(fx2, sx, 1e-3)
				and near(fy2, sy2, 1e-3)
				and near(fz2, sz, 1e-3)
				and near(fp2, sp, 1e-3),
			`{size} spot {spot}: the climb down ends standing in the hall`
		)
		ok(near(sy2, STAND_UP) and near(sp, 0), `{size}: standing upright after`)
		ok(sz < fz and sz > front.faceZ - 7, `{size}: a step back from the feet, still in the hall`)
	end
	-- the climber on the rungs: just in front of them, leaned with the ladder
	local _, _, z1 = Leaning.onLadder(fit, foot)
	local _, _, z2 = Leaning.point(fit, shape.centreX, 0, foot)
	ok(near(z2 - z1, Leaning.Off * s, 1e-4), `{size}: the climber in front of the rungs`)
end

-- raising it
local r0, f0 = Leaning.raise(0)
local r1, f1 = Leaning.raise(Leaning.Swing)
local r2, f2 = Leaning.raise(Leaning.Raised)
ok(near(r0, 0) and near(f0, 0), "raising: starts on the shoulder, collapsed")
ok(near(r1, 1) and near(f1, 0), "raising: against the front before the fly moves")
ok(near(r2, 1) and near(f2, 1), "raising: the fly all the way out at the end")
local lastR, lastF = 0, 0
local t = 0
local backwards = 0
while t <= Leaning.Raised do
	local r, f = Leaning.raise(t)
	if r < lastR - 1e-9 or f < lastF - 1e-9 then
		backwards += 1
	end
	lastR, lastF = r, f
	t += STEP
end
ok(backwards == 0, "raising: never goes back")
ok(Leaning.Raised < 1.2, "raising: up in about a second")

-- the sounds
local raiseCues = Leaning.raiseCues()
for i = 2, #raiseCues do
	ok(raiseCues[i].at >= raiseCues[i - 1].at, "raising: cues in order")
end
ok(raiseCues[#raiseCues].at <= Leaning.Raised + 1e-9, "raising: the locks catch as it stops")
do
	local text = fs.readFile("src/shared/StorageUnit/Specs/M.luau")
	local _, hy = vec(text, "Header = { Position = ")
	local _, hh = vec(text, "Header = { Position = Vector3%.new%([^)]+%), Size = ")
	local _, wy = vec(text, "Top = { Position = ")
	local _, wh = vec(text, "Top = { Position = Vector3%.new%([^)]+%), Size = ")
	local fit = Leaning.fit(shape, {
		edgeY = hy + hh / 2,
		faceZ = -0.63,
		topY = wy + wh / 2,
		doorWidth = num(text, "DoorWidth = "),
		width = num(text, "Width = "),
	})
	local upCues = Leaning.cues("Up", fit, STAND_UP)
	local busy = Leaning.upBusy(fit, STAND_UP)
	ok(upCues[1].at < Leaning.Mount, "up: the rungs sound as you get on")
	local landing = upCues[#upCues]
	ok(landing.sound == Leaning.Sounds.Steel, "up: the steel last")
	ok(landing.at > busy and landing.at < busy + Leaning.Roll, "up: the steel as you land on it")
	ok(landing.kick > 0, "up: landing jolts your view")
	local downCues = Leaning.cues("Down", fit, STAND_UP)
	ok(
		downCues[1].at == 0 and downCues[1].sound == Leaning.Sounds.Shift,
		"down: the steel gives first"
	)
	for _, cue in downCues do
		ok(cue.kick == 0, "down: no jolts")
	end
	ok(near(Leaning.arms("Top", 5, fit, STAND_UP), 1), "arms: lying, reaching ahead")
	ok(near(Leaning.arms("Up", 0, fit, STAND_UP), 0), "arms: climbing, the animation's")
	ok(
		near(Leaning.arms("Down", Leaning.Slide, fit, STAND_UP), 0),
		"arms: back on the ladder, the animation's"
	)
	for _, snd in Leaning.Sounds do
		ok(
			snd.from >= 0 and snd.length > 0 and snd.reach > snd.near,
			"a sound's stretch and reach make sense"
		)
	end
end

print(`leaning: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
