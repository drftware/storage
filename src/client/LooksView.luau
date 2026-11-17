--!strict
--[[
	LooksView: a home's new paint, paper or floor crossing the room on every screen near it
	(S5-03g2b, D-326; idea 18). The moment: you pick a paper and it rolls out from the middle of
	the back wall, round both back corners and down the side walls to the door, with a roller's
	soft squish; pick a floor and it unrolls from the back wall to your feet.

	The server stamps the new look on the unit (`Looks.Attribute`, begun at `Looks.SinceAttribute`)
	and dresses its panels when the wipe is done (`Looks.WornAttribute`). Meanwhile each screen
	lays thin sheets of the new look over the old and grows them: a plain part in the paint or
	floor colour with the set's colour map as a Texture (its clear bits show the colour, as the
	panels' Overlay does), tiled in studs and lined up with the panels' own tiles, so nothing
	jumps when the real panels change under it. The front wall's inside, round the doorway, fades
	in as the wipe reaches it, a copy of its panel. The sheets go once the panels wear the look.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local Specs = require(ReplicatedStorage.Shared.Home.Specs)

-- Which way a Texture's OffsetStudsU and V move its tiles (Studio, S5-03g2b): 1 when a larger
-- offset moves them right and down as you face the texture.
local SHIFT = 1
local GAP = 0.01 -- how far a sheet stands off the face it covers, clear of flicker
local SHEET = 0.02 -- a sheet's thickness
-- the roller: Aurarus's "Paint Roller", a wet squish; the floor's lower, a heavier roll
local ROLLER = "rbxassetid://252778323"
local ROLLER_VOLUME = 0.55
local FLOOR_PITCH = 0.8
local HEARD = 45 -- studs: heard across your home and the hall outside it, not the lobby
local LATE = 3 -- seconds past the wipe a sheet waits for the panels before it goes anyway

-- One wall a wipe crosses: where it stands, how far round the room its middle is, half its width.
type Wall = { cf: CFrame, mid: number, half: number, sheet: Part, texture: Texture }
type Wipe = {
	unit: Model,
	target: string,
	since: number,
	round: number,
	height: number,
	walls: { Wall },
	front: MeshPart?,
	frontFrom: number,
	frontSpan: number,
	floor: Part?,
	floorTexture: Texture?,
	floorCf: CFrame,
	floorDeep: number,
	floorTop: number,
	folder: Folder,
	sound: Sound?,
}

local LooksView = {}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function sheet(colour: string, folder: Folder): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = if colour ~= "" then Color3.fromHex(colour) else Color3.new(1, 1, 1)
	p.Size = Vector3.new(0.05, 0.05, SHEET)
	p.Transparency = 1
	p.Parent = folder
	return p
end

local function texture(part: Part, uri: string, tile: number): Texture
	local t = Instance.new("Texture")
	t.Face = Enum.NormalId.Front
	t.Texture = uri
	t.StudsPerTileU = tile
	t.StudsPerTileV = tile
	t.Parent = part
	return t
end

function LooksView.new(): Brix.System
	local seen: { [Model]: string? } = {}
	local wipes: { [Model]: Wipe } = {}
	local watches: { [Model]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local stepping: RBXScriptConnection? = nil

	local function finish(unit: Model)
		local w = wipes[unit]
		if not w then
			return
		end
		wipes[unit] = nil
		local sound = w.sound
		local holder = if sound then sound.Parent else nil
		if sound and holder and sound.IsPlaying then
			holder.Parent = Workspace -- the roller eases off rather than stopping dead
			TweenService:Create(sound, TweenInfo.new(0.3), { Volume = 0 }):Play()
			task.delay(0.35, function()
				holder:Destroy()
			end)
		end
		w.folder:Destroy()
	end

	-- The set's colour map, as a Texture can show it (a script reads `ColorMapContent`, not
	-- `ColorMap`: STUDIO.md).
	local function mapOf(template: Model, set: string): (string?, SurfaceAppearance?)
		local swatch = template:FindFirstChild(Specs.Swatches[set] or "", true)
		local look = if swatch then swatch:FindFirstChildOfClass("SurfaceAppearance") else nil
		if not look then
			return nil, nil
		end
		-- any: ColorMapContent (a Content) isn't in every type definition yet
		local content = (look :: any).ColorMapContent
		local uri = if content then content.Uri else nil
		return if type(uri) == "string" and uri ~= "" then uri else nil, look
	end

	local function step()
		local now = Workspace:GetServerTimeNow()
		for unit, w in wipes do
			local t = now - w.since
			if t > Looks.Wipe + LATE then
				finish(unit)
				continue
			end
			local share = Looks.reach(t)
			local r = share * w.round / 2
			for _, wall in w.walls do
				local spans = Looks.covered(wall.mid - wall.half, wall.mid + wall.half, r, w.round)
				local span = spans[1]
				if span then
					local a, b = span[1], span[2]
					wall.sheet.Size = Vector3.new(b - a, w.height, SHEET)
					wall.sheet.CFrame = wall.cf
						* CFrame.new(
							wall.mid - (a + b) / 2,
							0,
							-(Looks.Proud / 2 + GAP + SHEET / 2)
						)
					wall.texture.OffsetStudsU = Looks.offset(SHIFT * a, Specs.Looks.PaperTile)
					wall.sheet.Transparency = 0
				end
			end
			local front = w.front
			if front then
				front.Transparency = 1 - math.clamp((r - w.frontFrom) / w.frontSpan, 0, 1)
			end
			local floor = w.floor
			if floor then
				local deep = math.max(share * w.floorDeep, 0.05)
				floor.Size = Vector3.new(floor.Size.X, deep, SHEET)
				floor.CFrame = w.floorCf
					* CFrame.new(0, w.floorTop, w.floorDeep / 2 - deep / 2)
					* CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.zAxis)
				floor.Transparency = 0
			end
		end
		if next(wipes) == nil and stepping then
			stepping:Disconnect()
			stepping = nil
		end
	end

	-- Starts the wipe that carries `unit` from `before` to `after`, begun at server time `since`.
	local function begin(unit: Model, before: Looks.Chosen, after: Looks.Chosen, since: number)
		finish(unit)
		local template = Home.template()
		local frame = unit:GetAttribute(Looks.FrameAttribute)
		if not (template and typeof(frame) == "CFrame") then
			return
		end
		local wallsOff, floorOff = Looks.changes(before, after)
		local back = template:FindFirstChild("PanelBack", true)
		local left = template:FindFirstChild("PanelLeft", true)
		local base = template:FindFirstChild("PanelFloor", true)
		if not (back and left and base and back:IsA("BasePart") and left:IsA("BasePart")) then
			return
		end
		if not base:IsA("BasePart") or not (wallsOff or floorOff) then
			return
		end
		local wide = back.Size.X
		local deep = left.Size.X + 2 * Looks.Proud
		local folder = Instance.new("Folder")
		folder.Name = "LookWipe"
		folder.Parent = Workspace
		local w: Wipe = {
			unit = unit,
			target = Looks.encode(after),
			since = since,
			round = 2 * (wide + deep),
			height = back.Size.Y,
			walls = {},
			front = nil,
			frontFrom = wide / 2 + deep,
			frontSpan = wide / 2,
			floor = nil,
			floorTexture = nil,
			floorCf = frame * CFrame.new(vec(Specs.Panels.Floor.At)),
			floorDeep = base.Size.Z,
			floorTop = base.Size.Y / 2 + GAP + SHEET / 2,
			folder = folder,
			sound = nil,
		}
		local wallWear, floorWear = Looks.wear(after)
		if wallsOff then
			local uri, look = mapOf(template, wallWear.set)
			local mids = {
				PanelBack = 0,
				PanelRight = wide / 2 + deep / 2,
				PanelLeft = -(wide / 2 + deep / 2),
			}
			for _, spec in Specs.Panels.Walls do
				local cf = frame
					* CFrame.new(vec(spec.At))
					* CFrame.Angles(0, math.rad(spec.Turn), 0)
				local mid = mids[spec.Part]
				local source = template:FindFirstChild(spec.Part, true)
				if mid and uri and source and source:IsA("BasePart") then
					local s = sheet(wallWear.colour, folder)
					local tx = texture(s, uri, Specs.Looks.PaperTile)
					tx.OffsetStudsV = Looks.offset(-SHIFT * w.height, Specs.Looks.PaperTile)
					table.insert(
						w.walls,
						{ cf = cf, mid = mid, half = source.Size.X / 2, sheet = s, texture = tx }
					)
				elseif spec.Part == "PanelFront" and look and source and source:IsA("MeshPart") then
					local copy = source:Clone()
					for _, d in copy:GetChildren() do
						d:Destroy()
					end
					look:Clone().Parent = copy
					copy.Anchored = true
					copy.CanCollide = false
					copy.CanTouch = false
					copy.CanQuery = false
					copy.CastShadow = false
					copy.Color = Color3.fromHex(wallWear.colour)
					copy.Transparency = 1
					copy.CFrame = cf * CFrame.new(0, 0, -(Looks.Proud + GAP))
					copy.Parent = folder
					w.front = copy
				end
			end
		end
		if floorOff then
			local uri = mapOf(template, floorWear.set)
			if uri then
				local s = sheet(floorWear.colour, folder)
				s.Size = Vector3.new(base.Size.X, 0.05, SHEET)
				local tx = texture(s, uri, Specs.Looks.FloorTile)
				tx.OffsetStudsU = Looks.offset(SHIFT * -base.Size.X / 2, Specs.Looks.FloorTile)
				w.floor = s
				w.floorTexture = tx
			end
		end
		local sound = Instance.new("Sound")
		sound.SoundId = ROLLER
		sound.Volume = ROLLER_VOLUME
		sound.PlaybackSpeed = if wallsOff then 1 else FLOOR_PITCH
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 10
		sound.RollOffMaxDistance = HEARD
		local at = Instance.new("Part")
		at.Anchored = true
		at.CanCollide = false
		at.CanTouch = false
		at.CanQuery = false
		at.Transparency = 1
		at.Size = Vector3.new(0.05, 0.05, 0.05)
		at.CFrame = w.floorCf * CFrame.new(0, w.height / 2, 0)
		at.Parent = folder
		sound.Parent = at
		sound:Play()
		w.sound = sound
		wipes[unit] = w
		if not stepping then
			stepping = RunService.Heartbeat:Connect(step)
		end
		step()
	end

	local function changed(unit: Model)
		local now = unit:GetAttribute(Looks.Attribute)
		local before = Looks.decode(seen[unit])
		local after = Looks.decode(now)
		seen[unit] = if type(now) == "string" then now else nil
		if not (before and after) or Looks.encode(before) == Looks.encode(after) then
			return
		end
		local since = unit:GetAttribute(Looks.SinceAttribute)
		if type(since) ~= "number" or Workspace:GetServerTimeNow() - since > Looks.Wipe then
			finish(unit) -- seen late: the panels wear it already, or will in a moment
			return
		end
		begin(unit, before, after, since)
	end

	local function worn(unit: Model)
		local w = wipes[unit]
		if w and unit:GetAttribute(Looks.WornAttribute) == w.target then
			-- a frame on, so the panels draw their new look before the sheets go
			task.delay(0.05, function()
				if wipes[unit] == w then
					finish(unit)
				end
			end)
		end
	end

	local function added(instance: Instance)
		if not instance:IsA("Model") or watches[instance] then
			return
		end
		local unit = instance
		local look = unit:GetAttribute(Looks.Attribute)
		seen[unit] = if type(look) == "string" then look else nil
		watches[unit] = unit.AttributeChanged:Connect(function(name: string)
			if name == Looks.Attribute then
				changed(unit)
			elseif name == Looks.WornAttribute then
				worn(unit)
			end
		end)
	end

	local function removed(instance: Instance)
		if not instance:IsA("Model") then
			return
		end
		local c = watches[instance]
		if c then
			c:Disconnect()
			watches[instance] = nil
		end
		seen[instance] = nil
		finish(instance)
	end

	return {
		name = "LooksView",
		start = function(_: any, _context: Brix.Context)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Looks.Tag):Connect(added)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Looks.Tag):Connect(removed)
			)
			for _, each in CollectionService:GetTagged(Looks.Tag) do
				added(each)
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for unit in watches do
				removed(unit)
			end
			if stepping then
				stepping:Disconnect()
				stepping = nil
			end
		end,
	}
end

return LooksView
