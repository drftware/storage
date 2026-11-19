--!strict
--[[
	Group (S5-03j6b1): several things moved, turned or put away as one in Arrange, the room editor
	(D-436). The moment, The Sims 4's build-mode multi-select: three things lit by the box, you drag
	the crate and the lamp and the rug come along keeping their places round it; a quarter turn
	swings all three about their middle; let go and they land as one move, or, if any one can't
	stand there, none of them moves.

	Pure, and names no find: a group is ids and poses. It answers three things.
	- Where each thing of a group stands after a slide by (dx, dy), or a quarter turn about the
	  group's middle (`moved`, `turned`). Only the things on the floor move (the sensible default:
	  a thing on a wall can't slide across the floor with the rest, so it stays where it hangs and
	  OWNER.md asks whether it should). What rides on a thing (a cup on a table) isn't in the group:
	  it rides along, as it does when the table moves alone.
	- Whether a screen's group ask is well formed (`ask`, `askIds`), checked before anything reads it.
	- The change itself, all or none (`apply`): every thing lifted with its riders, each set at its
	  new place, the riders put back on top; one refusal and all of it goes back as it stood. Lifting
	  first means the things never block each other, so two can even swap places.

	Arranging (the server) calls `askIds`, `ask` and `apply` for its group asks; the screen (j6b2)
	calls `moved` and `turned` as a group is dragged and turned, and may run `apply` on its own copy of the
	room's judge to see the group green or red before it lets go. Its spec: tests/group.spec.luau.
]]
local Selection = require("./Selection")
local Spots = require("./Spots")

local Group = {}

-- A place in the room, as Brix's Placements gives it (`Brix.PlacementPose`).
export type Pose = { on: string, x: number, y: number, turn: number }
-- One thing of a group and where it stands (or where it's going).
export type Member = { id: string, pose: Pose }
-- One thing of a group ask: `what` is the id of a thing set out (it moves) or a find's name from the
-- box (it's set out: an undone group Put away), `to` where it goes.
export type Entry = { what: string, to: Pose }

-- What `apply` needs of the room's judge (Brix's Placements has it all).
export type Judge = {
	place: (self: any, id: string, shape: any, pose: Pose) -> string?, -- any: Brix's PlacementShape
	remove: (self: any, id: string) -> string?,
	poseOf: (self: any, id: string) -> Pose?,
	standingOn: (self: any, id: string) -> { string },
}

-- The group remote (in `Spots.RemoteFolder`): the screen fires ("place", list) or ("away", ids);
-- the server answers once on it with (verb, refusal or "", the ids each stands as).
Group.Remote = "ArrangeGroup"

-- The most things one group ask carries: as many as the box lights.
Group.Most = Selection.Most

-- The middle of the floor things of `members` on area `floor`: the middle of the box round their
-- places. Nil when none stands on that floor.
function Group.middle(members: { Member }, floor: string): (number?, number?)
	local left, right, near, far = math.huge, -math.huge, math.huge, -math.huge
	for _, m in members do
		local p = m.pose
		if p.on == floor then
			left, right = math.min(left, p.x), math.max(right, p.x)
			near, far = math.min(near, p.y), math.max(far, p.y)
		end
	end
	if left > right then
		return nil, nil
	end
	return (left + right) / 2, (near + far) / 2
end

-- Each of `members` on area `floor` slid by `dx`, `dy`, keeping their places round each other, as a
-- new list; the rest (on a wall) are left out: they stay where they are.
function Group.moved(members: { Member }, floor: string, dx: number, dy: number): { Member }
	local out: { Member } = {}
	for _, m in members do
		local p = m.pose
		if p.on == floor then
			table.insert(
				out,
				{ id = m.id, pose = { on = p.on, x = p.x + dx, y = p.y + dy, turn = p.turn } }
			)
		end
	end
	return out
end

-- Each of `members` on area `floor` swung a quarter turn about the group's middle, `quarters`
-- times (1 the way a single thing's Turn goes, -1 back), each thing turned with it, as a new list;
-- the rest are left out. The way round is Arranged.pose's: a turn of 90 carries a place `dx`, `dy`
-- from the middle to `-dy`, `dx`.
function Group.turned(members: { Member }, floor: string, quarters: number): { Member }
	local cx, cy = Group.middle(members, floor)
	local out: { Member } = {}
	if not (cx and cy) then
		return out
	end
	local q = quarters % 4
	for _, m in members do
		local p = m.pose
		if p.on == floor then
			local dx, dy = p.x - cx, p.y - cy
			for _ = 1, q do
				dx, dy = -dy, dx
			end
			table.insert(out, {
				id = m.id,
				pose = { on = p.on, x = cx + dx, y = cy + dy, turn = (p.turn + 90 * q) % 360 },
			})
		end
	end
	return out
end

-- A list from a screen: a table with exactly 1 to `Group.Most` entries at 1..n and nothing else.
local function list(v: unknown): { unknown }?
	if type(v) ~= "table" then
		return nil
	end
	local t = v :: { [unknown]: unknown }
	local n = 0
	for k in t do
		n += 1
		if type(k) ~= "number" or n > Group.Most then
			return nil
		end
	end
	if n < 1 then
		return nil
	end
	for i = 1, n do
		if t[i] == nil then
			return nil
		end
	end
	return t :: { unknown }
end

-- A group Place ask checked before anything reads it: a list of `{ what, on, x, y, turn }`, each
-- as a single Place's (`Spots.ask`), no thing twice. Nil if any is wrong.
function Group.ask(v: unknown): { Entry }?
	local t = list(v)
	if not t then
		return nil
	end
	local out: { Entry } = {}
	local seen: { [string]: boolean } = {}
	for _, e in t do
		if type(e) ~= "table" then
			return nil
		end
		local r = e :: { [string]: unknown }
		local what, pose = Spots.ask(r.what, r.on, r.x, r.y, r.turn)
		if not (what and pose) or (Spots.name(what) and seen[what]) then
			return nil
		end
		seen[what] = true
		table.insert(out, { what = what, to = pose })
	end
	return out
end

-- A group Put away ask checked: a list of ids set out (`Spots.askId`), none twice. Nil if wrong.
function Group.askIds(v: unknown): { string }?
	local t = list(v)
	if not t then
		return nil
	end
	local out: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, e in t do
		local id = Spots.askId(e)
		if not id or seen[id] then
			return nil
		end
		seen[id] = true
		table.insert(out, id)
	end
	return out
end

-- Whether `id` rides, at any height, on one of `set` in `judge`.
local function ridesOn(judge: Judge, id: string, set: { [string]: boolean }): boolean
	local pose = judge:poseOf(id)
	local guard = 0
	while pose and guard < 64 do
		if set[pose.on] then
			return true
		end
		pose = judge:poseOf(pose.on)
		guard += 1
	end
	return false
end

-- Moves each of `members` (things set out in `judge`) to its pose, all or none: nil, or the first
-- refusal, and then everything stands exactly as it did. Each thing's riders come with it, on its
-- top where they stood. `shapeOf` gives each thing's shape. Refused before anything changes: a
-- thing not set out ("notPlaced"), one twice or one riding on another of the group ("badAsk").
function Group.apply(
	judge: Judge,
	members: { Member },
	shapeOf: (id: string) -> any
): string? -- any: Brix's PlacementShape
	local set: { [string]: boolean } = {}
	for _, m in members do
		if set[m.id] then
			return "badAsk"
		elseif not judge:poseOf(m.id) then
			return "notPlaced"
		end
		set[m.id] = true
	end
	for _, m in members do
		if ridesOn(judge, m.id, set) then
			return "badAsk"
		end
	end
	-- Lift each with its riders, the riders first, noting where each stood.
	local gone: { string } = {}
	local was: { [string]: Pose } = {}
	local function away(id: string)
		for _, rider in judge:standingOn(id) do
			away(rider)
		end
		was[id] = judge:poseOf(id) :: Pose
		judge:remove(id)
		table.insert(gone, id)
	end
	for _, m in members do
		away(m.id)
	end
	-- Set each down, then the riders back on top (the reverse of lifting is bases first).
	local placed: { string } = {}
	local refusal: string? = nil
	for _, m in members do
		refusal = judge:place(m.id, shapeOf(m.id), m.pose)
		if refusal then
			break
		end
		table.insert(placed, m.id)
	end
	if not refusal then
		for i = #gone, 1, -1 do
			local id = gone[i]
			if not set[id] then
				refusal = judge:place(id, shapeOf(id), was[id])
				if refusal then
					break
				end
				table.insert(placed, id)
			end
		end
	end
	if not refusal then
		return nil
	end
	-- Refused: everything set down comes up again, and all goes back where it stood.
	for i = #placed, 1, -1 do
		judge:remove(placed[i])
	end
	for i = #gone, 1, -1 do
		local id = gone[i]
		judge:place(id, shapeOf(id), was[id])
	end
	return refusal
end

return Group
