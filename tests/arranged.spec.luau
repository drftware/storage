--!strict
-- lune run tests/arranged.spec
-- Where a find set out in your home stands (S5-03e2b, Home/Arranged, D-308): the unit's frame looks
-- out of its door; a find at turn 0 on the floor or the ceiling faces the door, a step along `y`
-- walks toward it, and a turn takes `x` toward `y` as Brix turns; a find on a wall stands upright
-- with its back to the wall; one from the ceiling hangs with its top on it.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Spots = require("../src/shared/Home/Spots")

local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

-- Arranged uses CFrame and Vector3, which Lune lacks as globals: load it with Lune's own.
local Arranged: any = luau.load(fs.readFile("src/shared/Home/Arranged.luau"), { -- any: loaded code
	environment = { Vector3 = Vector3, CFrame = CFrame },
})()

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function same(a: any, b: any): boolean -- any: two Lune Vector3s
	return (a - b).Magnitude < 1e-4
end

-- The lobby turned and moved, so nothing lines up by luck (not a quarter turn: Lune's lookAt
-- looks backwards straight down +Z, which Roblox's does not).
local pivot = CFrame.new(10, 2, -30) * CFrame.Angles(0, math.rad(30), 0)
local face = Arranged.face(pivot, { 60, 0, -122 }, { -1, 0, 0 })
ok(same(face.Position, pivot * Vector3.new(60, 0, -122)), "the unit's frame stands on its door")
ok(
	same(face.LookVector, pivot:VectorToWorldSpace(Vector3.new(-1, 0, 0))),
	"it looks out of the door"
)
ok(same(face.UpVector, Vector3.new(0, 1, 0)), "it stands upright")

local centre, size = Arranged.inside(pivot, face, { 75.125, 5, -122 }, { 29.75, 10, 20 })
ok(
	math.abs(centre[1]) < 1e-4 and math.abs(centre[2] - 5) < 1e-4,
	"the room's middle is on its axis"
)
ok(math.abs(centre[3] - 15.125) < 1e-4, "the room's middle is 15 studs in from the door")
ok(
	math.abs(size[1] - 20) < 1e-4
		and math.abs(size[2] - 10) < 1e-4
		and math.abs(size[3] - 29.75) < 1e-4,
	"the room is 20 across, 10 tall and 29.75 deep in the unit's frame"
)

local room = Spots.room(centre, size)
local inward = -face.LookVector

-- the floor: turn 0 faces the door, `y` walks toward it, `x` runs across
local floor = Arranged.area(face, room.Floor)
ok(
	same(floor.Position, face * Vector3.new(0, 0, 15.125)),
	"the floor's middle is the room's, on the floor"
)
local t = Arranged.pose(floor, 0, 0, 0)
ok(same(t.LookVector, face.LookVector), "a find on the floor at turn 0 faces the door")
ok(
	same(Arranged.pose(floor, 0, 2, 0).Position - t.Position, face.LookVector * 2),
	"y walks toward the door"
)
ok(same(Arranged.pose(floor, 3, 0, 0).Position - t.Position, face.RightVector * 3), "x runs across")
ok(
	same(Arranged.pose(floor, 0, 0, 90).LookVector, -face.RightVector),
	"a quarter turn takes x toward y"
)
local lamp = Arranged.box(t, "Tabletop", Vector3.new(1, 2, 1))
ok(same(lamp.Position, t.Position + Vector3.new(0, 1, 0)), "a find on the floor stands on it")
ok(same(Arranged.top(t, 2).Position, t.Position + Vector3.new(0, 2, 0)), "its top is its height up")

-- the back wall: upright, its back to the wall, `y` up
local back = Arranged.area(face, room.BackWall)
local w = Arranged.pose(back, 0, 0, 0)
local sign = Arranged.box(w, "Wall", Vector3.new(4, 2, 0.5))
ok(same(sign.UpVector, Vector3.new(0, 1, 0)), "a sign on a wall hangs upright")
ok(same(sign.LookVector, face.LookVector), "a sign on the back wall faces the door")
ok(same(sign.Position, w.Position + face.LookVector * 0.25), "its back is on the wall")
ok(
	same(Arranged.pose(back, 0, 1, 0).Position - w.Position, Vector3.new(0, 1, 0)),
	"y runs up a wall"
)
local left = Arranged.box(
	Arranged.pose(Arranged.area(face, room.LeftWall), 0, 0, 0),
	"Wall",
	Vector3.new(4, 2, 0.5)
)
ok(same(left.LookVector, -face.RightVector), "a sign on the left wall faces across the room")

-- the ceiling: its top on the ceiling, facing the door
local ceiling = Arranged.area(face, room.Ceiling)
local c = Arranged.pose(ceiling, 0, 0, 0)
ok(same(c.Position, face * Vector3.new(0, 10, 15.125)), "the ceiling's middle is overhead")
local ball = Arranged.box(c, "Ceiling", Vector3.new(1, 1.5, 1))
ok(same(ball.UpVector, Vector3.new(0, 1, 0)), "a disco ball hangs upright")
ok(same(ball.Position, c.Position - Vector3.new(0, 0.75, 0)), "its top is on the ceiling")
ok(same(ball.LookVector, face.LookVector), "it faces the door")
ok(
	same(Arranged.pose(ceiling, 0, 2, 0).Position - c.Position, face.LookVector * 2),
	"y walks toward the door"
)
ok(inward:Dot(face.LookVector) < 0, "in is away from the door")

-- a starter piece's top, and the pivot that stands a model's box where `box` says
local piece = Arranged.piece(face, { 7.9, 0, 17.6 }, 90)
ok(same(piece.Position, face * Vector3.new(7.9, 0, 17.6)), "a piece stands at its place")
ok(same(piece.LookVector, -face.RightVector), "a piece turned a quarter faces across")
local top = Arranged.furniture(piece, { 4.52, 0.84, 2.35 }, { 0, 2.32, -0.015 })
ok(same(top.Position, piece * Vector3.new(0, 2.74, -0.015)), "the job box's top is on its lid")
local p = Arranged.pivot(t, "Tabletop", Vector3.new(1, 2, 1), Vector3.new(0, 0.5, 0.2))
ok(
	same(p * Vector3.new(0, 0.5, 0.2), lamp.Position),
	"a model's box middle lands where its box stands"
)

print(`arranged.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
