--!strict
--[[
	Marked boxes on the server (B-02a): the one box in a unit with something in it, and its Open.
	The moment: you press Open and the tape rips, the flaps burst; everyone near hears and sees
	it (MarkedBoxView plays it on every screen), then a held breath in the grade's light and the
	find rises out, turns once and flies into the opener's hand (B-02b). The deal stands one in a
	unit whose find or tool packs into it (Deals, `Deal.packs`, B-03a), and puts a unit's coins in
	it too, or in a box of their own (B-03b): they burst out with the flaps and into the opener's
	count, chinking as each lands (CoinView).

	`stand` puts a marked box (`Boxes.cloneMarked`) at a place in a unit's hall piece, tagged
	`Opening.Tag`, with the unit in an ObjectValue for screens' door checks and one "Open" button
	on its lid. A press is checked as every press is (`Opening.refuse`): not opened yet, a living
	player who isn't wrapped, within `Opening.Reach` of the button, not through a shut door; then
	the rate (`Opening.allow`). Whoever's press arrives first opens it, once: the button goes, and
	the box is stamped with the server's time and the opener (`OpenedAt`, `OpenedBy`). The server
	never moves a flap: its copy stays shut, and only the body is solid, so nothing changes for
	anyone walking into it. An opened box stays where it stood, open, for the rest of the floor.

	What's inside (B-02b) is the server's alone until the open: only then is the box stamped with
	the find's key and grade (`Find`, `Grade`; a tool's key too, B-03a, whose row has no grade,
	so it opens as a Common), in the same batch before `OpenedAt` so every
	screen has them as it starts the reveal. If the opener's hands are full as they open it, the
	box is stamped `LaidAt` too: the find comes out and lands on the floor beside the box, toward
	them, to take as any find is. Otherwise it goes into their hand (`Slots.give`) the moment the
	reveal brings it there (`Opening.handAt`, the grade's hold in it), or lands at that spot if
	their hands filled or they died in the meantime. Its coins are stamped with the open too
	(`Opening.Coins`) and go into the opener's count at once (`Coins:pay`, "box"): their screen
	holds the count until the coins it flies in from the box land in it, as with a pile.

	A note's box (B-04a) holds the code's note: stamped with the open (`Opening.Note`, its grade
	`Opening.NoteGrade`, a lighter reveal), it goes into the opener's pocket (`NoteCard.Held`, never
	a hand) as the paper reaches them, and their screen holds it up. A note's holder who leaves
	puts it back on its unit's back wall (FloorBuilder.stickNote), so the code is never lost; B-04b
	drops it where they were instead, and drops a caught player's too.

	Studio's Workspace `DevBox` deals the next unit any find or tool in one, whatever its size,
	to see every grade's reveal (Deals).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Coins = require(script.Parent.Coins)
local Floor = require(ReplicatedStorage.Shared.Floor)
local FloorBuilder = require(script.Parent.FloorBuilder)
local NoteCard = require(ReplicatedStorage.Shared.Elevator.NoteCard)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local Opening = Boxes.Opening

-- The button sits this far above the lid: over the box, where a thumb finds it.
local BUTTON_ABOVE = 0.4

export type Opened = {
	box: Model,
	unit: Model,
	player: Player,
	find: string?, -- the find's or tool's catalog key, nil for a box of coins alone
	coins: number, -- how many coins it held (0 to 3), paid to the opener
	note: string?, -- the code's note it held, its writing ("_ 7 _ _"), into the opener's pocket
}

-- The code's note a box holds (B-04a): its writing, and its unit's size and number, so it can go
-- back on the unit's back wall if its holder leaves.
export type Note = { text: string, size: Floor.Size, number: string }

export type MarkedBoxes = Brix.System & {
	-- Fires as a box is opened, after it's stamped (the find is given later, at `handAt`).
	opened: Brix.Signal<Opened>,
	-- Stands a shut marked box at `place` (the middle of its bottom on the floor, its printed side
	-- facing the place's LookVector) in unit `unit`, into the unit's hall piece, holding find or
	-- tool `find` (a catalog key) and `coins` coins (B-03b), or the code's note `note` (B-04a). Nil
	-- when the place lacks the template.
	stand: (
		self: any,
		unit: Model,
		place: CFrame,
		find: string?,
		coins: number?,
		note: Note?
	) -> Model?,
}

type Standing = {
	box: Model,
	unit: Model,
	button: Vector3,
	prompt: ProximityPrompt,
	find: string?,
	coins: number,
	note: Note?,
}

-- A note in a player's pocket, and the unit it came out of.
type Held = { note: Note, unit: Model }

-- Studs from the box's middle to where a find lands beside it (toward the opener): clear of the
-- box and its open flaps, still within a Take's reach.
local LAID_OUT = 1.9

type Rate = { last: number?, burst: number }

local MarkedBoxes = {}

function MarkedBoxes.new(): MarkedBoxes
	local standing: { [Model]: Standing } = {}
	local rates: { [Player]: Rate } = {}
	local connections: { RBXScriptConnection } = {}
	local opened = Brix.Signal.new() :: Brix.Signal<Opened>
	local slots: Slots.Slots? = nil
	local bank: Coins.CoinsSystem? = nil
	local stopped = false
	local pockets: { [Player]: { Held } } = {}

	-- Mirrors what `player` holds onto them, for their screen (NoteView).
	local function mirror(player: Player)
		local texts: { string } = {}
		local list = pockets[player]
		if list then
			for _, h in list do
				table.insert(texts, h.note.text)
			end
		end
		player:SetAttribute(NoteCard.Held, if #texts > 0 then NoteCard.pocket(texts) else nil)
	end

	-- A note goes back on its unit's back wall: its holder left (or was gone before it reached them).
	local function putBack(h: Held)
		if h.unit.Parent then
			FloorBuilder.stickNote(h.unit, h.note.size, h.note.number, h.note.text)
		end
	end

	-- The reveal has brought the note `h` to `player`: into their pocket, or back on its wall.
	local function pocket(player: Player, h: Held)
		if stopped then
			return
		end
		if not player.Parent then
			putBack(h)
			return
		end
		local list = pockets[player] or {}
		pockets[player] = list
		table.insert(list, h)
		mirror(player)
		-- the floor it came from goes (the climb moves on): it leaves the pocket with it
		local gone: RBXScriptConnection
		gone = h.unit.AncestryChanged:Connect(function()
			if h.unit:IsDescendantOf(game) then
				return
			end
			gone:Disconnect()
			local now = pockets[player]
			local at = if now then table.find(now, h) else nil
			if now and at then
				table.remove(now, at)
				mirror(player)
			end
		end)
	end

	-- Whether `player` has a free hand for a find: a slot free, and nothing two-handed held.
	local function room(player: Player): boolean
		local s = slots
		if not s then
			return false
		end
		local keys, hand = s:carried(player)
		local held = Tools.Catalog[keys[hand] or ""]
		return table.find(keys, "") ~= nil and not (held and held.bothHands)
	end

	-- Where a find lands beside the box, toward `from`, and the turn (degrees) that faces it there.
	local function besideBox(box: Model, from: Vector3): (Vector3, number)
		local pivot = box:GetPivot()
		local d = Vector3.new(from.X - pivot.X, 0, from.Z - pivot.Z)
		local dir = if d.Magnitude > 0.1 then d.Unit else pivot.LookVector
		return pivot.Position + dir * LAID_OUT, math.deg(math.atan2(-dir.X, -dir.Z))
	end

	-- The reveal has brought find `key` to `player`'s hand: into it, or onto the floor at `at`.
	local function grant(player: Player, key: string, laid: boolean, at: Vector3, yaw: number)
		local s = slots
		if stopped or not s then
			return
		end
		if not laid and player.Parent and s:give(player, key) then
			return
		end
		s:lay(key, at, yaw)
	end

	local function open(s: Standing, player: Player)
		-- type: Triggered hands us a Player. Range: a box still shut and standing, then the checks.
		if standing[s.box] ~= s or not s.box.Parent then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local alive = humanoid ~= nil
			and humanoid.Health > 0
			and root ~= nil
			and root:IsA("BasePart")
		local at = if alive and root and root:IsA("BasePart") then root.Position else s.button
		local refusal = Opening.refuse({
			opened = s.box:GetAttribute(Opening.OpenedAt) ~= nil,
			alive = alive,
			wrapped = Prompts.wrapped(player),
			distance = (at - s.button).Magnitude,
			apart = alive
				and s.unit:FindFirstChild("DoorOrigin", true) ~= nil
				and StorageUnit.RollUpDoor.keepsApart(s.unit, at, s.button),
		})
		if refusal then
			return -- nothing on any screen: each refusal is plain where the player stands
		end
		-- rate
		local rate = rates[player] or { last = nil, burst = 0 }
		local now = os.clock()
		local may, left = Opening.allow(rate.last, rate.burst, now)
		if not may then
			return
		end
		rates[player] = { last = now, burst = left }

		standing[s.box] = nil
		s.prompt.Enabled = false
		-- what's inside reaches screens only now, before the stamp, in the same batch
		local key = s.find
		local row = if key then Tools.Catalog[key] else nil
		local note = s.note
		local grade = if note and not key
			then Opening.NoteGrade
			elseif row and row.grade and Opening.Reveals[row.grade] then row.grade
			else "Common"
		local laid = key ~= nil and not room(player)
		local spot, yaw = besideBox(s.box, at)
		if key then
			s.box:SetAttribute(Opening.Find, key)
		end
		s.box:SetAttribute(Opening.Grade, grade)
		if laid then
			s.box:SetAttribute(Opening.LaidAt, spot)
		end
		if s.coins > 0 then
			s.box:SetAttribute(Opening.Coins, s.coins)
		end
		if note then
			s.box:SetAttribute(Opening.Note, note.text)
		end
		s.box:SetAttribute(Opening.OpenedBy, player.UserId)
		s.box:SetAttribute(Opening.OpenedAt, Workspace:GetServerTimeNow())
		local button = s.prompt.Parent
		s.prompt:Destroy()
		if button then
			button:Destroy()
		end
		-- the coins go in now, with the stamp: the opener's screen holds its count until the
		-- coins it flies in from the box land (CoinView)
		local b = bank
		if s.coins > 0 and b then
			b:pay(player, s.coins, "box")
		end
		if RunService:IsStudio() then
			local coinsSaid = if s.coins > 0 then ` and {s.coins} coins` else ""
			local noteSaid = if note then `, the note "{note.text}"` else ""
			print(
				`MarkedBoxes: {player.Name} opened the box in {s.unit.Name}: {key or "no find"}{noteSaid}{coinsSaid}`
			)
		end
		if note then
			task.delay(
				Opening.handAt(Opening.Reveals[grade].Hold),
				pocket,
				player,
				{ note = note, unit = s.unit }
			)
		end
		if key then
			task.delay(
				Opening.handAt(Opening.Reveals[grade].Hold),
				grant,
				player,
				key,
				laid,
				spot,
				yaw
			)
		end
		opened:fire({
			box = s.box,
			unit = s.unit,
			player = player,
			find = key,
			coins = s.coins,
			note = if note then note.text else nil,
		})
	end

	local system = { name = "MarkedBoxes", opened = opened }

	function system.stand(
		_: any,
		unit: Model,
		place: CFrame,
		find: string?,
		coins: number?,
		note: Note?
	): Model?
		-- set up out of the world, then parented once into the hall piece
		local box = Boxes.cloneMarked(place)
		if not box then
			return nil
		end
		local body = box.PrimaryPart :: BasePart
		local unitValue = Instance.new("ObjectValue")
		unitValue.Name = Opening.UnitValue
		unitValue.Value = unit
		unitValue.Parent = box
		local at = Instance.new("Attachment")
		at.Name = "Open"
		at.Parent = body
		local button = place.Position + Vector3.new(0, Boxes.Marked.Size.Y + BUTTON_ABOVE, 0)
		at.WorldPosition = button
		local prompt = Prompts.make(at, {
			actionText = "Open",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Opening.Reach,
		})
		-- low in a unit full of somebody's stuff: a box mustn't hide another's button (a shut door
		-- still stops a press, on the server and on screens)
		prompt.RequiresLineOfSight = false
		CollectionService:AddTag(box, Opening.Tag)

		local s: Standing = {
			box = box,
			unit = unit,
			button = button,
			prompt = prompt,
			find = find,
			coins = math.clamp(math.floor(coins or 0), 0, 3),
			note = note,
		}
		standing[box] = s
		prompt.Triggered:Connect(function(player: Player)
			open(s, player)
		end)
		box.Destroying:Once(function()
			if standing[box] == s then
				standing[box] = nil
			end
		end)
		box.Parent = unit.Parent or unit
		return box
	end

	function system.start(_: any, context: Brix.Context)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry is untyped
		bank = (context.registry:get("coins") :: any) :: Coins.CoinsSystem? -- any: the same
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				rates[player] = nil
				local held = pockets[player]
				pockets[player] = nil
				if held then
					for _, h in held do
						putBack(h)
					end
				end
			end)
		)
	end

	function system.stop(_: any)
		stopped = true
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(standing)
		table.clear(rates)
		table.clear(pockets)
		opened:disconnectAll()
	end

	return system
end

return MarkedBoxes
