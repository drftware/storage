--!strict
--[[
	FindUses: pressing a find on the server (F-G1b2, D-229), a system like `Horns`. A press comes
	in as `Slots.used` (a living player with a find with a verb in hand, the press's rate already
	checked by Slots); here it must wait out `Use.Gap` since that player's last press, and the find
	must take the press now (`Use.press` against the stamp on its model: a burning tea light, a
	spent glow stick or a jack still mid-tune takes none). Then the stamp: the model gets its
	state, the server clock and the light left as attributes, and the tag, and every screen plays
	it from there (`FindUseView`). The same model moves from hand to floor and back, so a lantern
	dropped lit stays lit. A noisy find (the jack) is heard by every monster on the floor as its
	bang starts, where the find is then, unless it was pressed again since.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Keepers = require(script.Parent.Keepers)
local Slots = require(script.Parent.Slots)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

local FindUses = {}

-- The stamp on `model`, nil if it was never pressed.
local function stampOf(model: Model): Use.Stamp?
	return Use.read(
		model:GetAttribute(Use.StateAttribute),
		model:GetAttribute(Use.AtAttribute),
		model:GetAttribute(Use.LeftAttribute)
	)
end

function FindUses.new(): Brix.System
	local connections: { Brix.SignalConnection } = {}
	local leaving: RBXScriptConnection? = nil
	local last: { [Player]: number } = {} -- each player's last press that took, os.clock
	local keepers: Keepers.Keepers? = nil

	-- The jack's bang, `delay` seconds after the press stamped `at`: heard where the find is then.
	local function bang(model: Model, at: number, delay: number, who: string)
		task.delay(delay, function()
			if model.Parent == nil or model:GetAttribute(Use.AtAttribute) ~= at then
				return
			end
			local heard = if keepers then keepers:hearHorn(model:GetPivot().Position) else 0
			if RunService:IsStudio() then
				print(
					`FindUses: {who}'s {model:GetAttribute(Use.KeyAttribute)} went bang; {heard} heard it`
				)
			end
		end)
	end

	local function onUsed(use: Slots.Use)
		local row = Use.Rows[use.key]
		if not row then
			return
		end
		local player = use.player
		local t = os.clock()
		local before = last[player]
		if before and t - before < Use.Gap then
			return
		end
		local model = use.model
		local durations = Finds.durations(use.key)
		local now = Workspace:GetServerTimeNow()
		local stamp = stampOf(model)
		local pressed, left = Use.press(row, stamp, if stamp then now - stamp.at else 0, durations)
		if not pressed then
			return
		end
		local state: Use.State = pressed :: Use.State
		last[player] = t
		model:SetAttribute(Use.KeyAttribute, use.key)
		model:SetAttribute(Use.StateAttribute, state)
		model:SetAttribute(Use.LeftAttribute, Use.encode(left))
		-- last, so a screen reading the stamp on this change sees all of it
		model:SetAttribute(Use.AtAttribute, now)
		CollectionService:AddTag(model, Use.Tag)
		local delay = Use.noiseAt(row, state, durations)
		if delay then
			bang(model, now, delay, player.Name)
		end
	end

	local system = { name = "FindUses" }

	function system.start(_: any, context: Brix.Context)
		local s = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry's
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers?
		if s then
			table.insert(connections, s.used:connect(onUsed))
		else
			warn("FindUses: no Slots system, so nobody can use a find")
		end
		leaving = Players.PlayerRemoving:Connect(function(player: Player)
			last[player] = nil
		end)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		if leaving then
			leaving:Disconnect()
			leaving = nil
		end
		table.clear(last)
	end

	return system :: any -- any: a plain Brix system built field by field
end

return FindUses
