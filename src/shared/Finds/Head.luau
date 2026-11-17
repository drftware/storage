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
-- The weld holding a worn find to its wearer's head, and the find's model's name on them (not
-- `Tools.HeldName`: it isn't the thing in their hand).
Head.WeldName = "HeadWeld"
Head.ModelName = "WornFind"

--[[
	How a find sits on a head. `scale`: the find's model is built real size (D-196) and a Roblox
	head is bigger than a person's, so the hat is grown to fit it. `down`: studs its rim sits below
	the head's hat point (the top of the head), so the shell covers the crown, not perched on it.
	`ahead`: studs it sits forward, its brim over your brow. `tip`: degrees its front tips down,
	the lamp looking a little ahead of your feet as a real cap lamp does. `hide`: parts hidden
	while it's worn (the hat's cord and battery case, which a miner wears at the hip).
]]
export type Fit = {
	scale: number,
	down: number,
	ahead: number,
	tip: number,
	hide: { string },
}

Head.Fits = {
	HardHat = {
		scale = 1.4,
		down = 0.42,
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
