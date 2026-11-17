--!strict
--[[
	JobBoxView: every home's job box on this screen (S5-03c2a, D-287). The server (JobBoxes) owns
	each box's attributes (JobBox.Tag on the piece); this draws them.

	- Something new in it (Fresh above 0): its lid sparkles, the shelf's warm gold twinkle spread
	  over the lid, so you see from the door that the box took what the shelf couldn't.
	- The lid (Lid): up, it swings open about its hinge, slow and eased, with a soft steel creak;
	  the sparkle bursts off it and stops; a kind you'd never owned chimes as well, for the opener.
	  Shut, it falls, gathering speed, and lands with a clunk and a little kick.

	- What's set out on the lid rides it (S5-03e3b): the moon lamp on top swings up with the lid as
	  you open the box and comes back down with it, landing with its clunk. The server always draws
	  them on the lid shut; each screen carries them round the hinge as it poses the lid, then
	  leaves them where the server put them once it's shut (and takes up any the server moves).
	  A lid with something on it stops where that would touch the wall behind (`JobBox.Behind`),
	  propped there with the knock of a find set down.

	Only lids in motion are stepped. A box streaming out takes its sparkle with it; streaming back
	in, its lid is posed where the server says, without a sound.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Home = require(ReplicatedStorage.Shared.Home)
local Save = require(ReplicatedStorage.Shared.Save)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local ShelfView = require(script.Parent.ShelfView)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)

local JobBox = Home.JobBox

-- The lid's top as Arrange names it (`Spots.Furniture`): what stands on it rides the lid.
local TOP = "JobBoxTop"
assert(Spots.Furniture[TOP], "the job box's top is an area finds stand on")

-- A find riding the lid: where the server drew it (on the lid shut), and where this screen last
-- put it (so a move by the server is noticed and taken up).
type Rider = { rest: CFrame, set: CFrame? }

type Shown = {
	model: Model,
	lid: BasePart,
	rest: CFrame, -- the lid shut
	hinge: CFrame, -- the hinge line's middle, square to the box
	angle: number, -- degrees up now
	from: number, -- degrees up as this swing began
	t: number, -- seconds into it
	opening: boolean,
	sparkle: ParticleEmitter?,
	changed: { RBXScriptConnection },
	riders: { [Model]: Rider },
	cap: number, -- degrees the lid may lift with what rides it, short of the wall
	propped: boolean, -- it reached the cap this swing (the knock played)
}

local JobBoxView = {}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function number(model: Model, name: string): number
	local v = model:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

-- Whether two frames stand alike (a pivot read back can differ by float dust from one set).
local function same(a: CFrame, b: CFrame): boolean
	return (a.Position - b.Position).Magnitude < 1e-3
		and a.LookVector:Dot(b.LookVector) > 0.99999
		and a.UpVector:Dot(b.UpVector) > 0.99999
end

-- The folder of what's set out in the home whose job box is `box` (Starter, then the unit).
local function placedBy(box: Model): Instance?
	local starter = box.Parent
	local unit = if starter then starter.Parent else nil
	return if unit then unit:FindFirstChild(Arrange.Folder) else nil
end

function JobBoxView.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local moving: { [Shown]: true } = {}
	local connections: { RBXScriptConnection } = {}

	-- Finds what stands on `s`'s lid, however high up (a lamp on a drum on the lid), keeping the
	-- ones already riding as they are; new ones ride from where the server drew them.
	local function gather(s: Shown)
		local folder = placedBy(s.model)
		local on: { [string]: { Model } } = {}
		if folder then
			for _, m in folder:GetChildren() do
				local under = m:GetAttribute(Arrange.OnAttribute)
				if m:IsA("Model") and type(under) == "string" then
					local list = on[under] or {}
					on[under] = list
					table.insert(list, m)
				end
			end
		end
		local ride: { [Model]: boolean } = {}
		local function take(base: string, depth: number)
			local standing = on[base]
			if not standing then
				return
			end
			for _, m in standing do
				local id = m:GetAttribute(Spots.IdAttribute)
				if not ride[m] and depth < 32 then
					ride[m] = true
					if type(id) == "string" then
						take(id, depth + 1)
					end
				end
			end
		end
		take(TOP, 0)
		for m in s.riders do
			if not ride[m] then
				s.riders[m] = nil
			end
		end
		for m in ride do
			if not s.riders[m] then
				s.riders[m] = { rest = m:GetPivot(), set = nil }
			end
		end
		-- the lid lifts until a rider's corner would pass `Behind` the hinge (turned about the
		-- hinge's X, a point (y, z) in its frame goes back to y sin + z cos)
		local cap = JobBox.Lid.Lift
		local hinge = s.hinge:Inverse()
		for m, r in s.riders do
			local set = r.set
			local back = if set then r.rest * set:Inverse() else CFrame.identity -- to where it rests
			for _, p in m:GetDescendants() do
				if not p:IsA("BasePart") then
					continue
				end
				local c, h = hinge * back * p.CFrame, p.Size / 2
				for corner = 0, 7 do
					local q = c
						* Vector3.new(
							if corner % 2 == 0 then -h.X else h.X,
							if corner // 2 % 2 == 0 then -h.Y else h.Y,
							if corner // 4 == 0 then -h.Z else h.Z
						)
					for a = 1, cap do
						local rad = math.rad(a)
						if q.Y * math.sin(rad) + q.Z * math.cos(rad) > JobBox.Behind then
							cap = a - 1
							break
						end
					end
				end
			end
		end
		s.cap = cap
	end

	local function pose(s: Shown)
		local hinge = s.hinge
		local turn = hinge * CFrame.Angles(math.rad(s.angle), 0, 0) * hinge:Inverse()
		s.lid.CFrame = turn * s.rest
		for m, r in s.riders do
			if not m.Parent then
				s.riders[m] = nil -- streamed out or put away
				continue
			end
			local now = m:GetPivot()
			local set = r.set
			if set and not same(now, set) then
				r.rest = now -- the server moved it (it draws on the lid shut): ride from there
			end
			local target = turn * r.rest
			if not same(target, now) then
				m:PivotTo(target)
			end
			r.set = target
		end
	end

	local function stopSparkle(s: Shown, burst: boolean)
		local p = s.sparkle
		if not p then
			return
		end
		s.sparkle = nil
		if burst then
			p.Speed = NumberRange.new(2, 4.5)
			p.Drag = 4
			p.Lifetime = NumberRange.new(0.4, 0.7)
			p:Emit(JobBox.Sparkle.Burst)
		end
		p.Rate = 0
		task.delay(1.2, function()
			p:Destroy()
		end)
	end

	-- Sparkles the lid while something new is in the box and it's shut.
	local function follow(s: Shown)
		local fresh = number(s.model, JobBox.FreshAttribute)
		local up = number(s.model, JobBox.LidAttribute) > 0
		if fresh == Save.Fresh.Seen or up then
			stopSparkle(s, false)
		elseif not s.sparkle then
			local p = ShelfView.sparkle(s.lid)
			p.Name = "JobBoxSparkle"
			p.Rate = JobBox.Sparkle.Rate
			p.Shape = Enum.ParticleEmitterShape.Box
			p.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			p.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
			s.sparkle = p
		end
	end

	-- The lid's attribute changed: swing it, with its sounds (`quiet`: just pose it, as it streams in).
	local function swing(s: Shown, quiet: boolean)
		local lid = number(s.model, JobBox.LidAttribute)
		local opening = lid > 0
		if quiet then
			s.angle = if opening then JobBox.Lid.Lift else 0
			s.opening = opening
			if opening then
				gather(s) -- streaming in open: what's on top goes up with it
				s.angle = math.min(s.angle, s.cap)
			end
			pose(s)
			return
		end
		if opening == s.opening then
			return -- already going that way
		end
		s.opening = opening
		s.from = s.angle
		s.t = 0
		s.propped = false
		moving[s] = true
		gather(s)
		if opening then
			Tools.play(JobBox.Creak, s.lid, JobBox.Hearing)
			stopSparkle(s, true)
			if lid - 1 == Save.Fresh.Kind then
				Tools.play(Shelf.Chime, s.lid, Shelf.Hearing)
			end
		else
			local lands = JobBox.landing(s.from)
			task.delay(math.max(0, lands - JobBox.Hit), function()
				if shown[s.model] == s and not s.opening then
					Tools.play(JobBox.Clunk, s.lid, JobBox.Hearing)
				end
			end)
		end
		follow(s)
	end

	local function add(inst: Instance)
		if shown[inst :: any] or not (inst:IsA("Model") and inst.Parent) then -- any: a tagged Instance
			return
		end
		local model = inst :: Model
		local lid = model:FindFirstChild("JobBoxLid")
		if not (lid and lid:IsA("BasePart")) then
			return
		end
		local pivot = model.WorldPivot
		local s: Shown = {
			model = model,
			lid = lid,
			rest = pivot * CFrame.new(vec(Home.Specs.Parts.JobBoxLid.Centre)),
			hinge = pivot * CFrame.new(vec(Home.Specs.JobBox.Hinge)),
			angle = 0,
			from = 0,
			t = 0,
			opening = false,
			sparkle = nil,
			changed = {},
			riders = {},
			cap = JobBox.Lid.Lift,
			propped = false,
		}
		s.changed = {
			model:GetAttributeChangedSignal(JobBox.FreshAttribute):Connect(function()
				if shown[model] == s then
					follow(s)
				end
			end),
			model:GetAttributeChangedSignal(JobBox.LidAttribute):Connect(function()
				if shown[model] == s then
					swing(s, false)
				end
			end),
		}
		shown[model] = s
		swing(s, true)
		follow(s)
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if not s then
			return
		end
		shown[s.model] = nil
		moving[s] = nil
		table.clear(s.riders)
		for _, c in s.changed do
			c:Disconnect()
		end
		stopSparkle(s, false)
	end

	return {
		name = "JobBoxView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { JobBox.Creak.id, JobBox.Clunk.id })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(JobBox.Tag):Connect(function(inst)
					-- deferred so a box streaming in has its lid before it's looked for
					task.defer(add, inst)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(JobBox.Tag):Connect(remove)
			)
			-- a find set out (or streaming in) while a lid stands open goes up on it if it's on top
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Spots.Tag):Connect(function(inst)
					task.defer(function()
						for _, s in shown do
							if s.angle > 0 and inst.Parent == placedBy(s.model) then
								gather(s)
								s.angle = math.min(s.angle, s.cap)
								pose(s)
							end
						end
					end)
				end)
			)
			for _, inst in CollectionService:GetTagged(JobBox.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			for s in moving do
				if not s.lid.Parent then
					moving[s] = nil
					continue
				end
				s.t += dt
				local angle, done = JobBox.angle(s.opening, s.from, s.t)
				if s.opening and angle >= s.cap then
					angle = s.cap -- propped on what rides it, against the wall
					if not s.propped and next(s.riders) then
						s.propped = true
						Tools.play(Arrange.Knock, s.lid, JobBox.Hearing)
					end
				end
				s.angle = angle
				pose(s)
				if done then
					moving[s] = nil
					if not s.opening then
						table.clear(s.riders) -- shut: they stand where the server drew them
					end
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in shown do
				remove(model)
			end
		end,
	}
end

return JobBoxView
