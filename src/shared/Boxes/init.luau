--!strict
-- The moving boxes every unit is full of (art/boxes/README.md): their real sizes, generated from
-- the art's spec, and the templates a unit's contents are cloned from. A box is one MeshPart whose
-- pivot is the middle of its bottom and whose labelled long side faces its front (LookVector).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

export type Name = "Small" | "Medium" | "Large" | "Wardrobe" | "Open"

local Boxes = {}
Boxes.Specs = Specs
Boxes.Names = { "Small", "Medium", "Large", "Wardrobe", "Open" } :: { Name }

-- The marked box (B-01): the one box in a unit with something in it, a Model of parts whose Open
-- motion tears the tape and springs the flaps (Specs.Marked; art/boxes/README.md).
Boxes.Marked = Specs.Marked

-- Its sounds, from Roblox's licensed library (measured in docs/STUDIO.md "The marked box's
-- sounds"): `from` and `length` in seconds of the file, played as a Sound's TimePosition window.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
Boxes.Sounds = {
	-- the tape snapping in the middle: a short zippy rip, all of it in its first 75 ms
	Tear = { id = "rbxassetid://9113836687", from = 0, length = 0.15, volume = 0.8, pitch = 1.1 },
	-- the flaps bursting up: a cardboard slap, its hit 0.82 s into the file
	Flaps = { id = "rbxassetid://9113579352", from = 0.8, length = 0.4, volume = 0.9 },
	-- something inside: a soft, airy pulsing hum, looped, heard only up close
	Hum = { id = "rbxassetid://9116732713", from = 0, length = 18, volume = 0.18 },
} :: { [string]: Sound }

-- The kraft under the texture, shown only if the maps fail to load.
local KRAFT = Color3.fromRGB(165, 122, 78)

-- Where the templates live: in the place, since Rojo can't sync imported meshes (D-009).
local function templates(): Instance?
	local props = ReplicatedStorage:FindFirstChild("Props")
	return if props then props:FindFirstChild("Boxes") else nil
end

-- The import's last step, once per freshly imported box, from the command bar or the MCP
-- (CollisionFidelity can't be set while the game runs). A box is scenery until a keeper wakes it:
-- anchored, colliding as its box (the opened one as its hull, flaps and all), firing no touches.
-- Its pivot stays the middle of its bottom, turned square with the part.
function Boxes.prepare(part: MeshPart, name: Name)
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.CollisionFidelity = if Specs.Boxes[name].Open
		then Enum.CollisionFidelity.Hull
		else Enum.CollisionFidelity.Box
	part.Color = KRAFT
	part.PivotOffset = CFrame.new(part.PivotOffset.Position)
	part:SetAttribute("Box", name)
end

-- A copy of a box standing at `pivot` (its bottom's middle, its labelled side facing the pivot's
-- LookVector), parented last. Nil, with a warning, if the place is missing the template.
function Boxes.clone(name: Name, pivot: CFrame, parent: Instance): MeshPart?
	local folder = templates()
	local template = if folder then folder:FindFirstChild(name) else nil
	if not (template and template:IsA("MeshPart")) then
		warn(
			`Boxes: no template at ReplicatedStorage.Props.Boxes.{name}; import it (art/boxes/README.md)`
		)
		return nil
	end
	local box = template:Clone()
	box:PivotTo(pivot)
	box.Parent = parent
	return box
end

return Boxes
