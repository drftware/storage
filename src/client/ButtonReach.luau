--!strict
--[[
	ButtonReach: a button in the world hidden on this screen only, for any number of reasons at
	once (L-16b1, D-111). It shows only when nothing hides it.

	A screen hides a button by its reach (`MaxActivationDistance` 0): the server never changes a
	button's reach after making it, while it does turn buttons on and off (`Enabled`) as a door
	moves, which would undo a screen's own switch. Two views can want the same button hidden for
	different reasons: a door's Lock shows only with a padlock in your hand (ToolView) and never
	while you lie up on the tops (LadderView). Each says its own reason here, so neither undoes the
	other.

	Only a hidden button is remembered, in plain tables, and forgotten the moment nothing hides it
	or it leaves the world (streamed out or destroyed: its reach goes back, and a view that still
	hides it does so again when it streams back in, as LadderView and ToolView already do). Never key these by the button in a weak table: Roblox lets go of a
	weakly held Instance's entry while the Instance is still in the world (Studio, L-16b2: 163
	buttons in, none left after a garbage pass), so the server's reach was lost and taken again
	as 0, and every door button stayed hidden after climbing down off the tops.
]]

local ButtonReach = {}

-- Each hidden button's reach from the server, taken when the first reason hides it.
local base: { [ProximityPrompt]: number } = {}
-- What hides each hidden button.
local hiders: { [ProximityPrompt]: { [string]: true } } = {}
-- A hidden button leaving the world forgets it.
local gone: { [ProximityPrompt]: RBXScriptConnection } = {}

local restore: (prompt: ProximityPrompt) -> ()

local function forget(prompt: ProximityPrompt)
	base[prompt] = nil
	hiders[prompt] = nil
	local c = gone[prompt]
	if c then
		c:Disconnect()
		gone[prompt] = nil
	end
end

--- Hide `prompt` on this screen for `reason` (`hidden` true), or stop hiding it for that reason.
function ButtonReach.hide(prompt: ProximityPrompt, reason: string, hidden: boolean)
	local set = hiders[prompt]
	if hidden then
		if not set then
			set = {}
			hiders[prompt] = set
			base[prompt] = prompt.MaxActivationDistance
			gone[prompt] = prompt.AncestryChanged:Connect(function()
				if not prompt:IsDescendantOf(game) then
					restore(prompt)
				end
			end)
		end
		set[reason] = true
		if prompt.MaxActivationDistance ~= 0 then
			prompt.MaxActivationDistance = 0
		end
	elseif set and set[reason] then
		set[reason] = nil
		if next(set) == nil then
			restore(prompt)
		end
	end
end

-- Nothing hides `prompt` now: its reach back, and forgotten.
function restore(prompt: ProximityPrompt)
	local reach = base[prompt]
	forget(prompt)
	if reach and prompt.MaxActivationDistance ~= reach then
		prompt.MaxActivationDistance = reach
	end
end

return ButtonReach
