--!strict
--[[
	ArrangeGrid (S5-03j7b, taken out of ArrangeView): the faint grid that fades in on your floor as
	Arrange opens, a line each `Feel.Grid` studs from the floor's edges, so a thing ticking from
	square to square under your thumb has squares to tick along (Bloxburg's and The Sims' build
	grid). ArrangeView makes one from the room it judges as Arrange opens and removes it on Done.
	It's drawn under the camera, so only you see it.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)

local Feel = Arrange.Feel
local RISE = TweenInfo.new(Feel.Rise, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local ArrangeGrid = {}

-- The grid over room `r`'s floor, its lines fading in as the camera rises; nil for a room with
-- no floor.
function ArrangeGrid.make(r: Arrange.Room): Part?
	local f = r.frames.Floor
	local area = r.placements:areaOf("Floor")
	if not (f and area) then
		return nil
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(area.width, 0.05, area.depth)
	p.CFrame = f * CFrame.new(0, Feel.GridLift, 0)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 24
	sg.LightInfluence = 0
	sg.Adornee = p
	sg.Parent = p
	local function line(alongX: boolean, at: number)
		local l = Instance.new("Frame")
		l.BorderSizePixel = 0
		l.BackgroundColor3 = Color3.new(1, 1, 1)
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Size = if alongX
			then UDim2.new(0, Feel.GridLine, 1, 0)
			else UDim2.new(1, 0, 0, Feel.GridLine)
		l.Position = if alongX then UDim2.fromScale(at, 0.5) else UDim2.fromScale(0.5, at)
		l.Parent = sg
		TweenService:Create(l, RISE, { BackgroundTransparency = Feel.GridFade }):Play()
	end
	for i = 1, math.floor(area.width / Feel.Grid - 1e-6) do
		line(true, i * Feel.Grid / area.width)
	end
	for i = 1, math.floor(area.depth / Feel.Grid - 1e-6) do
		line(false, i * Feel.Grid / area.depth)
	end
	p.Parent = Workspace.CurrentCamera
	return p
end

return ArrangeGrid
