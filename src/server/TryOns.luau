--!strict
--[[
	TryOns: trying a wrap colour on at a mirror (S5-03f4a, idea 24, D-318), a system. The moment:
	press Try on at the mirror and you turn once round as the film winds up you, then there you
	are in the glass wrapped in a colour from the counter for a few seconds, until it loosens with a
	crinkle and drops to a heap at your ankles. Every Roblox avatar shop's try-on button.

	Every mirror's glass (tagged `Mirror.Tag`, in a home or anywhere else) gets a Try on button in
	front of it, for anyone. A press is checked here: rate-limited (`TryOn.Limit`), not wrapped and
	kept, not trying one on already, alive, standing (not sat or in the air), and in front of that
	glass within `TryOn.Reach` and its slack. Then the server picks the colour (the next on the
	counter's shelf after the one they last tried, `TryOn.next`), turns them to face the glass and
	holds them there (their root anchored, as the catch holds a kept player), and wraps them in that
	colour's film (`Film.make`), tagged `TryOn.Tag` and stamped with when it went on and the way they
	faced before. Every screen winds it on, plays the zip and the crinkle and peels it off from that
	stamp (TryOnView); the mirror shows it (MirrorView). Once `TryOn.length()` has passed the film
	goes and they're let go. Nothing is saved and nothing owned changes: it's free.

	The counter's shop tries a colour on too (S5-03f4b, D-319): a card's Try on fires `TryWrap`
	(Shop.TryRemote) with that colour's name, checked as `WearWrap`'s is (`Shop.name`, a colour
	only) and rate-limited with the mirror's button. That colour, not the next, goes on at the
	nearest mirror they stand in front of within `Shop.TryReach` (the counter's, beside it); with
	none, nothing happens. The film is stamped with the glass's middle too, so their own view turns
	to it as the film winds on (TryOnView): from the shop they were facing the counter.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Mirror = require(ReplicatedStorage.Shared.Mirror)
local TryOn = require(ReplicatedStorage.Shared.TryOn)
local Film = require(script.Parent.Film)
local Prompts = require(script.Parent.Prompts)
local Shop = require(ReplicatedStorage.Shared.Shop)

-- Studs below the glass's middle, and out in front of it, its button sits: about chest height.
local BUTTON_DOWN = 0.6
local BUTTON_OUT = 0.3

-- Someone trying a colour on: their film, their root (held still), and the wait that lets them go.
type Trying = { wound: number, film: BasePart, root: BasePart, done: thread }

local TryOns = {}

function TryOns.new(): Brix.System
	local limit = Brix.RateLimit.bucket(TryOn.Limit)
	local buttons: { [BasePart]: { at: Attachment, pressed: RBXScriptConnection } } = {}
	local trying: { [Player]: Trying } = {}
	local last: { [Player]: string } = {} -- the colour each player last tried
	local connections: { RBXScriptConnection } = {}
	local respawns: { [Player]: RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil

	-- The film off `player` and them let go (early, should they leave or respawn).
	local function release(player: Player)
		local t = trying[player]
		if not t then
			return
		end
		trying[player] = nil
		if coroutine.running() ~= t.done then
			task.cancel(t.done)
		end
		t.film:Destroy()
		if t.root.Parent then
			t.root.Anchored = false
		end
	end

	-- The root of `player`'s body if they could have a film put on: alive, standing (not sat or
	-- in the air) and not held by anything else.
	local function standing(player: Player): (Model?, BasePart?)
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if
			not (character and root and root:IsA("BasePart") and humanoid)
			or humanoid.Health <= 0
			or humanoid.Sit
			or root.Anchored -- something else holds them
			or humanoid.FloorMaterial == Enum.Material.Air
		then
			return nil, nil
		end
		return character, root
	end

	-- `player` wrapped in the colour `name` (the next on the shelf after their last when nil) at
	-- `glass`, if they may: rate-limited, not kept, not trying one on already, standing, and in
	-- front of the glass within `reach` and its slack.
	local function try(player: Player, glass: BasePart, name: string?, reach: number)
		if not limit:take(player, os.clock()) or Prompts.wrapped(player) then
			return
		end
		local now = Workspace:GetServerTimeNow()
		local busy = trying[player]
		if TryOn.busy(if busy then busy.wound else nil, now) then
			return
		end
		local character, root = standing(player)
		if not (character and root) then
			return
		end
		if
			not TryOn.before(
				glass.Position,
				glass.CFrame.LookVector,
				root.Position,
				reach + TryOn.Slack
			)
		then
			return
		end
		local colour = name or TryOn.next(last[player])
		local to = glass.Position - root.Position
		local dir = Vector3.new(to.X, 0, to.Z).Unit
		local look = root.CFrame.LookVector
		local from = math.atan2(-look.X, -look.Z)
		root.Anchored = true
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
		local film = Film.make(character, root, colour)
		if not film then
			root.Anchored = false
			return
		end
		last[player] = colour
		film.Name = "TryOnFilm"
		film:AddTag(TryOn.Tag)
		film:SetAttribute(TryOn.WoundAttribute, now)
		film:SetAttribute(TryOn.FromAttribute, from)
		film:SetAttribute(TryOn.LookAttribute, glass.Position)
		film.Parent = character
		trying[player] = {
			wound = now,
			film = film,
			root = root,
			done = task.delay(TryOn.length(), release, player),
		}
	end

	-- A card's Try on in the counter's shop: that colour at the nearest mirror they're in front of.
	local function fromShop(player: Player, value: unknown)
		local name = Shop.name(value, false)
		local _, root = standing(player)
		if name == nil or root == nil then
			return
		end
		local best: BasePart? = nil
		local nearest = math.huge
		for glass in buttons do
			local d = (glass.Position - root.Position).Magnitude
			if
				d < nearest
				and TryOn.before(
					glass.Position,
					glass.CFrame.LookVector,
					root.Position,
					Shop.TryReach + TryOn.Slack
				)
				and TryOn.inLine(
					glass.Position,
					glass.CFrame.RightVector,
					root.Position,
					glass.Size.X / 2 + TryOn.SideSlack
				)
			then
				best, nearest = glass, d
			end
		end
		if best then
			try(player, best, name, Shop.TryReach)
		end
	end

	local function addGlass(inst: Instance)
		if not inst:IsA("BasePart") or buttons[inst] then
			return
		end
		local glass = inst
		local at = Instance.new("Attachment")
		at.Name = "TryOnButton"
		at.CFrame = CFrame.new(0, -BUTTON_DOWN, -(glass.Size.Z / 2 + BUTTON_OUT))
		at.Parent = glass
		local prompt = Prompts.make(at, {
			actionText = TryOn.Press,
			key = Enum.KeyCode.R,
			pad = Enum.KeyCode.ButtonY,
			reach = TryOn.Reach,
		})
		prompt.Name = "TryOn"
		buttons[glass] = {
			at = at,
			pressed = prompt.Triggered:Connect(function(player: Player)
				try(player, glass, nil, TryOn.Reach)
			end),
		}
	end

	local function dropGlass(inst: Instance)
		local b = buttons[inst :: BasePart]
		if b then
			b.pressed:Disconnect()
			b.at:Destroy()
			buttons[inst :: BasePart] = nil
		end
	end

	local function watch(player: Player)
		respawns[player] = player.CharacterRemoving:Connect(function()
			release(player)
		end)
	end

	return {
		name = "TryOns",
		start = function(_: any, _context: Brix.Context)
			-- the shop's Try on, beside its other remotes (Wearing makes the folder too)
			local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
			if not (folder and folder:IsA("Folder")) then
				local made = Instance.new("Folder")
				made.Name = Shop.RemoteFolder
				made.Parent = ReplicatedStorage
				folder = made
			end
			local r = Instance.new("RemoteEvent")
			r.Name = Shop.TryRemote
			r.Parent = folder
			remote = r
			table.insert(connections, r.OnServerEvent:Connect(fromShop))
			for _, glass in CollectionService:GetTagged(Mirror.Tag) do
				addGlass(glass)
			end
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Mirror.Tag):Connect(addGlass)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Mirror.Tag):Connect(dropGlass)
			)
			for _, player in Players:GetPlayers() do
				watch(player)
			end
			table.insert(connections, Players.PlayerAdded:Connect(watch))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					release(player)
					last[player] = nil
					local c = respawns[player]
					if c then
						c:Disconnect()
						respawns[player] = nil
					end
				end)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, c in respawns do
				c:Disconnect()
			end
			table.clear(respawns)
			for player in trying do
				release(player)
			end
			for glass in buttons do
				dropGlass(glass)
			end
			table.clear(last)
			if remote then
				remote:Destroy()
				remote = nil
			end
		end,
	}
end

return TryOns
