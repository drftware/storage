--!strict
--[[
	FindUses: pressing a find on the server (F-G1b2, D-229), a system like `Horns`. A press comes
	in as `Slots.used` (a living player with a find with a verb in hand, the press's rate already
	checked by Slots); here it must wait out `Use.Gap` since that player's last press, and the find
	must take the press now (`Use.press` against the stamp on its model: a burning tea light, a
	spent glow stick or a jack still mid-tune takes none). Then the stamp: the model gets its
	state, the server clock and the light left as attributes, and the tag, and every screen plays
	it from there (`FindUseView`). The same model moves from hand to floor and back, so a lantern
	dropped lit stays lit. A noisy find (the jack, the duck) is heard by every monster on the floor
	as its noise starts, where the find is then, unless it was pressed again since; a lure (the
	cymbal monkey) is heard again every few seconds for as long as it plays (F-G1b3a). Each is
	heard as far as its loudness (`Use.loudness`, F-G1e1), one find at most once a `Use.HearGap`,
	and only `Use.LuresAtOnce` lures at a time: the newest (`Use.Din`).

	A find set down to play (the toy car, `down`) leaves your hand: it's stood on the floor in
	front of you, and its path is walked here first, so it stops short where it would roll into a
	wall. The server lays it where its roll ends at once (that's where it is, for picking up and
	for the Packrat) and stamps where it set off; every screen rolls it there.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Pose = require(ReplicatedStorage.Shared.Finds.Pose)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Keepers = require(script.Parent.Keepers)
local Slots = require(script.Parent.Slots)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

local FindUses = {}

-- Seconds between the points of a set-down find's path checked for walls: a toy car at its
-- fastest moves under half a stud in one.
local PATH_STEP = 0.1

-- The stamp on `model`, nil if it was never pressed.
local function stampOf(model: Model): Use.Stamp?
	return Use.read(
		model:GetAttribute(Use.StateAttribute),
		model:GetAttribute(Use.AtAttribute),
		model:GetAttribute(Use.LeftAttribute)
	)
end

function FindUses.new(): Brix.System
	local connections: { Brix.SignalConnection } = {}
	local leaving: RBXScriptConnection? = nil
	local last: { [Player]: number } = {} -- each player's last press that took, os.clock
	local keepers: Keepers.Keepers? = nil
	local slots: Slots.Slots? = nil
	local din: Use.Din<Model> = Use.din() -- the noises monsters hear: lures sounding, last heard

	-- Every monster on the floor hears `model`'s noise where it is now, as far as `row`'s
	-- loudness, unless it was heard under `Use.HearGap` ago: how many heard it, nil if it wasn't.
	local function heardAt(model: Model, row: Use.Row, what: string): number?
		local k = keepers
		if not (k and Use.hear(din, model, os.clock())) then
			return nil
		end
		return k:hear(model:GetPivot().Position, Use.loudness(row), what)
	end

	-- A noise (the jack's bang, the duck's squeak), `delay` seconds after the press stamped `at`:
	-- heard where the find is then.
	local function bang(model: Model, row: Use.Row, at: number, delay: number, who: string)
		task.delay(delay, function()
			if model.Parent == nil or model:GetAttribute(Use.AtAttribute) ~= at then
				return
			end
			local heard = heardAt(model, row, "a find's noise")
			if RunService:IsStudio() then
				local key = model:GetAttribute(Use.KeyAttribute)
				print(
					if heard
						then `FindUses: {who}'s {key} made its noise ({Use.loudness(row)} studs); {heard} heard it`
						else `FindUses: {who}'s {key} made its noise; heard too lately to be heard again`
				)
			end
		end)
	end

	-- A lure (the cymbal monkey) heard by every monster on the floor from `from` seconds after the
	-- press stamped `at` until `to`, every `Use.lureBeat`, wherever the find is then: one task a
	-- press, ended by another press, the find's going, the end of its play, or newer lures
	-- past `Use.LuresAtOnce`.
	local function lure(
		model: Model,
		row: Use.Row,
		at: number,
		from: number,
		to: number,
		who: string
	)
		-- a function, so the checker reads the parent fresh each time (it can go between waits)
		local function gone(): boolean
			return model.Parent == nil
		end
		local loud = Use.loudness(row)
		task.delay(from, function()
			if gone() or model:GetAttribute(Use.AtAttribute) ~= at then
				if gone() then
					Use.stopLure(din, model) -- gone before its lure began: never counted again
				end
				return
			end
			Use.startLure(din, model)
			local times, heard = 0, 0
			while
				not gone()
				and model:GetAttribute(Use.AtAttribute) == at
				and Use.luring(din, model)
			do
				if Workspace:GetServerTimeNow() - at >= to then
					break
				end
				local n = heardAt(model, row, "a lure")
				if n then
					heard = math.max(heard, n)
					times += 1
				end
				task.wait(Use.lureBeat(row))
			end
			-- wound again since, its new lure is its own
			if gone() or model:GetAttribute(Use.AtAttribute) == at then
				Use.stopLure(din, model)
			end
			if RunService:IsStudio() then
				print(
					`FindUses: {who}'s {model:GetAttribute(Use.KeyAttribute)} lured {times} times ({loud} studs); {heard} heard it`
				)
			end
		end)
	end

	--[[
		Sets `use`'s find down to play its press (`down`): out of the player's hand onto the floor
		just in front of them, facing where they face, its path walked for walls, laid where it ends.
		Where it set off and where it stopped short go on the model for every screen. False, and it
		stays in hand, if there's no floor in front of them.
	]]
	local function setDown(
		use: Slots.Use,
		row: Use.Row,
		state: Use.State,
		durations: { [string]: number }
	): boolean
		local s = slots
		local character = use.player.Character
		local body = character and character:FindFirstChild("HumanoidRootPart")
		local art = Finds.art(use.key)
		local box = Finds.box(use.key)
		if not (s and body and body:IsA("BasePart") and art and box) then
			return false
		end
		local model = use.model
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = { model }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		local look = body.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 1e-3 then
			return false
		end
		flat = flat.Unit
		-- just in front of your feet, short of a wall
		local wall = Workspace:Raycast(body.Position, flat * Use.SetAhead, params)
		local over = if wall
			then wall.Position - flat * (box.Size.Z / 2 + 0.1)
			else body.Position + flat * Use.SetAhead
		local floor = Workspace:Raycast(over, Vector3.new(0, -8, 0), params)
		if not floor then
			return false
		end
		local from = CFrame.lookAt(floor.Position, floor.Position + flat)
		-- its root along the press, sampled
		local rest = Finds.rest(use.key)
		local stamp: Use.Stamp = { state = state, at = 0, left = Use.Forever }
		local function rootAt(t: number): CFrame?
			local f = Use.frame(row, stamp, t, durations)
			local m = if f.motion then art.Motions[f.motion] else nil
			return Finds.rootAt(model, use.key, if m then Pose.at(m, f.t, rest) else rest)
		end
		local total = 0
		for _, step in Use.chain(row, state) do
			total += Use.length(step, durations)
		end
		local first = rootAt(0)
		if not first then
			return false
		end
		local stop: number? = nil
		local was = (from * first).Position
		local t = 0
		while t < total do
			local nextT = math.min(t + PATH_STEP, total)
			local at = rootAt(nextT) :: CFrame
			local p = (from * at).Position
			local step = p - was
			-- its nose ahead of its middle: it stops as its nose meets the wall
			if
				step.Magnitude > 1e-4
				and Workspace:Raycast(was, step + step.Unit * box.Size.Z / 2, params)
			then
				stop = t
				break
			end
			was, t = p, nextT
		end
		local id = s:place(use.player, use.key)
		if not id then
			return false
		end
		local ends = from * (rootAt(stop or total) :: CFrame)
		local _, yaw = ends:ToOrientation()
		s:lower(id, Vector3.new(ends.X, floor.Position.Y, ends.Z), math.deg(yaw), true)
		-- then exactly where every screen's roll ends
		local root = model:FindFirstChild(art.Parts[1].Name)
		if root and root:IsA("BasePart") then
			model:PivotTo(ends * root.CFrame:Inverse() * model:GetPivot())
		end
		model:SetAttribute(Use.FromAttribute, from)
		model:SetAttribute(Use.StopAttribute, stop)
		return true
	end

	local function onUsed(use: Slots.Use)
		local row = Use.Rows[use.key]
		if not row then
			return
		end
		local player = use.player
		local t = os.clock()
		local before = last[player]
		if before and t - before < Use.Gap then
			return
		end
		local model = use.model
		local durations = Finds.durations(use.key)
		local now = Workspace:GetServerTimeNow()
		local stamp = stampOf(model)
		local pressed, left = Use.press(row, stamp, if stamp then now - stamp.at else 0, durations)
		if not pressed then
			return
		end
		local state: Use.State = pressed :: Use.State
		if row.down and not setDown(use, row, state, durations) then
			return
		end
		last[player] = t
		model:SetAttribute(Use.KeyAttribute, use.key)
		model:SetAttribute(Use.StateAttribute, state)
		model:SetAttribute(Use.LeftAttribute, Use.encode(left))
		-- last, so a screen reading the stamp on this change sees all of it
		model:SetAttribute(Use.AtAttribute, now)
		CollectionService:AddTag(model, Use.Tag)
		local delay = Use.noiseAt(row, state, durations)
		local to = Use.lureUntil(row, state, durations)
		if delay and to and row.lure then
			lure(model, row, now, delay, to, player.Name)
		elseif delay then
			bang(model, row, now, delay, player.Name)
		end
	end

	local system = { name = "FindUses" }

	function system.start(_: any, context: Brix.Context)
		local s = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry's
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers?
		slots = s
		if s then
			table.insert(connections, s.used:connect(onUsed))
		else
			warn("FindUses: no Slots system, so nobody can use a find")
		end
		leaving = Players.PlayerRemoving:Connect(function(player: Player)
			last[player] = nil
		end)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		if leaving then
			leaving:Disconnect()
			leaving = nil
		end
		table.clear(last)
		din = Use.din()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return FindUses
