--!strict
--[[
	What you carry in your three slots (L-11b, GDD "Tools"; finds since S1-05, GDD "Finds"): one row
	each, as keepers are rows. A row says what it's called on screen, which template in the place it
	is, how it sits in your first-person view and in a friend's hand, and what it sounds like. The
	flashlight isn't here: everyone has one in hand, outside the slots (GDD; `Flashlight`).

	A tool's key is one of `Deal.Tools`' names, so a unit dealt "BoltCutters" lays this row's tool;
	a find's (`find`) is one of `Deal.Finds`'. Pure data (Lune reads it in the specs); `Tools`
	(init) does the instances.
]]

local Grades = require("../Grades")
local Rows = require("../Finds/Rows")

export type Sound = {
	id: string,
	from: number, -- seconds into the recording where the sound starts
	length: number, -- seconds of it played
	volume: number,
	pitch: number?, -- its playback speed (1 when nil): above 1 a smaller, lighter thing
}

-- How a tool wears out (S1-08, GDD "Tools wear out"), as Minecraft's tools do: it works `uses`
-- times, and the use that spends the last breaks it in your hand (`Wear`, `Slots:wear`).
export type Wear = {
	uses: number, -- the times a new one works
	-- seconds after its last use that it breaks, so the use's own moment lands first (the
	-- padlock's snap as it comes off, the horn's last blast dying away), then the tool's
	late: number,
	snap: Sound, -- it breaking at your hand: heard by you, and near you by friends
	-- the colours (0 to 255 red, green, blue) of the bits that fly off it as it breaks; none: it
	-- doesn't shatter, it's tossed away spent (the empty air horn)
	bits: { { number } },
}

export type Row = {
	name: string, -- on screen: the prompt's object, the slot's label ("Bolt cutters")
	template: string, -- the template's name under ReplicatedStorage.Props.Tools
	-- your view: where your left hand holds it, from the camera (right, up, back, in studs), then
	-- its turn (degrees: yaw left, pitch up, roll), as `Torch.Hold` and `HoldTurn` are the torch's
	hold: { number },
	holdTurn: { number },
	-- your view while you hold its button at a door (Cut, Lock): brought down to the latch; or,
	-- for a tool with a `verb`, while you use it (the air horn raised to blow)
	use: { number },
	useTurn: { number },
	-- a friend's hand: the grip's turn from their left hand's grip attachment, degrees about the
	-- hand's X, Y, Z (CFrame.Angles); none leaves the jaw along the hand's front (-Z)
	inHand: { number },
	-- the slot's picture: the camera's distance from the tool, as a share of its length; how far
	-- it's tipped to show its top (degrees about X), turned (about Y), then laid across the square
	-- (about the view's axis)
	icon: { number },
	pickUp: Sound, -- your hand closing on it: heard by you, and near you by friends
	drop: Sound, -- it landing on the concrete
	-- A big tool friends see on your left shoulder instead of in your hand (it would swing with
	-- your arm): where its grip sits from your upper torso's middle (right, up, back, in studs).
	-- `inHand` then turns it from there.
	shoulder: { number }?,
	-- It takes both hands, as Lethal Company's two-handed items: while it's in your hand you can't
	-- switch slots or pick anything up; drop it first.
	bothHands: boolean?,
	-- Your walk while it's in your hand (studs a second; Roblox's own is 16).
	walkSpeed: number?,
	-- What you do with it in your hand, one word on the press (Blow): a tool with one has a press
	-- of its own (`Tools.UseRemote`), wherever you stand.
	verb: string?,
	-- A find (S1-05, GDD "Finds"): something worth taking out, not a tool. It takes a slot like a
	-- tool, as Lethal Company's scrap shares its slots with your gear; its prompt says Take; its
	-- template is the find's art at ReplicatedStorage.Props.Finds.<template> (`Finds`).
	find: boolean?,
	-- A find's grip: where your hand closes on it, in studs from the middle of its bottom
	-- (across its front, up, front to back, its front towards -Z). A tool's grip is its pivot.
	grip: { number }?,
	-- How heavy it feels in your hand, 0 to 1 (a find's; none for a tool): it comes up into your
	-- view slower, sags as its weight lands in your hand, and sways lazier as you walk. Felt only:
	-- your walk is the same.
	heft: number?,
	-- A find's grade (D-188, `Grades`): how rare it is, so how often a unit holds it.
	grade: Grades.Grade?,
	-- A find's worth in cash, the item catalog's value (within its grade's `Grades.Worth`): the
	-- Packrat takes your most valuable find first (`Carry.worth`).
	worth: number?,
	-- The lowest floor a find is dealt on; none: from floor 1.
	from: number?,
	-- The catalog says loose only (the Old lamp, found lit): it stands on the unit's floor, never in
	-- its marked box (`Deals`).
	loose: boolean?,
	-- Fragile (F-G1e5e, as R.E.P.O.'s valuables): the glass part that cracks when it's dropped
	-- hard, by name; cracked once, it's worth half for good (`Finds/Chip`, `Slots`).
	fragile: string?,
	-- It wears out (S1-08). None: it never does (the ladder, a find), or it's used up whole as it's
	-- placed (the padlock hung on a door, the roll laid across a hall: `Slots:spend`).
	wear: Wear?,
}

local Catalog: { [string]: Row } = {
	-- Open padlocked units and free a friend from one (GDD). 18-inch cutters, red handles.
	BoltCutters = {
		name = "Bolt cutters",
		template = "BoltCutters",
		-- low on your left, jaw forward and a little in, so it's plain without covering the hall
		hold = { -0.72, -0.8, -1.3 },
		holdTurn = { -10, 14, -12 },
		-- out in front of you, reaching for the door, turned a little to show the handles and the
		-- jaw dipped towards the latch
		use = { -0.3, -0.45, -1.35 },
		useTurn = { 16, -10, -12 },
		-- through the fist front to back, as a hammer hangs at your side: the jaw forward, the
		-- head's plates and bolts facing out to the side
		inHand = { 0, 0, 90 },
		-- the plates and bolts to the front, the jaw to the upper right
		icon = { 0.5, 70, 0, -45 },
		-- Pro Sound Effects' "Manacles Metal Clangs 4": its first clang (0.05 to 0.3 s), the
		-- handles knocking together as a hand closes on them
		pickUp = { id = "rbxassetid://9116460746", from = 0, length = 0.42, volume = 0.9 },
		-- Pro Sound Effects' "Crowbar Impact Dropping To Concrete 1": the hit and its bounces
		drop = { id = "rbxassetid://9114008989", from = 0, length = 1.4, volume = 0.8 },
		-- 3 padlocks (GDD). The jaw cracks a beat after the third padlock's snap, so the lock going
		-- and the cutters going are two sounds: "Scissors Snap 28" (the padlock cut's own snap,
		-- DoorSound) played lower still, a heavier bar giving way. Bits of its red handles and steel.
		wear = {
			uses = 3,
			late = 0.35,
			snap = {
				id = "rbxassetid://9118829487",
				from = 0,
				length = 0.3,
				volume = 2.5,
				pitch = 0.36,
			},
			bits = { { 176, 36, 32 }, { 132, 134, 138 }, { 54, 54, 58 } },
		},
	},
	-- Locks a door so a trapped keeper stays trapped; one per door (GDD). The doors' laminated
	-- padlock, open, twice their size so it reads on a phone (art/padlock).
	Padlock = {
		name = "Padlock",
		template = "Padlock",
		-- low on your left, its face to you and the open shackle towards the middle of the view
		hold = { -0.62, -0.62, -1.75 },
		holdTurn = { 160, 10, 8 },
		-- out in front of you towards the door, the open shackle leading
		use = { -0.12, -0.5, -1.9 },
		useTurn = { 180, -20, 0 },
		-- the body in the fist, the shackle forward out of it, face down
		inHand = { -90, 0, 0 },
		-- face on, a little from above, turned to show the shackle's swing
		icon = { 0.6, 12, 200, 0 },
		-- Pro Sound Effects' "Keys In Padlock 1": a hand closing on a padlock, its clink
		pickUp = { id = "rbxassetid://9116175991", from = 0, length = 0.5, volume = 0.8 },
		-- the cutters' concrete clank, played faster: a small, heavy lump of steel bouncing
		drop = {
			id = "rbxassetid://9114008989",
			from = 0,
			length = 1.4,
			volume = 0.65,
			pitch = 1.7,
		},
	},
	-- Cuts a crawl hole into the next unit; keepers can't fit through; loud (GDD). A cordless
	-- reciprocating saw, green so it's never mistaken for the torch or the cutters (art/saw).
	Saw = {
		name = "Saw",
		template = "Saw",
		-- low on your left by its rear handle, turned in so you see its side and the blade
		-- reaching towards the middle of the view
		hold = { -1.25, -1.1, -2.0 },
		holdTurn = { -26, 10, 16 },
		-- at the wall while you saw: further out and nearer the middle than its hold, still turned
		-- in so you see its side, the blade reaching into the wall ahead (straight ahead showed
		-- only its back end, L-12b2)
		use = { -0.7, -0.9, -1.85 },
		useTurn = { -18, 6, 10 },
		-- by its rear handle, upright, blade forward: carried at the ready by your side
		inHand = { 0, 0, 0 },
		-- side on, its sticker to the front, a little from above, the blade to the upper right
		icon = { 0.62, 15, -90, -25 },
		-- Pro Sound Effects' "Plastic Ice Chest 25": its first knocks, a hand closing on a hollow
		-- plastic body
		pickUp = { id = "rbxassetid://9117544893", from = 0, length = 0.42, volume = 0.8 },
		-- Pro Sound Effects' "Chair Drop 3": from its first hard hit (0.25 s), plastic slamming on
		-- the floor and a short rattle, a little higher than a chair
		drop = {
			id = "rbxassetid://9113768847",
			from = 0.22,
			length = 0.9,
			volume = 0.8,
			pitch = 1.12,
		},
		-- 2 holes (GDD). Its blade snaps a beat after the second hole's panel drops: the padlock
		-- cut's snap played higher, a thin blade going. Bits of its green body, black grip and blade.
		wear = {
			uses = 2,
			late = 0.3,
			snap = {
				id = "rbxassetid://9118829487",
				from = 0,
				length = 0.3,
				volume = 2.2,
				pitch = 0.72,
			},
			bits = { { 70, 142, 64 }, { 36, 36, 38 }, { 172, 174, 178 } },
		},
	},
	-- Lures keepers to a spot; wakes dormant things nearby (GDD). A marine air horn: a white steel
	-- can with a black band, an orange trumpet standing up out of its collar (art/airhorn).
	AirHorn = {
		name = "Air horn",
		template = "AirHorn",
		-- low on your left by the can, the trumpet standing up beside the hall and turned so the
		-- can's sound-wave mark faces you
		hold = { -1.2, -1.15, -2.2 },
		holdTurn = { 205, 4, 10 },
		-- blowing it (L-14a2): brought up and in towards the middle of your view, the trumpet tipped
		-- forward down the hall, the can's mark still to you
		use = { -0.78, -0.62, -2.0 },
		useTurn = { 200, 16, 4 },
		-- the can in the fist, the trumpet up, its mark out to your side
		inHand = { 0, 90, 0 },
		verb = "Blow",
		-- its mark to the front, a little from above to show the bell, the trumpet to the upper right
		icon = { 0.62, 12, 180, -30 },
		-- Pro Sound Effects' "Metal Hit Steel Plate Hit Slapped 2": its one slap (0 to 0.15 s),
		-- played a little faster, a hand closing on a steel can
		pickUp = {
			id = "rbxassetid://9116657808",
			from = 0,
			length = 0.3,
			volume = 0.7,
			pitch = 1.25,
		},
		-- Pro Sound Effects' "Metal Container 2": from just before its hard hit (0.40 s), an empty
		-- can landing on concrete and bouncing, played faster for a smaller can
		drop = {
			id = "rbxassetid://9116546109",
			from = 0.36,
			length = 0.9,
			volume = 0.75,
			pitch = 1.3,
		},
		-- 3 blasts (GDD). The last one sags and dies as the can runs dry (`HornView`); then you
		-- shake it, empty (Pro Sound Effects' "Spray Paint 3": a can shaken, its rattle from 0.1 s
		-- to 0.7 s, measured), and it's tossed away whole.
		wear = {
			uses = 3,
			late = 0.85,
			snap = {
				id = "rbxassetid://9119523840",
				from = 0.1,
				length = 0.6,
				volume = 1,
				pitch = 0.85,
			},
			bits = {},
		},
	},
	-- Laid across a hall, it pops when anything crosses, heard floor-wide; friends pop it too (GDD):
	-- an alarm you set behind you, as Minecraft's tripwire is set off by any mob or player. A roll
	-- of large-bubble wrap on a cardboard core, its loose end taped down (art/bubblewrap). Lay
	-- unrolls the whole roll into one sheet across the hall (`Wrap`, `Props.BubbleSheet`).
	BubbleWrap = {
		name = "Bubble wrap",
		template = "BubbleWrap",
		-- low on your left, its axis reaching ahead and in from the bottom corner of your view,
		-- the taped end turned up to you
		hold = { -1.3, -1.2, -2.6 },
		holdTurn = { 240, -8, 0 },
		-- laying it (L-14b2a): held out ahead and low, across your view, going down to the floor
		use = { -0.3, -1.5, -2.4 },
		useTurn = { 180, -10, 0 },
		-- by its middle, its axis along your forearm: carried like a rolled mat
		inHand = { 0, 90, 0 },
		verb = "Lay",
		-- an end's wound layers and core to the front, a little from above to show the tape, laid
		-- corner to corner
		icon = { 0.62, 20, -35, -25 },
		-- Pro Sound Effects' "Plastic Bubble Wrap Short Fluttering Movements 12": from its first
		-- crinkle (0.22 s), a hand closing on the wrap and the rustle after it
		pickUp = { id = "rbxassetid://9125745465", from = 0.2, length = 0.45, volume = 0.7 },
		-- "Plastic Bubble Wrap Short Fluttering Movements 11": from just before its sharp crackle
		-- (0.30 s), the roll landing and its wrap settling, a little lower for its weight
		drop = {
			id = "rbxassetid://9125745466",
			from = 0.27,
			length = 0.6,
			volume = 0.8,
			pitch = 0.92,
		},
	},
	-- Gets you onto open unit tops to run across them (GDD). An aluminium extension ladder, carried
	-- collapsed; leaned on a unit's front its fly runs out past the steel top (art/ladder, L-13b2).
	Ladder = {
		name = "Ladder",
		template = "Ladder",
		-- low on your left by its rail, on its edge and rolled so you see its rungs, its top end
		-- reaching ahead across the bottom of your view: a big thing in your arms
		hold = { -1.2, -1.25, -0.7 },
		holdTurn = { -14, 8, -58 },
		-- nothing to do at a door with it yet (L-13b2 leans it): the same as its hold
		use = { -1.2, -1.25, -0.7 },
		useTurn = { -14, 8, -58 },
		-- on its edge on your shoulder, the arm through it, its top leading: the rail below hangs
		-- at your side, the fly towards you
		inHand = { 0, 0, -90 },
		shoulder = { -1.6, 0.87, 0 },
		-- the fly's face, from above and a little along, laid corner to corner
		icon = { 0.42, 60, 0, -45 },
		-- Pro Sound Effects' "Metal Ladder Bang Slams Against Body 1": a bang at once and its
		-- rattle (to 0.85 s), the ladder heaved onto your shoulder
		pickUp = { id = "rbxassetid://9116717868", from = 0, length = 0.85, volume = 0.5 },
		-- Pro Sound Effects' "Metal Ladder Impact 1": from just before its hard hit on concrete
		-- (0.70 s), the hit and the rattling bounces after it
		drop = { id = "rbxassetid://9116719494", from = 0.62, length = 0.95, volume = 0.9 },
		bothHands = true,
		-- slow: three quarters of a walk, so the one carrying it is the one the team waits for
		walkSpeed = 12,
	},

	-- The finds (S1-05): the 1980s bedroom set (art/finds), each `Deal.Finds`' name. Each hangs
	-- from your left hand by where a hand would take it, drawn low on the left of your view with
	-- its front turned to you, so what you're carrying is never in doubt.

	-- A big black boombox, carried by its chrome handle.
	Boombox = {
		name = "Boombox",
		template = "Boombox",
		find = true,
		verb = "Play", -- loud music, monsters come to look (`Finds/OneMesh`)
		grade = "Uncommon",
		worth = 25,
		grip = { 0, 1.33, 0 }, -- the handle's bar, over the middle of the case
		heft = 0.6,
		-- hanging low on your left by the handle, its speakers turned to you and its length running
		-- away from you, so it reads without covering the hall (S1-05, seen in Play)
		hold = { -1.55, -0.8, -2.4 },
		holdTurn = { 232, 4, 0 },
		use = { -1.55, -0.8, -2.4 },
		useTurn = { 232, 4, 0 },
		-- the case hanging below your fist, its length along your walk, as a boombox is carried
		inHand = { 0, 90, 0 },
		-- its front, a little from above, a little turned
		icon = { 0.62, 12, 200, 0 },
		-- Pro Sound Effects' "Switch Portable Plastic Radio Tape Player 9": its clack at 0.2 s,
		-- the handle snapping up and the keys rattling in the case
		pickUp = { id = "rbxassetid://9119728830", from = 0.15, length = 0.35, volume = 0.9 },
		-- Pro Sound Effects' "Shield Impacts 15": a plastic case hitting the floor, crunchy
		drop = {
			id = "rbxassetid://9119075637",
			from = 0,
			length = 0.7,
			volume = 0.8,
			pitch = 0.92,
		},
	},
	-- A portable TV in a woodgrain cabinet, rabbit ears up, carried by the cabinet's top.
	Television = {
		name = "TV",
		template = "Television",
		find = true,
		grade = "Uncommon",
		worth = 22,
		grip = { 0, 1.24, 0 }, -- the cabinet's top, between the ears
		heft = 1,
		-- low on your left by its top, the screen turned to you, the ears up by your cheek: the
		-- biggest thing in your view, never more than its lower left corner (seen in Play)
		hold = { -1.6, -0.78, -2.6 },
		holdTurn = { 215, 4, 0 },
		use = { -1.6, -0.78, -2.6 },
		useTurn = { 215, 4, 0 },
		-- the cabinet hanging from your fist, the screen to the side
		inHand = { 0, 90, 0 },
		icon = { 0.62, 10, 200, 0 },
		-- the hollow plastic knocks of the saw's pick-up, played slow: a big heavy cabinet
		pickUp = {
			id = "rbxassetid://9117544893",
			from = 0,
			length = 0.55,
			volume = 1,
			pitch = 0.72,
		},
		-- Pro Sound Effects' "Shield Impacts 19": from just before its big crunching hit at
		-- 0.2 s, played lower, the heaviest thing you carry landing
		drop = {
			id = "rbxassetid://9119075967",
			from = 0.17,
			length = 0.9,
			volume = 0.85,
			pitch = 0.78,
		},
	},
	-- A mended teddy, one button eye, carried by its arm.
	Teddy = {
		name = "Teddy",
		template = "Teddy",
		find = true,
		verb = "Hug", -- a tiny squeak (`Finds/OneMesh`)
		grade = "Common",
		worth = 4,
		grip = { 0.4, 0.66, 0 }, -- one arm, at the shoulder
		heft = 0.12,
		-- by its arm low on your left, its face to you
		hold = { -1.2, -0.72, -2.0 },
		holdTurn = { 200, 0, -8 },
		use = { -1.2, -0.72, -2.0 },
		useTurn = { 200, 0, -8 },
		-- dangling from your fist by its arm, facing out ahead of you
		inHand = { 0, 0, 0 },
		icon = { 0.62, 8, 195, 0 },
		-- Pro Sound Effects' "Pillow Blanket 1": its grab on the cloth at 0.45 s
		pickUp = { id = "rbxassetid://9117373366", from = 0.4, length = 0.4, volume = 0.75 },
		-- the same grab, slower and softer: plush flopping on concrete
		drop = {
			id = "rbxassetid://9117373366",
			from = 0.4,
			length = 0.45,
			volume = 0.6,
			pitch = 0.7,
		},
	},
	-- A pair of white high-top roller skates, pink wheels, carried by the standing one's collar.
	Skates = {
		name = "Skates",
		template = "Skates",
		find = true,
		grade = "Uncommon",
		worth = 18,
		grip = { -0.1, 0.88, 0.42 }, -- the standing skate's collar
		heft = 0.4,
		-- low on your left, the wheels turned to you
		hold = { -1.4, -0.75, -2.1 },
		holdTurn = { 215, 6, 0 },
		use = { -1.4, -0.75, -2.1 },
		useTurn = { 215, 6, 0 },
		inHand = { 0, 90, 0 },
		icon = { 0.62, 14, 200, 0 },
		-- Pro Sound Effects' "Roller Skate 10": the wheels' first rattle at 0.35 s
		pickUp = { id = "rbxassetid://9118697756", from = 0.33, length = 0.35, volume = 0.8 },
		-- its wheel and ground impacts from 0.72 s: the skates clattering down, wheels spinning
		drop = { id = "rbxassetid://9118697756", from = 0.72, length = 0.45, volume = 0.8 },
	},
}

--[[
	The kit's finds (F-G1f, D-265): each find built with the kit has its game row in its art spec
	(art/finds/<set>/spec.py), generated into `Finds/Rows` (art/finds/PIPELINE.md says how). Each
	one ticked built in art/finds/WAVES.md (`judged`) gets a catalog row here. Each is the kit's
	jointed model (`Finds`, posed as it's found), so `template` is its name in
	ReplicatedStorage.Props.Finds. Its size says where it sits in your view, as the bedroom set
	was judged in Play: a palm-sized one near and low (a glow stick, the die-cast car), a medium
	one where the teddy hangs, a big one where the boombox does.
]]
local HOLD = {
	Small = { at = { -0.95, -0.62, -1.7 }, turn = { 200, 6, 0 } },
	Medium = { at = { -1.2, -0.72, -2.0 }, turn = { 200, 0, -8 } },
	Large = { at = { -1.55, -0.8, -2.4 }, turn = { 215, 4, 0 } },
}

-- A find the catalog says takes both hands (the mega goo ball, S3b), as Lethal Company's
-- two-handed scrap is carried: hugged to your chest. Your view: low and in the middle, nearer
-- than a big one in one hand, filling the bottom of the screen. Friends: at your chest, from your
-- upper torso's middle (right, up, back), its front ahead and its sides under your arms.
local BOTH = { at = { 0, -0.95, -2.05 }, turn = { 180, 8, 0 } }
local CHEST = { 0, -0.45, -1.0 }

-- A kit find's catalog row: it hangs from your left hand by its grip, low on the left of your
-- view with its front turned to you, as the bedroom set does. Its verb is its press's word
-- (`Finds/Use` plays the press: the lantern's Switch, the jack's Wind), or the RC car's Drive
-- (`Finds/Drive`).
for _, row in Rows do
	if not row.judged then
		continue
	end
	local both = row.bothHands == true
	local hold = if both then BOTH else HOLD[row.size]
	Catalog[row.key] = {
		verb = row.verb,
		name = row.name,
		template = row.key,
		find = true,
		grade = row.grade,
		worth = row.worth,
		from = row.from,
		loose = row.loose,
		fragile = row.fragile,
		grip = row.grip,
		heft = row.heft,
		hold = hold.at,
		holdTurn = hold.turn,
		use = hold.at,
		useTurn = hold.turn,
		inHand = if both then { 0, 0, 0 } else { 0, 90, 0 },
		shoulder = if both then CHEST else nil,
		bothHands = if both then true else nil,
		icon = { 0.62, 14, 200, 0 },
		pickUp = row.pickUp,
		drop = row.drop,
	}
end

return Catalog
