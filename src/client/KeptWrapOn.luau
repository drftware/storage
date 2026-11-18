--!strict
--[[
	KeptWrapOn: the film going on as a keeper wraps someone (L-07b, L-06c2), on every screen. The
	moment: its hands close on a friend down the hall and you watch them turn once round as the
	film climbs them from the feet and clouds over them, as a pallet wrapper's turntable spins a
	load in film, with the film's screech; then they're gone. Caught yourself, you hear it in the
	black, after its face has rushed you.

	The squeal: each player's `Kept` attribute turns on at the catch (Keepers sets it; only the
	server can). On everyone else's screen it plays at once from where that player stood, heard to
	`Kept.SquealReach` studs; on the caught player's own screen it waits for the black
	(`Caught.Dark`) and plays close, as their own sound, so the dread before the lunge is silent.

	The wind: the server puts the film on at the catch, stamped with when (`Kept.WoundAttribute`).
	A screen that sees a fresh one on someone else winds it on over `Caught.Dark` (`Kept.wind`):
	the real film hidden, a copy of it climbing from their feet, clouding in, while their body
	turns once round on this screen only (their root is anchored and only the server moves it, so
	it ends facing the way it began). The moment the server moves them into a unit, it stops and
	the real film shows. Nothing extra goes over the network for any of it.

	It steps only while a wrap is winding on.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)
local ToLobby = require(ReplicatedStorage.Shared.ToLobby)
local Tools = require(ReplicatedStorage.Shared.Tools)

-- Studio only: Workspace's `DevCatchHold` (seconds after the catch) holds every wind at that
-- moment too, as it holds the caught screen (CaughtLunge), to look at one frame.
local DEV_HOLD = "DevCatchHold"

-- Studs a body's root has to move from where the wind began for it to count as moved by the
-- server (into its unit): the wind only ever turns it in place.
local MOVED = 1

-- A wrap winding on: the real film (hidden meanwhile), its copy, the body's root, where the root
-- stood and the film sat on it, the film's full size, and when it went on (server clock).
type Winding = {
	wrap: BasePart,
	copy: BasePart,
	root: BasePart,
	start: CFrame,
	offset: CFrame,
	size: Vector3,
	wound: number,
}

local KeptWrapOn = {}

function KeptWrapOn.new(): Brix.System
	local was: { [Player]: boolean } = {} -- each player's kept flag as last seen
	local watching: { [Player]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local winding: { [BasePart]: Winding } = {}
	local running = false
	local studio = RunService:IsStudio()

	local function squeal(player: Player)
		if player:GetAttribute(ToLobby.Attribute) ~= nil then
			-- sent down the back-to-the-lobby card's shaft: no film goes on, so no screech; the
			-- card's own hit plays instead (ToLobbyView on theirs, ToLobbyDrag on everyone else's)
			return
		end
		if
			Kept.brought(player:GetAttribute(Kept.BroughtAttribute), Workspace:GetServerTimeNow())
		then
			-- carried up (S3-01a): wrapped long ago, stood in a shut unit; their own screen heard
			-- the film in the dip (WatchView), and nobody else was there to hear it
			return
		end
		if player == Players.LocalPlayer then
			-- in the black, once its face has rushed you
			task.delay(Caught.Dark, function()
				if
					running
					and player:GetAttribute(Kept.Attribute) == true
					and player:GetAttribute(ToLobby.Attribute) == nil
				then
					Tools.play(Kept.Squeal, SoundService, Kept.SquealReach)
				end
			end)
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return -- streamed out: too far off to hear
		end
		-- where they stood, not their body: the server moves it into a unit in the black
		local at = Instance.new("Attachment")
		at.Name = "KeptSqueal"
		at.WorldPosition = root.Position
		at.Parent = Workspace.Terrain
		Tools.play(Kept.Squeal, at, Kept.SquealReach)
		task.delay(Kept.Squeal.length / (Kept.Squeal.pitch or 1) + 1, function()
			at:Destroy()
		end)
	end

	local function watch(player: Player)
		was[player] = player:GetAttribute(Kept.Attribute) == true
		watching[player] = player:GetAttributeChangedSignal(Kept.Attribute):Connect(function()
			local now = player:GetAttribute(Kept.Attribute) == true
			if now and not was[player] then
				-- after this frame's other marks: the server sends someone down in the same step
				-- it marks them caught, and the sent-down mark may land just after this one
				task.defer(squeal, player)
			end
			was[player] = now
		end)
	end

	-- The wind over: the copy gone, the real film shown, the body facing where it began unless
	-- the server has moved it meanwhile.
	local function finish(w: Winding)
		winding[w.wrap] = nil
		w.copy:Destroy()
		w.wrap.LocalTransparencyModifier = 0
		if (w.root.Position - w.start.Position).Magnitude < MOVED then
			w.root.CFrame = w.start
		end
	end

	-- A wrap the server has just put on someone else: wind it on, if it's fresh.
	local function onWrap(inst: Instance)
		if not (running and inst:IsA("BasePart")) or winding[inst] then
			return
		end
		local wound = inst:GetAttribute(Kept.WoundAttribute)
		if type(wound) ~= "number" or Workspace:GetServerTimeNow() - wound >= Caught.Dark then
			return -- on a while: they're in their unit now, wrapped
		end
		local character = inst.Parent
		if not character or character == Players.LocalPlayer.Character then
			return -- your own film is never drawn on your screen (CaughtView)
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local copy = inst:Clone()
		for _, d in copy:GetChildren() do
			if d:IsA("JointInstance") or d:IsA("Constraint") then
				d:Destroy()
			end
		end
		copy:RemoveTag(Kept.WrapTag)
		copy.Anchored = true
		copy.Transparency = 1
		copy.Name = "KeptWrapOn"
		copy.Parent = Workspace
		inst.LocalTransparencyModifier = 1
		winding[inst] = {
			wrap = inst,
			copy = copy,
			root = root,
			start = root.CFrame,
			offset = root.CFrame:ToObjectSpace(inst.CFrame),
			size = inst.Size,
			wound = wound,
		}
	end

	return {
		name = "KeptWrapOn",
		start = function(_: any, _context: Brix.Context)
			running = true
			task.spawn(SoundPrimer.prime, { Kept.Squeal.id })
			for _, player in Players:GetPlayers() do
				watch(player)
			end
			table.insert(connections, Players.PlayerAdded:Connect(watch))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local c = watching[player]
					if c then
						c:Disconnect()
					end
					watching[player], was[player] = nil, nil
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Kept.WrapTag):Connect(onWrap)
			)
		end,
		step = function(_: any, _dt: number)
			if next(winding) == nil then
				return
			end
			local now = Workspace:GetServerTimeNow()
			local hold = if studio then Workspace:GetAttribute(DEV_HOLD) else nil
			for _, w in winding do
				local t = if type(hold) == "number"
					then hold / Caught.Dark
					else (now - w.wound) / Caught.Dark
				local moved = (w.root.Position - w.start.Position).Magnitude >= MOVED
				if t >= 1 or moved or not (w.wrap.Parent and w.root.Parent) then
					finish(w)
					continue
				end
				local rise, turn, clear = Kept.wind(t)
				local turned = w.start * CFrame.Angles(0, turn, 0)
				w.root.CFrame = turned
				local size = w.size
				w.copy.Size = Vector3.new(size.X, size.Y * rise, size.Z)
				w.copy.CFrame = turned * w.offset * CFrame.new(0, -size.Y * (1 - rise) / 2, 0)
				w.copy.Transparency = Kept.WrapBlend + (1 - Kept.WrapBlend) * clear
			end
		end,
		stop = function(_: any)
			running = false
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, c in watching do
				c:Disconnect()
			end
			table.clear(watching)
			table.clear(was)
			for _, w in winding do
				finish(w)
			end
		end,
	}
end

return KeptWrapOn
