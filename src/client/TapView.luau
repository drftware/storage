--!strict
--[[
	Client system: the tap's bar on the puller's screen (S2-05a; ShutTap). A plain bar to test the
	rules with: S2-05b gives it its feel (where a thumb already is, the rise in, the latch and the
	bang).

	The server opens it ("Open" on Remotes.ShutTap: the unit, the pull's moment, the zone's left
	edge) as your door starts easing down over a sleeping monster. The marker runs on the server's
	clock (`ShutTap.marker`), so it's where the server judges it. One tap (a click, a touch, F as
	the pull was, or a gamepad's A or B) sends its moment and freezes the marker; the server's
	answer ("Done") lights the zone, pale green on a hit, red on a miss, and the bar goes. No words.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ShutTap = require(ReplicatedStorage.Shared.StorageUnit.ShutTap)

local BAR_WIDTH = 0.5 -- of the screen's width, held between the two below (px)
local BAR_MIN, BAR_MAX = 220, 380
local BAR_HEIGHT = 14 -- px
local BAR_Y = 0.72 -- of the screen's height: under the door, above the thumbs
local MARKER_WIDTH = 4 -- px
local SHOW_ANSWER = 0.35 -- s the lit zone stays before the bar goes
local GIVE_UP = 1.5 -- s past the window with no answer: the bar goes anyway

local BAR_COLOR = Color3.fromRGB(18, 18, 20)
local ZONE_COLOR = Color3.fromRGB(225, 220, 205)
local HIT_COLOR = Color3.fromRGB(150, 230, 160)
local MISS_COLOR = Color3.fromRGB(235, 70, 60)
local MARKER_COLOR = Color3.fromRGB(255, 255, 255)

local TAPS: { [Enum.KeyCode]: true } = {
	[Enum.KeyCode.F] = true,
	[Enum.KeyCode.ButtonA] = true,
	[Enum.KeyCode.ButtonB] = true,
}

export type TapView = Brix.System

local TapView = {}

function TapView.new(): TapView
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil
	local gui: ScreenGui? = nil
	local zoneFrame: Frame? = nil
	local marker: Frame? = nil
	-- the open window: its door, the pull's moment, and when (server's clock) you tapped, if you did
	local unit: Instance? = nil
	local start = 0
	local tapped: number? = nil
	local shown = 0 -- counts each bar shown, so a late hide can't take the next one down

	local function build(): (ScreenGui, Frame, Frame, Frame)
		local g = Instance.new("ScreenGui")
		g.Name = "ShutTap"
		g.IgnoreGuiInset = true
		g.ResetOnSpawn = false
		g.DisplayOrder = 5
		g.Enabled = false
		local b = Instance.new("Frame")
		b.Name = "Bar"
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(0.5, BAR_Y)
		b.Size = UDim2.new(BAR_WIDTH, 0, 0, BAR_HEIGHT)
		b.BackgroundColor3 = BAR_COLOR
		b.BackgroundTransparency = 0.25
		b.BorderSizePixel = 0
		local limit = Instance.new("UISizeConstraint")
		limit.MinSize = Vector2.new(BAR_MIN, BAR_HEIGHT)
		limit.MaxSize = Vector2.new(BAR_MAX, BAR_HEIGHT)
		limit.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.Color = ZONE_COLOR
		stroke.Transparency = 0.6
		stroke.Thickness = 1
		stroke.Parent = b
		local z = Instance.new("Frame")
		z.Name = "Zone"
		z.Size = UDim2.fromScale(ShutTap.ZoneWidth, 1)
		z.BackgroundColor3 = ZONE_COLOR
		z.BackgroundTransparency = 0.15
		z.BorderSizePixel = 0
		z.Parent = b
		local m = Instance.new("Frame")
		m.Name = "Marker"
		m.AnchorPoint = Vector2.new(0.5, 0.5)
		m.Size = UDim2.new(0, MARKER_WIDTH, 1.8, 0)
		m.BackgroundColor3 = MARKER_COLOR
		m.BorderSizePixel = 0
		m.ZIndex = 2
		m.Parent = b
		b.Parent = g
		g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		return g, b, z, m
	end

	local function hide()
		unit, tapped = nil, nil
		local g = gui
		if g then
			g.Enabled = false
		end
	end

	-- Hides the bar `after` seconds on, unless another has been shown since.
	local function hideAfter(after: number)
		local which = shown
		task.delay(after, function()
			if shown == which then
				hide()
			end
		end)
	end

	local function opened(u: Instance, at: number, zone: number)
		local g, z, m = gui, zoneFrame, marker
		if not (g and z and m) then
			return
		end
		shown += 1
		unit, start, tapped = u, at, nil
		z.Position = UDim2.fromScale(zone, 0)
		z.BackgroundColor3 = ZONE_COLOR
		m.Position = UDim2.fromScale(0, 0.5)
		g.Enabled = true
		hideAfter(ShutTap.Window + ShutTap.MaxLag + GIVE_UP)
	end

	local function answered(u: Instance, hit: boolean)
		local z = zoneFrame
		if u ~= unit or not z then
			return
		end
		z.BackgroundColor3 = if hit then HIT_COLOR else MISS_COLOR
		hideAfter(SHOW_ANSWER)
	end

	local function tap()
		local r, u = remote, unit
		if not (r and u) or tapped then
			return
		end
		local t = Workspace:GetServerTimeNow()
		tapped = t
		r:FireServer(u, t)
	end

	local system = { name = "TapView" }

	function system.start(_: any, _context: Brix.Context)
		local g, _, z, m = build()
		gui, zoneFrame, marker = g, z, m
		local folder = ReplicatedStorage:WaitForChild(ShutTap.RemoteFolder)
		local r = folder:WaitForChild(ShutTap.Remote) :: RemoteEvent
		remote = r
		table.insert(
			connections,
			-- unknown: whatever the server's message carries, checked before use
			r.OnClientEvent:Connect(function(what: unknown, u: unknown, a: unknown, b2: unknown)
				if typeof(u) ~= "Instance" then
					return
				end
				if what == "Open" and type(a) == "number" and type(b2) == "number" then
					opened(u, a, b2)
				elseif what == "Done" and type(a) == "boolean" then
					answered(u, a)
				elseif what == "Gone" and u == unit then
					hide()
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if not unit or processed then
					return
				end
				local t = input.UserInputType
				if
					t == Enum.UserInputType.MouseButton1
					or t == Enum.UserInputType.Touch
					or TAPS[input.KeyCode]
				then
					tap()
				end
			end)
		)
	end

	-- Only while the bar is up: the marker where the server's clock says, frozen once you tap.
	function system.step(_: any, _dt: number)
		local m = marker
		if not unit or not m then
			return
		end
		local at = tapped or Workspace:GetServerTimeNow()
		m.Position = UDim2.fromScale(ShutTap.marker(at - start), 0.5)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local g = gui
		if g then
			g:Destroy()
		end
		gui, zoneFrame, marker = nil, nil, nil
	end

	return system
end

return TapView
