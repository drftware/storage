--!strict
--[[
	Coins on the server (S1-04a): the coins lying on the floors and everyone's count, a system.
	The moment it serves: a door goes up and there's a glint of gold on the concrete; you step in,
	tap, and it's yours with a chink while your count ticks up. Most doors pay something, so every
	door is worth the noise of opening it.

	`Deals` lays a unit's pile as its door first lifts (`lay`, at the spot DealSpot keeps clear of
	whatever else the unit holds): one to three coin MeshParts from `ReplicatedStorage.Props.Coin`
	in the pile's generated layout (`Coins.Specs`), a faint glint on the top coin, and one "Take"
	button. The server owns the pile and the count. A take is checked as every press is: a living
	player who isn't wrapped (GDD "Earning nothing"), within `Coins.Reach` of the pile, not through
	a shut door, then the rate (`Coins.allow`). Whoever's take arrives first gets the whole pile, as
	DOORS' gold goes to whoever grabs it; a second press on a taken pile does nothing (its coins are
	already flying to the friend who took them, on screen).

	A taken pile is stamped with the taker (`Coins.TakenAttribute`) and stays `Coins.Linger` seconds
	so every screen throws its coins up and away (CoinView), then it goes. Each player's count is
	their own, on their Player as `Coins.Attribute`: zero as a climb begins (`Climbs.began`), for
	someone joining one already under way, and nil outside a climb. Coins are never saved: they
	last the climb. The gate adds each floor's pay (`pay`, GatePay, S1-06). As the climb ends,
	every count stops where it is and is handed over once (`close`), to be turned into cash
	(CashOut, S1-12); the counts stay on screen through the end and go as it covers every screen
	(`clear`).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Coins = require(ReplicatedStorage.Shared.Coins)
local CoinSpecs = require(ReplicatedStorage.Shared.Coins.Specs)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local REACH_SLACK = 2 -- studs the server allows past the button's reach (lag, a long arm)
local DEV_COINS = "DevCoins" -- Studio only: a Workspace attribute that sets every count

-- The glint: now and then a spark on the top coin, so a pile reads from the doorway on a phone.
local GLINT_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local GLINT_RATE = 0.9 -- sparks a second: a twinkle, never a fountain

-- Coins coming into a player's count: how many, the count after, and why: a pile they took
-- ("pile"), the floor's pay at the gate ("gate") or a marked box they opened ("box", B-03b).
-- Recording records each (S1-02).
export type Earned = {
	player: Player,
	amount: number,
	balance: number,
	reason: "pile" | "gate" | "box",
}

-- Coins going out of a player's count: how many, the count after, and what they bought (a key
-- of the car's machine's stock, S1-10c2). Recording records each.
export type Spent = {
	player: Player,
	amount: number,
	balance: number,
	item: string,
}

export type CoinsSystem = Brix.System & {
	-- Fires as coins come into a player's count, after it has changed.
	earned: Brix.Signal<Earned>,
	-- Fires as coins go out of a player's count, after it has changed.
	spent: Brix.Signal<Spent>,
	-- How many coins `player` has: nil outside a climb.
	countOf: (self: any, player: Player) -> number?,
	-- Takes `coins` from `player`'s count for `item` (the car's machine, S1-10c2). False, and
	-- nothing taken, if they're not in a climb or have too few.
	spend: (self: any, player: Player, coins: number, item: string) -> boolean,
	-- Lays a pile of `count` coins (1 to 3) at `place` (on the floor, facing as it lies) for unit
	-- `unit`, into the unit's hall piece. False when the place lacks the coin's template.
	lay: (self: any, unit: Model, count: number, place: CFrame) -> boolean,
	-- Everyone's count back to zero: a climb begins.
	reset: (self: any) -> (),
	-- The climb is over: every count stops where it is (nothing more is taken, paid or spent until
	-- the next climb begins) and is handed back, by player. Once a climb: called again before the
	-- next begins, it hands back nothing, so a count is never handed over twice.
	close: (self: any) -> { [Player]: number },
	-- Every count gone from its player (and their screen): the climb's end has covered everything.
	clear: (self: any) -> (),
	-- Adds `coins` to `player`'s count: paid at the gate (S1-06), or out of a marked box they
	-- opened (`reason` "box", B-03b; their screen flies the coins in from it). Nothing outside a
	-- climb.
	pay: (self: any, player: Player, coins: number, reason: ("gate" | "box")?) -> (),
}

type Pile = {
	model: Model,
	unit: Model,
	count: number,
	at: Vector3, -- the pile's middle, on the floor
	prompt: ProximityPrompt?,
}

type Rate = { last: number?, burst: number }

local CoinsSystem = {}

function CoinsSystem.new(): CoinsSystem
	local piles: { [Model]: Pile } = {}
	local counts: { [Player]: number? } = {}
	local rates: { [Player]: Rate } = {}
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}
	local climbing = false
	local warned = false
	local earned = Brix.Signal.new() :: Brix.Signal<Earned>
	local spent = Brix.Signal.new() :: Brix.Signal<Spent>

	local function template(): BasePart?
		local props = ReplicatedStorage:FindFirstChild("Props")
		local found = props and props:FindFirstChild(Coins.Template)
		if found and found:IsA("BasePart") then
			return found
		end
		if not warned then
			warned = true
			warn(`Coins: no ReplicatedStorage.Props.{Coins.Template}, so no coins are laid`)
		end
		return nil
	end

	local function setCount(player: Player, count: number?)
		counts[player] = count
		player:SetAttribute(Coins.Attribute, count)
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		if not character then
			return nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return root
		end
		return nil
	end

	local function take(pile: Pile, player: Player)
		-- type: Triggered hands us a Player. Range: a pile still lying there, a living player who
		-- isn't wrapped, near it, on its side of the door.
		if piles[pile.model] ~= pile or not pile.model.Parent or not climbing then
			return
		end
		if Prompts.wrapped(player) then
			return -- wrapped: no hands to take anything with
		end
		local root = rootOf(player)
		if not root or (root.Position - pile.at).Magnitude > Coins.Reach + REACH_SLACK then
			return
		end
		if
			pile.unit:FindFirstChild("DoorOrigin", true)
			and StorageUnit.RollUpDoor.keepsApart(pile.unit, root.Position, pile.at)
		then
			return -- a shut door between you and it: your screen hid its button (BehindDoors)
		end
		-- rate
		local rate = rates[player] or { last = nil, burst = 0 }
		local now = os.clock()
		local may, left = Coins.allow(rate.last, rate.burst, now)
		if not may then
			return
		end
		rates[player] = { last = now, burst = left }

		piles[pile.model] = nil
		if pile.prompt then
			pile.prompt.Enabled = false
		end
		pile.model:SetAttribute(Coins.TakenAttribute, player.UserId)
		setCount(player, (counts[player] or 0) + pile.count)
		earned:fire({
			player = player,
			amount = pile.count,
			balance = counts[player] or 0,
			reason = "pile",
		})
		if RunService:IsStudio() then
			print(
				`Coins: {player.Name} took {pile.count} in {pile.unit.Name}, now {counts[player]}`
			)
		end
		local model = pile.model
		task.delay(Coins.Linger, function()
			model:Destroy()
		end)
	end

	local function glint(coin: BasePart)
		local p = Instance.new("ParticleEmitter")
		p.Name = "Glint"
		p.Texture = GLINT_TEXTURE
		p.Rate = GLINT_RATE
		p.Lifetime = NumberRange.new(0.3, 0.45)
		p.Speed = NumberRange.new(0)
		p.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		p.Rotation = NumberRange.new(0, 90)
		p.RotSpeed = NumberRange.new(-90, 90)
		p.Color = ColorSequence.new(Color3.fromRGB(255, 233, 168))
		p.LightEmission = 1
		p.LightInfluence = 0.4 -- brighter in the bulb's light, still there in the dark
		p.Brightness = 2
		p.ZOffset = 0.4 -- in front of the coin it sits on
		p.Parent = coin
	end

	local system = { name = "Coins", earned = earned, spent = spent }

	function system.lay(_: any, unit: Model, count: number, place: CFrame): boolean
		local spec = CoinSpecs.Piles[count]
		local coin = template()
		if not (spec and coin) then
			return false
		end
		local model = Instance.new("Model")
		model.Name = "Coins"
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		local top: BasePart? = nil
		for i, c in spec.Coins do
			local part = coin:Clone()
			part.Name = `Coin{i}`
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false -- no ray stops on a coin: drops, torches, the keepers' eyes
			part.CastShadow = false
			local turn = c.Turn
			part.CFrame = place
				* CFrame.new(c.Position)
				* CFrame.fromOrientation(math.rad(turn.X), math.rad(turn.Y), math.rad(turn.Z))
			part.Parent = model
			if not top or part.Position.Y > top.Position.Y then
				top = part
			end
		end
		local first = model:FindFirstChild("Coin1") :: BasePart
		model.PrimaryPart = first
		if top then
			glint(top)
		end
		local at = Instance.new("Attachment")
		at.Name = "Take"
		at.Parent = first
		at.WorldPosition = place.Position + Vector3.new(0, 0.5, 0)
		local prompt = Prompts.make(at, {
			actionText = "Take",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Coins.Reach,
		})
		prompt.RequiresLineOfSight = false -- low on the floor: a box mustn't hide it
		model:SetAttribute(Coins.CountAttribute, count)
		CollectionService:AddTag(model, Coins.Tag)

		local pile: Pile = {
			model = model,
			unit = unit,
			count = count,
			at = place.Position,
			prompt = prompt,
		}
		piles[model] = pile
		prompt.Triggered:Connect(function(player: Player)
			take(pile, player)
		end)
		model.Destroying:Once(function()
			if piles[model] == pile then
				piles[model] = nil
			end
		end)
		model.Parent = unit.Parent or unit
		return true
	end

	function system.pay(_: any, player: Player, coins: number, reason: ("gate" | "box")?)
		local count = counts[player]
		if count == nil or coins <= 0 or not climbing then
			return
		end
		local amount = math.floor(coins)
		setCount(player, count + amount)
		if amount > 0 then
			earned:fire({
				player = player,
				amount = amount,
				balance = count + amount,
				reason = reason or "gate",
			})
		end
	end

	function system.countOf(_: any, player: Player): number?
		return counts[player]
	end

	function system.spend(_: any, player: Player, coins: number, item: string): boolean
		local count = counts[player]
		local amount = math.floor(coins)
		if count == nil or amount <= 0 or count < amount or not climbing then
			return false
		end
		setCount(player, count - amount)
		spent:fire({ player = player, amount = amount, balance = count - amount, item = item })
		return true
	end

	function system.reset(_: any)
		climbing = true
		for _, player in Players:GetPlayers() do
			setCount(player, 0)
		end
	end

	function system.close(_: any): { [Player]: number }
		local handed: { [Player]: number } = {}
		if not climbing then
			return handed
		end
		climbing = false
		for player, count in counts do
			if count and player.Parent then
				handed[player] = count
			end
		end
		return handed
	end

	function system.clear(_: any)
		climbing = false
		for _, player in Players:GetPlayers() do
			setCount(player, nil)
		end
		table.clear(counts)
	end

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Climbs fills this (init.server)
		local climbs = (context.registry:get("climbs") :: any) :: { began: Brix.Signal<any> }?
		if climbs and climbs.began then
			table.insert(
				signals,
				climbs.began:connect(function()
					system.reset(system)
				end)
			)
		end
		-- Studio only: Workspace's `DevCoins` (a number) sets everyone's count in a climb, to test
		-- the car's machine (docs/STUDIO.md, "Staging a buy").
		if RunService:IsStudio() then
			table.insert(
				connections,
				game:GetService("Workspace"):GetAttributeChangedSignal(DEV_COINS):Connect(function()
					local value = game:GetService("Workspace"):GetAttribute(DEV_COINS)
					if type(value) == "number" then
						for _, player in Players:GetPlayers() do
							setCount(player, math.clamp(math.floor(value), 0, 999))
						end
					end
				end)
			)
		end
		table.insert(
			connections,
			Players.PlayerAdded:Connect(function(player: Player)
				if climbing then
					setCount(player, 0) -- joining a climb under way: from zero
				end
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				counts[player] = nil
				rates[player] = nil
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, s in signals do
			s:disconnect()
		end
		table.clear(signals)
		table.clear(piles)
	end

	return system
end

return CoinsSystem
