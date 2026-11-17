--!strict
--[[
	Client system: the RC car's view in the dark, on the driver's screen (F-G1b3c2e, D-255).

	While your view is on the car you drive (DriveView's `hull`), this screen judges the light at
	the car ten times a second. It's lit, and the view stays in normal colour, in a hall light's
	pool while that light is lit (each fixture's state, `MotionLight.StateAttribute`: one dark, cut
	by a breaker or out for the alarm is no light), in a unit whose door is up (its bulb is wired
	to its door, `ShutIn.bulb`), or near the freight elevator's lamp. Anywhere else in the
	building's halls it's dark, and the view goes infrared, as Outlast's camcorder sees: black and
	white with a green cast (a ColorCorrection in Lighting) and the security feed's grain crawling
	over it, lit by a lamp on the hood that only this screen has (a SpotLight about 30 studs
	ahead). Friends see no light, and nothing in the game's rules sees it: it holds no Mannequin.
	Out of the halls altogether (the lobby, lit by its own lamps) it stays in colour.

	The switch answers both ways: a small relay click in your ears and a quick flicker between the
	two looks (`Infrared.shown`), as a security camera's night mode snaps over. A light tripped
	near the car, or the power back on, flicks it back to colour the same way. The first judging
	waits for your view to land on the hood.

	In infrared, each monster near the car and facing it has two white points for eyes
	(`Infrared.Eyes`, by its row), brightest near and fading toward their reach: billboards on
	attachments of this screen's own, moved to its head each frame, so nothing is added to its
	body. A wall hides them as it hides the monster.

	Back, caught, or the car taken back: your own eyes in full colour at once, with no click.
]]
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Drive = require(ReplicatedStorage.Shared.Finds.Drive)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Feed = require(ReplicatedStorage.Shared.Feed)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local Infrared = require(ReplicatedStorage.Shared.Finds.Infrared)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local ShutIn = require(ReplicatedStorage.Shared.StorageUnit.ShutIn)
local SoundPrimer = require(script.Parent.SoundPrimer)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local player = Players.LocalPlayer

local KEEPER_TAG = "Keeper" -- on each monster's body (the server's Keepers)
local ROW_ATTRIBUTE = "Keeper" -- and its row's name
local LIT: MotionLight.Look = "Lit"
local TILE = 128 -- points each tile of grain covers (the feed's: one point a pixel)
local LAMP_UP = 0.1 -- studs over your view the lamp rides, clear of the hood
-- Studs from a unit's door within which the car may be in it: past a big unit's depth.
local UNIT_NEAR = 30
type Eye = { at: Attachment, gui: BillboardGui, dot: Frame }
type Eyes = { left: Eye, right: Eye, spot: Infrared.EyeSpot, shown: boolean }

local InfraredView = {}

local function makeEye(name: string): Eye
	local at = Instance.new("Attachment")
	at.Name = name
	local gui = Instance.new("BillboardGui")
	gui.Name = "Shine"
	gui.Size = UDim2.new(Infrared.EyeStuds, Infrared.EyeDot, Infrared.EyeStuds, Infrared.EyeDot)
	gui.AlwaysOnTop = false -- a wall, or its own head turned away, hides it
	gui.LightInfluence = 0
	gui.Brightness = Infrared.EyeGlow
	gui.MaxDistance = Infrared.EyeReach + 4
	gui.Enabled = false
	gui.Adornee = at
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromScale(1, 1)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = dot
	dot.Parent = gui
	gui.Parent = at
	at.Parent = Workspace.Terrain -- world space, this screen's own
	return { at = at, gui = gui, dot = dot }
end

-- `hull` gives the car your view is on (DriveView's), nil while your view is home.
function InfraredView.new(hull: () -> BasePart?): Brix.System
	local connections: { RBXScriptConnection } = {}
	-- the hall lights and units, read where they stand at each judging: a floor tags them before
	-- it has finished moving them into place
	local fixtures: { [Model]: true } = {}
	local units: { [Model]: true } = {}
	local lamps: { [PointLight]: true } = {} -- the freight elevators' lamps
	local bodies: { [Model]: true } = {} -- every monster's body on this screen
	local eyes: { [Model]: Eyes } = {} -- the eyes made so far, for those that have shone
	local look: ColorCorrectionEffect? = nil
	local gui: ScreenGui? = nil
	local grain: ImageLabel? = nil
	local lamp: SpotLight? = nil
	local lampPart: Part? = nil
	local click: Sound? = nil
	local random = Random.new()

	local on = false -- your view is on a car
	local judgeIn = 0 -- seconds to the next judging
	local dark = false -- the light at the car, as last judged
	local switched = -math.huge -- os.clock of the last switch
	local showing = false -- infrared on the screen now

	-- Whether feet `at` are in light, the view now `wasDark` (a pool's edge holds what it shows),
	-- and what lights them or why not (for Studio's Output).
	local function lit(at: Vector3, wasDark: boolean): (boolean, string)
		local x, y, z = at.X, at.Y, at.Z
		for unit in units do
			-- its door's part, streamed in (a unit's parts may stream out apart from it)
			local origin = unit:FindFirstChild("DoorOrigin", true)
			if
				origin
				and origin:IsA("BasePart")
				and origin:IsDescendantOf(Workspace)
				and (origin.Position - at).Magnitude < UNIT_NEAR
			then
				local p = RollUpDoor.frame(unit):PointToObjectSpace(at)
				if
					ShutIn.inside(RollUpDoor.room(unit), p.X, p.Y, p.Z)
					and RollUpDoor.rise(unit) > ShutIn.BulbOffRise
				then
					return true, `{unit.Name}'s bulb` -- in a unit, its door up: its bulb is lit
				end
			end
		end
		for light in lamps do
			local holder = light.Parent
			if
				light.Enabled
				and holder
				and holder:IsA("Attachment")
				-- streamed out with its part, an attachment reads as if at the world's middle
				and holder:IsDescendantOf(Workspace)
				and (holder.WorldPosition - at).Magnitude <= light.Range * Infrared.LampShare
			then
				return true, "the elevator's lamp"
			end
		end
		local reach = Infrared.reach(wasDark)
		local halls = false
		for model in fixtures do
			local spot = model:GetPivot().Position
			if Infrared.near(spot.X, spot.Y, spot.Z, x, y, z, Infrared.Building) then
				halls = true
				if
					model:GetAttribute(MotionLight.StateAttribute) == LIT
					and Infrared.near(spot.X, spot.Y, spot.Z, x, y, z, reach)
				then
					return true, "a hall light"
				end
			end
		end
		-- out of the building's halls, the place's own lamps light it
		return not halls, if halls then "the hall's lights out" else "out of the halls"
	end

	local function eyesOf(body: Model): Eyes?
		local e = eyes[body]
		if e then
			return e
		end
		local row = body:GetAttribute(ROW_ATTRIBUTE)
		local spot = if type(row) == "string" then (Infrared.Eyes :: any)[row] else nil -- any: by its row's name
		if not spot then
			return nil
		end
		local made: Eyes = {
			left = makeEye("InfraredEyeLeft"),
			right = makeEye("InfraredEyeRight"),
			spot = spot :: Infrared.EyeSpot,
			shown = false,
		}
		eyes[body] = made
		return made
	end

	local function hideEyes(e: Eyes)
		if e.shown then
			e.shown = false
			e.left.gui.Enabled = false
			e.right.gui.Enabled = false
		end
	end

	-- Each monster's eyes this frame, from your view at `eye`.
	local function shine(eye: Vector3)
		for body in bodies do
			local head = body:FindFirstChild("Head")
			local e: Eyes? = eyes[body]
			if head and head:IsA("BasePart") then
				local frame = head.CFrame
				local to = eye - frame.Position
				local distance = to.Magnitude
				local k = if distance > 0.1
					then Infrared.shine(distance, frame.LookVector:Dot(to / distance))
					else 0
				if k > 0 then
					e = e or eyesOf(body)
				end
				if e then
					if k > 0 then
						local s = e.spot
						e.left.at.WorldPosition =
							frame:PointToWorldSpace(Vector3.new(-s.apart / 2, s.up, -s.ahead))
						e.right.at.WorldPosition =
							frame:PointToWorldSpace(Vector3.new(s.apart / 2, s.up, -s.ahead))
						local see = 1 - k
						e.left.dot.BackgroundTransparency = see
						e.right.dot.BackgroundTransparency = see
						if not e.shown then
							e.shown = true
							e.left.gui.Enabled = true
							e.right.gui.Enabled = true
						end
					else
						hideEyes(e)
					end
				end
			elseif e then
				hideEyes(e)
			end
		end
	end

	local function show(infrared: boolean)
		if infrared == showing then
			return
		end
		showing = infrared
		if look then
			look.Enabled = infrared
		end
		if gui then
			gui.Enabled = infrared
		end
		if lamp then
			lamp.Enabled = infrared
		end
		if not infrared then
			for _, e in eyes do
				hideEyes(e)
			end
		end
	end

	local function addFixture(inst: Instance)
		if inst:IsA("Model") and inst:IsDescendantOf(Workspace) then
			fixtures[inst] = true
		end
	end

	local function addUnit(inst: Instance)
		-- only units in the world (the template in ReplicatedStorage carries the tag too)
		if
			inst:IsA("Model")
			and inst:IsDescendantOf(Workspace)
			and inst:FindFirstChild("DoorOrigin", true)
		then
			units[inst] = true
		end
	end

	local function addElevator(inst: Instance)
		if not inst:IsDescendantOf(Workspace) then
			return
		end
		local at = inst:FindFirstChild("LampLight", true)
		local light = at and at:FindFirstChildOfClass("PointLight")
		if light then
			lamps[light] = true
		end
	end

	local function removeElevator(inst: Instance)
		for light in lamps do
			if light:IsDescendantOf(inst) or light.Parent == nil then
				lamps[light] = nil
			end
		end
	end

	local function addBody(inst: Instance)
		if inst:IsA("Model") then
			bodies[inst] = true
		end
	end

	local function removeBody(inst: Instance)
		local e = eyes[inst :: Model]
		bodies[inst :: Model] = nil
		eyes[inst :: Model] = nil
		if e then
			e.left.at:Destroy()
			e.right.at:Destroy()
		end
	end

	-- Each of the tagged things this screen follows, as they stream in and out.
	local function follow(tag: string, add: (Instance) -> (), remove: (Instance) -> ())
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst: Instance)
				task.defer(add, inst) -- a streamed model's parts all in place first
			end)
		)
		table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(remove))
		for _, inst in CollectionService:GetTagged(tag) do
			add(inst)
		end
	end

	local function make()
		local c = Instance.new("ColorCorrectionEffect")
		c.Name = "CarInfrared"
		c.Saturation = Infrared.Saturation
		c.TintColor = Color3.fromRGB(Infrared.Tint[1], Infrared.Tint[2], Infrared.Tint[3])
		c.Contrast = Infrared.Contrast
		c.Brightness = Infrared.Brightness
		c.Enabled = false
		c.Parent = Lighting -- made on this screen, so it's yours alone
		look = c

		local g = Instance.new("ScreenGui")
		g.Name = "CarInfrared"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 4 -- under the Back button (DriveView's, 5)
		g.Enabled = false
		local l = Instance.new("ImageLabel")
		l.Name = "Grain"
		l.Image = Feed.Grain
		l.ScaleType = Enum.ScaleType.Tile
		l.TileSize = UDim2.fromOffset(TILE, TILE)
		l.Size = UDim2.new(1, TILE * 2, 1, TILE * 2) -- room to jump without an edge showing
		l.BackgroundTransparency = 1
		l.ImageTransparency = Infrared.GrainSee
		l.Parent = g
		g.Parent = player:WaitForChild("PlayerGui")
		gui, grain = g, l

		local folder = Instance.new("Folder")
		folder.Name = "YourInfrared"
		local p = Instance.new("Part")
		p.Name = "Lamp"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.one * 0.2
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front
		s.Range = Infrared.LampRange
		s.Angle = Infrared.LampAngle
		s.Brightness = Infrared.LampBrightness
		s.Color = Color3.new(1, 1, 1)
		s.Shadows = true
		s.Enabled = false
		s.Parent = p
		p.Parent = folder
		folder.Parent = Workspace
		lamp, lampPart = s, p

		local k = Instance.new("Sound")
		k.Name = "InfraredClick"
		k.SoundId = HallLight.ClickSound
		k.Volume = Infrared.ClickVolume
		k.Parent = SoundService -- flat in your ears
		click = k
	end

	local system = { name = "InfraredView" }

	function system.start(_: any)
		SoundPrimer.prime({ HallLight.ClickSound })
		task.spawn(make)
		follow(MotionLight.Tag, addFixture, function(inst: Instance)
			fixtures[inst :: Model] = nil
		end)
		follow(UnitKit.Tag, addUnit, function(inst: Instance)
			units[inst :: Model] = nil
		end)
		follow(Elevator.Tag, addElevator, removeElevator)
		follow(KEEPER_TAG, addBody, removeBody)
	end

	function system.step(_: any, dt: number)
		local h = hull()
		local camera = Workspace.CurrentCamera
		if not (h and h.Parent and camera) then
			if on then
				on = false
				show(false) -- your own eyes, in colour at once
			end
			return
		end
		if not on then
			on, dark, switched = true, false, -math.huge
			judgeIn = Drive.Drop -- once your view has landed on the hood
		end
		judgeIn -= dt
		if judgeIn <= 0 then
			judgeIn = Infrared.Every
			local feet = h.Position - Vector3.new(0, Drive.HullHeight / 2, 0)
			local light, why = lit(feet, dark)
			if light == dark then
				dark, switched = not light, os.clock()
				if RunService:IsStudio() then
					print(`InfraredView: {if dark then "infrared" else "colour"} ({why})`)
				end
				local k = click
				if k then
					k.PlaybackSpeed = if dark then Infrared.ClickToDark else Infrared.ClickToColour
					k:Play()
				end
			end
		end
		local new = Infrared.shown(os.clock() - switched)
		show(if new then dark else not dark)
		if not showing then
			return
		end
		local view = camera.CFrame
		local p = lampPart
		if p then
			p.CFrame = view * CFrame.new(0, LAMP_UP, 0)
		end
		local g = grain
		if g then
			-- the grain jumps by whole pixels, even rows down: it crawls, the scanlines hold
			g.Position = UDim2.fromOffset(
				-random:NextInteger(0, TILE - 1),
				-2 * random:NextInteger(0, TILE / 2 - 1)
			)
		end
		shine(view.Position)
	end

	function system.stop(_: any)
		show(false)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for body in bodies do
			removeBody(body)
		end
		for _, thing in { look, gui, click } :: { Instance? } do
			if thing then
				thing:Destroy()
			end
		end
		local p = lampPart
		if p then
			local folder = p.Parent
			p:Destroy()
			if folder then
				folder:Destroy()
			end
		end
		look, gui, grain, lamp, lampPart, click = nil, nil, nil, nil, nil, nil
	end

	return system :: any -- any: a plain Brix system built field by field
end

return InfraredView
