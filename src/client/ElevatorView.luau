--!strict
--[[
	ElevatorView: every freight elevator on this player's screen, its gate folding and its keypad
	answering, with their sounds (L-05b1c). The server decides everything (Elevators) and writes
	it as two replicated values on the elevator, the gate's motion (`Gate.Attribute`) and the
	keypad's state (`Keypad.Attribute`); this draws both:

	- The gate folds from its motion, posed every frame while it moves (only moving gates are
	  stepped), and jolts the view of anyone beside it the instant it slams.
	- Each press sinks its key into the keypad and back, with a beep. The readout's red LED digits
	  (LedReadout) sit on an invisible card just off the readout's glass: dim dashes at rest, a
	  digit lit as it's punched; a wrong code blinks them, and the status light with them, while
	  the alarm rings; the right one turns the digits, the light and the glow green.
	- The sounds (Elevator.Sounds) are timed off the server's clock, so the fold's slam lands as
	  every player sees the gate hit.

	The screen keypad (KeypadPad) calls `press` to beep and sink a key the instant it's pressed;
	the server's echo of that press names this player (`by`), so it's skipped here.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local LedReadout = require(script.Parent.LedReadout)
local Shake = require(ReplicatedStorage.Shared.Shake)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Gate = require(ReplicatedStorage.Shared.Elevator.Gate)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)
local Sounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local Specs = require(ReplicatedStorage.Shared.Elevator.Specs)

-- A pressed key snaps in at once, holds a beat, then springs back out over this.
local KEY_BACK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05)
-- The wall readout's LEDs: each digit 78% of the glass's height, 6% of its width apart. The card's
-- pixels a stud (sharp at arm's length) and how far off it still draws (it's lit, so the dashes
-- read from across the lobby).
local CARD_PIXELS = 400
local CARD_REACH = 70
-- Lit LEDs a touch over full brightness, so they glow against the dark glass.
local CARD_BRIGHTNESS = 1.3
local WALL_LOOK: LedReadout.Look = {
	unlit = Elevator.ReadoutUnlit,
	unlitTransparency = 0.6,
	rest = Elevator.ReadoutRest,
	lit = Elevator.ReadoutLit,
	right = Elevator.ReadoutRight,
}
-- Where the gate's sounds come from: the middle of the opening, at chest height, in its plane.
local GATE_SOUNDS = CFrame.new(0, 4.5, Specs.Gate.Plane)

type Key = { part: BasePart, rest: CFrame, tween: Tween? }

type View = {
	model: Model,
	alive: boolean,
	conns: { RBXScriptConnection },
	made: { Instance }, -- what this screen added to the elevator, removed with it
	-- the gate
	from: number,
	to: number,
	start: number,
	motions: number, -- counts its motions, so a new one cancels the last one's sounds still to come
	slammed: boolean,
	-- the keypad
	state: Keypad.State,
	since: number, -- os.clock() when its state last changed
	draw: LedReadout.Draw?,
	keys: { [number]: Key },
	travel: Vector3, -- a key's push into the keypad, in the world
	light: BasePart?,
	glow: PointLight?,
	tone: Readout.Tone?, -- the status light's, as last shown
	-- the sounds
	emitters: { [Sounds.Source]: Attachment },
	sounds: { [Sounds.SoundName]: Sound },
	fades: { [Sound]: Tween },
}

-- What the screen keypad calls on a press: beep and sink that key on `model`'s keypad now.
export type Press = (model: Model, key: Keypad.Key) -> ()

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function find(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local ElevatorView = {}

-- `kick` shakes this player's view (CameraShake's).
function ElevatorView.new(kick: (amount: number) -> ()): (Brix.System, Press)
	local views: { [Model]: View } = {}
	local moving: { [View]: true } = {}
	local blinking: { [View]: true } = {}
	local connections: { RBXScriptConnection } = {}

	-- Where this player hears from: their character, or the camera without one.
	local function listener(): Vector3?
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
		local camera = Workspace.CurrentCamera
		return if camera then camera.CFrame.Position else nil
	end

	local function emitter(view: View, source: Sounds.Source): Attachment?
		local existing = view.emitters[source]
		if existing then
			return existing
		end
		local host = find(view.model, if source == "Keypad" then "Keypad" else "Car")
		if not host then
			return nil
		end
		local a = Instance.new("Attachment")
		a.Name = `{source}Sounds`
		a.Parent = host
		a.WorldCFrame = if source == "Keypad"
			then CFrame.new(Elevator.keypadPoint(view.model))
			else view.model:GetPivot() * GATE_SOUNDS
		view.emitters[source] = a
		table.insert(view.made, a)
		return a
	end

	local function soundFor(view: View, name: Sounds.SoundName): Sound?
		local existing = view.sounds[name]
		if existing then
			return existing
		end
		local row = Sounds.Sounds[name]
		local at = emitter(view, row.Source)
		if not at then
			return nil
		end
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = row.Id
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = row.Near
		s.RollOffMaxDistance = row.Reach
		s.PlaybackRegionsEnabled = true
		s.Parent = at
		view.sounds[name] = s
		return s
	end

	-- Plays `cue` now, `late` seconds behind time: a timed sound skips ahead to keep its slam.
	local function play(view: View, cue: Sounds.Cue, late: number)
		local row = Sounds.Sounds[cue.sound]
		local s = soundFor(view, cue.sound)
		if not s then
			return
		end
		local fading = view.fades[s]
		if fading then
			fading:Cancel()
			view.fades[s] = nil
		end
		local from = if row.Timed then cue.from + late * cue.pitch else cue.from
		if from >= row.Stop then
			return
		end
		s.PlaybackRegion = NumberRange.new(from, row.Stop)
		s.PlaybackSpeed = cue.pitch
		s.Volume = row.Volume
		s.TimePosition = from
		s:Play()
		if row.Fade > 0 then
			-- fade out over the stretch's last Fade seconds (at this pitch), so the cut is silent
			local length = row.Stop - from
			local info = TweenInfo.new(
				math.min(row.Fade, length) / cue.pitch,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(length - row.Fade, 0) / cue.pitch
			)
			local tween = TweenService:Create(s, info, { Volume = 0 })
			tween:Play()
			view.fades[s] = tween
		end
	end

	-- Plays `cue` `wait` seconds from now while `current()` holds; at once if it's only a little late.
	local function schedule(view: View, cue: Sounds.Cue, wait: number, current: () -> boolean)
		if wait < -Sounds.LateCue then
			return
		elseif wait <= 0 then
			play(view, cue, -wait)
			return
		end
		task.delay(wait, function()
			if view.alive and current() then
				play(view, cue, 0)
			end
		end)
	end

	-- Sinks key `digit` into the keypad at once and springs it back out.
	local function sink(view: View, digit: number)
		local key = view.keys[digit]
		if not key then
			return
		end
		if key.tween then
			key.tween:Cancel()
		end
		key.part.CFrame = key.rest + view.travel
		local tween = TweenService:Create(key.part, KEY_BACK, { CFrame = key.rest })
		key.tween = tween
		tween:Play()
	end

	-- The status light and the glow: red, green once the code is right, dark between blinks.
	local function showLight(view: View, tone: Readout.Tone)
		if view.tone == tone then
			return
		end
		view.tone = tone
		local light = view.light
		if light then
			light.Color = if tone == "Right"
				then Elevator.KeypadRight
				elseif tone == "Off" then Elevator.KeypadDark
				else Elevator.KeypadLight
		end
		local glow = view.glow
		if glow then
			glow.Color = if tone == "Right"
				then Elevator.KeypadRight
				else Elevator.KeypadGlow.Colour
			glow.Enabled = tone ~= "Off"
		end
	end

	local function draw(view: View)
		local since = os.clock() - view.since
		local d = view.draw
		if d then
			d(view.state, since)
		end
		showLight(view, Readout.light(view.state, since))
	end

	-- The server wrote the keypad's state: draw it and, when it's news, sound it.
	local function keypadChanged(view: View, live: boolean)
		local state = Keypad.decode(view.model:GetAttribute(Keypad.Attribute))
		if live and state.count == view.state.count then
			return
		end
		view.state, view.since = state, os.clock()
		draw(view)
		if Readout.blinking(state) then
			blinking[view] = true
		end
		if not live then
			return -- streaming in: the keypad as it stands, no replayed beeps
		end
		-- this player's own presses beeped and sank when they were made (`press`)
		local mine = state.by ~= nil and state.by == Players.LocalPlayer.UserId
		if state.digit and not mine then
			sink(view, state.digit)
		end
		local pressed = not mine and (state.digit ~= nil or state.event == "Clear")
		local count = state.count
		local function current(): boolean
			return view.state.count == count
		end
		for _, cue in Sounds.keypad(state.event, pressed) do
			schedule(view, cue, cue.at, current)
		end
	end

	-- The server sent the gate somewhere: pose it where it is now, then fold it each frame.
	local function gateChanged(view: View)
		local from, to, start = Gate.decode(view.model:GetAttribute(Gate.Attribute))
		view.from, view.to, view.start = from, to, start
		view.motions += 1
		local elapsed = now() - start
		if elapsed >= Gate.settles(from, to) then
			Elevator.setGate(view.model, to) -- long over: a gate streaming in where it ended up
			moving[view] = nil
			return
		end
		Elevator.setGate(view.model, Gate.at(from, to, elapsed))
		view.slammed = elapsed >= Gate.duration(from, to)
		moving[view] = true
		local mine = view.motions
		local function current(): boolean
			return view.motions == mine
		end
		for _, cue in Sounds.gate(from, to) do
			schedule(view, cue, cue.at - elapsed, current)
		end
	end

	-- The gate hit the stack or the post: jolt the view of anyone beside it.
	local function slam(view: View)
		local from = listener()
		if from then
			local d = (from - (view.model:GetPivot() * GATE_SOUNDS).Position).Magnitude
			kick(Sounds.SlamShake * Shake.falloff(d, Sounds.ShakeNear, Sounds.ShakeReach))
		end
	end

	-- The readout's digits on an invisible card just off its glass, facing the lobby.
	local function makeReadout(view: View)
		local glass = Specs.Parts.KeypadReadout
		local front = glass.Centre[3] - glass.Size[3] / 2
		local card = Instance.new("Part")
		card.Name = "ReadoutDigits"
		card.Size = Vector3.new(glass.Size[1], glass.Size[2], 0.002)
		-- its front face 0.003 off the glass, as the note's card is off its paper
		card.CFrame = view.model:GetPivot()
			* CFrame.new(glass.Centre[1], glass.Centre[2], front - 0.002)
		card.Transparency = 1
		card.Anchored = true
		card.CanCollide = false
		card.CanTouch = false
		card.CanQuery = false
		card.CastShadow = false
		card.Massless = true
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Digits"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = CARD_PIXELS
		gui.LightInfluence = 0 -- the LEDs make their own light
		gui.Brightness = CARD_BRIGHTNESS
		gui.MaxDistance = CARD_REACH
		gui.Parent = card
		view.draw = LedReadout.new(gui, WALL_LOOK, 0.78, 0.06)
		card.Parent = view.model
		table.insert(view.made, card)
	end

	local function remove(inst: Instance)
		local view = views[inst :: Model]
		if not view then
			return
		end
		views[inst :: Model] = nil
		moving[view] = nil
		blinking[view] = nil
		view.alive = false
		for _, c in view.conns do
			c:Disconnect()
		end
		for _, tween in view.fades do
			tween:Cancel()
		end
		for _, key in view.keys do
			if key.tween then
				key.tween:Cancel()
			end
		end
		for _, made in view.made do
			made:Destroy()
		end
	end

	local function add(inst: Instance)
		-- only elevators in the world: the template in ReplicatedStorage draws nothing
		if not inst:IsA("Model") or views[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local pivot = inst:GetPivot()
		local keys: { [number]: Key } = {}
		for digit = 0, 9 do
			local p = find(inst, `Key{digit}`)
			if p then
				keys[digit] = { part = p, rest = p.CFrame, tween = nil }
			end
		end
		local keypad = find(inst, "Keypad")
		local glowAt = keypad and keypad:FindFirstChild("Glow")
		local glow = glowAt and glowAt:FindFirstChildWhichIsA("PointLight")
		local view: View = {
			model = inst,
			alive = true,
			conns = {},
			made = {},
			from = 1,
			to = 1,
			start = 0,
			motions = 0,
			slammed = true,
			state = Keypad.decode(nil),
			since = os.clock(),
			draw = nil,
			keys = keys,
			travel = pivot:VectorToWorldSpace(Vector3.new(0, 0, Specs.Keypad.Travel)),
			light = find(inst, "KeypadLight"),
			glow = glow,
			tone = nil,
			emitters = {},
			sounds = {},
			fades = {},
		}
		views[inst] = view
		if find(inst, "KeypadReadout") then
			makeReadout(view)
		end
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Gate.Attribute):Connect(function()
				gateChanged(view)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Keypad.Attribute):Connect(function()
				keypadChanged(view, true)
			end)
		)
		gateChanged(view) -- mid-motion as it streams in: folding on, with only the sounds still to come
		keypadChanged(view, false)
	end

	-- Readies every elevator sound up front, so the first slam isn't late (SoundPrimer).
	local function preload()
		local ids: { string } = {}
		for _, row in Sounds.Sounds do
			table.insert(ids, row.Id)
		end
		SoundPrimer.prime(ids)
	end

	local function press(model: Model, key: Keypad.Key)
		local view = views[model]
		if not view then
			return
		end
		play(view, Sounds.press(key), 0)
		if type(key) == "number" then
			sink(view, key)
		end
	end

	local system: Brix.System = {
		name = "ElevatorView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(preload)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, _dt: number)
			if next(moving) ~= nil then
				local t = now()
				for view in moving do
					local elapsed = t - view.start
					if elapsed <= 0 then
						continue -- still waiting on the latch: posed where it rests
					end
					if not view.slammed and elapsed >= Gate.duration(view.from, view.to) then
						view.slammed = true
						slam(view)
					end
					if elapsed >= Gate.settles(view.from, view.to) then
						Elevator.setGate(view.model, view.to)
						moving[view] = nil
					else
						Elevator.setGate(view.model, Gate.at(view.from, view.to, elapsed))
					end
				end
			end
			for view in blinking do
				draw(view)
				if not Readout.blinking(view.state) then
					blinking[view] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in views do
				remove(model)
			end
		end,
	}
	return system, press
end

return ElevatorView
