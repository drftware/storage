--!strict
--[[
	ArrangeHome (S5-03j7b, taken out of ArrangeView): which home is yours, and whether you stand
	inside it. Arrange shows only to a home's holder standing in their own home, so ArrangeView
	asks `standingIn()` for the Arrange button and before opening by a held thing or the job box's
	Set out.

	It watches every unit's holder (a home changing hands, yours being taken or let go) and your
	home's size: the room inside its walls is measured again as it grows (S5-03h5, D-354), and the
	lobby slot it stands in is measured at XL (the lobby's walls round it), where the build
	camera's eye stays. `leaving` is called before your home changes and after it grows, so the
	screen closes as it does on a walk away (D-356).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local ArrangeCamera = require(script.Parent.ArrangeCamera)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local Walls = require(ReplicatedStorage.Shared.Home.Walls)

export type ArrangeHome = {
	-- Your home's model, or nil while you hold none (or it isn't streamed in).
	home: () -> Model?,
	-- The lobby slot your home stands in, at XL, or nil.
	slot: () -> ArrangeCamera.Box?,
	-- Whether you stand inside your own home now.
	standingIn: () -> boolean,
	-- Starts watching the units; `stop` lets them all go.
	start: () -> (),
	stop: () -> (),
}

local ArrangeHome = {}

function ArrangeHome.new(leaving: () -> ()): ArrangeHome
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local unitWatch: { [Instance]: RBXScriptConnection } = {}
	local home: Model? = nil
	local inside: ArrangeCamera.Box? = nil
	local slotBox: ArrangeCamera.Box? = nil
	local homeSized: RBXScriptConnection? = nil -- your home's size, re-measuring `inside`

	-- the room inside its walls at its size, and the slot at XL
	local function measure(mine: Model?)
		inside = nil
		slotBox = nil
		local n = if mine then mine:GetAttribute(Arrange.SlotAttribute) else nil
		local slot = if type(n) == "number" then Arrange.slot(n) else nil
		if mine and slot then
			local face, _, c, s = Arrange.areas(slot, Lobby.Origin, Walls.sizeOf(mine))
			inside = {
				face = face,
				centre = Vector3.new(c[1], c[2], c[3]),
				size = Vector3.new(s[1], s[2], s[3]),
			}
			local xlFace, _, xc, xs = Arrange.areas(slot, Lobby.Origin, Sizes.Biggest)
			slotBox = {
				face = xlFace,
				centre = Vector3.new(xc[1], xc[2], xc[3]),
				size = Vector3.new(xs[1], xs[2], xs[3]),
			}
		end
	end

	local function findHome()
		local mine: Model? = nil
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			if inst:IsA("Model") and inst:GetAttribute(Door.HolderAttribute) == me.UserId then
				mine = inst
				break
			end
		end
		if mine == home then
			return
		end
		leaving()
		home = mine
		if homeSized then
			homeSized:Disconnect()
			homeSized = nil
		end
		measure(mine)
		if mine then
			homeSized = mine:GetAttributeChangedSignal(Spots.SizeAttribute):Connect(function()
				measure(mine)
				-- it grew while you arranged (a friend's gift; S5-03h6, D-356): the room you were
				-- judging is laid again bigger, so the screen closes as it does on a walk away,
				-- a lifted piece sliding back, and the walls grind back round you
				leaving()
			end)
		end
	end

	local function watchUnit(inst: Instance)
		if inst:IsA("Model") and not unitWatch[inst] then
			unitWatch[inst] = inst:GetAttributeChangedSignal(Door.HolderAttribute):Connect(findHome)
		end
		findHome()
	end

	return {
		home = function(): Model?
			return home
		end,
		slot = function(): ArrangeCamera.Box?
			return slotBox
		end,
		standingIn = function(): boolean
			local box = inside
			local character = me.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if not (box and root and root:IsA("BasePart")) then
				return false
			end
			local p = box.face:PointToObjectSpace(root.Position) - box.centre
			local h = box.size / 2
			return math.abs(p.X) <= h.X and math.abs(p.Z) <= h.Z and math.abs(p.Y) <= h.Y + 2
		end,
		start = function()
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(watchUnit)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(UnitKit.Tag)
					:Connect(function(inst: Instance)
						local w = unitWatch[inst]
						if w then
							w:Disconnect()
							unitWatch[inst] = nil
						end
						findHome()
					end)
			)
			for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
				watchUnit(inst)
			end
		end,
		stop = function()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, w in unitWatch do
				w:Disconnect()
			end
			table.clear(unitWatch)
			if homeSized then
				homeSized:Disconnect()
				homeSized = nil
			end
		end,
	}
end

return ArrangeHome
