--!strict
--[[
	Doors: every storage unit's roll-up door as the GDD's state machine (the pure `Door`), a system
	on the server's Host clock. It finds each unit in the world by its tag and gives it buttons:

	- On the door's hall side, the buttons its state allows and nothing else, each where your hand
	  would go (`Door.place`, L-19b): Open on the door's middle and Peek low by the lift handle on
	  a shut door, Close and Slam side by side in the middle of an open one, Lock and Cut on the
	  latch. Lock shows only on the screen of someone with a padlock in hand (ToolView hides it).
	  The middle row is laid out so a double tap can't fire something else. Each spot is an
	  Attachment tagged `DoorSpot.Tag`; each screen moves its own copy into view (DoorSpotView).
	- Just inside the door, Lift, only while the door is down: someone shut in can always get out
	  (unless it's padlocked: then it rattles).

	Every press is checked before the door moves: the player must be within reach of the button (a
	little slack for lag), on the right side of the door (Lift only from inside), both judged where
	the server sees them or a moment on, as it sees a run late (`Arrival`: sprint out under a
	closing door and Lock it at once, and it may still see you inside, L-16b2), holding the tool it
	needs in their hand (`Slots`: the cutters to Cut, a padlock to Lock, which then leaves their
	slots for good), and not pressing faster than a hand can. A refusal the player can see answers at
	the door: a padlocked door rattles against its bolt, loud, and the button says "Padlocked",
	"Need bolt cutters" or "Hold the cutters" for a moment.

	Every door event fires `acted` with how far it's heard (DoorSound), so keepers (L-06) hear
	exactly what players hear, and every change of a door's state fires `changed`, so the keepers'
	map knows which doorways are open. Only doors in motion are stepped, to refresh their buttons
	when the motion ends. The building moves a door itself with `move`: a keeper trapped behind it
	bangs on it or bursts it up (L-06b3d).

	The tap (S2-05a): a Close pressed over a monster that's asleep or hasn't seen the presser
	(`Taps`, asked through the registry's "taps" slot) eases the door down to hang a foot up instead
	(Motion's "Ease") and opens that player's tap window. The tap's answer moves it the rest of the
	way with `move`: "Settle" on a hit, "Drop" on a miss.

	Each button carries its action as the attribute `DoorAction`, so a screen can find Lock and Cut,
	and the tag `Door.ButtonTag`, so a screen can hide them all from someone lying up on the tops.
	Lying at a unit's front edge your head is over it, 7 studs from the door's buttons below (L-16b1,
	D-111): a crawler's press is ignored, as their screen never shows those buttons.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Arrival = require(ReplicatedStorage.Shared.Arrival)
local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local DoorSpot = require(ReplicatedStorage.Shared.StorageUnit.DoorSpot)
local Ladders = require(script.Parent.Ladders)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

export type DoorEvent = {
	unit: Model,
	action: Door.Action?, -- what a player pressed; nil when the building moved it (`move`)
	motion: Motion.Kind?, -- what the door did; a padlocked door tried rattles
	player: Player?, -- nil when the game itself did it
	at: Vector3, -- the middle of the doorway, on the floor
	reach: number, -- studs it's heard to (DoorSound): a keeper within it hears the door
}

-- The tap (S2-05a), as Doors sees it: whether `player` pulling `unit`'s door down earns the tap,
-- and that its door has started easing down for them. `Taps` fills the "taps" slot; typed here, not
-- required, as Taps requires Doors.
type Careful = {
	earns: (self: any, unit: Model, player: Player) -> boolean,
	begin: (self: any, unit: Model, player: Player) -> (),
}

export type DoorChange = {
	unit: Model,
	state: Door.State, -- what it is now
}

export type Doors = Brix.System & {
	-- Fires for every door action that made a sound: each move, each rattle, each padlock on or off.
	acted: Brix.Signal<DoorEvent>,
	-- Fires as a door's state changes (a door rising fires again once it's all the way up), so the
	-- keepers' map lets them through only while it's open.
	changed: Brix.Signal<DoorChange>,
	-- Puts a padlock on a shut door (true) or takes it off (false). With a player, as they would by
	-- hand (their tools, their side); without, as the game (the director, a test). Whether it took.
	lock: (self: any, unit: Model, locked: boolean, player: Player?) -> boolean,
	-- The door's state now.
	stateOf: (self: any, unit: Model) -> Door.State,
	-- Moves a door as the building does, no player's hand on it (L-06b3d): a trapped keeper's
	-- blow from inside ("Bang"), only on a door at rest, shut, peeked or padlocked; its burst up
	-- ("Burst"), on any door that's down or coming down and not padlocked; or a door rolling all
	-- the way up by itself ("Open", a wrong code's, S2-04), only from shut or peeked. Fires `acted`
	-- with its sound's reach, so keepers hear it as they hear a player's. Or the tap's answer on a
	-- door still easing down over its sleeper (S2-05a): set down soft ("Settle") or dropped with a
	-- bang ("Drop"). Or a door pulled down by the game ("Close", a home let go), from any rise.
	-- Whether it moved.
	move: (self: any, unit: Model, kind: Motion.Kind) -> boolean,
}

-- Where the buttons sit: each spot at its height (DoorSpot.Height). A point inside the door's
-- invisible collider loses its sight line and hides, so each sits just outside it.
local HALL_OUT = RollUpDoor.ColliderDepth / 2 + 0.1 -- the hall side's buttons, just off the door
local INSIDE_IN = RollUpDoor.ColliderDepth / 2 + 0.1 -- Lift, just behind it: a shut door hides it
local LATCH_PART = "Padlock" -- the unit's padlock on its latch (art/unit): the latch spot's side
local LATCH_EDGE = 0.25 -- studs in from the door's edge the latch sits if a unit has no padlock
local SPOT_TOP = 6 -- studs off the floor a screen may raise a spot to: a tall avatar's eye
local HALL_REACH = 8 -- close enough to touch the door, not the neighbour's
local INSIDE_REACH = 5 -- only someone shut inside should see Lift

-- The checks on a press.
local RANGE_SLACK = 4 -- studs past a button's reach still accepted: a moving player's lag
local REPEAT_SECONDS = 0.3 -- a player's presses closer than this are dropped: a double tap
local INSIDE_SLACK = 1 -- studs either side of the doorway that still count as inside the unit
local CUT_SECONDS = 1 -- the bolt cutters' hold (GDD: cut free in a second)
local LOCK_SECONDS = 0.5 -- the padlock's hold: long enough that nobody locks a friend in by a slip

type Button = {
	action: Door.Action,
	text: string,
	key: Enum.KeyCode,
	pad: Enum.KeyCode,
	hold: number?,
}
local Doors = {}

-- Keys: one per action, so none hides another on a keyboard or pad.
local HALL_BUTTONS: { Button } = {
	{ action = "Peek", text = "Peek", key = Enum.KeyCode.Q, pad = Enum.KeyCode.ButtonL1 },
	{ action = "Open", text = "Open", key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX },
	{ action = "Close", text = "Close", key = Enum.KeyCode.F, pad = Enum.KeyCode.ButtonB },
	{ action = "Slam", text = "Slam", key = Enum.KeyCode.G, pad = Enum.KeyCode.ButtonY },
	{
		action = "Cut",
		text = "Cut",
		key = Enum.KeyCode.R,
		pad = Enum.KeyCode.ButtonR2, -- R1 is the torch's (D-047)
		hold = CUT_SECONDS,
	},
	-- Lock and Cut never show together (a shut door, a padlocked one), so they share keys
	{
		action = "Lock",
		text = "Lock",
		key = Enum.KeyCode.R,
		pad = Enum.KeyCode.ButtonR2,
		hold = LOCK_SECONDS,
	},
}
Doors.ActionAttribute = "DoorAction"
local LIFT_BUTTON: Button =
	{ action = "Lift", text = "Lift", key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX }

local PADLOCK: DoorSound.SoundName = "PadlockShut" -- how far a padlock going on is heard
local SNAP: DoorSound.SoundName = "Snap" -- and the cutters' snap taking one off
local ATTR_MOTION = "DoorMotion"
local ATTR_LOCKED = "DoorLocked"

type Entry = {
	unit: Model,
	frame: CFrame, -- the door's frame: +Z into the unit
	halfWidth: number,
	fullStroke: number,
	spots: { [Door.Spot]: Attachment },
	buttons: { [Door.Action]: ProximityPrompt },
	refusers: { [ProximityPrompt]: (string, Player) -> () },
	state: Door.State,
	settles: number, -- server time its motion ends
	conns: { RBXScriptConnection },
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Where `player` has each tool, from their slots: in hand, in the other slot, or not at all.
local function carries(slots: Slots.Slots?, player: Player): Door.Tools
	local tools: Door.Tools = { BoltCutters = "None", Padlock = "None" }
	if not slots then
		return tools
	end
	local keys, hand = slots:carried(player)
	for i, key in keys do
		local where: Door.Holding = if i == hand then "Hand" else "Slot"
		if key == "BoltCutters" and tools.BoltCutters ~= "Hand" then
			tools.BoltCutters = where
		elseif key == "Padlock" and tools.Padlock ~= "Hand" then
			tools.Padlock = where
		end
	end
	return tools
end

function Doors.new(): Doors
	local entries: { [Model]: Entry } = {}
	local moving: { [Entry]: true } = {}
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local acted = Brix.Signal.new() :: Brix.Signal<DoorEvent>
	local changed = Brix.Signal.new() :: Brix.Signal<DoorChange>
	local slots: Slots.Slots? = nil -- what's in each hand (Slots fills its slot in init.server)
	local ladders: Ladders.Ladders? = nil -- who's lying up on the tops
	local taps: Careful? = nil -- the tap over a sleeper (Taps fills its slot in init.server)

	-- A door's buttons carry a name only while it's padlocked: news inside, where the padlock
	-- can't be seen. Its number is painted on the door. Only Open and Lift carry it, the head of
	-- each side, so it shows once.
	local function nameOf(entry: Entry, action: Door.Action): string
		-- a home's door (held, D-274) says nothing: its padlock and its holder's name are in sight
		local held = entry.unit:GetAttribute(Door.HolderAttribute) ~= nil
		if entry.state == "Locked" and not held and (action == "Open" or action == "Lift") then
			return "Padlocked"
		end
		return ""
	end

	-- Reads the door's state from its motion and padlock, and shows only the buttons it allows.
	local function refresh(entry: Entry)
		local unit = entry.unit
		local kind: Motion.Kind, from: number, to: number, start: number =
			Motion.decode(unit:GetAttribute(ATTR_MOTION) :: string?)
		local elapsed = now() - start
		local state: Door.State = Door.stateOf(
			kind,
			from,
			to,
			elapsed,
			entry.fullStroke,
			unit:GetAttribute(ATTR_LOCKED) == true
		)
		entry.settles = start + Motion.duration(kind, from, to, entry.fullStroke)
		if entry.settles > now() then
			moving[entry] = true
		end
		if state == entry.state then
			return
		end
		entry.state = state
		-- nobody padlocks a home or cuts one's padlock off: the game does (Door.decideHeld)
		local held = unit:GetAttribute(Door.HolderAttribute) ~= nil
		for _, point: Door.Side in Door.Sides do
			local offered = Door.offers(state, point)
			for action, p in entry.buttons do
				if (action == "Lift") == (point == "Inside") then
					local byGame = held and (action == "Lock" or action == "Cut")
					p.Enabled = table.find(offered, action) ~= nil and not byGame
				end
			end
		end
		for action: Door.Action, p in entry.buttons do
			p.ObjectText = nameOf(entry, action)
			-- a button going away keeps its place as it fades: only those offered move along the row
			if p.Enabled then
				local _, at = Door.place(state, action)
				p.UIOffset = Vector2.new(at * Door.Step, 0)
			end
		end
		changed:fire({ unit = unit, state = state })
	end

	local function event(entry: Entry, action: Door.Action?, motion: Motion.Kind?, player: Player?)
		local reach = if motion
			then DoorSound.Actions[motion].Reach
			elseif action == "Cut" then DoorSound.Sounds[SNAP].Reach
			else DoorSound.Sounds[PADLOCK].Reach
		acted:fire({
			unit = entry.unit,
			action = action,
			motion = motion,
			player = player,
			at = entry.frame.Position,
			reach = reach,
		})
	end

	-- Where `player` stands: in the hall, or inside the unit (behind the door, within its walls).
	local function sideOf(entry: Entry, at: Vector3): Door.Side
		local p = entry.frame:PointToObjectSpace(at)
		if p.Z > 0 and math.abs(p.X) <= entry.halfWidth + INSIDE_SLACK then
			return "Inside"
		end
		return "Hall"
	end

	--[[
		The nearest place to `at` that a screen may have moved `spot` to (DoorSpotView): anywhere up
		the door from where it belongs to a tall eye, or down to the row's lowest while kneeling,
		and the latch's anywhere in along the bar to the door's middle. Reach is judged from there,
		so a button a player sees within reach is within reach here too.
	]]
	local function nearest(entry: Entry, spot: Door.Spot, at: Vector3): Vector3
		local a = entry.spots[spot]
		if not DoorSpot.Moves[spot] then
			return a.WorldPosition
		end
		local frame = entry.frame
		local home = frame:PointToObjectSpace(a.WorldPosition)
		local p = frame:PointToObjectSpace(at)
		local x = math.clamp(p.X, math.min(home.X, 0), math.max(home.X, 0))
		local y = math.clamp(p.Y, math.min(home.Y, DoorSpot.Lowest), math.max(home.Y, SPOT_TOP))
		return frame:PointToWorldSpace(Vector3.new(x, y, home.Z))
	end

	-- For a held door (a home's, D-274), whether `player` holds it; nil for the climb's doors.
	local function holds(entry: Entry, player: Player): boolean?
		local holder = entry.unit:GetAttribute(Door.HolderAttribute)
		if type(holder) ~= "number" then
			return nil
		end
		return holder ~= 0 and holder == player.UserId
	end

	--[[
		How `action` by someone whose body is `root`, carrying `tools`, is decided: where the server
		sees them or a moment on (Arrival), the first moment that lets it happen, else the answer
		where it sees them. With `reach`, only moments within it of the button's spot count, and nil
		if none is. Only a body crossing the door line as it lands sees two sides here. `held` is
		`holds`'s answer: a home's door is decided by Door.decideHeld.
	]]
	local function judge(
		entry: Entry,
		action: Door.Action,
		root: BasePart,
		tools: Door.Tools,
		reach: number?,
		held: boolean?
	): Door.Verdict?
		local from = root.Position
		local v = root.AssemblyLinearVelocity
		local first: Door.Verdict? = nil
		local spot: Door.Spot = Door.place(entry.state, action)
		for i = 0, Arrival.Steps do
			local at = from + v * Arrival.ahead(i)
			if not reach or (at - nearest(entry, spot, at)).Magnitude <= reach then
				local side: Door.Side = sideOf(entry, at)
				local verdict: Door.Verdict
				if held ~= nil then
					verdict = Door.decideHeld(entry.state, action, side, tools, held)
				else
					verdict = Door.decide(entry.state, action, side, tools)
				end
				if verdict.ok then
					return verdict
				end
				first = first or verdict
			end
		end
		return first
	end

	-- A press of `action`'s button on `entry` by `player`: checked, then decided, then done.
	local function press(entry: Entry, action: Door.Action, player: Player)
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < REPEAT_SECONDS then
			return
		end
		local l = ladders
		if l and l:crawling(player) then
			return -- up on the tops: these buttons are off your screen there
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local reach = if action == "Lift" then INSIDE_REACH else HALL_REACH
		refresh(entry)
		local verdict = judge(
			entry,
			action,
			root,
			carries(slots, player),
			reach + RANGE_SLACK,
			holds(entry, player)
		)
		if not verdict then
			return
		end
		lastPress[player] = t
		local motion: Motion.Kind? = verdict.motion
		local tap = taps
		local easing = motion == "Close" and tap ~= nil and tap:earns(entry.unit, player)
		if easing then
			motion = "Ease" -- over a sleeper: it hangs a foot up while the tap's bar runs
		end
		if verdict.lock == false and motion then
			-- a home's padlock comes off as its door lifts from inside: off first, or it won't lift
			RollUpDoor.setLocked(entry.unit, false)
		end
		if motion then
			RollUpDoor.play(entry.unit, motion)
		end
		if verdict.lock ~= nil and not (verdict.lock == false and motion) then
			-- the padlock leaves your hand for the door (decide just saw it there, nothing yields);
			-- or the cutters in your hand took one off, and wear (S1-08)
			if RollUpDoor.setLocked(entry.unit, verdict.lock) and slots then
				if verdict.lock then
					slots:spend(player, "Padlock")
				else
					slots:wear(player, "BoltCutters")
				end
			end
		end
		if verdict.refusal then
			local p = entry.buttons[action]
			local refuse = p and entry.refusers[p]
			if refuse then
				refuse(verdict.refusal, player)
			end
		end
		if motion or verdict.lock ~= nil then
			event(entry, action, motion, player)
		end
		refresh(entry)
		if easing and tap then
			tap:begin(entry.unit, player)
		end
	end

	local function add(inst: Instance)
		-- only units in the world: a tagged template in ReplicatedStorage has no door to use
		if not inst:IsA("Model") or entries[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local unit = inst
		local root = unit.PrimaryPart
		if not root then
			return
		end
		local spec = RollUpDoor.spec(unit)
		local frame = RollUpDoor.frame(unit)
		local halfWidth = spec.DoorWidth / 2
		-- the latch's side: wherever the art hangs the padlock (the hall's right, on today's units)
		local latchX = -(halfWidth - LATCH_EDGE)
		local lock = unit:FindFirstChild(LATCH_PART, true)
		if lock and lock:IsA("BasePart") then
			latchX = math.clamp(frame:PointToObjectSpace(lock.Position).X, -halfWidth, halfWidth)
		end
		local across: { [Door.Spot]: number } = { Middle = 0, Low = 0, Latch = latchX, Inside = 0 }
		local spots: { [Door.Spot]: Attachment } = {}
		for _, spot: Door.Spot in Door.Spots do
			local a = Instance.new("Attachment")
			a.Name = `Door{spot}`
			a:SetAttribute(DoorSpot.Attribute, spot)
			if across[spot] ~= 0 then
				a:SetAttribute(DoorSpot.Across, across[spot])
			end
			if DoorSpot.Moves[spot] then
				a:AddTag(DoorSpot.Tag)
			end
			a.Parent = root -- first: WorldCFrame is kept relative to the parent it has
			local out = if spot == "Inside" then INSIDE_IN else -HALL_OUT
			-- facing the hall, as the door does: a screen moving it reads the way out from it
			a.WorldCFrame = frame * CFrame.new(across[spot], DoorSpot.Height[spot], out)
			spots[spot] = a
		end

		local entry: Entry = {
			unit = unit,
			frame = frame,
			halfWidth = halfWidth,
			fullStroke = spec.Rise.Open,
			spots = spots,
			buttons = {},
			refusers = {},
			state = "Closed",
			settles = 0,
			conns = {},
		}
		local function make(button: Button, reach: number)
			local spot: Door.Spot = Door.place("Closed", button.action)
			local p = Prompts.make(spots[spot], {
				actionText = button.text,
				key = button.key,
				pad = button.pad,
				reach = reach,
				hold = button.hold,
			})
			p.Enabled = false
			p:SetAttribute(Doors.ActionAttribute, button.action)
			p:AddTag(Door.ButtonTag)
			if button.action == "Lock" then
				CollectionService:AddTag(p, Tools.LockTag)
			end
			entry.buttons[button.action] = p
			entry.refusers[p] = Prompts.refuser(p)
			table.insert(
				entry.conns,
				p.Triggered:Connect(function(player: Player)
					if Prompts.wrapped(player) then
						return
					end
					press(entry, button.action, player)
				end)
			)
			if button.hold then
				-- answer the moment the hold starts: the wrong thing in hand, no point holding
				table.insert(
					entry.conns,
					p.PromptButtonHoldBegan:Connect(function(player: Player)
						local l = ladders
						if l and l:crawling(player) then
							return
						end
						local character = player.Character
						local body = character and character:FindFirstChild("HumanoidRootPart")
						if not (body and body:IsA("BasePart")) then
							return
						end
						local verdict = judge(
							entry,
							button.action,
							body,
							carries(slots, player),
							nil,
							holds(entry, player)
						)
						if verdict and verdict.refusal then
							entry.refusers[p](verdict.refusal, player)
						end
					end)
				)
			end
		end
		for _, button in HALL_BUTTONS do
			make(button, HALL_REACH)
		end
		make(LIFT_BUTTON, INSIDE_REACH)

		local function moved()
			refresh(entry)
		end
		table.insert(entry.conns, unit:GetAttributeChangedSignal(ATTR_MOTION):Connect(moved))
		table.insert(entry.conns, unit:GetAttributeChangedSignal(ATTR_LOCKED):Connect(moved))
		entries[unit] = entry
		-- every button starts hidden, which is Slamming's set; so the first refresh shows the
		-- door's own unless it really is mid-slam, when hidden is right
		entry.state = "Slamming"
		refresh(entry)
	end

	local function remove(inst: Instance)
		local entry = entries[inst :: Model]
		if not entry then
			return
		end
		entries[inst :: Model] = nil
		moving[entry] = nil
		for _, c in entry.conns do
			c:Disconnect()
		end
		for _, a in entry.spots do
			a:Destroy()
		end
	end

	local system = {
		name = "Doors",
		acted = acted,
		changed = changed,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		ladders = (context.registry:get("ladders") :: any) :: Ladders.Ladders?
		taps = (context.registry:get("taps") :: any) :: Careful? -- any: as above
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(remove)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastPress[player] = nil
			end)
		)
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			add(inst)
		end
	end

	-- Only doors in motion: when one's motion ends, its buttons change (opening becomes open).
	function system.step(_: any, _dt: number)
		if next(moving) == nil then
			return
		end
		local t = now()
		for entry in moving do
			if t >= entry.settles then
				moving[entry] = nil
				refresh(entry)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for unit in entries do
			remove(unit)
		end
		acted:disconnectAll()
		changed:disconnectAll()
	end

	-- The states a building's move works from: a bang only on a door at rest, a burst on any door
	-- down or coming down (a padlocked one RollUpDoor refuses).
	local BANGS: { [Door.State]: true } = { Closed = true, Peeking = true, Locked = true }
	local BURSTS: { [Door.State]: true } =
		{ Closed = true, Peeking = true, Closing = true, Slamming = true }
	local OPENS: { [Door.State]: true } = { Closed = true, Peeking = true }
	-- the game pulling a door down (a home let go, D-274): any door that's up or going up
	local CLOSES: { [Door.State]: true } =
		{ Peeking = true, Opening = true, Open = true, Lifting = true }
	-- the tap's answer (S2-05a) lands only a door still easing down over its sleeper
	local LANDS: { [Door.State]: true } = { Closing = true, Peeking = true }

	function system.move(_: any, unit: Model, kind: Motion.Kind): boolean
		local entry = entries[unit]
		if not entry then
			return false
		end
		refresh(entry)
		local from = if kind == "Bang"
			then BANGS
			elseif kind == "Burst" then BURSTS
			elseif kind == "Open" then OPENS
			elseif kind == "Close" then CLOSES
			elseif kind == "Settle" or kind == "Drop" then LANDS
			else nil
		local easing = Motion.decode(unit:GetAttribute(ATTR_MOTION) :: string?) == "Ease"
		if (kind == "Settle" or kind == "Drop") and not easing then
			return false
		end
		if not (from and from[entry.state]) or RollUpDoor.play(unit, kind) <= 0 then
			return false
		end
		event(entry, nil, kind, nil)
		refresh(entry)
		return true
	end

	function system.lock(_: any, unit: Model, locked: boolean, player: Player?): boolean
		local entry = entries[unit]
		if not entry then
			return RollUpDoor.setLocked(unit, locked)
		end
		refresh(entry)
		local action: Door.Action = if locked then "Lock" else "Cut"
		local took: boolean
		if player then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not (root and root:IsA("BasePart")) then
				return false
			end
			local verdict = Door.decide(
				entry.state,
				action,
				sideOf(entry, root.Position),
				carries(slots, player)
			)
			took = verdict.ok and RollUpDoor.setLocked(unit, locked)
			if took and slots then
				if locked then
					slots:spend(player, "Padlock")
				else
					slots:wear(player, "BoltCutters") -- cut off: the cutters wear (S1-08)
				end
			end
		else
			took = (entry.state == "Locked") ~= locked and RollUpDoor.setLocked(unit, locked)
		end
		if took then
			event(entry, action, nil, player)
		end
		refresh(entry)
		return took
	end

	function system.stateOf(_: any, unit: Model): Door.State
		local entry = entries[unit]
		if entry then
			refresh(entry)
			return entry.state
		end
		return "Closed"
	end

	return system
end

return Doors
