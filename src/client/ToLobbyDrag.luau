--!strict
--[[
	ToLobbyDrag: a friend sent down to the lobby, seen from the floor (S4-03c4b, D-410, shared
	`ToLobby`). The moment: a Mannequin's hands close on your friend down the hall, the floor
	under them glows the card's red, they're yanked down, then dragged through the floor faster
	and faster with the card's low hit, gone, and far below a slam: the car. You know at once what
	that card does, and you're one fewer. As a Dead by Daylight survivor is taken off the hook
	while the rest play on. No words.

	Each other player's `ToLobby.Attribute` (the catch's server time, set by the server's
	ToLobby) starts it, if the catch is fresh and their body is streamed in. Their root is
	anchored by the server at the catch and only the server moves it, so on this screen it is
	moved down by `ToLobby.drag` alone (nothing goes over the network); the server's swap at
	`ToLobby.Swap` takes the body a beat after it's under. Under the body, where they stood, a red
	light and a flat red pool on the floor rise and fade with the drag's glow. A friend close by
	feels a jolt as the drag starts (`ToLobby.DragKick`, gone by `ToLobby.DragReach` studs).

	If the mark comes off while the body is still here (the last friend caught: the end covers,
	nobody is swapped), the body goes back where it stood. In Studio a stand-in friend
	(`Left.StandInTag`) given the mark on its model is dragged too, so one player can see it.

	It steps only while a drag is on.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Left = require(ReplicatedStorage.Shared.Left)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Sounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local ToLobby = require(ReplicatedStorage.Shared.ToLobby)

local ToLobbyDrag = {}

-- How far off the card's low hit carries, and the far slam of the car under the floor (studs).
local HIT_REACH = 70
local SLAM_REACH = 40
-- The far slam: the car's gate under the floor, pitched down and quiet, from deep below.
local SLAM_PITCH = 0.6
local SLAM_VOLUME = 0.45
local SLAM_LENGTH = 1.1
local SLAM_BELOW = 6
-- The red under them: the light's brightness and reach at full glow, lifted off the floor so it
-- lights the body from below and the floor round it.
local LIGHT_BRIGHTNESS = 6
local LIGHT_RANGE = 14
local LIGHT_LIFT = 0.8
-- The pool's see-through at full glow (Neon: it glows, so not solid), and its lift off the
-- floor so it never fights the floor's surface.
local POOL_CLEAR = 0.3
local POOL_LIFT = 0.03
-- How far down to look for the floor under a root (studs).
local FLOOR_LOOK = 12
local FOLD = Sounds.Sounds["Fold" :: Sounds.SoundName]
-- Studio only: Workspace's `DevCatchHold` (seconds after the catch) holds every drag at that
-- moment, as it holds the caught screen and the film's wind, to look at one frame.
local DEV_HOLD = "DevCatchHold"

type Drag = {
	body: Model,
	root: BasePart,
	start: CFrame,
	placed: CFrame, -- where this screen last put the root: anything else, the server moved it
	at: number, -- the catch's server time
	place: Attachment, -- on the floor where they stood: the light and the sounds
	light: PointLight,
	pool: Part,
	-- their name over their head shows through the floor: hidden once they're under, put back
	-- with the body
	humanoid: Humanoid?,
	named: Enum.HumanoidDisplayDistanceType,
	hit: boolean,
	slammed: boolean,
	lit: boolean, -- the red still up (its light and pool not yet cleared)
}

function ToLobbyDrag.new(kick: (amount: number) -> ()): Brix.System
	local version = NextFloor.find("CaughtToLobby") :: NextFloor.Version
	local red = Color3.new(version.light[1], version.light[2], version.light[3])
	local connections: { RBXScriptConnection } = {}
	local watching: { [Instance]: RBXScriptConnection } = {}
	local drags: { [Model]: Drag } = {}
	local stepping = false
	local studio = RunService:IsStudio()

	local function play(
		id: string,
		from: number,
		length: number,
		volume: number,
		pitch: number,
		parent: Instance,
		reach: number
	)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.PlaybackSpeed = pitch
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = reach
		s.TimePosition = from
		s.Parent = parent
		s:Play()
		task.delay(length / pitch + 0.2, function()
			s:Destroy()
		end)
	end

	local function clear(d: Drag)
		if d.lit then
			d.lit = false
			d.light:Destroy()
			d.pool:Destroy()
			-- the place outlives the light for the far slam still ringing from it
			task.delay(SLAM_LENGTH / SLAM_PITCH + 0.5, function()
				d.place:Destroy()
			end)
		end
	end

	local function finish(body: Model, putBack: boolean)
		local d = drags[body]
		if not d then
			return
		end
		drags[body] = nil
		clear(d)
		if putBack and d.root.Parent then
			if d.root.CFrame.Position:FuzzyEq(d.placed.Position, 0.01) then
				d.root.CFrame = d.start
			end
			local humanoid = d.humanoid
			if humanoid then
				humanoid.DisplayDistanceType = d.named
			end
		end
	end

	-- Where the floor is under `root`, looking past every body (a friend's legs, a monster).
	local function floorUnder(body: Model, root: BasePart): number
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = { body }
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				table.insert(skip, character)
			end
		end
		params.FilterDescendantsInstances = skip
		local hit = Workspace:Raycast(root.Position, Vector3.new(0, -FLOOR_LOOK, 0), params)
		if hit then
			return hit.Position.Y
		end
		-- no floor found: a standing avatar's root is about three studs up
		return root.Position.Y - 3
	end

	local function begin(body: Model, at: number)
		local since = Workspace:GetServerTimeNow() - at
		if drags[body] or not ToLobby.fresh(since) then
			return
		end
		local root = body:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return -- streamed out: too far off to see
		end
		local floor = floorUnder(body, root)
		local place = Instance.new("Attachment")
		place.Name = "ToLobbyDrag"
		place.WorldPosition = Vector3.new(root.Position.X, floor + LIGHT_LIFT, root.Position.Z)
		local light = Instance.new("PointLight")
		light.Color = red
		light.Brightness = 0
		light.Range = LIGHT_RANGE
		light.Shadows = false
		light.Parent = place
		place.Parent = Workspace.Terrain
		local pool = Instance.new("Part")
		pool.Name = "ToLobbyPool"
		pool.Shape = Enum.PartType.Cylinder
		pool.Material = Enum.Material.Neon
		pool.Color = red
		pool.Anchored = true
		pool.CanCollide = false
		pool.CanQuery = false
		pool.CanTouch = false
		pool.CastShadow = false
		pool.Transparency = 1
		pool.Size = Vector3.new(0.05, 0.1, 0.1)
		-- a cylinder's axis is its X: stood on end, it lies flat on the floor
		pool.CFrame = CFrame.new(root.Position.X, floor + POOL_LIFT, root.Position.Z)
			* CFrame.Angles(0, 0, math.pi / 2)
		pool.Parent = Workspace
		local humanoid = body:FindFirstChildOfClass("Humanoid")
		drags[body] = {
			body = body,
			root = root,
			start = root.CFrame,
			placed = root.CFrame,
			at = at,
			place = place,
			light = light,
			pool = pool,
			humanoid = humanoid,
			named = if humanoid
				then humanoid.DisplayDistanceType
				else Enum.HumanoidDisplayDistanceType.Viewer,
			-- one arriving late (a stream, a join) skips the sounds it missed
			hit = since >= Caught.Dark + 0.25,
			slammed = since >= ToLobby.Land + 0.25,
			lit = true,
		}
		if humanoid and since >= ToLobby.Land then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		stepping = true
	end

	local function onMark(body: Model?, value: unknown)
		if not body then
			return
		end
		if type(value) == "number" then
			begin(body, value)
		else
			finish(body, true)
		end
	end

	local function watchPlayer(player: Player)
		if player == Players.LocalPlayer or watching[player] then
			return
		end
		watching[player] = player:GetAttributeChangedSignal(ToLobby.Attribute):Connect(function()
			onMark(player.Character, player:GetAttribute(ToLobby.Attribute))
		end)
		onMark(player.Character, player:GetAttribute(ToLobby.Attribute))
	end

	-- Studio only: a stand-in friend's model carries the mark itself.
	local function watchStandIn(inst: Instance)
		if not inst:IsA("Model") or watching[inst] then
			return
		end
		watching[inst] = inst:GetAttributeChangedSignal(ToLobby.Attribute):Connect(function()
			onMark(inst, inst:GetAttribute(ToLobby.Attribute))
		end)
		onMark(inst, inst:GetAttribute(ToLobby.Attribute))
	end

	local function unwatch(inst: Instance)
		local c = watching[inst]
		if c then
			c:Disconnect()
			watching[inst] = nil
		end
	end

	return {
		name = "ToLobbyDrag",
		start = function(_: any, _context: Brix.Context)
			-- the card's hit and the car's slam are primed by ToLobbyView on this same screen
			for _, player in Players:GetPlayers() do
				watchPlayer(player)
			end
			table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					unwatch(player)
					local body = player.Character
					if body then
						finish(body, false)
					end
				end)
			)
			if studio then
				for _, inst in CollectionService:GetTagged(Left.StandInTag) do
					watchStandIn(inst)
				end
				table.insert(
					connections,
					CollectionService:GetInstanceAddedSignal(Left.StandInTag):Connect(watchStandIn)
				)
				table.insert(
					connections,
					CollectionService:GetInstanceRemovedSignal(Left.StandInTag):Connect(unwatch)
				)
			end
		end,
		step = function(_: any, _dt: number)
			if not stepping then
				return
			end
			local now = Workspace:GetServerTimeNow()
			local any = false
			for body, d in drags do
				if
					not (d.root.Parent and d.root.CFrame.Position:FuzzyEq(d.placed.Position, 0.01))
				then
					-- the server's swap took the body, or the server moved it: it's theirs now
					finish(body, false)
					continue
				end
				any = true
				local since = now - d.at
				local hold = if studio then Workspace:GetAttribute(DEV_HOLD) else nil
				if type(hold) == "number" then
					since = math.min(since, hold)
				end
				local sink, glow = ToLobby.drag(since)
				d.placed = d.start - Vector3.yAxis * sink
				d.root.CFrame = d.placed
				if not d.hit and since >= Caught.Dark then
					d.hit = true
					for _, h in version.sound do
						task.delay(
							h.at,
							play,
							h.id,
							h.from,
							h.length,
							h.volume,
							h.pitch,
							d.place,
							HIT_REACH
						)
					end
					local camera = Workspace.CurrentCamera
					if camera then
						local away = (camera.Focus.Position - d.place.WorldPosition).Magnitude
						local amount = ToLobby.DragKick * (1 - away / ToLobby.DragReach)
						if amount > 0 then
							kick(amount)
						end
					end
				end
				if not d.slammed and since >= ToLobby.Land then
					d.slammed = true
					local humanoid = d.humanoid
					if humanoid then
						humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end
					local below = Instance.new("Attachment")
					below.WorldPosition = d.place.WorldPosition - Vector3.yAxis * SLAM_BELOW
					below.Parent = d.place
					play(
						FOLD.Id,
						Sounds.FoldSlam - 0.04,
						SLAM_LENGTH,
						FOLD.Volume * SLAM_VOLUME,
						SLAM_PITCH,
						below,
						SLAM_REACH
					)
				end
				if d.lit then
					if since >= ToLobby.Land + ToLobby.DragFade then
						clear(d)
					else
						d.light.Brightness = LIGHT_BRIGHTNESS * glow
						local wide = ToLobby.DragHole * math.sqrt(glow)
						d.pool.Size = Vector3.new(0.05, wide, wide)
						d.pool.Transparency = 1 - (1 - POOL_CLEAR) * glow
					end
				end
			end
			stepping = any
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for inst in watching do
				unwatch(inst)
			end
			for body in drags do
				finish(body, true)
			end
			stepping = false
		end,
	} :: Brix.System
end

return ToLobbyDrag
