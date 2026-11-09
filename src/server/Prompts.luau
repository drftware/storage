--!strict
--[[
	Prompts: the ProximityPrompts the server puts in the world, made one way. The doors (Doors) and
	the test hall's posts ("Go far", "Cut power", "Walk a floor") and a tool on a floor ("Pick up") use them.

	A refusal flashes on the prompt in place of its name for a moment ("Padlocked", "Still laying
	it"), then the name comes back.
]]
local Prompts = {}

-- How long a refusal shows before the prompt's name returns.
local REFUSAL_SECONDS = 1.2
-- A post is touched from about a door's reach.
local POST_REACH = 8

export type Spec = {
	objectText: string,
	actionText: string,
	key: Enum.KeyCode,
	pad: Enum.KeyCode,
	reach: number,
	hold: number?, -- seconds to hold (0 or nil: a tap)
}

-- A prompt on `at`. It needs a clear line from the player, so a shut door hides what's behind it.
function Prompts.make(at: Attachment, spec: Spec): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = spec.objectText
	p.ActionText = spec.actionText
	p.KeyboardKeyCode = spec.key
	p.GamepadKeyCode = spec.pad
	p.HoldDuration = spec.hold or 0
	p.MaxActivationDistance = spec.reach
	p.RequiresLineOfSight = true
	p.Parent = at
	return p
end

--[[
	Returns a function that flashes a refusal on `p` in place of its name; `name()` gives the name
	to put back, so a prompt whose name changed meanwhile (a door padlocked) gets the new one. A
	newer refusal wins.
]]
function Prompts.refuser(p: ProximityPrompt, name: () -> string): (text: string) -> ()
	local shown = 0
	return function(text: string)
		shown += 1
		local mine = shown
		p.ObjectText = text
		task.delay(REFUSAL_SECONDS, function()
			if shown == mine and p.Parent then
				p.ObjectText = name()
			end
		end)
	end
end

-- A test post's one prompt on `at`: E (X on a pad) unless `key` says otherwise.
function Prompts.post(
	at: Attachment,
	objectText: string,
	actionText: string,
	key: Enum.KeyCode?,
	pad: Enum.KeyCode?
): ProximityPrompt
	return Prompts.make(at, {
		objectText = objectText,
		actionText = actionText,
		key = key or Enum.KeyCode.E,
		pad = pad or Enum.KeyCode.ButtonX,
		reach = POST_REACH,
	})
end

return Prompts
