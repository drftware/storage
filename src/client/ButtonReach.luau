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
]]

local ButtonReach = {}

-- Each button's reach from the server, taken the first time any reason touches it. Weak keys: a
-- button gone from the world is forgotten with it (`:: any`: setmetatable's result doesn't carry
-- the table's key and value types).
local base: { [ProximityPrompt]: number } = setmetatable({}, { __mode = "k" }) :: any
-- What hides each button now, if anything.
local hiders: { [ProximityPrompt]: { [string]: boolean } } = setmetatable({}, { __mode = "k" }) :: any

--- Hide `prompt` on this screen for `reason` (`hidden` true), or stop hiding it for that reason.
function ButtonReach.hide(prompt: ProximityPrompt, reason: string, hidden: boolean)
	local reach = base[prompt]
	if reach == nil then
		reach = prompt.MaxActivationDistance
		base[prompt] = reach
	end
	local set = hiders[prompt]
	if hidden then
		if not set then
			set = {}
			hiders[prompt] = set
		end
		set[reason] = true
	elseif set then
		set[reason] = nil
		if next(set) == nil then
			hiders[prompt] = nil
		end
	end
	local to = if hiders[prompt] then 0 else reach
	if prompt.MaxActivationDistance ~= to then
		prompt.MaxActivationDistance = to
	end
end

return ButtonReach
