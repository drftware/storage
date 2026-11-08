--!strict
-- lune run scripts/mannequin-poses
-- Writes art/mannequin/out/poses.json: every named pose of the Mannequin as each part's place
-- (4x4, row by row, Roblox's frame) from src/shared/Mannequin/Pose.luau, so Blender's look
-- sheets wear the game's own poses (art/mannequin/build.py --stage renders).
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Pose = require("../src/shared/Mannequin/Pose")

local out = {}
for _, name in Pose.Names do
	local parts = Pose.solve(Pose.Poses[name])
	local rows = {}
	for part, t in parts do
		if part ~= "HumanoidRootPart" then
			rows[part] = { t[1], t[2], t[3], t[10], t[4], t[5], t[6], t[11], t[7], t[8], t[9], t[12], 0, 0, 0, 1 }
		end
	end
	out[name] = rows
end
fs.writeFile("art/mannequin/out/poses.json", serde.encode("json", out))
print(`poses: {#Pose.Names} written to art/mannequin/out/poses.json`)
