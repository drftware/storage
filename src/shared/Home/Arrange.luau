--!strict
--[[
	Arrange (S5-03e3a, D-310): one home's room as the judge sees it, set up the same way on the
	server (Arranging, the truth of every move) and on its holder's screen (ArrangeView, which paints
	the lifted find green or red as it's dragged). The moment it serves: you slide your lava lamp
	over the room and it goes red in the shelf and green on the job box, and when you let it down
	the server agrees, because both judged it with the same areas, frames and blocks.

	`room` builds a `Brix.Placements` (D-306) from the unit's slot and its size: the room's areas
	(`Spots.room`, from the size's box in the slot, `Home.Sizes`, D-340) and the ceiling's lamp
	placed first (`Spots.blocks`, D-309). The starter pieces are rows like bought furniture
	(S5-03i1b, D-346), their tops their own (`Spots.pieceTop`). Each
	area's world frame is kept by name, so `poseFrame` turns any pose into a CFrame, a find's own
	top included (lifted by its drawn height, `heights`, or its art's) and a piece of furniture's
	(its art's own top, `Spots.pieceTop`, D-338).

	Also here: the screen's feel numbers and sounds, and the box remote's name (the screen asks for
	what's in your job box; the server answers it, and again after every move).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Arranged = require(script.Parent.Arranged)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Furniture = require(script.Parent.Furniture)
local Gold = require(script.Parent.Gold)
local HomeSpecs = require(script.Parent.Specs)
local LobbySpecs = require(ReplicatedStorage.Shared.Lobby.Specs)
local Sizes = require(script.Parent.Sizes)
local Spots = require(script.Parent.Spots)

local Arrange = {}

-- One home's room: its judge, each area's world frame by name, the unit's frame (`Arranged.face`),
-- the inside box in that frame (middle and size: across, tall, deep), and the drawn height of each
-- find set out whose top is stood on (filled as they're drawn); its size's name and how many finds
-- it holds set out.
export type Room = {
	placements: Brix.Placements,
	frames: { [string]: CFrame },
	face: CFrame,
	centre: Vector3,
	size: Vector3,
	heights: { [string]: number },
	sizeName: string,
	limit: number,
}

-- The box remote (in `Spots.RemoteFolder`): the screen fires it with nothing to ask what's in its
-- job box; the server fires back (counts by name, then how many finds are set out and the most the
-- home holds, for the limit bar) then, and after every move or put away.
Arrange.BoxRemote = "ArrangeBox"
-- What a drawn find stands on and where (x, y, turn), set by the server as it draws it, so the
-- owner's screen loads its judge from what it sees.
Arrange.OnAttribute = "PlacedOn"
Arrange.AtAttribute = "PlacedAt"
-- When a move drew it (the server's `GetServerTimeNow`), so another player's screen settles a find
-- just set out in with a short drop and a knock, and leaves one streaming in or laid at a join.
Arrange.WhenAttribute = "PlacedWhen"
-- The folder in a home unit that holds what's set out in it.
Arrange.Folder = "Placed"
-- The lobby slot a unit was laid in (Lobby.front).
Arrange.SlotAttribute = "LobbySlot"

-- The screen's feel (ArrangeView).
Arrange.Feel = table.freeze({
	-- The camera's ease up over the room as Arrange opens, and back down as it closes (seconds).
	Rise = 0.7,
	-- How far below the ceiling the camera hangs, and how far in from the doorway (studs): high in
	-- the corner by the door, the whole room under it like a dollhouse.
	Below = 1.2,
	In = 1.5,
	-- Where it looks: this far into the room from its middle (fraction of the depth), on the floor.
	Look = 0.15,
	-- The front tab's camera (S5-03g3a2), facing the door from inside: this far back from the
	-- doorway (studs, kept a stud off the back wall), this high off the floor (a little over a
	-- player's head), looking at the doorway this high. On the Galaxy A16 that sets the 8-stud
	-- door from its foot to its coil between the tray and the screen's top (the limit bar rises
	-- away on this tab), and keeps the camera in front of the starter shelf (Unit1's stands 14.4
	-- back).
	FrontBack = 13.4,
	FrontEye = 6.3,
	FrontAim = 4.5,
	-- After a name card chip on the front tab (S5-03g3c), the camera stands out in the hall
	-- facing your plate: this far out from the wall (studs), this far under the plate's middle,
	-- looking at the wall this far under it, so on the Galaxy A16 the plate sits in the middle
	-- of the picture over the tray with the top of your door under it. The camera dips through
	-- black (`Dip` seconds each way) to get out there and back, never through the wall.
	HallOut = 11,
	HallBelow = 3.5,
	HallAim = 3.4,
	Dip = 0.16,
	-- The lifted find rides this high over where it would stand (studs), and settles in this long
	-- (seconds) when it lands; it follows the finger this quickly (seconds to close half the gap).
	Hover = 0.6,
	Land = 0.18,
	Follow = 0.05,
	-- A tap on a find in the shelf's cubby lifts the find, not the shelf, when its box is met no
	-- more than this far (studs) past the board the tap lands on: a finger's slack on a phone, so a
	-- tap on the teddy's edge where the cubby's side board shows still picks the teddy (S5-03i2b).
	CubbySlack = 0.35,
	-- The grid: squares this big (studs; the snap's step is finer, so a find ticks between lines).
	Grid = 1,
	-- The lines' transparency and width (pixels at 24 a stud): faint, but seen on the oak at phone
	-- size from the far wall (0.85 and 2 vanished there, S5-03e3a2).
	GridFade = 0.55,
	GridLine = 3,
	-- How high the grid floats over the floor (studs): over the rug, so it shows across it.
	GridLift = 0.09,
	-- A refused or cancelled find slides back where it came from over this long (seconds).
	Back = 0.35,
	-- The puff of dust as it lands: this many motes.
	Puff = 10,
	-- The limit bar fills or empties over this long (seconds) as a Place or Put away is answered,
	-- and slides in from above as Arrange opens over `Rise`.
	Fill = 0.35,
	-- A friend's find set out or moved settles in (SettleView): it drops this far (studs) over this
	-- long (seconds), easing in like a thing set down, with the knock heard this far away (studs).
	-- Only finds drawn this recently (seconds, by the server's clock) settle: older ones streaming
	-- in, or laid at a join, simply stand there.
	Drop = 0.5,
	Settle = 0.22,
	Hearing = 30,
	Fresh = 1.5,
})

-- The grid snap the screen drags by: half a stud, quarter turns (Bloxburg's grid).
Arrange.Step = 0.5
Arrange.Turn = 90

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
-- Lifting a find: "Magic Whooshes Pass Bys Metallic Shimmering 7" (the box reveal's whoosh),
-- short and quiet, the air moving as it rises.
Arrange.Lift = {
	id = "rbxassetid://9125646918",
	from = 0.25,
	length = 0.45,
	volume = 0.35,
	pitch = 1.3,
} :: Sound
-- Each grid square it crosses: the panel's click, quieter and higher, a tick.
Arrange.Tick = {
	id = "rbxassetid://15675059323",
	from = 0,
	length = 0.15,
	volume = 0.12,
	pitch = 1.6,
} :: Sound
-- Setting it down: the job box lid's clack, lighter and quieter, a soft knock.
Arrange.Knock = {
	id = "rbxassetid://9116436662",
	from = 1.45,
	length = 0.5,
	volume = 0.4,
	pitch = 1.05,
} :: Sound
-- Sliding back (refused, cancelled or put away): the whoosh low and soft.
Arrange.Slide = {
	id = "rbxassetid://9125646918",
	from = 0.3,
	length = 0.4,
	volume = 0.22,
	pitch = 0.75,
} :: Sound

local slotOf: { [number]: LobbySpecs.Slot } = {}
for _, slot in LobbySpecs.Slots do
	slotOf[slot.Number] = slot
end

-- Lobby slot `n`, or nil.
function Arrange.slot(n: number): LobbySpecs.Slot?
	return slotOf[n]
end

-- What's fixed in every home at size `size`: the round lamp in the ceiling, wired to the room as
-- a real unit's is (D-345), over the room's middle at every size (S5-03h5, D-354). Everything
-- else, the starter pieces too, is a row you arrange (S5-03i1b).
function Arrange.fixed(size: string): { Spots.Fixed }
	local lamp = HomeSpecs.Parts.Lamp
	return {
		{
			id = "Lamp",
			on = "Ceiling",
			at = Sizes.onWall(size, "Middle", HomeSpecs.Lamp),
			width = lamp.Size[1],
			depth = lamp.Size[3],
		},
	}
end

-- Where starter piece `kind` (`Furniture.Starter`) is pivoted to stand at pose frame `t`: its
-- spec box (`Spots.pieceBox`, not the drawn one, so the mirror keeps its lean) stood on the face,
-- its middle on the pose. `Home.Layout` lays the rows by that box.
function Arrange.starterPivot(t: CFrame, kind: string): CFrame
	local box, mid = Spots.pieceBox(kind)
	if not (box and mid) then
		return t
	end
	return t * CFrame.new(-mid[1], box[2] / 2 - mid[2], -mid[3])
end

-- Find `name`'s art box as Spots takes it (across, up, front to back), nil when the place lacks it;
-- a piece of the counter's furniture's ("CampBed:Furniture", D-336) from its parts' boxes.
function Arrange.boxOf(name: string): Spots.Vec?
	local piece = Furniture.ofPlaced(name)
	if piece then
		return (Spots.pieceBox(piece.id))
	end
	local box = Finds.box(Gold.base(name) or name)
	return if box then { box.Size.X, box.Size.Y, box.Size.Z } else nil
end

-- The footprint of what id `id` names (a find set out), for Brix to judge it by.
function Arrange.shapeOf(id: string): Brix.PlacementShape?
	local name = Spots.name(id)
	return if name then Spots.shape(name, Arrange.boxOf(name)) else nil
end

-- The unit's frame (`Arranged.face`) of lobby slot `slot`, the lobby laid at `pivot`
-- (`Lobby.Origin`), and the room's areas there at size `size` (a `Home.Sizes` name), as
-- `Spots.room` gives them.
function Arrange.areas(
	slot: LobbySpecs.Slot,
	pivot: CFrame,
	size: string
): (CFrame, { [string]: Spots.RoomArea }, Spots.Vec, Spots.Vec)
	local face = Arranged.face(pivot, slot.Door, slot.Out)
	local xlCentre, xlSize = Arranged.inside(pivot, face, slot.Inside.Centre, slot.Inside.Size)
	local centre, box = Sizes.inside(size, xlCentre, xlSize)
	return face, Spots.room(centre, box), centre, box
end

-- The room of the home in lobby slot `slot`, the lobby laid at `pivot` (`Lobby.Origin`), at size
-- `size`: its judge holding the ceiling's lamp, up to the size's limit of finds besides it and the
-- starter pieces (rows, free of the limit: `Spots.setOut`; Arranging checks the finds' count).
function Arrange.room(slot: LobbySpecs.Slot, pivot: CFrame, size: string): Room
	local face, room, centre, box = Arrange.areas(slot, pivot, size)
	local limit = Spots.limit(size)
	local areas: { [string]: Brix.PlacementArea } = {}
	local frames: { [string]: CFrame } = {}
	for name, r in room do
		areas[name] = { kind = r.kind, width = r.width, depth = r.depth }
		frames[name] = Arranged.area(face, r)
	end
	local blocks: { Spots.Block } = {}
	for _, b in Spots.blocks(room, {}, HomeSpecs.Pieces, HomeSpecs.Parts, Arrange.fixed(size)) do
		if Spots.within(room, b) then
			table.insert(blocks, b)
		end
	end
	local placements = Brix.Placements.new({
		areas = areas,
		limit = limit + #blocks + #Furniture.Starter,
	})
	for _, b in blocks do
		local refusal = placements:place(b.id, b.shape, b.pose)
		if refusal then
			warn(`Arrange: the room's {b.id} doesn't stand in unit {slot.Number} ({refusal})`)
		end
	end
	return {
		placements = placements,
		frames = frames,
		face = face,
		centre = Vector3.new(centre[1], centre[2], centre[3]),
		size = Vector3.new(box[1], box[2], box[3]),
		heights = {},
		sizeName = Sizes.of(size).name,
		limit = limit,
	}
end

local poseFrame: (room: Room, id: string) -> CFrame?

-- The world frame of area or top `on`: a room or furniture area's, or a find's own top.
function Arrange.frameOn(room: Room, on: string): CFrame?
	local frame = room.frames[on]
	if frame then
		return frame
	end
	local t = poseFrame(room, on)
	local name = Spots.name(on)
	if not (t and name) then
		return nil
	end
	local piece = Furniture.ofPlaced(name)
	if piece then -- the art's own top, wherever it stands in the piece's box (D-338)
		local _, at = Spots.pieceTop(piece.id)
		return if at then t * CFrame.new(at[1], at[2], at[3]) else nil
	end
	return Arranged.top(t, room.heights[on] or Spots.topHeight(Arrange.boxOf(name)))
end

-- Where find `id` stands now, as a pose frame (`Arranged.pose`), or nil when it isn't set out.
function poseFrame(room: Room, id: string): CFrame?
	local pose = room.placements:poseOf(id)
	local a = if pose then Arrange.frameOn(room, pose.on) else nil
	return if pose and a then Arranged.pose(a, pose.x, pose.y, pose.turn) else nil
end
Arrange.poseFrame = poseFrame

return table.freeze(Arrange)
