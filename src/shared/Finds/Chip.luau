--!strict
--[[
	Fragile finds (F-G1e5e, D-296), as R.E.P.O.'s valuables: careless carrying costs you. The moment:
	you panic, drop the oil lamp from a run, and hear its glass crack. It still lights, but it's
	worth half now, for good.

	A find whose row names a glass part (`fragile`: the oil lamp's chimney, the glass lamp's shade)
	cracks when it's let go hard: you were running, or falling, or it fell a long way from your
	hand to the floor (`hard`, the server's own measure as it lands). Set down standing still, it
	never does. It cracks once (`cracks`): the crack is drawn on its glass on every screen
	(`mark`), it's heard where it lands over its own clank (`Sound`), and from then it's worth half
	(`worth`), kept with it through the gate into your save (`Save.chip`). Nothing on screen says
	why: you hear it, you see it, you carry the next one more carefully.

	Pure, but for `mark`, which only adds decals to a model.
]]
local Chip = {}

-- The model attribute every screen reads: true once the find's glass is cracked (`Slots`).
Chip.Attribute = "Chipped"

-- Studs a second you were moving as you let go (your body's speed, any way) at or above which a
-- fragile find cracks: about two thirds of a full run (Roblox's walk is 16, and you're always at
-- it unless your stick is part way). Lower makes every drop on the move crack; higher only a
-- flat-out sprint. Standing or creeping, it never does.
Chip.HardSpeed = 10
-- Studs it falls from your hand to the floor at or above which it cracks however slowly you
-- moved: let go standing, it falls about 2; let go at the top of a jump or off a crate's edge,
-- more than this.
Chip.HardFall = 4.5

-- The crack drawn on the glass (art/finds/kit/crack.py, uploaded by scripts/upload_art: Crack).
Chip.Image = "rbxassetid://140562657168117"
-- The crack heard as it lands, over its own clank: "glass crack" (0.7 s), a short sharp crack
-- with no shatter after it, since it still works.
Chip.Sound =
	{ id = "rbxassetid://133541517744065", from = 0, length = 0.7, volume = 0.8, pitch = 1 }
-- How far off the crack is heard (studs): about a unit's width, so whoever is near hears it and a
-- friend down the hall doesn't. It's yours to hear, not a noise that draws monsters.
Chip.Heard = 30
-- The decal's name on a cracked part, so a part is marked once.
Chip.DecalName = "Crack"

-- Whether a drop is hard: you were moving `speed` studs a second as you let go, and it fell
-- `fall` studs from your hand to the floor. A bad number is never hard.
function Chip.hard(speed: number, fall: number): boolean
	if speed ~= speed or fall ~= fall then
		return false
	end
	return speed >= Chip.HardSpeed or fall >= Chip.HardFall
end

-- Whether a find cracks as it lands: it's fragile (its row's `fragile`), it isn't cracked yet
-- (`chipped`), and the drop was hard. Never twice.
function Chip.cracks(fragile: string?, chipped: boolean, speed: number, fall: number): boolean
	return fragile ~= nil and fragile ~= "" and not chipped and Chip.hard(speed, fall)
end

-- What a find worth `worth` in cash is worth once cracked: half, rounded down, never below 1 for
-- a find worth anything. Uncracked, its worth.
function Chip.worth(worth: number, chipped: boolean): number
	if not chipped or worth ~= worth or worth <= 0 then
		return worth
	end
	return math.max(1, math.floor(worth / 2))
end

-- Draws the crack on `model`'s part named `part` (its row's `fragile`), once: decals on its faces.
-- Whether the part was there.
function Chip.mark(model: Model, part: string): boolean
	local glass = model:FindFirstChild(part, true)
	if not (glass and glass:IsA("BasePart")) then
		return false
	end
	if glass:FindFirstChild(Chip.DecalName) then
		return true
	end
	-- front and back, so you see it whichever way the find lies (a round chimney shows each on
	-- its half); made here, not at load, so the Lune spec can require this module
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local decal = Instance.new("Decal")
		decal.Name = Chip.DecalName
		decal.Texture = Chip.Image
		decal.Face = face
		decal.Parent = glass
	end
	return true
end

return table.freeze(Chip)
