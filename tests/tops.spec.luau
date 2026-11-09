--!strict
-- lune run tests/tops.spec
-- The crawl along the tops (L-13b2c) on real floors: the map survives its text form; every
-- climber's lying spot (the ladder's, on both sizes) is a body that fits on the steel; crawling
-- anywhere, any way, never leaves the steel (the head only out over a unit's front, never through
-- a panel); you can crawl from one unit to the next along a run, round a junction's lid, and push
-- your head out over a front to look down; the drop off a front is smooth, goes over the edge and
-- lands you standing in the hall in under a second.
local fs = require("@lune/fs")
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
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

-- The ladder leaned on each size of unit, as Leaned.fit makes it.
local ladderText = fs.readFile("src/shared/Tools/Specs/Ladder.luau")
local _, _, feetZ = vec(ladderText, "Feet = ")
local _, boundsH = vec(ladderText, "Bounds = {%s*Size = ")
local boundsX, boundsY = vec(ladderText, "Bounds = {%s*Size = Vector3%.new%([^)]+%),%s*Centre = ")
local _, _, topZ = vec(ladderText, "Top = ")
local shape: Leaning.Shape = {
	feetZ = feetZ,
	back = boundsY - boundsH / 2,
	centreX = boundsX,
	topZ = topZ,
	travel = num(ladderText, "Travel = "),
}
local fits: { [string]: Leaning.Fit } = {}
local curtains: { [string]: number } = {}
for _, size in { "S", "M" } do
	local text = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local _, hy, hz = vec(text, "Header = { Position = ")
	local _, hh, hd = vec(text, "Header = { Position = Vector3%.new%([^)]+%), Size = ")
	local _, wy = vec(text, "Top = { Position = ")
	local _, wh = vec(text, "Top = { Position = Vector3%.new%([^)]+%), Size = ")
	curtains[size] = num(text, "CurtainPlane = ")
	fits[size] = Leaning.fit(shape, {
		edgeY = hy + hh / 2,
		faceZ = hz - hd / 2 - curtains[size],
		topY = wy + wh / 2,
		doorWidth = num(text, "DoorWidth = "),
		width = num(text, "Width = "),
	})
	-- the header stands 0.08 proud of the slot's face line: near enough to count as the same edge
	ok(
		math.abs(fits[size].faceZ + curtains[size]) < 0.1,
		`{size}: the front's face is the floor's slot face (the curtain {curtains[size]} behind it)`
	)
end

-- A unit's front frame (RollUpDoor.frame) on the floor: its origin, X along it, Z into the unit.
local function frontOf(s: Floor.Slot): (number, number, number, number, number, number)
	local fx, fz = Floor.dir(s.facing)
	local c = curtains[s.size]
	return s.x - fx * c, s.z - fz * c, -fz, fx, -fx, -fz
end
-- A front's point (lx, lz) on the floor.
local function onFloor(s: Floor.Slot, lx: number, lz: number): (number, number)
	local ox, oz, xx, xz, zx, zz = frontOf(s)
	return ox + xx * lx + zx * lz, oz + xz * lx + zz * lz
end

local function inRect(r: Tops.Rect, x: number, z: number): boolean
	return x >= r.x0 - 1e-6 and x <= r.x1 + 1e-6 and z >= r.z0 - 1e-6 and z <= r.z1 + 1e-6
end

-- A seeded walk's numbers, so a failure repeats.
local rng = Brix.Random.new({ seed = 99 })
local DT = 1 / 30

local floors, spotsChecked, walks, pairsWalked, lidsWalked, peeks = 0, 0, 0, 0, 0, 0
for seed = 1, 6 do
	for number = 1, 10 do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		floors += 1
		local tops, lips = Tops.rects(floor)
		local text = Tops.encode(tops, lips)
		local map = Tops.decode(text)
		ok(map ~= nil, `floor {number} seed {seed}: its map reads back`)
		if not map then
			continue
		end
		ok(#map.tops == #tops and #map.lips == #lips, `floor {number}: every rectangle reads back`)
		ok(#text < 60000, `floor {number}: its map fits an attribute ({#text} characters)`)

		-- each unit's footprint, to find where a body is
		local footprints: { [number]: Tops.Rect } = {}
		for i, s in floor.slots do
			if s.top then
				local size = Floor.Sizes[s.size]
				local fx, fz = Floor.dir(s.facing)
				footprints[i] = Tops.footprint(s.x, s.z, fx, fz, size.width, size.depth)
			end
		end

		local function walk(from: Tops.State, steps: number, what: string): Tops.State
			local s = from
			local mx, mz, lx, lz = 0, 0, 0, -1
			local good = true
			for n = 1, steps do
				if n % 20 == 1 then
					local a = rng:nextNumber() * 2 * math.pi
					local push = if rng:nextNumber() < 0.2 then 0 else 0.4 + rng:nextNumber() * 0.6
					mx, mz = math.cos(a) * push, math.sin(a) * push
					local b = rng:nextNumber() * 2 * math.pi
					lx, lz = math.cos(b), math.sin(b)
				end
				s = Tops.step(map, s, mx, mz, lx, lz, DT)
				if not (Tops.fits(map, s.x, s.z, s.yaw) and Tops.within(map, s.x, s.z)) then
					good = false
					break
				end
			end
			ok(good, `{what}: a random crawl stays on the steel`)
			return s
		end

		for i, s in floor.slots do
			if s.kind ~= "Unit" or not s.top then
				continue
			end
			local fit = fits[s.size]
			local fx, fz = Floor.dir(s.facing)
			local inYaw = Tops.yawOf(-fx, -fz)
			-- every climber's lying spot is a body on the steel
			for spot = 1, #fit.spots do
				local lx, _, lz = Leaning.lying(fit, spot)
				local x, z = onFloor(s, lx, lz)
				spotsChecked += 1
				ok(
					Tops.fits(map, x, z, inYaw),
					`floor {number} seed {seed} unit {s.number}: spot {spot} fits on the steel`
				)
			end
			local lx, _, lz = Leaning.lying(fit, 1)
			local x0, z0 = onFloor(s, lx, lz)
			local start: Tops.State = { x = x0, z = z0, yaw = inYaw, travel = 0 }
			-- crawl anywhere: never off the steel
			if i % 3 == 0 then
				walks += 1
				walk(start, 240, `floor {number} seed {seed} unit {s.number}`)
			end
			-- out to the front: your view (1.5 along) goes out past the edge, your root stays on
			do
				local p = start
				for _ = 1, 150 do
					p = Tops.step(map, p, fx, fz, fx, fz, DT)
				end
				local hx, hz = Tops.heading(p.yaw)
				local ex, ez = p.x + hx * 1.5, p.z + hz * 1.5
				local past = (ex - s.x) * fx + (ez - s.z) * fz
				peeks += 1
				ok(past > 0.3, `unit {s.number}: your view gets out over the front ({past})`)
				ok(Tops.within(map, p.x, p.z), `unit {s.number}: your root stays on the steel`)
			end
			-- along the run to the next slot on your left (as you face the unit)
			local left = s.left
			local leftPrint = left and footprints[left]
			if left and leftPrint and floor.slots[left].run == s.run then
				pairsWalked += 1
				local d = Floor.sideDir(s, "left")
				local dx, dz = Floor.dir(d)
				local p = start
				local reached = false
				for _ = 1, 30 * 6 do
					p = Tops.step(map, p, dx, dz, dx, dz, DT)
					if inRect(leftPrint, p.x, p.z) then
						reached = true
						break
					end
				end
				ok(
					reached,
					`floor {number} seed {seed}: unit {s.number} crawls to the slot beside it`
				)
			end
		end

		-- round a junction: from the middle of each lid, onto every top beside it
		for _, l in floor.lids do
			local size = Floor.Sizes[l.size]
			local fx, fz = Floor.dir(l.facing)
			local r = Tops.footprint(l.x, l.z, fx, fz, size.width, size.depth)
			local cx, cz = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
			for i, f in footprints do
				local touchX = (math.abs(f.x1 - r.x0) < 1e-6 or math.abs(f.x0 - r.x1) < 1e-6)
					and math.min(f.z1, r.z1) - math.max(f.z0, r.z0) >= 4
				local touchZ = (math.abs(f.z1 - r.z0) < 1e-6 or math.abs(f.z0 - r.z1) < 1e-6)
					and math.min(f.x1, r.x1) - math.max(f.x0, r.x0) >= 4
				if not (touchX or touchZ) then
					continue
				end
				lidsWalked += 1
				-- head straight across the shared edge, toward the middle of the overlap
				local tx = if touchX then (if f.x0 >= r.x1 - 1e-6 then 1 else -1) else 0
				local tz = if touchZ then (if f.z0 >= r.z1 - 1e-6 then 1 else -1) else 0
				local p: Tops.State = { x = cx, z = cz, yaw = Tops.yawOf(tx, tz), travel = 0 }
				ok(Tops.fits(map, p.x, p.z, p.yaw), `floor {number}: a body fits in a lid's middle`)
				local reached = false
				for _ = 1, 30 * 5 do
					p = Tops.step(map, p, tx, tz, tx, tz, DT)
					if inRect(f, p.x, p.z) and not inRect(r, p.x, p.z) then
						reached = true
						break
					end
				end
				ok(reached, `floor {number} seed {seed}: from a lid onto slot {i} beside it`)
			end
		end
	end
end
ok(spotsChecked > 1000 and walks > 200 and pairsWalked > 300 and lidsWalked > 50, "enough cases")

-- The crawl's speed always moves you on (never stops dead mid-pull) and averages Speed.
do
	local sum, least = 0, math.huge
	for i = 0, 99 do
		local v = Tops.surge(i / 100 * Tops.Pull)
		sum += v
		least = math.min(least, v)
	end
	ok(least > 0.3, "a pull never stops you dead")
	ok(math.abs(sum / 100 - 1) < 1e-6, "the surge averages the crawl's speed")
end

-- The drop, on an M front: smooth, over the edge, a fall, standing in the hall.
do
	local fit = fits.M
	local standUp = 3
	local last: { number }? = nil
	local maxJump, overEdge, endY, endZ, endP = 0, false, 0, 0, 0
	local t = 0
	while t <= Tops.DropSeconds + 1e-9 do
		local x, y, z, p = Tops.drop(t, 1, fit.faceZ, fit.topY, Leaning.ProneUp, standUp)
		if last then
			maxJump = math.max(maxJump, math.abs(y - last[1]) + math.abs(z - last[2]))
		end
		if y < fit.topY and z < fit.faceZ then
			overEdge = true
		end
		ok(x == 1, "the drop keeps to where along the front you went over")
		last = { y, z }
		endY, endZ, endP = y, z, p
		t += 1 / 240
	end
	ok(maxJump < 0.3, `the drop never jumps ({maxJump} studs in a frame)`)
	ok(overEdge, "below the steel only once out past the front")
	ok(math.abs(endY - standUp) < 0.05, "standing at the end")
	ok(math.abs(endZ - (fit.faceZ - Tops.Out)) < 1e-6 and endZ < fit.faceZ - 1, "out in the hall")
	ok(endP == 0, "upright at the end")
	local _, y0, z0, p0 = Tops.drop(0, 1, fit.faceZ, fit.topY, Leaning.ProneUp, standUp)
	ok(math.abs(y0 - (fit.topY + Leaning.ProneUp)) < 1e-6, "the drop starts lying on the steel")
	ok(math.abs(z0 - (fit.faceZ + Tops.EdgeIn)) < 1e-6 and p0 == -math.pi / 2, "on your belly")
	ok(Tops.DropSeconds < 1.1, "the drop is under a second and a bit")
	local cues = Tops.dropCues()
	ok(
		#cues == 2 and cues[2].at > Tops.Over and cues[2].at <= Tops.Over + Tops.Fall,
		"the landing's thud comes at the end of the fall"
	)
	ok(
		Tops.dropX(9, 12) == 6 - Tops.DropEnds and Tops.dropX(0, 8) == 0,
		"dropping clear of the posts"
	)
end

print(
	`tops: {checks - failures}/{checks} passed ({floors} floors, {spotsChecked} spots, {walks} walks, {pairsWalked} unit to unit, {lidsWalked} round lids, {peeks} peeks)`
)
if failures > 0 then
	error(`{failures} failed`)
end
