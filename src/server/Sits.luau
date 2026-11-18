--!strict
--[[
	Sits: the Sit button on each seat of a home's furniture (S5-03i4, D-353). The moment: you walk
	up to the milk crate in your home, press Sit, and you're sat on it; a friend over at yours sits
	on the bed beside you. Jump and you're up, as anywhere in Roblox.

	Arranging puts one on every seat of each piece it draws (`Home.Sit` rows: the crate, the
	beanbag, the blanket, the camp bed). Every screen in that home shows it (HomeSitView: only to a
	player inside the home, never while that screen's Arrange is open or while the seat is taken).
	Anyone in the home may sit, its holder or a friend (D-345; Animal Crossing's visitors use the
	furniture): `HomeUses.near` checks the sitter isn't wrapped and stands in the home within reach.
	A piece moved or put away stands up whoever sits on it first (`stand`), so nobody rides a crate
	across the room or is left sitting on air.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sit = require(ReplicatedStorage.Shared.Home.Sit)
local HomeUses = require(script.Parent.HomeUses)
local Prompts = require(script.Parent.Prompts)

local Sits = {}

-- Sits `player` on `seat` of `model` if they may: in the home within reach, alive, not sat
-- already, and the seat free. A press that can't sit does nothing (its button wasn't showing).
local function sit(player: Player, model: Model, seat: Seat)
	if seat.Occupant ~= nil or not HomeUses.near(player, model) then
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if humanoid then humanoid.RootPart else nil
	if not (humanoid and root) or humanoid.Health <= 0 or humanoid.SeatPart ~= nil then
		return
	end
	if (root.Position - seat.Position).Magnitude > Sit.Reach + Sit.Slack then
		return
	end
	seat:Sit(humanoid)
end

-- Puts a Sit button over each of `model`'s seats.
function Sits.offer(model: Model)
	for _, d in model:GetDescendants() do
		if not (d:IsA("Seat") and d:GetAttribute(Sit.KindAttribute) ~= nil) then
			continue
		end
		local seat = d :: Seat
		local at = Instance.new("Attachment")
		at.Name = Sit.Name
		at.Position = Vector3.new(0, Sit.Above, 0)
		at.Parent = seat
		local p = Prompts.make(at, {
			actionText = Sit.Verb,
			key = Enum.KeyCode.R,
			pad = Enum.KeyCode.ButtonB,
			reach = Sit.Reach,
		})
		p.Name = Sit.Name
		p.RequiresLineOfSight = false -- a find standing on the crate mustn't hide it
		p.Enabled = false -- each screen in the home shows it (HomeSitView)
		p.Triggered:Connect(function(player: Player)
			sit(player, model, seat)
		end)
	end
end

-- Stands up whoever sits on `model`, before it moves or goes.
function Sits.stand(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("Seat") then
			local humanoid = d.Occupant
			local weld = d:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			if humanoid then
				humanoid.Sit = false
			end
		end
	end
end

return Sits
