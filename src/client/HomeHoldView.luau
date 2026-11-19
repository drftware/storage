--!strict
--[[
	HomeHoldView: a finger held on one of your things at home opens Arrange with it lifted
	(S5-03j5b2, D-466). The moment: in your home you press and hold on the lamp on the job box;
	Arrange rises round you, the camera lifting to it, and the lamp is already up in your fingers,
	ready to drag; let go and it lands. As The Sims' and Animal Crossing's press-and-hold picks up a
	piece of furniture.

	Brix's Gestures reads the press (its `hold`, after `Arrange.Feel.HoldOpen` seconds still), so a
	tap, a look round or a walk never trips it; a tap still reaches the find's own Take button as
	before. Only your own things set out in your home (`Spots.Tag`, its owner you), seen from where
	you look (a ray that stops at the first thing it meets, so never through a wall), only while
	Arrange is shut (your tools aren't stowed) and you stand in your home (ArrangeView's `grab`
	checks that, and that nothing is lifted). A hold on a friend's thing or bare floor does nothing.

	Called by the client's bootstrap with ArrangeView's `grab`, which opens Arrange and hands the
	held finger to the hand, so the drag, the let-go, undo and the server's Place are Arrange's own.
	Nothing steps unless a press is down: one render step from the press till it's let go or held.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Take = require(ReplicatedStorage.Shared.Home.Take)
local Tools = require(ReplicatedStorage.Shared.Tools)

-- Opens Arrange with `thing` lifted under the press `input` (ArrangeView's `grab`).
export type Grab = (thing: Model, input: InputObject) -> ()

local MOUSE = "mouseLeft" -- the left button's pointer key to Gestures
local REACH = 200 -- studs a look reaches for a thing

local HomeHoldView = {}

-- Your thing set out that `inst` is part of, or nil.
local function yoursOf(inst: Instance?, me: Player): Model?
	while inst and inst ~= Workspace do
		if inst:IsA("Model") and inst:HasTag(Spots.Tag) then
			local mine = inst:GetAttribute(Spots.OwnerAttribute) == me.UserId
				and inst:GetAttribute(Take.Attribute) == nil
			return if mine then inst else nil
		end
		inst = inst.Parent
	end
	return nil
end

function HomeHoldView.new(grab: Grab): Brix.System
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local stepping: RBXScriptConnection? = nil
	-- each press down, by its Gestures key: the InputObject that will carry the drag on
	local downs: { [any]: InputObject } = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local gestures = Brix.Gestures.new({
		-- gui points, as `InputObject.Position` gives them
		pick = function(x: number, y: number): Model?
			local camera = Workspace.CurrentCamera
			if not camera then
				return nil
			end
			local ray = camera:ScreenPointToRay(x, y)
			params.FilterDescendantsInstances = { me.Character :: Instance, camera }
			local hit = Workspace:Raycast(ray.Origin, ray.Direction * REACH, params)
			return yoursOf(if hit then hit.Instance else nil, me)
		end,
		holdTime = Arrange.Feel.HoldOpen,
	})

	local function stop()
		local s = stepping
		stepping = nil
		if s then
			s:Disconnect()
		end
	end

	local function forget()
		stop()
		table.clear(downs)
		gestures:cancel()
		gestures:takeIntents()
	end

	local function step()
		gestures:advance(os.clock())
		for _, i in gestures:takeIntents() do
			if i.kind == "hold" then
				local thing = i.target
				-- the press it came from: the one down nearest where it's held
				local input: InputObject? = nil
				local best = math.huge
				for _, d in downs do
					local far = (Vector2.new(d.Position.X, d.Position.Y) - Vector2.new(i.x, i.y)).Magnitude
					if far < best then
						input, best = d, far
					end
				end
				forget()
				if thing and input and thing.Parent then
					grab(thing, input)
				end
				return
			end
		end
		if next(downs) == nil then
			stop()
		end
	end

	local function shut(): boolean
		return me:GetAttribute(Tools.StowAttribute) ~= true
	end

	local function began(input: InputObject, processed: boolean)
		local t = input.UserInputType
		if processed or not shut() then
			return
		end
		local p = input.Position
		if t == Enum.UserInputType.Touch then
			downs[input] = input
			gestures:press(input, p.X, p.Y, "touch", os.clock())
		elseif t == Enum.UserInputType.MouseButton1 then
			downs[MOUSE] = input
			gestures:press(MOUSE, p.X, p.Y, "left", os.clock())
		else
			return
		end
		if not stepping then
			stepping = RunService.RenderStepped:Connect(step)
		end
	end

	local function changed(input: InputObject)
		if next(downs) == nil then
			return
		end
		local t, p = input.UserInputType, input.Position
		if t == Enum.UserInputType.Touch and downs[input] then
			gestures:move(input, p.X, p.Y, os.clock())
		elseif t == Enum.UserInputType.MouseMovement and downs[MOUSE] then
			gestures:move(MOUSE, p.X, p.Y, os.clock())
		end
	end

	local function ended(input: InputObject)
		local t, p = input.UserInputType, input.Position
		if t == Enum.UserInputType.Touch and downs[input] then
			downs[input] = nil
			gestures:release(input, p.X, p.Y, os.clock())
		elseif t == Enum.UserInputType.MouseButton1 and downs[MOUSE] then
			downs[MOUSE] = nil
			gestures:release(MOUSE, p.X, p.Y, os.clock())
		end
	end

	return {
		name = "HomeHoldView",
		start = function(_: any)
			table.insert(connections, UserInputService.InputBegan:Connect(began))
			table.insert(connections, UserInputService.InputChanged:Connect(changed))
			table.insert(connections, UserInputService.InputEnded:Connect(ended))
			table.insert(connections, UserInputService.WindowFocusReleased:Connect(forget))
		end,
		stop = function(_: any)
			forget()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

return HomeHoldView
