--!strict
--[[
	MotionLight: the rules of the building's motion lights (GDD "Lights"), pure, so Lune can test
	them (tests/motionlight.spec.luau).

	A hall fixture watches an area of the hall under it. Anything that moves there wakes it: it
	clicks on, and the building sees that spot. It stays lit while something keeps moving in its
	area and falls dark `HoldSeconds` after the last movement it saw, so walking on leaves it
	behind you and holding still under it puts you in the dark ("hold still and you go dark to
	it"). A fixture whose power the breaker room cut is blind: dark, and seeing nothing.

	`MotionLight.watch()` makes the server's record of every fixture (the MotionLights system owns
	one). Each tick the server hands it where every body that trips lights is; it judges who moved,
	wakes the fixtures whose area they moved in, darkens those that timed out, and returns only the
	fixtures whose state changed, which is all the server replicates (GDD tech plan: a fixed tick
	against a spatial hash of fixtures). Its hot path allocates nothing once its bodies are known.
]]
local MotionLight = {}

-- What a fixture is doing, as players see it: dark with its eye open, lit (it saw something
-- move), or blind (its zone's power is cut).
export type State = "Dark" | "Lit" | "Blind"

-- A fixture's watch area: the Zone contract's `contains` (Brix's Zone.box makes them).
export type Area = { contains: (self: any, position: vector) -> boolean }

-- How long a light stays on after the last movement it saw, in seconds. It is the held breath
-- of freezing under a light, and the trail of light you leave: at a walk about five fixtures stay
-- lit behind you, like a real storage hall's (the owner's pick, 7 to 8 s, Nov 7).
MotionLight.HoldSeconds = 7.5
-- Slower than this, in studs a second, is holding still. Low enough that any step, a slow
-- thumbstick creep or a jump trips a light; above the drift of a standing character.
MotionLight.MovingSpeed = 1
-- How often the server looks, in seconds: twenty times a second, so a light another player or
-- a keeper trips answers within a stride; the check stays cheap with every fixture on a floor.
-- Your own lights don't wait for it: your screen predicts them (HallLights).
MotionLight.TickSeconds = 0.05

-- The watch area under a fixture, in studs. Along the hall it reaches 20 studs each way, 8 past
-- the middle of the stretch to the next fixture (24 studs apart), so the light ahead clicks on
-- as you pass under the one you're at, before its pool could reach you: the light follows you
-- down the hall and you never step into the dark (the owner, Nov 7).
MotionLight.WatchLength = 40
-- Across: the 8-stud hall and a stud into each doorway. A unit's inside is out of its sight, so
-- a unit is somewhere to hide from the lights.
MotionLight.WatchWidth = 10
-- Up: from the floor to the deck, so a jump still counts.
MotionLight.WatchHeight = 13

-- The size of the spatial hash's cells, in studs: the floor's 24-stud grid.
MotionLight.Cell = 24

-- On each fixture's model, as a string attribute: its State. The server writes it only when it
-- changes; each client draws it (HallLights). A fixture with none yet is Dark.
MotionLight.StateAttribute = "Light"
-- Tagged on each fixture's model so the server watches it and clients draw it.
MotionLight.Tag = "MotionLight"
-- On a fixture's model, as a string attribute: the power zone the breaker room cuts it with.
MotionLight.PowerAttribute = "PowerZone"
-- Tagged on each part that trips lights when it moves: players' root parts, and keepers' except
-- the Mannequin's (GDD "Lights").
MotionLight.BodyTag = "TripsLights"

-- Which way a fixture's hall runs, from its frame's X direction (dx, dz) along the floor: the turn
-- Brix's Zone.box takes, which swings a box's x side towards -z for a positive turn, as a
-- Roblox CFrame's turn about Y does.
function MotionLight.turnOf(dx: number, dz: number): number
	return math.atan2(-dz, dx)
end

-- The options for Brix's Zone.box of a fixture's watch area, for a fixture whose frame stands on
-- the floor at (x, y, z), its hall turned `turn` (turnOf). `pathing` is what the box measures
-- along (Brix's free pathing).
function MotionLight.watchBox<P>(
	pathing: P,
	x: number,
	y: number,
	z: number,
	turn: number
): { pathing: P, center: vector, size: vector, turn: number }
	return {
		pathing = pathing,
		center = vector.create(x, y + MotionLight.WatchHeight / 2, z),
		size = vector.create(
			MotionLight.WatchLength,
			MotionLight.WatchHeight,
			MotionLight.WatchWidth
		),
		turn = turn,
	}
end

-- How far a watch area reaches from its fixture across the floor: its footprint's half-diagonal.
MotionLight.Reach = math.sqrt((MotionLight.WatchLength / 2) ^ 2 + (MotionLight.WatchWidth / 2) ^ 2)

-- One fixture, as the watch keeps it.
type Fixture = {
	area: Area,
	cells: { number }, -- the hash cells its area overlaps
	state: State,
	seen: number, -- when it last saw something move, in the watch's seconds
}

-- One body, as the watch last saw it.
type Body = { at: vector, time: number, tick: number }

export type Watch = {
	-- Adds a fixture whose area lies within `reach` studs of (x, z): dark, or blind when
	-- `powered` is false. Returns its id.
	add: (
		self: Watch,
		area: Area,
		x: number,
		z: number,
		reach: number,
		powered: boolean?
	) -> number,
	-- Forgets a fixture.
	remove: (self: Watch, id: number) -> (),
	-- A fixture's state now.
	state: (self: Watch, id: number) -> State,
	-- Cuts (false) or restores (true) a fixture's power. Returns whether its state changed.
	setPowered: (self: Watch, id: number, powered: boolean) -> boolean,
	-- Lights a fixture at `now` as if something moved under it (the alarm), unless it's blind.
	-- It holds for HoldSeconds like any other. Returns whether its state changed.
	wake: (self: Watch, id: number, now: number) -> boolean,
	-- Looks once, at `now` seconds: `bodies` maps each body to where it is. Returns the ids of the
	-- fixtures whose state changed, in a list the watch reuses on its next step.
	step: (self: Watch, now: number, bodies: { [unknown]: vector }) -> { number },
}

-- One cell's key: its column and row packed into one number, unique for any floor under 49,000
-- studs across.
local function key(cx: number, cz: number): number
	return cx * 4096 + cz
end

local function cellOf(v: number): number
	return math.floor(v / MotionLight.Cell)
end

local function removeFrom(list: { number }, id: number)
	local i = table.find(list, id)
	if i then
		list[i] = list[#list]
		list[#list] = nil
	end
end

function MotionLight.watch(): Watch
	local fixtures: { [number]: Fixture } = {}
	local cells: { [number]: { number } } = {}
	local lit: { number } = {} -- the fixtures that are on, the only ones that can time out
	local bodies: { [unknown]: Body } = {}
	local changed: { number } = {}
	local nextId = 0
	local ticks = 0

	local watch = {} :: Watch

	function watch.add(_: Watch, area: Area, x: number, z: number, reach: number, powered: boolean?)
		nextId += 1
		local id = nextId
		local state: State = if powered == false then "Blind" else "Dark"
		local f: Fixture = { area = area, cells = {}, state = state, seen = -math.huge }
		for cx = cellOf(x - reach), cellOf(x + reach) do
			for cz = cellOf(z - reach), cellOf(z + reach) do
				local k = key(cx, cz)
				local cell = cells[k]
				if not cell then
					cell = {}
					cells[k] = cell
				end
				table.insert(cell, id)
				table.insert(f.cells, k)
			end
		end
		fixtures[id] = f
		return id
	end

	function watch.remove(_: Watch, id: number)
		local f = fixtures[id]
		if not f then
			return
		end
		for _, k in f.cells do
			removeFrom(cells[k], id)
		end
		removeFrom(lit, id)
		fixtures[id] = nil
	end

	function watch.state(_: Watch, id: number): State
		local f = fixtures[id]
		assert(f, `MotionLight: no fixture {id}`)
		return f.state
	end

	function watch.setPowered(_: Watch, id: number, powered: boolean): boolean
		local f = fixtures[id]
		assert(f, `MotionLight: no fixture {id}`)
		local was: State = f.state
		if powered then
			if was ~= "Blind" then
				return false
			end
			f.state = "Dark"
			return true
		end
		if was == "Blind" then
			return false
		elseif was == "Lit" then
			removeFrom(lit, id)
		end
		f.state = "Blind"
		return true
	end

	function watch.wake(_: Watch, id: number, now: number): boolean
		local f = fixtures[id]
		assert(f, `MotionLight: no fixture {id}`)
		if f.state == "Blind" then
			return false
		end
		f.seen = math.max(f.seen, now)
		if f.state == "Lit" then
			return false
		end
		f.state = "Lit"
		table.insert(lit, id)
		return true
	end

	function watch.step(_: Watch, now: number, positions: { [unknown]: vector }): { number }
		table.clear(changed)
		ticks += 1
		for body, at in positions do
			local b = bodies[body]
			if not b then
				-- First sighting (a spawn, a body streaming in): nothing to compare, so no movement.
				bodies[body] = { at = at, time = now, tick = ticks }
				continue
			end
			local elapsed = now - b.time
			local moved = elapsed > 0
				and vector.magnitude(at - b.at) >= MotionLight.MovingSpeed * elapsed
			b.at, b.time, b.tick = at, now, ticks
			if not moved then
				continue
			end
			local cell = cells[key(cellOf(at.x), cellOf(at.z))]
			if not cell then
				continue
			end
			for _, id in cell do
				local f = fixtures[id]
				if f.state ~= "Blind" and f.area:contains(at) then
					f.seen = now
					if f.state == "Dark" then
						f.state = "Lit"
						table.insert(lit, id)
						table.insert(changed, id)
					end
				end
			end
		end
		-- Bodies missing this tick are gone (a keeper caught, a player left); forget them.
		for body, b in bodies do
			if b.tick ~= ticks then
				bodies[body] = nil
			end
		end
		-- Lights nothing has moved under for HoldSeconds fall dark.
		for i = #lit, 1, -1 do
			local id = lit[i]
			local f = fixtures[id]
			if now - f.seen >= MotionLight.HoldSeconds then
				f.state = "Dark"
				lit[i] = lit[#lit]
				lit[#lit] = nil
				table.insert(changed, id)
			end
		end
		return changed
	end

	return watch
end

return MotionLight
