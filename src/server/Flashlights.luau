--!strict
--[[
	Every player's flashlight (L-11a, D-047): the server owns whether each torch is on and where it
	points. Each character gets a torch in its right hand (Flashlight.clone, welded at the hand's
	grip, its beam along the forearm), its light off. The torch's model carries what every screen
	draws: `On` and `Aim` (degrees up, whole). Each screen lights the lens and beam itself (yours
	from your own view's torch), so the server never switches a light.

	Two remotes (a stand-in for Brix ENG-09), both checked for type, then range, then rate:
	ReplicatedStorage.Remotes.Flashlight takes the state you want (on or off: the client asks for
	a state, not a toggle, so a dropped or refused message can't leave it inverted) and
	Remotes.FlashlightAim (unreliable) takes your look's pitch while it's on.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Flashlight = require(ReplicatedStorage.Shared.Flashlight)

local Torch = Flashlight.Torch

export type Switch = { player: Player, on: boolean }

export type Flashlights = Brix.System & {
	-- Fires as a torch is switched, for whoever cares (keepers that see light, later).
	switched: Brix.Signal<Switch>,
	-- Whether `player`'s torch is on.
	isOn: (self: any, player: Player) -> boolean,
	-- Where `player`'s torch points: degrees up from level (their facing gives the rest).
	aim: (self: any, player: Player) -> number,
}

type Held = {
	model: Model,
	on: boolean,
	aim: number,
	last: number?, -- when the last switch went through
	burst: number, -- switches left in hand
	aimAt: number, -- when the last aim was taken
}

-- How the torch sits in a hand, from the hand's grip attachment: its beam down the forearm (the
-- hand's -Y), its button towards the back of the hand, so with the arm raised the button is up.
local IN_HAND = CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, -Vector3.zAxis, Vector3.yAxis)

local function now(): number
	return os.clock()
end

local function handOf(character: Model): (BasePart?, CFrame)
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not (hand and hand:IsA("BasePart")) then
		return nil, CFrame.identity
	end
	-- only the grip's place: rigs turn the attachment differently (Studio's own avatar turns its
	-- look down the arm), so the torch is turned from the hand itself
	local grip = hand:FindFirstChild("RightGripAttachment")
	local at = if grip and grip:IsA("Attachment")
		then grip.Position
		else Vector3.new(0, -hand.Size.Y / 2, 0)
	return hand, CFrame.new(at)
end

local Flashlights = {}

function Flashlights.new(): Flashlights
	local held: { [Player]: Held } = {}
	local connections: { RBXScriptConnection } = {}
	local switched = Brix.Signal.new() :: Brix.Signal<Switch>
	local remotes: { Instance } = {}

	-- A fresh torch in a new character's hand, off.
	local function give(player: Player, character: Model)
		local old = held[player]
		if old then
			old.model:Destroy()
			held[player] = nil
		end
		local hand, grip = handOf(character)
		if not hand then
			warn(`Flashlights: {player.Name}'s character has no right hand`)
			return
		end
		local r = Flashlight.clone(hand.CFrame * grip * IN_HAND, character, false)
		if not r then
			return
		end
		r.model:SetAttribute(Torch.OnAttribute, false)
		r.model:SetAttribute(Torch.AimAttribute, 0)
		for _, part in { r.body, r.lens } :: { MeshPart } do
			local weld = Instance.new("Weld")
			weld.Part0 = hand
			weld.Part1 = part
			weld.C0 = grip * IN_HAND
			weld.C1 = part.PivotOffset
			weld.Parent = part
			part.Anchored = false
		end
		held[player] =
			{ model = r.model, on = false, aim = 0, last = nil, burst = Torch.Burst, aimAt = 0 }
	end

	local function set(player: Player, h: Held, on: boolean)
		h.on = on
		h.model:SetAttribute(Torch.OnAttribute, on)
		switched:fire({ player = player, on = on })
	end

	-- The state `player` wants their torch in: checked, then done.
	local function onSwitch(player: Player, on: unknown)
		-- type: a state, not a toggle
		if type(on) ~= "boolean" then
			return
		end
		-- range: a torch of theirs, in a living hand
		local h = held[player]
		if not (h and h.model.Parent) then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (humanoid and humanoid.Health > 0) then
			return
		end
		-- rate: a fast thumb's blinks, no faster
		local t = now()
		local may, left = Torch.allow(h.last, h.burst, t)
		if not may then
			return
		end
		h.last, h.burst = t, left
		if on ~= h.on then
			set(player, h, on)
		end
	end

	-- Where `player` looks, while their torch is on: checked, then kept and shown.
	local function onAim(player: Player, pitch: unknown)
		-- type: a real number, clamped to how far you can look
		local degrees = Torch.aim(pitch)
		if degrees == nil then
			return
		end
		-- range: a lit torch of theirs
		local h = held[player]
		if not (h and h.on) then
			return
		end
		-- rate: no faster than the client sends
		local t = now()
		if t - h.aimAt < Torch.AimEvery * 0.5 then
			return
		end
		h.aimAt = t
		if degrees ~= h.aim then
			h.aim = degrees
			h.model:SetAttribute(Torch.AimAttribute, degrees)
		end
	end

	local function addPlayer(player: Player)
		table.insert(
			connections,
			player.CharacterAdded:Connect(function(character: Model)
				-- the rig's hand arrives with the character; wait a moment for it if not
				character:WaitForChild("RightHand", 5)
				if character.Parent then
					give(player, character)
				end
			end)
		)
		if player.Character then
			give(player, player.Character)
		end
	end

	local system = {
		name = "Flashlights",
		switched = switched,
	}

	function system.start(_: any, _context: Brix.Context)
		local f = ReplicatedStorage:FindFirstChild(Torch.RemoteFolder)
		if not f then
			f = Instance.new("Folder")
			f.Name = Torch.RemoteFolder
			f.Parent = ReplicatedStorage
		end
		local switch = Instance.new("RemoteEvent")
		switch.Name = Torch.SwitchRemote
		switch.Parent = f
		local aim = Instance.new("UnreliableRemoteEvent")
		aim.Name = Torch.AimRemote
		aim.Parent = f
		remotes = { switch, aim }
		table.insert(connections, switch.OnServerEvent:Connect(onSwitch))
		table.insert(connections, aim.OnServerEvent:Connect(onAim))
		table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				held[player] = nil
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
		switched:disconnectAll()
	end

	function system.isOn(_: any, player: Player): boolean
		local h = held[player]
		return h ~= nil and h.on
	end

	function system.aim(_: any, player: Player): number
		local h = held[player]
		return if h then h.aim else 0
	end

	return system :: any -- any: the table is the Flashlights shape built field by field above
end

return Flashlights
