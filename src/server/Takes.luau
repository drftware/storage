--!strict
--[[
	Takes: the Take button on a find standing in a home (S5-03i2a, D-350), made one way for the
	shelf's cubbies (Shelves) and the finds set out (Arranging). Each system checks a press against
	its own save (the cubby or row is the presser's own and still holds that find), then:

	- `near`: the presser isn't wrapped and stands within reach of it (`Take.Reach`, plus slack);
	- `leave`: the copy is stamped with its taker (`Take.Attribute`) and its button goes; every
	  screen hides it and flies its own copy into the taker's hand (HomeTakeView); the copy goes a
	  moment later (`Take.Linger`), so a screen a beat behind still sees the stamp.

	The take itself (the save's spot freed and `Slots:unbox` in the same step) is the caller's.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Take = require(ReplicatedStorage.Shared.Home.Take)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Prompts = require(script.Parent.Prompts)

local Takes = {}

-- The part a button hangs on: the find's body as a hand holds it, else any part of it.
local function bodyOf(model: Model): BasePart?
	local body = Tools.body(model)
	return body or model:FindFirstChildWhichIsA("BasePart", true)
end

-- Puts a Take button on `model`, by its top, where your eye goes; `press` hears each press.
function Takes.offer(model: Model, press: (player: Player) -> ()): ProximityPrompt?
	local body = bodyOf(model)
	if not body then
		return nil
	end
	local cf, size = model:GetBoundingBox()
	local at = Instance.new("Attachment")
	at.Name = "Take"
	at.Parent = body
	at.WorldPosition = cf.Position + Vector3.new(0, size.Y * 0.3, 0)
	local p = Prompts.make(at, {
		actionText = Take.Verb,
		key = Enum.KeyCode.E,
		pad = Enum.KeyCode.ButtonX,
		reach = Take.Reach,
	})
	p.RequiresLineOfSight = false -- a cubby's sides mustn't hide what stands in it
	p.Enabled = false -- its holder's screen shows it (HomeTakeView)
	p.Triggered:Connect(press)
	return p
end

-- Whether `player` may take `model` now: not wrapped, alive, and within reach of it.
function Takes.near(player: Player, model: Model): boolean
	if Prompts.wrapped(player) then
		return false
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (root and root:IsA("BasePart")) then
		return false
	end
	local cf = model:GetBoundingBox()
	return (root.Position - cf.Position).Magnitude <= Take.Reach + Take.Slack
end

-- `model` taken by `player`: stamped, its button gone, and gone itself a moment later.
function Takes.leave(model: Model, player: Player)
	model:SetAttribute(Take.Attribute, player.UserId)
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d:Destroy()
		end
	end
	task.delay(Take.Linger, function()
		model:Destroy()
	end)
end

return Takes
