--!strict
--[[
	ArrangeBlockers (S5-03j4b2, D-462): what's in the way, lit up, in Arrange, the room editor
	(D-436). Drag the bed against the shelf and the bed goes red, and the shelf itself flares soft
	red and stays faintly lit while you're pressing into it, so you see what's blocking you without
	a word, as The Sims 4 lights the object in the way.

	It lights whatever ids it's given (Brix's `Placements.blocking`, asked by the hand as the ghost
	moves) by finding each one's drawn model in your placed folder, where every thing set out is a
	model named by its id. It knows nothing of what any thing is, so a find, a piece of furniture
	and the home's own pieces glow the same way. A few Highlights are made once and kept; they move
	between things only when the set in the way changes, never per frame. ArrangeHand owns one.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)

local Feel = Arrange.Feel

local FLASH = TweenInfo.new(Feel.BlockerFade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SETTLE = TweenInfo.new(Feel.BlockerSettle, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(Feel.BlockerFade, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type Blockers = {
	-- Lights the things named in `ids` (drawn in `folder`, by name), at most `Feel.BlockerMost`,
	-- fading out any lit before that aren't among them. True when nothing was lit before and
	-- something is now: the moment a drag first presses into something.
	show: (self: Blockers, ids: { string }, folder: Instance?) -> boolean,
	-- Fades every glow out.
	clear: (self: Blockers) -> (),
	destroy: (self: Blockers) -> (),
}

-- One glow: its Highlight, the id it's on (nil: free), and a count that a fade's end checks, so
-- an older fade finishing never undoes a newer one.
type Glow = { highlight: Highlight, id: string?, turn: number }
type Self = Blockers & { glows: { Glow }, lit: number }

local Methods = {}
Methods.__index = Methods

local function highlight(): Highlight
	local h = Instance.new("Highlight")
	h.Name = "ArrangeBlocker"
	-- seen through the ghost hanging over it, the way the ghost's own glow is
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillColor = Feel.BlockerColour
	h.OutlineColor = Feel.BlockerColour
	h.FillTransparency = 1
	h.OutlineTransparency = 1
	h.Enabled = false
	return h
end

local function fadeIn(glow: Glow, model: Model)
	glow.turn += 1
	local turn = glow.turn
	local h = glow.highlight
	h.Adornee = model
	h.FillTransparency = 1
	h.OutlineTransparency = 1
	h.Enabled = true
	h.Parent = Workspace.CurrentCamera
	local flash = TweenService:Create(
		h,
		FLASH,
		{ FillTransparency = Feel.BlockerFlash, OutlineTransparency = Feel.BlockerOutline }
	)
	flash.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed and glow.turn == turn then
			TweenService:Create(h, SETTLE, { FillTransparency = Feel.BlockerHold }):Play()
		end
	end)
	flash:Play()
end

local function fadeOut(glow: Glow)
	glow.id = nil
	glow.turn += 1
	local turn = glow.turn
	local h = glow.highlight
	local fade = TweenService:Create(h, FADE, { FillTransparency = 1, OutlineTransparency = 1 })
	fade.Completed:Once(function(state: Enum.PlaybackState)
		if state == Enum.PlaybackState.Completed and glow.turn == turn then
			h.Enabled = false
			h.Adornee = nil
		end
	end)
	fade:Play()
end

function Methods.show(self: Self, ids: { string }, folder: Instance?): boolean
	local before = self.lit
	-- out with the glows on things no longer in the way
	for _, glow in self.glows do
		local id = glow.id
		if id and table.find(ids, id) == nil then
			fadeOut(glow)
			self.lit -= 1
		end
	end
	-- in with the things newly in the way, each on a free glow
	for i, id in ids do
		if i > #self.glows then
			break
		end
		local on = false
		for _, glow in self.glows do
			if glow.id == id then
				on = true
				break
			end
		end
		local model = if on or not folder then nil else folder:FindFirstChild(id)
		if model and model:IsA("Model") then
			for _, glow in self.glows do
				if glow.id == nil then
					glow.id = id
					fadeIn(glow, model)
					self.lit += 1
					break
				end
			end
		end
	end
	return before == 0 and self.lit > 0
end

function Methods.clear(self: Self)
	for _, glow in self.glows do
		if glow.id then
			fadeOut(glow)
		end
	end
	self.lit = 0
end

function Methods.destroy(self: Self)
	for _, glow in self.glows do
		glow.turn += 1
		glow.highlight:Destroy()
	end
	table.clear(self.glows)
	self.lit = 0
end

local ArrangeBlockers = {}

-- A few glows, drawn under the camera so only this player sees them.
function ArrangeBlockers.new(): Blockers
	local glows: { Glow } = table.create(Feel.BlockerMost)
	for i = 1, Feel.BlockerMost do
		glows[i] = { highlight = highlight(), id = nil, turn = 0 }
	end
	local self = setmetatable({ glows = glows, lit = 0 }, Methods)
	return (self :: any) :: Blockers -- any: the metatable's methods make the typed interface
end

return ArrangeBlockers
