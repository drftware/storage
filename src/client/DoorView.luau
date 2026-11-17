--!strict
--[[
	DoorView: draws every storage unit's roll-up door on this client, wherever the server has moved
	it, as units stream in and out. The door's motion is RollUpDoor's; this system starts and stops
	the watching with the Host.

	And the cut padlock (L-11c): the moment bolt cutters take a door's padlock off, a copy of it
	drops off the latch and tumbles out onto the hall floor, where it lies a while, cut, then fades.
	Only on screens: it's scenery, so each screen throws its own (DoorSounds plays the snap and the
	clatter on the same change).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local RollUpDoor = StorageUnit.RollUpDoor

local ATTR_LOCKED = "DoorLocked"
local LOCK_PART = "Padlock" -- the unit's padlock on its latch (art/unit)
local THROW_OUT = 6 -- studs a second it's knocked out into the hall by the jaw
local THROW_UP = 12 -- and up, so it flips once and lands about a stud out (0.2 s)
local SPIN = 14 -- radians a second, at most, about each axis
local LIES = 20 -- seconds a cut padlock lies on the floor before it fades
local FADE = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local MOST = 6 -- cut padlocks lying at once on this screen; the oldest goes first
-- The latch sits in the corner of the door, the wall beside it and the floor: a copy left there
-- is wedged in all three and never moves. So it starts a little out and up, passing through
-- everything for a moment.
local START_OUT = 0.4 -- studs out from the door into the hall
local START_UP = 0.18 -- studs up off the floor
local GHOST = 0.08 -- seconds before it collides

local DoorView = {}

function DoorView.new(): Brix.System
	local stopWatching: (() -> ())? = nil
	local connections: { RBXScriptConnection } = {}
	local watched: { [Model]: { locked: boolean, conn: RBXScriptConnection } } = {}
	local lying: { BasePart } = {}
	local folder: Folder? = nil

	local function clear(piece: BasePart)
		local i = table.find(lying, piece)
		if i then
			table.remove(lying, i)
		end
		piece:Destroy()
	end

	-- The padlock on `unit`'s latch falls off and out into the hall.
	local function throw(unit: Model)
		local lock = unit:FindFirstChild(LOCK_PART, true)
		if not (lock and lock:IsA("BasePart") and folder) then
			return
		end
		if #lying >= MOST then
			clear(lying[1])
		end
		local piece = lock:Clone()
		piece:ClearAllChildren()
		local look = lock:FindFirstChildWhichIsA("SurfaceAppearance")
		if look then
			look:Clone().Parent = piece
		end
		-- out of the doorway into the hall (the door's frame has +Z into the unit, so it looks out
		-- to the hall), a little to one side, turning over
		local frame = RollUpDoor.frame(unit)
		piece.Name = "CutPadlock"
		piece.Transparency = 0
		piece.Anchored = false
		piece.CanCollide = false
		piece.CanTouch = false
		piece.CanQuery = false
		piece.Massless = false
		piece.CFrame = lock.CFrame + frame.LookVector * START_OUT + Vector3.new(0, START_UP, 0)
		piece.Parent = folder
		task.delay(GHOST, function()
			if piece.Parent then
				piece.CanCollide = true
			end
		end)
		local side = (math.random() - 0.5) * 2
		piece.AssemblyLinearVelocity = frame.LookVector * THROW_OUT
			+ frame.RightVector * side
			+ Vector3.new(0, THROW_UP, 0)
		piece.AssemblyAngularVelocity = Vector3.new(
			(math.random() - 0.5) * 2 * SPIN,
			(math.random() - 0.5) * 2 * SPIN,
			(math.random() - 0.5) * 2 * SPIN
		)
		table.insert(lying, piece)
		task.delay(LIES, function()
			if piece.Parent then
				local tween = TweenService:Create(piece, FADE, { Transparency = 1 })
				tween.Completed:Once(function()
					clear(piece)
				end)
				tween:Play()
			end
		end)
	end

	local function watch(inst: Instance)
		if not inst:IsA("Model") or watched[inst] then
			return
		end
		local unit = inst
		local w = {
			locked = unit:GetAttribute(ATTR_LOCKED) == true,
			conn = unit:GetAttributeChangedSignal(ATTR_LOCKED):Connect(function()
				local entry = watched[unit]
				local locked = unit:GetAttribute(ATTR_LOCKED) == true
				-- a home's padlock comes off with its key, so it stays out of the hall (D-275)
				local keyed = unit:GetAttribute(StorageUnit.Door.HolderAttribute) ~= nil
				if entry and entry.locked and not locked and not keyed then
					throw(unit)
				end
				if entry then
					entry.locked = locked
				end
			end),
		}
		watched[unit] = w
	end

	local function unwatch(inst: Instance)
		local w = watched[inst :: Model]
		if w then
			w.conn:Disconnect()
			watched[inst :: Model] = nil
		end
	end

	return {
		name = "DoorView",
		start = function(_: any, _context: Brix.Context)
			stopWatching = RollUpDoor.watchTagged(StorageUnit.UnitKit.Tag)
			local f = Instance.new("Folder")
			f.Name = "CutPadlocks"
			f.Parent = Workspace
			folder = f
			local tag = StorageUnit.UnitKit.Tag
			table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(watch))
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(tag):Connect(unwatch)
			)
			for _, inst in CollectionService:GetTagged(tag) do
				watch(inst)
			end
		end,
		stop = function(_: any)
			if stopWatching then
				stopWatching()
				stopWatching = nil
			end
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for unit in watched do
				unwatch(unit)
			end
			if folder then
				folder:Destroy()
				folder = nil
			end
			table.clear(lying)
		end,
	}
end

return DoorView
