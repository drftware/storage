--!strict
--[[
	ArrangeFront (S5-03j7b, taken out of ArrangeView): where the camera stands on the tray's front
	tab, where you paint your door and pick your home's card. It swings round to face your door from
	near the back of the room (S5-03g3a2), or, after a card chip is tapped, goes out through black
	into the hall to face your home's plate (S5-03g3c). Back to the door each time Arrange opens.

	ArrangeView asks `view` when the front tab opens and calls `focus` when LooksTab's chips are
	tapped; it hands in the build camera's `show` and what's open now.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local CardPlate = require(ReplicatedStorage.Shared.Home.CardPlate)
local Home = require(ReplicatedStorage.Shared.Home)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)

local Feel = Arrange.Feel

export type Options = {
	home: () -> Model?, -- your home
	-- The room being arranged while the front tab shows (nil when shut or on another tab).
	facing: () -> Arrange.Room?,
	-- The build camera to `at`, through black when `through` (ArrangeCamera.show).
	show: (at: CFrame, through: boolean) -> (),
}

export type ArrangeFront = {
	-- The door's view of room `r`, a little over head height from near its back.
	door: (r: Arrange.Room) -> CFrame,
	-- Where the front tab's camera stands now: the plate's, else the door's.
	view: (r: Arrange.Room) -> CFrame,
	-- Whether it's out in the hall facing the plate.
	inHall: () -> boolean,
	-- A door or card chip tapped: the camera goes to the door, or out to the plate.
	focus: (kind: Looks.Kind) -> (),
	-- Back to the door, as Arrange opens.
	reset: () -> (),
}

local ArrangeFront = {}

function ArrangeFront.new(o: Options): ArrangeFront
	local at: "door" | "card" = "door"

	-- Near the back of the room, a little over head height, facing the door; the doorway's head
	-- and an open door's coil in view above the tray.
	local function door(r: Arrange.Room): CFrame
		local c, s = r.centre, r.size
		local doorZ, floor = c.Z - s.Z / 2, c.Y - s.Y / 2
		local back = math.min(Feel.FrontBack, s.Z - 1)
		local eye = r.face * Vector3.new(c.X, floor + Feel.FrontEye, doorZ + back)
		local look = r.face * Vector3.new(c.X, floor + Feel.FrontAim, doorZ)
		return CFrame.lookAt(eye, look)
	end

	-- Out in the hall facing your home's plate, a little under it. Nil when the card isn't here
	-- (not streamed in).
	local function hall(): CFrame?
		local h = o.home()
		local n = if h then h:GetAttribute(Arrange.SlotAttribute) else nil
		if n == nil then
			return nil
		end
		for _, card in CollectionService:GetTagged(Home.CardTag) do
			local wall = card:GetAttribute(CardPlate.WallAttribute)
			if card:GetAttribute(Home.CardSlot) == n and typeof(wall) == "CFrame" then
				local eye = wall * Vector3.new(0, -Feel.HallBelow, -Feel.HallOut)
				return CFrame.lookAt(eye, wall * Vector3.new(0, -Feel.HallAim, 0))
			end
		end
		return nil
	end

	local function view(r: Arrange.Room): CFrame
		return (if at == "card" then hall() else nil) or door(r)
	end

	return {
		door = door,
		view = view,
		inHall = function(): boolean
			return at == "card"
		end,
		focus = function(kind: Looks.Kind)
			local r = o.facing()
			local want: "door" | "card" = if kind == "card" then "card" else "door"
			if not r or want == at then
				return
			end
			if want == "card" and not hall() then
				return -- the plate isn't here to look at: stay on the door
			end
			at = want
			o.show(view(r), true)
		end,
		reset = function()
			at = "door"
		end,
	}
end

return ArrangeFront
