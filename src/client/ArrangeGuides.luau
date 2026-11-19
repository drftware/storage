--!strict
--[[
	ArrangeGuides (S5-03j3b, D-457): the faint lines in Arrange, the room editor (D-436), where a
	dragged thing's edge or middle lines up with a neighbour's, as The Sims 4 draws its guides. A
	crate slid beside another shows a thin warm line where their edges meet, so you see the snap
	that just pulled it straight.

	It draws whatever Brix's line-up answers (`Brix.PlacementAlignment`, filled by the hand's
	`settle`): it knows nothing of what is dragged or what it lines up with, so any area (a floor,
	a top, a wall) and any thing get lines the same way. Six lines at most (the contract's cap):
	six thin parts made once and kept, laid only when the hand's pose changes, never per frame.
	ArrangeHand owns one.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)

local Feel = Arrange.Feel

local MOST = 6 -- the contract's most lines in one answer
local WARM = Color3.fromRGB(255, 244, 222) -- a warm white, the room's light, not a tool's blue

export type Guides = {
	-- Lays the first `lines.count` of `lines.guides` on the area whose world frame is `frame`
	-- (x along its X, y along its -Z, up its Y); parks the rest.
	show: (self: Guides, frame: CFrame, lines: Brix.PlacementAlignment) -> (),
	-- Parks every line.
	hide: (self: Guides) -> (),
	destroy: (self: Guides) -> (),
}

type Self = Guides & { parts: { Part }, shown: number }

local Methods = {}
Methods.__index = Methods

local function part(): Part
	local p = Instance.new("Part")
	p.Name = "ArrangeGuide"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = WARM
	p.Transparency = Feel.GuideFaint
	p.Size = Vector3.new(Feel.GuideWidth, Feel.GuideWidth * 0.5, 1)
	return p
end

function Methods.show(self: Self, frame: CFrame, lines: Brix.PlacementAlignment)
	local count = math.min(lines.count, MOST)
	for i = 1, count do
		local g = lines.guides[i]
		local p = self.parts[i]
		local from, to =
			math.min(g.from, g.to) - Feel.GuideReach, math.max(g.from, g.to) + Feel.GuideReach
		local mid, length = (from + to) / 2, to - from
		-- a line on "x" stands at x = at and runs along the depth (the frame's Z); one on "y"
		-- stands at y = at (the frame's -Z) and runs along the width (its X)
		local x, y = if g.axis == "x" then g.at else mid, if g.axis == "x" then mid else g.at
		p.Size = if g.axis == "x"
			then Vector3.new(Feel.GuideWidth, Feel.GuideWidth * 0.5, length)
			else Vector3.new(length, Feel.GuideWidth * 0.5, Feel.GuideWidth)
		p.CFrame = frame * CFrame.new(x, Feel.GuideLift, -y)
		p.Parent = Workspace.CurrentCamera
	end
	for i = count + 1, self.shown do
		self.parts[i].Parent = nil
	end
	self.shown = count
end

function Methods.hide(self: Self)
	for i = 1, self.shown do
		self.parts[i].Parent = nil
	end
	self.shown = 0
end

function Methods.destroy(self: Self)
	for _, p in self.parts do
		p:Destroy()
	end
	table.clear(self.parts)
	self.shown = 0
end

local ArrangeGuides = {}

-- A pool of six lines, drawn under the camera so only this player sees them.
function ArrangeGuides.new(): Guides
	local parts = table.create(MOST)
	for i = 1, MOST do
		parts[i] = part()
	end
	local self = setmetatable({ parts = parts, shown = 0 }, Methods)
	return (self :: any) :: Guides -- any: the metatable's methods make the typed interface
end

return ArrangeGuides
