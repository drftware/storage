--!strict
--[[
	BangMarks: a kept friend banging on their door, on everyone else's screen (L-07c). Dead by
	Daylight shows every survivor where a friend hangs on a hook; here a friend shut in a unit
	hammers on its door and, wherever you are on the floor, a blue mark (the corner map's friend
	blue) with their name stands over that door, seen through the walls. Each bang sends a ring
	out from it, so you can tell they're still at it; it holds while they keep banging and fades
	out `Kept.BangMark` seconds after the last one, or at once when they're let out.

	The server puts each floor's latest bangs on its model (`Kept.BangsAttribute`, from
	KeptPlayers) with where the door is, so the mark shows even when the unit hasn't streamed to
	this screen. Never your own (you're the one inside), and none while you're kept yourself:
	your screen is the dark inside your own unit. The door's thud is DoorSounds', heard near it.

	It steps only while a mark is up.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Minimap = require(ReplicatedStorage.Shared.Minimap)

local FRIEND = Color3.fromRGB(110, 186, 255) -- the corner map's friend blue
local INK = Color3.fromRGB(240, 246, 255)
local DOT = 26 -- points across the dot: a thumb's target's size, read at a glance on a phone
local DOT_SEE = 0.08 -- its transparency, fully up
local RIPPLE = 3 -- a bang's ring grows to this many dots across
local RIPPLE_TIME = 0.75 -- seconds a ring takes to grow and fade
local THUMP = 0.35 -- the dot swells this much more at each bang, settling as its ring goes
local UP = 5.5 -- studs over the door's foot: about its middle, at your eye
local NAME_SIZE = 17
local LEAVE = 0.3 -- seconds a mark takes to go when its friend is let out

type Mark = {
	user: number,
	at: number, -- the latest bang (the server's clock)
	rang: number, -- os.clock of its latest ring, or -1
	leaving: number, -- os.clock its friend was let out, or -1
	attach: Attachment,
	gui: BillboardGui,
	dot: Frame,
	thump: UIScale,
	ripple: Frame,
	rippleRing: UIStroke,
	name: TextLabel,
	nameStroke: UIStroke,
}

local function makeMark(): Mark
	local attach = Instance.new("Attachment")
	attach.Name = "BangMark"
	attach.Parent = Workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.Name = "BangMark"
	gui.Adornee = attach
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = math.huge
	gui.ResetOnSpawn = false
	gui.Size = UDim2.fromOffset(DOT * RIPPLE + 8, DOT * RIPPLE + NAME_SIZE * 2)
	local function circle(name: string, size: number): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(0.5, 0, 0, DOT * RIPPLE / 2)
		f.Size = UDim2.fromOffset(size, size)
		f.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		f.Parent = gui
		return f
	end
	local ripple = circle("Ring", DOT)
	ripple.BackgroundTransparency = 1
	local rippleRing = Instance.new("UIStroke")
	rippleRing.Color = FRIEND
	rippleRing.Thickness = 3
	rippleRing.Transparency = 1
	rippleRing.Parent = ripple
	local dot = circle("Dot", DOT)
	dot.BackgroundColor3 = FRIEND
	local rim = Instance.new("UIStroke")
	rim.Color = INK
	rim.Thickness = 2
	rim.Parent = dot
	local thump = Instance.new("UIScale")
	thump.Parent = dot
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, DOT * RIPPLE / 2 + DOT / 2 + 4)
	name.Size = UDim2.new(1, 0, 0, NAME_SIZE + 4)
	name.BackgroundTransparency = 1
	name.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	name.TextSize = NAME_SIZE
	name.TextColor3 = INK
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = gui
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.new(0, 0, 0)
	nameStroke.Thickness = 1.5
	nameStroke.Parent = name
	return {
		user = 0,
		at = -math.huge,
		rang = -1,
		leaving = -1,
		attach = attach,
		gui = gui,
		dot = dot,
		thump = thump,
		ripple = ripple,
		rippleRing = rippleRing,
		name = name,
		nameStroke = nameStroke,
	}
end

local BangMarks = {}

function BangMarks.new(): Brix.System
	local me = Players.LocalPlayer
	local floors: { [Instance]: RBXScriptConnection } = {}
	local marks: { [Instance]: { [number]: Mark } } = {} -- each floor's, by slot
	local connections: { RBXScriptConnection } = {}
	local parent: Instance? = nil

	local function drop(mark: Mark)
		mark.gui:Destroy()
		mark.attach:Destroy()
	end

	-- Reads `model`'s bangs: a new one rings its mark (making it if it's the first), and a friend
	-- no longer listed has been let out, so theirs goes.
	local function read(model: Instance)
		local text = model:GetAttribute(Kept.BangsAttribute)
		local list: { Kept.Bang } = if type(text) == "string" then Kept.decodeBangs(text) else {}
		local on = marks[model]
		if not on then
			on = {}
			marks[model] = on
		end
		local listed: { [number]: boolean } = {}
		for _, b in list do
			if b.user == me.UserId then
				continue
			end
			listed[b.slot] = true
			local mark: Mark
			local had = on[b.slot]
			if had then
				mark = had
			else
				mark = makeMark()
				mark.gui.Parent = parent
				on[b.slot] = mark
			end
			if b.user ~= mark.user then
				mark.user = b.user
				local friend = Players:GetPlayerByUserId(b.user)
				mark.name.Text = if friend then friend.DisplayName else ""
			end
			mark.attach.WorldPosition = Vector3.new(b.x, b.y + UP, b.z)
			mark.leaving = -1
			if b.at > mark.at then
				mark.at = b.at
				mark.rang = os.clock()
			end
		end
		for slot, mark in on do
			if not listed[slot] and mark.leaving < 0 then
				mark.leaving = os.clock()
			end
		end
	end

	local function added(model: Instance)
		if floors[model] then
			return
		end
		floors[model] = model:GetAttributeChangedSignal(Kept.BangsAttribute):Connect(function()
			read(model)
		end)
		read(model)
	end

	local function removed(model: Instance)
		local c = floors[model]
		if c then
			c:Disconnect()
			floors[model] = nil
		end
		local on = marks[model]
		if on then
			for _, mark in on do
				drop(mark)
			end
			marks[model] = nil
		end
	end

	local system = { name = "BangMarks" }

	function system.start(_: any, _context: Brix.Context)
		parent = me:WaitForChild("PlayerGui")
		for _, model in CollectionService:GetTagged(Minimap.Tag) do
			added(model)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Minimap.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Minimap.Tag):Connect(removed)
		)
	end

	function system.step(_: any, _dt: number)
		if next(marks) == nil then
			return
		end
		local now = Workspace:GetServerTimeNow()
		local clock = os.clock()
		local hidden = me:GetAttribute(Kept.Attribute) == true
		for model, on in marks do
			for slot, mark in on do
				local level = Kept.mark(now - mark.at)
				if mark.leaving >= 0 then
					level *= math.max(0, 1 - (clock - mark.leaving) / LEAVE)
				end
				if level <= 0 then
					drop(mark)
					on[slot] = nil
					continue
				end
				mark.gui.Enabled = not hidden
				if hidden then
					continue
				end
				mark.dot.BackgroundTransparency = 1 - (1 - DOT_SEE) * level
				mark.name.TextTransparency = 1 - level
				mark.nameStroke.Transparency = 1 - level * 0.6
				local p = if mark.rang >= 0 then (clock - mark.rang) / RIPPLE_TIME else 1
				if p < 1 then
					local out = 1 - (1 - p) * (1 - p) -- fast, then slowing
					local side = DOT * (1 + (RIPPLE - 1) * out)
					mark.ripple.Size = UDim2.fromOffset(side, side)
					mark.rippleRing.Transparency = 1 - (1 - p) * level
					mark.thump.Scale = 1 + THUMP * (1 - p) * (1 - p)
				elseif mark.rang >= 0 then
					mark.rang = -1
					mark.rippleRing.Transparency = 1
					mark.thump.Scale = 1
				end
			end
			if next(on) == nil then
				marks[model] = nil
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in floors do
			removed(model)
		end
		for model in marks do
			removed(model)
		end
	end

	return system :: any -- any: a plain Brix system built field by field
end

return BangMarks
