--!strict
--[[
	Wraps: laying the bubble wrap on the server (L-14b2a, D-090), a system. A Lay comes in as
	`Slots.used` (a living player with the roll in hand, the press's rate already checked); here
	where they stand must be a hall of a place `add` was given (a laid floor, the test hall), found
	by `Wrap.place`. Then the roll is spent from their hand (`Slots:spend`) and one sheet
	(`Props.BubbleSheet`) laid square across the hall just ahead of their toes, stamped with the
	server's clock (`Wrap.LaidAttribute`) and tagged (`Wrap.Tag`), so every screen unrolls it
	(`WrapView`). Refused, their screen says the fix (`Wrap.NotHere`) on Slots' short line.

	The pops (L-14b2b): each step, while any sheet lies unpopped, every living player's feet (their
	root, down to the floor) and every keeper's (`Keepers:feet`) are checked against the sheets,
	from where they were last step to where they are (`Wrap.crosses`). A crossing pops that sheet
	once: it's stamped (`Wrap.PoppedAttribute`), so every screen plays the pops and flattens it,
	and every keeper on the floor hears it as far as an opened door (`Keepers:hear`, `Wrap.Reach`).
	A popped sheet stays, flat and silent.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Keepers = require(script.Parent.Keepers)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)

local SHEETS = "BubbleWrap" -- the folder in each place's model the sheets are laid in
local SHEET_TEMPLATE = "BubbleSheet" -- under ReplicatedStorage.Props

-- A sheet laid in a place: where it lies (the place's coordinates), its model, whether it's popped.
type Laid = { sheet: Wrap.Sheet, model: Model, popped: boolean }
-- A place sheets may be laid in: its halls in its own coordinates, and where those are; the
-- sheets laid there, and how many of them are still unpopped.
type Area = {
	halls: { Wrap.Hall },
	model: Instance,
	origin: CFrame,
	folder: Folder?,
	laid: { Laid },
	live: number,
}

export type Wraps = Brix.System & {
	-- Lets sheets be laid in `halls` (`Wrap.halls` of a floor, or a hand-built hall's), in the
	-- coordinates of `origin`, laid into `model`, until `model` is destroyed.
	add: (self: any, halls: { Wrap.Hall }, model: Instance, origin: CFrame) -> (),
}

local Wraps = {}

function Wraps.new(): Wraps
	local connections: { Brix.SignalConnection } = {}
	local areas: { Area } = {}
	local gone: { [Instance]: RBXScriptConnection } = {}
	local slots: Slots.Slots? = nil
	local keepers: Keepers.Keepers? = nil
	local warned = false
	-- The pops: how many sheets lie unpopped anywhere (none: nothing is checked), where each
	-- living player's and keeper's feet were last step (the world's), and the players, kept as they
	-- come and go so no list is made each step.
	local live = 0
	local lastPlayer: { [Player]: Vector3 } = {}
	local lastKeeper: { [Model]: Vector3 } = {}
	local seen: { [Model]: number } = {} -- each keeper body, the step it was last seen
	local stepNo = 0
	local everyone: { Player } = {}
	local joins: { RBXScriptConnection } = {}

	local function tell(player: Player, text: string)
		local folder = ReplicatedStorage:FindFirstChild(Tools.RemoteFolder)
		local notice = folder and folder:FindFirstChild(Tools.NoticeRemote)
		if notice and notice:IsA("RemoteEvent") then
			notice:FireClient(player, text)
		end
	end

	local function template(): Model?
		local props = ReplicatedStorage:FindFirstChild("Props")
		local t = props and props:FindFirstChild(SHEET_TEMPLATE)
		if t and t:IsA("Model") then
			return t
		end
		if not warned then
			warned = true
			warn(
				`Wraps: no ReplicatedStorage.Props.{SHEET_TEMPLATE}, so bubble wrap lays nothing; import it (art/bubblewrap/README.md)`
			)
		end
		return nil
	end

	local function onUsed(use: Slots.Use)
		if use.key ~= Wrap.Key then
			return
		end
		local player = use.player
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local sheet = template()
		if not sheet then
			return
		end
		-- the first place whose halls they stand in; facing as their character does (the server
		-- sees a turn a moment late, D-084: the sheet still lies square across the hall)
		local found: Area? = nil
		local point: vector? = nil
		local across: vector? = nil
		for _, area in areas do
			local p = area.origin:PointToObjectSpace(root.Position)
			local f = area.origin:VectorToObjectSpace(root.CFrame.LookVector)
			local at, a =
				Wrap.place(area.halls, vector.create(p.X, p.Y, p.Z), vector.create(f.X, f.Y, f.Z))
			if at and a then
				found, point, across = area, at, a
				break
			end
		end
		if not (found and point and across) then
			tell(player, Wrap.NotHere)
			return
		end
		local s = slots
		if not (s and s:spend(player, Wrap.Key)) then
			return
		end
		local folder = found.folder
		if not (folder and folder.Parent) then
			local f = Instance.new("Folder")
			f.Name = SHEETS
			f.Parent = found.model
			found.folder = f
			folder = f
		end
		local laid = sheet:Clone()
		local frame = CFrame.fromMatrix(
			Vector3.new(point.x, point.y, point.z),
			Vector3.new(across.x, across.y, across.z),
			Vector3.yAxis
		)
		laid:PivotTo(found.origin * frame)
		laid:SetAttribute(Wrap.LaidAttribute, Workspace:GetServerTimeNow())
		CollectionService:AddTag(laid, Wrap.Tag)
		laid.Parent = folder
		table.insert(found.laid, {
			sheet = { at = point, across = across },
			model = laid,
			popped = false,
		})
		found.live += 1
		live += 1
		if RunService:IsStudio() then
			local w = laid:GetPivot().Position
			print(
				`Wraps: {player.Name} laid bubble wrap across the hall at ({math.round(w.X)}, {math.round(
					w.Z
				)})`
			)
		end
	end

	-- `who` (a name for Output) popped `l` in `area`: stamped for every screen, and heard.
	local function pop(area: Area, l: Laid, who: string)
		l.popped = true
		area.live -= 1
		live -= 1
		if not l.model.Parent then
			return -- cleared away: nothing to hear
		end
		l.model:SetAttribute(Wrap.PoppedAttribute, Workspace:GetServerTimeNow())
		local at = area.origin:PointToWorldSpace((l.sheet.at :: any) :: Vector3) -- any: a vector
		local heard = if keepers then keepers:hear(at, Wrap.Reach, "bubble wrap pop") else 0
		if RunService:IsStudio() then
			print(
				`Wraps: {who} popped the bubble wrap at ({math.round(at.X)}, {math.round(at.Z)}); {heard} keeper(s) heard it`
			)
		end
	end

	-- Feet that stepped from `from` to `to` (the world's): every unpopped sheet they crossed pops.
	local function stepped(who: string, from: Vector3, to: Vector3)
		for _, area in areas do
			if area.live <= 0 then
				continue
			end
			local f = area.origin:PointToObjectSpace(from)
			local t = area.origin:PointToObjectSpace(to)
			local fv, tv = vector.create(f.X, f.Y, f.Z), vector.create(t.X, t.Y, t.Z)
			for _, l in area.laid do
				if not l.popped and Wrap.crosses(l.sheet, fv, tv) then
					pop(area, l, who)
				end
			end
		end
	end

	-- A keeper's feet this step (Keepers:feet), made once.
	local function onKeeperFeet(body: Model, at: Vector3)
		seen[body] = stepNo
		local was = lastKeeper[body]
		lastKeeper[body] = at
		if was then
			local row = body:GetAttribute("Keeper")
			stepped(if type(row) == "string" then `the {row}` else body.Name, was, at)
		end
	end

	local system = { name = "Wraps" }

	function system.add(_: any, halls: { Wrap.Hall }, model: Instance, origin: CFrame)
		if gone[model] then
			return
		end
		local area: Area = { halls = halls, model = model, origin = origin, laid = {}, live = 0 }
		table.insert(areas, area)
		gone[model] = model.Destroying:Connect(function()
			local i = table.find(areas, area)
			if i then
				table.remove(areas, i)
				live -= area.live
				area.live = 0
			end
			local c = gone[model]
			if c then
				c:Disconnect()
				gone[model] = nil
			end
		end)
	end

	function system.start(_: any, context: Brix.Context)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry's
		local s = slots
		if s then
			table.insert(connections, s.used:connect(onUsed))
		else
			warn("Wraps: no Slots system, so nobody can lay bubble wrap")
		end
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers? -- any: as above
		for _, p in Players:GetPlayers() do
			table.insert(everyone, p)
		end
		table.insert(
			joins,
			Players.PlayerAdded:Connect(function(p: Player)
				table.insert(everyone, p)
			end)
		)
		table.insert(
			joins,
			Players.PlayerRemoving:Connect(function(p: Player)
				local i = table.find(everyone, p)
				if i then
					table.remove(everyone, i)
				end
				lastPlayer[p] = nil
			end)
		)
	end

	-- Only while a sheet lies unpopped: everyone's feet, last step's to this step's.
	function system.step(_: any, _dt: number)
		if live <= 0 then
			-- nothing to pop: forget where feet were, so a sheet laid later checks fresh steps only
			if next(lastPlayer) or next(lastKeeper) then
				table.clear(lastPlayer)
				table.clear(lastKeeper)
				table.clear(seen)
			end
			return
		end
		stepNo += 1
		for _, player in everyone do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local feet = root.Position - Vector3.yAxis * (humanoid.HipHeight + root.Size.Y / 2)
				local was = lastPlayer[player]
				lastPlayer[player] = feet
				if was then
					stepped(player.Name, was, feet)
				end
			else
				lastPlayer[player] = nil
			end
		end
		local k = keepers
		if k then
			k:feet(onKeeperFeet)
			for body, n in seen do
				if n ~= stepNo then -- gone from its floor
					seen[body] = nil
					lastKeeper[body] = nil
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in gone do
			c:Disconnect()
		end
		table.clear(gone)
		table.clear(areas)
		for _, c in joins do
			c:Disconnect()
		end
		table.clear(joins)
		table.clear(everyone)
		table.clear(lastPlayer)
		table.clear(lastKeeper)
		table.clear(seen)
		live = 0
	end

	return system :: any -- any: a plain Brix system built field by field
end

return Wraps
