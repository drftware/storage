--!strict
--[[
	Client system: the bubble wrap laid, on this screen (L-14b2a, D-090).

	Yours: Lay (HornView's round button, a click or L2, as for any tool with a verb) brings the roll
	out ahead and down in your view (ToolView's `use`); the server decides and lays the sheet, or
	your screen says "Lay it in a hall".

	Everyone's: a sheet the server has just laid (`Wrap.LaidAttribute`, tagged `Wrap.Tag`) unrolls
	across the hall from the layer's left: a roll rolls over the floor, thinning as it goes, the
	sheet laid out behind it, then the spent core sinks away; a crinkle plays at the sheet. A sheet
	first seen long after it was laid (streamed in late) just lies there.

	The pops (L-14b2b): a sheet the server has just popped (`Wrap.PoppedAttribute`) bursts at
	the sheet, as loud and as far as keepers hear it, and goes flat: its bubbles squash and its
	film dulls, fast then settling. Under your feet, your view jolts. Popped mid-unroll, it
	flattens as it unrolls. A sheet first seen long after it popped just lies flat.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Specs = require(ReplicatedStorage.Shared.Tools.Specs.BubbleWrap)
local ToolView = require(script.Parent.ToolView)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)

-- A sheet on this screen while it moves: its part's laid size and place; unrolling, the roll
-- crossing it and when that started (os.clock); popped, when it started going flat, and its look.
type Moving = {
	part: BasePart,
	size: Vector3,
	frame: CFrame,
	roll: BasePart?,
	laid: number?,
	popped: number?,
	look: SurfaceAppearance?,
}

local TINT = Color3.new(Wrap.Tint.r, Wrap.Tint.g, Wrap.Tint.b)
local WHITE = Color3.new(1, 1, 1)

local WrapView = {}

-- The roll's body to roll across a sheet: a loose copy, touching and casting nothing.
local function rollCopy(): BasePart?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local tools = props and props:FindFirstChild("Tools")
	local t = tools and tools:FindFirstChild(Wrap.Key)
	local body = if t and t:IsA("Model") then Tools.body(t) else nil
	if not body then
		return nil
	end
	local p = body:Clone()
	p:ClearAllChildren()
	local look = body:FindFirstChildOfClass("SurfaceAppearance")
	if look then
		look:Clone().Parent = p
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Name = "Unrolling"
	return p
end

--- The system, and your press: called as you press Lay (HornView), true if it went out. `kick`
--- jolts your view (CameraShake).
function WrapView.new(
	hand: ToolView.Hand,
	kick: (amount: number) -> ()
): (Brix.System, () -> boolean)
	local connections: { RBXScriptConnection } = {}
	local moving: { Moving } = {}
	local byPart: { [BasePart]: Moving } = {}
	local watching: { [Instance]: RBXScriptConnection } = {} -- each sheet's Popped, while it's here
	local flat: { [BasePart]: true } = {} -- sheets this screen has popped: once each

	local function lay(): boolean
		hand.use(Wrap.Down)
		return true
	end

	-- The record for `part` moving, made from where it lies now if it isn't moving yet.
	local function record(part: BasePart): Moving
		local m = byPart[part]
		if m then
			return m
		end
		local made: Moving = { part = part, size = part.Size, frame = part.CFrame }
		byPart[part] = made
		table.insert(moving, made)
		return made
	end

	-- Whether your feet are on the sheet laid as `m` (the world's: a sheet turns about Y only).
	local function underYou(m: Moving): boolean
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid) then
			return false
		end
		local feet = root.Position - Vector3.yAxis * (humanoid.HipHeight + root.Size.Y / 2)
		local floor = m.frame.Position - m.frame.UpVector * (m.size.Y / 2)
		local across = m.frame.RightVector
		return Wrap.on({
			at = vector.create(floor.X, floor.Y, floor.Z),
			across = vector.create(across.X, 0, across.Z),
		}, vector.create(feet.X, feet.Y, feet.Z))
	end

	local function onPopped(model: Model)
		local part = Tools.body(model)
		local popped = model:GetAttribute(Wrap.PoppedAttribute)
		if not part or type(popped) ~= "number" or flat[part] then
			return
		end
		flat[part] = true
		local late = Workspace:GetServerTimeNow() - popped
		local m = record(part)
		-- its look's tint, if a script may set it (untested in Play, docs/STUDIO.md): else it
		-- only squashes
		local look = part:FindFirstChildOfClass("SurfaceAppearance")
		if look and pcall(function()
			look.Color = WHITE
		end) then
			m.look = look
		end
		if late > Wrap.Fresh then
			m.popped = -math.huge -- long ago: it just lies flat
			return
		end
		m.popped = os.clock() - math.max(0, late)
		Tools.play(Wrap.Pops, part, Wrap.Reach)
		if underYou(m) then
			kick(Wrap.Kick)
		end
	end

	local function onSheet(model: Instance)
		if not model:IsA("Model") or watching[model] then
			return
		end
		local part = Tools.body(model)
		if not part then
			return
		end
		watching[model] = model:GetAttributeChangedSignal(Wrap.PoppedAttribute):Connect(function()
			onPopped(model)
		end)
		local laid = model:GetAttribute(Wrap.LaidAttribute)
		local late = if type(laid) == "number"
			then Workspace:GetServerTimeNow() - laid
			else math.huge
		if late <= Wrap.Fresh then
			local snd = Tools.sound(Wrap.Crinkle, part, Wrap.Heard)
			snd:Play()
			task.delay(Wrap.Crinkle.length / (Wrap.Crinkle.pitch or 1) + 0.5, function()
				snd:Destroy()
			end)
			local roll = rollCopy()
			if roll then
				roll.Parent = Workspace
			end
			local m = record(part)
			m.roll = roll
			m.laid = os.clock() - math.max(0, late)
			part.Size = Vector3.new(0.05, m.size.Y, m.size.Z)
		end
		onPopped(model)
	end

	local function onSheetGone(model: Instance)
		local c = watching[model]
		if c then
			c:Disconnect()
			watching[model] = nil
		end
		local part = if model:IsA("Model") then Tools.body(model) else nil
		if part then
			flat[part] = nil
		end
	end

	-- `m` at `now`: unrolling, the sheet out to under the roll, the roll on the floor rolling and
	-- thinning, then the core sinking away; popped, its bubbles squashing and its film dulling.
	-- Whether it's done moving.
	local function pose(m: Moving, now: number): boolean
		local len = m.size.X
		local out = len
		local done = true
		local laid = m.laid
		if laid then
			local t = now - laid
			local w = math.clamp(t / Wrap.Unroll, 0, 1)
			w = 1 - (1 - w) * (1 - w) -- a pushed roll slowing as it goes
			local r = Specs.Radius * (1 - (1 - Wrap.Core) * w)
			local x = -len / 2 + r + (len - 2 * r) * w -- the roll's middle across the sheet
			if w < 1 then
				out = math.clamp(x + len / 2, 0.05, len)
			end
			local gone = math.clamp((t - Wrap.Unroll) / Wrap.Gone, 0, 1)
			local roll = m.roll
			if roll then
				local k = r / Specs.Radius
				roll.Size =
					Vector3.new(Specs.Body.Size.X, Specs.Body.Size.Y * k, Specs.Body.Size.Z * k)
				-- along the sheet's Z (the hall), on the floor under it, turning as it rolls
				local floor = m.frame * CFrame.new(0, -m.size.Y / 2 + 0.01, 0)
				roll.CFrame = floor
					* CFrame.new(x, r - gone * r * 1.2, 0)
					* CFrame.Angles(0, math.pi / 2, 0)
					* CFrame.Angles((x + len / 2) / Specs.Radius, 0, 0)
				roll.Transparency = gone
			end
			done = gone >= 1
		end
		local height = m.size.Y
		local popped = m.popped
		if popped then
			local f = math.clamp((now - popped) / Wrap.Flatten, 0, 1)
			f = 1 - (1 - f) ^ 3 -- squashed at once, then settling
			height = m.size.Y * (1 - (1 - Wrap.Flat) * f)
			local look = m.look
			if look then
				look.Color = WHITE:Lerp(TINT, f)
			end
			done = done and f >= 1
		end
		m.part.Size = Vector3.new(out, height, m.size.Z)
		-- grown from its left edge, and squashed down onto the floor
		m.part.CFrame = m.frame * CFrame.new(-len / 2 + out / 2, (height - m.size.Y) / 2, 0)
		return done
	end

	local system = { name = "WrapView" }

	function system.start(_: any, _context: Brix.Context)
		task.spawn(SoundPrimer.prime, { Wrap.Pops.id, Wrap.Crinkle.id })
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Wrap.Tag):Connect(onSheet)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Wrap.Tag):Connect(onSheetGone)
		)
		for _, m in CollectionService:GetTagged(Wrap.Tag) do
			onSheet(m)
		end
	end

	function system.step(_: any, _dt: number)
		if #moving == 0 then
			return
		end
		local now = os.clock()
		for i = #moving, 1, -1 do
			local m = moving[i]
			if not m.part.Parent or pose(m, now) then
				if m.roll then
					m.roll:Destroy()
				end
				byPart[m.part] = nil
				moving[i] = moving[#moving]
				moving[#moving] = nil
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, c in watching do
			c:Disconnect()
		end
		table.clear(watching)
		for _, m in moving do
			if m.roll then
				m.roll:Destroy()
			end
		end
		table.clear(moving)
		table.clear(byPart)
		table.clear(flat)
	end

	return system :: any, lay -- any: a plain Brix system built field by field
end

return WrapView
