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
}

export type Row = {
	name: string, -- on screen: the prompt's object, the slot's label ("Bolt cutters")
	template: string, -- the template's name under ReplicatedStorage.Props.Tools
	-- your view: where your left hand holds it, from the camera (right, up, back, in studs), then
	-- its turn (degrees: yaw left, pitch up, roll), as `Torch.Hold` and `HoldTurn` are the torch's
	hold: { number },
	holdTurn: { number },
	-- a friend's hand: the grip's turn from their left hand's grip attachment, degrees about the
	-- hand's X, Y, Z (CFrame.Angles); none leaves the jaw along the hand's front (-Z)
	inHand: { number },
	-- the slot's picture: the camera's distance from the tool, as a share of its length; how far
	-- it's tipped to show its top (degrees about X), turned (about Y), then laid across the square
	-- (about the view's axis)
	icon: { number },
	pickUp: Sound, -- your hand closing on it: heard by you, and near you by friends
	drop: Sound, -- it landing on the concrete
}

local Catalog: { [string]: Row } = {
	-- Open padlocked units and free a friend from one (GDD). 18-inch cutters, red handles.
	BoltCutters = {
		name = "Bolt cutters",
		template = "BoltCutters",
		-- low on your left, jaw forward and a little in, so it's plain without covering the hall
		hold = { -0.72, -0.8, -1.3 },
		holdTurn = { -10, 14, -12 },
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
}

return Catalog
