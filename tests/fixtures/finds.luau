--!strict
-- Every built find's data for the specs (F-G1a): the bedroom set's generated Specs and the kit's
-- generated sets (src/shared/Finds/Sets), loaded with Lune's Vector3 and Color3 since the
-- generated modules build them and Lune lacks them as globals. `boxes` is each find's size and
-- middle from its pivot, as `Finds.box` gives the game; `kit` each kit-built find's whole data,
-- and `order` its motions in the order its set's text wrote them.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local SETS = "src/shared/Finds/Sets"

-- any: generated tables, read field by field by the specs
local function load(path: string): any
	return luau.load(fs.readFile(path), {
		environment = {
			Vector3 = roblox.Vector3,
			Color3 = roblox.Color3,
			-- a set's `require(script.Parent.Parent.Art)` is only for its type
			script = { Parent = { Parent = { Art = {} } } },
			require = function()
				return {}
			end,
		},
	})()
end

local boxes: { [string]: { Size: any, Centre: any } } = {}
local kit: { [string]: any } = {}
local order: { [string]: { string } } = {}

for name, spec in load("src/shared/Finds/Specs.luau").Finds do
	boxes[name] = { Size = spec.Size, Centre = roblox.Vector3.new(0, spec.Size.Y / 2, 0) }
end
for _, file in fs.readDir(SETS) do
	local path = `{SETS}/{file}`
	for name, find in load(path) do
		kit[name] = find
		boxes[name] = { Size = find.Size, Centre = find.Centre }
	end
	-- the motions' order as written: a find opens at "\t<Find> = {", a motion at three tabs in
	local current: string? = nil
	for line in string.gmatch(fs.readFile(path), "[^\n]+") do
		local find = string.match(line, "^\t(%u%w*) = {$")
		if find then
			current = find
			order[find] = {}
		end
		local motion = string.match(line, "^\t\t\t(%u%w*) = {$")
		if motion and current and kit[current] and kit[current].Motions[motion] then
			table.insert(order[current], motion)
		end
	end
end

return { boxes = boxes, kit = kit, order = order, Vector3 = roblox.Vector3 }
