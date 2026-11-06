--!strict
--[[
	Roll-up curtain kinematics. A line-for-line port of art/unit/curtain.py, checked against it
	by tests/curtain.spec.luau.

	The curtain is a chain of rigid slats, one rib each, hinged at the rib valleys. One number
	drives the whole door: `rise`, how far the curtain's bottom edge has lifted (studs).

	Solved in the door's side plane: z = outward (toward the hallway), y = up, origin at the
	bottom middle of the opening on the curtain plane. The curtain hangs in the guides along
	z = 0 up to the guide top, runs straight to a tangent point on the coil, then winds inward
	along an Archimedean spiral to its anchor on the drum.

	Pure numbers, no Instances: safe to run on the server, the client or in Lune.
]]

export type Params = {
	Pitch: number,
	Count: number,
	BottomClosed: number,
	GuideTop: number,
	DrumZ: number,
	DrumY: number,
	DrumRadius: number,
	Wrap: number,
}

-- One solve: the coil's wound angle, the tangent point's polar angle, the straight run's length.
export type State = {
	rise: number,
	phi: number,
	theta: number,
	ell: number,
}

export type Curtain = {
	params: Params,
	length: number,
	k: number,
	anchorClosed: number,
	solve: (self: Curtain, rise: number, phiGuess: number?) -> State,
	point: (self: Curtain, u: number, state: State) -> (number, number),
	slats: (self: Curtain, rise: number, out: { number }, phiGuess: number?) -> State,
	drumAngle: (self: Curtain, state: State) -> number,
	radius: (self: Curtain, phi: number) -> number,
}

local Curtain = {}
Curtain.__index = Curtain

local TAU = 2 * math.pi

local function arc(self: Curtain, phi: number): number
	return self.params.DrumRadius * phi + 0.5 * self.k * phi * phi
end

local function arcInv(self: Curtain, s: number): number
	local r0 = self.params.DrumRadius
	s = math.max(s, 0)
	return (-r0 + math.sqrt(r0 * r0 + 2 * self.k * s)) / self.k
end

function Curtain.radius(self: Curtain, phi: number): number
	return self.params.DrumRadius + self.k * phi
end

-- Tangent point on the coil (radius R) for the line from the guide top, front side, with the
-- curtain arriving counter-clockwise (front, over the top, to the back).
local function tangent(self: Curtain, R: number): (number, number)
	local p = self.params
	local dz, dy = -p.DrumZ, p.GuideTop - p.DrumY
	local D = math.sqrt(dz * dz + dy * dy)
	local a = math.acos(math.min(1, R / D))
	local base = math.atan2(dy, dz)
	local ell = math.sqrt(math.max(D * D - R * R, 0))
	-- two candidates, base + a and base - a: take the one the curtain reaches counter-clockwise
	local theta = base + a
	local tz = p.DrumZ + R * math.cos(theta)
	local ty = p.DrumY + R * math.sin(theta)
	if tz * -math.sin(theta) + (ty - p.GuideTop) * math.cos(theta) > 0 then
		return theta, ell
	end
	theta = base - a
	tz = p.DrumZ + R * math.cos(theta)
	ty = p.DrumY + R * math.sin(theta)
	if tz * -math.sin(theta) + (ty - p.GuideTop) * math.cos(theta) > 0 then
		return theta, ell
	end
	error("Curtain: guide top is inside the coil")
end

function Curtain.solve(self: Curtain, rise: number, phiGuess: number?): State
	local p = self.params
	local hanging = p.GuideTop - (p.BottomClosed + rise)
	local target = self.length - hanging
	local phi = phiGuess or arcInv(self, target)
	for _ = 1, 12 do
		local R = self:radius(phi)
		local _, ell = tangent(self, R)
		local f = arc(self, phi) + ell - target
		local df = R - (R * self.k) / math.max(ell, 1e-6)
		local step = f / df
		phi -= step
		if math.abs(step) < 1e-9 then
			break
		end
	end
	local theta, ell = tangent(self, self:radius(phi))
	return { rise = rise, phi = phi, theta = theta, ell = ell }
end

-- Point on the curtain at distance u from its bottom edge, as (z, y).
function Curtain.point(self: Curtain, u: number, st: State): (number, number)
	local p = self.params
	local bottom = p.BottomClosed + st.rise
	local hanging = p.GuideTop - bottom
	if u <= hanging then
		return 0, bottom + u
	end
	u -= hanging
	local R = self:radius(st.phi)
	local tz = p.DrumZ + R * math.cos(st.theta)
	local ty = p.DrumY + R * math.sin(st.theta)
	if u <= st.ell then
		local f = if st.ell > 1e-9 then u / st.ell else 0
		return tz * f, p.GuideTop + (ty - p.GuideTop) * f
	end
	local w = u - st.ell
	local q = arcInv(self, arc(self, st.phi) - w)
	local th = st.theta + (st.phi - q)
	local r = self:radius(q)
	return p.DrumZ + r * math.cos(th), p.DrumY + r * math.sin(th)
end

--[[
	Every slat's hinge-chord frame, bottom first, written flat into `out`:
	out[4i+1..4i+4] = midZ, midY, dirZ, dirY for slat i (0-based). dir is the unit vector up the
	curtain; the slat's outward normal is (dirY, -dirZ). Reuses `out`, so a door moving every
	frame allocates nothing but the returned State.
]]
function Curtain.slats(self: Curtain, rise: number, out: { number }, phiGuess: number?): State
	local st = self:solve(rise, phiGuess)
	local pitch = self.params.Pitch
	local az, ay = self:point(0, st)
	for i = 0, self.params.Count - 1 do
		local bz, by = self:point((i + 1) * pitch, st)
		local dz, dy = bz - az, by - ay
		local n = math.sqrt(dz * dz + dy * dy)
		if n == 0 then
			n = 1
		end
		local j = 4 * i
		out[j + 1] = (az + bz) * 0.5
		out[j + 2] = (ay + by) * 0.5
		out[j + 3] = dz / n
		out[j + 4] = dy / n
		az, ay = bz, by
	end
	return st
end

-- Drum rotation (radians, counter-clockwise in z-y) relative to the shut door. The anchor sits
-- at polar angle theta + phi, welded to the drum.
function Curtain.drumAngle(self: Curtain, st: State): number
	return (st.theta + st.phi) - self.anchorClosed
end

function Curtain.new(params: Params): Curtain
	local self = setmetatable({
		params = params,
		length = params.Pitch * params.Count,
		k = params.Wrap / TAU,
		anchorClosed = 0,
	}, Curtain) :: any
	local st = self:solve(0)
	self.anchorClosed = st.theta + st.phi
	return self :: Curtain
end

return Curtain
