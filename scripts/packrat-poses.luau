--!strict
-- lune run scripts/packrat-poses
-- Writes art/packrat/out/poses.json: every named pose of the Packrat as each part's place (4x4,
-- row by row, Roblox's frame) from src/shared/Packrat/Pose.luau, and where a carried find sits
-- (`Carry`) or, in a pose that holds it in its hands, where it sits between them (`Grip`), so
-- Blender's look sheets wear the game's own poses (art/packrat/build.py renders).
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Pose = require("../src/shared/Packrat/Pose")

local function rows(t: { number }): { number }
	return { t[1], t[2], t[3], t[10], t[4], t[5], t[6], t[11], t[7], t[8], t[9], t[12], 0, 0, 0, 1 }
end

local out = {}
for _, name in Pose.Names do
	local placed = {}
	for part, t in (Pose.solve(Pose.Poses[name])) do
		if part ~= "HumanoidRootPart" then
			placed[part] = rows(t)
		end
	end
	placed.Carry = rows(Pose.carry(Pose.Poses[name]))
	local hands = Pose.InHands[name]
	if hands then
		placed.Grip = rows(Pose.grip(Pose.Poses[name], hands))
	end
	out[name] = placed
end
fs.writeFile("art/packrat/out/poses.json", serde.encode("json", out))
print(`poses: {#Pose.Names} written to art/packrat/out/poses.json`)
