--!strict
--[[
	Everyone's tool slots (L-11b, D-048; three since L-20a), as Lethal Company's: the server owns
	every tool, where it is and who carries it. A tool lies on a floor with a "Pick up" prompt until
	someone takes it; carried, it's in one of their slots (`Tools.Carry`), and the one in their hand
	is welded in their left hand for everyone to see (the torch has the right). They switch slots,
	pocket the tool on their slot or bring it back up (out of sight, still theirs), drop what's in
	their hand at their feet, or hand it to a friend within reach who has room. Dying or leaving
	drops everything where you stood.

	Every screen reads the slots from attributes on each Player (`ToolSlot1` to `ToolSlot3`: the
	catalog key or ""; `ToolHand`: the slot your hand is on; `ToolPocketed`: its tool put away).
	Four remotes in (a stand-in for Brix ENG-09), each checked for type, then range (a living
	character, reach, room), then rate (`Carry.allow`): ToolSwitch takes a slot, ToolPocket a
	boolean, ToolDrop nothing, ToolGive a Player. ToolNotice tells one screen a short line ("Bolt
	cutters from Sam").

	A big tool (the ladder) rides on your left shoulder for everyone to see, takes both hands (no
	switching slots or picking up while it's in your hand, as Lethal Company's two-handed items) and
	slows your walk (`Catalog` row's `shoulder`, `bothHands`, `walkSpeed`).

	`Doors` reads `carried` to know what's in your hand (the cutters to Cut, a padlock to Lock), and
	`spend`s the padlock that goes on a door: it leaves your slots for good.

	A tool whose row has a `verb` (the air horn's Blow) is used where you stand: ToolUse takes
	nothing, checked for a living character with such a tool in hand, then its own rate (so using
	never spends the hand's), and fires `used` for that tool's system (`Horns`) to decide the rest.

	A find (S1-05, GDD "Finds": a catalog row with `find`) is carried the same way: `Deals` lays it
	standing in its unit with a "Take" prompt, one tap puts it in a slot and in your hand, and it's
	dropped, handed over and dropped where you're caught as a tool is. A tool's or a find's own
	sound answers each take and drop. As the gate shuts with you aboard, your finds are kept for
	good (`keep`, S1-06): out of your slots, the one in your hand gone in a glint.

	Tools wear out (S1-08, GDD "Tools wear out", as Minecraft's do): each tool keeps its own uses
	left (`Wear`), so a dropped or handed-over one keeps its wear, and every screen reads them from
	`ToolUses1` to `ToolUses3`. The system that uses one (`Doors`' Cut, `Saws`, `Horns`) `wear`s it;
	the use that spends the last breaks it a beat later (its row's `wear.late`): out of your slots,
	it jolts out of your hand with its own snap and a burst of its bits, tumbles to the floor with
	its clank, lies there a moment and fades. Your screen is told (ToolBroke) to break it in your
	view; until it goes, your hand can't move and the tool can't be used.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Carry = Tools.Carry
local Catalog = Tools.Catalog
local Wear = Tools.Wear

local HAND_SOUND_REACH = 24 -- a hand closing on a tool, heard close by
local FALL = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- A find the Packrat sets on its pile (S2-06b2): eased from its hands to the floor, unhurried
local PUT_DOWN = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DROP_AHEAD = 2.2 -- studs in front of your middle where a dropped tool lands
local REACH_SLACK = 2 -- studs the server allows past a prompt's reach (lag, a long arm)
-- A kept find's glint as it goes from your hand, for everyone near: the coins' sparkle, warm gold.
local GLINT_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local GLINT_BURST = 0.18 -- seconds the glint throws sparks: a short burst, then gone
-- A tool breaking (S1-08): it jumps out of your hand (studs a second up, and ahead of you) with a
-- tumble (radians a second at most), its bits flying (how many, how big in studs, how fast), heard
-- as far as a cut padlock's snap; it lies on the floor for `BROKEN_LIES` seconds, then fades.
local BREAK_JUMP = 8
local BREAK_AHEAD = 4
local BREAK_SPIN = 14
local BITS = 10
local BIT_SIZE = { 0.1, 0.26 }
local BIT_SPEED = { 7, 15 }
local BREAK_REACH = 40
local BROKEN_LIES = 2.5
local BROKEN_FADE = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type Change = {
	player: Player,
	kind: "PickUp" | "Drop" | "Give" | "Switch" | "Pocket" | "Spend" | "Place" | "Keep" | "Break",
}

-- A press of ToolUse that passed: who, the tool's catalog key, and its model in their hand.
export type Use = { player: Player, key: string, model: Model }
-- A dropped tool hitting the floor: its clank, heard `reach` studs off (Carry.DropHeard).
export type Landed = { key: string, at: Vector3, reach: number }

export type Slots = Brix.System & {
	-- Fires as anyone's slots change, for whoever cares.
	changed: Brix.Signal<Change>,
	-- Fires as a dropped tool lands with its clank, wherever it fell: keepers hear it (L-15).
	landed: Brix.Signal<Landed>,
	-- Fires as someone uses the tool in their hand (its row's `verb`), checked and rate-limited.
	used: Brix.Signal<Use>,
	-- Fires as the finds lying loose change (S2-06b2): one laid, dropped, picked up, cleared,
	-- lifted by a monster or laid on its pile. The Packrat is told (`Keepers`).
	loose: Brix.Signal<nil>,
	-- Calls `each` with every find lying loose on a floor: its number and the floor point under
	-- its middle (the world's). Allocates nothing.
	finds: (self: any, each: (n: number, at: Vector3) -> ()) -> (),
	-- A monster's hands close on find `n` lying loose (the Packrat's take, S2-06b2): its prompt
	-- goes and it's welded to `part`, its middle where it lay, in `holder` (the monster's body).
	-- The weld, or nil if it no longer lies loose.
	lift: (self: any, n: number, part: BasePart, holder: Instance) -> Weld?,
	-- Lays lifted find `n` on the floor at `at`, turned `yaw` degrees, quietly (the Packrat's
	-- pile): "Take" again, as any find. It eases there from `from` (its middle in the world, where
	-- screens show it in the hands, S2-06b2b), or from where the server holds it.
	putDown: (self: any, n: number, at: Vector3, yaw: number, from: CFrame?) -> (),
	-- Lays a new tool of catalog key `key` on the floor at `at` (a floor point), turned `yaw`
	-- degrees. Returns its id, or nil if the place has no template.
	lay: (self: any, key: string, at: Vector3, yaw: number) -> string?,
	-- Takes away every tool lying on a floor where `inside` says (a floor being cleared, L-08b);
	-- carried and placed ones stay. Returns how many went.
	clear: (self: any, inside: (at: Vector3) -> boolean) -> number,
	-- The catalog keys `player` carries, slot by slot ("" for empty), and the slot in hand (0 while
	-- its tool is pocketed).
	carried: (self: any, player: Player) -> ({ string }, number),
	-- Uses up what's in `player`'s hand if it's catalog key `key` (a padlock hung on a door): out
	-- of their slots and gone. Whether it was.
	spend: (self: any, player: Player, key: string) -> boolean,
	-- Spends one use of what's in `player`'s hand if it's catalog key `key` and wears out (S1-08:
	-- a padlock cut, a hole sawn, a blast). The use that spends its last breaks it a beat later
	-- (its row's `wear.late`). The uses left (0: it's breaking), or nil if their hand had no such
	-- tool or it never wears out.
	wear: (self: any, player: Player, key: string) -> number?,
	-- Takes what's in `player`'s hand out of their slots if it's catalog key `key`, to stand in the
	-- world (the ladder leaned on a front): Slots keeps it, carried by nobody and lying nowhere, its
	-- body anchored where it was, for the caller to place. Its id and model, or nil.
	place: (self: any, player: Player, key: string) -> (string?, Model?),
	-- Puts placed tool `id` back in `player`'s hand, as a pick-up (their hands must be free of a
	-- big tool and have room). Nil if it did, else the refusal to show ("" to refuse silently).
	handBack: (self: any, player: Player, id: string) -> string?,
	-- A new tool of catalog key `key` straight into a free slot of `player`'s and their hand (bought
	-- at the car's machine, S1-10c2), with its pick-up sound. False, and nothing made, if they have
	-- no room, a big tool in their hands, no living character, or the place lacks its art.
	give: (self: any, player: Player, key: string, quiet: boolean?) -> boolean,
	-- Lays placed tool `id` on the floor at `at`, turned `yaw` degrees (its front gone from under it).
	lower: (self: any, id: string, at: Vector3, yaw: number) -> (),
	-- Drops everything `player` carries where they stand, as dying does (caught by a keeper, L-07a).
	dropAll: (self: any, player: Player) -> (),
	-- Takes every find out of `player`'s slots for good (the gate shut with them aboard, S1-06):
	-- each goes from their hand with a glint everyone near sees, and their tools stay. The kept
	-- finds' catalog keys, slot order.
	keep: (self: any, player: Player) -> { string },
}

type Tool = {
	id: string,
	n: number, -- its number, as a keeper's brain knows a find (`Keeper.Finds`, S2-06b2)
	key: string,
	model: Model,
	body: BasePart,
	prompt: ProximityPrompt?,
	refuse: ((string, Player) -> ())?,
	owner: Player?,
	weld: Weld?,
	placed: boolean?, -- standing in the world (`place`), not in a hand or on a floor
	uses: number?, -- uses left before it breaks (S1-08); nil: it never wears out
}

type Hand = {
	carry: Tools.CarryState,
	last: number?,
	burst: number,
	usedLast: number?, -- ToolUse's own rate, as `last` and `burst` are the hand's
	usedBurst: number,
}

-- The tool's pivot for lying flat on a floor with its middle at `at`, turned `yaw` degrees: its
-- lowest point on the floor. By its middle, not its grip, so a long tool dropped by a wall lies
-- along it rather than through it.
local function resting(key: string, at: Vector3, yaw: number): CFrame
	local body = Tools.bounds(key)
	local lift = body.Size.Y / 2 - body.Centre.Y
	return CFrame.new(at + Vector3.new(0, lift, 0))
		* CFrame.Angles(0, math.rad(yaw), 0)
		* CFrame.new(-body.Centre.X, 0, -body.Centre.Z)
end

-- The left hand and where its grip is (the attachment's place only: rigs turn it differently).
local function handOf(character: Model): (BasePart?, CFrame)
	local hand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	if not (hand and hand:IsA("BasePart")) then
		return nil, CFrame.identity
	end
	local grip = hand:FindFirstChild("LeftGripAttachment")
	local at = if grip and grip:IsA("Attachment")
		then grip.Position
		else Vector3.new(0, -hand.Size.Y / 2, 0)
	return hand, CFrame.new(at)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and humanoid and humanoid.Health > 0) then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function now(): number
	return os.clock()
end

-- A burst of gold sparks at `at`, gone in a second: a kept find leaving a hand. An emitter switched
-- on and off rather than `Emit`, so every screen sees it.
local function glint(at: Vector3)
	local spot = Instance.new("Attachment")
	spot.Name = "KeptGlint"
	spot.WorldPosition = at
	local p = Instance.new("ParticleEmitter")
	p.Texture = GLINT_TEXTURE
	p.Rate = 70
	p.Lifetime = NumberRange.new(0.35, 0.6)
	p.Speed = NumberRange.new(2, 5)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Drag = 4
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.4, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Rotation = NumberRange.new(0, 90)
	p.RotSpeed = NumberRange.new(-120, 120)
	p.Color = ColorSequence.new(Color3.fromRGB(255, 226, 150))
	p.LightEmission = 1
	p.LightInfluence = 0.3
	p.Brightness = 2.5
	p.Parent = spot
	spot.Parent = Workspace.Terrain
	task.delay(GLINT_BURST, function()
		p.Enabled = false
	end)
	task.delay(1.2, function()
		spot:Destroy()
	end)
end

local Slots = {}

function Slots.new(): Slots
	local tools: { [string]: Tool } = {}
	local hands: { [Player]: Hand } = {}
	local connections: { RBXScriptConnection } = {}
	local remotes: { Instance } = {}
	local changed = Brix.Signal.new() :: Brix.Signal<Change>
	local used = Brix.Signal.new() :: Brix.Signal<Use>
	local landed = Brix.Signal.new() :: Brix.Signal<Landed>
	local loose = Brix.Signal.new() :: Brix.Signal<nil>
	local lying: Folder? = nil
	-- where each lying tool's middle stands on the floor (its id's), for `finds`
	local grounds: { [string]: Vector3 } = {}
	local notice: RemoteEvent? = nil
	local broke: RemoteEvent? = nil
	local nextId = 0

	local function handOfPlayer(player: Player): Hand
		local h = hands[player]
		if not h then
			h = { carry = Carry.new(), last = nil, burst = Carry.Burst, usedBurst = Carry.Burst }
			hands[player] = h
		end
		return h
	end

	local function tell(player: Player, text: string)
		if notice then
			notice:FireClient(player, text)
		end
	end

	-- The row of the tool in `h`'s hand if it takes both hands (the ladder), else nil.
	local function bothHands(h: Hand): Tools.Row?
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		return if row and row.bothHands then row else nil
	end

	-- `player`'s walk for what's in their hand: a big tool's pace, else the place's own.
	local function pace(player: Player, h: Hand)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		local speed = if row and row.walkSpeed
			then row.walkSpeed
			else StarterPlayer.CharacterWalkSpeed
		if humanoid.WalkSpeed ~= speed then
			humanoid.WalkSpeed = speed
		end
	end

	-- Writes `player`'s slots to their attributes, for every screen, and sets their walk to match.
	local function publish(player: Player)
		local h = handOfPlayer(player)
		pace(player, h)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			local key = if t then t.key else ""
			if player:GetAttribute(Tools.slotAttribute(i)) ~= key then
				player:SetAttribute(Tools.slotAttribute(i), key)
			end
			local uses = if t and t.uses then t.uses else 0
			if player:GetAttribute(Wear.slotAttribute(i)) ~= uses then
				player:SetAttribute(Wear.slotAttribute(i), uses)
			end
		end
		if player:GetAttribute(Tools.HandAttribute) ~= h.carry.active then
			player:SetAttribute(Tools.HandAttribute, h.carry.active)
		end
		if player:GetAttribute(Tools.PocketedAttribute) ~= h.carry.pocketed then
			player:SetAttribute(Tools.PocketedAttribute, h.carry.pocketed)
		end
	end

	-- Takes a tool out of any hand: unwelded, out of the world.
	local function stow(t: Tool)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.body.Anchored = true
		t.model.Parent = nil
	end

	-- Puts what `player` has in hand into their left hand, and stows the rest.
	local function dress(player: Player)
		local h = handOfPlayer(player)
		local held = Carry.held(h.carry)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			if t and id ~= held then
				stow(t)
			end
		end
		local t = if held then tools[held] else nil
		if not t then
			return
		end
		local character = player.Character
		if not character then
			stow(t)
			return
		end
		local row = Catalog[t.key]
		local hand, grip = handOf(character)
		-- a big tool rides on the shoulder: welded to the torso, it doesn't swing with your arm
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		local shoulder = row.shoulder
		if shoulder and torso and torso:IsA("BasePart") then
			hand, grip = torso, CFrame.new(shoulder[1], shoulder[2], shoulder[3])
		end
		if not hand then
			stow(t)
			return
		end
		if t.weld and t.weld.Part0 == hand then
			return
		end
		if t.weld then
			t.weld:Destroy()
		end
		local turn = row.inHand
		local inHand = grip * CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
		t.model.Name = Tools.HeldName
		t.model:PivotTo(hand.CFrame * inHand)
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = t.body
		weld.C0 = inHand
		weld.C1 = t.body.PivotOffset
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Parent = character
	end

	local pickUp: (Tool, Player) -> ()

	-- A prompt on a lying tool: "Pick up" and its name.
	local function offer(t: Tool)
		local row = Catalog[t.key]
		local at = Instance.new("Attachment")
		at.Name = "Prompt"
		at.Position = Vector3.new(0, 0.3, 0) -- just above its middle
		at.Parent = t.body
		local p = Prompts.make(at, {
			objectText = row.name,
			actionText = if row.find then "Take" else "Pick up",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Carry.PickReach,
		})
		p.RequiresLineOfSight = false -- a tool on the floor is low: boxes mustn't hide its prompt
		if row.find then
			-- a find stands taller than a tool lies: the prompt by its top, where your eye is drawn
			at.Position = Vector3.new(0, t.body.Size.Y * 0.3, 0)
		end
		t.prompt = p
		t.refuse = Prompts.refuser(p)
		p.Triggered:Connect(function(player: Player)
			pickUp(t, player)
		end)
	end

	local function unoffer(t: Tool)
		if t.prompt then
			local at = t.prompt.Parent
			t.prompt:Destroy()
			if at and at:IsA("Attachment") then
				at:Destroy()
			end
		end
		t.prompt = nil
		t.refuse = nil
	end

	-- Lays `t` on the floor at `pose`; falls there from `from` if given, clanking as it lands.
	local function layDown(t: Tool, pose: CFrame, from: CFrame?)
		t.owner = nil
		stow(t)
		t.model.Name = t.key
		t.model:PivotTo(from or pose)
		t.model.Parent = lying
		local box = Tools.bounds(t.key)
		grounds[t.id] = (pose * CFrame.new(
			box.Centre.X,
			box.Centre.Y - box.Size.Y / 2,
			box.Centre.Z
		)).Position
		if Catalog[t.key].find then
			loose:fire(nil)
		end
		if from then
			local goal = pose * t.body.PivotOffset:Inverse()
			local tween = TweenService:Create(t.body, FALL, { CFrame = goal })
			tween.Completed:Once(function()
				if t.owner == nil and t.model.Parent == lying then
					Tools.play(Catalog[t.key].drop, t.body, Carry.DropHeard)
					landed:fire({ key = t.key, at = t.body.Position, reach = Carry.DropHeard })
				end
			end)
			tween:Play()
		end
		offer(t)
	end

	-- Where a tool dropped by someone at `root` lands: a floor point just ahead of them, found by a
	-- ray down that sees only the building (no players, no tools).
	local function dropPoint(root: BasePart): Vector3
		local ahead = root.CFrame * CFrame.new(0, 0, -DROP_AHEAD)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = {}
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		if lying then
			table.insert(skip, lying)
		end
		params.FilterDescendantsInstances = skip
		-- from your middle, so a wall in front stops the ray short of the far side
		local start = root.Position
		local toward = ahead.Position - start
		local wall = Workspace:Raycast(start, toward, params)
		local over = if wall then wall.Position - toward.Unit * 0.6 else ahead.Position
		local hit = Workspace:Raycast(over, Vector3.new(0, -8, 0), params)
		return if hit then hit.Position else root.Position - Vector3.new(0, 3, 0)
	end

	-- Drops every tool `player` carries where they are (dying, leaving).
	local function dropAll(player: Player, root: BasePart?)
		local h = hands[player]
		if not h then
			return
		end
		local ids = Carry.clear(h.carry)
		for k, id in ids do
			local t = tools[id]
			if t then
				local at = if root then dropPoint(root) else Vector3.zero
				local fromCF = if root then root.CFrame else nil
				layDown(
					t,
					resting(t.key, at + Vector3.new(0.4 * (k - 1), 0, 0), math.random(0, 359)),
					fromCF
				)
			end
		end
		if player.Parent then
			publish(player)
		end
	end

	-- A worn-out tool breaking (S1-08), wherever it is now: out of its owner's slots, it jumps out
	-- of the hand with its own snap and a burst of its bits, tumbles to the floor and clanks as it
	-- lands (keepers hear it, as a dropped tool), lies there a moment, then fades. Never silent,
	-- never just gone.
	local function shatter(t: Tool)
		if tools[t.id] ~= t then
			return -- gone already: kept, or the floor it lay on cleared
		end
		tools[t.id] = nil
		local row = Catalog[t.key]
		local w = row.wear
		local owner = t.owner
		local inHand = t.weld ~= nil
		local character = if owner then owner.Character else nil
		local root = if owner then rootOf(owner) else nil
		-- where it breaks: in the hand it's welded to, at its owner's hand if it was put away, or
		-- where it lies
		local pose = t.body.CFrame
		if owner and not inHand and t.model.Parent == nil then
			local hand = if character then handOf(character) else nil
			pose = if hand then hand.CFrame else if root then root.CFrame else pose
		end
		if owner then
			local h = hands[owner]
			if h then
				Carry.remove(h.carry, t.id)
			end
		end
		unoffer(t)
		stow(t)
		t.owner = nil
		local model, body = t.model, t.body
		model.Name = "Broken"
		body.CFrame = pose
		body.CanCollide = true
		body.CanQuery = false
		body.CanTouch = false
		model.Parent = Workspace
		body.Anchored = false
		local ahead = if root then root.CFrame.LookVector else Vector3.zero
		local function spin(): number
			return (math.random() * 2 - 1) * BREAK_SPIN
		end
		body.AssemblyLinearVelocity = ahead * BREAK_AHEAD + Vector3.new(0, BREAK_JUMP, 0)
		body.AssemblyAngularVelocity = Vector3.new(spin(), spin(), spin())
		-- the server's to move, so every screen sees the same tumble
		pcall(function() -- pcall: refused if the engine has it anchored to something still
			body:SetNetworkOwner(nil)
		end)
		local at = body.Position
		if w then
			Tools.play(w.snap, body, BREAK_REACH)
			for i = 1, if #w.bits > 0 then BITS else 0 do
				local c = w.bits[(i - 1) % #w.bits + 1]
				local function between(r: { number }): number
					return r[1] + math.random() * (r[2] - r[1])
				end
				local bit = Instance.new("Part")
				bit.Name = "Bit"
				bit.Size =
					Vector3.new(between(BIT_SIZE), between(BIT_SIZE) * 0.5, between(BIT_SIZE))
				bit.Color = Color3.fromRGB(c[1], c[2], c[3])
				bit.Material = Enum.Material.Metal
				bit.CastShadow = false
				bit.CanQuery = false
				bit.CanTouch = false
				bit.CFrame = CFrame.new(at)
					* CFrame.Angles(
						math.random() * 6.28,
						math.random() * 6.28,
						math.random() * 6.28
					)
				local dir = Vector3.new(
					math.random() * 2 - 1,
					math.random() * 0.8 + 0.2,
					math.random() * 2 - 1
				)
				bit.AssemblyLinearVelocity = dir.Unit * between(BIT_SPEED)
				bit.AssemblyAngularVelocity = Vector3.new(spin(), spin(), spin()) * 2
				bit.Parent = model
				pcall(function() -- pcall: as the tool's own
					bit:SetNetworkOwner(nil)
				end)
			end
		end
		-- its clank as it lands: the fall from here to the floor under it, at this place's gravity
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = { model }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		local floor = Workspace:Raycast(at, Vector3.new(0, -20, 0), params)
		local drop = if floor then math.max(0, at.Y - floor.Position.Y) else 3
		local g = math.max(1, Workspace.Gravity)
		local fall = (BREAK_JUMP + math.sqrt(BREAK_JUMP * BREAK_JUMP + 2 * g * drop)) / g
		task.delay(fall, function()
			if model.Parent then
				Tools.play(row.drop, body, Carry.DropHeard)
				landed:fire({ key = t.key, at = body.Position, reach = Carry.DropHeard })
			end
		end)
		task.delay(BROKEN_LIES, function()
			if not model.Parent then
				return
			end
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					TweenService:Create(part, BROKEN_FADE, { Transparency = 1 }):Play()
				end
			end
			task.delay(BROKEN_FADE.Time + 0.1, function()
				model:Destroy()
			end)
		end)
		if owner and owner.Parent then
			if inHand and broke then
				broke:FireClient(owner, t.key)
			end
			dress(owner)
			publish(owner)
			changed:fire({ player = owner, kind = "Break" })
		end
	end

	-- Whether `player`'s hand may move now (the rate check); spends one if so.
	local function allowed(h: Hand): boolean
		-- a tool breaking in your hand (its last use spent): the hand holds it till it goes
		local held = Carry.held(h.carry)
		local tool = if held then tools[held] else nil
		if tool and not Wear.usable(tool.uses) then
			return false
		end
		local t = now()
		local may, left = Carry.allow(h.last, h.burst, t)
		if not may then
			return false
		end
		h.last, h.burst = t, left
		return true
	end

	pickUp = function(t: Tool, player: Player)
		-- range: a living player near a tool still on the floor
		local root = rootOf(player)
		if not root or t.owner ~= nil or t.model.Parent ~= lying then
			return
		end
		if player:GetAttribute(Kept.Attribute) == true then
			return -- wrapped: no hands to pick anything up with (L-07a)
		end
		if (root.Position - t.body.Position).Magnitude > Carry.PickReach + REACH_SLACK + 2 then
			return
		end
		-- a shut door between you and it: your screen hid its prompt (BehindDoors)
		for _, unit in CollectionService:GetTagged(StorageUnit.UnitKit.Tag) do
			if
				unit:IsA("Model")
				and unit:IsDescendantOf(Workspace)
				and unit:FindFirstChild("DoorOrigin", true)
				and StorageUnit.RollUpDoor.keepsApart(unit, root.Position, t.body.Position)
			then
				return
			end
		end
		local h = handOfPlayer(player)
		local big = bothHands(h)
		if big then
			if t.refuse then
				t.refuse(`Drop the {string.lower(big.name)} first`, player)
			end
			return
		end
		if Carry.room(h.carry) == nil then
			if t.refuse then
				t.refuse("Hands full", player)
			end
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		Carry.take(h.carry, t.id)
		unoffer(t)
		t.owner = player
		grounds[t.id] = nil
		dress(player)
		publish(player)
		local character = player.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or root, HAND_SOUND_REACH)
		changed:fire({ player = player, kind = "PickUp" })
		if Catalog[t.key].find then
			loose:fire(nil)
		end
	end

	local function onSwitch(player: Player, slot: unknown)
		-- type: a whole slot number
		local s = Carry.slot(slot)
		if not s then
			return
		end
		-- range: a living character
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		-- rate
		if not allowed(h) then
			publish(player)
			return
		end
		-- both hands on a big tool: no switching away from it
		local big = bothHands(h)
		if big and s ~= h.carry.active then
			tell(player, `Drop the {string.lower(big.name)} first`)
			publish(player)
			return
		end
		if Carry.select(h.carry, s) then
			dress(player)
			changed:fire({ player = player, kind = "Switch" })
		end
		publish(player)
	end

	-- ToolPocket: `down` true puts the tool on your slot away, false brings it back up.
	local function onPocket(player: Player, down: unknown)
		-- type: a boolean
		if type(down) ~= "boolean" then
			return
		end
		-- range: a living character
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		-- rate
		if not allowed(h) then
			publish(player)
			return
		end
		-- both hands on a big tool: it rides on your shoulder, it can't be put away (your screen
		-- answers this press itself)
		if down and bothHands(h) then
			publish(player)
			return
		end
		if Carry.pocket(h.carry, down) then
			dress(player)
			changed:fire({ player = player, kind = "Pocket" })
		end
		publish(player)
	end

	-- ToolUse: nothing to check for type (it takes nothing); range: a living character with a
	-- tool in hand that has a verb; then its own rate.
	local function onUse(player: Player)
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		if not (t and row and row.verb and Wear.usable(t.uses)) then
			return
		end
		local at = now()
		local may, left = Carry.allow(h.usedLast, h.usedBurst, at)
		if not may then
			return
		end
		h.usedLast, h.usedBurst = at, left
		used:fire({ player = player, key = t.key, model = t.model })
	end

	local function onDrop(player: Player)
		-- range: a living character with something in hand
		local root = rootOf(player)
		if not root then
			return
		end
		local h = handOfPlayer(player)
		if Carry.held(h.carry) == nil then
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		local id = Carry.release(h.carry) :: string
		local t = tools[id]
		publish(player)
		if not t then
			return
		end
		local from = t.body.CFrame * t.body.PivotOffset
		local _, facing = root.CFrame:ToOrientation()
		-- crosswise in front of you, as a dropped tool lands, a little askew
		local yaw = math.deg(facing) + 90 + math.random(-25, 25)
		layDown(t, resting(t.key, dropPoint(root), yaw), from)
		changed:fire({ player = player, kind = "Drop" })
	end

	local function onGive(player: Player, target: unknown)
		-- type: a player in this server, not you
		if typeof(target) ~= "Instance" or not (target :: Instance):IsA("Player") then
			return
		end
		local friend = target :: Player
		if friend == player or friend.Parent ~= Players then
			return
		end
		if
			player:GetAttribute(Kept.Attribute) == true
			or friend:GetAttribute(Kept.Attribute) == true
		then
			return -- either of you wrapped (L-07a)
		end
		-- range: both alive, within reach, something in your hand, room in theirs
		local root, theirs = rootOf(player), rootOf(friend)
		if not (root and theirs) then
			return
		end
		if (root.Position - theirs.Position).Magnitude > Carry.GiveReach + REACH_SLACK then
			return
		end
		local h, them = handOfPlayer(player), handOfPlayer(friend)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (id and t) then
			return
		end
		if Carry.room(them.carry) == nil or bothHands(them) then
			tell(player, "Their hands are full")
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		Carry.release(h.carry)
		Carry.take(them.carry, id)
		t.owner = friend
		stow(t)
		dress(player)
		dress(friend)
		publish(player)
		publish(friend)
		local character = friend.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or theirs, HAND_SOUND_REACH)
		tell(friend, `{Catalog[t.key].name} from {player.DisplayName}`)
		changed:fire({ player = player, kind = "Give" })
	end

	local function addPlayer(player: Player)
		handOfPlayer(player)
		publish(player)
		local function onCharacter(character: Model)
			character:WaitForChild("LeftHand", 5)
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				-- goes with the humanoid
				humanoid.Died:Connect(function()
					local root = character:FindFirstChild("HumanoidRootPart")
					dropAll(player, if root and root:IsA("BasePart") then root else nil)
				end)
			end
			if character.Parent then
				dress(player)
				pace(player, handOfPlayer(player))
			end
		end
		table.insert(connections, player.CharacterAdded:Connect(onCharacter))
		-- a character replaced without dying takes its held tool out first, so it isn't destroyed
		-- with it; the next character gets it back in hand
		table.insert(
			connections,
			player.CharacterRemoving:Connect(function()
				local h = hands[player]
				local held = if h then Carry.held(h.carry) else nil
				local t = if held then tools[held] else nil
				if t and t.owner == player then
					stow(t)
				end
			end)
		)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end

	local system = {
		name = "Slots",
		changed = changed,
		used = used,
		landed = landed,
		loose = loose,
	}

	function system.start(_: any, _context: Brix.Context)
		local f = Workspace:FindFirstChild("Tools")
		if not f then
			f = Instance.new("Folder")
			f.Name = "Tools"
			f.Parent = Workspace
		end
		lying = f :: Folder
		local rf = ReplicatedStorage:FindFirstChild(Tools.RemoteFolder)
		if not rf then
			rf = Instance.new("Folder")
			rf.Name = Tools.RemoteFolder
			rf.Parent = ReplicatedStorage
		end
		local function remote(name: string): RemoteEvent
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = rf
			table.insert(remotes, r)
			return r
		end
		table.insert(connections, remote(Tools.SwitchRemote).OnServerEvent:Connect(onSwitch))
		table.insert(connections, remote(Tools.PocketRemote).OnServerEvent:Connect(onPocket))
		table.insert(connections, remote(Tools.DropRemote).OnServerEvent:Connect(onDrop))
		table.insert(connections, remote(Tools.GiveRemote).OnServerEvent:Connect(onGive))
		table.insert(connections, remote(Tools.UseRemote).OnServerEvent:Connect(onUse))
		notice = remote(Tools.NoticeRemote)
		broke = remote(Tools.BrokeRemote)
		table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				dropAll(player, rootOf(player))
				hands[player] = nil
			end)
		)
		for _, player in Players:GetPlayers() do
			addPlayer(player)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, r in remotes do
			r:Destroy()
		end
		table.clear(remotes)
		changed:disconnectAll()
		used:disconnectAll()
		landed:disconnectAll()
		loose:disconnectAll()
	end

	function system.lay(_: any, key: string, at: Vector3, yaw: number): string?
		local pose = resting(key, at, yaw)
		local model = Tools.clone(key, pose)
		if not model then
			return nil
		end
		local body = Tools.body(model)
		if not body then
			model:Destroy()
			return nil
		end
		nextId += 1
		local id = `{key}{nextId}`
		local t: Tool = {
			id = id,
			n = nextId,
			key = key,
			model = model,
			body = body,
			owner = nil,
			uses = Wear.full(key),
		}
		tools[id] = t
		layDown(t, pose, nil)
		return id
	end

	function system.clear(_: any, inside: (at: Vector3) -> boolean): number
		local gone = 0
		for id, t in tools do
			if t.owner == nil and t.model.Parent == lying and inside(t.body.Position) then
				tools[id] = nil
				grounds[id] = nil
				unoffer(t)
				t.model:Destroy()
				gone += 1
			end
		end
		if gone > 0 then
			loose:fire(nil)
		end
		return gone
	end

	function system.finds(_: any, each: (n: number, at: Vector3) -> ())
		for id, t in tools do
			local at = grounds[id]
			if at and t.owner == nil and t.model.Parent == lying and Catalog[t.key].find then
				each(t.n, at)
			end
		end
	end

	-- A find by its number: the one lying loose (`lifted` false) or in a monster's arms.
	local function numbered(n: number, lifted: boolean): Tool?
		for id, t in tools do
			if t.n == n and t.owner == nil and (not grounds[id]) == lifted then
				return t
			end
		end
		return nil
	end

	function system.lift(_: any, n: number, part: BasePart, holder: Instance): Weld?
		local t = numbered(n, false)
		if not (t and t.model.Parent == lying) then
			return nil
		end
		unoffer(t)
		grounds[t.id] = nil
		local box = Tools.bounds(t.key)
		local middle = t.body.PivotOffset * CFrame.new(box.Centre)
		local weld = Instance.new("Weld")
		weld.Name = Tools.CarriedName
		weld.Part0 = part
		weld.Part1 = t.body
		weld.C0 = part.CFrame:ToObjectSpace(t.body.CFrame * middle)
		weld.C1 = middle
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Name = t.key
		t.model.Parent = holder
		loose:fire(nil)
		return weld
	end

	function system.putDown(_: any, n: number, at: Vector3, yaw: number, held: CFrame?)
		local t = numbered(n, true)
		if not (t and t.weld) then
			return
		end
		-- the pivot, from where its middle is held (as `lift` measures the middle)
		local from = if held
			then held * CFrame.new(Tools.bounds(t.key).Centre):Inverse()
			else t.body.CFrame * t.body.PivotOffset
		local pose = resting(t.key, at, yaw)
		t.weld:Destroy()
		t.weld = nil
		t.body.Anchored = true
		layDown(t, pose, nil)
		-- set down, not dropped: a short ease from its hands to the floor, no clank
		t.model:PivotTo(from)
		TweenService:Create(t.body, PUT_DOWN, { CFrame = pose * t.body.PivotOffset:Inverse() })
			:Play()
	end

	function system.carried(_: any, player: Player): ({ string }, number)
		local h = handOfPlayer(player)
		local out = {}
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			out[i] = if t then t.key else ""
		end
		-- a pocketed tool isn't in your hand: no slot is (0), so Lock, Cut, Saw and Lean see a
		-- tool carried but not held
		return out, Carry.hand(h.carry)
	end

	function system.dropAll(_: any, player: Player)
		dropAll(player, rootOf(player))
	end

	function system.keep(_: any, player: Player): { string }
		local h = hands[player]
		if not h then
			return {}
		end
		local ids = Carry.keep(h.carry, function(id: string): boolean
			local t = tools[id]
			local row = if t then Catalog[t.key] else nil
			return row ~= nil and row.find == true
		end)
		local keys: { string } = {}
		for _, id in ids do
			local t = tools[id]
			if t then
				tools[id] = nil
				table.insert(keys, t.key)
				if t.model.Parent then
					glint(t.body.Position) -- the one in your hand, as everyone near saw it
				end
				stow(t)
				t.model:Destroy()
			end
		end
		if #keys > 0 then
			dress(player)
			publish(player)
			changed:fire({ player = player, kind = "Keep" })
		end
		return keys
	end

	function system.spend(_: any, player: Player, key: string): boolean
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key) then
			return false
		end
		Carry.release(h.carry)
		tools[t.id] = nil
		stow(t)
		t.model:Destroy()
		publish(player)
		changed:fire({ player = player, kind = "Spend" })
		return true
	end

	function system.wear(_: any, player: Player, key: string): number?
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key and t.uses) then
			return nil
		end
		local left, gone = Wear.spend(t.uses)
		t.uses = left
		-- on the model first: a screen learning of a blast already knows it was the last
		t.model:SetAttribute(Wear.ModelAttribute, left)
		publish(player)
		local w = Catalog[key].wear
		if gone and w then
			task.delay(w.late, shatter, t)
		end
		return left
	end

	function system.place(_: any, player: Player, key: string): (string?, Model?)
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key) then
			return nil, nil
		end
		Carry.release(h.carry)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.body.Anchored = true
		t.owner = nil
		t.placed = true
		t.model.Name = t.key
		publish(player)
		changed:fire({ player = player, kind = "Place" })
		return t.id, t.model
	end

	function system.handBack(_: any, player: Player, id: string): string?
		local t = tools[id]
		if not (t and t.placed) or not rootOf(player) then
			return ""
		end
		local h = handOfPlayer(player)
		local big = bothHands(h)
		if big then
			return `Drop the {string.lower(big.name)} first`
		end
		if Carry.room(h.carry) == nil then
			return "Hands full"
		end
		if not allowed(h) then
			return ""
		end
		t.placed = nil
		Carry.take(h.carry, t.id)
		t.owner = player
		dress(player)
		publish(player)
		local character = player.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or t.body, HAND_SOUND_REACH)
		changed:fire({ player = player, kind = "PickUp" })
		return nil
	end

	-- `quiet`: no pick-up sound here, as the screens play it when the thing reaches the hand
	-- (a buy at the car's machine, MachineVend).
	function system.give(_: any, player: Player, key: string, quiet: boolean?): boolean
		local root = rootOf(player)
		local h = handOfPlayer(player)
		if not root or Catalog[key] == nil or bothHands(h) or Carry.room(h.carry) == nil then
			return false
		end
		local model = Tools.clone(key, root.CFrame)
		local body = if model then Tools.body(model) else nil
		if not (model and body) then
			if model then
				model:Destroy()
			end
			return false
		end
		nextId += 1
		local t: Tool = {
			id = `{key}{nextId}`,
			n = nextId,
			key = key,
			model = model,
			body = body,
			owner = player,
			uses = Wear.full(key),
		}
		tools[t.id] = t
		Carry.take(h.carry, t.id)
		dress(player)
		publish(player)
		if not quiet then
			local character = player.Character
			local hand = if character then handOf(character) else nil
			Tools.play(Catalog[key].pickUp, hand or root, HAND_SOUND_REACH)
		end
		changed:fire({ player = player, kind = "PickUp" })
		return true
	end

	function system.lower(_: any, id: string, at: Vector3, yaw: number)
		local t = tools[id]
		if not (t and t.placed) then
			return
		end
		t.placed = nil
		layDown(t, resting(t.key, at, yaw), t.body.CFrame * t.body.PivotOffset)
	end

	return system :: any -- any: the table is the Slots shape built field by field above
end

return Slots
