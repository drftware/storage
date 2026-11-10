--!strict
--[[
	Wraps: laying the bubble wrap on the server (L-14b2a, D-090), a system. A Lay comes in as
	`Slots.used` (a living player with the roll in hand, the press's rate already checked); here
	where they stand must be a hall of a place `add` was given (a laid floor, the test hall), found
	by `Wrap.place`. Then the roll is spent from their hand (`Slots:spend`) and one sheet
	(`Props.BubbleSheet`) laid square across the hall just ahead of their toes, stamped with the
	server's clock (`Wrap.LaidAttribute`) and tagged (`Wrap.Tag`), so every screen unrolls it
	(`WrapView`). Refused, their screen says the fix (`Wrap.NotHere`) on Slots' short line.
	The pops when something crosses it are L-14b2b's.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)

local SHEETS = "BubbleWrap" -- the folder in each place's model the sheets are laid in
local SHEET_TEMPLATE = "BubbleSheet" -- under ReplicatedStorage.Props

-- A place sheets may be laid in: its halls in its own coordinates, and where those are.
type Area = { halls: { Wrap.Hall }, model: Instance, origin: CFrame, folder: Folder? }

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
	local warned = false

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
		if RunService:IsStudio() then
			local w = laid:GetPivot().Position
			print(
				`Wraps: {player.Name} laid bubble wrap across the hall at ({math.round(w.X)}, {math.round(
					w.Z
				)})`
			)
		end
	end

	local system = { name = "Wraps" }

	function system.add(_: any, halls: { Wrap.Hall }, model: Instance, origin: CFrame)
		if gone[model] then
			return
		end
		local area: Area = { halls = halls, model = model, origin = origin }
		table.insert(areas, area)
		gone[model] = model.Destroying:Connect(function()
			local i = table.find(areas, area)
			if i then
				table.remove(areas, i)
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
	end

	return system :: any -- any: a plain Brix system built field by field
end

return Wraps
