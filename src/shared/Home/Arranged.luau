--!strict
--[[
	Arranged (S5-03e2b, D-308): where the finds you've set out in your home stand in the world. The
	server draws them by it (Arranging) and e3's screen drags them by it, so both put a find in the
	same place. `Home.Spots` says which areas there are and what fits where; this file turns an
	area and a pose into CFrames.

	The unit's frame is the starter set's (`face`, Lobby.front): X across, Y up, +Z in from the
	door, so its LookVector looks out of the door. An area's frame is
	`CFrame.fromMatrix(origin, across, normal)` in it; the area's `y` runs along `normal` crossed
	with `across`, which is that frame's -Z (its LookVector), so a pose stands at
	`A * CFrame.new(x, 0, -y)` turned about the normal, and a find at turn 0 faces down `y`.

	It requires nothing, so a Lune spec loads it with Lune's CFrame (tests/arranged.spec.luau).
]]
local Arranged = {}

type Vec = { number }

-- One of the room's flat faces, in the unit's frame (`Spots.RoomArea` without its Brix area).
export type Face = { origin: Vec, normal: Vec, across: Vec }

local function vec(v: Vec): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

-- The unit's frame for a lobby slot laid at `pivot`: its doorway's outer face on the floor
-- (`door`, the slot's Door), looking `out` onto the lobby (the slot's Out, in the lobby's frame).
function Arranged.face(pivot: CFrame, door: Vec, out: Vec): CFrame
	-- CFrame.lookAt(at, at + look) for a level `out`, built square so Lune's CFrame (whose lookAt
	-- flips Z) gives the same frame in the spec
	local look = pivot:VectorToWorldSpace(vec(out)).Unit
	local up = Vector3.new(0, 1, 0)
	return CFrame.fromMatrix(pivot * vec(door), look:Cross(up), up)
end

-- A starter piece's pivot: its origin `at` in the unit's frame `face`, turned `turn` degrees about Y
-- (0 with its front toward the door).
function Arranged.piece(face: CFrame, at: Vec, turn: number): CFrame
	return face * CFrame.new(vec(at)) * CFrame.Angles(0, math.rad(turn), 0)
end

-- A slot's inside box (`centre` and `size` in the lobby's frame, laid at `pivot`) in the unit's
-- frame `face`: its middle, and its size across, tall and deep, as `Spots.room` takes them.
function Arranged.inside(pivot: CFrame, face: CFrame, centre: Vec, size: Vec): (Vec, Vec)
	local c = face:PointToObjectSpace(pivot * vec(centre))
	local s = face:VectorToObjectSpace(pivot:VectorToWorldSpace(vec(size)))
	return { c.X, c.Y, c.Z }, { math.abs(s.X), math.abs(s.Y), math.abs(s.Z) }
end

-- A room area's frame in the world, from the unit's frame `face`.
function Arranged.area(face: CFrame, area: Face): CFrame
	return face * CFrame.fromMatrix(vec(area.origin), vec(area.across), vec(area.normal))
end

-- A starter piece's top as an area frame: the piece's pivot `pivot` and its top part's box (its size
-- and middle in the piece's frame, `Home.Specs.Parts`). Turn 0 faces out of the piece's front.
function Arranged.furniture(pivot: CFrame, partSize: Vec, partCentre: Vec): CFrame
	return pivot * CFrame.new(partCentre[1], partCentre[2] + partSize[2] / 2, partCentre[3])
end

-- Where pose (`x`, `y`, `turn`) stands on area frame `a`: on its face, turned about its normal.
function Arranged.pose(a: CFrame, x: number, y: number, turn: number): CFrame
	return a * CFrame.new(x, 0, -y) * CFrame.Angles(0, math.rad(turn), 0)
end

-- A find's own top as an area frame: the find standing at pose frame `t`, `height` tall
-- (`Spots.topHeight`).
function Arranged.top(t: CFrame, height: number): CFrame
	return t * CFrame.new(0, height, 0)
end

-- Where the middle of a find's box stands, for a find of spot `spot` (`Spots.spot`) at pose frame
-- `t`, its box `size` (across its front, up, front to back). Upright everywhere and facing the
-- room: on a floor or a top it stands on the face; on a wall its back is to the wall; from the
-- ceiling its top is on the ceiling.
function Arranged.box(t: CFrame, spot: string, size: Vector3): CFrame
	if spot == "Wall" then
		return CFrame.fromMatrix(t.Position + t.YVector * (size.Z / 2), -t.XVector, -t.ZVector)
	elseif spot == "Ceiling" then
		return CFrame.fromMatrix(t.Position + t.YVector * (size.Y / 2), -t.XVector, -t.YVector)
	end
	return t * CFrame.new(0, size.Y / 2, 0)
end

-- The box round a model's visible parts in its pivot's frame: its size and its middle. Nil when
-- nothing in it can be seen.
function Arranged.bounds(model: Model): (Vector3?, Vector3?)
	local pivot = model:GetPivot()
	local low = Vector3.one * math.huge
	local high = -low
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local cf = pivot:ToObjectSpace(d.CFrame)
			local h = d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						low = low:Min(p)
						high = high:Max(p)
					end
				end
			end
		end
	end
	if low.X > high.X then
		return nil, nil
	end
	return high - low, (high + low) / 2
end

-- The pivot that stands a model whose box is `size` round `centre` (`bounds`) as `box` says.
function Arranged.pivot(t: CFrame, spot: string, size: Vector3, centre: Vector3): CFrame
	return Arranged.box(t, spot, size) * CFrame.new(-centre)
end

return table.freeze(Arranged)
