--!strict
--[[
	JobBoxView: every home's job box on this screen (S5-03c2a, D-287). The server (JobBoxes) owns
	each box's attributes (JobBox.Tag on the piece); this draws them.

	- Something new in it (Fresh above 0): its lid sparkles, the shelf's warm gold twinkle spread
	  over the lid, so you see from the door that the box took what the shelf couldn't.
	- The lid (Lid): up, it swings open about its hinge, slow and eased, with a soft steel creak;
	  the sparkle bursts off it and stops; a kind you'd never owned chimes as well, for the opener.
	  Shut, it falls, gathering speed, and lands with a clunk and a little kick.

	Only lids in motion are stepped. A box streaming out takes its sparkle with it; streaming back
	in, its lid is posed where the server says, without a sound.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Save = require(ReplicatedStorage.Shared.Save)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local ShelfView = require(script.Parent.ShelfView)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

local JobBox = Home.JobBox

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
}

local JobBoxView = {}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function number(model: Model, name: string): number
	local v = model:GetAttribute(name)
	return if type(v) == "number" then v else 0
end

function JobBoxView.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local moving: { [Shown]: true } = {}
	local connections: { RBXScriptConnection } = {}

	local function pose(s: Shown)
		local hinge = s.hinge
		s.lid.CFrame = hinge * CFrame.Angles(math.rad(s.angle), 0, 0) * hinge:Inverse() * s.rest
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
			pose(s)
			return
		end
		if opening == s.opening then
			return -- already going that way
		end
		s.opening = opening
		s.from = s.angle
		s.t = 0
		moving[s] = true
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
				s.angle = angle
				pose(s)
				if done then
					moving[s] = nil
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
