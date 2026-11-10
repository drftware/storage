--!strict
-- lune run tests/minimap.spec
-- The minimap's drawing (L-10): every hall piece, the lobby and the elevator as pieces that fill in
-- as you walk them, each unit beside the hall it opens onto; which piece a point is on, so standing
-- anywhere on the floor (a hall, a unit, the lobby, the car) fills in the right one; the layout sent
-- to screens as text and back; the opened units' list; a marker held on the window's edge.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Minimap = require("../src/shared/Minimap")
local Wrap = require("../src/shared/Tools/Wrap")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local EPS = 1e-3

local function inside(r: Minimap.Rect, x: number, z: number): boolean
	return x > r.x0 + EPS and x < r.x1 - EPS and z > r.z0 + EPS and z < r.z1 - EPS
end

local function overlaps(a: Minimap.Rect, b: Minimap.Rect): boolean
	return a.x0 < b.x1 - EPS and b.x0 < a.x1 - EPS and a.z0 < b.z1 - EPS and b.z0 < a.z1 - EPS
end

local function same(a: Minimap.Rect, b: Minimap.Rect): boolean
	return math.abs(a.x0 - b.x0) < EPS
		and math.abs(a.x1 - b.x1) < EPS
		and math.abs(a.z0 - b.z0) < EPS
		and math.abs(a.z1 - b.z1) < EPS
end

local SEEDS = { 1, 7, 42, 1234, 90210 }

for _, seed in SEEDS do
	for number = 1, 10 do
		local tag = `seed {seed} floor {number}`
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local map = Minimap.from(floor)

		-- the pieces: one per hall piece, the lobby's its own, and the elevator's behind it
		ok(#map.pieces == #floor.cells + 1, `{tag}: a piece for each hall piece and the elevator`)
		local lobby = map.pieces[map.lobby]
		local car = map.pieces[map.elevator]
		ok(lobby ~= nil and lobby.kind == "Lobby", `{tag}: the lobby is a Lobby piece`)
		ok(car ~= nil and car.kind == "Elevator", `{tag}: the elevator is an Elevator piece`)
		local hallPieces = 0
		for i, p in map.pieces do
			ok(#p.rects > 0, `{tag}: piece {i} has something to draw`)
			if p.kind == "Hall" then
				hallPieces += 1
			end
			for _, r in p.rects do
				ok(r.x0 < r.x1 and r.z0 < r.z1, `{tag}: piece {i}'s rects have size`)
			end
		end
		ok(hallPieces == #floor.cells - 1, `{tag}: every cell but the lobby is a hall piece`)
		local lc = floor.cells[floor.lobby]
		for _, r in car.rects do
			ok(
				r.z0 >= lc.z + Floor.LobbySize / 2 - EPS,
				`{tag}: the elevator stands behind the lobby`
			)
		end

		-- the pieces never overlap, so a point is on one piece at most
		for i = 1, #map.pieces do
			for j = i + 1, #map.pieces do
				for _, a in map.pieces[i].rects do
					for _, b in map.pieces[j].rects do
						ok(not overlaps(a, b), `{tag}: pieces {i} and {j} overlap`)
					end
				end
			end
		end

		-- each unit once, beside the hall it opens onto, its whole footprint
		local units = 0
		local seen: { [number]: boolean } = {}
		for i, s in floor.slots do
			if s.kind == "Unit" then
				units += 1
			end
		end
		ok(#map.units == units, `{tag}: every unit is on the map ({#map.units} of {units})`)
		for _, u in map.units do
			local s = floor.slots[u.slot]
			ok(s ~= nil and s.kind == "Unit", `{tag}: map unit {u.slot} is a unit`)
			ok(not seen[u.slot], `{tag}: unit {u.slot} once`)
			seen[u.slot] = true
			if s then
				local x0, x1, z0, z1 = Floor.footprint(s)
				ok(
					same(u.rect, { x0 = x0, x1 = x1, z0 = z0, z1 = z1 }),
					`{tag}: unit {u.slot}'s footprint`
				)
				local cellPiece = Minimap.at(map, floor.cells[s.cell].x, floor.cells[s.cell].z)
				ok(u.piece == cellPiece, `{tag}: unit {u.slot} is drawn with its hall`)
				-- standing in it fills in its hall
				local mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
				ok(
					Minimap.at(map, mx, mz) == u.piece,
					`{tag}: standing in unit {u.slot} is on its hall`
				)
			end
		end

		-- which piece: each cell's middle is its own piece; the lobby's and the car's middles
		for i, c in floor.cells do
			local at = Minimap.at(map, c.x, c.z)
			ok(at ~= nil, `{tag}: cell {i}'s middle is on a piece`)
			if at then
				ok(
					(i == floor.lobby) == (at == map.lobby),
					`{tag}: cell {i}'s middle is the lobby only if it is the lobby`
				)
			end
		end
		local carZ = lc.z + Floor.LobbySize / 2 + 6
		ok(
			Minimap.at(map, lc.x, carZ) == map.elevator,
			`{tag}: standing in the car is the elevator`
		)
		ok(
			Minimap.at(map, lc.x, lc.z + Floor.LobbySize / 2 - 0.5) == map.lobby,
			`{tag}: the lobby's back`
		)

		-- anywhere a sheet can lie (every hall, wall to wall, end to end) is on a hall piece
		for _, h in Wrap.halls(floor) do
			local hx = if h.along == 0 then h.half else Floor.HallWidth / 2
			local hz = if h.along == 1 then h.half else Floor.HallWidth / 2
			if h.along == -1 then
				hx, hz = h.half, h.half
			end
			for fx = -0.95, 0.95, 0.475 do
				for fz = -0.95, 0.95, 0.475 do
					local at = Minimap.at(map, h.x + fx * hx, h.z + fz * hz)
					ok(
						at ~= nil and map.pieces[at].kind == "Hall",
						`{tag}: hall point ({h.x + fx * hx}, {h.z + fz * hz}) is on a hall piece`
					)
				end
			end
		end

		-- off the floor is on nothing, and near it only within the margin
		ok(Minimap.near(map, lc.x, lc.z, 0), `{tag}: the lobby is on the floor`)
		ok(
			not Minimap.near(map, map.bounds.x1 + 9, lc.z, 8),
			`{tag}: 9 studs off the side is off it`
		)
		ok(Minimap.near(map, map.bounds.x1 + 7, lc.z, 8), `{tag}: 7 studs off the side is near it`)
		ok(Minimap.at(map, map.bounds.x1 + 50, map.bounds.z0 - 50) == nil, `{tag}: off the floor`)
		for _, p in map.pieces do
			for _, r in p.rects do
				ok(
					r.x0 >= map.bounds.x0 - EPS
						and r.x1 <= map.bounds.x1 + EPS
						and r.z0 >= map.bounds.z0 - EPS
						and r.z1 <= map.bounds.z1 + EPS,
					`{tag}: the bounds hold every piece`
				)
			end
		end

		-- sent as text and back, the same map; small enough for an attribute
		local text = Minimap.encode(map)
		ok(#text < 20000, `{tag}: the layout's text is {#text} long`)
		ok(not string.find(text, "[^%d%.%-%s;,|HLE]"), `{tag}: the layout is shapes only`)
		local back = Minimap.decode(text)
		ok(back ~= nil, `{tag}: the layout decodes`)
		if back then
			ok(
				#back.pieces == #map.pieces and #back.units == #map.units,
				`{tag}: as many pieces and units`
			)
			ok(
				back.lobby == map.lobby and back.elevator == map.elevator,
				`{tag}: the lobby and car kept`
			)
			ok(same(back.bounds, map.bounds), `{tag}: the bounds kept`)
			for i, p in map.pieces do
				local q = back.pieces[i]
				ok(q ~= nil and q.kind == p.kind and #q.rects == #p.rects, `{tag}: piece {i} kept`)
				if q then
					for k, r in p.rects do
						ok(
							q.rects[k] ~= nil and same(q.rects[k], r),
							`{tag}: piece {i} rect {k} kept`
						)
					end
				end
			end
			for i, u in map.units do
				local v = back.units[i]
				ok(
					v ~= nil and v.slot == u.slot and v.piece == u.piece and same(v.rect, u.rect),
					`{tag}: unit {i} kept`
				)
			end
		end
	end
end

-- a bad layout decodes to nothing rather than a broken map
ok(Minimap.decode("") == nil, "an empty layout is no map")
ok(Minimap.decode("nonsense") == nil, "nonsense is no map")
ok(Minimap.decode("H 0 1 0 1|") == nil, "a layout with no lobby or elevator is no map")
ok(
	Minimap.decode("L 0 1 0 1;E 0 1 1 2|1 9 0 1 0 1") == nil,
	"a unit beside a piece that isn't there"
)
ok(Minimap.decode("L 0 1 0 1;E 0 1 1 2|1 1 0 1 0 1") ~= nil, "a lobby, a car and one unit is a map")
ok(Minimap.decode("L 0 1 0 1;E 0 1 1 2|1 1 0 1 0 1|2") == nil, "a third part is no map")

-- the units opened so far, as the server lists them
do
	local text = Minimap.encodeOpened({ 3, 17, 22 })
	local back = Minimap.decodeOpened(text)
	ok(back[3] and back[17] and back[22] and not back[4], "opened units come back")
	ok(next(Minimap.decodeOpened("")) == nil, "none opened")
	local bad = Minimap.decodeOpened("4,x,-2,1.5,,7")
	ok(bad[4] and bad[7] and not bad[-2], "a bad entry is skipped, the rest kept")
	local n = 0
	for _ in bad do
		n += 1
	end
	ok(n == 2, "only whole slot numbers count")
end

-- a marker held on the window's edge, pointing the right way
do
	local x, y, held = Minimap.edge(10, -20, 50)
	ok(x == 10 and y == -20 and not held, "inside the window, a marker stays where it is")
	x, y, held = Minimap.edge(0, 200, 50)
	ok(
		held and math.abs(x) < EPS and math.abs(y - 50) < EPS,
		"straight below, it sits on the bottom edge"
	)
	x, y, held = Minimap.edge(-300, 150, 50)
	ok(
		held and math.abs(x + 50) < EPS and math.abs(y - 25) < EPS,
		"off to the left and down, on the left edge"
	)
	ok(math.abs(x / y - (-300 / 150)) < EPS, "the same way as the thing it points at")
	x, y, held = Minimap.edge(50, 50, 50)
	ok(not held and x == 50 and y == 50, "on the corner counts as inside")
end

print(`minimap: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
