--!strict
--[[
	PlaceAim: where a thing you carry would go, and whether it may stand there, judged exactly as
	the server judges it (S5-03j5a, D-463). The one aim and judge for every "put this on or into
	that" on this screen: Arrange's hand (ArrangeHand) drags with it, placing a held find where you
	look (HandPlaceView) aims with it, and the recipes' "put on or into" (S5-03k) will start from
	it. It names no find: what a thing is comes from its catalog row (`Arrange.shapeOf`, its spot,
	whether it hangs on a wall, has a top, leans or keeps its lid's room, `Layout`).

	It was ArrangeHand's middle (S5-03j2a to j4b2); it lives on its own so both hands share one
	judge instead of two that drift. Nothing here steps or allocates per call but the pose a
	`settle` answers; the room's copy (`room`) is built once as a screen starts aiming.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Snapping = require(ReplicatedStorage.Shared.Home.Snapping)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Turning = require(ReplicatedStorage.Shared.Home.Turning)
local WallHang = require(ReplicatedStorage.Shared.Home.WallHang)

-- How far past a room area's edge a finger still aims at it (studs): a find dragged toward a
-- wall slides along it, flush, rather than stopping short. Tops don't use it: a find stands on a
-- top only with its middle over it (`Snapping.over`, D-455).
local REACH = 2.5
-- How much nearer along the ray (studs) another top has to be than the one a thing stands on to
-- take it: two tops of a height side by side don't trade it back and forth.
local TIE = 0.25

-- The grid every carried thing settles on, and Free's (Alt, or Arrange's corner switch): exactly
-- where the finger has it, to the whole degree. Neither keeps state, so every caller shares them.
local GRID = Brix.PlacementSnap.grid({ step = Arrange.Step, turn = Arrange.Turn })
local FREE = Brix.PlacementSnap.free({ turn = 1 })

-- A thing being carried toward a spot: what the judge needs to know of it, and where it is now.
-- ArrangeHand's `Lifted` is one; HandPlaceView makes one for the find in your hand.
export type Carried = {
	id: string, -- the id the judge checks it as (the next free one for a find not yet set out)
	shape: Brix.PlacementShape,
	spot: Spots.Spot,
	size: Vector3, -- its box as drawn (`Arranged.bounds`)
	centre: Vector3,
	starter: string?, -- a home's own piece's kind (`Layout.kind`): it stands by its spec box
	pose: Brix.PlacementPose?, -- where it would stand now, snapped
	turn: number,
	-- Whether it turns its back to a wall it's pushed to (furniture that isn't flat, and not the
	-- leaning mirror); the wall it's against now, if any; Brix's line-up with its neighbours,
	-- made once and filled again on every move (the guide lines to draw).
	backs: boolean,
	wall: number?,
	lines: Brix.PlacementAlignment,
}

local PlaceAim = {}

-- A fresh, empty line-up for a new `Carried`.
function PlaceAim.lines(): Brix.PlacementAlignment
	return { x = 0, y = 0, count = 0, guides = {} }
end

-- The room's judge, as the server's, for the home drawn as `unit` (its slot, its size), loaded
-- with the finds of `owner`'s drawn in it; `tops` is cleared and filled with those whose top
-- takes another. Nil when `unit` isn't a home slot.
function PlaceAim.room(unit: Model, tops: { [string]: boolean }, owner: number?): Arrange.Room?
	local n = unit:GetAttribute(Arrange.SlotAttribute)
	local slot = if type(n) == "number" then Arrange.slot(n) else nil
	if not slot then
		return nil
	end
	local me = owner or Players.LocalPlayer.UserId
	-- the home's size, as the server set it from the holder's save (S5-03h1)
	local sized = unit:GetAttribute(Spots.SizeAttribute)
	local r =
		Arrange.room(slot, Lobby.Origin, if type(sized) == "string" then sized else Spots.Start)
	table.clear(tops)
	local waiting: { { id: string, on: string, at: Vector3, model: Model } } = {}
	local folder = unit:FindFirstChild(Arrange.Folder)
	local children: { Instance } = if folder then folder:GetChildren() else {}
	for _, m in children do
		local id, on, at =
			m:GetAttribute(Spots.IdAttribute),
			m:GetAttribute(Arrange.OnAttribute),
			m:GetAttribute(Arrange.AtAttribute)
		if
			m:IsA("Model")
			and m:GetAttribute(Spots.OwnerAttribute) == me
			and type(id) == "string"
			and type(on) == "string"
			and typeof(at) == "Vector3"
		then
			table.insert(waiting, { id = id, on = on, at = at, model = m })
		end
	end
	-- what stands on another find goes in after it
	local progress = true
	while progress and #waiting > 0 do
		progress = false
		for i = #waiting, 1, -1 do
			local w = waiting[i]
			local shape = Arrange.shapeOf(w.id)
			if shape and (r.frames[w.on] or r.placements:poseOf(w.on)) then
				r.placements:place(
					w.id,
					shape,
					{ on = w.on, x = w.at.X, y = w.at.Y, turn = w.at.Z }
				)
				local size = Arranged.bounds(w.model)
				if size then
					r.heights[w.id] = size.Y
				end
				if shape.top then
					tops[w.id] = true
				end
				table.remove(waiting, i)
				progress = true
			end
		end
	end
	r.placements:takeEvents() -- the screen draws nothing from these
	return r
end

-- Whether `id` stands, however high up, on `base`.
function PlaceAim.rides(r: Arrange.Room, id: string, base: string): boolean
	local on = id
	for _ = 1, 32 do
		local pose = r.placements:poseOf(on)
		if not pose then
			return false
		elseif pose.on == base then
			return true
		end
		on = pose.on
	end
	return false
end
local rides = PlaceAim.rides

-- The area along `ray` that `c` fits, nearest first, and the point on it (`x`, `y` from its
-- middle): a room's floor, walls and ceiling, or the top of anything in `tops`. Nil over nothing
-- it fits.
function PlaceAim.aim(
	r: Arrange.Room,
	c: Carried,
	ray: Ray,
	tops: { [string]: boolean }
): (string?, number, number)
	local best: string? = nil
	local nearest, bx, by = math.huge, 0, 0
	-- something hung from the ceiling follows the finger over the floor under it, as The Sims
	-- hangs a ceiling light from the tile you point at: the corner camera looks down on the
	-- room, so the ceiling itself is seldom on the screen (S5-03g4d)
	local under = r.frames.Floor
	-- the top the thing stands on now: it holds a little past its edge, and wins a near tie
	local held = if c.pose then c.pose.on else nil
	local heldBest = false
	-- a thing that hangs only on walls slides along them at the height it hangs (D-458): the
	-- finger picks the wall and how far along, however high or low it is (over the floor, the
	-- wall the ray leaves the room through); `WallHang.height` keeps the height
	local hangs = WallHang.only(c.shape.fits, Spots.Kinds.Wall)
	local function try(on: string, f: CFrame, area: Brix.PlacementArea, top: boolean)
		if not table.find(c.shape.fits, area.kind) then
			return
		end
		local plane = if area.kind == Spots.Kinds.Ceiling and under then under else f
		local n = plane.YVector
		local facing = ray.Direction:Dot(n)
		if facing > -1e-4 then
			return -- seen from behind or edge on
		end
		local t = (plane.Position - ray.Origin):Dot(n) / facing
		local mine = top and on == held
		if
			t <= 0
			or t >= (if heldBest then nearest - TIE elseif mine then nearest + TIE else nearest)
		then
			return
		end
		local p = f:PointToObjectSpace(ray.Origin + ray.Direction * t)
		local x, y = p.X, -p.Z
		if top then
			if not Snapping.over(x, y, area.width, area.depth, mine) then
				return -- a thing stands on a top only with its middle over it (D-455)
			end
		elseif
			math.abs(x) > area.width / 2 + REACH
			or (not hangs and math.abs(y) > area.depth / 2 + REACH)
		then
			return
		end
		best, nearest, bx, by, heldBest = on, t, x, y, mine
	end
	for on, f in r.frames do
		local area = r.placements:areaOf(on)
		if area then
			try(on, f, area, false)
		end
	end
	for id in tops do
		if id ~= c.id and not rides(r, id, c.id) then
			local shape = Arrange.shapeOf(id)
			local f = Arrange.frameOn(r, id)
			if shape and shape.top and f then
				try(id, f, shape.top, true)
			end
		end
	end
	local area = if hangs and best then r.placements:areaOf(best) else nil
	if area then
		local pose = c.pose
		local was = if pose then r.placements:areaOf(pose.on) else nil
		local kept = if pose and was and was.kind == Spots.Kinds.Wall then pose.y else nil
		by = WallHang.height(by, kept, area.depth, c.shape.depth)
	end
	return best, bx, by
end

-- The area `on`'s size, a room's or a find's top.
function PlaceAim.areaOf(r: Arrange.Room, on: string): Brix.PlacementArea?
	local area = r.placements:areaOf(on)
	if area then
		return area
	end
	local shape = Arrange.shapeOf(on)
	return if shape then shape.top else nil
end
local areaOf = PlaceAim.areaOf

-- `x`, `y` on `area` snapped by `snapper` (the grid, or Free) and kept inside it, `c` turned
-- `turn`: kept in by the reach of its footprint so turned, square on or askew, as Brix's judge
-- measures it (S5-03j2b2b). Answers where it stands and its turn, how far its middle may go
-- from the area's each way, and its reach across and deep.
local function snapIn(
	snapper: Brix.PlacementSnap,
	area: Brix.PlacementArea,
	c: Carried,
	x: number,
	y: number,
	turn: number
): (number, number, number, number, number, number, number)
	local _, _, turned = snapper:snap(area, c.shape, x, y, turn) -- (the turn's snap alone)
	local rx, ry = Turning.reach(c.shape.width, c.shape.depth, turned)
	local hx, hy = math.max(0, area.width / 2 - rx), math.max(0, area.depth / 2 - ry)
	local sx, sy, st =
		snapper:snap(area, c.shape, math.clamp(x, -hx, hx), math.clamp(y, -hy, hy), turn)
	return math.clamp(sx, -hx, hx), math.clamp(sy, -hy, hy), st, hx, hy, rx, ry
end

-- Where `c` settles aimed at `x`, `y` on area `on`, as The Sims 4 settles a thing you drag
-- (D-455): on the grid (`free`: as it is) and inside the area; a piece with a back pushed to a
-- wall turns its back to it as it arrives and sits flush; lined up with its neighbours where an
-- edge or middle comes within `Snapping.Line` (the lines kept in `c.lines`); then a leaning
-- piece leans on its wall and one that keeps room in front of it keeps it (`Layout`). Free skips
-- the wall and the lines. No tables made but the pose answered.
function PlaceAim.settle(
	r: Arrange.Room,
	c: Carried,
	on: string,
	x: number,
	y: number,
	free: boolean
): Brix.PlacementPose?
	local area = areaOf(r, on)
	if not area then
		return nil
	end
	local snapper = if free then FREE else GRID
	local px, py, pt, hx, hy, rx, ry = snapIn(snapper, area, c, x, y, c.turn)
	if on ~= "Floor" then
		c.wall = nil
	elseif c.backs and not free then
		local wall = Snapping.wall(area, px, py, rx, ry, pt, c.wall)
		local turn = Snapping.turned(pt, wall, c.wall)
		if turn ~= pt then -- arrived at a wall: its back to it, then the grid at that turn
			c.turn = turn
			px, py, pt, hx, hy, rx, ry = snapIn(snapper, area, c, x, y, turn)
		end
		c.wall = wall
		if wall then
			px, py = Snapping.flush(area, wall, px, py, rx, ry)
		end
	end
	local pose = { on = on, x = px, y = py, turn = pt }
	local kind, lines = c.starter, c.lines
	if free or (kind and Layout.Lean[kind]) then
		lines.count = 0
	else
		r.placements:align(c.id, c.shape, pose, Snapping.Line, lines)
		local across: ("x" | "y")? = if c.wall then Snapping.across(c.wall) else nil
		pose.x, pose.y, lines.count =
			Snapping.lineUp(px, py, lines.x, lines.y, hx, hy, across, lines.guides, lines.count)
	end
	local floor = r.placements:areaOf("Floor")
	if kind and floor and Layout.Lean[kind] then
		-- a leaning piece finds the wall nearest the finger and turns its back to it (D-348)
		local leant = Layout.leanTo(kind, pose, floor)
		if leant then
			c.turn = leant.turn
			return leant
		end
	elseif kind and floor then
		return Layout.clearOf(kind, pose, floor) -- the job box keeps its lid's room
	end
	return pose
end

-- Whether `c` may stand at `pose`: Brix's judge, and a leaning piece against a wall, as the
-- server's.
function PlaceAim.fitsAt(r: Arrange.Room, c: Carried, pose: Brix.PlacementPose): boolean
	if r.placements:check(c.id, c.shape, pose) ~= nil then
		return false
	end
	local kind, floor = c.starter, r.placements:areaOf("Floor")
	return not (kind and floor) or Layout.stands(kind, pose, floor)
end

-- Where `c`'s pivot stands at `pose`, and the area's normal (out of it, into the room).
function PlaceAim.standAt(r: Arrange.Room, c: Carried, pose: Brix.PlacementPose): (CFrame?, Vector3)
	local a = Arrange.frameOn(r, pose.on)
	if not a then
		return nil, Vector3.yAxis
	end
	local t = Arranged.pose(a, pose.x, pose.y, pose.turn)
	local kind = c.starter
	if kind then -- by its spec box, as the server draws it (the mirror keeps its lean)
		return Arrange.starterPivot(t, kind), t.YVector
	end
	return Arranged.pivot(t, c.spot, c.size, c.centre), t.YVector
end

return table.freeze(PlaceAim)
