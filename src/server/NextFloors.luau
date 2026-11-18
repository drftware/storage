--!strict
--[[
	NextFloors: the team's vote on the ride for the version of the floor above (S4-03a, the rules
	in `NextFloor`), a system. The moment: the car lurches off, three versions of the next floor
	light up on its panel, friends jab at them and change their minds, and on the cable's second
	knock the winner is the floor the car stops at. Most presses wins, as a lobby's map vote does.

	Climbs opens a vote on the riding car as it leaves a floor with riders (`open`): the versions
	dealt for the floor above go on the car (`NextFloor.OfferAttribute`) for every screen to light.
	A rider's press (`NextFloor.Remote`, a version's name) is checked: a short string (type), one
	of the versions lit on their car (range), from someone who rode as its gate shut and isn't
	wrapped (ownership), no faster than `NextFloor.Limit` (rate). One press each: pressing another
	changes it, pressing the same one again does nothing. The presses go on the car
	(`PressesAttribute`) for each screen to mark. Climbs ends the vote on the cable's second knock
	(`close`): the winner (`NextFloor.winner`: most presses, a tie or no presses at random) goes on
	the car (`PickedAttribute`) and back to Climbs, which deals the floor as picked. A rider who
	leaves the game takes their press with them.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Floor = require(ReplicatedStorage.Shared.Floor)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Prompts = require(script.Parent.Prompts)

-- The longest name a press may carry: longer than any version's, so anything past it is junk.
local NAME_MAX = 40

-- A vote under way on a riding car.
type Vote = {
	riders: { Player },
	offered: { string },
	presses: { [number]: string }, -- each rider's press, by UserId
	random: Floor.Random, -- the floor's offer Random, carried on for a tie
}

export type NextFloors = Brix.System & {
	-- Lights `offered` (version names) on `car`'s panel for `riders` to press, `random` (the
	-- Random that dealt them) kept for a tie; a vote already on it is dropped.
	open: (
		self: any,
		car: Model,
		riders: { Player },
		offered: { string },
		random: Floor.Random
	) -> (),
	-- Ends the vote on `car` and returns the version that won, shown on the car; nil with no vote.
	close: (self: any, car: Model) -> string?,
	-- Ends every vote without a winner and darkens their cars (a new climb).
	clear: (self: any) -> (),
}

local NextFloors = {}

function NextFloors.new(): NextFloors
	local limit = Brix.RateLimit.bucket(NextFloor.Limit)
	local votes: { [Model]: Vote } = {}
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil

	local function show(car: Model, vote: Vote)
		car:SetAttribute(NextFloor.PressesAttribute, NextFloor.encodePresses(vote.presses))
	end

	local function onPress(player: Player, name: unknown)
		-- type, then range, then ownership, then rate
		if typeof(name) ~= "string" or #name == 0 or #name > NAME_MAX then
			return
		end
		local car: Model? = nil
		local vote: Vote? = nil
		for c, v in votes do
			if table.find(v.riders, player) then
				car, vote = c, v
				break
			end
		end
		if not (car and vote and car.Parent) or not table.find(vote.offered, name) then
			return
		end
		if Prompts.wrapped(player) or not limit:take(player, os.clock()) then
			return
		end
		if vote.presses[player.UserId] == name then
			return
		end
		vote.presses[player.UserId] = name
		show(car, vote)
	end

	local system = {
		name = "NextFloors",
	}

	function system.open(
		_: any,
		car: Model,
		riders: { Player },
		offered: { string },
		random: Floor.Random
	)
		local vote: Vote = {
			riders = table.clone(riders),
			offered = table.clone(offered),
			presses = {},
			random = random,
		}
		votes[car] = vote
		car:SetAttribute(NextFloor.PickedAttribute, "")
		car:SetAttribute(NextFloor.PressesAttribute, "")
		car:SetAttribute(NextFloor.OfferAttribute, NextFloor.encodeOffer(offered))
	end

	function system.close(_: any, car: Model): string?
		local vote = votes[car]
		if not vote then
			return nil
		end
		votes[car] = nil
		local winner = NextFloor.winner(vote.presses, vote.offered, vote.random)
		if car.Parent then
			car:SetAttribute(NextFloor.PickedAttribute, winner or "")
		end
		return winner
	end

	function system.clear(_: any)
		for car in votes do
			if car.Parent then
				car:SetAttribute(NextFloor.OfferAttribute, "")
				car:SetAttribute(NextFloor.PressesAttribute, "")
				car:SetAttribute(NextFloor.PickedAttribute, "")
			end
		end
		table.clear(votes)
	end

	function system.start(_: any, _context: Brix.Context)
		local folder = ReplicatedStorage:FindFirstChild(NextFloor.RemoteFolder)
		if not folder then
			local made = Instance.new("Folder")
			made.Name = NextFloor.RemoteFolder
			made.Parent = ReplicatedStorage
			folder = made
		end
		local r = Instance.new("RemoteEvent")
		r.Name = NextFloor.Remote
		r.Parent = folder
		remote = r
		table.insert(connections, r.OnServerEvent:Connect(onPress))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				for car, vote in votes do
					local i = table.find(vote.riders, player)
					if i then
						table.remove(vote.riders, i)
					end
					if vote.presses[player.UserId] then
						vote.presses[player.UserId] = nil
						if car.Parent then
							show(car, vote)
						end
					end
				end
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(votes)
		if remote then
			remote:Destroy()
			remote = nil
		end
	end

	return system :: any -- any: the table is filled in above to the NextFloors shape
end

return NextFloors
