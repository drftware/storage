--!strict
--[[
	Cart.Home: pure. A cart left out rolls itself home to the rack (L-08e4b2, D-129): hop off at
	a car's stripes and behind you it rolls back by itself, the casters rattling, and noses into a
	free slot with a soft clunk. One left standing anywhere else goes home after a while.

	It rolls nose first, as a cart is pushed home, and turns as a real one does, about its fixed
	casters at the handle end (Ride.Pivot): their middle (the hub) follows the way and the cart
	points along it. Facing well away from home, it first swings round on the spot about the hub.
	It then curves to line up with its slot and rolls the last stretch straight in, easing off, so
	its nose passes between the rack's hoops. Ridden away from the rack (handle first), a cart
	already faces home, so most ways home are one smooth curve.

	How far along the way it is at any moment comes from a run: where it was, its speed, where it
	stops and when (the server's clock). The server sends a run once; every screen draws the cart
	from it each frame. Someone in the way: a new run brakes it to a stop where it is; the way
	clear again, a new run sets it off once more. Runs are stamped with the server's time, so a
	screen that hears late is a hair off for a moment, never a jump.

	Poses are on the floor: x, z, and a heading `h` the way the cart's nose points (radians about
	Y, as `CFrame.Angles(0, h, 0)` turns its LookVector: the way (-sin h, -cos h)).
]]
local Ride = require("./Ride")

local Home = {}

-- The feel. A walk is 16 studs a second; a ride cruises about 22.
Home.Pace = 7 -- studs a second it rolls home: unhurried, a cart with nobody on it
Home.Accel = 6 -- studs a second gained each second as it sets off (or sets off again)
Home.Ease = 3 -- and lost each second as it eases into the rack, down to...
Home.Touch = 1.2 -- ...this as its nose meets the rack: the soft clunk
Home.Brake = 10 -- lost each second stopping for someone in its way: about 2.5 studs from its pace
Home.Lead = 0.15 -- seconds after the server's word that it sets off: every screen hears in time

-- The way. Studs unless said.
Home.Approach = 6 -- it rolls this far straight in, the hub on the slot's line: the nose clears
-- the rack's hoops (they stand 4.8 out from the wall) before it starts in
Home.Lined = 0.6 -- a hub this close to the slot's line, out in front of it, rolls straight in
Home.Arm = 3.4 -- the hub to the swivel casters: swinging on the spot, they trace this circle
Home.SwingFrom = math.rad(80) -- facing further than this from where it heads, it swings first
Home.Reach = 0.4 -- each end's pull on the curve, as a share of the way across (a shape)
Home.ReachMost = 15 -- and no more than this
Home.Samples = 32 -- points along the curve

-- When it goes, and the way in its way.
Home.Wait = 20 -- seconds a cart stands out (unridden, not at the stripes) before it goes home
Home.BandWait = 1.2 -- seconds a cart stopped at the cars' stripes stands before it goes home
Home.Look = { 0.75, 1.75, 3 } -- studs ahead of where it is that it looks for anyone in the way
Home.Clear = 0.6 -- seconds its way must stay clear before it rolls on
Home.GiveUp = 12 -- seconds held up, all told, before it gives up and is put in its slot
Home.Snug = 0.6 -- a cart this close to a slot's middle...
Home.SnugTurn = math.rad(12) -- ...and turned no further than this from it is in that slot

export type Pose = { x: number, z: number, h: number }

export type Way = {
	hx: number, -- the hub where it starts, where any swing turns about
	hz: number,
	h0: number, -- its heading before the swing
	swing: number, -- radians it swings on the spot first (signed; 0 for none)
	swingLength: number, -- studs: the swivel casters' arc
	xs: { number }, -- then the hub's way, as points...
	zs: { number },
	hs: { number }, -- ...the heading at each...
	ls: { number }, -- ...and the studs to each from the swing's end
	inFrom: number, -- studs along the whole way where the straight run into the slot begins
	length: number, -- the whole way, swing and roll
}

-- A run: where along the way the cart was (`from`, studs) and how fast (`speed`) at `at` (the
-- server's clock), and where it stops (`to`). Running to the way's end, it eases in and noses
-- into the rack; short of it, it brakes to a stop.
export type Run = { from: number, speed: number, to: number, at: number }

local wrap = Ride.wrap

local function hubOf(p: Pose): (number, number)
	local wx, wz = Ride.way(p.h)
	return p.x - wx * Ride.Pivot, p.z - wz * Ride.Pivot
end

--[[
	The way home from `from` to the slot at `to` (the parked pose). `reach` shapes the curve (the
	share of the way across each end pulls; Home.Reach unless given), so a way that meets
	something can be tried bent another way.
]]
function Home.plan(from: Pose, to: Pose, reach: number?): Way
	local hx, hz = hubOf(from)
	local tx, tz = Ride.way(to.h)
	local ex, ez = hubOf(to) -- the hub, parked
	local ox, oz = -tx, -tz -- out of the slot, into the room
	local px, pz = hx - ex, hz - ez
	local along = px * ox + pz * oz
	local across = px * oz - pz * ox
	local xs, zs, hs, ls = { hx }, { hz }, {}, { 0 }
	local swing = 0
	if math.abs(across) <= Home.Lined and along >= -0.1 and along <= Home.Approach + 8 then
		-- lined up in front of its slot: square to it, then straight in
		swing = wrap(to.h - from.h)
		if math.abs(swing) < 1e-3 then
			swing = 0
		end
		hs[1] = to.h
		table.insert(xs, ex)
		table.insert(zs, ez)
		table.insert(hs, to.h)
		table.insert(ls, math.sqrt(px * px + pz * pz))
	else
		local ax, az = ex + ox * Home.Approach, ez + oz * Home.Approach
		local dx, dz = ax - hx, az - hz
		local d = math.sqrt(dx * dx + dz * dz)
		local h = from.h
		local off = wrap(Ride.headingOf(dx, dz) - h)
		if d > 1e-3 and math.abs(off) > Home.SwingFrom then
			-- facing well away: swing round on the spot to face where it heads
			swing = off
			h = wrap(h + off)
		end
		local pull = math.clamp(d * (reach or Home.Reach), 0.5, Home.ReachMost)
		local hwx, hwz = Ride.way(h)
		-- a cubic curve from the hub, leaving the way it faces, into the slot's line
		local x0, z0 = hx, hz
		local x1, z1 = hx + hwx * pull, hz + hwz * pull
		local x2, z2 = ax + ox * pull, az + oz * pull
		local x3, z3 = ax, az
		hs[1] = h
		local n = Home.Samples
		local lx, lz = hx, hz
		local run = 0
		for i = 1, n do
			local u = i / n
			local v = 1 - u
			local x = v * v * v * x0 + 3 * v * v * u * x1 + 3 * v * u * u * x2 + u * u * u * x3
			local z = v * v * v * z0 + 3 * v * v * u * z1 + 3 * v * u * u * z2 + u * u * u * z3
			-- the heading from the curve's slope there
			local sx = 3 * v * v * (x1 - x0) + 6 * v * u * (x2 - x1) + 3 * u * u * (x3 - x2)
			local sz = 3 * v * v * (z1 - z0) + 6 * v * u * (z2 - z1) + 3 * u * u * (z3 - z2)
			local hh = if sx * sx + sz * sz > 1e-12 then Ride.headingOf(sx, sz) else hs[i]
			run += math.sqrt((x - lx) * (x - lx) + (z - lz) * (z - lz))
			lx, lz = x, z
			table.insert(xs, x)
			table.insert(zs, z)
			table.insert(hs, hh)
			table.insert(ls, run)
		end
		hs[#hs] = to.h
		-- then straight in
		table.insert(xs, ex)
		table.insert(zs, ez)
		table.insert(hs, to.h)
		table.insert(ls, run + Home.Approach)
	end
	local swingLength = math.abs(swing) * Home.Arm
	local rolled = ls[#ls]
	local straight = math.sqrt((xs[#xs] - xs[#xs - 1]) ^ 2 + (zs[#zs] - zs[#zs - 1]) ^ 2)
	return {
		hx = hx,
		hz = hz,
		h0 = from.h,
		swing = swing,
		swingLength = swingLength,
		xs = xs,
		zs = zs,
		hs = hs,
		ls = ls,
		inFrom = swingLength + rolled - straight,
		length = swingLength + rolled,
	}
end

-- Where the cart stands `s` studs along the way: its pivot (x, z) and heading.
function Home.pose(way: Way, s: number): (number, number, number)
	local hx, hz, h
	if s < way.swingLength then
		local f = if way.swingLength > 0 then math.max(s, 0) / way.swingLength else 1
		hx, hz, h = way.hx, way.hz, wrap(way.h0 + way.swing * f)
	else
		local r = s - way.swingLength
		local ls = way.ls
		local n = #ls
		if r >= ls[n] then
			hx, hz, h = way.xs[n], way.zs[n], way.hs[n]
		else
			-- the last point at or before r
			local lo, hi = 1, n
			while hi - lo > 1 do
				local mid = (lo + hi) // 2
				if ls[mid] <= r then
					lo = mid
				else
					hi = mid
				end
			end
			local span = ls[hi] - ls[lo]
			local f = if span > 1e-9 then (r - ls[lo]) / span else 0
			local xs, zs, hs = way.xs, way.zs, way.hs
			hx = xs[lo] + (xs[hi] - xs[lo]) * f
			hz = zs[lo] + (zs[hi] - zs[lo]) * f
			h = wrap(hs[lo] + wrap(hs[hi] - hs[lo]) * f)
		end
	end
	local wx, wz = Ride.way(h)
	return hx + wx * Ride.Pivot, hz + wz * Ride.Pivot, h
end

--[[
	A run's shape: its speed at the start (v0), its top (vp) and at the end (e), its rates (gain
	a1, loss a3, both positive), how long each part lasts (t1 changing to the top, t2 at the top,
	t3 slowing), and the studs it covers changing (d1) and at the top (d2).
]]
local function shape(r: Run, length: number)
	local d = math.max(0, r.to - r.from)
	local home = r.to >= length - 1e-6
	local e = if home then Home.Touch else 0
	local a1 = Home.Accel
	local a3 = if home then Home.Ease else Home.Brake
	local v0 = math.clamp(r.speed, 0, Home.Pace)
	if d <= 1e-9 then
		return v0, 0, 0, a1, a3, 0, 0, 0, 0, 0
	end
	if v0 * v0 + 2 * a1 * d <= e * e then
		-- too short to even reach the touch: it gains all the way
		local ve = math.sqrt(v0 * v0 + 2 * a1 * d)
		return v0, ve, ve, a1, a3, (ve - v0) / a1, 0, 0, d, 0
	end
	if v0 * v0 - e * e >= 2 * a3 * d then
		-- already too quick to slow at its rate: it slows harder, all the way
		local need = (v0 * v0 - e * e) / (2 * d)
		if need < 1e-9 then
			return v0, v0, v0, a1, a3, 0, d / v0, 0, 0, d
		end
		return v0, v0, e, a1, need, 0, 0, (v0 - e) / need, 0, 0
	end
	local top = math.sqrt((2 * a1 * a3 * d + a3 * v0 * v0 + a1 * e * e) / (a1 + a3))
	local vp = math.max(math.min(top, Home.Pace), v0)
	local d1 = (vp * vp - v0 * v0) / (2 * a1)
	local d3 = (vp * vp - e * e) / (2 * a3)
	local d2 = math.max(0, d - d1 - d3)
	return v0, vp, e, a1, a3, (vp - v0) / a1, if vp > 0 then d2 / vp else 0, (vp - e) / a3, d1, d2
end

-- Where a run has the cart at `t` (the server's clock): studs along, speed, and whether it's done.
function Home.at(r: Run, length: number, t: number): (number, number, boolean)
	local v0, vp, _e, a1, a3, t1, t2, t3, d1, d2 = shape(r, length)
	local tau = t - r.at
	if tau <= 0 then
		return r.from, v0, false
	end
	if tau < t1 then
		return r.from + v0 * tau + 0.5 * a1 * tau * tau, v0 + a1 * tau, false
	end
	tau -= t1
	if tau < t2 then
		return r.from + d1 + vp * tau, vp, false
	end
	tau -= t2
	if tau < t3 then
		return r.from + d1 + d2 + vp * tau - 0.5 * a3 * tau * tau, vp - a3 * tau, false
	end
	-- there: at the way's end it met the rack at the touch; short of it, stopped
	return math.max(r.from, r.to), 0, true
end

-- How long a run lasts, from its `at`.
function Home.lasts(r: Run, length: number): number
	local _, _, _, _, _, t1, t2, t3 = shape(r, length)
	return t1 + t2 + t3
end

-- Setting off from the start of a way at `t`.
function Home.start(length: number, t: number): Run
	return { from = 0, speed = 0, to = length, at = t + Home.Lead }
end

-- Someone in its way at `t`: brake to a stop from where it is.
function Home.halt(r: Run, length: number, t: number): Run
	local s, v = Home.at(r, length, t)
	return { from = s, speed = v, to = math.min(length, s + v * v / (2 * Home.Brake)), at = t }
end

-- The way clear again at `t`: on from where it is, home.
function Home.go(r: Run, length: number, t: number): Run
	local s, v = Home.at(r, length, t)
	return { from = s, speed = v, to = length, at = t }
end

-- Whether a run brakes to a stop short of home.
function Home.halting(r: Run, length: number): boolean
	return r.to < length - 1e-6
end

-- Whether a cart standing at `p` is in the slot at `slot`.
function Home.slotted(p: Pose, slot: Pose): boolean
	local dx, dz = p.x - slot.x, p.z - slot.z
	return dx * dx + dz * dz <= Home.Snug * Home.Snug
		and math.abs(wrap(p.h - slot.h)) <= Home.SnugTurn
end

-- Whether two cart footprints meet: boxes `halfWidth` by `halfLength` (along each heading)
-- about each pose (the separating-axis test on the floor).
function Home.meet(a: Pose, b: Pose, halfWidth: number, halfLength: number): boolean
	local dx, dz = b.x - a.x, b.z - a.z
	local ax, az = Ride.way(a.h)
	local bx, bz = Ride.way(b.h)
	-- whether the two boxes stand apart along the axis (nx, nz)
	local function apart(nx: number, nz: number): boolean
		local gap = math.abs(dx * nx + dz * nz)
		local ra = halfLength * math.abs(ax * nx + az * nz)
			+ halfWidth * math.abs(-az * nx + ax * nz)
		local rb = halfLength * math.abs(bx * nx + bz * nz)
			+ halfWidth * math.abs(-bz * nx + bx * nz)
		return gap > ra + rb
	end
	return not (apart(ax, az) or apart(-az, ax) or apart(bx, bz) or apart(-bz, bx))
end

return Home
