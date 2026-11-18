--!strict
--[[
	HomeGlows: the light the lit pieces set out in homes throw on this player's screen (S5-03g4d,
	D-339). The moment: home after a climb, the string lights over your camp bed and the neon moon
	on the wall glow warm as you walk in, and with your lamp switched off the room is theirs.
	Precedents: Bloxburg's and Adopt Me's string lights and neon signs, Animal Crossing's lit
	furniture.

	The server draws each piece with its bulbs and tube Neon (Home.paint), so every one glows on
	every screen without a light. On top of that only the few nearest a point just ahead of the
	camera (Home.LitPiece.Near, within Reach: D-271's budget) throw a real light here, made as you
	come, warmed up and faded out over Fade and then destroyed, as the neon cards' washes are
	(HomeCards). Each light hangs where its piece's row in Specs.Glows says, in the piece's frame,
	on one of its parts, so it goes where the piece goes.

	Only the pick steps, a few times a second, and only while any lit piece is drawn.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local UnitLight = require(ReplicatedStorage.Shared.UnitLight)

local LIT = Home.LitPiece
local WARM = TweenInfo.new(LIT.Fade, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local NAME = "PieceGlow" -- the attachment holding a piece's light

-- A lit piece drawn here: its light exists only while it's one of the nearest.
type Lit = {
	model: Model,
	glow: HomeSpecs.Glow,
	near: boolean,
	distance: number, -- from the camera's lead point, at the last pick
	light: PointLight?,
	tween: Tween?,
}

local function byNearness(a: Lit, b: Lit): boolean
	return a.distance < b.distance
end

-- Where `lit`'s light hangs in the world now.
local function lightAt(lit: Lit): Vector3
	local v = lit.glow.Light
	return lit.model:GetPivot() * Vector3.new(v[1], v[2], v[3])
end

export type HomeGlows = Brix.System

local HomeGlows = {}

function HomeGlows.new(): HomeGlows
	local top: { RBXScriptConnection } = {}
	local lits: { [Model]: Lit } = {}
	local ranked: { Lit } = {} -- reused at each pick
	local untilPick = 0

	-- Warms `lit`'s light up as it becomes one of the nearest, or fades it and lets it go.
	local function shine(lit: Lit, on: boolean)
		local tween = lit.tween
		if tween then
			tween:Cancel()
		end
		local light = lit.light
		if on and not light then
			local part = lit.model.PrimaryPart or lit.model:FindFirstChildWhichIsA("BasePart", true)
			if not part then
				return
			end
			local a = Instance.new("Attachment")
			a.Name = NAME
			a.Position = part.CFrame:PointToObjectSpace(lightAt(lit))
			local l = Instance.new("PointLight")
			l.Color = Color3.fromHex(lit.glow.Colour)
			l.Range = lit.glow.Range
			l.Brightness = 0
			l.Shadows = false
			l.Parent = a
			a.Parent = part
			lit.light = l
			light = l
		end
		if not light then
			return
		end
		local made: PointLight = light
		local t =
			TweenService:Create(made, WARM, { Brightness = if on then lit.glow.Brightness else 0 })
		lit.tween = t
		if not on then
			t.Completed:Once(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and lit.light == made then
					lit.light = nil
					local a = made.Parent
					if a then
						a:Destroy()
					end
				end
			end)
		end
		t:Play()
	end

	-- The lit pieces nearest a point just ahead of the camera throw their light: one already
	-- lit keeps it until another is clearly nearer (UnitLight.NearMargin).
	local function pick()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.CFrame
		local look = view.LookVector * Vector3.new(1, 0, 1)
		local from = view.Position
			+ (if look.Magnitude > 1e-3 then look.Unit * UnitLight.NearLead else Vector3.zero)
		table.clear(ranked)
		for _, lit in lits do
			lit.distance = (lightAt(lit) - from).Magnitude
				- (if lit.near then UnitLight.NearMargin else 0)
			if lit.distance <= LIT.Reach then
				table.insert(ranked, lit)
			end
		end
		table.sort(ranked, byNearness)
		for _, lit in lits do
			local place = table.find(ranked, lit)
			local near = place ~= nil and place <= LIT.Near
			if near ~= lit.near then
				lit.near = near
				shine(lit, near)
			end
		end
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or lits[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local id = inst:GetAttribute(Spots.IdAttribute)
		local name = if type(id) == "string" then Spots.name(id) else nil
		local glow = if name then Spots.glow(name) else nil
		if not glow then
			return -- a find, or a piece that doesn't light up
		end
		lits[inst] = { model = inst, glow = glow, near = false, distance = math.huge }
		untilPick = 0 -- picked on the next frame, so a piece just set out warms up at once
	end

	local function remove(inst: Instance)
		local lit = if inst:IsA("Model") then lits[inst] else nil
		if not lit then
			return
		end
		lits[inst :: Model] = nil
		local tween = lit.tween
		if tween then
			tween:Cancel()
		end
		local light = lit.light
		if light and light.Parent then
			(light.Parent :: Instance):Destroy()
		end
		lit.light = nil
	end

	return {
		name = "HomeGlows",
		start = function(_: any)
			table.insert(top, CollectionService:GetInstanceAddedSignal(Spots.Tag):Connect(add))
			table.insert(top, CollectionService:GetInstanceRemovedSignal(Spots.Tag):Connect(remove))
			for _, inst in CollectionService:GetTagged(Spots.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			if next(lits) == nil then
				return
			end
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = UnitLight.NearSeconds
				pick()
			end
		end,
		stop = function(_: any)
			for _, c in top do
				c:Disconnect()
			end
			table.clear(top)
			for model in lits do
				remove(model)
			end
		end,
	}
end

return HomeGlows
