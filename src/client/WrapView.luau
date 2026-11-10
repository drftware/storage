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
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Specs = require(ReplicatedStorage.Shared.Tools.Specs.BubbleWrap)
local ToolView = require(script.Parent.ToolView)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)

-- A sheet unrolling: its part's laid size and place, the roll crossing it, when it started.
type Unroll = { part: BasePart, size: Vector3, frame: CFrame, roll: BasePart?, since: number }

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

--- The system, and your press: called as you press Lay (HornView), true if it went out.
function WrapView.new(hand: ToolView.Hand): (Brix.System, () -> boolean)
	local connections: { RBXScriptConnection } = {}
	local unrolls: { Unroll } = {}

	local function lay(): boolean
		hand.use(Wrap.Down)
		return true
	end

	local function onSheet(model: Instance)
		if not model:IsA("Model") then
			return
		end
		local laid = model:GetAttribute(Wrap.LaidAttribute)
		local late = if type(laid) == "number"
			then Workspace:GetServerTimeNow() - laid
			else math.huge
		local part = Tools.body(model)
		if not part or late > Wrap.Fresh then
			return
		end
		local snd = Tools.sound(Wrap.Crinkle, part, Wrap.Heard)
		snd:Play()
		task.delay(Wrap.Crinkle.length / (Wrap.Crinkle.pitch or 1) + 0.5, function()
			snd:Destroy()
		end)
		local roll = rollCopy()
		if roll then
			roll.Parent = Workspace
		end
		local u: Unroll = {
			part = part,
			size = part.Size,
			frame = part.CFrame,
			roll = roll,
			since = os.clock() - math.max(0, late),
		}
		table.insert(unrolls, u)
		part.Size = Vector3.new(0.05, u.size.Y, u.size.Z)
	end

	-- `u`, `t` seconds in: the sheet out to under the roll, the roll on the floor rolling and
	-- thinning, then the core sinking away. Whether it's done.
	local function pose(u: Unroll, t: number): boolean
		local len = u.size.X
		local w = math.clamp(t / Wrap.Unroll, 0, 1)
		w = 1 - (1 - w) * (1 - w) -- a pushed roll slowing as it goes
		local r = Specs.Radius * (1 - (1 - Wrap.Core) * w)
		local x = -len / 2 + r + (len - 2 * r) * w -- the roll's middle across the sheet
		local out = math.clamp(x + len / 2, 0.05, len)
		if w >= 1 then
			out = len
		end
		u.part.Size = Vector3.new(out, u.size.Y, u.size.Z)
		u.part.CFrame = u.frame * CFrame.new(-len / 2 + out / 2, 0, 0)
		local roll = u.roll
		local gone = math.clamp((t - Wrap.Unroll) / Wrap.Gone, 0, 1)
		if roll then
			local k = r / Specs.Radius
			roll.Size = Vector3.new(Specs.Body.Size.X, Specs.Body.Size.Y * k, Specs.Body.Size.Z * k)
			-- along the sheet's Z (the hall), on the floor under the sheet's frame, turning as it rolls
			local floor = u.frame * CFrame.new(0, -u.size.Y / 2 + 0.01, 0)
			roll.CFrame = floor
				* CFrame.new(x, r - gone * r * 1.2, 0)
				* CFrame.Angles(0, math.pi / 2, 0)
				* CFrame.Angles((x + len / 2) / Specs.Radius, 0, 0)
			roll.Transparency = gone
		end
		return gone >= 1
	end

	local system = { name = "WrapView" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Wrap.Tag):Connect(onSheet)
		)
		for _, m in CollectionService:GetTagged(Wrap.Tag) do
			onSheet(m)
		end
	end

	function system.step(_: any, _dt: number)
		if #unrolls == 0 then
			return
		end
		local now = os.clock()
		for i = #unrolls, 1, -1 do
			local u = unrolls[i]
			if not u.part.Parent or pose(u, now - u.since) then
				if u.part.Parent then
					u.part.Size = u.size
					u.part.CFrame = u.frame
				end
				if u.roll then
					u.roll:Destroy()
				end
				table.remove(unrolls, i)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, u in unrolls do
			if u.roll then
				u.roll:Destroy()
			end
		end
		table.clear(unrolls)
	end

	return system :: any, lay -- any: a plain Brix system built field by field
end

return WrapView
