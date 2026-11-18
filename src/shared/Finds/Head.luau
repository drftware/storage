--!strict
--[[
	Head (F-G1b4a1, D-277): a find worn on your head, as Lethal Company's and Phasmophobia's head
	torches are. The hard hat's one word is Wear: pressed in your hand, it goes from your hand onto
	your head, its lamp clicks on, and the slot it was in is free again. On your head it's still
	yours (`Slots`): caught, it drops with everything else; aboard as the gate shuts, it's kept with
	your other finds. It lights the hall from your forehead for everyone, and holds a Mannequin as
	any found light does, from where your head is.
	Pure numbers and rules, so Lune tests them: `Slots` welds the hat, `FindUses` takes the press.
]]

local Head = {}

-- The press's word for a find that goes on your head (its row's `verb`, the button's word).
Head.Verb = "Wear"
-- On the Player: the catalog key of the find on their head, or "" for none (screens read it).
Head.Attribute = "ToolHead"
-- On a worn find's model: its wearer's UserId, while it's on their head.
Head.WornAttribute = "WornBy"
-- Whether a Player's `Attribute` says they wear something (their headlamp's aim is taken then).
function Head.wearing(value: unknown): boolean
	return type(value) == "string" and value ~= ""
end
-- The weld holding a worn find to its wearer's head, and the find's model's name on them (not
-- `Tools.HeldName`: it isn't the thing in their hand).
Head.WeldName = "HeadWeld"
Head.ModelName = "WornFind"

--[[
	How a find sits on a head, numbered for a standard head (`Standard` studs tall, the classic
	R15 head) and grown with yours, so a bigger avatar's hat is bigger and just as deep (D-283).
	`scale`: the find's model is built real size (D-196) and a Roblox head is bigger than a
	person's, so the hat is grown to fit it. `rim`: the part whose lowest edge is its rim (the
	shell, brim and all). `down`: studs that rim sits below the head's hat point (the top of the
	head): the shell covers the crown and the brim rides level over your brow, a miner's hard hat,
	not perched on top and never down at the chin. `ahead`: studs it sits forward. `tip`: degrees
	its front tips down, the lamp looking a little ahead of your feet as a real cap lamp does.
	`hide`: parts hidden while it's worn (the hat's cord and battery case, which a miner wears at
	the hip).
]]
export type Fit = {
	scale: number,
	rim: string,
	down: number,
	ahead: number,
	tip: number,
	hide: { string },
}

Head.Standard = 1.2 -- studs: the classic R15 head's height, the one `Fits` are numbered for

Head.Fits = {
	HardHat = {
		-- 1.7: its shell 1.5 studs across, a Roblox hat's width, so it sits over most hair (the
		-- free Pal Hair is 1.76 across) as a hat does, not buried in it; seen in Play (D-283)
		scale = 1.7,
		rim = "HardHat_Shell",
		down = 0.3,
		ahead = 0.05,
		tip = 4,
		hide = { "HardHat_Pack" },
	},
} :: { [string]: Fit }

-- How `key` sits on a head, or nil if it isn't worn there.
function Head.fit(key: string): Fit?
	return Head.Fits[key]
end

--[[
	Where a find sits on a head `height` studs tall (D-283). A find's pivot is its grip, which for
	the hat is the crown of its shell, so it's sat by its rim: `depth` is studs from its pivot down
	to its rim's lowest edge at its own size (scale 1). Gives the size to grow it to, and how far
	its pivot sits up from and ahead of the head's hat point, so the rim lands `down` under it.
]]
function Head.seat(fit: Fit, height: number, depth: number): (number, number, number)
	local k = if height > 0 then height / Head.Standard else 1
	local scale = fit.scale * k
	return scale, depth * scale - fit.down * k, fit.ahead * k
end

--[[
	Your own eye (D-282): with your camera at your head, the hat you wear is hidden from you alone,
	so its shell and brim never fill your view; friends and the mirror still see it on you, and
	its lamp still lights the way. Roblox hides your body in first person only while its own camera
	runs, so a camera the game holds (a crawl, a shot) would show the hat; this rule never depends
	on it. `HideNear`: studs from your head's middle inside which it's wholly hidden (first person
	sits at about 0.5). `HideFar`: studs past which it shows in full (no camera zooms out between).
	`HideRate`: how fast it fades in or out, per second (about a fifth of a second), so it never
	pops as the camera leaves your head (the RC car's view, being caught).
]]
Head.HideNear = 1.5
Head.HideFar = 3
Head.HideRate = 14

-- How hidden your worn find should be (0 shown, 1 hidden) with your camera `distance` studs
-- from your head's middle.
function Head.hidden(distance: number): number
	if distance <= Head.HideNear then
		return 1
	elseif distance >= Head.HideFar then
		return 0
	end
	local t = (Head.HideFar - distance) / (Head.HideFar - Head.HideNear)
	return t * t * (3 - 2 * t) -- eased at both ends
end

-- `now` moved toward `goal` over `dt` seconds at `HideRate`, landing on it once within a hair.
function Head.fade(now: number, goal: number, dt: number): number
	local next = goal + (now - goal) * math.exp(-Head.HideRate * dt)
	return if math.abs(next - goal) < 0.01 then goal else next
end

--[[
	The ground floor (D-259: "At home nothing runs down"): is a point, in the front office's own
	frame (`Lobby.Origin`; studs right, up and back from its front edge), on it? Its room is
	`width` across and `depth` back from that edge; the homes open off its walls and run `beyond`
	studs past them, and the floor is everything from a little under its deck to well over head.
]]
Head.Beyond = 40 -- studs past the room's walls the homes reach (a home is 30 deep)
Head.Below, Head.Above = 8, 40 -- studs under and over the deck still counted the ground floor
function Head.home(x: number, y: number, z: number, width: number, depth: number): boolean
	return math.abs(x) <= width / 2 + Head.Beyond
		and z <= Head.Beyond
		and z >= -depth - Head.Beyond
		and y >= -Head.Below
		and y <= Head.Above
end

return Head
