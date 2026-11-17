--!strict
--[[
	FindUseView: every pressed find on this screen plays what its press started (F-G1b2, D-229).
	The moment: you take a lantern, press Switch, it clicks on and lights the hall; your friend
	sees it light in your hand; you drop it lit and it stays lit on the floor. The jack cranks its
	tune, bangs open, and monsters come to look.

	The server stamps a pressed find's model (`FindUses`: its state, the server clock, the light
	left) and tags it. Here each tagged model works out where it is in its motions from the stamp
	and the server clock (`Use.frame`) and stands its parts there by their joints alone
	(`Finds.joints`: a find in a hand is part of a character, so no part is ever moved). Only a
	find whose frame moves is posed again: a lantern held lit holds still and costs nothing. A
	step's sound plays at the find as the step starts, never for a find just come into view.

	Your own find in hand is drawn twice: the real one in your character (what friends see) and
	your view's copy near your eye (`ToolView`); your copy plays the same frame and carries the
	light, so the hall lights from where you see it. Your press answers at once with the stamp it
	will get (`press`) until the server's lands, and `can` hides the button while a press would do
	nothing (a tea light burning, a jack mid-tune, a spent glow stick).

	Real lights shine on the `Use.LightsShown` nearest lit finds only; the rest still glow.

	A step with a `hit` sounds on every beat of its motion (the cymbal monkey's every clash), only
	the beats still to come for a find just come into view. A find set down to play (the toy car)
	rolls from where it was set down to where the server laid it, its root moved on this screen
	alone while it lies loose and rolls; it holds where it stopped short if it met a wall. A
	wind-up that `walks` (the chattering teeth) plays on against the wall, held where it stopped
	over the floor (F-G1e2a).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Art = require(ReplicatedStorage.Shared.Finds.Art)
local Brix = require(ReplicatedStorage.Brix)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Pose = require(ReplicatedStorage.Shared.Finds.Pose)
local ToolView = require(script.Parent.ToolView)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

local player = Players.LocalPlayer

-- Finds farther than this from your camera hold their last pose until you come near (studs): a
-- flame flickering across the floor isn't worth its sums every frame.
local STEP_RANGE = 90
-- Seconds between choosing which finds' lights shine.
local RANK_EVERY = 0.2
-- A press seen within this many seconds of its stamp is heard from its start: a friend's first
-- press reaches you with the find's tag, and a lag spike is no reason to miss the click.
local FRESH = 1

type Entry = {
	model: Model,
	key: string,
	row: Use.Row,
	durations: { [string]: number },
	motions: { [string]: Art.Motion },
	rest: Pose.Values,
	stamp: Use.Stamp?, -- the server's
	predicted: Use.Stamp?, -- your own press, until the server's stamp lands
	predictedUntil: number,
	-- the stamp the sounds have followed (its state and clock) and its last step heard
	heardState: string?,
	heardAt: number,
	heardStep: number,
	-- what it was last posed at
	motion: string?,
	t: number,
	lights: boolean, -- its real lights may shine (`rank`)
	posedLights: boolean,
	view: Model?, -- your view's copy it last posed (your own find in hand)
	dirty: boolean, -- pose again whatever the frame (a part streamed in)
	glowing: boolean, -- a candidate for real lights
	shines: boolean, -- it has real lights at all
	-- each step motion's sounds after it starts (its `hit`'s beats, its `cues`), by motion name
	beats: { [string]: { Use.Cue } },
	beatStep: number, -- the step and stamp the beats follow, and the next beat to sound
	beatAt: number,
	beatNext: number,
	from: CFrame?, -- where a find set down to play set off (the server's stamp)
	stop: number?, -- the seconds into its press it stopped short
	root: string, -- its root part's name: what travels over the floor
	-- a wind-up stopped by a wall: its frame where it stopped (it plays on, held there), and
	-- the stamp that frame is for
	held: Pose.Values?,
	heldAt: number,
	connections: { RBXScriptConnection },
}

export type Api = {
	-- Your press of the find `key` in your hand: true if it does something now (its stamp shown
	-- at once), so the press goes to the server.
	press: (key: string) -> boolean,
	-- Whether a press of the find `key` in your hand would do anything now (other keys: true).
	can: (key: string) -> boolean,
}

local FindUseView = {}

function FindUseView.new(hand: ToolView.Hand): (Brix.System, Api)
	local connections: { RBXScriptConnection } = {}
	local entries: { [Model]: Entry } = {}
	local rankIn = 0
	local lastPress = -math.huge

	local function stampOf(e: Entry): Use.Stamp?
		local p = e.predicted
		if p and os.clock() < e.predictedUntil then
			return p
		end
		return e.stamp
	end

	-- The server's stamp, read when its clock changes (written last, so the rest is there). A
	-- stamp confirming your own press keeps your press's clock, so nothing plays twice.
	local function reread(e: Entry)
		local m = e.model
		local s = Use.read(
			m:GetAttribute(Use.StateAttribute),
			m:GetAttribute(Use.AtAttribute),
			m:GetAttribute(Use.LeftAttribute)
		)
		local p = e.predicted
		if s and p and s.state == p.state and math.abs(s.at - p.at) < Use.Predict then
			s = { state = s.state, at = p.at, left = s.left }
		end
		e.predicted = nil
		e.stamp = s
		local from, stop = m:GetAttribute(Use.FromAttribute), m:GetAttribute(Use.StopAttribute)
		e.from = if typeof(from) == "CFrame" then from else nil
		e.stop = if type(stop) == "number" then stop else nil
		e.held = nil
	end

	local function add(model: Model, key: string): Entry?
		local had = entries[model]
		if had then
			return had
		end
		local row = Use.Rows[key]
		local art = Finds.art(key)
		if not (row and art) then
			return nil
		end
		local beats: { [string]: { Use.Cue } } = {}
		for _, step in row.on do
			if step.hit or step.cues then
				beats[step.motion] = Use.timeline(step, art.Motions[step.motion])
			end
		end
		local e: Entry = {
			model = model,
			key = key,
			row = row,
			durations = Finds.durations(key),
			motions = art.Motions,
			rest = Finds.rest(key),
			stamp = nil,
			predicted = nil,
			predictedUntil = 0,
			heardState = nil,
			heardAt = -1,
			heardStep = -1, -- first sight: whatever step it's on is heard already
			motion = nil,
			t = -1,
			lights = false,
			posedLights = false,
			view = nil,
			dirty = true,
			glowing = false,
			shines = #art.Lights > 0,
			beats = beats,
			beatStep = -1,
			beatAt = -1,
			beatNext = 1,
			from = nil,
			stop = nil,
			root = art.Parts[1].Name,
			held = nil,
			heldAt = -1,
			connections = {},
		}
		entries[model] = e
		reread(e)
		table.insert(
			e.connections,
			model:GetAttributeChangedSignal(Use.AtAttribute):Connect(function()
				reread(e)
			end)
		)
		table.insert(
			e.connections,
			model.DescendantAdded:Connect(function()
				e.dirty = true
			end)
		)
		return e
	end

	local function drop(model: Model)
		local e = entries[model]
		if not e then
			return
		end
		entries[model] = nil
		for _, c in e.connections do
			c:Disconnect()
		end
		Finds.grip(model, CFrame.identity)
	end

	local function onTagged(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local key = inst:GetAttribute(Use.KeyAttribute)
		if type(key) == "string" then
			add(inst, key)
		end
	end

	-- Your find in hand: the real model in your character.
	local function held(): Model?
		local character = player.Character
		local m = character and character:FindFirstChild(Tools.HeldName)
		return if m and m:IsA("Model") then m else nil
	end

	local function alive(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end

	-- Whether a press of `key` (in your hand as `model`) does something now.
	local function would(key: string, model: Model): (Use.State?, number)
		local row = Use.Rows[key]
		if not row then
			return nil, 0
		end
		local e = entries[model]
		local s = if e
			then stampOf(e)
			else Use.read(
				model:GetAttribute(Use.StateAttribute),
				model:GetAttribute(Use.AtAttribute),
				model:GetAttribute(Use.LeftAttribute)
			)
		local now = Workspace:GetServerTimeNow()
		return Use.press(row, s, if s then now - s.at else 0, Finds.durations(key))
	end

	local api: Api = {
		press = function(key: string): boolean
			local model = held()
			if not (model and Use.Rows[key] and alive()) then
				return false
			end
			local clock = os.clock()
			if clock - lastPress < Use.Gap then
				return false
			end
			local pressed, left = would(key, model)
			if not pressed then
				return false
			end
			local state: Use.State = pressed :: Use.State
			local e = add(model, key)
			if not e then
				return false
			end
			lastPress = clock
			e.predicted = { state = state, at = Workspace:GetServerTimeNow(), left = left }
			e.predictedUntil = clock + Use.Predict
			return true
		end,
		can = function(key: string): boolean
			if not Use.Rows[key] then
				return true
			end
			local model = held()
			return model ~= nil and (would(key, model)) ~= nil
		end,
	}

	-- A step's sound as it starts, at the find.
	local function hear(e: Entry, stamp: Use.Stamp, step: number, elapsed: number)
		if e.heardState ~= stamp.state or e.heardAt ~= stamp.at then
			-- a new press: heard from its first step, unless the find comes into view long after
			-- it (a friend's first press tags the find as it happens, so that one is heard)
			local late = e.heardStep < 0 and elapsed > FRESH
			e.heardState, e.heardAt = stamp.state, stamp.at
			e.heardStep = if late then step else 0
		end
		if step == e.heardStep then
			return
		end
		e.heardStep = step
		local s = Use.stepAt(e.row, stamp.state, step)
		local sound = s and s.sound
		local body = Tools.body(e.model)
		if sound and body then
			Tools.play(sound, body, Use.Reach)
		end
	end

	-- A step's sounds on each beat and cue its motion passes, `t` seconds in: never a burst of one
	-- sound after a hitch, and only the ones still to come for a step first seen mid-way.
	local function beat(e: Entry, stamp: Use.Stamp, f: Use.Frame)
		local s = Use.stepAt(e.row, stamp.state, f.step)
		local times = s and e.beats[s.motion]
		if not (s and times and f.motion == s.motion) then
			return
		end
		if e.beatStep ~= f.step or e.beatAt ~= stamp.at then
			e.beatStep, e.beatAt, e.beatNext = f.step, stamp.at, 1
			while e.beatNext <= #times and times[e.beatNext].t < f.t - 0.05 do
				e.beatNext += 1
			end
		end
		local body = Tools.body(e.model)
		local last: Use.Sound? = nil
		while e.beatNext <= #times and times[e.beatNext].t <= f.t do
			local sound = times[e.beatNext].sound
			e.beatNext += 1
			-- several due at once (a hitch): each different sound once
			if body and sound ~= last then
				Tools.play(sound, body, Use.Reach)
			end
			last = sound
		end
	end

	-- Whether `model` lies loose on a floor (not in a hand or a monster's): its root may be moved.
	local function loose(model: Model): boolean
		local parent = model.Parent
		local body = Tools.body(model)
		return parent ~= nil and not parent:IsA("Model") and body ~= nil and body.Anchored
	end

	-- Which finds' real lights shine: the nearest glowing ones, your own in hand first.
	local function rank(mine: Model?)
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local lit: { Entry } = {}
		local far: { [Entry]: number } = {}
		for _, e in entries do
			if e.glowing then
				table.insert(lit, e)
				far[e] = if e.model == mine
					then -1
					else (e.model:GetPivot().Position - eye).Magnitude
			end
		end
		table.sort(lit, function(a, b)
			return far[a] < far[b]
		end)
		for _, e in entries do
			e.lights = false
		end
		for i = 1, math.min(#lit, Use.LightsShown) do
			lit[i].lights = true
		end
	end

	local system = { name = "FindUseView" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Use.Tag):Connect(onTagged)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Use.Tag):Connect(function(inst: Instance)
				if inst:IsA("Model") then
					drop(inst)
				end
			end)
		)
		for _, inst in CollectionService:GetTagged(Use.Tag) do
			onTagged(inst)
		end
	end

	function system.step(_: any, dt: number)
		local mine = held()
		local view, viewKey = hand.model()
		rankIn -= dt
		if rankIn <= 0 then
			rankIn = RANK_EVERY
			rank(mine)
		end
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local now = Workspace:GetServerTimeNow()
		local clock = os.clock()
		for model, e in entries do
			-- your press refused (no word in time) and never tagged: back to how it was
			if
				e.predicted
				and clock >= e.predictedUntil
				and not CollectionService:HasTag(model, Use.Tag)
			then
				e.predicted = nil
				Finds.joints(model, e.key, e.rest, model:GetScale(), false)
				if view and model == mine and viewKey == e.key then
					Finds.joints(view, e.key, e.rest, view:GetScale(), false)
					hand.shift(CFrame.identity)
				end
				drop(model)
				continue
			end
			local own = model == mine and view ~= nil and viewKey == e.key
			if not own and (model:GetPivot().Position - eye).Magnitude > STEP_RANGE then
				continue
			end
			local stamp = stampOf(e)
			-- a stop short is the server's stamp's: your own press shown early has none
			local stop = if stamp and stamp == e.stamp then e.stop else nil
			local elapsed, travel = 0, 0
			if stamp then
				elapsed, travel = Use.played(e.row, now - stamp.at, stop)
			end
			local f = Use.frame(e.row, stamp, elapsed, e.durations)
			e.glowing = e.shines
				and not f.spent
				and (f.lit or (stamp ~= nil and stamp.state ~= "Off" and f.motion ~= nil))
			if stamp then
				hear(e, stamp, f.step, now - stamp.at)
				beat(e, stamp, f)
			end
			-- a find set down to play rolls on this screen while it lies loose and rolls
			local from: CFrame? = nil
			if e.row.down and stamp and stamp == e.stamp and e.from then
				local total = 0
				for _, step in Use.chain(e.row, stamp.state) do
					total += Use.length(step, e.durations)
				end
				-- a wind-up stopped by a wall plays on where it stands, bobbing as it goes
				local ends = if e.row.walks then total else stop or total
				if now - stamp.at <= ends + 0.5 and loose(model) then
					from = e.from
				end
			end
			local shownView = if own then view else nil
			if
				not e.dirty
				and f.motion == e.motion
				and f.t == e.t
				and e.lights == e.posedLights
				and shownView == e.view
			then
				continue
			end
			e.dirty, e.motion, e.t, e.view, e.posedLights =
				false, f.motion, f.t, shownView, e.lights
			local motion = if f.motion then e.motions[f.motion] else nil
			local values = if motion then Pose.at(motion, f.t, e.rest) else e.rest
			-- a wind-up stopped short by a wall: held where it stopped over the floor
			if stamp and travel < elapsed then
				if not e.held or e.heldAt ~= stamp.at then
					local g = Use.frame(e.row, stamp, travel, e.durations)
					local gm = if g.motion then e.motions[g.motion] else nil
					e.held = if gm then Pose.at(gm, g.t, e.rest) else e.rest
					e.heldAt = stamp.at
				end
				values = Pose.hold(values, e.held :: Pose.Values, e.root, Use.Holds)
			end
			if shownView then
				Finds.joints(model, e.key, values, model:GetScale(), false)
				Finds.joints(shownView, e.key, values, shownView:GetScale(), e.lights)
			else
				Finds.joints(model, e.key, values, model:GetScale(), e.lights, from)
			end
			-- its root's own motion (the kazoo lifted to your lips) moves the grip that holds
			-- it, here and in your view's copy; a find set down to play never plays in a hand
			if not e.row.down then
				Finds.grip(model, Finds.shift(model, e.key, values, e.rest, model:GetScale()))
				if shownView then
					local scale = shownView:GetScale()
					hand.shift(Finds.shift(shownView, e.key, values, e.rest, scale))
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in entries do
			drop(model)
		end
	end

	return system :: any, api -- any: a plain Brix system built field by field
end

return FindUseView
