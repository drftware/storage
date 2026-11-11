--!strict
--[[
	RideView: the ride on a rider's screen (L-08a, Ride). The server writes the ride's value on the
	elevator the instant its shut gate hits its post (`Ride.Attribute`), with who rode
	(`Departure.AboardAttribute`); if this player rode, this draws the whole climb from it, off the
	server's clock, so friends in the car see and hear the same moment:

	- The shaft: the car never moves (nothing jitters, nobody falls through a floor). A thin sleeve
	  of shaft is laid just outside the car's gate on this screen only, and slides down past it:
	  the hall you left goes dark as the brakes let go, then its header beam, bare concrete with
	  the next floor's number painted on it, the next landing's apron and bright sill, and its dark
	  mouth, level with you, which lifts to show the hall as the bell rings. The car's lamp lights
	  it and prints the gate's lattice on it, standing still while the wall slides.
	- The sway: held on the camera (CameraShake's `hold`), read from the ride's clock each frame:
	  the lurch, your weight as it pulls and slows, the cable clanks, the bob as it levels.
	- The sounds: the brakes' clunk, the motor swelling with the speed and its deep rumble, the
	  clanks, the readout's relay, the motor winding down, the brake setting and the bell, all
	  flat in your ears (you're inside the box they come from).

	Testing (Studio only): a number in Workspace's `DevRideHold` attribute holds the ride at that
	many seconds in (RideClock), so a frame can be looked at (docs/STUDIO.md).

	ElevatorView dims the car's lamp and runs the car's readout; GateClock turns the clock's plate
	into the floor counter. When L-08b moves riders into the next floor's car mid-ride, it writes
	the same ride on that car, and this follows whichever riding car holds the player.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CameraShake = require(script.Parent.CameraShake)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- A ride older than this when this screen learns of it is over (an elevator streaming in).
local STALE = Ride.opens()
-- Pixels a stud on the painted number: crisp at the gate's distance, cheap.
local PAINT_PIXELS = 60

type Piece = { part: BasePart, at: CFrame } -- a sleeve part and where it sits, unmoved, in the elevator's frame

type Trip = {
	model: Model,
	at: number, -- server time the gate hit its post
	from: number,
	to: number,
	folder: Folder,
	pieces: { Piece },
	parts: { BasePart }, -- the same parts, for BulkMoveTo
	homes: { CFrame }, -- where they sit in the world as the car stands at the floor it leaves
	places: { CFrame }, -- where they go this frame, rewritten in place
	leaving: BasePart, -- the dark over the hall you left
	arriving: BasePart, -- and over the next one
	since: number, -- seconds into the ride last frame, for the cues crossed since
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function rootOf(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Whether this player stands inside `model`'s car (Departure's box, in the elevator's frame).
local function inCar(model: Model): boolean
	local root = rootOf()
	if not root then
		return false
	end
	local p = model:GetPivot():PointToObjectSpace(root.Position)
	local centre, size = Departure.car()
	return math.abs(p.X - centre[1]) <= size[1] / 2
		and math.abs(p.Y - centre[2]) <= size[2] / 2
		and math.abs(p.Z - centre[3]) <= size[3] / 2
end

local RideView = {}

-- `hold` puts a motion of its own on this player's view (CameraShake's).
function RideView.new(hold: (pose: CameraShake.Pose?) -> ()): Brix.System
	local connections: { RBXScriptConnection } = {}
	local watched: { [Model]: { RBXScriptConnection } } = {}
	local sounds: { [string]: Sound } = {}
	local fades: { [Sound]: Tween } = {}
	local cues = Ride.cues()
	local motorSound: Sound? = nil -- the two that follow the car's speed
	local rumbleSound: Sound? = nil
	local current: Trip? = nil

	-- One sleeve part, `size` studs, its middle `y` up the shaft and `x` across (elevator frame),
	-- `forward` toward the car off the sleeve's plane.
	local function piece(
		ride: { pieces: { Piece }, folder: Folder },
		name: string,
		x: number,
		y: number,
		width: number,
		height: number,
		forward: number,
		colour: { number },
		material: Enum.Material
	): BasePart
		local s = Ride.Shaft
		local p: BasePart = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(width, height, s.Depth)
		p.Color = rgb(colour)
		p.Material = material
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Locked = true
		p.Parent = ride.folder
		table.insert(ride.pieces, { part = p, at = CFrame.new(x, y, s.Plane + forward) })
		return p
	end

	-- Lays the shaft outside `model`'s gate, as the car stands at the floor it leaves.
	local function lay(model: Model, from: number, to: number, at: number): Trip
		local s = Ride.Shaft
		local folder = Instance.new("Folder")
		folder.Name = "RideShaft"
		local ride = {
			pieces = {} :: { Piece },
			folder = folder,
		}
		local w, mouth, rise = s.Width, s.Mouth, Ride.Rise
		local c = s.Colours
		local concrete, metal = Enum.Material.Concrete, Enum.Material.Metal
		-- the wall under the landing you leave, and the dark of its hall
		piece(ride, "Below", 0, -s.Below / 2, w, s.Below, 0, c.Wall, concrete)
		local leaving = piece(
			ride,
			"Leaving",
			0,
			mouth / 2,
			w,
			mouth,
			-0.005,
			c.Dark,
			Enum.Material.SmoothPlastic
		)
		leaving.Transparency = 1
		-- its header beam, then the bare wall to the next landing's apron
		local top = mouth + s.Header
		piece(ride, "Header", 0, mouth + s.Header / 2, w, s.Header, 0.006, c.Steel, metal)
		local apron = rise - s.Sill - s.Apron
		local wall = piece(ride, "Wall", 0, (top + apron) / 2, w, apron - top, 0, c.Wall, concrete)
		for i, h in s.Seams do
			piece(ride, `Seam{i}`, 0, top + h, w, 0.06, 0.004, c.Seam, concrete)
		end
		-- the next floor's number, painted on the bare wall
		local number = s.Number
		local paint = Instance.new("SurfaceGui")
		paint.Name = "Number"
		paint.Face = Enum.NormalId.Back -- the car's side
		paint.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		paint.PixelsPerStud = PAINT_PIXELS
		paint.LightInfluence = 1 -- paint, lit by the car's lamp
		paint.MaxDistance = 40
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 1)
		-- seen from the car, the painted face runs from the part's -X (left) to its +X
		label.Position =
			UDim2.new(0.5 + number.X / w, 0, 1, -math.floor(number.Above * PAINT_PIXELS))
		label.Size = UDim2.fromOffset(
			math.floor(number.Height * 0.8 * PAINT_PIXELS),
			math.floor(number.Height * PAINT_PIXELS)
		)
		label.Text = tostring(to)
		label.TextScaled = true
		label.FontFace = Font.new(Font.fromEnum(Enum.Font.Oswald).Family, Enum.FontWeight.Bold)
		label.TextColor3 = rgb(c.Paint)
		label.TextTransparency = 0.18 -- worn
		label.Parent = paint
		paint.Parent = wall
		-- the next landing: its apron, its sill, the dark of its hall, its header and the wall over
		piece(ride, "Apron", 0, apron + s.Apron / 2, w, s.Apron, 0.008, c.Apron, metal)
		piece(
			ride,
			"Sill",
			0,
			rise - s.Sill / 2,
			w,
			s.Sill,
			0.012,
			c.Sill,
			Enum.Material.DiamondPlate
		)
		local arriving = piece(
			ride,
			"Arriving",
			0,
			rise + mouth / 2,
			w,
			mouth,
			-0.005,
			c.Dark,
			Enum.Material.SmoothPlastic
		)
		piece(
			ride,
			"NextHeader",
			0,
			rise + mouth + s.Header / 2,
			w,
			s.Header,
			0.006,
			c.Steel,
			metal
		)
		piece(ride, "Above", 0, rise + top + s.Below / 2, w, s.Below, 0, c.Wall, concrete)
		local n = #ride.pieces
		local parts: { BasePart } = table.create(n)
		local homes: { CFrame } = table.create(n)
		local places: { CFrame } = table.create(n)
		local pivot = model:GetPivot()
		for i, p in ride.pieces do
			parts[i] = p.part
			homes[i] = pivot * p.at
			places[i] = homes[i]
			p.part.CFrame = homes[i]
		end
		folder.Parent = model
		return {
			model = model,
			at = at,
			from = from,
			to = to,
			folder = folder,
			pieces = ride.pieces,
			parts = parts,
			homes = homes,
			places = places,
			leaving = leaving,
			arriving = arriving,
			since = -math.huge,
		}
	end

	local function play(cue: Ride.Cue, late: number)
		local s = sounds[cue.sound]
		local row = Ride.Sounds[cue.sound]
		if not s then
			return
		end
		local from = row.Start + late * cue.pitch
		if from >= row.Stop then
			return
		end
		local fading = fades[s]
		if fading then
			fading:Cancel()
			fades[s] = nil
		end
		s.PlaybackSpeed = cue.pitch
		s.Volume = row.Volume * cue.volume
		s.TimePosition = from
		s:Play()
		if row.Fade > 0 then
			-- fade out over the stretch's last Fade seconds (at this pitch), so the cut is silent
			local length = row.Stop - from
			local tween = TweenService:Create(
				s,
				TweenInfo.new(
					math.min(row.Fade, length) / cue.pitch,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In,
					0,
					false,
					math.max(length - row.Fade, 0) / cue.pitch
				),
				{ Volume = 0 }
			)
			tween:Play()
			fades[s] = tween
		end
	end

	-- The ride is over (or gone): the shaft goes, the view is let go, the motor's stopped.
	local function finish()
		local ride = current
		if not ride then
			return
		end
		current = nil
		hold(nil)
		ride.folder:Destroy()
		for _, s in { motorSound, rumbleSound } do
			if s then
				s:Stop()
			end
		end
	end

	-- The view's motion this frame, read off the ride's clock.
	local function pose(): CFrame?
		local ride = current
		if not ride then
			return nil
		end
		local lift, nod, roll = Ride.sway(RideClock(ride.at))
		return CFrame.new(0, lift, 0) * CFrame.Angles(nod, 0, roll)
	end

	-- Something about `model`'s ride changed: begin it, follow it to this car, or let it go.
	local function check(model: Model)
		local at, from, to = Ride.decode(model:GetAttribute(Ride.Attribute))
		local ride = current
		if ride and ride.model == model and not at then
			finish() -- armed again: the ride's long over
			return
		end
		if not at or now() - at > STALE then
			return
		end
		if ride and math.abs(ride.at - at) < 1e-3 then
			-- the same ride on another car (L-08b's hand-off): follow it if this player's in it
			if ride.model ~= model and inCar(model) then
				local pivot = model:GetPivot()
				ride.model = model
				ride.folder.Parent = model
				for i, p in ride.pieces do
					ride.homes[i] = pivot * p.at
				end
			end
			return
		end
		local leftAt, ids = Departure.decodeAboard(model:GetAttribute(Departure.AboardAttribute))
		local rode = leftAt ~= nil
			and math.abs(leftAt - at) < 1e-3
			and table.find(ids, Players.LocalPlayer.UserId) ~= nil
		if not rode then
			return
		end
		finish()
		current = lay(model, from, to, at)
		hold(pose)
	end

	local function unwatch(inst: Instance)
		local conns = watched[inst :: Model]
		if not conns then
			return
		end
		watched[inst :: Model] = nil
		for _, c in conns do
			c:Disconnect()
		end
		local ride = current
		if ride and ride.model == inst then
			finish()
		end
	end

	local function watch(inst: Instance)
		if not inst:IsA("Model") or watched[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local model = inst
		local function changed()
			check(model)
		end
		watched[model] = {
			model:GetAttributeChangedSignal(Ride.Attribute):Connect(changed),
			model:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(changed),
		}
		check(model)
	end

	local function step(_: any, _dt: number)
		local ride = current
		if not ride then
			return
		end
		if not ride.model.Parent then
			finish()
			return
		end
		local since = RideClock(ride.at)
		if since >= Ride.opens() then
			finish()
			return
		end
		-- the shaft slides down past the gate
		local down = ride.model:GetPivot().UpVector * -Ride.climbed(since)
		local homes, places = ride.homes, ride.places
		for i, home in homes do
			places[i] = home + down
		end
		Workspace:BulkMoveTo(ride.parts, places, Enum.BulkMoveMode.FireCFrameChanged)
		local leaving, arriving = 1 - Ride.leaving(since), 1 - Ride.arriving(since)
		if ride.leaving.Transparency ~= leaving then
			ride.leaving.Transparency = leaving
		end
		if ride.arriving.Transparency ~= arriving then
			ride.arriving.Transparency = arriving
		end
		-- the sounds whose moment has come since last frame
		local was = ride.since
		ride.since = since
		for _, cue in cues do
			if cue.at > was and cue.at <= since then
				play(cue, since - cue.at)
			end
		end
		-- the motor and the rumble follow the car's speed
		local motor = motorSound
		if motor and motor.IsPlaying then
			local pitch, volume = Ride.motor(since)
			motor.PlaybackSpeed = pitch
			motor.Volume = Ride.Motor.Volume * volume
		end
		local rumble = rumbleSound
		if rumble and rumble.IsPlaying then
			local share = Ride.share(since)
			rumble.Volume = Ride.Rumble.Volume * share
			rumble.PlaybackSpeed = 0.9 + 0.1 * share
		end
	end

	local system: Brix.System = {
		name = "RideView",
		start = function(_: any, _context: Brix.Context)
			local ids: { string } = {}
			for _, name in Ride.Names do
				local row = Ride.Sounds[name]
				local s = Instance.new("Sound")
				s.Name = `Ride{name}`
				s.SoundId = row.Id
				s.PlaybackRegionsEnabled = true
				s.PlaybackRegion = NumberRange.new(row.Start, row.Stop)
				s.Volume = row.Volume
				s.Parent = SoundService -- flat: you're inside the box the sound comes from
				sounds[name] = s
				if name == "Motor" then
					motorSound = s
				elseif name == "Rumble" then
					rumbleSound = s
				end
				if not table.find(ids, row.Id) then
					table.insert(ids, row.Id)
				end
			end
			task.spawn(SoundPrimer.prime, ids)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(watch)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(unwatch)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				watch(inst)
			end
		end,
		step = step,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in watched do
				unwatch(model)
			end
			finish()
			for _, tween in fades do
				tween:Cancel()
			end
			table.clear(fades)
			for _, s in sounds do
				s:Destroy()
			end
			table.clear(sounds)
		end,
	}
	return system
end

return RideView
