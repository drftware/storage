--!strict
--[[
	Drives: the RC car driven, on the server (F-G1b3c2c, D-252), a system.

	Drive (`Slots.used` for the RC car, a living player with it in hand) sets the car down: its
	parts (the drive's body and all that rides on it, `Drive.carParts`) leave the find's model,
	which stays in the player's hand as the transmitter, and become their own model on the floor
	in front of them, facing where they face, short of a wall. The car slides on an invisible box
	(`Drive.HullName`) with no friction, its meshes riding it without colliding, so the handling
	alone moves and stops it. Then Brix's Driving hands it to the player's device and checks every
	move (no faster than the handling's top with `Drive.CheckSlack`, no wall passed through); a bad
	move is put back and stamped `PutBack` for the driver's jolt. While they drive, the car says
	who (`Driver`) and their streaming follows the car (`Player.ReplicationFocus`), so the halls it
	drives down stream in on their screen.

	While the car is out, the transmitter is held by its own handle (`regrip`): the find is held
	by the car's roof, which isn't in the hand any more. While they drive, the driver's character
	carries `Drive.BodyTag`, so every screen crouches it over the transmitter (DriverBodies).

	The drive ends when the driver says Back (`DriveBack`), lets go of the transmitter (switched,
	pocketed, dropped), is caught (`Kept.Attribute`), dies, leaves, or the car falls out of the
	world. The car stays where it stopped, anchored so nobody kicks it about. Drive again with the
	transmitter in hand and it drives on from there. Walk to it with the transmitter in your hand,
	or drive it back to your feet once it has been away (`Drive.home`), and it's back in your hand:
	its parts go back into the find, joined to the transmitter as they were. A find that goes
	(destroyed, not just pocketed) takes its car with it.

	The car belongs to the floor it's set down on (F-G1b3c3): it's put in that floor's model, so a
	car still out when the elevator leaves stays with the floor, and as the floor goes its
	transmitter dies wherever it is (`Slots.lose`, `Drive.Lost`). To monsters the find is where its
	car is (`Slots.out`, told again as it moves): the Packrat goes for the car, and as its hands
	close the driver's screen is told (`Drive.TakenRemote`: the view lifts, shakes and cuts to
	static), the transmitter is brought to the car and the whole find goes into its arms, to its
	pile, where it's taken back as any find.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Drive = require(ReplicatedStorage.Shared.Finds.Drive)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)

-- Seconds between looks for a transmitter's holder close enough to take its car back.
local TAKE_EVERY = 0.1

-- How each car part was in the find, to put it back as it was.
type Kept = {
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
	massless: boolean,
	anchored: boolean,
}

type Car = {
	find: Model, -- the find's model: the transmitter, in a hand or lying somewhere
	model: Model, -- the car out on the floor
	hull: Part,
	parts: { BasePart },
	kept: { [BasePart]: Kept },
	joint: Motor6D, -- the body's joint: from the transmitter in the find, from the hull out here
	jointFrom: BasePart, -- the transmitter's part it hangs from in the find
	jointC0: CFrame,
	pivot: CFrame, -- the find's own grip (its body's PivotOffset), to put back
	drive: Brix.DrivingServer?,
	driver: Player?,
	character: Model?, -- the driver's, tagged `Drive.BodyTag` while they drive
	away: boolean, -- the car has been `Drive.HomeAway` from its driver's feet this drive
	out: Slots.Out, -- where monsters see the find, and how they take it (`Slots.out`)
	told: Vector3, -- where the hull was when monsters were last told
	going: RBXScriptConnection, -- the find destroyed
	lost: RBXScriptConnection, -- the car gone from the world with its floor
}

local Drives = {}

-- The player whose hand `find` is in, if any.
local function holderOf(find: Model): Player?
	local character = find.Parent
	if find.Name ~= Tools.HeldName or not (character and character:IsA("Model")) then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- The find's grip moved from `from` to `to`: its body's pivot (where a hand or the floor holds
-- it) and the weld of a hand holding it there now.
local function regrip(find: Model, from: CFrame, to: CFrame)
	local body = Tools.body(find)
	if not body then
		return
	end
	body.PivotOffset = to
	for _, weld in body:GetChildren() do
		if
			weld:IsA("Weld")
			and weld.Part1 == body
			and (weld.C1.Position - from.Position).Magnitude < 1e-3
		then
			weld.C1 = to
		end
	end
end

-- The transmitter's own grip for a find held at `pivot`: its handle, under the middle of its head
-- (the part's middle across and front to back, measured in Studio), at the height the whole find
-- is held, so a transmitter dropped alone still lands on its foot.
local function handleOf(pivot: CFrame): CFrame
	return CFrame.new(0, pivot.Position.Y, 0)
end

-- Every part in `parts` moved rigidly so `body` lands on `at`, keeping how they sit round it.
-- Their joint to anything else must be let go first: setting a part's CFrame moves its whole
-- assembly, and a find in a hand is in the character's. Every place is worked out before any
-- part moves, since moving one moves the rest of its assembly with it.
-- The floor's model a car set down on `ground` belongs to (FloorBuilder's), or nil (the dev hall).
local function floorOf(ground: Instance): Instance?
	local at = ground:FindFirstAncestorWhichIsA("Model")
	while at do
		if Floor.isModel(at.Name) then
			return at
		end
		at = at:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end

local function carry(parts: { BasePart }, body: BasePart, at: CFrame)
	local move = at * body.CFrame:Inverse()
	local places = table.create(#parts)
	for i, part in parts do
		places[i] = move * part.CFrame
	end
	for i, part in parts do
		part.CFrame = places[i]
	end
end

function Drives.new(): Brix.System
	local connections: { Brix.SignalConnection } = {}
	local roblox: { RBXScriptConnection } = {}
	local cars: { [Model]: Car } = {} -- by find
	local handling = Brix.Handling.car(Drive.Handling)
	local check = Brix.MoveCheck.ground({
		top = handling:topSpeed() * Drive.CheckSlack,
		fall = Drive.CheckFall,
		bunch = Drive.CheckBunch,
	})
	local folder: Folder? = nil
	local slots: Slots.Slots? = nil
	local takenRemote: RemoteEvent? = nil
	local takeIn = 0

	local function say(text: string)
		if RunService:IsStudio() then
			print(`Drives: {text}`)
		end
	end

	-- The drive on `car` over: the car stopped and anchored where it is, its driver's streaming
	-- back on them.
	local function endDrive(car: Car, why: string)
		local drive = car.drive
		if not drive then
			return
		end
		car.drive = nil
		local driver = car.driver
		car.driver = nil
		drive:stop()
		car.model:SetAttribute(Drive.DriverAttribute, nil)
		local character = car.character
		car.character = nil
		if character then
			CollectionService:RemoveTag(character, Drive.BodyTag)
		end
		if driver and driver.ReplicationFocus == car.hull then
			driver.ReplicationFocus = nil
		end
		local hull = car.hull
		if hull.Parent then
			hull.AssemblyLinearVelocity = Vector3.zero
			hull.AssemblyAngularVelocity = Vector3.zero
			hull.Anchored = true
		end
		say(`{if driver then driver.Name else "?"} stopped driving ({why})`)
	end

	-- `car` no longer out: forgotten here and by monsters.
	local function forget(car: Car)
		cars[car.find] = nil
		car.going:Disconnect()
		car.lost:Disconnect()
		local s = slots
		if s then
			s:out(car.find, nil)
		end
	end

	--[[
		`car` back in its find, joined to the transmitter as it was; the car out on the floor gone.
		`there`: the transmitter is brought to the car, not the car to it (a monster's hands closed on
		the car, the find already out of any hand and anchored).
	]]
	local function takeBack(car: Car, why: string, there: boolean?)
		endDrive(car, why)
		forget(car)
		local find = car.find
		local body = car.joint.Part1
		local back: { BasePart } = {}
		for _, part in car.parts do
			if part.Parent ~= nil then
				table.insert(back, part)
			end
		end
		car.joint.Part0 = nil
		if body and body.Parent ~= nil and there then
			local move = body.CFrame * (car.jointFrom.CFrame * car.jointC0):Inverse()
			find:PivotTo(move * find:GetPivot())
		elseif body and body.Parent ~= nil and car.jointFrom.Parent ~= nil then
			-- (a pocketed find is out of the world, its parts still placed: carried to it all the same)
			carry(back, body, car.jointFrom.CFrame * car.jointC0)
		end
		for _, part in back do
			local k = car.kept[part]
			part.Anchored = k.anchored
			part.CanCollide = k.canCollide
			part.CanTouch = k.canTouch
			part.CanQuery = k.canQuery
			part.Massless = k.massless
			part.Parent = find
		end
		car.joint.Part0 = car.jointFrom
		car.joint.C0 = car.jointC0
		regrip(find, handleOf(car.pivot), car.pivot)
		car.model:Destroy()
		find:SetAttribute(Drive.OutAttribute, nil)
		say(`the car is back with its transmitter ({why})`)
	end

	-- A monster's hands closed on `car` (F-G1b3c3, `Slots.lift`; the find already out of any hand):
	-- its driver's screen told first (the view lifts, shakes and cuts to static: DriveView), then
	-- the transmitter brought to the car, the whole find together there for its arms.
	local function stolen(car: Car)
		local driver = car.driver
		local r = takenRemote
		if driver and r then
			r:FireClient(driver)
		end
		takeBack(car, "a monster took it", true)
	end

	--[[
		Sets `find`'s car down in front of `player`: on the floor, facing where they face, short of
		a wall. Nil, and it stays together, if there's no floor there or the find isn't whole.
	]]
	local function setDown(player: Player, find: Model): Car?
		local root = rootOf(player)
		local art = Finds.art(Drive.Key)
		if not (root and art and art.Drive and folder) then
			return nil
		end
		local names = Drive.carParts(art)
		local body = find:FindFirstChild(art.Drive.Body)
		if not (body and body:IsA("BasePart")) then
			return nil
		end
		local joint: Motor6D? = nil
		for _, j in body:GetChildren() do
			if j:IsA("Motor6D") and j.Part1 == body and j.Part0 then
				joint = j
			end
		end
		local parts: { BasePart } = {}
		for _, name in names do
			local part = find:FindFirstChild(name)
			if not (part and part:IsA("BasePart")) then
				return nil
			end
			table.insert(parts, part)
		end
		local inFind = Finds.rootAt(find, Drive.Key, Finds.rest(Drive.Key))
		local held = Tools.body(find)
		if not (joint and joint.Part0 and inFind and held) then
			return nil
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = { find }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		params.RespectCanCollide = true
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 1e-3 then
			return nil
		end
		flat = flat.Unit
		local reach = Drive.SetAhead + Drive.HullLength / 2
		local wall = Workspace:Raycast(root.Position, flat * reach, params)
		local over = if wall
			then wall.Position - flat * (Drive.HullLength / 2 + 0.1)
			else root.Position + flat * Drive.SetAhead
		local floor = Workspace:Raycast(over, Vector3.new(0, -8, 0), params)
		if not floor then
			return nil
		end
		local home = floorOf(floor.Instance) or folder
		-- the car's frame: on the floor, its front (-Z) the way you face
		local at = CFrame.lookAt(floor.Position, floor.Position + flat)
		local hullAt = CFrame.new(0, Drive.HullHeight / 2, 0)
		-- where the body sits in the car's frame: the transmitter's place in the find's frame
		-- (whose origin is the car's floor point, the art's pivot) times the joint
		local bodyAt = inFind * joint.C0

		local model = Instance.new("Model")
		model.Name = Drive.CarName
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		local hull = Instance.new("Part")
		hull.Name = Drive.HullName
		hull.Size = Vector3.new(Drive.HullWidth, Drive.HullHeight, Drive.HullLength)
		hull.Transparency = 1
		hull.CastShadow = false
		hull.CanTouch = false
		hull.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 1)
		hull.RootPriority = 1
		hull.Anchored = true
		hull.CFrame = at * hullAt
		hull.Parent = model
		model.PrimaryPart = hull

		local from = joint.Part0 :: BasePart
		local c0 = joint.C0
		joint.Part0 = nil
		local kept: { [BasePart]: Kept } = {}
		carry(parts, body, at * bodyAt)
		for _, part in parts do
			kept[part] = {
				canCollide = part.CanCollide,
				canTouch = part.CanTouch,
				canQuery = part.CanQuery,
				massless = part.Massless,
				anchored = part.Anchored,
			}
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			part.Parent = model
		end
		joint.Part0 = hull
		joint.C0 = hullAt:Inverse() * bodyAt
		local pivot = held.PivotOffset
		regrip(find, pivot, handleOf(pivot))

		local car: Car
		car = {
			find = find,
			model = model,
			hull = hull,
			parts = parts,
			kept = kept,
			joint = joint,
			jointFrom = from,
			jointC0 = c0,
			pivot = pivot,
			drive = nil,
			driver = nil,
			character = nil,
			away = false,
			out = {
				-- to monsters the find lies where its car is: the floor under the hull
				at = function(): Vector3?
					if not hull:IsDescendantOf(Workspace) then
						return nil
					end
					return hull.Position - hull.CFrame.UpVector * (Drive.HullHeight / 2)
				end,
				gather = function(there: boolean)
					if there then
						stolen(car)
					else
						takeBack(car, "torn from its holder's hands")
					end
				end,
			},
			told = hull.Position,
			-- a find that goes (kept, cleared with a floor) takes its car with it; pocketed or
			-- switched away from it's only out of the world a while, and the car stays
			going = find.Destroying:Connect(function()
				if cars[find] == car then
					endDrive(car, "the find went")
					forget(car)
					model:Destroy()
				end
			end),
			-- its floor went, the car with it (Destroying fires for a destroyed ancestor too):
			-- the find dies wherever it is, never kept
			lost = model.Destroying:Connect(function()
				if cars[find] == car then
					endDrive(car, "left with its floor")
					forget(car)
					local s = slots
					if s then
						s:lose(find, Drive.Lost)
					end
					say("a car was left with its floor; its transmitter died")
				end
			end),
		}
		CollectionService:AddTag(model, Drive.Tag)
		model.Parent = home
		find:SetAttribute(Drive.OutAttribute, true)
		cars[find] = car
		local s = slots
		if s then
			s:out(find, car.out)
		end
		say(`{player.Name} set the car down`)
		return car
	end

	local function startDrive(car: Car, player: Player)
		if car.drive then
			return
		end
		for _, other in cars do
			if other.driver == player then
				return
			end
		end
		car.hull.Anchored = false
		local drive = Brix.Roblox.Driving.server({
			body = car.model,
			driver = player,
			check = check,
			players = Players,
			frames = RunService.Heartbeat,
		})
		car.drive, car.driver = drive, player
		drive.ended:connect(function(reason: string)
			if reason ~= "stopped" then
				endDrive(car, reason)
			end
		end)
		drive.putBack:connect(function()
			car.model:SetAttribute(Drive.PutBackAttribute, Workspace:GetServerTimeNow())
			say(`{player.Name}'s car was put back`)
		end)
		local started, why = pcall(function()
			drive:start()
		end)
		if not started then
			warn(`Drives: the car couldn't be handed to {player.Name}: {why}`)
			car.drive, car.driver = nil, nil
			car.hull.Anchored = true
			return
		end
		car.model:SetAttribute(Drive.DriverAttribute, player.UserId)
		car.away = false
		local character = player.Character
		if character then
			car.character = character
			CollectionService:AddTag(character, Drive.BodyTag)
		end
		player.ReplicationFocus = car.hull
		say(`{player.Name} is driving`)
	end

	local function onUsed(use: Slots.Use)
		if use.key ~= Drive.Key then
			return
		end
		local out = cars[use.model]
		if out and out.drive then
			return
		end
		local car = out or setDown(use.player, use.model)
		if car then
			startDrive(car, use.player)
		end
	end

	-- DriveBack: nothing to check for type (it takes nothing) or range; it only ever ends the
	-- sender's own drive.
	local function onBack(player: Player)
		for _, car in cars do
			if car.driver == player then
				endDrive(car, "back")
			end
		end
	end

	local function onFrame(dt: number)
		-- a drive ends the moment its driver is caught, lets go of the transmitter or dies
		for _, car in cars do
			local driver = car.driver
			if car.drive and driver then
				if driver:GetAttribute(Kept.Attribute) == true then
					endDrive(car, "caught")
				elseif not (holderOf(car.find) == driver and rootOf(driver)) then
					endDrive(car, "let go")
				end
			end
		end
		takeIn -= dt
		if takeIn > 0 then
			return
		end
		takeIn = TAKE_EVERY
		-- a car that's moved: monsters told where it is now (the Packrat follows it)
		local s = slots
		for _, car in cars do
			local at = car.hull.Position
			if s and car.hull.Parent and (at - car.told).Magnitude >= Drive.ToldMoved then
				car.told = at
				s:out(car.find, car.out)
			end
		end
		-- a car walked to with its transmitter in hand, or driven back to its driver's feet
		local back: { Car } = {}
		local why: { string } = {}
		for _, car in cars do
			local driving = car.drive ~= nil
			local holder = if driving then car.driver else holderOf(car.find)
			local root = holder and rootOf(holder)
			if root and car.hull.Parent then
				local d = car.hull.Position - root.Position
				local home = false
				if driving then
					car.away, home = Drive.home(car.away, d.X, d.Y, d.Z)
				else
					home = Drive.takes(d.X, d.Y, d.Z)
				end
				if home then
					table.insert(back, car)
					table.insert(why, if driving then "driven home" else "walked to it")
				end
			end
		end
		for i, car in back do
			takeBack(car, why[i])
		end
	end

	local system = { name = "Drives" }

	function system.start(_: any, context: Brix.Context)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry's
		local s = slots
		if s then
			table.insert(connections, s.used:connect(onUsed))
		else
			warn("Drives: no Slots system, so nobody can drive the RC car")
		end
		-- where a car set down off any laid floor lives (the dev hall); on a floor, its model
		local f = Instance.new("Folder")
		f.Name = "Driven"
		f.Parent = Workspace
		folder = f
		local remotes = ReplicatedStorage:FindFirstChild(Drive.RemoteFolder)
		if not remotes then
			remotes = Instance.new("Folder")
			remotes.Name = Drive.RemoteFolder
			remotes.Parent = ReplicatedStorage
		end
		local back = Instance.new("RemoteEvent")
		back.Name = Drive.BackRemote
		back.Parent = remotes
		local taken = Instance.new("RemoteEvent")
		taken.Name = Drive.TakenRemote
		taken.Parent = remotes
		takenRemote = taken
		table.insert(roblox, back.OnServerEvent:Connect(onBack))
		table.insert(roblox, RunService.Heartbeat:Connect(onFrame))
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in roblox do
			c:Disconnect()
		end
		table.clear(roblox)
		local all: { Car } = {}
		for _, car in cars do
			table.insert(all, car)
		end
		for _, car in all do
			takeBack(car, "the game stopped")
		end
		if folder then
			folder:Destroy()
			folder = nil
		end
	end

	return system :: any -- any: a plain Brix system built field by field
end

return Drives
