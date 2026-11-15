--!strict
-- What the finds kit (art/finds/kit, art/finds/CRAFT.md "The kit") writes about a find built with
-- it, and how its motions play. The generated sets (Finds/Sets/<Set>.luau) are typed by this.
-- Nothing deals from them yet: a set's templates must be in the place first (D-009).
--
-- Studs and Roblox axes, relative to the find's pivot. A find is a Model of MeshParts named
-- "<Find>_<Part>"; each part's pivot sits on its real hinge or axle.

export type Part = {
	Name: string,
	Parent: string?, -- the part it rides on; nil for the root (the find's pivot)
	Pivot: Vector3, -- its hinge, from the find's pivot
	Axis: Vector3?, -- what it turns about or slides along (right-handed); nil if it never moves
	Clear: boolean?, -- see-through (glass, a flame): its SurfaceAppearance is in AlphaMode
	-- Transparency, and the part wants Transparency 0.02 or the alpha cuts (docs/STUDIO.md)
	Size: Vector3,
	Triangles: number,
}

export type Light = {
	Kind: "Spot" | "Point" | "Surface",
	Part: string, -- the part it rides on
	At: Vector3,
	Face: Vector3, -- where a spot shines
	Color: Color3, -- from the real source's colour temperature
	Brightness: number, -- when fully on; scaled by the glow
	Range: number,
	Angle: number?,
	Shadows: boolean,
}

-- One key: time (seconds), value, and how it's reached from the key before (EasingStyle and
-- EasingDirection names: Linear, Sine, Quad, Cubic, Quart, Back; In, Out, InOut).
export type Key = { any } -- { number, number, string, string }; a tuple Luau can't type
export type Track = {
	Part: string,
	-- turn: degrees about its Axis; move: studs along it; glow: 0 to 1 lit; scale: times its size
	-- about its pivot (near 0: hide it, a MeshPart can't be size 0); stretch: times as tall up
	-- the find's Y and 1/sqrt as wide about its pivot, squash and stretch keeping its volume
	Channel: "turn" | "move" | "glow" | "scale" | "stretch",
	Keys: { Key },
}

export type Motion = { Duration: number, Tracks: { Track } }

export type Find = {
	Size: Vector3,
	Centre: Vector3, -- the middle of its box, from its pivot
	Triangles: number,
	Texture: number, -- its texture set's side, in texels
	Parts: { Part },
	Glow: { Part: string, Strength: number, Tint: Color3 }?, -- the part with the emissive mask,
	-- its SurfaceAppearance.EmissiveStrength when on, and EmissiveTint
	Lights: { Light },
	Motions: { [string]: Motion },
}

local Art = {}

local BACK = 1.70158

local function easeIn(style: string, t: number): number
	if style == "Linear" then
		return t
	elseif style == "Sine" then
		return 1 - math.cos(t * math.pi / 2)
	elseif style == "Quad" then
		return t * t
	elseif style == "Cubic" then
		return t * t * t
	elseif style == "Quart" then
		return t * t * t * t
	elseif style == "Back" then
		return t * t * ((BACK + 1) * t - BACK)
	end
	error(`Art: no easing style {style}`)
end

-- The same sums as art/finds/kit/ease.py, so the game plays what the previews showed.
function Art.ease(style: string, direction: string, t: number): number
	t = math.clamp(t, 0, 1)
	if direction == "In" then
		return easeIn(style, t)
	elseif direction == "Out" then
		return 1 - easeIn(style, 1 - t)
	end
	if t < 0.5 then
		return easeIn(style, 2 * t) / 2
	end
	return 1 - easeIn(style, 2 - 2 * t) / 2
end

-- A track's value at time t (seconds from the motion's start).
function Art.sample(keys: { Key }, t: number): number
	local first = keys[1]
	if t <= first[1] then
		return first[2]
	end
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if t <= b[1] then
			local span = b[1] - a[1]
			local alpha = if span > 0 then (t - a[1]) / span else 1
			return a[2] + (b[2] - a[2]) * Art.ease(b[3], b[4], alpha)
		end
	end
	return keys[#keys][2]
end

return Art
