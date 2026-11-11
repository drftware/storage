--!strict
--[[
	HallLights: draws the building's motion lights on this player's screen. The server decides
	each fixture's state (MotionLights) and replicates only that, on the fixture's model; this
	turns each change into what you see and hear (GDD "Lights"):

	- It trips: the sensor's eye flares hot and settles to a hard red, its relay clicks, and the
	  tube flickers on as its starter catches (HallLight.Flicker), then the dust drifts under it.
	- It falls dark: the tube cuts out, the relay lets go with a softer click, and the eye sinks
	  back to a dim red, watching.
	- Its power is cut: tube and eye die together, with no click (the relay has no power either).

	Your own lights follow you with no wait: this screen runs the same rules on your own character
	(a MotionLight watch of its own) and shows a fixture lit as soon as either it or the server
	says so; the server's word alone decides when it goes dark or blind, and it alone is what the
	building sees (D-025). Other players' and keepers' lights come from the server.

	Only the lit fixtures nearest the view throw real light (HallLight.NearFixtures, each two
	lights, D-017), measured from a point ahead of the camera so the light you're walking into wins
	over the one behind you; one farther out is its glowing tube alone, the GDD's glow. A fixture
	that streams in already lit just shows lit, without a click. Lights are set only through HallLight,
	so they carry its tag and lit brightness and BehindDoors keeps scaling them; this system runs
	before BehindDoors each frame, so its dimming lands on top of a flicker.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local SoundPrimer = require(script.Parent.SoundPrimer)

local FREE = Brix.Pathing.free()

-- One fixture on this screen.
type Shown = {
	model: Model,
	tube: BasePart,
	eye: BasePart,
	click: Sound,
	state: MotionLight.State, -- what it shows
	server: MotionLight.State, -- what the server says
	predicted: number, -- its id in this screen's own watch
	real: boolean, -- throws real light (one of the nearest lit fixtures)
	since: number, -- seconds since its state last changed
	flicker: number?, -- the next step of its tube flickering on, nil once steady
	eyeFrom: Color3?, -- its eye easing from this colour to `eyeTo`, nil once settled
	eyeTo: Color3,
	eyeSeconds: number,
	changed: RBXScriptConnection,
}

local function stateOf(model: Model): MotionLight.State
	local state = model:GetAttribute(MotionLight.StateAttribute)
	return if state == "Lit" or state == "Blind" then state else "Dark"
end

local function partIn(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- Eases out: quick at first, settling gently.
local function easeOut(alpha: number): number
	return 1 - (1 - alpha) ^ 3
end

local HallLights = {}

function HallLights.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local moving: { [Shown]: true } = {} -- fixtures mid-flicker or with an eye easing
	local ranked: { Shown } = {} -- reused each time the nearest lit fixtures are picked
	local nearness: { [Shown]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()
	local untilPick = 0
	local predicted = MotionLight.watch() -- the lights your own movement wakes, on this screen
	local byPredicted: { [number]: Shown } = {}
	local mine: { [unknown]: vector } = {} -- your character's place, the one body predicted
	local root: BasePart? = nil
	local clock = 0

	-- Your character's root part, found again after a respawn.
	local function myRoot(): BasePart?
		if not (root and root.Parent) then
			local character = Players.LocalPlayer.Character
			local found = character and character:FindFirstChild("HumanoidRootPart")
			root = if found and found:IsA("BasePart") then found else nil
		end
		return root
	end

	-- What a fixture shows: blind or dark as the server says, lit if the server or your own
	-- movement says so.
	local function shownState(s: Shown): MotionLight.State
		if s.server == "Blind" then
			return "Blind"
		elseif s.server == "Lit" or predicted:state(s.predicted) == "Lit" then
			return "Lit"
		end
		return "Dark"
	end

	local function byNearness(a: Shown, b: Shown): boolean
		return nearness[a] < nearness[b]
	end

	-- Gives real light to the lit fixtures nearest the camera and takes it from the rest.
	local function pick()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local from = camera.CFrame.Position
			+ (if look.Magnitude > 1e-3 then look.Unit * HallLight.NearLead else Vector3.zero)
		table.clear(ranked)
		for _, s in shown do
			if s.state == "Lit" then
				-- one already lit keeps its light until another is clearly nearer
				nearness[s] = (s.tube.Position - from).Magnitude
					- (if s.real then HallLight.NearMargin else 0)
				table.insert(ranked, s)
			end
		end
		table.sort(ranked, byNearness)
		for i, s in ranked do
			local real = i <= HallLight.NearFixtures
			if real ~= s.real then
				s.real = real
				if not s.flicker then
					HallLight.light(s.tube, 1, real)
				end
			end
		end
		table.clear(nearness)
	end

	local function easeEye(s: Shown, from: Color3, to: Color3, seconds: number)
		s.eye.Material = Enum.Material.Neon
		s.eye.Color = from
		s.eyeFrom, s.eyeTo, s.eyeSeconds = from, to, seconds
		moving[s] = true
	end

	local function playClick(s: Shown, volume: number, pitch: number)
		s.click.Volume = volume
		s.click.PlaybackSpeed = pitch
		s.click.TimePosition = 0
		s.click:Play()
	end

	-- Shows `s` steady in its state, with no click or animation (a fixture streaming in).
	local function settle(s: Shown)
		s.flicker, s.eyeFrom = nil, nil
		moving[s] = nil
		if s.state == "Lit" then
			HallLight.light(s.tube, 1, s.real)
			HallLight.eye(s.eye, "Seen")
		else
			HallLight.light(s.tube, 0)
			HallLight.eye(s.eye, if s.state == "Blind" then "Blind" else "Watching")
		end
	end

	-- The server changed a fixture's state: show the change as it happens.
	local function change(s: Shown, state: MotionLight.State)
		local was = s.state
		if state == was then
			return
		end
		s.state, s.since = state, 0
		if state == "Lit" then
			local pitch = HallLight.ClickPitch
			playClick(s, HallLight.ClickVolume, random:NextNumber(pitch.Min, pitch.Max))
			easeEye(s, HallLight.EyeFlare, HallLight.EyeSeen, HallLight.EyeFlareSeconds)
			s.flicker = 1
			-- pick now, so a light waking beside you throws real light from its first flash
			untilPick = 0
		elseif state == "Dark" and was == "Lit" then
			s.flicker, s.real = nil, false
			HallLight.light(s.tube, 0)
			playClick(s, HallLight.ClickOffVolume, HallLight.ClickOffPitch)
			easeEye(s, HallLight.EyeSeen, HallLight.EyeWatching, HallLight.EyeRelaxSeconds)
		else
			-- power cut, or back on: the eye and tube snap to it, silently
			s.real = false
			settle(s)
		end
	end

	local function add(inst: Instance)
		-- a tagged template in ReplicatedStorage is no light (docs/STUDIO.md)
		if not inst:IsA("Model") or shown[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local tube, eye = partIn(inst, "Diffuser"), partIn(inst, "Eye")
		if not (tube and eye) then
			warn(`HallLights: {inst:GetFullName()} has no Diffuser or Eye part`)
			return
		end
		local click = Instance.new("Sound")
		click.Name = "Click"
		click.SoundId = HallLight.ClickSound
		click.RollOffMode = Enum.RollOffMode.InverseTapered
		click.RollOffMinDistance = HallLight.ClickNear
		click.RollOffMaxDistance = HallLight.ClickReach
		click.Parent = eye
		local frame = inst:GetPivot()
		local at, along = frame.Position, frame.XVector
		local server: MotionLight.State = stateOf(inst)
		local area = Brix.Zone.box(
			MotionLight.watchBox(FREE, at.X, at.Y, at.Z, MotionLight.turnOf(along.X, along.Z))
		)
		local id = predicted:add(area, at.X, at.Z, MotionLight.Reach, server ~= "Blind")
		local s: Shown
		s = {
			model = inst,
			tube = tube,
			eye = eye,
			click = click,
			state = server,
			server = server,
			predicted = id,
			real = false,
			since = 0,
			flicker = nil,
			eyeFrom = nil,
			eyeTo = HallLight.EyeWatching,
			eyeSeconds = 0,
			changed = inst:GetAttributeChangedSignal(MotionLight.StateAttribute):Connect(function()
				s.server = stateOf(inst)
				predicted:setPowered(s.predicted, s.server ~= "Blind")
				change(s, shownState(s))
			end),
		}
		shown[inst] = s
		byPredicted[id] = s
		settle(s)
		untilPick = 0
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if s then
			s.changed:Disconnect()
			s.click:Destroy()
			predicted:remove(s.predicted)
			byPredicted[s.predicted] = nil
			moving[s] = nil
			shown[inst :: any] = nil
		end
	end

	-- Moves one fixture's flicker and eye on by `dt`.
	local function animate(s: Shown, dt: number)
		s.since += dt
		local step = s.flicker
		while step do
			local flash = HallLight.Flicker[step]
			if not flash then
				-- caught: the tube holds, and the dust starts drifting under it
				HallLight.light(s.tube, 1, s.real)
				step = nil
			elseif s.since >= flash.at then
				HallLight.glow(s.tube, flash.level, s.real)
				step += 1
			else
				break
			end
		end
		s.flicker = step
		local from = s.eyeFrom
		if from then
			local alpha = math.min(s.since / s.eyeSeconds, 1)
			s.eye.Color = from:Lerp(s.eyeTo, easeOut(alpha))
			if alpha >= 1 then
				s.eyeFrom = nil
			end
		end
		if not (s.flicker or s.eyeFrom) then
			moving[s] = nil
		end
	end

	return {
		name = "HallLights",
		start = function(_: any, _context: Brix.Context)
			-- a motion light's first click on time, not a third of a second after it lights
			task.spawn(SoundPrimer.prime, { HallLight.ClickSound })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(MotionLight.Tag):Connect(function(inst)
					-- Deferred so a fixture streaming in has all its parts before they're looked up.
					task.defer(add, inst)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(MotionLight.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(MotionLight.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			clock += dt
			-- your own movement wakes your lights this frame, before the server hears of it
			local body = myRoot()
			-- any: a Vector3 is the native vector the watch measures, which the checker won't cast
			if body then
				mine.me = (body.Position :: any) :: vector
			else
				table.clear(mine)
			end
			for _, id in predicted:step(clock, mine) do
				local s = byPredicted[id]
				if s then
					change(s, shownState(s))
				end
			end
			-- picked before animating, so a light that just woke has its real light from its first flash
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = HallLight.NearSeconds
				pick()
			end
			for s in moving do
				animate(s, dt)
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

return HallLights
