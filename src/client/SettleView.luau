--!strict
--[[
	SettleView: a find a friend sets out in their home settles into place on this screen
	(S5-03e3b), as Animal Crossing's furniture does while a friend decorates: it drops a little and
	lands with the knock your own Arrange screen plays, heard nearby, rather than popping in.

	The server draws every find (Arranging) and stays the truth. A find it draws by a move carries
	the server's time (`Arrange.WhenAttribute`); this screen lifts it a hand's width and eases it
	down onto where the server put it (one on the ceiling rises up into place instead). One drawn
	longer ago than `Feel.Fresh` (streaming in, or laid as a friend joined) simply stands. Your own
	finds are left to your Arrange screen, which lands its own ghost there.

	Only finds settling are stepped; a find streaming out mid-drop is let go.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Feel = Arrange.Feel

-- A find dropping into place: where the server drew it, how high over it the drop begins (down
-- for a find on the ceiling), how far in (seconds), and where this screen last put it.
type Settling = { target: CFrame, lift: Vector3, t: number, set: CFrame }

local SettleView = {}

function SettleView.new(): Brix.System
	local me = Players.LocalPlayer
	local settling: { [Model]: Settling } = {}
	local watched: { [Model]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}

	-- Starts `model` settling if a friend's move drew it just now.
	local function check(model: Model)
		if not model.Parent or model:GetAttribute(Spots.OwnerAttribute) == me.UserId then
			return
		end
		local when = model:GetAttribute(Arrange.WhenAttribute)
		local age = if type(when) == "number"
			then Workspace:GetServerTimeNow() - when
			else math.huge
		if age > Feel.Fresh or age < -Feel.Fresh then
			return
		end
		local id = model:GetAttribute(Spots.IdAttribute)
		local name = if type(id) == "string" then Spots.name(id) else nil
		local up = if name and Spots.spot(name) == "Ceiling" then -1 else 1
		local now = model:GetPivot()
		local was = settling[model]
		-- mid-drop: where this screen holds it is no place of the server's, unless it moved it again
		local target = if was and (now.Position - was.set.Position).Magnitude < 1e-3
			then was.target
			else now
		local lift = Vector3.yAxis * (Feel.Drop * up)
		local start = target + lift
		settling[model] = { target = target, lift = lift, t = 0, set = start }
		model:PivotTo(start)
	end

	local function add(inst: Instance)
		if watched[inst :: any] or not inst:IsA("Model") then -- any: a tagged Instance
			return
		end
		local model = inst :: Model
		watched[model] = model:GetAttributeChangedSignal(Arrange.WhenAttribute):Connect(function()
			task.defer(check, model) -- after the move's frame has reached this screen
		end)
		check(model)
	end

	local function remove(inst: Instance)
		local model = inst :: any -- any: the removed signal hands back an Instance
		local c = watched[model]
		if c then
			c:Disconnect()
			watched[model] = nil
		end
		settling[model] = nil
	end

	return {
		name = "SettleView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { Arrange.Knock.id })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Spots.Tag):Connect(function(inst)
					task.defer(add, inst) -- its attributes and parts are in by then
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Spots.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Spots.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			for model, s in settling do
				if not model.Parent then
					settling[model] = nil
					continue
				end
				s.t += dt
				local a = math.min(s.t / Feel.Settle, 1)
				-- falling: slow off the lift, quickest as it lands
				local at = s.target + s.lift * (1 - a * a)
				model:PivotTo(at)
				s.set = at
				if a >= 1 then
					settling[model] = nil
					local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
					if part then
						Tools.play(Arrange.Knock, part, Feel.Hearing)
					end
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in watched do
				remove(model)
			end
		end,
	}
end

return SettleView
