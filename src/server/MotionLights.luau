--!strict
--[[
	MotionLights: the server owns every hall fixture's motion light (GDD "Lights"; the rules are
	MotionLight's). Whoever hangs a fixture tags its model `MotionLight.Tag`, and from then on
	anything that moves under it wakes it: the floor generator (L-01) will, the test hall
	(DevCorridor) does now.

	Ten times a second it hands the watch where every body that trips lights is (each player's
	root part, tagged here; keepers tag their own, all but the Mannequin) and writes the state of
	each fixture that changed to its model's `MotionLight.StateAttribute`. Only changes cross the
	wire; each player's screen draws them (HallLights). A fixture's watch area is a Brix box zone
	under it, turned with it down its hall.

	`cut(zone, isCut)` is the breaker room's: every fixture whose `MotionLight.PowerAttribute` is
	`zone` goes blind, or comes back dark. `flash(floor)` is the breaker's power coming back:
	every powered fixture on that floor comes on at once and holds like any other. `out(floor,
	seconds)` is the elevator's alarm (a wrong code, S2-04c): every fixture on that floor goes
	blind for `seconds`, the keypad's dead span, and comes back dark (shown "Out", so screens play
	the alarm's cut, `MotionLight.look`); the car's own lamp isn't a fixture, so it stays. In the
	dark nothing freezes a Mannequin, so the monsters the alarm calls come on through the black,
	as Lethal Company's facility goes dark when the apparatus is pulled and wakes what's inside.
	A fixture comes back powered only when neither its zone is cut nor its floor out. `woke` fires with each fixture's model as it wakes: the
	building sees that spot, and later sends a keeper to look (L-04, L-06). `lightOn(at)` says
	whether a lit fixture's pool is on a spot (`MotionLight.inPool`): the Mannequin standing there
	is frozen in its light (L-06b3b).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local Pace = require(ReplicatedStorage.Shared.Pace)

export type MotionLights = Brix.System & {
	-- Cuts (true) or restores (false) the power to every fixture in power zone `zone`.
	cut: (self: any, zone: string, isCut: boolean) -> (),
	-- Lights every powered fixture under `within` (a floor) at once, as the breaker's power
	-- coming back does.
	flash: (self: any, within: Instance) -> (),
	-- Puts every fixture under `within` (a floor) out for `seconds`, as the alarm does.
	out: (self: any, within: Instance, seconds: number) -> (),
	-- Fires with each fixture's model as it wakes.
	woke: Brix.Signal<Model>,
	-- Whether a lit fixture's pool is on `at` (feet on a floor, the world's).
	lightOn: (self: any, at: Vector3) -> boolean,
}

local FREE = Brix.Pathing.free()

-- A fixture's watch area: a box from the floor up, centred under it, its length down the hall.
local function areaOf(frame: CFrame): MotionLight.Area
	local at, along = frame.Position, frame.XVector
	return Brix.Zone.box(
		MotionLight.watchBox(FREE, at.X, at.Y, at.Z, MotionLight.turnOf(along.X, along.Z))
	)
end

local MotionLights = {}

function MotionLights.new(): MotionLights
	local watch = MotionLight.watch()
	local ids: { [Model]: number } = {}
	local models: { [number]: Model } = {}
	local spots: { [number]: Vector3 } = {} -- each fixture's frame on the floor
	local lit: { [number]: true } = {} -- the fixtures lit now
	local bodies: { BasePart } = {}
	local positions: { [BasePart]: vector } = {} -- refilled every tick, never reallocated
	local cutZones: { [string]: true } = {}
	local outUntil: { [Instance]: number } = {} -- floors out for the alarm, till this `now`
	local connections: { RBXScriptConnection } = {}
	local woke = Brix.Signal.new() :: Brix.Signal<Model>
	local now, carry = 0, 0

	local function powerOf(model: Model): string?
		local zone = model:GetAttribute(MotionLight.PowerAttribute)
		return if type(zone) == "string" then zone else nil
	end

	local function zoneCut(model: Model): boolean
		local zone = powerOf(model)
		return zone ~= nil and cutZones[zone] == true
	end

	-- Whether the alarm has the floor `model` hangs on out.
	local function isOut(model: Model): boolean
		for floor in outUntil do
			if model:IsDescendantOf(floor) then
				return true
			end
		end
		return false
	end

	-- What a fixture shows players now (`MotionLight.look`).
	local function lookOf(id: number): MotionLight.Look
		local model = models[id]
		return MotionLight.look(watch:state(id), zoneCut(model), isOut(model))
	end

	-- Writes a fixture's state for clients to draw. `quiet` (the breaker's flash) wakes it
	-- without `woke`: the building didn't see anything there, so it sends nothing to look.
	local function show(id: number, quiet: boolean?)
		local model = models[id]
		local state = watch:state(id)
		if state == "Lit" then
			lit[id] = true
		else
			lit[id] = nil
		end
		model:SetAttribute(MotionLight.StateAttribute, lookOf(id))
		if state == "Lit" and not quiet then
			woke:fire(model)
		end
	end

	-- Gives a fixture power or takes it, and writes what it shows if that changed.
	local function repower(model: Model, id: number)
		local changed = watch:setPowered(id, MotionLight.powered(zoneCut(model), isOut(model)))
		if changed or model:GetAttribute(MotionLight.StateAttribute) ~= lookOf(id) then
			show(id)
		end
	end

	local function addFixture(inst: Instance)
		-- a tagged template in ReplicatedStorage is no light (docs/STUDIO.md)
		if not inst:IsA("Model") or ids[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local frame = inst:GetPivot()
		local id = watch:add(
			areaOf(frame),
			frame.Position.X,
			frame.Position.Z,
			MotionLight.Reach,
			MotionLight.powered(zoneCut(inst), isOut(inst))
		)
		ids[inst] = id
		models[id] = inst
		spots[id] = frame.Position
		show(id)
	end

	local function removeFixture(inst: Instance)
		local id = ids[inst :: any] -- any: the removed signal hands back an Instance
		if id then
			watch:remove(id)
			ids[inst :: any] = nil
			models[id] = nil
			spots[id] = nil
			lit[id] = nil
		end
	end

	local function addBody(inst: Instance)
		if inst:IsA("BasePart") and not table.find(bodies, inst) then
			table.insert(bodies, inst)
		end
	end

	local function removeBody(inst: Instance)
		local i = table.find(bodies, inst :: any) -- any: the removed signal hands back an Instance
		if i then
			bodies[i] = bodies[#bodies]
			bodies[#bodies] = nil
		end
	end

	-- Every player's character trips lights by its root part.
	local function addCharacter(character: Model)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root:AddTag(MotionLight.BodyTag)
		end
	end

	local function addPlayer(player: Player)
		table.insert(connections, player.CharacterAdded:Connect(addCharacter))
		if player.Character then
			addCharacter(player.Character)
		end
	end

	local function listen(tag: string, added: (Instance) -> (), removed: (Instance) -> ())
		table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(added))
		table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(removed))
		for _, inst in CollectionService:GetTagged(tag) do
			added(inst)
		end
	end

	local system = {
		name = "MotionLights",
		woke = woke,
	}

	function system.start(_: any, _context: Brix.Context)
		listen(MotionLight.Tag, addFixture, removeFixture)
		listen(MotionLight.BodyTag, addBody, removeBody)
		table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
		for _, player in Players:GetPlayers() do
			addPlayer(player)
		end
	end

	function system.step(_: any, dt: number)
		now += dt
		local look: boolean
		look, carry = Pace.step(carry, dt, 1 / MotionLight.TickSeconds)
		if not look then
			return
		end
		-- a floor's alarm is over: its lights come back dark, those under someone lit next tick
		for floor, ends in outUntil do
			if now >= ends or not floor.Parent then
				outUntil[floor] = nil
				for model, id in ids do
					if model:IsDescendantOf(floor) then
						repower(model, id)
					end
				end
			end
		end
		table.clear(positions)
		for _, body in bodies do
			if body.Parent then
				-- any: a Vector3 is the native vector Brix measures, which the checker won't cast
				positions[body] = (body.Position :: any) :: vector
			end
		end
		for _, id in watch:step(now, positions) do
			show(id)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		woke:disconnectAll()
	end

	function system.lightOn(_: any, at: Vector3): boolean
		for id in lit do
			local spot = spots[id]
			if MotionLight.inPool(spot.X, spot.Y, spot.Z, at.X, at.Y, at.Z) then
				return true
			end
		end
		return false
	end

	function system.flash(_: any, within: Instance)
		for model, id in ids do
			if model:IsDescendantOf(within) and watch:wake(id, now) then
				show(id, true)
			end
		end
	end

	function system.cut(_: any, zone: string, isCut: boolean)
		if isCut then
			cutZones[zone] = true
		else
			cutZones[zone] = nil
		end
		for model, id in ids do
			if powerOf(model) == zone then
				repower(model, id)
			end
		end
	end

	function system.out(_: any, within: Instance, seconds: number)
		outUntil[within] = MotionLight.outEnds(outUntil[within], now, seconds)
		for model, id in ids do
			if model:IsDescendantOf(within) then
				repower(model, id)
			end
		end
	end

	return system
end

return MotionLights
