--!strict
--[[
	LobbyCars: the front office's six cars as the way into a climb (L-08e1b1, GDD "The lobby",
	D-112), as DOORS' lobby elevators do. A system on the server.

	- Each car is the climb's own elevator (Lobby.lay), stood open in its bay by Elevators'
	  `lobby`: its keypad asleep, its readout the count (ElevatorView).
	- Step through its gate and you're in its group (Boarding); a Brix zone over the car decides
	  it, as the climb's car decides who rode (Departure.carBox). Out of it for
	  `Boarding.LeaveGrace` and you've left. The group goes on the car for every screen
	  (`Boarding.GroupAttribute`): only those aboard see and hear its clock (GateClock).
	- The first step in starts the count on the climb's gate clock (Elevators' `count`): 20 s, 5
	  once six are aboard, and floor 1 starts laying out of play (Climbs' `ready`), so it's there
	  long before the car leaves.
	- At zero the gate shuts with the climb's own ratchet and slam; whoever's inside as it hits
	  its post rides (`Boarding.riders`), and the climb carries them up to floor 1 on this server
	  (Climbs' `board`), as a floor's car hands its riders to the next. Anyone else left in the car
	  (a seventh) is set down outside its gate.
	- `Boarding.Back` seconds after it left, the car stands open in its bay again, empty.
	- One climb at a time on a server until L-08e1c gives each group a server of its own: while
	  one a car started is on, the other cars' counts are held (their groups stay) and start again
	  from the full count once it's over.

	Every step checks each player against the six cars: a few box tests, no allocation.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local Climbs = require(script.Parent.Climbs)
local Elevators = require(script.Parent.Elevators)
local FrontOffice = require(script.Parent.FrontOffice)

type Car = {
	model: Model,
	zone: Brix.Zone,
	state: Boarding.Car,
	out: { [number]: number }, -- UserId → server time they were first seen out of the car
	away: boolean, -- it left and isn't back in its bay yet
	pick: (inside: { Player }) -> { Player },
}

local FREE = Brix.Pathing.free()
local STUDIO = RunService:IsStudio()

-- Where someone left in a car that leaves without them is set down: on the striped zone in
-- front of its gate, facing the room (in the elevator's frame, +Z into the car).
local SET_DOWN = CFrame.new(0, 3, -4) * CFrame.Angles(0, math.pi, 0)

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local LobbyCars = {}

function LobbyCars.new(): Brix.System
	local cars: { Car } = {}
	local elevators: Elevators.Elevators? = nil
	local climbs: Climbs.Climbs? = nil
	local folder: Folder? = nil -- the climbs the lobby starts are laid in here
	local departing: Brix.SignalConnection? = nil
	local connections: { RBXScriptConnection } = {}
	local returns: { thread } = {}
	-- a climb a car started is on this server (until L-08e1c), and since when
	local climbing = false
	local boardedAt = 0

	-- The car's group and count, as the server holds them now, out to every screen.
	local function publish(car: Car)
		car.model:SetAttribute(Boarding.GroupAttribute, Boarding.encode(car.state.group))
		local e = elevators
		if e then
			e:count(car.model, car.state.departs)
		end
	end

	-- Floor 1 starts laying out of play the moment a count starts, so it's there by zero.
	local function ready()
		local c, f = climbs, folder
		if c and f and not climbing then
			c:ready({
				seed = Random.new():NextInteger(1, 2 ^ 31 - 1),
				number = 1,
				origin = Lobby.ClimbOrigin,
				parent = f,
			})
		end
	end

	-- Stands `car` open in its bay again, empty.
	local function back(car: Car)
		car.away = false
		car.state = Boarding.new()
		table.clear(car.out)
		car.model:SetAttribute(Boarding.GroupAttribute, nil)
		local e = elevators
		if e then
			e:lobby(car.model, car.pick)
		end
	end

	-- `player` is inside `car` (true) or not at server time `t`: joins it, or leaves it once out
	-- for the grace. True if the group changed.
	local function see(car: Car, player: Player, inside: boolean, t: number): boolean
		local id = player.UserId
		if inside then
			car.out[id] = nil
			return Boarding.join(car.state, id, t)
		end
		if not table.find(car.state.group, id) then
			return false
		end
		local since = car.out[id]
		if not since then
			car.out[id] = t
			return false
		end
		if t - since < Boarding.LeaveGrace then
			return false
		end
		car.out[id] = nil
		return Boarding.leave(car.state, id, t)
	end

	-- The car left with `leaving.aboard`: the climb takes them up; anyone else in it is set down
	-- outside; the car comes back for the next group.
	local function departed(leaving: Elevators.Leaving)
		local car: Car? = nil
		for _, c in cars do
			if c.model == leaving.elevator then
				car = c
			end
		end
		if not car then
			return
		end
		car.away = true
		car.state = Boarding.new()
		table.clear(car.out)
		car.model:SetAttribute(Boarding.GroupAttribute, nil)
		local pivot = car.model:GetPivot()
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if
				root
				and not table.find(leaving.aboard, player)
				and car.zone:contains((root.Position :: any) :: vector)
			then
				local character = player.Character :: Model
				character:PivotTo(pivot * SET_DOWN)
			end
		end
		local c = climbs
		local wait = Boarding.Back
		if #leaving.aboard == 0 then
			wait = 0 -- nobody rode: it's back at once
		elseif c and c:board(leaving.elevator, leaving) then
			climbing, boardedAt = true, now()
			-- every other car's count waits for this climb to end
			for _, other in cars do
				if other ~= car and other.state.departs then
					other.state.departs = nil
					publish(other)
				end
			end
		else
			warn("LobbyCars: no floor 1 to ride to; the car comes back")
		end
		for i = #returns, 1, -1 do
			if coroutine.status(returns[i]) == "dead" then
				table.remove(returns, i)
			end
		end
		table.insert(returns, task.delay(math.max(leaving.at + wait - now(), 0), back, car))
	end

	local system: Brix.System = {
		name = "LobbyCars",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system
			-- (init.server), and these start before this one
			local e = (registry:get("elevators") :: any) :: Elevators.Elevators
			elevators = e
			climbs = (registry:get("climbs") :: any) :: Climbs.Climbs -- any: as above
			local office = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice -- any: as above
			local laid = office:laid()
			if not laid then
				return
			end
			local f = Instance.new("Folder")
			f.Name = "LobbyClimb"
			f.Parent = Workspace
			folder = f
			for _, model in laid.cars do
				local at, x = model:GetPivot().Position, model:GetPivot().XVector
				local car: Car
				car = {
					model = model,
					zone = Brix.Zone.box(
						Departure.carBox(FREE, at.X, at.Y, at.Z, MotionLight.turnOf(x.X, x.Z))
					),
					state = Boarding.new(),
					out = {},
					away = false,
					pick = function(inside: { Player }): { Player }
						local ids = table.create(#inside)
						for i, player in inside do
							ids[i] = player.UserId
						end
						local out: { Player } = {}
						for _, id in Boarding.riders(car.state.group, ids) do
							for _, player in inside do
								if player.UserId == id then
									table.insert(out, player)
								end
							end
						end
						return out
					end,
				}
				table.insert(cars, car)
				e:lobby(model, car.pick)
			end
			departing = e.departed:connect(departed)
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local t = now()
					for _, car in cars do
						car.out[player.UserId] = nil
						if Boarding.leave(car.state, player.UserId, t) then
							publish(car)
						end
					end
				end)
			)
			if STUDIO then
				print(`LobbyCars: {#cars} cars open; step into one to start its count`)
			end
		end,
		step = function(_: any, _dt: number)
			if #cars == 0 then
				return
			end
			local t = now()
			local c = climbs
			-- the climb a car started is over (its end has cleared it): the held counts start again
			if climbing and c and not c:current() and t > boardedAt + Boarding.Back then
				climbing = false
				for _, car in cars do
					if not car.away and not car.state.departs and #car.state.group > 0 then
						Boarding.resume(car.state, t)
						publish(car)
						ready()
					end
				end
			end
			local players = Players:GetPlayers() -- one list a step, for all six cars
			for _, car in cars do
				if car.away then
					continue
				end
				local counting = car.state.departs ~= nil
				local changed = false
				for _, player in players do
					local root = rootOf(player)
					local inside = root ~= nil
						and car.zone:contains((root.Position :: any) :: vector)
					if see(car, player, inside, t) then
						changed = true
					end
				end
				if changed then
					if climbing then
						car.state.departs = nil -- held while another group climbs
					elseif not counting and car.state.departs then
						ready()
					end
					publish(car)
				end
			end
		end,
		stop = function(_: any)
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			if departing then
				departing:disconnect()
				departing = nil
			end
			for _, thread in returns do
				if coroutine.status(thread) ~= "dead" then
					task.cancel(thread)
				end
			end
			table.clear(returns)
			table.clear(cars)
			if folder then
				folder:Destroy()
				folder = nil
			end
		end,
	}
	return system
end

return LobbyCars
