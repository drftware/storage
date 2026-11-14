--!strict
--[[
	MachineView: the vending machine in every floor's car (S1-10b2), drawn on each screen from its
	car's ride. For those aboard (and anyone watching a friend, ElevatorView's `rode` rule), a ride
	from floor 1 up wakes it as `Machine.Wake` says, second for second alike on every rider's
	screen: each row's tube tinks, flashes and catches, bottom row first, the sign buzzes on, the
	price windows' LEDs show their dashes, the hum swells, the cold light spills across the car; it dips with the car's lamp and cuts out as the gate starts to fold. The first
	ride (up from the lobby), the car standing at a floor, or a car that left you: dark.

	Only a waking, lit or dying machine is stepped, and a light is written only when what it shows
	changes. Its one SurfaceLight stays off unless it's lit, so a screen only ever has one on.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Left = require(ReplicatedStorage.Shared.Left)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local LedReadout = require(script.Parent.LedReadout)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Wake = Machine.Wake

-- Shares are drawn in steps this fine, so a light is written only when it visibly changes.
local STEPS = 64
-- A tink this late (a screen that joined mid-ride, or a hitch) is skipped, not played late.
local LATE = 0.25
-- The price windows' LEDs: the keypad's red, its dashes at rest; unlit segments faint.
local LED: LedReadout.Look = {
	unlit = Color3.fromRGB(60, 10, 8),
	unlitTransparency = 0.55,
	rest = Color3.fromRGB(170, 26, 16),
	lit = Color3.fromRGB(255, 52, 36),
	right = Color3.fromRGB(255, 52, 36),
}

type View = {
	model: Model,
	car: Instance,
	tubes: { BasePart },
	sign: BasePart,
	glass: BasePart,
	carLight: SurfaceLight?,
	windows: { Instance },
	digits: { LedReadout.Set }?, -- drawn the first time it wakes
	ledsOn: boolean,
	rideAt: number?,
	from: number,
	rode: boolean,
	shown: { number }, -- each light's share as last drawn: the tubes, then the sign
	nextClick: number, -- the next starter's click to play, in `Wake.Clicks`
	tink: Sound?,
	buzz: Sound?,
	hum: Sound?,
	conns: { RBXScriptConnection },
}

local MachineView = {}

local function sound(spec: Machine.Sound, parent: Instance, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = 0
	s.PlaybackSpeed = spec.pitch
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	s.Looped = looped
	if looped then
		s.LoopRegion = s.PlaybackRegion
	end
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 6
	s.RollOffMaxDistance = Machine.Heard
	s.Parent = parent
	return s
end

local function quantize(share: number): number
	return math.floor(math.clamp(share, 0, 1) * STEPS + 0.5) / STEPS
end

-- A tube or the sign at `share` of full: Neon glowing that bright, or plain when it's out.
local function glow(p: BasePart, share: number, lit: Color3, dark: Color3)
	if share <= 0 then
		p.Material = Enum.Material.SmoothPlastic
		p.Color = dark
	else
		p.Material = Enum.Material.Neon
		p.Color = dark:Lerp(lit, share)
	end
end

function MachineView.new(): Brix.System
	local me = Players.LocalPlayer
	local views: { [Model]: View } = {}
	local stepping: { [View]: true } = {}
	local connections: { RBXScriptConnection } = {}

	local function setLeds(view: View, on: boolean)
		if view.ledsOn == on then
			return
		end
		view.ledsOn = on
		local digits = view.digits
		if not digits and on then
			local made: { LedReadout.Set } = {}
			for i, window in view.windows do
				made[i] = LedReadout.row(window, LED, 0.8, 0.12, 2)
			end
			view.digits = made
			digits = made
		end
		if digits then
			for _, set in digits do
				set(1, "-", if on then "Rest" else "Off")
				set(2, "-", if on then "Rest" else "Off")
			end
		end
	end

	local function stopSounds(view: View)
		for _, s in { view.hum, view.buzz } do
			if s and s.IsPlaying then
				s:Stop()
			end
		end
	end

	-- Draws `view` `since` seconds into a ride from `from`: its tubes, sign, lights, LEDs, hum
	-- and the sign's buzz. A light is written only when its share changes.
	local function draw(view: View, since: number, from: number)
		local n = #view.tubes
		local changed = false
		local baySum = 0
		for row, tube in view.tubes do
			local q = quantize(Wake.tube(row, since, from))
			baySum += q
			if q ~= view.shown[row] then
				view.shown[row] = q
				changed = true
				glow(tube, q, Machine.TubeLit, Machine.TubeDark)
			end
		end
		local signShare = quantize(Wake.sign(since, from))
		if signShare ~= view.shown[n + 1] then
			view.shown[n + 1] = signShare
			changed = true
			glow(view.sign, signShare, Machine.SignLit, Machine.SignDark)
		end

		if changed then
			-- the spill, as bright as the whole machine
			local all = (baySum + signShare) / (n + 1)
			local carLight = view.carLight
			if carLight then
				carLight.Enabled = all > 0
				carLight.Brightness = Machine.Light.Car.Brightness * all
			end
			-- the hum, as loud as the share of it that's lit
			local hum = Wake.hum(since, from)
			if hum > 0 then
				local s = view.hum or sound(Machine.Hum, view.glass, true)
				view.hum = s
				s.Volume = Machine.Hum.volume * hum
				if not s.IsPlaying then
					s.TimePosition = Machine.Hum.from
						+ math.max(since, 0) % (Machine.Hum.length - 1)
					s:Play()
				end
			elseif view.hum and view.hum.IsPlaying then
				view.hum:Stop()
			end
		end
		-- the coin mech's LEDs come on with the power that catches the bottom tube
		setLeds(view, (view.shown[1] or 0) > 0.5)

		-- the sign's buzz, on and off with its stutters until it holds, then gone under the hum
		local buzzing = Wake.wakes(from)
			and since >= Wake.Sign.At
			and since < Wake.catches(0) + 0.15
		if buzzing then
			local buzz = view.buzz or sound(Machine.Buzz, view.glass, true)
			view.buzz = buzz
			buzz.Volume = Machine.Buzz.volume * (if signShare > 0 then 1 else 0.15)
			if not buzz.IsPlaying then
				buzz:Play()
			end
		elseif view.buzz and view.buzz.IsPlaying then
			view.buzz:Stop()
		end
	end

	-- The starters' tinks, each as its moment passes `since` seconds into the ride.
	local function tinks(view: View, since: number)
		local clicks = Wake.Clicks
		while view.nextClick <= #clicks and clicks[view.nextClick].At <= since do
			local click = clicks[view.nextClick]
			view.nextClick += 1
			if since - click.At < LATE then
				local tink = view.tink or sound(Machine.Tink, view.glass, false)
				view.tink = tink
				local rise = if click.Light == 0 then #view.tubes + 1 else click.Light
				tink.Volume = Machine.Tink.volume
				tink.PlaybackSpeed = Machine.Tink.pitch + Machine.TinkRise * (rise - 1)
				tink.TimePosition = Machine.Tink.from
				tink:Play()
			end
		end
	end

	-- Whether `view` wakes on this screen now: a ride from floor 1 up that you rode, not over.
	local function waking(view: View, since: number): boolean
		return view.rideAt ~= nil and view.rode and Wake.changing(since, view.from)
	end

	-- Steps `view` from now on while it's waking, lit or dying; or draws it dark and stops.
	local function refresh(view: View)
		local at = view.rideAt
		local since = if at then RideClock(at) else math.huge
		if waking(view, since) then
			stepping[view] = true
		else
			stepping[view] = nil
			draw(view, since, Ride.Lobby)
			stopSounds(view)
		end
	end

	-- The car rode (or a new ride began): when, and from which floor. Cleared as it stands at a
	-- floor again, the ride is kept until it has died out (`Wake.over`).
	local function rideChanged(view: View)
		local at, from = Ride.decode(view.car:GetAttribute(Ride.Attribute))
		if at and at ~= view.rideAt then
			view.rideAt = at
			view.from = from
			-- the clicks already past (joining mid-ride) are skipped
			local since = RideClock(at)
			local i = 1
			while i <= #Wake.Clicks and Wake.Clicks[i].At < since - LATE do
				i += 1
			end
			view.nextClick = i
		end
		refresh(view)
	end

	local function aboardChanged(view: View)
		local at, ids = Departure.decodeAboard(view.car:GetAttribute(Departure.AboardAttribute))
		view.rode = at ~= nil
			and (table.find(ids, me.UserId) ~= nil or me:FindFirstChild(Left.WatchValue) ~= nil)
		refresh(view)
	end

	local function added(inst: Instance)
		if not inst:IsA("Model") or not inst:IsDescendantOf(Workspace) or views[inst] then
			return
		end
		local car = inst.Parent
		local sign, glass = inst:FindFirstChild("Sign"), inst:FindFirstChild("Glass")
		local prices = inst:FindFirstChild("Prices")
		local gui = prices and prices:FindFirstChild("Digits")
		if
			not (car and sign and sign:IsA("BasePart") and glass and glass:IsA("BasePart") and gui)
		then
			return -- streamed in part-way: it's Atomic, so this is a broken copy
		end
		local tubes: { BasePart } = {}
		for row in Machine.Specs.Tubes do
			local t = inst:FindFirstChild(`Tube{row}`)
			if t and t:IsA("BasePart") then
				tubes[row] = t
			end
		end
		local windows: { Instance } = {}
		for i in Machine.Specs.Bays do
			local w = gui:FindFirstChild(`Window{i}`)
			if w then
				table.insert(windows, w)
			end
		end
		local spill = glass:FindFirstChild("CarLight")
		local view: View = {
			model = inst,
			car = car,
			tubes = tubes,
			sign = sign,
			glass = glass,
			carLight = if spill and spill:IsA("SurfaceLight") then spill else nil,
			windows = windows,
			ledsOn = false,
			from = Ride.Lobby,
			rode = false,
			shown = table.create(#tubes + 1, 0),
			nextClick = #Wake.Clicks + 1,
			conns = {},
		}
		views[inst] = view
		table.insert(
			view.conns,
			car:GetAttributeChangedSignal(Ride.Attribute):Connect(function()
				rideChanged(view)
			end)
		)
		table.insert(
			view.conns,
			car:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(function()
				aboardChanged(view)
			end)
		)
		local at, ids = Departure.decodeAboard(car:GetAttribute(Departure.AboardAttribute))
		view.rode = at ~= nil
			and (table.find(ids, me.UserId) ~= nil or me:FindFirstChild(Left.WatchValue) ~= nil)
		rideChanged(view)
	end

	local function removed(inst: Instance)
		local view = views[inst :: Model]
		if not view then
			return
		end
		views[inst :: Model] = nil
		stepping[view] = nil
		for _, c in view.conns do
			c:Disconnect()
		end
		for _, s in { view.tink, view.buzz, view.hum } do
			if s then
				s:Destroy()
			end
		end
	end

	-- Watching a friend began or ended: every machine is decided again, as ElevatorView's lamps.
	local function watchChanged(child: Instance)
		if child.Name == Left.WatchValue then
			for _, view in views do
				aboardChanged(view)
			end
		end
	end

	local system = { name = "MachineView" }

	function system.start(_: any, _context: Brix.Context)
		for _, inst in CollectionService:GetTagged(Machine.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Machine.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Machine.Tag):Connect(removed)
		)
		table.insert(connections, me.ChildAdded:Connect(watchChanged))
		table.insert(connections, me.ChildRemoved:Connect(watchChanged))
		task.spawn(SoundPrimer.prime, { Machine.Tink.id, Machine.Buzz.id, Machine.Hum.id })
	end

	function system.step(_: any, _dt: number)
		if next(stepping) == nil then
			return
		end
		local now = Workspace:GetServerTimeNow()
		for view in stepping do
			local since = RideClock(view.rideAt :: number, now)
			if waking(view, since) then
				draw(view, since, view.from)
				tinks(view, since)
			else
				stepping[view] = nil
				draw(view, since, Ride.Lobby)
				stopSounds(view)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local all = {}
		for inst in views do
			table.insert(all, inst)
		end
		for _, inst in all do
			removed(inst)
		end
		table.clear(stepping)
	end

	return system
end

return MachineView
