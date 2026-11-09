--!strict
--[[
	Everyone's two tool slots (L-11b, D-048), as Lethal Company's: the server owns every tool, where
	it is and who carries it. A tool lies on a floor with a "Pick up" prompt until someone takes it;
	carried, it's in one of their two slots (`Tools.Carry`), and the one in their hand is welded in
	their left hand for everyone to see (the torch has the right). They switch slots, drop what's in
	their hand at their feet, or hand it to a friend within reach who has room. Dying or leaving
	drops everything where you stood.

	Every screen reads the slots from attributes on each Player (`ToolSlot1`, `ToolSlot2`: the
	catalog key or ""; `ToolHand`: the slot in hand). Three remotes in (a stand-in for Brix ENG-09),
	each checked for type, then range (a living character, reach, room), then rate (`Carry.allow`):
	ToolSwitch takes a slot, ToolDrop nothing, ToolGive a Player. ToolNotice tells one screen a short
	line ("Bolt cutters from Sam").

	`Doors` reads `carried` to know what's in your hand (the cutters to Cut, a padlock to Lock), and
	`spend`s the padlock that goes on a door: it leaves your slots for good.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Prompts = require(script.Parent.Prompts)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Carry = Tools.Carry
local Catalog = Tools.Catalog

local SOUND_REACH = 40 -- studs: a dropped tool's clank carries down a hall leg
local HAND_SOUND_REACH = 24 -- a hand closing on a tool, heard close by
local FALL = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local DROP_AHEAD = 2.2 -- studs in front of your middle where a dropped tool lands
local REACH_SLACK = 2 -- studs the server allows past a prompt's reach (lag, a long arm)

export type Change = { player: Player, kind: "PickUp" | "Drop" | "Give" | "Switch" | "Spend" }

export type Slots = Brix.System & {
	-- Fires as anyone's slots change, for whoever cares (keepers that hear a drop, later).
	changed: Brix.Signal<Change>,
	-- Lays a new tool of catalog key `key` on the floor at `at` (a floor point), turned `yaw`
	-- degrees. Returns its id, or nil if the place has no template.
	lay: (self: any, key: string, at: Vector3, yaw: number) -> string?,
	-- The catalog keys `player` carries, slot by slot ("" for empty), and the slot in hand.
	carried: (self: any, player: Player) -> ({ string }, number),
	-- Uses up what's in `player`'s hand if it's catalog key `key` (a padlock hung on a door): out
	-- of their slots and gone. Whether it was.
	spend: (self: any, player: Player, key: string) -> boolean,
}

type Tool = {
	id: string,
	key: string,
	model: Model,
	body: BasePart,
	prompt: ProximityPrompt?,
	refuse: ((string) -> ())?,
	owner: Player?,
	weld: Weld?,
}

type Hand = {
	carry: Tools.CarryState,
	last: number?,
	burst: number,
}

-- The tool's pivot for lying flat on a floor with its middle at `at`, turned `yaw` degrees: its
-- lowest point on the floor. By its middle, not its grip, so a long tool dropped by a wall lies
-- along it rather than through it.
local function resting(key: string, at: Vector3, yaw: number): CFrame
	local body = Tools.specs(key).Body
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

local Slots = {}

function Slots.new(): Slots
	local tools: { [string]: Tool } = {}
	local hands: { [Player]: Hand } = {}
	local connections: { RBXScriptConnection } = {}
	local remotes: { Instance } = {}
	local changed = Brix.Signal.new() :: Brix.Signal<Change>
	local lying: Folder? = nil
	local notice: RemoteEvent? = nil
	local nextId = 0

	local function handOfPlayer(player: Player): Hand
		local h = hands[player]
		if not h then
			h = { carry = Carry.new(), last = nil, burst = Carry.Burst }
			hands[player] = h
		end
		return h
	end

	local function tell(player: Player, text: string)
		if notice then
			notice:FireClient(player, text)
		end
	end

	-- Writes `player`'s slots to their attributes, for every screen.
	local function publish(player: Player)
		local h = handOfPlayer(player)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			local key = if t then t.key else ""
			if player:GetAttribute(Tools.slotAttribute(i)) ~= key then
				player:SetAttribute(Tools.slotAttribute(i), key)
			end
		end
		if player:GetAttribute(Tools.HandAttribute) ~= h.carry.active then
			player:SetAttribute(Tools.HandAttribute, h.carry.active)
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
		local hand, grip = handOf(character)
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
		local turn = Catalog[t.key].inHand
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
			actionText = "Pick up",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Carry.PickReach,
		})
		p.RequiresLineOfSight = false -- a tool on the floor is low: boxes mustn't hide its prompt
		t.prompt = p
		t.refuse = Prompts.refuser(p, function()
			return row.name
		end)
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
		if from then
			local goal = pose * t.body.PivotOffset:Inverse()
			local tween = TweenService:Create(t.body, FALL, { CFrame = goal })
			tween.Completed:Once(function()
				if t.owner == nil and t.model.Parent == lying then
					Tools.play(Catalog[t.key].drop, t.body, SOUND_REACH)
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

	-- Whether `player`'s hand may move now (the rate check); spends one if so.
	local function allowed(h: Hand): boolean
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
		if (root.Position - t.body.Position).Magnitude > Carry.PickReach + REACH_SLACK + 2 then
			return
		end
		local h = handOfPlayer(player)
		if Carry.room(h.carry) == nil then
			if t.refuse then
				t.refuse("Hands full")
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
		dress(player)
		publish(player)
		local character = player.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or root, HAND_SOUND_REACH)
		changed:fire({ player = player, kind = "PickUp" })
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
		if Carry.select(h.carry, s) then
			dress(player)
			changed:fire({ player = player, kind = "Switch" })
		end
		publish(player)
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
		if Carry.room(them.carry) == nil then
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
		table.insert(connections, remote(Tools.DropRemote).OnServerEvent:Connect(onDrop))
		table.insert(connections, remote(Tools.GiveRemote).OnServerEvent:Connect(onGive))
		notice = remote(Tools.NoticeRemote)
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
		local t: Tool = { id = id, key = key, model = model, body = body, owner = nil }
		tools[id] = t
		layDown(t, pose, nil)
		return id
	end

	function system.carried(_: any, player: Player): ({ string }, number)
		local h = handOfPlayer(player)
		local out = {}
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			out[i] = if t then t.key else ""
		end
		return out, h.carry.active
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

	return system :: any -- any: the table is the Slots shape built field by field above
end

return Slots
