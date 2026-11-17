--!strict
--[[
	Gold: four of one find in the job box make one Gold of it (S5-03c3b, D-188, D-251, D-298), as
	Pet Simulator's golden machine turns copies of one pet into its golden one. The item catalog's
	variant table: solid gold that catches any light, worth five times the find, every find but the
	Secrets.

	A Gold is kept as a name of its own in the save's `finds`: the find's name with `Mark` after it
	("Teddy:Gold"), so the save's shape is unchanged (no new version) and the box, the shelf and
	the book count it as they count any find. Its catalog row is its find's (`base`); what's gold
	about it is drawn (ToolPicture) and priced (`BoxPanel.price`).
]]
local Grades = require("../Grades")

local Gold = {}

-- After a find's name, its Gold's: never in a find's own name (those are letters only).
Gold.Mark = ":Gold"
-- Of one find in the box that make one Gold: Pet Simulator's machine takes copies of one pet.
Gold.Need = 4
-- A Gold's worth, times its find's (the item catalog's variant table): a little more than the
-- four it took, so making one is a reward and never a loss.
Gold.Times = 5
-- The grade that never comes in gold: the Secrets are the rarest already (the catalog).
Gold.Never = "Secret" :: Grades.Grade

-- What a Gold is called on screen: "Gold Teddy bear".
Gold.Word = "Gold"

--[[
	The show when four become a Gold (S5-03c3b2), as Pet Simulator's golden machine and every
	gacha reveal build to a flash: Gold pressed, the panel dims and four copies of the find's
	picture fly off its card to a ring round the screen's middle, each landing with a chink a step
	higher; they swirl inward, ever faster, turning gold as a shimmer rises under them; a white-gold
	flash, a ring and sparks, and one big Gold pops at the middle with rays turning behind it and
	its name under it; it holds, then flies down onto its card. Sizes are shares of the screen's
	height, so a phone and a monitor see the same show.
]]
Gold.Show = table.freeze({
	Spread = 0.42, -- seconds each copy takes from the card to its place on the ring
	Stagger = 0.06, -- seconds between the four leaving the card: one, two, three, four
	Ring = 0.24, -- the ring's radius: wide enough that the four read as four on a phone
	Copy = 0.2, -- each copy's size on the ring
	Orbit = 1.4, -- seconds they swirl inward: long enough to build, short enough not to drag
	Turns = 1.75, -- turns they make round the middle as they close in, gathering speed
	Shrink = 0.6, -- a copy's size as it reaches the middle, of its size on the ring
	Jitter = 5, -- points the four shiver in the swirl's last third: about to burst
	Glow = 1.4, -- the halo growing between them as they close, of a copy's size on the ring
	Flash = 0.55, -- seconds the white-gold flash takes to clear
	Burst = 0.5, -- seconds the ring of light takes to spread and fade
	BurstSize = 1.3, -- the ring's size when it fades
	Sparks = 12, -- sparks thrown out at the flash
	SparkFly = 0.32, -- how far a spark goes
	SparkTime = 0.6, -- seconds a spark flies before it's gone
	Big = 0.46, -- the Gold's size at the middle: big, the payoff
	Pop = 0.45, -- seconds the Gold takes to pop up to its size, overshooting a touch
	Rays = 0.95, -- the rays' length behind it
	Spin = 5, -- seconds a ray takes to turn once: slow and grand
	Hold = 0.9, -- seconds it sits big at the middle before it goes to its card
	Veil = 0.45, -- the panel dimmed this much behind the show (0 clear, 1 black)
	Fade = 0.3, -- seconds the dim, the rays and the name take to go once it flies
	Chink = 0.14, -- each copy's chink this much higher in pitch than the one before
})

-- Solid gold that catches any light (the item catalog's Gold), as red, green and blue: bright
-- enough that it reads as gold under the home's warm bulb and a climb's cold torch alike.
Gold.Colour = table.freeze({ 255, 196, 64 })

-- The player attribute that says slot `i` holds a Gold (true, or absent): the slot's own key
-- stays its find's ("Teddy"), so every catalog row and model is the find's (Slots, ToolView).
function Gold.slotAttribute(i: number): string
	return `ToolGold{i}`
end

-- Every part of `model` turned to gold, wherever a Gold is drawn (a hand, a shelf, a slot's
-- picture): its textures off, one gold metal all over, its shape the find's own.
function Gold.gild(model: Model)
	local c = Gold.Colour
	local gold = Color3.fromRGB(c[1], c[2], c[3])
	for _, d in model:GetDescendants() do
		if d:IsA("SurfaceAppearance") or d:IsA("Decal") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Color = gold
			d.Material = Enum.Material.Metal
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
		end
	end
end

-- The Gold of find `name`: its key in the save.
function Gold.key(name: string): string
	return name .. Gold.Mark
end

-- The find a Gold's `key` is made of, or nil when `key` isn't a Gold's.
function Gold.base(key: string): string?
	local n = #Gold.Mark
	if #key > n and string.sub(key, -n) == Gold.Mark then
		return string.sub(key, 1, -n - 1)
	end
	return nil
end

-- Whether a find with catalog `row` can be made Gold: a find, and not a Secret.
function Gold.can(row: { find: boolean?, grade: Grades.Grade? }?): boolean
	return row ~= nil and row.find == true and row.grade ~= Gold.Never
end

return table.freeze(Gold)
