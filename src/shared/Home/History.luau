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

	Pure: ArrangeUndo calls `record` for each accepted change the hand reports, `undo` and `redo`
	for the buttons and keys (each answers the ask to send, or nil), and `answered` with the
	server's word. Its spec: tests/history.spec.luau.
]]

-- A place in the room, as Brix's Placements gives it (`Brix.PlacementPose`).
export type Pose = { on: string, x: number, y: number, turn: number }

-- One thing across its steps: what it is, and the id it stands as now (nil: in the box).
export type Thing = { name: string, id: string? }

export type Step = { thing: Thing, before: Pose?, after: Pose? }

-- What to send for an undo or redo: move `id` to `to`; with no `id`, set `name` out of the box
-- onto `to`; with no `to`, put `id` away.
export type Ask = { name: string, id: string?, to: Pose? }

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
	-- Starts an undo or a redo: the ask to send, or nil when there's nothing to do or an ask is
	-- still waiting for its answer.
	undo: () -> Ask?,
	redo: () -> Ask?,
	-- The server's word on the ask in flight: kept (standing as `id`, or in the box), or refused,
	-- and then that step is dropped.
	answered: (ok: boolean, id: string?) -> (),
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
	-- The step whose ask is in flight, and where it's sending the thing.
	local pending: Step? = nil
	local pendingTo: Pose? = nil

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

	local function record(
		name: string,
		idBefore: string?,
		before: Pose?,
		idAfter: string?,
		after: Pose?
	)
		if before == nil and after == nil then
			return
		end
		local known = if idBefore then byId[idBefore] else nil
		local thing: Thing = if known and known.name == name
			then known
			else { name = name, id = idBefore }
		moveThing(thing, if after then idAfter else nil)
		list:record({ thing = thing, before = before, after = after })
	end

	-- Sends the thing of `step` to `to`, or drops the step when there's nothing to send.
	local function start(step: Step?, to: Pose?): Ask?
		if not step then
			return nil
		end
		local thing = step.thing
		if thing.id == nil and to == nil then
			list:drop(step) -- already in the box: nothing to ask
			return nil
		end
		pending, pendingTo = step, to
		return { name = thing.name, id = thing.id, to = to }
	end

	return {
		record = record,
		undo = function(): Ask?
			if pending then
				return nil
			end
			local step = list:undo()
			return start(step, if step then step.before else nil)
		end,
		redo = function(): Ask?
			if pending then
				return nil
			end
			local step = list:redo()
			return start(step, if step then step.after else nil)
		end,
		answered = function(ok: boolean, id: string?)
			local step = pending
			if not step then
				return
			end
			if ok then
				moveThing(step.thing, if pendingTo then id else nil)
			else
				list:drop(step)
			end
			pending, pendingTo = nil, nil
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
			pending, pendingTo = nil, nil
		end,
	}
end

return History
