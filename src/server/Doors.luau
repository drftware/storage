--!strict
--[[
	Doors: every storage unit's roll-up door as the GDD's state machine (the pure `Door`), a system
	on the server's Host clock. It finds each unit in the world by its tag and gives it buttons:

	- On the door's hall side at eye height, the buttons its state allows and nothing else: Peek,
	  Open and Lock on a shut door, Close and Slam on an open one, Open and Cut on a padlocked one.
	  Lock shows only on the screen of someone with a padlock in hand (ToolView hides it). Each
	  action keeps one place on screen (`Door.Slots`), side by side, so a phone thumb can pick one
	  and a double tap can't fire something else.
	- Just inside the door, Lift, only while the door is down: someone shut in can always get out
	  (unless it's padlocked: then it rattles).

	Every press is checked before the door moves: the player must be within reach of the button (a
	little slack for lag), on the right side of the door (Lift only from inside), holding the tool it
	needs in their hand (`Slots`: the cutters to Cut, a padlock to Lock, which then leaves their
	slots for good), and not pressing faster than a hand can. A refusal the player can see answers at
	the door: a padlocked door rattles against its bolt, loud, and the button says "Padlocked",
	"Need bolt cutters" or "Hold the cutters" for a moment.

	Every door event fires `acted` with how far it's heard (DoorSound), so keepers (L-06) hear
	exactly what players hear, and every change of a door's state fires `changed`, so the keepers'
	map knows which doorways are open. Only doors in motion are stepped, to refresh their buttons
	when the motion ends.

	Each button carries its action as the attribute `DoorAction`, so a screen can find Lock and Cut.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

export type DoorEvent = {
	unit: Model,
	action: Door.Action,
	motion: Motion.Kind?, -- what the door did; a padlocked door tried rattles
	player: Player?, -- nil when the game itself did it
	at: Vector3, -- the middle of the doorway, on the floor
	reach: number, -- studs it's heard to (DoorSound): a keeper within it hears the door
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
}

-- Where the buttons sit. In first person a button shows only while its point is on screen, so the
-- points sit on the door at about eye height: pressed against the door with a level gaze, they
-- still show. A point inside the door's invisible collider loses its sight line and hides, so both
-- sit just outside it.
local HALL_OUT = RollUpDoor.ColliderDepth / 2 + 0.1 -- the hall side's buttons, just off the door
local INSIDE_IN = RollUpDoor.ColliderDepth / 2 + 0.1 -- Lift, just behind it: a shut door hides it
local HEIGHT = 4 -- just under a standing player's eyes (about 4.4)
local HALL_REACH = 8 -- close enough to touch the door, not the neighbour's
local INSIDE_REACH = 5 -- only someone shut inside should see Lift
local SLOT_PIXELS = 150 -- between neighbouring buttons' centres: a button is 138 wide

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
	name: string, -- "Unit 304"
	frame: CFrame, -- the door's frame: +Z into the unit
	halfWidth: number,
	fullStroke: number,
	hall: Attachment,
	inside: Attachment,
	buttons: { [Door.Action]: ProximityPrompt },
	refusers: { [ProximityPrompt]: (string) -> () },
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

	local function nameOf(entry: Entry): string
		return if entry.state == "Locked" then "Padlocked" else entry.name
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
		for _, point: Door.Side in Door.Sides do
			local offered = Door.offers(state, point)
			for action, p in entry.buttons do
				if (action == "Lift") == (point == "Inside") then
					p.Enabled = table.find(offered, action) ~= nil
				end
			end
		end
		local name = nameOf(entry)
		for _, p in entry.buttons do
			p.ObjectText = name
		end
		changed:fire({ unit = unit, state = state })
	end

	local function event(entry: Entry, action: Door.Action, motion: Motion.Kind?, player: Player?)
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

	-- A press of `action`'s button on `entry` by `player`: checked, then decided, then done.
	local function press(entry: Entry, action: Door.Action, player: Player)
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < REPEAT_SECONDS then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local point = if action == "Lift" then entry.inside else entry.hall
		local reach = if action == "Lift" then INSIDE_REACH else HALL_REACH
		if (root.Position - point.WorldPosition).Magnitude > reach + RANGE_SLACK then
			return
		end
		lastPress[player] = t
		refresh(entry)
		local verdict =
			Door.decide(entry.state, action, sideOf(entry, root.Position), carries(slots, player))
		if verdict.motion then
			RollUpDoor.play(entry.unit, verdict.motion)
		end
		if verdict.lock ~= nil then
			-- the padlock leaves your hand for the door (decide just saw it there, nothing yields)
			if RollUpDoor.setLocked(entry.unit, verdict.lock) and verdict.lock and slots then
				slots:spend(player, "Padlock")
			end
		end
		if verdict.refusal then
			local p = entry.buttons[action]
			local refuse = p and entry.refusers[p]
			if refuse then
				refuse(verdict.refusal)
			end
		end
		if verdict.motion or verdict.lock ~= nil then
			event(entry, action, verdict.motion, player)
		end
		refresh(entry)
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
		local number = string.match(unit.Name, "^Unit(.+)$") or unit.Name
		local hall = Instance.new("Attachment")
		hall.Name = "DoorButtons"
		hall.Parent = root
		hall.WorldCFrame = frame * CFrame.new(0, HEIGHT, -HALL_OUT)
		local inside = Instance.new("Attachment")
		inside.Name = "LiftButton"
		inside.Parent = root
		inside.WorldCFrame = frame * CFrame.new(0, HEIGHT, INSIDE_IN)

		local entry: Entry = {
			unit = unit,
			name = `Unit {number}`,
			frame = frame,
			halfWidth = spec.DoorWidth / 2,
			fullStroke = spec.Rise.Open,
			hall = hall,
			inside = inside,
			buttons = {},
			refusers = {},
			state = "Closed",
			settles = 0,
			conns = {},
		}
		local function make(button: Button, at: Attachment, reach: number)
			local p = Prompts.make(at, {
				objectText = entry.name,
				actionText = button.text,
				key = button.key,
				pad = button.pad,
				reach = reach,
				hold = button.hold,
			})
			p.UIOffset = Vector2.new(Door.Slots[button.action] * SLOT_PIXELS, 0)
			p.Enabled = false
			p:SetAttribute(Doors.ActionAttribute, button.action)
			if button.action == "Lock" then
				CollectionService:AddTag(p, Tools.LockTag)
			end
			entry.buttons[button.action] = p
			entry.refusers[p] = Prompts.refuser(p, function()
				return nameOf(entry)
			end)
			table.insert(
				entry.conns,
				p.Triggered:Connect(function(player: Player)
					press(entry, button.action, player)
				end)
			)
			if button.hold then
				-- answer the moment the hold starts: the wrong thing in hand, no point holding
				table.insert(
					entry.conns,
					p.PromptButtonHoldBegan:Connect(function(player: Player)
						local character = player.Character
						local body = character and character:FindFirstChild("HumanoidRootPart")
						if not (body and body:IsA("BasePart")) then
							return
						end
						local verdict = Door.decide(
							entry.state,
							button.action,
							sideOf(entry, body.Position),
							carries(slots, player)
						)
						if verdict.refusal then
							entry.refusers[p](verdict.refusal)
						end
					end)
				)
			end
		end
		for _, button in HALL_BUTTONS do
			make(button, hall, HALL_REACH)
		end
		make(LIFT_BUTTON, inside, INSIDE_REACH)

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
		entry.hall:Destroy()
		entry.inside:Destroy()
	end

	local system = {
		name = "Doors",
		acted = acted,
		changed = changed,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
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
			if took and locked and slots then
				slots:spend(player, "Padlock")
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
