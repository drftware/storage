--!strict
--[[
	FrontOffice: lays Everkeep's front office (the lobby, L-08e1a) at `Lobby.Origin` on every
	server, from the template in the place (ReplicatedStorage.Props.Lobby) and the art's Specs, and
	makes it where everyone loads in (L-08e1b1): a spawn just inside the front door, facing the six
	cars (LobbyCars runs them). The place's own baseplate and spawn pad go: this runs only on a
	running server (Play, or live), on its copy of the place.

	Each home's light switch is its button here (S5-03a2b3): "Switch" from just inside the door
	flips the unit's light (Home.LightAttribute), which every screen draws (HomeLights). Only the
	home's holder flips it (D-263); a spare home's switch answers nobody.

	A home each (S5-03a3b, D-275): Brix's Plots and PlayerPlots hand each player one of the twelve
	homes as they join, nearest the spawn first (Home.Holding.order). A beat after they first stand
	in the lobby their name goes on the home's card (HomeCards sprays it on) and its padlock comes
	off as the door rolls up; it's theirs (Door.HolderAttribute) until they leave, when the card
	blanks, the door comes down and the padlock goes back on.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Doors = require(script.Parent.Doors)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local LobbySpecs = require(ReplicatedStorage.Shared.Lobby.Specs)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)

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
		if Prompts.wrapped(player) or unit:GetAttribute(Door.HolderAttribute) ~= player.UserId then
			return -- the holder's own (its button shows only on their screen, HomeCards)
		end
		local t = os.clock()
		if t - last < Home.Switch.Cooldown then
			return
		end
		last = t
		unit:SetAttribute(Home.LightAttribute, unit:GetAttribute(Home.LightAttribute) ~= true)
	end)
end

local Holding = require(ReplicatedStorage.Shared.Home.Holding)

function FrontOffice.new(): FrontOffice
	local laid: Lobby.Laid? = nil
	local switches: { RBXScriptConnection } = {}
	local playerPlots: Brix.PlayerPlots? = nil
	local turns: { [string]: number } = {} -- each home's hand-outs so far: a stale wait gives up
	local doors: Doors.Doors? = nil

	-- `plot` is `player`'s: their name on its card, its padlock off as its door rolls up, its light on.
	local function arrive(l: Lobby.Laid, plot: string, player: Player, turn: number)
		local n = Holding.number(plot)
		local unit = n and l.units[n]
		local card = n and l.cards[n]
		if not (unit and card) or turns[plot] ~= turn or player.Parent == nil then
			return
		end
		unit:SetAttribute(Door.HolderAttribute, player.UserId)
		unit:SetAttribute(Home.LightAttribute, true)
		card.Text = Holding.words(player.DisplayName)
		task.delay(Holding.Arrive.DoorAfter, function()
			if turns[plot] ~= turn or not unit.Parent then
				return
			end
			local d = doors
			if d then
				d:lock(unit, false)
				d:move(unit, "Open")
			else
				RollUpDoor.setLocked(unit, false)
				RollUpDoor.play(unit, "Open")
			end
		end)
	end

	-- `plot` let go: its card blank, its door down and padlocked again, its light left on.
	local function leave(l: Lobby.Laid, plot: string)
		local n = Holding.number(plot)
		local unit = n and l.units[n]
		local card = n and l.cards[n]
		if not (unit and card) then
			return
		end
		local turn = (turns[plot] or 0) + 1
		turns[plot] = turn
		unit:SetAttribute(Door.HolderAttribute, 0)
		unit:SetAttribute(Home.LightAttribute, true)
		card.Text = ""
		local d = doors
		if not d then
			return
		end
		d:move(unit, "Close")
		local _, from, to = Motion.decode(unit:GetAttribute("DoorMotion") :: string?)
		local spec = RollUpDoor.spec(unit)
		task.delay(Motion.duration("Close", from, to, spec.Rise.Open) + 0.1, function()
			if turns[plot] == turn and unit.Parent and d:stateOf(unit) == "Closed" then
				d:lock(unit, true)
			end
		end)
	end

	return {
		name = "FrontOffice",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back plain Systems; each slot is filled by its system
			doors = (context.registry:get("doors") :: any) :: Doors.Doors?
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
			-- a home each, nearest the spawn first
			local slots: { Holding.Slot } = {}
			for _, s in LobbySpecs.Slots do
				table.insert(slots, { Number = s.Number, Door = s.Door })
			end
			local plots = Brix.Plots.new({
				plots = Holding.order(slots, LobbySpecs.Spawn),
				pick = Brix.PlotPick.inOrder(),
			})
			local pp = Brix.Roblox.PlayerPlots.new({ plots = plots, players = Players })
			pp.claimed:connect(function(change: Brix.PlayerPlotChange)
				local plot, player = change.plot, change.player
				local turn = (turns[plot] or 0) + 1
				turns[plot] = turn
				-- a beat after they first stand here, so their screen is up to see and hear it
				local function stood()
					task.delay(Holding.Arrive.After, arrive, l, plot, player, turn)
				end
				if player.Character then
					stood()
				else
					player.CharacterAdded:Once(stood)
				end
			end)
			pp.released:connect(function(change: Brix.PlayerPlotChange)
				leave(l, change.plot)
			end)
			playerPlots = pp
			pp:start()
			print(
				`FrontOffice: the lobby is laid, {#l.cars} cars in their bays, {#switches} homes lit`
			)
		end,
		stop = function(_: any)
			if playerPlots then
				playerPlots:stop()
				playerPlots = nil
			end
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
