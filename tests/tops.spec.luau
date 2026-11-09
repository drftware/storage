--!strict
-- lune run tests/tops.spec
-- The crawl along the tops (L-13b2c) on real floors: the map survives its text form; every
-- climber's lying spot (the ladder's, on both sizes) is a body that fits on the steel; crawling
-- anywhere, any way, never leaves the steel (the head only out over a unit's front, never through
-- a panel); you can crawl from one unit to the next along a run, round a junction's lid, and push
-- your head out over a front to look down; the drop off a front is smooth, goes over the edge and
-- lands you standing in the hall in under a second. A top sawn through (L-13b2d2c) comes off the
-- map: nobody's body goes over its hole, the head may, you can't crawl across it, a body lying
-- on it as it goes through is slid off its edge, and the ladder's spots on it or past it are out
-- while the one by the ladder always stays.
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
-- A sawn top's hole, in its hole frame (TopHole): across from the unit's middle, back from the
-- first channel, which is `Channel` back from the slot's face.
local holeText = fs.readFile("src/shared/StorageUnit/TopHole/Specs.luau")
local hole = {
	left = num(holeText, "\n\tLeft = "),
	right = num(holeText, "\n\tRight = "),
	front = num(holeText, "\n\tFront = "),
	back = num(holeText, "\n\tBack = "),
}
local channels = { M = num(holeText, "\n\t\tM = "), S = num(holeText, "\n\t\tS = ") }
local widest = 0
for _, p in Tops.Body do
	widest = math.max(widest, p.half)
end

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
		clear = hole.right + widest + 0.05, -- as Leaned.holeClear
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

-- A slot's sawn hole on the floor: the hole frame's numbers through the front's frame, which
-- starts a curtain in from the slot's face.
local function holeOf(s: Floor.Slot): Tops.Rect
	local c, ch = curtains[s.size], channels[s.size]
	local ax, az = onFloor(s, hole.left, ch + hole.front - c)
	local bx, bz = onFloor(s, hole.right, ch + hole.back - c)
	return {
		x0 = math.min(ax, bx),
		x1 = math.max(ax, bx),
		z0 = math.min(az, bz),
		z1 = math.max(az, bz),
	}
end

-- Whether a body's middle or feet (what must stay on the steel) reach into a hole: the squares'
-- true overlap with the holes, worked out here, not through the map's corner checks. Pass the
-- holes as the map has them (to a thousandth of a stud).
local function bodyInHole(holes: { Tops.Rect }, x: number, z: number, yaw: number): boolean
	local hx, hz = Tops.heading(yaw)
	for _, p in Tops.Body do
		if p.peek then
			continue
		end
		local px, pz, h = x + hx * p.along, z + hz * p.along, p.half
		for _, r in holes do
			if
				px + h > r.x0 + 1e-6
				and px - h < r.x1 - 1e-6
				and pz + h > r.z0 + 1e-6
				and pz - h < r.z1 - 1e-6
			then
				return true
			end
		end
	end
	return false
end

-- A seeded walk's numbers, so a failure repeats.
local rng = Brix.Random.new({ seed = 99 })
local DT = 1 / 30

local floors, spotsChecked, walks, pairsWalked, lidsWalked, peeks = 0, 0, 0, 0, 0, 0
local holesCut, holeWalks, slides = 0, 0, 0
-- whether each size's ladder spot is offered on a sawn top: the same on every unit of a size
local offeredBySize: { [string]: { [number]: boolean } } = { S = {}, M = {} }
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

		-- every other unit's top sawn through: its hole off the map
		local holes: { Tops.Rect } = {}
		local holed: { [number]: Tops.Rect } = {}
		for i, s in floor.slots do
			if s.kind == "Unit" and s.top and i % 2 == 0 then
				local r = holeOf(s)
				table.insert(holes, r)
				holed[i] = r
			end
		end
		local hmap = Tops.decode(Tops.encode(tops, lips, holes))
		ok(hmap ~= nil and #hmap.holes == #holes, `floor {number} seed {seed}: its holes read back`)
		if not hmap then
			continue
		end
		local function walkHoled(from: Tops.State, steps: number, what: string)
			local s = from
			local mx, mz, lx, lz = 0, 0, 0, -1
			for n = 1, steps do
				if n % 20 == 1 then
					local a = rng:nextNumber() * 2 * math.pi
					mx, mz = math.cos(a), math.sin(a)
					local b = rng:nextNumber() * 2 * math.pi
					lx, lz = math.cos(b), math.sin(b)
				end
				s = Tops.step(hmap, s, mx, mz, lx, lz, DT)
				if
					bodyInHole(hmap.holes, s.x, s.z, s.yaw) or not Tops.fits(hmap, s.x, s.z, s.yaw)
				then
					ok(false, `{what}: a random crawl by a hole never goes over it`)
					return
				end
			end
		end
		for i, s in floor.slots do
			if s.kind ~= "Unit" or not s.top then
				continue
			end
			local fit = fits[s.size]
			local fx, fz = Floor.dir(s.facing)
			local inYaw = Tops.yawOf(-fx, -fz)
			local r = holed[i]
			local what = `floor {number} seed {seed} unit {s.number} ({s.size})`
			if not r then
				-- a unit beside a sawn one keeps every spot
				for spot = 1, #fit.spots do
					local lx, _, lz = Leaning.lying(fit, spot)
					local x, z = onFloor(s, lx, lz)
					ok(Tops.fits(hmap, x, z, inYaw), `{what}: spot {spot} untouched by a hole`)
				end
				continue
			end
			holesCut += 1
			local foot = footprints[i]
			ok(
				foot ~= nil and inRect(foot, r.x0, r.z0) and inRect(foot, r.x1, r.z1),
				`{what}: its hole in its own top`
			)

			-- the ladder's spots: out if on the hole or rolled onto past it; the first always in
			local _, topAlong = Leaning.span(fit, 0)
			local ax, _, az = Leaning.onLadder(fit, topAlong)
			local lax, laz = onFloor(s, ax, az)
			for spot = 1, #fit.spots do
				local lx, _, lz = Leaning.lying(fit, spot)
				local x, z = onFloor(s, lx, lz)
				local offered = Tops.fits(hmap, x, z, inYaw)
					and Tops.pathClear(hmap, lax, laz, x, z, inYaw)
				if spot == 1 then
					ok(offered, `{what}: the spot by the ladder stays`)
				end
				if bodyInHole(hmap.holes, x, z, inYaw) then
					ok(not offered, `{what}: spot {spot}, on the hole, is out`)
				end
				local before = offeredBySize[s.size][spot]
				ok(before == nil or before == offered, `{what}: spot {spot} as on every {s.size}`)
				offeredBySize[s.size][spot] = offered
			end

			-- from behind the hole, push for the hall: your head goes out over it to look down,
			-- your body stays on the steel and never gets past it
			local behind = channels[s.size] + hole.back + 0.95 -- studs in from the slot's face
			local bx, bz = onFloor(s, 0, behind - curtains[s.size])
			local outYaw = Tops.yawOf(fx, fz)
			local p: Tops.State = { x = bx, z = bz, yaw = outYaw, travel = 0 }
			ok(Tops.fits(hmap, p.x, p.z, p.yaw), `{what}: a body fits behind the hole`)
			local stayed = true
			for _ = 1, 30 * 5 do
				p = Tops.step(hmap, p, fx, fz, fx, fz, DT)
				local inward = -((p.x - s.x) * fx + (p.z - s.z) * fz)
				if bodyInHole(hmap.holes, p.x, p.z, p.yaw) or inward < behind - 0.05 then
					stayed = false
					break
				end
			end
			ok(stayed, `{what}: pushing at the hole, you can't crawl over it`)
			local hx, hz = Tops.heading(p.yaw)
			local vx, vz = p.x + hx * 1.5, p.z + hz * 1.5
			peeks += 1
			ok(
				vx > r.x0 and vx < r.x1 and vz > r.z0 and vz < r.z1,
				`{what}: your view out over the hole, to look down into the unit`
			)
			if i % 4 == 0 then
				holeWalks += 1
				walkHoled(p, 240, what)
				local lx, _, lz = Leaning.lying(fit, 1)
				local x1, z1 = onFloor(s, lx, lz)
				walkHoled({ x = x1, z = z1, yaw = inYaw, travel = 0 }, 240, what)
			end

			-- lying across it as it goes through: slid off its edge onto the steel, not far
			local cx, cz = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
			for n = 0, 5 do
				local x = if n == 0 then cx else r.x0 + rng:nextNumber() * (r.x1 - r.x0)
				local z = if n == 0 then cz else r.z0 + rng:nextNumber() * (r.z1 - r.z0)
				local yaw = if n == 0 then inYaw else rng:nextNumber() * 2 * math.pi
				slides += 1
				ok(not Tops.fits(hmap, x, z, yaw), `{what}: a body on the hole doesn't fit`)
				local sx, sz = Tops.settle(hmap, x, z, yaw)
				if not (sx and sz) then
					ok(false, `{what}: a body on the hole has somewhere to slide`)
					continue
				end
				local d = math.sqrt((sx - x) ^ 2 + (sz - z) ^ 2)
				ok(
					Tops.fits(hmap, sx, sz, yaw) and not bodyInHole(hmap.holes, sx, sz, yaw),
					`{what}: slid off onto the steel`
				)
				ok(d <= 3.6, `{what}: slid off the nearest edge ({d} studs)`)
			end
		end
	end
end
ok(holesCut > 300 and holeWalks > 50 and slides > 1500, "enough sawn tops")
for size, spots in offeredBySize do
	local n = 0
	for _, offered in spots do
		n += if offered then 1 else 0
	end
	print(`  a sawn {size} top keeps {n} of its ladder's spots`)
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
	`tops: {checks - failures}/{checks} passed ({floors} floors, {spotsChecked} spots, {walks} walks, {pairsWalked} unit to unit, {lidsWalked} round lids, {peeks} peeks, {holesCut} sawn tops, {slides} slid off)`
)
if failures > 0 then
	error(`{failures} failed`)
end
