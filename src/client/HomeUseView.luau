--!strict
--[[
	HomeUseView: each find set out in a home shows its own button on this screen (S5-03i3, D-351).
	The moment: you walk into your home, up to the lamp you stood on the end table, and its Switch
	is there; press it and the corner glows (FindUseView plays the server's stamp, its real light
	under the screen's cap). A friend over at yours gets the same buttons and can squeeze your duck.

	The server's button (HomeUses) shows here only while this screen's player stands in that home
	(its folder's room, `Press.inside`), Arrange isn't open (your tools are stowed then), the find
	isn't being taken, and a press would take (`Use.press`: a lit tea light or a jack mid-tune takes
	none, so its button is gone until it would). On its holder's screen it sits beside the find's
	Take, the two a button's width apart (`Press.Side`); alone, it sits on the find.

	Checked a few times a second, and only the finds of the home you stand in are weighed.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Press = require(ReplicatedStorage.Shared.Home.Press)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Take = require(ReplicatedStorage.Shared.Home.Take)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

-- Seconds between looks at who's in which home and which presses would take: quick enough that a
-- button is there as you step in, or back as a jack's tune ends.
local LOOK = 0.2

-- A find set out on this screen with its own button.
type Standing = {
	model: Model,
	prompt: ProximityPrompt,
	take: ProximityPrompt?,
	row: Use.Row,
	durations: { [string]: number },
}

local function promptNamed(model: Model, name: string): ProximityPrompt?
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == name then
			return d
		end
	end
	return nil
end

local function takeOf(model: Model): ProximityPrompt?
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name == "Take" then
			return d
		end
	end
	return nil
end

local HomeUseView = {}

function HomeUseView.new(): Brix.System
	local me = Players.LocalPlayer
	local standing: { [Model]: Standing } = {}
	local inHome: { [Instance]: boolean } = {} -- per home folder, this look: am I in it
	local connections: { RBXScriptConnection } = {}
	local since = 0

	-- Whether a press of `s` would take now (its stamp's state and how far it has played).
	local function would(s: Standing): boolean
		local m = s.model
		local stamp = Use.read(
			m:GetAttribute(Use.StateAttribute),
			m:GetAttribute(Use.AtAttribute),
			m:GetAttribute(Use.LeftAttribute),
			m:GetAttribute(Use.CountAttribute)
		)
		local elapsed = if stamp then Workspace:GetServerTimeNow() - stamp.at else 0
		return (Use.press(s.row, stamp, elapsed, s.durations)) ~= nil
	end

	local function place(s: Standing, shown: boolean)
		local take = s.take
		local both = shown and take ~= nil and take.Enabled
		local half = Press.Side / 2
		local want = if both then Vector2.new(-half, 0) else Vector2.zero
		if s.prompt.UIOffset ~= want then
			s.prompt.UIOffset = want
		end
		if take then
			local theirs = if both then Vector2.new(half, 0) else Vector2.zero
			if take.UIOffset ~= theirs then
				take.UIOffset = theirs
			end
		end
	end

	local function look()
		local character = me.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local at = if root and root:IsA("BasePart") then root.Position else nil
		local stowed = me:GetAttribute(Tools.StowAttribute) == true
		table.clear(inHome)
		for model, s in standing do
			local folder = model.Parent
			local here = false
			if folder and at and not stowed then
				local known = inHome[folder]
				if known == nil then
					local middle = folder:GetAttribute(Press.RoomAttribute)
					local half = folder:GetAttribute(Press.HalfAttribute)
					known = false
					if typeof(middle) == "CFrame" and typeof(half) == "Vector3" then
						local p = middle:PointToObjectSpace(at)
						known = Press.inside(p.X, p.Z, half.X, half.Z)
					end
					inHome[folder] = known
				end
				here = known == true
			end
			local shown = here and model:GetAttribute(Take.Attribute) == nil and would(s)
			if s.prompt.Enabled ~= shown then
				s.prompt.Enabled = shown
			end
			place(s, shown)
		end
	end

	local function added(inst: Instance)
		if not inst:IsA("Model") or standing[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local prompt = promptNamed(inst, Press.Name)
		local key = inst:GetAttribute(Tools.KindAttribute)
		local row = if type(key) == "string" then Press.row(key) else nil
		if not (prompt and row and type(key) == "string") then
			return -- furniture, a home's own piece, or a find whose press needs a hand
		end
		standing[inst] = {
			model = inst,
			prompt = prompt,
			take = takeOf(inst),
			row = row,
			durations = Finds.durations(key),
		}
	end

	local function removed(inst: Instance)
		if inst:IsA("Model") then
			standing[inst] = nil
		end
	end

	local system = { name = "HomeUseView" }

	function system.start(_: any, _context: Brix.Context)
		for _, inst in CollectionService:GetTagged(Spots.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Spots.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Spots.Tag):Connect(removed)
		)
		table.insert(
			connections,
			RunService.Heartbeat:Connect(function(dt: number)
				since += dt
				if since >= LOOK then
					since = 0
					look()
				end
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(standing)
	end

	return system
end

return HomeUseView
