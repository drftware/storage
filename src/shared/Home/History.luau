--!strict
--[[
	History (S5-03j4a, D-460): what Undo and Redo do in Arrange, the room editor (D-436). The
	moment, The Sims 4's build mode: you shove the bed into the wrong corner, tap Undo and it glides
	back; Redo sends it again. Only while Arrange is open; closing forgets it all.

	One step is one change the server accepted: a thing moved, set out of the box, or put away. It
	holds the thing and where it stood before and after (no place: in the box). Undo asks the server
	to put the thing where it stood before, Redo where it stood after, as the ordinary Place or Put
	away a finger would send (no new remote): the server judges it as any move, so a spot taken
	since is refused, and that step is dropped from the list.

	A thing keeps one record across all its steps (`Thing`), because its id can change: put away and
	set out again by an undo, it may come back under another number, and every older step about it
	has to follow. The record holds the id it stands as now, or nil while it's in the box.

	Nothing here names a find or reads what a thing is: the steps are ids, names and places. The
	two-sided list itself is Brix's (`Brix.UndoList`, ENG-28c), passed in so this stays pure.

	A group (S5-03j6b1, `Home/Group`): several things moved or put away together are one step,
	`recordGroup`, and its undo or redo is one ask carrying them all (`Ask.more`), sent as one
	group ask the server judges all or none; its answer gives each thing's id in the same order.

	Pure: ArrangeUndo calls `record` for each accepted change the hand reports, `undo` and `redo`
	for the buttons and keys (each answers the ask to send, or nil), and `answered` with the
	server's word. Its spec: tests/history.spec.luau.
]]

-- A place in the room, as Brix's Placements gives it (`Brix.PlacementPose`).
export type Pose = { on: string, x: number, y: number, turn: number }

-- One thing across its steps: what it is, and the id it stands as now (nil: in the box).
export type Thing = { name: string, id: string? }

-- One change; a group's first change holds the rest in `more` (one step for them all).
export type Step = { thing: Thing, before: Pose?, after: Pose?, more: { Step }? }

-- A change the server accepted, for `recordGroup`: as `record`'s arguments.
export type Change = {
	name: string,
	idBefore: string?,
	before: Pose?,
	idAfter: string?,
	after: Pose?,
}

-- What to send for an undo or redo: move `id` to `to`; with no `id`, set `name` out of the box
-- onto `to`; with no `to`, put `id` away. A group's ask is its first thing's, the others in `more`,
-- all moves and set-outs (a group Place) or all put-aways (a group Put away), never mixed.
export type Ask = { name: string, id: string?, to: Pose?, more: { Ask }? }

-- The part of Brix's UndoList this uses (`Brix.UndoList<Step>`).
export type List = {
	record: (self: any, step: Step) -> (),
	undo: (self: any) -> Step?,
	redo: (self: any) -> Step?,
	drop: (self: any, step: Step) -> boolean,
	canUndo: (self: any) -> boolean,
	canRedo: (self: any) -> boolean,
	clear: (self: any) -> (),
}

export type History = {
	-- A change the server accepted: what was `idBefore` at `before` (nil, nil: out of the box) is
	-- now `idAfter` at `after` (nil, nil: in the box). A change from the box to the box is no step.
	record: (name: string, idBefore: string?, before: Pose?, idAfter: string?, after: Pose?) -> (),
	-- Several changes the server accepted as one group ask: one step, undone and redone as one.
	recordGroup: (changes: { Change }) -> (),
	-- Starts an undo or a redo: the ask to send, or nil when there's nothing to do or an ask is
	-- still waiting for its answer.
	undo: () -> Ask?,
	redo: () -> Ask?,
	-- The server's word on the ask in flight: kept (standing as `id`, or in the box; a group's
	-- others as `more`, in its ask's order), or refused, and then that step is dropped.
	answered: (ok: boolean, id: string?, more: { string? }?) -> (),
	-- Whether an ask waits for its answer.
	waiting: () -> boolean,
	canUndo: () -> boolean,
	canRedo: () -> boolean,
	-- Forgets everything (Arrange closed).
	clear: () -> (),
}

local History = {}

function History.new(list: List): History
	-- Each thing that stands, by the id it stands as now.
	local byId: { [string]: Thing } = {}
	-- The parts of the step whose ask is in flight (one, or a group's), where each is going, and
	-- the step itself.
	local pending: Step? = nil
	local parts: { Step } = {}
	local tos: { Pose | false } = {}

	local function moveThing(thing: Thing, id: string?)
		local was = thing.id
		if was and byId[was] == thing then
			byId[was] = nil
		end
		thing.id = id
		if id then
			byId[id] = thing
		end
	end

	-- One change as a step, its thing followed to where it stands now; nil for box to box.
	local function change(
		name: string,
		idBefore: string?,
		before: Pose?,
		idAfter: string?,
		after: Pose?
	): Step?
		if before == nil and after == nil then
			return nil
		end
		local known = if idBefore then byId[idBefore] else nil
		local thing: Thing = if known and known.name == name
			then known
			else { name = name, id = idBefore }
		moveThing(thing, if after then idAfter else nil)
		return { thing = thing, before = before, after = after }
	end

	local function record(
		name: string,
		idBefore: string?,
		before: Pose?,
		idAfter: string?,
		after: Pose?
	)
		local step = change(name, idBefore, before, idAfter, after)
		if step then
			list:record(step)
		end
	end

	local function recordGroup(changes: { Change })
		local first: Step? = nil
		local more: { Step } = {}
		for _, c in changes do
			local step = change(c.name, c.idBefore, c.before, c.idAfter, c.after)
			if step and first then
				table.insert(more, step)
			elseif step then
				first = step
			end
		end
		if first then
			first.more = if #more > 0 then more else nil
			list:record(first)
		end
	end

	-- Sends the things of `step` (where `before` says: to where they stood before, else after), or
	-- drops the step when there's nothing to send.
	local function start(step: Step?, before: boolean): Ask?
		if not step then
			return nil
		end
		table.clear(parts)
		table.clear(tos)
		local asks: { Ask } = {}
		local function add(each: Step)
			local to = if before then each.before else each.after
			if each.thing.id == nil and to == nil then
				return -- already in the box: nothing to ask
			end
			table.insert(parts, each)
			table.insert(tos, to or false)
			table.insert(asks, { name = each.thing.name, id = each.thing.id, to = to })
		end
		add(step)
		local more: { Step } = step.more or {}
		for _, each in more do
			add(each)
		end
		if #asks == 0 then
			list:drop(step)
			return nil
		end
		pending = step
		local ask = asks[1]
		if #asks > 1 then
			ask.more = table.move(asks, 2, #asks, 1, {})
		end
		return ask
	end

	return {
		record = record,
		recordGroup = recordGroup,
		undo = function(): Ask?
			if pending then
				return nil
			end
			return start(list:undo(), true)
		end,
		redo = function(): Ask?
			if pending then
				return nil
			end
			return start(list:redo(), false)
		end,
		answered = function(ok: boolean, id: string?, more: { string? }?)
			local step = pending
			if not step then
				return
			end
			if ok then
				for i, part in parts do
					local now = if i == 1 then id elseif more then more[i - 1] else nil
					moveThing(part.thing, if tos[i] then now else nil)
				end
			else
				list:drop(step)
			end
			pending = nil
			table.clear(parts)
			table.clear(tos)
		end,
		waiting = function(): boolean
			return pending ~= nil
		end,
		canUndo = function(): boolean
			return list:canUndo()
		end,
		canRedo = function(): boolean
			return list:canRedo()
		end,
		clear = function()
			list:clear()
			table.clear(byId)
			pending = nil
			table.clear(parts)
			table.clear(tos)
		end,
	}
end

return History
