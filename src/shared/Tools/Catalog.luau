--!strict
--[[
	The tools you carry in your two slots (L-11b, GDD "Tools"): one row each, as keepers are rows.
	A row says what the tool is called on screen, which template in the place it is, how it sits in
	your first-person view and in a friend's hand, and what it sounds like. The flashlight isn't
	here: everyone has one in hand, outside the slots (GDD; `Flashlight`).

	The keys are `Deal.Tool`'s names, so a unit dealt "BoltCutters" lays this row's tool. Pure data
	(Lune reads it in the specs); `Tools` (init) does the instances.
]]

export type Sound = {
	id: string,
	from: number, -- seconds into the recording where the sound starts
	length: number, -- seconds of it played
	volume: number,
	pitch: number?, -- its playback speed (1 when nil): above 1 a smaller, lighter thing
}

export type Row = {
	name: string, -- on screen: the prompt's object, the slot's label ("Bolt cutters")
	template: string, -- the template's name under ReplicatedStorage.Props.Tools
	-- your view: where your left hand holds it, from the camera (right, up, back, in studs), then
	-- its turn (degrees: yaw left, pitch up, roll), as `Torch.Hold` and `HoldTurn` are the torch's
	hold: { number },
	holdTurn: { number },
	-- your view while you hold its button at a door (Cut, Lock): brought down to the latch
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
	},
	-- Gets you onto open unit tops to run across them (GDD). An aluminium extension ladder, carried
	-- collapsed; leaned on a unit's front its fly runs out past the wire top (art/ladder, L-13b2).
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
}

return Catalog
