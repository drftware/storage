--!strict
--[[
	Selection (S5-03j6a): which things a box dragged across the screen in Arrange, the room editor
	(D-436), takes. The moment: you hold a finger on bare floor, drag a box round the crate, the
	lamp on it and the rug, and each lights up as the box reaches it; let go and the three stay lit,
	ready to move as one. As The Sims 4's build-mode box and Bloxburg's multi-select.

	Pure: screen points in, ids out. It names no find: what a thing stands on comes from the
	room's placements (`baseOf`, `standingOn`), so any thing, any top, any height of stacking
	works the same. Who calls it: ArrangeBox, as the box's finger moves (`inside`, then `roots`,
	then `lit`) and to know when to tick (`joined`). Its spec: tests/selection.spec.luau.
]]

local Selection = {}

-- How far (points) the box's corners must be apart, across or down, before it takes anything:
-- under it the finger is only settling after the hold, not drawing yet.
Selection.Slop = 14
-- At most this many things glow at once (Roblox draws 31 Highlights in all, and the hand and the
-- blocker glows need theirs): past it the rest are still taken, only unlit. A home rarely holds
-- this many in one box.
Selection.Most = 24
-- Each thing joining the box ticks this much higher than the one before (a share of the tick's
-- pitch), up to `TopPitch` times it: a box sweeping across a room plays a rising run, as a
-- combo counter climbs.
Selection.Rise = 0.05
Selection.TopPitch = 1.5
-- The box's fill and edge (transparency, 0 to 1), and how long (seconds) it fades in once it's
-- past the slop and out as the finger lifts: there and gone, never snapping.
Selection.Fill = 0.86
Selection.Edge = 0.15
Selection.Fade = 0.1
-- The glow on a taken thing: its fill's transparency (a faint wash, the thing still reads) and how
-- long it takes to come up as the box reaches it.
Selection.Glow = 0.78
Selection.GlowIn = 0.08

-- A box on the screen, in points, y down; left <= right and top <= bottom.
export type Box = { left: number, top: number, right: number, bottom: number }

-- A thing's middle on the screen (points) and whether it is in front of the camera.
export type Point = { id: string, x: number, y: number, ahead: boolean }

-- The box with corners `ax, ay` and `bx, by`, either way round. Fills `into` when given.
function Selection.box(ax: number, ay: number, bx: number, by: number, into: Box?): Box
	local b: Box = into or { left = 0, top = 0, right = 0, bottom = 0 }
	b.left, b.right = math.min(ax, bx), math.max(ax, bx)
	b.top, b.bottom = math.min(ay, by), math.max(ay, by)
	return b
end

-- Whether the box is drawn yet: past `Slop` across or down.
function Selection.big(b: Box): boolean
	return b.right - b.left >= Selection.Slop or b.bottom - b.top >= Selection.Slop
end

-- The ids of `points` whose middle is in the box (edges count) and in front of the camera, in
-- `points`' order. A box not yet `big` takes nothing. Fills `into` (emptied first) when given.
function Selection.inside(b: Box, points: { Point }, into: { string }?): { string }
	local out = into or {}
	table.clear(out)
	if not Selection.big(b) then
		return out
	end
	for _, p in points do
		if p.ahead and p.x >= b.left and p.x <= b.right and p.y >= b.top and p.y <= b.bottom then
			table.insert(out, p.id)
		end
	end
	return out
end

-- Of `ids`, the ones whose base (what they stand on, `baseOf`; nil for a room's own area such as
-- the floor or a wall) isn't also among `ids`, however far down: those ride along with their base,
-- so a group move carries each thing once. In `ids`' order, as a new list.
function Selection.roots(ids: { string }, baseOf: (id: string) -> string?): { string }
	local chosen: { [string]: boolean } = {}
	for _, id in ids do
		chosen[id] = true
	end
	local out = {}
	for _, id in ids do
		local under, steps, riding = baseOf(id), 0, false
		-- 64: a stack is never that tall; it and `under ~= id` guard a bad loop of bases
		while under and under ~= id and steps < 64 do
			if chosen[under] then
				riding = true
				break
			end
			under, steps = baseOf(under), steps + 1
		end
		if not riding then
			table.insert(out, id)
		end
	end
	return out
end

-- `roots` and everything standing on them, however high up (`standingOn`), each once: what
-- lights up and moves. Roots first in their order, then each one's riders. A new list.
function Selection.lit(roots: { string }, standingOn: (id: string) -> { string }): { string }
	local out, seen = {}, {}
	local function add(id: string, depth: number)
		if seen[id] or depth > 64 then
			return
		end
		seen[id] = true
		table.insert(out, id)
		for _, rider in standingOn(id) do
			add(rider, depth + 1)
		end
	end
	for _, id in roots do
		add(id, 0)
	end
	return out
end

-- How many of `now` weren't in `before`: the things that just joined, one tick each.
function Selection.joined(before: { string }, now: { string }): number
	local had: { [string]: boolean } = {}
	for _, id in before do
		had[id] = true
	end
	local n = 0
	for _, id in now do
		if not had[id] then
			n += 1
		end
	end
	return n
end

-- Whether `a` and `b` hold the same ids, in any order.
function Selection.same(a: { string }, b: { string }): boolean
	return #a == #b and Selection.joined(a, b) == 0
end

return Selection
