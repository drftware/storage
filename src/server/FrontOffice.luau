--!strict
--[[
	FrontOffice: lays Everkeep's front office (the lobby, L-08e1a) at `Lobby.Origin` on every
	server, from the template in the place (ReplicatedStorage.Props.Lobby) and the art's Specs, and
	makes it where everyone loads in (L-08e1b1): a spawn just inside the front door, facing the six
	cars (LobbyCars runs them). The place's own baseplate and spawn pad go: this runs only on a
	running server (Play, or live), on its copy of the place.

	Each home's light switch is its button here (S5-03a2b3): "Switch" from just inside the door
	flips the unit's light (Home.LightAttribute), which every screen draws (HomeLights). Anyone
	in reach may flip it until homes have owners (S5-03a3).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Prompts = require(script.Parent.Prompts)

export type FrontOffice = Brix.System & {
	-- The lobby as laid, or nil if the place has no template.
	laid: (self: FrontOffice) -> Lobby.Laid?,
}

local FrontOffice = {}

-- A home's switch: its button just off the plate, into the room. Pressed, the light flips; flips
-- closer together than Home.Switch.Cooldown are dropped (someone mashing it).
local function wireSwitch(unit: Model): RBXScriptConnection?
	local plate = unit:FindFirstChild("Switch")
	if not (plate and plate:IsA("BasePart")) then
		return nil
	end
	-- the button hangs on a spot of its own just off the plate, into the room (the plate's frame is
	-- the unit's: +Z is in): the plate sits inside the front's wall collider, which would stand in
	-- the way of the line-of-sight check. Seen to show and press from here (Studio, S5-03a2b4)
	local spot = Instance.new("Part")
	spot.Name = "SwitchSpot"
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanTouch = false
	spot.CanQuery = false
	spot.CastShadow = false
	spot.Transparency = 1
	spot.Size = Vector3.one * 0.2
	spot.CFrame = plate.CFrame * CFrame.new(0, 0, 0.6)
	spot.Parent = unit
	local at = Instance.new("Attachment")
	at.Name = "SwitchButton"
	at.Parent = spot
	local prompt = Prompts.make(at, {
		actionText = "Switch",
		-- its own key: inside a shut home the door's Lift is on E, and the nearer button took it
		-- (Studio, S5-03a2b3); on a phone each button is its own tap
		key = Enum.KeyCode.T,
		pad = Enum.KeyCode.DPadUp,
		reach = Home.Switch.Reach,
	})
	local last = -math.huge
	return prompt.Triggered:Connect(function(player: Player)
		if Prompts.wrapped(player) then
			return
		end
		local t = os.clock()
		if t - last < Home.Switch.Cooldown then
			return
		end
		last = t
		unit:SetAttribute(Home.LightAttribute, unit:GetAttribute(Home.LightAttribute) ~= true)
	end)
end

function FrontOffice.new(): FrontOffice
	local laid: Lobby.Laid? = nil
	local switches: { RBXScriptConnection } = {}
	return {
		name = "FrontOffice",
		start = function(_: any)
			local l = Lobby.lay(Lobby.Origin, Workspace)
			laid = l
			if not l then
				return
			end
			for _, d in Workspace:GetDescendants() do
				if d:IsA("SpawnLocation") then
					d:Destroy()
				end
			end
			local baseplate = Workspace:FindFirstChild("Baseplate")
			if baseplate then
				baseplate:Destroy()
			end
			-- you load in just inside the door, turned to the cars: a spawn's own facing is the
			-- one a new character takes (and LobbyView turns the camera to it)
			local at = Lobby.spawn(l.pivot)
			local spawn = Instance.new("SpawnLocation")
			spawn.Name = "LobbySpawn"
			spawn.Anchored = true
			spawn.CanCollide = false
			spawn.CanQuery = false
			spawn.CanTouch = false
			spawn.Transparency = 1
			spawn.Neutral = true
			spawn.Duration = 0
			spawn.Size = Vector3.new(4, 0.2, 4)
			spawn.CFrame = at - Vector3.new(0, at.Position.Y - l.pivot.Position.Y - 0.1, 0)
			spawn.Parent = l.folder
			-- anyone already in (Studio's Play can load a character first) is put there too
			for _, player in Players:GetPlayers() do
				if player.Character then
					player.Character:PivotTo(at)
				end
			end
			for _, unit in l.units do
				local c = wireSwitch(unit)
				if c then
					table.insert(switches, c)
				end
			end
			print(
				`FrontOffice: the lobby is laid, {#l.cars} cars in their bays, {#switches} homes lit`
			)
		end,
		stop = function(_: any)
			for _, c in switches do
				c:Disconnect()
			end
			table.clear(switches)
			if laid then
				laid.folder:Destroy()
				laid = nil
			end
		end,
		laid = function(_: FrontOffice): Lobby.Laid?
			return laid
		end,
	}
end

return FrontOffice
