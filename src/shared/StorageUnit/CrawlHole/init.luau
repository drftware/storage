--!strict
--[[
	CrawlHole: a saw's crawl hole between two units side by side (GDD "The hole trap"). Two such
	units share one wall, stood by one of them (D-031). `saw` swaps that wall for the same wall
	with the hole cut through it, lays the bright cut edge with its tongues of steel bent away from
	the saw, and drops the cut-out panel flat on the floor of the unit it was pushed into. The
	wall's collision opens round the hole: too low for anyone to walk through, so crawling it is
	the "Crawl through" button's job (L-12b2), and a keeper never fits. Art and its numbers:
	art/hole/README.md, Specs (generated).

		CrawlHole.saw(from, into, at?)  -- on the server: true if it cut one; the swap replicates
		CrawlHole.between(a, b)         -- the side wall two units share, and the unit standing it
		CrawlHole.frame(unit, wall)     -- the kit's frame laid on a wall: hole numbers to the world
		CrawlHole.prepare(kit)          -- once, in Studio's Edit, on the freshly imported kit

	Sawing it is `Saws` on the server and `SawView` on screens; its rules are `Sawing` (pure).

	The kit lives in the place at ReplicatedStorage.Props.CrawlHole (Rojo can't sync imported
	meshes, D-009). Its walls and panel wear the unit's own wall texture, copied from
	ReplicatedStorage.Units.M by `prepare`, so a holed wall is the wall it replaces.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boxes = require(script.Boxes)
local HoleSpecs = require(script.Specs)
local Specs = require(script.Parent.Specs)

local CrawlHole = {}

CrawlHole.Specs = HoleSpecs
-- Set on a holed wall: "Pos" or "Neg", which way its panel fell (the kit's own words).
CrawlHole.Attribute = "CrawlHole"
-- Every holed wall carries this tag, so a screen finds a hole as it streams in.
CrawlHole.Tag = "CrawlHole"
-- A panel a saw just cut out carries this tag, the server time it went through, the line it
-- tips over on (a CFrame on the floor at its edge by the wall, turning about its Z) and how far
-- it stands up from there (radians), so a screen shows it fall and clang once (a hole streaming
-- in later is old news).
CrawlHole.PanelTag = "CrawlPanel"
CrawlHole.CutAtAttribute = "CrawlCutAt"
CrawlHole.HingeAttribute = "CrawlHinge"
CrawlHole.FallAttribute = "CrawlFall"
-- How far up the panel starts its fall: pushed through, already leaning past upright (degrees).
local FALL_FROM = 78
-- The hole on its wall, in the kit's frame (along from the hall, up from the floor).
CrawlHole.Rect = {
	from = HoleSpecs.From,
	to = HoleSpecs.To,
	bottom = HoleSpecs.Bottom,
	top = HoleSpecs.Top,
}

local WALLS = { "WallLeft", "WallRight" }

local function kit(): Model?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local found = props and props:FindFirstChild("CrawlHole")
	return if found and found:IsA("Model") then found else nil
end

local function piece(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

--[[
	The wall `from` and `into` share: whichever of their side walls stands between their door
	faces, the two on opposite sides of it. Returns the unit standing it and the wall; nil for two
	units that aren't side by side in a row (across a hall, back to back, a corner's side against
	a back wall).
]]
local function between(from: Model, into: Model): (Model?, BasePart?)
	local a, b = from:GetPivot().Position, into:GetPivot().Position
	local best, bestUnit, bestReach = nil, nil, math.huge
	for _, unit in { from, into } do
		for _, name in WALLS do
			local wall = piece(unit, name)
			if wall then
				local la, lb = wall.CFrame:PointToObjectSpace(a), wall.CFrame:PointToObjectSpace(b)
				-- the wall's thin axis is X (its Size is 0.2 across); both door faces lie just in
				-- front of its near end, on the same floor
				-- (side by side in a row, their door faces are on one line along the wall: a unit
				-- across the hall and one along isn't a neighbour)
				local apart = la.X * lb.X < 0
				local reach = math.abs(la.X) + math.abs(lb.X)
				local level = math.abs(la.Y - lb.Y) < 0.5 and math.abs(la.Z - lb.Z) < 0.5
				if apart and level and reach < 20 and reach < bestReach then
					best, bestUnit, bestReach = wall, unit, reach
				end
			end
		end
	end
	return bestUnit, best
end

CrawlHole.between = between

-- The unit's size and the wall's side, as the kit names its pieces ("M", "Left").
local function kind(unit: Model, wall: BasePart): (string, string)
	local size = (unit:GetAttribute("UnitSize") :: string?) or "M"
	return size, if wall.Name == "WallLeft" then "Left" else "Right"
end

--[[
	The kit's frame laid on `wall` (stood by `unit`): its origin on the wall's middle plane, level
	with the floor and the corridor wall's outer face; +Y up, +Z along the wall away from the hall.
	`Rect`'s numbers and the kit's Specs are in this frame, so `frame * Vector3.new(0, up, along)`
	is a point on the hole. The holed wall is swapped in at the wall's own CFrame, so this frame is
	the same before and after the cut.
]]
function CrawlHole.frame(unit: Model, wall: BasePart): CFrame
	local size, side = kind(unit, wall)
	local row = (HoleSpecs.Parts :: any)[`HoleWall_{size}_{side}`]
	local centre: Vector3 = if row then row.Centre else HoleSpecs.Parts.HoleWall_M_Left.Centre
	return wall.CFrame * CFrame.new(-centre)
end

-- The wall's collision box split round the hole, in the collider's own frame.
local function openCollider(unit: Model, wallName: string, size: string)
	local folder = unit:FindFirstChild("Colliders")
	local old = folder and folder:FindFirstChild(wallName)
	local spec = Specs[size]
	local row = spec and (spec.Colliders :: any)[wallName]
	if not (old and old:IsA("BasePart") and row) then
		return
	end
	local centre, length, height = row.Position, row.Size.Z, row.Size.Y
	local wall = { along0 = -length / 2, along1 = length / 2, up0 = -height / 2, up1 = height / 2 }
	local hole = {
		along0 = HoleSpecs.From - centre.Z,
		along1 = HoleSpecs.To - centre.Z,
		up0 = HoleSpecs.Bottom - centre.Y,
		up1 = HoleSpecs.Top - centre.Y,
	}
	for _, p in Boxes.around(wall, hole) do
		local box = old:Clone()
		box.Name = if p.name == "Front" then wallName else wallName .. p.name
		box.Size = Vector3.new(old.Size.X, p.up1 - p.up0, p.along1 - p.along0)
		box.CFrame = old.CFrame * CFrame.new(0, (p.up0 + p.up1) / 2, (p.along0 + p.along1) / 2)
		box.Parent = folder
	end
	old:Destroy()
end

--[[
	Cuts the crawl hole in the wall `from` and `into` share, sawn from `from`: its panel falls
	into `into`. With `at` (the server time a saw went through), the panel carries it and the line
	it fell over on, so screens show it fall and clang. False (and nothing changes) if they share no
	side wall, it's holed already, or the kit isn't in the place.
]]
function CrawlHole.saw(from: Model, into: Model, at: number?): boolean
	local template = kit()
	if not template then
		warn("CrawlHole: no kit at ReplicatedStorage.Props.CrawlHole (art/hole/README.md)")
		return false
	end
	local unit, wall = between(from, into)
	if not (unit and wall) or wall:GetAttribute(CrawlHole.Attribute) ~= nil then
		return false
	end
	local size, side = kind(unit, wall)
	local holed = piece(template, `HoleWall_{size}_{side}`)
	local tPanel = piece(template, "Panel_Pos")
	if not (holed and tPanel) then
		warn(`CrawlHole: the kit has no HoleWall_{size}_{side}`)
		return false
	end
	-- which way the panel falls: toward `into`, on the kit's Pos side or its Neg side
	local posSide = holed.CFrame:PointToObjectSpace(tPanel.Position).X
	local intoSide = wall.CFrame:PointToObjectSpace(into:GetPivot().Position).X
	local way = if posSide * intoSide > 0 then "Pos" else "Neg"

	local swapped = holed:Clone()
	swapped.Name = wall.Name
	swapped.CFrame = wall.CFrame
	swapped:SetAttribute(CrawlHole.Attribute, way)
	swapped:AddTag(CrawlHole.Tag)
	-- the kit's pieces keep where they stand from its wall: the edge round the hole (with the
	-- unit standing the wall) and the panel (with the unit it fell into, which it streams with)
	local function lay(name: string, as: string, parent: Model): BasePart?
		local t = piece(template, name)
		if not t then
			return nil
		end
		local p = t:Clone()
		p.Name = as
		p.CFrame = wall.CFrame * holed.CFrame:ToObjectSpace(t.CFrame)
		p.Parent = parent
		return p
	end
	lay("Edge_" .. way, "CrawlEdge", unit)
	local tFell = piece(template, "Panel_" .. way)
	local panel = lay("Panel_" .. way, "CrawlPanel", into)
	if at and panel and tFell then
		-- the kit's frame in the world, then the panel's edge nearest the wall, on the floor
		local kitFrame = wall.CFrame * holed.CFrame:Inverse()
		local c, half = tFell.Position, tFell.Size.X / 2
		local out = if c.X > 0 then 1 else -1
		local hinge = kitFrame * CFrame.new(c.X - out * half, c.Y - tFell.Size.Y / 2, c.Z)
		panel:SetAttribute(CrawlHole.CutAtAttribute, at)
		panel:SetAttribute(CrawlHole.HingeAttribute, hinge)
		panel:SetAttribute(CrawlHole.FallAttribute, out * math.rad(FALL_FROM))
		panel:AddTag(CrawlHole.PanelTag)
	end
	openCollider(unit, wall.Name, size)
	swapped.Parent = wall.Parent
	wall:Destroy()
	return true
end

--[[
	Run once in Studio's Edit on the freshly inserted kit (art/hole/README.md, "Into the place"):
	no package link, every piece anchored and colliding with nothing (the unit's colliders do
	that), the walls and panel wearing the unit's own wall texture, the pieces where the kit's
	Specs put them, and the kit moved to ReplicatedStorage.Props.CrawlHole.
]]
function CrawlHole.prepare(model: Model)
	local link = model:FindFirstChildOfClass("PackageLink")
	if link then
		link:Destroy()
	end
	local units = ReplicatedStorage:FindFirstChild("Units")
	local m = units and units:FindFirstChild("M")
	local source = m and m:FindFirstChild("WallLeft", true)
	local look = source and source:FindFirstChildOfClass("SurfaceAppearance")
	if not look then
		warn(
			"CrawlHole.prepare: no ReplicatedStorage.Units.M.WallLeft to take the wall's look from"
		)
	end
	-- the importer keeps the FBX's layout but not where it stood or which way it faced (Studio
	-- turns an inserted model): square every piece to the kit's frame by its holed M wall
	local anchor = piece(model, "HoleWall_M_Left")
	assert(anchor, "CrawlHole.prepare: the kit has no HoleWall_M_Left")
	local from = anchor.CFrame
	local to = CFrame.new(HoleSpecs.Parts.HoleWall_M_Left.Centre)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.CFrame = to * from:ToObjectSpace(d.CFrame)
			local row = (HoleSpecs.Parts :: any)[d.Name]
			if row and (d.Position - row.Centre).Magnitude > 0.01 then
				warn(`CrawlHole.prepare: {d.Name} is {d.Position}, its Specs say {row.Centre}`)
			end
			local isSheet = string.sub(d.Name, 1, 9) == "HoleWall_"
				or string.sub(d.Name, 1, 6) == "Panel_"
			if isSheet and look then
				local old = d:FindFirstChildOfClass("SurfaceAppearance")
				if old then
					old:Destroy()
				end
				look:Clone().Parent = d
			end
		end
	end
	model.WorldPivot = CFrame.identity
	model.Name = "CrawlHole"
end

return CrawlHole
