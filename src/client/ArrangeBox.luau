--!strict
--[[
	ArrangeBox (S5-03j6a): the box that selects several things at once in Arrange, the room editor
	(D-436). The moment: you hold a finger on bare floor, the hold ripens, and as you drag a soft
	white box opens from that spot; each thing whose middle it reaches lights up with a faint glow
	and a tick that climbs a little higher with every one; let go and the box fades, the lit things
	stay lit. As The Sims 4's build-mode box and Bloxburg's multi-select.

	It owns only the box on screen and the glows; which things it takes is the pure `Selection`
	(names no find: what stands on what comes from the room's placements). ArrangeView makes one
	and hands it the build camera's held drags on the bare room (`ArrangeCamera`'s `box` option);
	a tap, or a drag on a thing, clears it there. Moving the group together is S5-03j6b.

	Nothing steps: the box changes only as its finger moves, and the glows are tweens.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ArrangeHand = require(script.Parent.ArrangeHand)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Selection = require(ReplicatedStorage.Shared.Home.Selection)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)

local WASH = Color3.fromRGB(255, 244, 222) -- a warm white: picked, not judged (green and red are)
local FADE = TweenInfo.new(Selection.Fade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GLOW = TweenInfo.new(Selection.GlowIn, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type Options = {
	-- Arrange's gui, where the box is drawn.
	gui: () -> ScreenGui?,
	-- The room's judge (what stands on what).
	room: () -> Arrange.Room?,
	-- The folder your finds are drawn in.
	placed: () -> Instance?,
	-- Where the box's ticks play.
	sounds: () -> Instance,
	-- A phone tap (nothing off a phone).
	tap: (tap: Feedback.Tap) -> (),
	-- Whether the hand holds something now: then a held drag on the room slides the camera, as it
	-- always did, instead of starting a box.
	busy: () -> boolean,
}

export type ArrangeBox = {
	-- A held drag on the bare room (gui points): "dragBegan" answers whether the box takes it;
	-- its moves and end follow.
	intent: (i: Brix.GestureIntent<Model>) -> boolean,
	-- The things taken, as roots (what rides on one moves with it), in the room's order: a new
	-- list. Empty when nothing is selected.
	ids: () -> { string },
	-- Lets go of the selection: the glows fade.
	clear: () -> (),
	-- The glows hidden (`on`) while the group's ghosts stand in for the lit things as they move
	-- (ArrangeGroup), and back after.
	dim: (on: boolean) -> (),
}

local ArrangeBox = {}

function ArrangeBox.new(options: Options): ArrangeBox
	local me = Players.LocalPlayer
	local frame: Frame? = nil
	local startX, startY = 0, 0
	local drawn = false -- past the slop: the box shows
	local box = Selection.box(0, 0, 0, 0)
	local points: { Selection.Point } = {}
	local pointsFor: CFrame? = nil -- the camera the points were found from
	local inside: { string } = {}
	local roots: { string } = {}
	local lit: { string } = {}
	local glows: { [string]: Highlight } = {}
	local pitch = 1

	-- Every find of yours drawn in the room, its middle on the screen from the camera now.
	local function findPoints()
		local camera = Workspace.CurrentCamera
		local folder = options.placed()
		if not (camera and folder) or pointsFor == camera.CFrame then
			return
		end
		pointsFor = camera.CFrame
		table.clear(points)
		for _, m in folder:GetChildren() do
			local id = m:GetAttribute(Spots.IdAttribute)
			if
				m:IsA("Model")
				and type(id) == "string"
				and m:GetAttribute(Spots.OwnerAttribute) == me.UserId
			then
				local at = camera:WorldToScreenPoint(m:GetBoundingBox().Position)
				table.insert(points, { id = id, x = at.X, y = at.Y, ahead = at.Z > 0 })
			end
		end
	end

	-- The drawn find `id`, if it's drawn.
	local function model(id: string): Model?
		local folder = options.placed()
		local m = if folder then folder:FindFirstChild(id) else nil
		return if m and m:IsA("Model") then m else nil
	end

	-- What `id` stands on, when that's another thing (nil for the floor or a wall).
	local function baseOf(id: string): string?
		local r = options.room()
		local pose = if r then r.placements:poseOf(id) else nil
		if r and pose and r.placements:poseOf(pose.on) then
			return pose.on
		end
		return nil
	end

	local function standingOn(id: string): { string }
		local r = options.room()
		return if r then r.placements:standingOn(id) else {}
	end

	-- Glows on exactly the things in `lit` (up to `Selection.Most`); the rest fade off.
	local function light()
		local want: { [string]: boolean } = {}
		for n, id in lit do
			if n > Selection.Most then
				break
			end
			want[id] = true
			local m = model(id)
			if m and not glows[id] then
				local h = Instance.new("Highlight")
				h.Name = "ArrangeSelected"
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.FillColor = WASH
				h.OutlineColor = WASH
				h.FillTransparency = 1
				h.OutlineTransparency = 1
				h.Adornee = m
				h.Parent = Workspace.CurrentCamera
				TweenService
					:Create(h, GLOW, { FillTransparency = Selection.Glow, OutlineTransparency = 0 })
					:Play()
				glows[id] = h
			end
		end
		for id, h in glows do
			if not want[id] then
				glows[id] = nil
				local t =
					TweenService:Create(h, FADE, { FillTransparency = 1, OutlineTransparency = 1 })
				t.Completed:Once(function()
					h:Destroy()
				end)
				t:Play()
			end
		end
	end

	local function makeFrame(g: ScreenGui): Frame
		local f = Instance.new("Frame")
		f.Name = "SelectBox"
		f.BackgroundColor3 = WASH
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.ZIndex = 0 -- under the ring, the tray and every button
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = f
		local edge = Instance.new("UIStroke")
		edge.Color = WASH
		edge.Thickness = 1.5
		edge.Transparency = 1
		edge.Parent = f
		f.Parent = g
		return f
	end

	-- The box to the finger at gui point `x`, `y`: drawn once past the slop, and what it takes
	-- now lit, with a rising tick for each that joins.
	local function stretch(x: number, y: number)
		Selection.box(startX, startY, x, y, box)
		local f = frame
		if not f then
			return
		end
		f.Position = UDim2.fromOffset(box.left, box.top)
		f.Size = UDim2.fromOffset(box.right - box.left, box.bottom - box.top)
		if not drawn and Selection.big(box) then
			drawn = true
			TweenService:Create(f, FADE, { BackgroundTransparency = Selection.Fill }):Play()
			local edge = f:FindFirstChildOfClass("UIStroke")
			if edge then
				TweenService:Create(edge, FADE, { Transparency = Selection.Edge }):Play()
			end
		end
		findPoints()
		Selection.inside(box, points, inside)
		local nowRoots = Selection.roots(inside, baseOf)
		if Selection.same(nowRoots, roots) then
			return
		end
		local joined = Selection.joined(roots, nowRoots)
		roots = nowRoots
		lit = Selection.lit(roots, standingOn)
		light()
		if joined > 0 then
			pitch = math.min(pitch + Selection.Rise * joined, Selection.TopPitch)
			local tick: Arrange.Sound = table.clone(Arrange.Tick)
			tick.pitch = (Arrange.Tick.pitch or 1) * pitch
			ArrangeHand.play(tick, options.sounds())
			options.tap(Feedback.Taps.Light)
		end
	end

	-- The finger lifts: the box fades; what it took stays lit (nothing, if it was `cancelled`).
	local function finish(cancelled: boolean)
		local f = frame
		frame, drawn = nil, false
		if f then
			local t = TweenService:Create(f, FADE, { BackgroundTransparency = 1 })
			local edge = f:FindFirstChildOfClass("UIStroke")
			if edge then
				TweenService:Create(edge, FADE, { Transparency = 1 }):Play()
			end
			t.Completed:Once(function()
				f:Destroy()
			end)
			t:Play()
		end
		if cancelled then
			table.clear(roots)
			table.clear(lit)
			light()
		end
	end

	local function clear()
		if frame then
			finish(true)
		else
			table.clear(roots)
			table.clear(lit)
			light()
		end
	end

	local function intent(i: Brix.GestureIntent<Model>): boolean
		if i.kind == "dragBegan" then
			local g = options.gui()
			if not g or options.busy() or not options.room() then
				return false
			end
			if frame then
				finish(true)
			end
			table.clear(roots)
			table.clear(lit)
			light()
			startX, startY, pitch, pointsFor = i.x, i.y, 1, nil
			frame = makeFrame(g)
			stretch(i.x, i.y)
			return true
		elseif i.kind == "dragMoved" then
			stretch(i.x, i.y)
		elseif i.kind == "dragEnded" then
			if not i.cancelled then
				stretch(i.x, i.y)
			end
			finish(i.cancelled)
		end
		return true
	end

	return {
		intent = intent,
		ids = function(): { string }
			return table.clone(roots)
		end,
		clear = clear,
		dim = function(on: boolean)
			for _, h in glows do
				h.Enabled = not on
			end
		end,
	}
end

return ArrangeBox
