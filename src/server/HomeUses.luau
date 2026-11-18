--!strict
--[[
	HomeUses: the find's own button on each find set out in a home (S5-03i3, D-351). The moment:
	you stand your lamp on the end table, walk up, press Switch, and the corner glows.

	Arranging puts one on every find it draws whose press works where it stands (`Press.verb`:
	Switch, Play, Wind, Squeeze...), beside its Take, at the same point by the find's top. Every
	screen in that home shows it (HomeUseView: only to a player inside the home, never while that
	screen's Arrange is open, and never while a press would do nothing). Anyone in the home may
	press it, its holder or a friend (D-345): `near` checks the presser isn't wrapped and stands in
	the home within reach. The press itself is FindUses' (`setOut`): the stamp every screen plays.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Press = require(ReplicatedStorage.Shared.Home.Press)
local Take = require(ReplicatedStorage.Shared.Home.Take)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Prompts = require(script.Parent.Prompts)

local HomeUses = {}

-- Puts find `key`'s own button on `model` (none if its press doesn't work where it stands);
-- `press` hears each press.
function HomeUses.offer(model: Model, key: string, press: (player: Player) -> ()): ProximityPrompt?
	local verb = Press.verb(key)
	local body = Tools.body(model) or model:FindFirstChildWhichIsA("BasePart", true)
	if not (verb and body) then
		return nil
	end
	local cf, size = model:GetBoundingBox()
	local at = Instance.new("Attachment")
	at.Name = Press.Name
	at.Parent = body
	at.WorldPosition = cf.Position + Vector3.new(0, size.Y * 0.3, 0) -- where Take's is
	local p = Prompts.make(at, {
		actionText = verb,
		key = Enum.KeyCode.F,
		pad = Enum.KeyCode.ButtonY,
		reach = Press.Reach,
	})
	p.Name = Press.Name
	p.RequiresLineOfSight = false -- as Take's; a neighbour through the wall is kept out by `near`
	p.Enabled = false -- each screen in the home shows it (HomeUseView)
	p.Triggered:Connect(press)
	return p
end

-- On a home's folder of finds set out: the room's middle and half size, for `near` here and
-- HomeUseView's own judge of who is in the home.
function HomeUses.room(folder: Folder, middle: CFrame, size: Vector3)
	folder:SetAttribute(Press.RoomAttribute, middle)
	folder:SetAttribute(Press.HalfAttribute, size / 2)
end

-- Whether `player` may press `model` now: not wrapped, alive, in the home it stands in (its
-- folder's room), within reach of it, and it isn't being taken.
function HomeUses.near(player: Player, model: Model): boolean
	if Prompts.wrapped(player) or model:GetAttribute(Take.Attribute) ~= nil then
		return false
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local folder = model.Parent
	if not (root and root:IsA("BasePart") and folder) then
		return false
	end
	local middle, half =
		folder:GetAttribute(Press.RoomAttribute), folder:GetAttribute(Press.HalfAttribute)
	if typeof(middle) ~= "CFrame" or typeof(half) ~= "Vector3" then
		return false
	end
	local p = middle:PointToObjectSpace(root.Position)
	if not Press.inside(p.X, p.Z, half.X, half.Z) then
		return false
	end
	local cf = model:GetBoundingBox()
	return (root.Position - cf.Position).Magnitude <= Press.Reach + Press.Slack
end

return HomeUses
