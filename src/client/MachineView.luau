--!strict
--[[
	MachineView: the vending machine in every floor's car (S1-10b2), drawn on each screen from its
	car's ride. For those aboard (and anyone watching a friend, ElevatorView's `rode` rule), a ride
	from floor 1 up wakes it as `Machine.Wake` says, second for second alike on every rider's
	screen: each row's tube tinks, flashes and catches, bottom row first, the sign buzzes on, the
	hum swells, the cold light spills across the car; it dips with the car's lamp and cuts out as
	the gate starts to fold. The first ride (up from the lobby), the car standing at a floor, or a
	car that left you: dark.

	The stock (S1-10c1): what the server dealt this ride (`Stock.Attribute`) stands in the coils
	(MachineStock), each row's things there from its tube's first flash, so the light seems to
	find them; as a row's tube catches its price windows run their LEDs' test (88) and settle on
	the prices, dashes for an empty coil. All gone as the power cuts.

	The buy (S1-10c2): a sale reads off the stock (`Buy.sold`: the same stock with a count
	lowered), never a refill: that bay's vend plays (MachineVend: the button, the coil's turn, the
	drop, the flap) and its window shows dashes once it's empty. A press of a bay's Buy on this
	screen sinks its button at once with its click; with too few coins for its price the machine
	gives one dull buzz and the price blinks, and nothing else happens (the server refuses it too).

	Only a waking, lit or dying machine is stepped, and a light is written only when what it shows
	changes. Its one SurfaceLight stays off unless it's lit, so a screen only ever has one on.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Left = require(ReplicatedStorage.Shared.Left)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Stock = require(ReplicatedStorage.Shared.Machine.Stock)
local LedReadout = require(script.Parent.LedReadout)
local MachineStock = require(script.Parent.MachineStock)
local MachineVend = require(script.Parent.MachineVend)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Wake = Machine.Wake
local Buy = Machine.Buy
local Tools = require(ReplicatedStorage.Shared.Tools)

-- Shares are drawn in steps this fine, so a light is written only when it visibly changes.
local STEPS = 64
-- A tink this late (a screen that joined mid-ride, or a hitch) is skipped, not played late.
local LATE = 0.25
-- Seconds a row's price windows show their test (every segment lit, "88") as its tube catches,
-- before the prices: an old machine's LEDs checking themselves as the power comes up.
local LED_TEST = 0.18
-- The price windows' LEDs: the keypad's red, prices bright, dashes for an empty coil at rest;
-- unlit segments faint.
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
	windows: { [number]: Instance }, -- each bay's price window, by bay
	digits: { [number]: LedReadout.Set }?, -- drawn the first time it wakes
	stockText: string?, -- the stock as last read off the machine
	stock: Stock.Stock?,
	goods: MachineStock.Shown?, -- the stock standing in the coils on this screen
	rideAt: number?,
	from: number,
	rode: boolean,
	shown: { number }, -- each light's share as last drawn: the tubes, then the sign
	nextClick: number, -- the next starter's click to play, in `Wake.Clicks`
	tink: Sound?,
	buzz: Sound?,
	hum: Sound?,
	conns: { RBXScriptConnection },
	vends: { MachineVend.Vend }, -- sales playing at it
	pressed: { [number]: number }, -- os.clock each bay's button was last pressed on this screen
}

-- A button pressed on this screen, sunk and back up; and its price blinking for someone who
-- can't pay.
type Press = { view: View, bay: number, button: BasePart, rest: CFrame, at: number, blink: boolean }

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
	local vending: { [View]: true } = {} -- machines with a sale playing
	local presses: { Press } = {}
	local connections: { RBXScriptConnection } = {}

	-- Every price window `since` seconds into a ride from `from`: dark until its row's tube
	-- catches, then its test, then its price (dashes for an empty coil); dark again at the cut.
	local function drawPrices(view: View, since: number, from: number)
		local live = Wake.wakes(from) and since < Ride.opens() + Wake.Fade
		local digits: { [number]: LedReadout.Set }
		local had = view.digits
		if had then
			digits = had
		elseif live and since >= Wake.catches(1) then
			digits = {}
			for i, window in view.windows do
				digits[i] = LedReadout.row(window, LED, 0.8, 0.12, 2)
			end
			view.digits = digits
		else
			return -- never lit yet: nothing to draw
		end
		local stock = view.stock
		for i, set in digits do
			local bay = Machine.Specs.Bays[i]
			local caught = Wake.catches(bay.Row)
			if not live or since < caught then
				set(1, " ", "Off")
				set(2, " ", "Off")
			elseif since < caught + LED_TEST then
				set(1, "8", "Lit")
				set(2, "8", "Lit")
			else
				local s = stock and stock[i]
				if s and s.count > 0 then
					local tens, ones = Stock.digits(s.price)
					set(1, tens, "Lit")
					set(2, ones, "Lit")
				else
					set(1, "-", "Rest")
					set(2, "-", "Rest")
				end
			end
		end
	end

	-- Each row's stock in its coils from its tube's first flash until the power cuts.
	local function drawGoods(view: View, since: number, from: number)
		local shown = view.goods
		if not shown then
			return
		end
		local live = Wake.wakes(from) and since < Ride.opens() + Wake.Fade
		for row, start in Wake.Tubes do
			MachineStock.show(shown, view.model, row, live and since >= start.At)
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
		drawGoods(view, since, from)
		drawPrices(view, since, from)

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

	-- The server dealt this ride's stock (or it changed, or the car stands at a floor again):
	-- the coils filled anew, each row shown or not as the ride's clock says.
	local function stockChanged(view: View)
		local text = view.model:GetAttribute(Stock.Attribute)
		local value = if type(text) == "string" then text else nil
		if value == view.stockText then
			return
		end
		view.stockText = value
		local was, now = view.stock, Stock.decode(value)
		view.stock = now
		local sold = Buy.sold(was, now)
		local goods = view.goods
		if sold and was and goods then
			local clock = os.clock()
			for bay, n in sold do
				local things = goods.bays[bay]
				for _ = 1, n do
					if things and #things > 0 then
						local sunk = clock - (view.pressed[bay] or -math.huge) < Buy.Vend.Up + 0.6
						local vend =
							MachineVend.start(view.model, bay, was[bay].key, things, clock, sunk)
						table.insert(view.vends, vend)
						vending[view] = true
					end
				end
			end
			refresh(view) -- an empty coil's window to dashes
			return
		end
		for _, vend in view.vends do
			MachineVend.finish(vend)
		end
		table.clear(view.vends)
		vending[view] = nil
		if view.goods then
			MachineStock.clear(view.goods)
			view.goods = nil
		end
		local stock = view.stock
		if stock then
			view.goods = MachineStock.fill(view.model, stock)
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
		local windows: { [number]: Instance } = {}
		for i in Machine.Specs.Bays do
			local w = gui:FindFirstChild(`Window{i}`)
			if w then
				windows[i] = w
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
			from = Ride.Lobby,
			rode = false,
			shown = table.create(#tubes + 1, 0),
			nextClick = #Wake.Clicks + 1,
			conns = {},
			vends = {},
			pressed = {},
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
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Stock.Attribute):Connect(function()
				stockChanged(view)
			end)
		)
		stockChanged(view)
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
		vending[view] = nil
		for _, vend in view.vends do
			MachineVend.finish(vend)
		end
		table.clear(view.vends)
		if view.goods then
			MachineStock.clear(view.goods)
			view.goods = nil
		end
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

	-- This screen pressed a machine's Buy: the button down at once; too few coins, the dull buzz
	-- and the price blinking (the server refuses it as well).
	local function pressed(prompt: ProximityPrompt)
		local spot = prompt.Parent
		local button = spot and spot.Parent
		local model = button and button.Parent
		local view = if model and model:IsA("Model") then views[model] else nil
		if not (view and button and button:IsA("BasePart")) then
			return
		end
		local bay = tonumber(string.match(button.Name, "^Button(%d)$"))
		local s = bay and view.stock and view.stock[bay]
		if not (bay and s) then
			return
		end
		local clock = os.clock()
		view.pressed[bay] = clock
		local _, rest = MachineVend.press(view.model, bay)
		local coins = me:GetAttribute(Coins.Attribute)
		local poor = Buy.check(s, if type(coins) == "number" then coins else nil) == "poor"
		if poor then
			Tools.play(Buy.Nope, button, Buy.Heard)
		end
		for i = #presses, 1, -1 do
			if presses[i].button == button then
				rest = presses[i].rest -- pressed again mid-sink: its true rest
				table.remove(presses, i)
			end
		end
		table.insert(
			presses,
			{ view = view, bay = bay, button = button, rest = rest, at = clock, blink = poor }
		)
	end

	-- A press's button and blink `now`; true once both are over.
	local function stepPress(p: Press, now: number): boolean
		local t = now - p.at
		local done = t >= math.max(Buy.Vend.Up + Buy.Vend.Sink, if p.blink then Buy.Blink else 0)
		p.button:PivotTo(if done then p.rest else MachineVend.sinkAt(p.rest, t))
		local digits = p.view.digits
		local set = digits and digits[p.bay]
		local s = p.view.stock and p.view.stock[p.bay]
		if p.blink and set and s then
			local on = done or math.floor(t * Buy.BlinkHz * 2) % 2 == 0
			local tens, ones = Stock.digits(s.price)
			set(1, if on then tens else " ", if on then "Lit" else "Off")
			set(2, if on then ones else " ", if on then "Lit" else "Off")
		end
		return done
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
		table.insert(connections, ProximityPromptService.PromptTriggered:Connect(pressed))
		task.spawn(
			SoundPrimer.prime,
			{ Machine.Tink.id, Machine.Buzz.id, Machine.Hum.id, Buy.Click.id, Buy.Motor.id }
		)
	end

	-- The presses and sales playing: after the ride's own draw, so a blink shows over it.
	local function stepSales()
		local clock = os.clock()
		for i = #presses, 1, -1 do
			if stepPress(presses[i], clock) then
				table.remove(presses, i)
			end
		end
		for view in vending do
			for i = #view.vends, 1, -1 do
				if MachineVend.step(view.vends[i], clock) then
					table.remove(view.vends, i)
				end
			end
			if #view.vends == 0 then
				vending[view] = nil
			end
		end
	end

	function system.step(_: any, _dt: number)
		if next(stepping) ~= nil then
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
		if #presses > 0 or next(vending) ~= nil then
			stepSales()
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
