--!strict
--[[
	DoorPrompts: the door's test prompts, one per action, until L-02 makes the door the GDD's state
	machine with prompts that offer only what its state allows. Each action is on its own key so
	none hides another: Peek Q, Open E, Close F, Slam G, Lock or Unlock R, and Lift T from inside.
	A refusal flashes on the prompt in place of the unit's name ("Padlocked", "Shut it first").
	The test hall (DevCorridor) and every laid floor (FloorBuilder) put them on their units.

	`post` is a dev post's one prompt (E): "Go far", "Cut power", "Walk a floor".
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)

-- The prompts.
-- In first person a prompt shows only while its point is on screen, so the points sit on the door
-- at about eye height: pressed against the door with a level gaze, they still show.
-- A point inside the door's invisible collider loses its sight line and hides, so both sit just
-- outside it (RollUpDoor.ColliderDepth).
local PROMPT_OUT = RollUpDoor.ColliderDepth / 2 + 0.1 -- the door's prompts hang just outside the collider, hall side
local PROMPT_HEIGHT = 4 -- just under a standing player's eyes (about 4.4)
local PROMPT_REACH = 8 -- close enough to touch the door, not the neighbour's
local LIFT_IN = RollUpDoor.ColliderDepth / 2 + 0.1 -- Lift hangs just behind the collider, so the shut door hides it from the hall
local LIFT_REACH = 5 -- only someone shut inside should see Lift
local REFUSAL_SECONDS = 1.2 -- how long "Padlocked" or "Shut it first" shows before the unit's name returns

type Action = { kind: Motion.Kind, text: string, key: Enum.KeyCode, pad: Enum.KeyCode }
local OUTSIDE_ACTIONS: { Action } = {
	{ kind = "Peek", text = "Peek", key = Enum.KeyCode.Q, pad = Enum.KeyCode.ButtonL1 },
	{ kind = "Open", text = "Open", key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX },
	{ kind = "Close", text = "Close", key = Enum.KeyCode.F, pad = Enum.KeyCode.ButtonB },
	{ kind = "Slam", text = "Slam", key = Enum.KeyCode.G, pad = Enum.KeyCode.ButtonY },
}
local LIFT_ACTION: Action =
	{ kind = "LiftInside", text = "Lift", key = Enum.KeyCode.T, pad = Enum.KeyCode.ButtonX }
local LIFTS: { [Motion.Kind]: true } = { Peek = true, Open = true, LiftInside = true }

local function prompt(
	at: Attachment,
	objectText: string,
	action: Action,
	reach: number
): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = objectText
	p.ActionText = action.text
	p.KeyboardKeyCode = action.key
	p.GamepadKeyCode = action.pad
	p.HoldDuration = 0
	p.MaxActivationDistance = reach
	p.RequiresLineOfSight = true
	p.Parent = at
	return p
end

-- Shows `text` on the prompt for a moment in place of the unit's name. A newer refusal wins.
local function refuser(p: ProximityPrompt, objectText: string): (text: string) -> ()
	local shown = 0
	return function(text: string)
		shown += 1
		local mine = shown
		p.ObjectText = text
		task.delay(REFUSAL_SECONDS, function()
			if shown == mine and p.Parent then
				p.ObjectText = objectText
			end
		end)
	end
end

-- An attachment at a world frame, on the unit's own part, so its prompts stream with the unit.
local function pointOn(unit: Model, at: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.Parent = unit.PrimaryPart
	a.WorldCFrame = at
	return a
end

local DoorPrompts = {}

-- A post's prompt at `at`: one action on E (X on a pad), within a door's reach.
function DoorPrompts.post(at: Attachment, objectText: string, actionText: string): ProximityPrompt
	return prompt(
		at,
		objectText,
		{ kind = "Close", text = actionText, key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX },
		PROMPT_REACH
	)
end

-- Flashes a refusal on a post's prompt, as the doors do.
DoorPrompts.refuser = refuser

-- The door's prompts on `unit`, numbered `number`: on the door at eye height, hall side, and Lift
-- just inside it. Call before the unit is parented.
function DoorPrompts.add(unit: Model, number: string)
	local frame = RollUpDoor.frame(unit)
	local objectText = `Unit {number}`

	local function act(kind: Motion.Kind, refuse: (string) -> ())
		if LIFTS[kind] and unit:GetAttribute("DoorLocked") == true then
			refuse("Padlocked")
			return
		end
		RollUpDoor.play(unit, kind)
	end

	local outside = pointOn(unit, frame * CFrame.new(0, PROMPT_HEIGHT, -PROMPT_OUT))
	for _, action in OUTSIDE_ACTIONS do
		local p = prompt(outside, objectText, action, PROMPT_REACH)
		local refuse = refuser(p, objectText)
		p.Triggered:Connect(function()
			act(action.kind, refuse)
		end)
	end

	local lock = prompt(
		outside,
		objectText,
		{ kind = "Close", text = "Lock", key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonR1 },
		PROMPT_REACH
	)
	local refuseLock = refuser(lock, objectText)
	local function showLock()
		lock.ActionText = if unit:GetAttribute("DoorLocked") == true then "Unlock" else "Lock"
	end
	showLock()
	unit:GetAttributeChangedSignal("DoorLocked"):Connect(showLock)
	lock.Triggered:Connect(function()
		local locked = unit:GetAttribute("DoorLocked") == true
		if not RollUpDoor.setLocked(unit, not locked) then
			refuseLock("Shut it first")
		end
	end)

	local inside = pointOn(unit, frame * CFrame.new(0, PROMPT_HEIGHT, LIFT_IN))
	local lift = prompt(inside, objectText, LIFT_ACTION, LIFT_REACH)
	local refuseLift = refuser(lift, objectText)
	lift.Triggered:Connect(function()
		act("LiftInside", refuseLift)
	end)
end

return DoorPrompts
