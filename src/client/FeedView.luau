--!strict
--[[
	FeedView: the security camera feed on this screen (S2-02d; `Feed`'s numbers, the server's
	`Feeds` decides when).

	The moment: you're deep in a hall and the corner map snaps to snow with a burst of
	interference, then to a grainy, cold, choppy camera picture of the breaker box down some other
	hall, "CAM 07" in the corner and a red dot blinking. The Mannequin steps into it, stiff, and
	stops at the box. The lever slams down; the clunk comes thin through the camera's speaker, the
	picture jolts and the hall in it goes dark. It stands there. Static, and the map is back. As
	Five Nights at Freddy's cameras catch the animatronic where it wasn't. No words.

	How: the picture is a ViewportFrame grown out of the map's own square (`Feed.Grow`, 4:3),
	which draws only what's put inside it. As a feed starts, the halls in front of the camera
	(`Feed.Reach`) are copied into it once, each part with only what draws it; what the server
	names to watch (the monster's body, the box) is copied too and, `Feed.Fps` times a second, each
	of its parts takes its real part's place and colour, so the walk and the lever move in it in
	an old camera's choppy frames. Its light is its own, flat and cold (`Feed.Ambient`, tinted
	`Feed.Tint`): a security camera sees whether the halls are lit or not, until the moment says the
	lights went (`dim`): then the picture drops darker and its copied tubes go out.

	Over it: the grain (art/feed, moved to a new place each frame so it crawls), a soft shade top
	and bottom, a faint bright band rolling down, the number and the dot. The snow (art/feed) covers
	it as it cuts in and out. Sounds are flat in your ears: a burst in, quiet static under it, the
	moment's own sound through a thin speaker, a burst out.

	Only a showing feed is stepped; nothing allocates per frame.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Feed = require(ReplicatedStorage.Shared.Feed)
local SoundPrimer = require(script.Parent.SoundPrimer)

local MAP_GUI, MAP_WINDOW = "Minimap", "Window" -- MinimapView's corner map, which it covers
local RIM = Color3.fromRGB(230, 226, 214) -- the map's rim, so the window reads as the same one
local RIM_SEE = 0.65
local BLACK = Color3.fromRGB(6, 8, 9)
local TILE = 128 -- points each tile of grain or snow covers: one point a pixel
local MOST_PARTS = 700 -- a hall's parts copied in at most: a phone's budget for a few seconds
local ROLL_TIME = 2.6 -- seconds the faint bright band takes to roll down the picture
local SNOW_FADE = 0.1 -- seconds the snow takes to clear once the picture is up
local JOLT = 0.07 -- seconds the picture jumps at the moment
local JOLT_POINTS = 3
local FLASH_SEE = 0.35 -- the snow's flash at the moment, see-through this much
local DIM_TIME = 0.25 -- seconds the picture takes to drop darker after the moment
-- The feed's layers start here: the map's screen layers its window by one ZIndex for all, so the
-- feed and everything on it sit above the map's own.
local Z = 10
local SHRINK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- What a copied part keeps: only what draws it.
local DRAWS: { [string]: boolean } =
	{ SurfaceAppearance = true, Decal = true, Texture = true, SpecialMesh = true }

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

type Pair = { from: BasePart, to: BasePart }

type Showing = {
	id: number,
	own: ScreenGui?, -- its own screen, only when the map's isn't up
	screen: Frame,
	view: ViewportFrame,
	grain: ImageLabel,
	snow: ImageLabel,
	roll: Frame,
	dot: Frame,
	pairs: { Pair },
	lit: { BasePart }, -- the copied halls' glowing parts: out when the moment puts the lights out
	small: UDim2, -- the map's square, what it grows from and shrinks back to
	began: number, -- os.clock as it cut in
	moment: number, -- os.clock of the moment, -1 until it comes
	ends: number, -- os.clock it starts cutting out
	frame: number, -- os.clock of the picture's last frame
	bed: Sound,
	out: boolean, -- cutting out: the snow is up and the out burst played
}

local FeedView = {}

function FeedView.new(): Brix.System
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local showing: Showing? = nil
	local random = Random.new()

	local function sound(id: string, volume: number, looped: boolean): Sound
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.Looped = looped
		s.Parent = SoundService
		return s
	end

	local function once(id: string, volume: number, thin: boolean)
		local s = sound(id, volume, false)
		if thin then
			-- through a camera's little speaker: no body, a rasp on top
			local eq = Instance.new("EqualizerSoundEffect")
			eq.LowGain, eq.MidGain, eq.HighGain = -30, 3, -12
			eq.Parent = s
			local grit = Instance.new("DistortionSoundEffect")
			grit.Level = 0.35
			grit.Parent = s
		end
		s.Ended:Once(function()
			s:Destroy()
		end)
		s:Play()
	end

	-- The map's window on this screen: the feed goes in the map's own screen, its top-right
	-- corner on the window's, so the two always line up; and the window's square. No map up (it
	-- shouldn't happen on a floor): nil, and a place like the map's.
	local function mapWindow(): (ScreenGui?, UDim2, Vector2)
		local gui = me:FindFirstChildOfClass("PlayerGui")
		local map = gui and gui:FindFirstChild(MAP_GUI)
		local window = map and map:FindFirstChild(MAP_WINDOW)
		if
			map
			and map:IsA("ScreenGui")
			and window
			and window:IsA("GuiObject")
			and window.Visible
			and window.AbsoluteSize.X > 0
		then
			return map, window.Position, window.AbsoluteSize
		end
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local side = math.clamp(view.Y * 0.3, 104, 176) -- as the map's own
		return nil, UDim2.fromOffset(view.X - 10, 68), Vector2.new(side, side)
	end

	-- A copy of `part` with only what draws it, or nil if it can't be copied.
	local function drawn(part: BasePart): BasePart?
		if not part.Archivable then
			return nil
		end
		local copy = part:Clone()
		for _, child in copy:GetChildren() do
			if not DRAWS[child.ClassName] then
				child:Destroy()
			end
		end
		copy.Anchored = true
		return copy
	end

	-- Pairs each part under `from` with its copy under `to`, child by child (a child that didn't
	-- copy is passed over).
	local function pair(from: Instance, to: Instance, out: { Pair })
		local copies = to:GetChildren()
		local j = 1
		for _, child in from:GetChildren() do
			local other = copies[j]
			if other and other.Name == child.Name and other.ClassName == child.ClassName then
				j += 1
				if child:IsA("BasePart") and other:IsA("BasePart") then
					table.insert(out, { from = child, to = other })
				end
				pair(child, other, out)
			end
		end
	end

	-- Copies what the camera sees into `s.view`: the halls once, the watched things to follow.
	-- (The halls' pieces don't answer spatial queries, CanQuery off, so `within`'s parts are each
	-- tested against the lens's view: once a feed, a floor's few thousand parts in a millisecond
	-- or two.)
	local function build(s: Showing, camera: CFrame, watch: { Instance }, within: Instance?)
		local world = Instance.new("Model")
		world.Name = "Halls"
		local up = math.tan(math.rad(Feed.Fov / 2))
		local across = up / Feed.Aspect
		local copied = 0
		local all: { Instance } = if within then within:GetDescendants() else {}
		for _, part in all do
			if not part:IsA("BasePart") or part.Transparency >= 0.98 then
				continue
			end
			local p = camera:PointToObjectSpace(part.Position)
			local depth, r = -p.Z, part.Size.Magnitude / 2
			if
				depth < -r
				or depth > Feed.Reach + r
				or math.abs(p.X) > math.max(depth, 0) * across + r
				or math.abs(p.Y) > math.max(depth, 0) * up + r
			then
				continue -- out of the lens's view
			end
			local watched = false
			for _, inst in watch do
				if part == inst or part:IsDescendantOf(inst) then
					watched = true
					break
				end
			end
			if watched or copied >= MOST_PARTS then
				continue
			end
			copied += 1
			local copy = drawn(part)
			if copy then
				if copy.Material == Enum.Material.Neon then
					table.insert(s.lit, copy)
				end
				copy.Parent = world
			end
		end
		world.Parent = s.view
		for _, inst in watch do
			if not inst.Archivable then
				continue
			end
			local copy = inst:Clone()
			pair(inst, copy, s.pairs)
			if inst:IsA("BasePart") and copy:IsA("BasePart") then
				table.insert(s.pairs, { from = inst, to = copy })
			end
			for _, d in copy:GetDescendants() do
				if
					d.Parent
					and not (d:IsA("BasePart") or d:IsA("Model") or d:IsA("Folder"))
					and not DRAWS[d.ClassName]
				then
					d:Destroy()
				end
			end
			copy.Parent = s.view
		end
	end

	-- Each of the watched things' parts takes its real part's place and colour: one frame.
	local function picture(s: Showing)
		for _, p in s.pairs do
			local from, to = p.from, p.to
			if from.Parent then
				to.CFrame = from.CFrame
				if to.Color ~= from.Color then
					to.Color = from.Color
				end
				if to.Transparency ~= from.Transparency then
					to.Transparency = from.Transparency
				end
			end
		end
		-- the grain jumps by whole pixels, even rows down: it crawls, the scanlines hold
		s.grain.Position = UDim2.fromOffset(
			-random:NextInteger(0, TILE - 1),
			-2 * random:NextInteger(0, TILE / 2 - 1)
		)
	end

	local function finish()
		local s = showing
		if not s then
			return
		end
		showing = nil
		s.bed:Destroy()
		s.screen:Destroy()
		if s.own then
			s.own:Destroy()
		end
	end

	local function show(
		id: number,
		camera: CFrame,
		number: number,
		watch: { Instance },
		within: Instance?
	)
		finish() -- a new feed takes the window at once
		local map, corner, square = mapWindow()
		local small = UDim2.fromOffset(square.X, square.Y)
		local width = math.floor(square.X * Feed.Grow)
		local big = UDim2.fromOffset(width, math.floor(width * Feed.Aspect))

		local own: ScreenGui? = nil
		if not map then
			local gui = Instance.new("ScreenGui")
			gui.Name = "Feed"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = true
			gui.DisplayOrder = 5 -- over the map's 4
			own = gui
		end
		local screen = Instance.new("Frame")
		screen.AnchorPoint = Vector2.new(1, 0)
		screen.Position = corner
		screen.ZIndex = Z -- over the map's window, its sibling
		screen.Size = small
		screen.BackgroundColor3 = BLACK
		screen.BorderSizePixel = 0
		screen.ClipsDescendants = true
		screen.Name = "Feed"
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0, 10)
		round.Parent = screen
		local rim = Instance.new("UIStroke")
		rim.Color = RIM
		rim.Transparency = RIM_SEE
		rim.Thickness = 1.5
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Parent = screen

		local view = Instance.new("ViewportFrame")
		view.Name = "Picture"
		view.Size = UDim2.fromScale(1, 1)
		view.BackgroundColor3 = BLACK
		view.BorderSizePixel = 0
		view.ImageColor3 = rgb(Feed.Tint)
		view.Ambient = rgb(Feed.Ambient)
		view.LightColor = rgb(Feed.Light)
		view.LightDirection = (camera.LookVector + Vector3.new(0, -1.2, 0)).Unit
		view.ZIndex = Z + 1
		local lens = Instance.new("Camera")
		lens.FieldOfView = Feed.Fov
		lens.CFrame = camera
		lens.Parent = view
		view.CurrentCamera = lens
		view.Parent = screen

		local shade = Instance.new("Frame")
		shade.Name = "Shade"
		shade.Size = UDim2.fromScale(1, 1)
		shade.BackgroundColor3 = Color3.new(0, 0, 0)
		shade.BorderSizePixel = 0
		shade.ZIndex = Z + 2
		local fall = Instance.new("UIGradient")
		fall.Rotation = 90
		fall.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.22, 1),
			NumberSequenceKeypoint.new(0.78, 1),
			NumberSequenceKeypoint.new(1, 0.25),
		})
		fall.Parent = shade
		shade.Parent = screen

		local roll = Instance.new("Frame")
		roll.Name = "Roll"
		roll.Size = UDim2.fromScale(1, 0.2)
		roll.BackgroundColor3 = Color3.new(1, 1, 1)
		roll.BackgroundTransparency = 0.95
		roll.BorderSizePixel = 0
		roll.ZIndex = Z + 2
		roll.Parent = screen

		local function tiled(name: string, image: string, z: number, see: number): ImageLabel
			local l = Instance.new("ImageLabel")
			l.Name = name
			l.Image = image
			l.ScaleType = Enum.ScaleType.Tile
			l.TileSize = UDim2.fromOffset(TILE, TILE)
			l.Size = UDim2.new(1, TILE * 2, 1, TILE * 2) -- room to jump without an edge showing
			l.BackgroundTransparency = 1
			l.ImageTransparency = see
			l.ZIndex = Z + z
			l.Parent = screen
			return l
		end
		local grain = tiled("Grain", Feed.Grain, 3, Feed.GrainSee)

		local label = Instance.new("TextLabel")
		label.Name = "Number"
		label.AnchorPoint = Vector2.new(0, 0)
		label.Position = UDim2.fromScale(0.06, 0.06)
		label.Size = UDim2.fromScale(0.5, 0.13)
		label.BackgroundTransparency = 1
		label.FontFace = Font.fromEnum(Enum.Font.Code)
		label.Text = string.format("CAM %02d", number)
		label.TextColor3 = Color3.fromRGB(232, 238, 236)
		label.TextStrokeTransparency = 0.45
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = Z + 4
		label.Parent = screen

		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.AnchorPoint = Vector2.new(1, 0)
		dot.Position = UDim2.fromScale(0.94, 0.075)
		dot.Size = UDim2.fromScale(0.09, 0.09)
		dot.BackgroundColor3 = rgb(Feed.Dot)
		dot.BorderSizePixel = 0
		dot.ZIndex = Z + 4
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 1
		ratio.DominantAxis = Enum.DominantAxis.Height
		ratio.Parent = dot
		local disc = Instance.new("UICorner")
		disc.CornerRadius = UDim.new(0.5, 0)
		disc.Parent = dot
		dot.Parent = screen

		local snow = tiled("Snow", Feed.Snow, 5, 0)

		local now = os.clock()
		local s: Showing = {
			id = id,
			own = own,
			screen = screen,
			view = view,
			grain = grain,
			snow = snow,
			roll = roll,
			dot = dot,
			pairs = {},
			lit = {},
			small = small,
			began = now,
			moment = -1,
			ends = now + Feed.Most,
			frame = 0,
			bed = sound(Feed.BedSound, Feed.BedVolume, true),
			out = false,
		}
		local thin = Instance.new("EqualizerSoundEffect")
		thin.LowGain, thin.MidGain, thin.HighGain = -40, -6, 0
		thin.Parent = s.bed
		build(s, camera, watch, within)
		picture(s)
		showing = s
		if own then
			screen.Parent = own
			own.Parent = me:WaitForChild("PlayerGui")
		else
			screen.Parent = map
		end
		TweenService:Create(
			screen,
			TweenInfo.new(Feed.Pop, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = big }
		):Play()
		once(Feed.InSound, Feed.InVolume, false)
	end

	local function close(id: number, momentSound: string, dim: boolean)
		local s = showing
		if not s or s.id ~= id or s.moment >= 0 then
			return
		end
		local now = os.clock()
		s.moment = now
		s.ends = math.min(s.ends, now + Feed.After)
		if momentSound ~= "" then
			once(momentSound, Feed.MomentVolume, true)
		end
		if dim then
			local into = TweenInfo.new(DIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local light = rgb(Feed.Ambient):Lerp(Color3.new(0, 0, 0), 1 - Feed.Dim)
			local from = rgb(Feed.Light):Lerp(Color3.new(0, 0, 0), 1 - Feed.Dim)
			TweenService:Create(s.view, into, { Ambient = light, LightColor = from }):Play()
			for _, tube in s.lit do
				tube.Material = Enum.Material.SmoothPlastic
				tube.Color = tube.Color:Lerp(Color3.new(0, 0, 0), 0.75)
			end
		end
	end

	local system = { name = "FeedView" }

	function system.start(_: any, _context: Brix.Context)
		task.spawn(SoundPrimer.prime, { Feed.InSound, Feed.BedSound, Feed.OutSound })
		task.spawn(function()
			local remote = ReplicatedStorage:WaitForChild(Feed.Remote)
			if not remote:IsA("RemoteEvent") then
				return
			end
			table.insert(
				connections,
				-- only ever the server's: a Show's camera, number and what to watch; a Close's id
				remote.OnClientEvent:Connect(
					function(
						kind: string,
						id: number,
						a: unknown,
						b: unknown,
						c: unknown,
						d: unknown
					)
						if
							kind == "Show"
							and typeof(a) == "CFrame"
							and type(b) == "number"
							and type(c) == "table"
						then
							local watch: { Instance } = {}
							for _, inst in c :: { unknown } do
								if typeof(inst) == "Instance" then
									table.insert(watch, inst)
								end
							end
							show(id, a, b, watch, if typeof(d) == "Instance" then d else nil)
						elseif kind == "Close" and type(a) == "string" and type(b) == "boolean" then
							close(id, a, b)
						end
					end
				)
			)
		end)
	end

	function system.step(_: any, _dt: number)
		local s = showing
		if not s then
			return
		end
		local now = os.clock()
		local t = now - s.began
		-- the picture's own choppy frames
		if now - s.frame >= 1 / Feed.Fps then
			s.frame = now
			picture(s)
		end
		-- the snow: solid as it cuts in, clearing, a flash at the moment, solid again cutting out
		local see = 1
		if t < Feed.SnowIn then
			see = 0
		elseif t < Feed.SnowIn + SNOW_FADE then
			see = (t - Feed.SnowIn) / SNOW_FADE
		end
		if s.moment >= 0 and now - s.moment < JOLT then
			see = math.min(see, FLASH_SEE)
			s.view.Position = UDim2.fromOffset(0, JOLT_POINTS)
		elseif s.view.Position.Y.Offset ~= 0 then
			s.view.Position = UDim2.new()
		end
		if now >= s.ends then
			see = 0
			if not s.out then
				s.out = true
				s.bed:Stop()
				once(Feed.OutSound, Feed.OutVolume, false)
				task.delay(Feed.SnowOut, function()
					if showing == s then
						TweenService:Create(s.screen, SHRINK, { Size = s.small }):Play()
						task.delay(SHRINK.Time, function()
							if showing == s then
								finish()
							end
						end)
					end
				end)
			end
		elseif t >= Feed.SnowIn and not s.bed.IsPlaying then
			s.bed:Play()
		end
		if s.snow.ImageTransparency ~= see then
			s.snow.ImageTransparency = see
		end
		if see < 1 then
			s.snow.Position =
				UDim2.fromOffset(-random:NextInteger(0, TILE - 1), -random:NextInteger(0, TILE - 1))
		end
		s.dot.Visible = (t % Feed.Blink) < Feed.Blink / 2
		s.roll.Position = UDim2.fromScale(0, (t % ROLL_TIME) / ROLL_TIME * 1.2 - 0.2)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		finish()
	end

	return system
end

return FeedView
