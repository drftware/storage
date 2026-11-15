--!strict
--[[
	NotePlaces: a code note on its way somewhere, on every screen near it (B-04b, D-214).

	- Pinned: you walk up to the keypad holding notes, and each paper leaves your hand in a short
	  arc, turning as it flies, and lands flat on the wall beside the keypad with a tack's tap and
	  a tiny press into the wall. The team's clues gather where the code goes in.
	- Dropped: caught or gone, each paper leaves the hand with a flap and tumbles to the floor,
	  rocking side to side as a loose sheet does, and settles with a soft one where it lies.

	The server has already put the note where it ends (Pockets) and stamped how it got there
	(`NoteCard.Placed`, `PlacedAt`, `PlacedFrom`). This screen moves its own copy along the way,
	once, if it sees the note while it's fresh (`NoteCard.PlacedFresh`); a note that streams in
	later just lies where it is. Only notes in flight are stepped, and the step stops with the last.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local NoteCard = require(ReplicatedStorage.Shared.Elevator.NoteCard)

-- The flap of a sheet of paper (Pro Sound Effects, "File Folder Movement 5", NoteView's): its one
-- sharp flap. Leaving the hand, and softer and lower as it settles on the floor.
local FLAP = { Id = "rbxassetid://9114409576", Start = 0.74, Stop = 1.0 }
local FLAP_OUT = { volume = 0.5, pitch = 1.05 }
local FLAP_DOWN = { volume = 0.28, pitch = 0.8 }
-- A tack pressed in: the sharp toggle click (Pro Sound Effects, "Moviola Toggle Switch Single
-- Clicks Sharp 8", the unit light's), its first click alone, pitched up small and bright.
local TAP = { Id = "rbxassetid://9117028600", Start = 0, Stop = 0.16, volume = 0.6, pitch = 1.55 }
-- Heard full within this many studs, gone by the second: the lobby round the keypad.
local NEAR, REACH = 5, 34
-- Landing on the wall, the paper presses in from this far off its face over this long.
local PRESS_OUT, PRESS = 0.06, 0.07
-- Leaving the hand, a dropped sheet hangs upright, turned this much off flat.
local DROP_UPRIGHT = math.rad(75)

type Flight = {
	model: Model,
	paper: BasePart,
	from: CFrame,
	to: CFrame,
	start: number, -- os.clock() it left the hand
	pinned: boolean,
	landed: boolean,
	sway: Vector3, -- a dropped sheet's rocking, across the way it falls
}

local NotePlaces = {}

function NotePlaces.new(): Brix.System
	local flights: { [Model]: Flight } = {}
	local connections: { RBXScriptConnection } = {}
	local stepping: RBXScriptConnection? = nil

	local function play(
		paper: BasePart,
		sound: { Id: string, Start: number, Stop: number },
		volume: number,
		pitch: number
	)
		local s = Instance.new("Sound")
		s.SoundId = sound.Id
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(sound.Start, sound.Stop)
		s.Volume = volume
		s.PlaybackSpeed = pitch * (0.95 + math.random() * 0.1)
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = NEAR
		s.RollOffMaxDistance = REACH
		s.Parent = paper
		s.Ended:Once(function()
			s:Destroy()
		end)
		s:Play()
		task.delay(1, function()
			if s.Parent then
				s:Destroy()
			end
		end)
	end

	local function stop()
		local c = stepping
		if c then
			c:Disconnect()
			stepping = nil
		end
	end

	-- Where `f` is `t` seconds after it left the hand, and whether it's done.
	local function pose(f: Flight, t: number): (CFrame, boolean)
		if f.pinned then
			local fly = NoteCard.PinFly
			if t >= fly then
				-- pressed into the wall
				local k = math.min(1, (t - fly) / PRESS)
				return f.to * CFrame.new(0, 0, -PRESS_OUT * (1 - k)), k >= 1
			end
			local u = t / fly
			local e = 1 - (1 - u) * (1 - u) -- quick off the hand, easing onto the wall
			local at = f.from.Position:Lerp(f.to.Position, e)
				+ Vector3.new(0, math.sin(math.pi * u) * NoteCard.PinArc, 0)
			local spin = (1 - e) * math.pi / 2
			local rot = f.from.Rotation:Lerp(f.to.Rotation, e) * CFrame.Angles(0, 0, spin)
			return CFrame.new(at) * rot, false
		end
		local fall = NoteCard.DropFall
		local u = math.min(1, t / fall)
		local drop = u * u * (3 - 2 * u) -- a sheet: slow off the hand, slow again as air catches it
		local rock = math.sin(u * NoteCard.DropRocks * 2 * math.pi) * (1 - u)
		local at = f.from.Position:Lerp(f.to.Position, drop) + f.sway * (rock * NoteCard.DropSway)
		local rot = f.from.Rotation:Lerp(f.to.Rotation, u) * CFrame.Angles(0, 0, rock * 0.5)
		return CFrame.new(at) * rot, u >= 1
	end

	local function step()
		local now = os.clock()
		for model, f in flights do
			if not model.Parent then
				flights[model] = nil
				continue
			end
			local frame, done = pose(f, now - f.start)
			model:PivotTo(frame)
			if f.pinned and not f.landed and now - f.start >= NoteCard.PinFly then
				f.landed = true
				play(f.paper, TAP, TAP.volume, TAP.pitch)
			end
			if done then
				model:PivotTo(f.to)
				if not f.pinned then
					play(f.paper, FLAP, FLAP_DOWN.volume, FLAP_DOWN.pitch)
				end
				flights[model] = nil
			end
		end
		if next(flights) == nil then
			stop()
		end
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or flights[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local how = inst:GetAttribute(NoteCard.Placed)
		local at = inst:GetAttribute(NoteCard.PlacedAt)
		local from = inst:GetAttribute(NoteCard.PlacedFrom)
		if not (type(at) == "number" and typeof(from) == "Vector3") then
			return
		end
		if Workspace:GetServerTimeNow() - at > NoteCard.PlacedFresh then
			return -- streamed in late: it just lies there
		end
		local paper = inst:FindFirstChild("Paper")
		if not (paper and paper:IsA("BasePart")) then
			return
		end
		local to = inst:GetPivot()
		local pinned = how == "Pinned"
		local start: CFrame
		local sway = Vector3.zero
		if pinned then
			-- leaves the hand facing where it flies, a quarter turn off how it lands
			start = CFrame.new(from) * to.Rotation * CFrame.Angles(0, 0, -math.pi / 2)
		else
			-- hangs nearly upright in the hand, turned as it will lie, then tips over as it falls
			start = CFrame.new(from) * to.Rotation * CFrame.Angles(-DROP_UPRIGHT, 0, 0)
			local across = to.RightVector
			sway = Vector3.new(across.X, 0, across.Z)
			sway = if sway.Magnitude > 0 then sway.Unit else Vector3.xAxis
			play(paper, FLAP, FLAP_OUT.volume, FLAP_OUT.pitch)
		end
		flights[inst] = {
			model = inst,
			paper = paper,
			from = start,
			to = to,
			start = os.clock(),
			pinned = pinned,
			landed = false,
			sway = sway,
		}
		inst:PivotTo(start)
		if not stepping then
			stepping = RunService.RenderStepped:Connect(step)
		end
	end

	return {
		name = "NotePlaces",
		start = function(_: any, _context: Brix.Context)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.NoteTag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.NoteTag)
					:Connect(function(inst: Instance)
						if inst:IsA("Model") then
							flights[inst] = nil
						end
					end)
			)
		end,
		stop = function(_: any)
			stop()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			table.clear(flights)
		end,
	}
end

return NotePlaces
