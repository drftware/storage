--!strict
--[[
	Kneels: who's down on their knees peeking under a door, for every screen (L-06b5b). A player's
	own screen drops their view the moment they tap Peek (KneelView); this tags their character
	`Kneel.Tag` once the server has lifted the door for them, so every friend's screen kneels their
	body. The same pure rule as their screen (`Kneel`): they stay down while the door holds its peek
	and they stay where they knelt; any other move of that door, a step or a jump stands them up.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Doors = require(script.Parent.Doors)
local Kneel = require(ReplicatedStorage.Shared.StorageUnit.Kneel)

type Down = {
	player: Player,
	character: Model,
	root: BasePart,
	unit: Model,
	hold: Kneel.Hold,
}

local Kneels = {}

function Kneels.new(): Brix.System
	local down: { [Player]: Down } = {}
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}

	local function stand(d: Down)
		if down[d.player] == d then
			down[d.player] = nil
		end
		if d.character.Parent then
			d.character:RemoveTag(Kneel.Tag)
		end
	end

	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if not motion then
			return -- a padlock on or off: the door didn't move
		end
		-- the door moved: whoever was down at it stands, unless it's their own peek lifting it
		for _, d in down do
			if d.unit == event.unit and not Kneel.doorMoved(d.hold, motion) then
				stand(d)
			end
		end
		local player = event.player
		if not (player and event.action == "Peek" and motion == "Peek") then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (character and root and root:IsA("BasePart")) then
			return
		end
		local was = down[player]
		if was then
			stand(was)
		end
		local p = root.Position
		down[player] = {
			player = player,
			character = character,
			root = root,
			unit = event.unit,
			hold = Kneel.start(p.X, p.Y, p.Z, os.clock(), true),
		}
		character:AddTag(Kneel.Tag)
	end

	return {
		name = "Kneels",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back a plain System; Doors fills this slot (init.server)
			local doors = (context.registry:get("doors") :: any) :: Doors.Doors
			table.insert(signals, doors.acted:connect(onActed))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local d = down[player]
					if d then
						stand(d)
					end
				end)
			)
		end,
		-- Only players down: each one stepped off, jumped, respawned or gone stands.
		step = function(_: any, _dt: number)
			if next(down) == nil then
				return
			end
			local t = os.clock()
			for _, d in down do
				local p = d.root.Position
				if
					d.player.Character ~= d.character
					or not d.root.Parent
					or not Kneel.holds(d.hold, t, p.X, p.Y, p.Z)
				then
					stand(d)
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, s in signals do
				s:disconnect()
			end
			table.clear(signals)
			for _, d in down do
				stand(d)
			end
		end,
	}
end

return Kneels
