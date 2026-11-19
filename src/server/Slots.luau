--!strict
--[[
	Everyone's tool slots (L-11b, D-048; three since L-20a), as Lethal Company's: the server owns
	every tool, where it is and who carries it. A tool lies on a floor with a "Pick up" prompt until
	someone takes it; carried, it's in one of their slots (`Tools.Carry`), and the one in their hand
	is welded in their left hand for everyone to see (the torch has the right). They switch slots,
	pocket the tool on their slot or bring it back up (out of sight, still theirs), drop what's in
	their hand at their feet, or hand it to a friend within reach who has room. Dying or leaving
	drops everything where you stood.

	Every screen reads the slots from attributes on each Player (`ToolSlot1` to `ToolSlot3`: the
	catalog key or ""; `ToolHand`: the slot your hand is on; `ToolPocketed`: its tool put away).
	Four remotes in (a stand-in for Brix ENG-09), each checked for type, then range (a living
	character, reach, room), then rate (`Carry.allow`): ToolSwitch takes a slot, ToolPocket a
	boolean, ToolDrop nothing, ToolGive a Player. ToolNotice tells one screen a short line ("Bolt
	cutters from Sam").

	A big tool (the ladder) rides on your left shoulder for everyone to see, takes both hands (no
	switching slots or picking up while it's in your hand, as Lethal Company's two-handed items) and
	slows your walk (`Catalog` row's `shoulder`, `bothHands`, `walkSpeed`).

	`Doors` reads `carried` to know what's in your hand (the cutters to Cut, a padlock to Lock), and
	`spend`s the padlock that goes on a door: it leaves your slots for good.

	A tool whose row has a `verb` (the air horn's Blow) is used where you stand: ToolUse takes
	nothing, checked for a living character with such a tool in hand, then its own rate (so using
	never spends the hand's), and fires `used` for that tool's system (`Horns`) to decide the rest.

	A find (S1-05, GDD "Finds": a catalog row with `find`) is carried the same way: `Deals` lays it
	standing in its unit with a "Take" prompt, one tap puts it in a slot and in your hand, and it's
	dropped, handed over and dropped where you're caught as a tool is. A tool's or a find's own
	sound answers each take and drop. As the gate shuts with you aboard, your finds are kept for
	good (`keep`, S1-06): out of your slots, the one in your hand gone in a glint.

	Tools wear out (S1-08, GDD "Tools wear out", as Minecraft's do): each tool keeps its own uses
	left (`Wear`), so a dropped or handed-over one keeps its wear, and every screen reads them from
	`ToolUses1` to `ToolUses3`. The system that uses one (`Doors`' Cut, `Saws`, `Horns`) `wear`s it;
	the use that spends the last breaks it a beat later (its row's `wear.late`): out of your slots,
	it jolts out of your hand with its own snap and a burst of its bits, tumbles to the floor with
	its clank, lies there a moment and fades. Your screen is told (ToolBroke) to break it in your
	view; until it goes, your hand can't move and the tool can't be used.

	A find can have a piece out on a floor away from the rest (`out`, F-G1b3c3: the RC car set down
	while its transmitter stays in your hand). Monsters see that find where its piece is, never
	where the rest is: the Packrat goes for the car, and its hands closing on it bring the whole
	find together there (`Out.gather`) and into its arms, out of whoever's slots it was in; torn
	from your hands instead, its piece comes home into it first. It isn't kept at the gate while
	its piece is out: it's left behind with the floor, and goes from your hand when the piece goes
	with it (`lose`).

	A find out of its owner's job box (S5-03c2b2, D-293: `unbox`) is carried like any other, but
	it is still theirs in their save, so it's marked with whose box it came from. What's in the box
	is what you own less these (`fromBox`, Save.boxed), and when its owner leaves at home each goes
	back into the box in a glint. Taken up into the climb (S5-03d2, D-302: `up`, as its holder
	rides a lobby car into floor 1) it's at risk: carried aboard by its owner it stays in their
	slots; by a friend it's kept as theirs (`keep`'s moved); gone with a floor, the climb, used up
	or its owner leaving mid-climb, it's lost (`taken`), and then a friend may still carry it
	aboard as any find.

	Across the trip (S5-03d4, D-358): a live climb runs on a server of its own. As a lobby car's
	group is sent, each rider's finds out of a rider's job box are named for the trip's data and
	marked going (`going`); as the rider leaves they go from the lobby quietly, not back into the
	box (their crack goes with them), and if the trip fails for good they stay in hand (`stay`).
	On the group's server each one the owner's save backs is dealt straight into its holder's
	slots or onto their head, already up (`carryUp`).

	A fragile find (F-G1e5e, D-296: its row names its glass) let go hard (`Chip.hard`: you were
	running or falling, or it fell far from your hand) cracks as it lands, once: its crack heard
	over its clank and drawn on its glass for everyone (`Chip.mark`; the model's `Chipped`
	attribute for your view's copy), worth half from then, and `keep` names it so the save does.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Chip = require(ReplicatedStorage.Shared.Finds.Chip)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local HandPlace = require(ReplicatedStorage.Shared.Home.HandPlace)
local Pack = require(ReplicatedStorage.Shared.Finds.Pack)
local Seal = require(ReplicatedStorage.Shared.Finds.Seal)
local Head = require(ReplicatedStorage.Shared.Finds.Head)
local Headlamp = require(ReplicatedStorage.Shared.Finds.Headlamp)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Carry = Tools.Carry
local Catalog = Tools.Catalog
local Wear = Tools.Wear

local HAND_SOUND_REACH = 24 -- a hand closing on a tool, heard close by
local FALL = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- A sealed find whose pack tore as it landed (S5-02b2b2) drops the pack's height to the floor this
-- fast, turned up to `SPILL_TURN` degrees either way: spilled out of its pack, not set down.
local SPILL = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SPILL_TURN = 22
-- A find the Packrat sets on its pile (S2-06b2): eased from its hands to the floor, unhurried
local PUT_DOWN = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local DROP_AHEAD = 2.2 -- studs in front of your middle where a dropped tool lands
-- Running, it falls at your heels instead (S2-06c2): this far behind your middle, the way you
-- came, so you never run into your own drop and a find let go to buy off a Packrat on your tail
-- lands between you and it. Running is moving faster than RUNNING studs a second across the floor.
local DROP_BEHIND = 1.8
local RUNNING = 6
local REACH_SLACK = 2 -- studs the server allows past a prompt's reach (lag, a long arm)
-- Studs across the floor from a monster's chest a find's piece out (the RC car) may be as its
-- hands close: it reaches about 4 ahead (the Packrat's `grab`); driven farther, it slipped them.
local OUT_GRASP = 7
-- A kept find's glint as it goes from your hand, for everyone near: the coins' sparkle, warm gold.
local GLINT_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local GLINT_BURST = 0.18 -- seconds the glint throws sparks: a short burst, then gone
-- A tool breaking (S1-08): it jumps out of your hand (studs a second up, and ahead of you) with a
-- tumble (radians a second at most), its bits flying (how many, how big in studs, how fast), heard
-- as far as a cut padlock's snap; it lies on the floor for `BROKEN_LIES` seconds, then fades.
local BREAK_JUMP = 8
local BREAK_AHEAD = 4
local BREAK_SPIN = 14
local BITS = 10
local BIT_SIZE = { 0.1, 0.26 }
local BIT_SPEED = { 7, 15 }
local BREAK_REACH = 40
local BROKEN_LIES = 2.5
local BROKEN_FADE = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type Change = {
	player: Player,
	kind: "PickUp"
		| "Drop"
		| "Give"
		| "Switch"
		| "Pocket"
		| "Spend"
		| "Place"
		| "Keep"
		| "Break"
		| "Taken"
		| "Wear",
}

-- A press of ToolUse that passed: who, the tool's catalog key, and its model in their hand.
export type Use = { player: Player, key: string, model: Model }
-- A find taken up out of a job box ending somewhere other than a gate (S5-03d2, D-302, D-304):
-- "Lost" as it goes for good on the climb (left with a floor, the climb over, used up, its owner
-- gone), "Back" as it goes back into its owner's box at home. The save is settled from it.
export type Taken = {
	home: number, -- the UserId whose box it came out of
	name: string, -- its name in the save (a Gold's "Teddy:Gold")
	how: "Lost" | "Back",
	cracked: boolean, -- its glass cracked while it was out (D-296)
	torn: boolean, -- out of its box sealed, its pack torn while it was out (D-427)
}
-- A friend's find taken up, carried aboard by someone else as a gate shut (`keep`): theirs now.
export type Moved = { home: number, name: string, cracked: boolean, torn: boolean }
-- A dropped tool hitting the floor: its clank, heard `reach` studs off (Carry.DropHeard).
export type Landed = { key: string, at: Vector3, reach: number }
-- A find's piece out on a floor away from the rest (the RC car set down, F-G1b3c3), as the
-- system that set it there (`Drives`) answers for it.
export type Out = {
	-- the floor point under the piece now, or nil while no monster could take it from anywhere
	at: () -> Vector3?,
	-- the piece back in its find. `there`: the rest brought to where the piece stands (a monster's
	-- hands closed on the piece; the find already out of any hand and off any floor, its body
	-- anchored), else the piece brought to the rest (a monster tearing the rest from your hands)
	gather: (there: boolean) -> (),
}

-- A find taken up out of a job box going with the trip (Home.Taken's `Up`, spelled out here as a
-- cross-folder require's types don't reach every caller's checker).
export type Up = { owner: number, name: string, holder: number, cracked: boolean, worn: boolean }

export type Slots = Brix.System & {
	-- Fires as anyone's slots change, for whoever cares.
	changed: Brix.Signal<Change>,
	-- Fires as a dropped tool lands with its clank, wherever it fell: keepers hear it (L-15).
	landed: Brix.Signal<Landed>,
	-- Fires as someone uses the tool in their hand (its row's `verb`), checked and rate-limited.
	used: Brix.Signal<Use>,
	-- Fires as the finds lying loose change (S2-06b2): one laid, dropped, picked up, cleared,
	-- lifted by a monster or laid on its pile. The Packrat is told (`Keepers`).
	loose: Brix.Signal<nil>,
	-- Fires as a find taken up out of a job box is lost on the climb or back in its owner's box
	-- (`Taken`; a gate's ends come from `keep`). Fired as its owner leaves too, in that frame.
	taken: Brix.Signal<Taken>,
	-- Every find out of a job box in `player`'s slots or on their head goes up into the climb
	-- (they rode a lobby car into it, S5-03d2): from now on it can be lost (`taken`).
	up: (self: any, player: Player) -> (),
	-- A lobby car's group is being sent on a trip (S5-03d4): each find out of a rider's job box in
	-- a rider's slots or on their head is named for the trip's data and marked going, so it leaves
	-- the lobby quietly with its holder instead of going back into the box.
	going: (self: any, players: { Player }) -> { Up },
	-- `player`'s trip failed for good: what they hold stays in hand, not going any more; one whose
	-- owner already left goes back into that box.
	stay: (self: any, player: Player) -> (),
	-- On a group's own server: find `u` carried across the trip, dealt into `holder`'s slots (onto
	-- their head when it rode there and the head is free), out of `u.owner`'s box, already up,
	-- cracked as it left. `quiet`: no pick-up sound (their screen is still black). Whether it was.
	carryUp: (self: any, holder: Player, u: Up, quiet: boolean) -> boolean,
	-- Find `model` has a piece out on a floor (`out`), or not any more (nil). Monsters see the find
	-- where the piece is (`finds`). Call it again with the same `out` when the piece has moved, so
	-- they're told.
	out: (self: any, model: Model, out: Out?) -> (),
	-- Find `model` goes for good wherever it is (a hand, a pocket, a floor), its piece gone with the
	-- floor it was left on: `sound` from where it was, and from a hand it breaks away in its
	-- carrier's view (ToolBroke). Never kept.
	lose: (self: any, model: Model, sound: Tools.SoundSpec) -> (),
	-- Calls `each` with every find lying loose on a floor: its number, the floor point under its
	-- middle (the world's) and its model (a found light's stamp, F-G1b3b). A find with a piece out
	-- (`out`) is there, at the piece, wherever the rest is. Allocates nothing.
	finds: (self: any, each: (n: number, at: Vector3, model: Model) -> ()) -> (),
	-- A monster's hands close on find `n` lying loose (the Packrat's take, S2-06b2): its prompt
	-- goes and it's welded to `part`, its middle where it lay, in `holder` (the monster's body).
	-- One with a piece out is gathered where the piece is first, out of whoever's slots it was in
	-- (their screen told, as `snatch`'s). The weld, or nil if it no longer lies loose.
	lift: (self: any, n: number, part: BasePart, holder: Instance) -> Weld?,
	-- Lays lifted find `n` on the floor at `at`, turned `yaw` degrees, quietly (the Packrat's
	-- pile): "Take" again, as any find. It eases there from `from` (its middle in the world, where
	-- screens show it in the hands, S2-06b2b), or from where the server holds it.
	putDown: (self: any, n: number, at: Vector3, yaw: number, from: CFrame?) -> (),
	-- Lays a new tool of catalog key `key` on the floor at `at` (a floor point), turned `yaw`
	-- degrees. Returns its id, or nil if the place has no template. `sealed`: a find still in its
	-- packaging (S5-02b2b1), standing in its pack.
	lay: (self: any, key: string, at: Vector3, yaw: number, sealed: boolean?) -> string?,
	-- Takes away every tool lying on a floor where `inside` says (a floor being cleared, L-08b);
	-- carried and placed ones stay. Returns how many went.
	clear: (self: any, inside: (at: Vector3) -> boolean) -> number,
	-- The catalog keys `player` carries, slot by slot ("" for empty), and the slot in hand (0 while
	-- its tool is pocketed).
	carried: (self: any, player: Player) -> ({ string }, number),
	-- Uses up what's in `player`'s hand if it's catalog key `key` (a padlock hung on a door): out
	-- of their slots and gone. Whether it was.
	spend: (self: any, player: Player, key: string) -> boolean,
	-- Spends one use of what's in `player`'s hand if it's catalog key `key` and wears out (S1-08:
	-- a padlock cut, a hole sawn, a blast). The use that spends its last breaks it a beat later
	-- (its row's `wear.late`). The uses left (0: it's breaking), or nil if their hand had no such
	-- tool or it never wears out.
	wear: (self: any, player: Player, key: string) -> number?,
	-- Takes what's in `player`'s hand out of their slots if it's catalog key `key`, to stand in the
	-- world (the ladder leaned on a front): Slots keeps it, carried by nobody and lying nowhere, its
	-- body anchored where it was, for the caller to place. Its id and model, or nil.
	place: (self: any, player: Player, key: string) -> (string?, Model?),
	-- The name (`named`: a Gold's "Teddy:Gold") of the find in `player`'s hand when it's out of
	-- their own job box, never taken up the climb and not in its pack (S5-03j5a, D-463): one they
	-- may set down in their home by hand. Nil otherwise.
	heldFromBox: (self: any, player: Player) -> string?,
	-- Takes that find (`heldFromBox`) out of `player`'s hand and back into their box, quietly, for
	-- Arranging to set it out in the same step (Place by hand). Whether there was one.
	setDown: (self: any, player: Player) -> boolean,
	-- Puts placed tool `id` back in `player`'s hand, as a pick-up (their hands must be free of a
	-- big tool and have room). Nil if it did, else the refusal to show ("" to refuse silently).
	handBack: (self: any, player: Player, id: string) -> string?,
	-- A new tool of catalog key `key` straight into a free slot of `player`'s and their hand (bought
	-- at the car's machine, S1-10c2), with its pick-up sound. False, and nothing made, if they have
	-- no room, a big tool in their hands, no living character, or the place lacks its art.
	-- `since`: when the player reached for it (a box opened, its find landing as the reveal
	-- ends): a switch or a put-away since then keeps their hand where they put it (F-G1e6q2).
	-- `sealed`: a find still in its packaging (S5-02b2b1), in its pack in their hand.
	give: (
		self: any,
		player: Player,
		key: string,
		quiet: boolean?,
		since: number?,
		sealed: boolean?
	) -> boolean,
	-- A find `key` out of `player`'s job box (S5-03c2b2, D-293; a Gold's gilded) into a free slot,
	-- as `give` with `quiet` (their screen plays the pick-up as the picture lands), marked as
	-- from their box. The slot it went into, or nil when it can't (as `give`).
	-- `kept`: where it stood when Taken (S5-03j5b1), its kept spot while it's in their hand.
	unbox: (self: any, player: Player, key: string, kept: HandPlace.Pose?) -> number?,
	-- Whether any find in `player`'s hands keeps a spot (S5-03j5b1).
	keeps: (self: any, player: Player) -> boolean,
	-- Forgets every kept spot of `player`'s finds (they stepped out of their home, S5-03j5b1).
	forget: (self: any, player: Player) -> (),
	-- Whether a find could go into `player`'s hands now, as `unbox` asks (S5-03i2a): a living
	-- character, no big tool held in both hands, and a free slot.
	room: (self: any, player: Player) -> boolean,
	-- How many of each find out of `player`'s job box are in the world now (in anyone's hands,
	-- on a head, lying or set down), by name: Save.boxed takes them off what's in the box.
	fromBox: (self: any, player: Player) -> { [string]: number },
	-- A find `name` out of `player`'s job box straight onto their head (S5-03f2b, D-316: worn off
	-- their clothes rail; a Gold's gilded), marked as from their box as `unbox` does. Its model,
	-- or nil when it isn't worn, their head isn't free, or they have no living character.
	boxToHead: (self: any, player: Player, name: string) -> Model?,
	-- The find on `player`'s head, by its save's name, and whether it came out of their own box.
	onHead: (self: any, player: Player) -> (string?, boolean),
	-- Hangs `player`'s worn find `name` back up (D-316): out of their own box, it goes off their
	-- head and back into the box, out of the world. Where it was on their head, or nil if they
	-- don't wear one of `name` from their box.
	hangUp: (self: any, player: Player, name: string) -> Vector3?,
	-- Lays placed tool `id` on the floor at `at`, turned `yaw` degrees (its front gone from under it).
	-- `still`: stood there at once, no fall and no clank (the toy car let go to roll: every screen
	-- plays its roll there from where it was set down).
	lower: (self: any, id: string, at: Vector3, yaw: number, still: boolean?) -> (),
	-- Drops everything `player` carries where they stand, as dying does (caught by a keeper, L-07a).
	dropAll: (self: any, player: Player) -> (),
	-- Wear (F-G1b4a1, D-277): the find `key` in `player`'s hand goes onto their head
	-- (`Head.fit`): out of its slot, welded to their head, still theirs (dropped where they're
	-- caught, kept at the gate). Its model, or nil if it isn't in their hand or isn't worn.
	toHead: (self: any, player: Player, key: string) -> Model?,
	-- Each living player's find on their head, and its model (for keepers: a lit hat holds a
	-- Mannequin from where the head is).
	worn: (self: any, each: (player: Player, model: Model) -> ()) -> (),
	-- The find on `player`'s head spent (the hard hat's minute out, F-G1b4b): it slips off and
	-- cracks apart on the floor, lost (D-141's break). True if they wore one.
	breakWorn: (self: any, player: Player) -> boolean,
	-- Each find's model `player` has on them now, in their slots (held or pocketed) or on their head
	-- (S5-03f3: the lights they ride up with get their minute).
	onThem: (self: any, player: Player, each: (model: Model) -> ()) -> (),
	-- Takes every find out of `player`'s slots for good (the gate shut with them aboard, S1-06):
	-- each goes from their hand with a glint everyone near sees, and their tools stay. The kept
	-- finds' catalog keys, slot order, and the keys of those with cracked glass (F-G1e5e). A
	-- find taken up out of their own job box stays in their slots, at risk on the next floor; one
	-- out of a friend's goes like the rest but comes back apart (`Moved`, S5-03d2): theirs now.
	keep: (self: any, player: Player) -> ({ string }, { string }, { Moved }),
	-- Takes the find `model` up off the floor where it lies loose, kept for a rider as a gate
	-- shuts (the big find set down in the car, S4-05b4): a glint where it lay, and it's gone. Its
	-- kept name and whether its glass is cracked, as `keep`'s; nil if it isn't lying loose, or
	-- came out of a job box (those go by `keep` alone).
	takeUp: (self: any, model: Model) -> (string?, boolean),
	-- What the Packrat would take from `player` if it reached them now (S2-06c, `Carry.prize`):
	-- that thing's number, or 0 for nothing it takes. Allocates nothing.
	prize: (self: any, player: Player) -> number,
	-- The Packrat's hands close on thing `n` in `player`'s slots (S2-06c): out of their slots and
	-- hand, welded to `part` in `holder` (the monster's body) as `lift` welds a find, and their
	-- screen told (ToolSnatched). The weld and where the thing was (in their hand as everyone saw
	-- it, else their middle), or nil if they no longer carry it.
	snatch: (
		self: any,
		player: Player,
		n: number,
		part: BasePart,
		holder: Instance
	) -> (Weld?, CFrame?),
}

-- A worn find falling off a head as it breaks (`shatter`): where it starts, its hop (studs a
-- second up and ahead), and its crack and bits as it hits the floor.
type Fall = {
	from: CFrame,
	up: number,
	ahead: number,
	snap: Tools.SoundSpec,
	bits: { { number } },
}

type Tool = {
	id: string,
	n: number, -- its number, as a keeper's brain knows a find (`Keeper.Finds`, S2-06b2)
	key: string,
	model: Model,
	body: BasePart,
	prompt: ProximityPrompt?,
	refuse: ((string, Player) -> ())?,
	owner: Player?,
	weld: Weld?,
	placed: boolean?, -- standing in the world (`place`), not in a hand or on a floor
	uses: number?, -- uses left before it breaks (S1-08); nil: it never wears out
	-- the UserId whose job box it came out of (S5-03c2b2, D-293): still theirs in their save, so
	-- no gate ever keeps it for anyone; nil for a find from a floor
	home: number?,
	-- taken up into the climb (`up`, S5-03d2): from then a find out of a job box can be lost
	up: boolean?,
	-- going on a trip with its holder (S5-03d4): it leaves the lobby with them, never recalled
	away: boolean?,
	-- its glass cracked (a fragile find dropped hard, F-G1e5e): worth half, never cracks again
	chipped: boolean?,
	-- a Gold of its find (S5-03c3b3, D-298): `key` stays the find's, so its row, model and sounds
	-- are the find's; its model is gilded for everyone, its slot says so (Gold.slotAttribute),
	-- and it's counted and kept by its Gold's name (`named`). Solid gold: it never cracks.
	gold: boolean?,
	-- still in its packaging (S5-02b, D-424): its model wrapped in its pack for everyone
	-- (`Finds/Pack`), its slot marked (`Seal.slotAttribute`); it takes no press and never cracks
	sealed: boolean?,
	-- out of a job box sealed, its pack torn on the climb (D-427): still its owner's sealed one by
	-- name till it's settled (`named`), then a plain one (`Taken`'s `torn`)
	torn: boolean?,
	-- where it stood in its owner's home when they Took it (S5-03j5b1, D-465): its kept spot, shown
	-- faintly while it's in their hand; gone once it's dropped, given, set down or put away, or
	-- they step out of their home (`forget`)
	kept: HandPlace.Pose?,
}

-- The name `t` goes by in a save: "Teddy", its Gold's "Teddy:Gold", or its sealed one's
-- "Teddy:Sealed" (D-427; one out of a job box torn on the climb too, till it's settled).
local function named(t: Tool): string
	if t.gold then
		return Gold.key(t.key)
	end
	return if t.sealed or t.torn then Seal.key(t.key) else t.key
end

-- Whether `t` is a find out of UserId `home`'s own job box that they may set down at home by
-- hand (S5-03j5a): never taken up the climb, not going on a trip, not in its pack.
local function ownBox(t: Tool, home: number): boolean
	return t.home == home and not (t.up or t.away or t.sealed or t.torn)
end

type Hand = {
	carry: Tools.CarryState,
	last: number?,
	burst: number,
	usedLast: number?, -- ToolUse's own rate, as `last` and `burst` are the hand's
	usedBurst: number,
	moved: number, -- when the player last switched or put away (`now()`), -inf before
}

-- The tool's pivot for lying flat on a floor with its middle at `at`, turned `yaw` degrees: its
-- lowest point on the floor. By its middle, not its grip, so a long tool dropped by a wall lies
-- along it rather than through it.
local function resting(key: string, at: Vector3, yaw: number, sealed: boolean?): CFrame
	local body = Tools.bounds(key)
	local lift = body.Size.Y / 2 - body.Centre.Y
	if sealed then
		lift += Pack.lift(Catalog[key].size, body) -- standing in its pack, its bottom on the floor
	end
	return CFrame.new(at + Vector3.new(0, lift, 0))
		* CFrame.Angles(0, math.rad(yaw), 0)
		* CFrame.new(-body.Centre.X, 0, -body.Centre.Z)
end

-- The left hand and where its grip is (the attachment's place only: rigs turn it differently).
local function handOf(character: Model): (BasePart?, CFrame)
	local hand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	if not (hand and hand:IsA("BasePart")) then
		return nil, CFrame.identity
	end
	local grip = hand:FindFirstChild("LeftGripAttachment")
	local at = if grip and grip:IsA("Attachment")
		then grip.Position
		else Vector3.new(0, -hand.Size.Y / 2, 0)
	return hand, CFrame.new(at)
end

-- Studs from a worn find's pivot (its grip, the hat's crown) down to the lowest edge of its rim
-- part (`Head.Fit.rim`), at its own size: what `Head.seat` sits it by. Its parts' boxes, in its
-- pivot's frame; 0 (sat by its pivot) if it has no such part.
local function rimDepth(model: Model, fit: Head.Fit): number
	local part = model:FindFirstChild(fit.rim, true)
	if not (part and part:IsA("BasePart")) then
		return 0
	end
	local pivot = model:GetPivot()
	local half = part.Size / 2
	local low = math.huge
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				local corner = part.CFrame:PointToWorldSpace(half * Vector3.new(x, y, z))
				low = math.min(low, pivot:PointToObjectSpace(corner).Y)
			end
		end
	end
	return -low / model:GetScale()
end

-- The head, the size a worn find grows to on it, and where its pivot sits (`Head.seat`): over
-- the head's hat point (the top of the head) so its rim lands over the brow, tipped by the fit.
local function headOf(character: Model, model: Model, fit: Head.Fit): (BasePart?, number, CFrame)
	local head = character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return nil, 1, CFrame.identity
	end
	local hat = head:FindFirstChild("HatAttachment")
	local top = if hat and hat:IsA("Attachment")
		then hat.Position
		else Vector3.new(0, head.Size.Y / 2, 0)
	local scale, up, ahead = Head.seat(fit, head.Size.Y, rimDepth(model, fit))
	return head,
		scale,
		CFrame.new(top + Vector3.new(0, up, -ahead)) * CFrame.Angles(math.rad(-fit.tip), 0, 0)
end
local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and humanoid and humanoid.Health > 0) then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function now(): number
	return os.clock()
end

-- A burst of gold sparks at `at`, gone in a second: a kept find leaving a hand. An emitter switched
-- on and off rather than `Emit`, so every screen sees it.
local function glint(at: Vector3)
	local spot = Instance.new("Attachment")
	spot.Name = "KeptGlint"
	spot.WorldPosition = at
	local p = Instance.new("ParticleEmitter")
	p.Texture = GLINT_TEXTURE
	p.Rate = 70
	p.Lifetime = NumberRange.new(0.35, 0.6)
	p.Speed = NumberRange.new(2, 5)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Drag = 4
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.4, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Rotation = NumberRange.new(0, 90)
	p.RotSpeed = NumberRange.new(-120, 120)
	p.Color = ColorSequence.new(Color3.fromRGB(255, 226, 150))
	p.LightEmission = 1
	p.LightInfluence = 0.3
	p.Brightness = 2.5
	p.Parent = spot
	spot.Parent = Workspace.Terrain
	task.delay(GLINT_BURST, function()
		p.Enabled = false
	end)
	task.delay(1.2, function()
		spot:Destroy()
	end)
end

local Slots = {}

function Slots.new(): Slots
	local tools: { [string]: Tool } = {}
	local hands: { [Player]: Hand } = {}
	local connections: { RBXScriptConnection } = {}
	local remotes: { Instance } = {}
	local changed = Brix.Signal.new() :: Brix.Signal<Change>
	local used = Brix.Signal.new() :: Brix.Signal<Use>
	local landed = Brix.Signal.new() :: Brix.Signal<Landed>
	local loose = Brix.Signal.new() :: Brix.Signal<nil>
	local taken = Brix.Signal.new() :: Brix.Signal<Taken>
	local lying: Folder? = nil
	-- where each lying tool's middle stands on the floor (its id's), for `finds`
	local grounds: { [string]: Vector3 } = {}
	-- each find with a piece out on a floor (`out`), by its model
	local outs: { [Model]: Out } = {}
	-- the find each player wears on their head (`toHead`, F-G1b4a1), its id
	local heads: { [Player]: string } = {}
	local notice: RemoteEvent? = nil
	local broke: RemoteEvent? = nil
	local snatched: RemoteEvent? = nil
	-- scratch for `prize`: a player's slots' catalog keys
	local prizeKeys: { string } = { "", "", "" }
	local nextId = 0

	local function handOfPlayer(player: Player): Hand
		local h = hands[player]
		if not h then
			h = {
				carry = Carry.new(),
				last = nil,
				burst = Carry.Burst,
				usedBurst = Carry.Burst,
				moved = -math.huge,
			}
			hands[player] = h
		end
		return h
	end

	local function tell(player: Player, text: string)
		if notice then
			notice:FireClient(player, text)
		end
	end

	-- The row of the tool in `h`'s hand if it takes both hands (the ladder), else nil.
	local function bothHands(h: Hand): Tools.Row?
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		return if row and row.bothHands then row else nil
	end

	-- `player`'s walk for what's in their hand: a big tool's pace, else the place's own.
	local function pace(player: Player, h: Hand)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		local speed = if row and row.walkSpeed
			then row.walkSpeed
			else StarterPlayer.CharacterWalkSpeed
		if humanoid.WalkSpeed ~= speed then
			humanoid.WalkSpeed = speed
		end
	end

	-- Writes `player`'s slots to their attributes, for every screen, and sets their walk to match.
	local function publish(player: Player)
		local h = handOfPlayer(player)
		pace(player, h)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			local key = if t then t.key else ""
			-- a Gold's mark goes on before its key and off after it, so no screen ever reads a
			-- Gold's key unmarked and draws it plain for a moment
			local gold = if t and t.gold then true else nil
			local goldChanged = player:GetAttribute(Gold.slotAttribute(i)) ~= gold
			if goldChanged and gold then
				player:SetAttribute(Gold.slotAttribute(i), gold)
			end
			-- a sealed find's mark the same way (S5-02b2b1): never drawn out of its pack a moment
			local sealed = if t and t.sealed then true else nil
			local sealChanged = player:GetAttribute(Seal.slotAttribute(i)) ~= sealed
			if sealChanged and sealed then
				player:SetAttribute(Seal.slotAttribute(i), sealed)
			end
			if player:GetAttribute(Tools.slotAttribute(i)) ~= key then
				player:SetAttribute(Tools.slotAttribute(i), key)
			end
			if goldChanged and not gold then
				player:SetAttribute(Gold.slotAttribute(i), nil)
			end
			if sealChanged and not sealed then
				player:SetAttribute(Seal.slotAttribute(i), nil)
			end
			-- out of their own box, never up the climb, not in its pack: theirs to set down by hand
			local own = if t and ownBox(t, player.UserId) then true else nil
			if player:GetAttribute(HandPlace.slotAttribute(i)) ~= own then
				player:SetAttribute(HandPlace.slotAttribute(i), own)
			end
			-- where it stood when Taken, while it's still theirs to set down by hand (S5-03j5b1)
			local kept = if own and t and t.kept then HandPlace.encode(t.kept) else nil
			if player:GetAttribute(HandPlace.keptAttribute(i)) ~= kept then
				player:SetAttribute(HandPlace.keptAttribute(i), kept)
			end
			local uses = if t and t.uses then t.uses else 0
			if player:GetAttribute(Wear.slotAttribute(i)) ~= uses then
				player:SetAttribute(Wear.slotAttribute(i), uses)
			end
		end
		if player:GetAttribute(Tools.HandAttribute) ~= h.carry.active then
			player:SetAttribute(Tools.HandAttribute, h.carry.active)
		end
		if player:GetAttribute(Tools.PocketedAttribute) ~= h.carry.pocketed then
			player:SetAttribute(Tools.PocketedAttribute, h.carry.pocketed)
		end
		local worn = heads[player]
		local onHead = if worn and tools[worn] then tools[worn].key else ""
		if player:GetAttribute(Head.Attribute) ~= onHead then
			player:SetAttribute(Head.Attribute, onHead)
		end
	end

	-- Takes a tool out of any hand: unwelded, out of the world.
	local function stow(t: Tool)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.body.Anchored = true
		t.model.Parent = nil
	end

	-- Puts what `player` has in hand into their left hand, and stows the rest.
	local function dress(player: Player)
		local h = handOfPlayer(player)
		local held = Carry.held(h.carry)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			if t and id ~= held then
				stow(t)
			end
		end
		local t = if held then tools[held] else nil
		if not t then
			return
		end
		local character = player.Character
		if not character then
			stow(t)
			return
		end
		local row = Catalog[t.key]
		local hand, grip = handOf(character)
		-- a big tool rides on the shoulder: welded to the torso, it doesn't swing with your arm
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		local shoulder = row.shoulder
		if shoulder and torso and torso:IsA("BasePart") then
			hand, grip = torso, CFrame.new(shoulder[1], shoulder[2], shoulder[3])
		end
		if not hand then
			stow(t)
			return
		end
		if t.weld and t.weld.Part0 == hand then
			return
		end
		if t.weld then
			t.weld:Destroy()
		end
		local turn = row.inHand
		local inHand = grip * CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
		t.model.Name = Tools.HeldName
		t.model:PivotTo(hand.CFrame * inHand)
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = t.body
		weld.C0 = inHand
		weld.C1 = t.body.PivotOffset
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Parent = character
	end

	-- Puts the find `player` wears onto their character's head (`Head.fit`), grown to fit a
	-- Roblox head and its cord and battery hidden; stowed while they have no character.
	local function wearOn(player: Player)
		local id = heads[player]
		local t = if id then tools[id] else nil
		local fit = if t then Head.fit(t.key) else nil
		if not (t and fit) then
			return
		end
		local character = player.Character
		if not character then
			stow(t)
			return
		end
		local head, scale, on = headOf(character, t.model, fit)
		if not head then
			stow(t)
			return
		end
		if t.weld and t.weld.Part0 == head then
			return
		end
		if t.weld then
			t.weld:Destroy()
		end
		if t.model:GetScale() ~= scale then
			t.model:ScaleTo(scale)
		end
		for _, name in fit.hide do
			local part = t.model:FindFirstChild(name, true)
			if part and part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
		t.model.Name = Head.ModelName
		t.model:SetAttribute(Head.WornAttribute, player.UserId)
		t.model:PivotTo(head.CFrame * on)
		local weld = Instance.new("Weld")
		weld.Name = Head.WeldName
		weld.Part0 = head
		weld.Part1 = t.body
		weld.C0 = on
		weld.C1 = t.body.PivotOffset
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Parent = character
	end

	-- Takes `player`'s worn find off their head, back to its own size and look, out of the
	-- world: the tool, or nil if they wear nothing. Its caller says where it goes next.
	local function offHead(player: Player): Tool?
		local id = heads[player]
		heads[player] = nil
		local t = if id then tools[id] else nil
		if not t then
			return nil
		end
		stow(t)
		local fit = Head.fit(t.key)
		if fit then
			if t.model:GetScale() ~= 1 then
				t.model:ScaleTo(1)
			end
			for _, name in fit.hide do
				local part = t.model:FindFirstChild(name, true)
				if part and part:IsA("BasePart") then
					part.Transparency = 0
				end
			end
		end
		t.model:SetAttribute(Head.WornAttribute, nil)
		t.model.Name = t.key
		return t
	end

	local pickUp: (Tool, Player) -> ()

	-- A prompt on a lying tool: "Pick up" and its name.
	local function offer(t: Tool)
		local row = Catalog[t.key]
		local at = Instance.new("Attachment")
		at.Name = "Prompt"
		at.Position = Vector3.new(0, 0.3, 0) -- just above its middle
		at.Parent = t.body
		local p = Prompts.make(at, {
			objectText = row.name,
			actionText = if row.find then "Take" else "Pick up",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Carry.PickReach,
		})
		p.RequiresLineOfSight = false -- a tool on the floor is low: boxes mustn't hide its prompt
		if row.find then
			-- a find stands taller than a tool lies: the prompt by its top, where your eye is drawn
			at.Position = Vector3.new(0, t.body.Size.Y * 0.3, 0)
		end
		t.prompt = p
		t.refuse = Prompts.refuser(p)
		p.Triggered:Connect(function(player: Player)
			pickUp(t, player)
		end)
	end

	local function unoffer(t: Tool)
		if t.prompt then
			local at = t.prompt.Parent
			t.prompt:Destroy()
			if at and at:IsA("Attachment") then
				at:Destroy()
			end
		end
		t.prompt = nil
		t.refuse = nil
	end

	-- Lays `t` on the floor at `pose`; falls there from `from` if given, clanking as it lands.
	-- A fragile find's glass cracks where it landed (F-G1e5e): heard over its clank, drawn on
	-- every screen, worth half from now on. Once.
	local function crack(t: Tool)
		local glass = Catalog[t.key].fragile
		if t.chipped or t.gold or not glass then
			return
		end
		t.chipped = true
		Chip.mark(t.model, glass)
		t.model:SetAttribute(Chip.Attribute, true)
		Tools.play(Chip.Sound, t.body, Chip.Heard)
	end

	-- Whether `t`, let go by someone moving `speed` studs a second, falling `fall` studs from
	-- their hand to the floor, cracks as it lands (`Chip.cracks`).
	local function cracks(t: Tool, speed: number, fall: number): boolean
		-- sealed, its pack takes the fall instead (`Seal.tears`, S5-02b2b2): the glass never cracks
		local whole = t.chipped == true or t.gold == true or t.sealed == true
		return Chip.cracks(Catalog[t.key].fragile, whole, speed, fall)
	end

	-- A sealed find let go hard (S5-02b2b2): its pack tears off as it lands, with a rip, its board,
	-- film and a few scraps thrown clear (`Pack.tear`), and the bare find drops the pack's height
	-- to the floor where it lay, turned a little askew as if spilled out, and lands with its own
	-- clank: a plain find from now on, worth its plain price. Lying at `pose` in its pack.
	local function rip(t: Tool, pose: CFrame)
		local box = Tools.bounds(t.key)
		local drop = Pack.lift(Catalog[t.key].size, box)
		t.sealed = nil
		t.torn = if t.home then true else nil -- its owner's save still has it sealed (D-427)
		Pack.tear(t.model)
		Tools.play(Pack.Rip, t.body, Carry.DropHeard)
		local middle = (pose * CFrame.new(box.Centre)).Position
		local bare = CFrame.new(0, -drop, 0)
			* CFrame.new(middle)
			* CFrame.Angles(0, math.rad(math.random(-SPILL_TURN, SPILL_TURN)), 0)
			* CFrame.new(-middle)
			* pose
		grounds[t.id] = (bare * CFrame.new(
			box.Centre.X,
			box.Centre.Y - box.Size.Y / 2,
			box.Centre.Z
		)).Position
		local tween =
			TweenService:Create(t.body, SPILL, { CFrame = bare * t.body.PivotOffset:Inverse() })
		tween.Completed:Once(function()
			if t.owner == nil and t.model.Parent == lying then
				Tools.play(Catalog[t.key].drop, t.body, Carry.DropHeard)
			end
		end)
		tween:Play()
	end

	-- `hard`: it was let go hard enough to crack its glass as it lands (`cracks`). `tear`: hard
	-- enough to tear a sealed find's pack off (`Seal.tears`, `rip`); never both.
	local function layDown(t: Tool, pose: CFrame, from: CFrame?, hard: boolean?, tear: boolean?)
		t.owner = nil
		stow(t)
		t.model.Name = t.key
		t.model:PivotTo(from or pose)
		t.model.Parent = lying
		local box = Tools.bounds(t.key)
		grounds[t.id] = (pose * CFrame.new(
			box.Centre.X,
			box.Centre.Y - box.Size.Y / 2,
			box.Centre.Z
		)).Position
		if Catalog[t.key].find then
			loose:fire(nil)
		end
		if from then
			local goal = pose * t.body.PivotOffset:Inverse()
			local tween = TweenService:Create(t.body, FALL, { CFrame = goal })
			tween.Completed:Once(function()
				if t.owner == nil and t.model.Parent == lying then
					if tear and t.sealed then
						rip(t, pose)
					else
						-- sealed, its pack lands: a soft cardboard thud, not the find's own clank
						local sound = if t.sealed then Pack.Thud else Catalog[t.key].drop
						Tools.play(sound, t.body, Carry.DropHeard)
						if hard then
							crack(t)
						end
					end
					landed:fire({ key = t.key, at = t.body.Position, reach = Carry.DropHeard })
				end
			end)
			tween:Play()
		end
		offer(t)
	end

	-- Where a tool dropped by someone at `root` lands: a floor point just ahead of them, or at
	-- their heels if they're running (`DROP_BEHIND`), found by a ray down that sees only the
	-- building (no players, no tools).
	local function dropPoint(root: BasePart): Vector3
		local v = root.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		local ahead = if flat.Magnitude > RUNNING
			then CFrame.new(root.Position - flat.Unit * DROP_BEHIND)
			else root.CFrame * CFrame.new(0, 0, -DROP_AHEAD)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = {}
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		if lying then
			table.insert(skip, lying)
		end
		params.FilterDescendantsInstances = skip
		-- from your middle, so a wall in front stops the ray short of the far side
		local start = root.Position
		local toward = ahead.Position - start
		local wall = Workspace:Raycast(start, toward, params)
		local over = if wall then wall.Position - toward.Unit * 0.6 else ahead.Position
		local hit = Workspace:Raycast(over, Vector3.new(0, -8, 0), params)
		return if hit then hit.Position else root.Position - Vector3.new(0, 3, 0)
	end

	-- Drops every tool `player` carries where they are (dying, leaving).
	local function dropAll(player: Player, root: BasePart?)
		local h = hands[player]
		if not h then
			return
		end
		local ids = Carry.clear(h.carry)
		local worn = offHead(player) -- falls with the rest (F-G1b4a1)
		if worn then
			table.insert(ids, worn.id)
		end
		for k, id in ids do
			local t = tools[id]
			if t then
				local at = if root then dropPoint(root) else Vector3.zero
				local fromCF = if root then root.CFrame else nil
				-- caught or fallen while running, a fragile find cracks as one let go does
				local speed = if root then root.AssemblyLinearVelocity.Magnitude else 0
				local fall = if root then root.Position.Y - at.Y else 0
				local hard = root ~= nil and cracks(t, speed, fall)
				local tear = root ~= nil and Seal.tears(t.sealed == true, speed, fall)
				layDown(
					t,
					resting(
						t.key,
						at + Vector3.new(0.4 * (k - 1), 0, 0),
						math.random(0, 359),
						t.sealed
					),
					fromCF,
					hard,
					tear
				)
			end
		end
		if player.Parent then
			publish(player)
		end
	end

	-- A find out of a job box `t` going for good (S5-03d2, D-302): taken up into the climb, it's
	-- lost to its owner's save; one that never went up is simply back in the box, nothing told.
	local function lost(t: Tool)
		local home = t.home
		if home and t.up then
			taken:fire({
				home = home,
				name = named(t),
				how = "Lost",
				cracked = t.chipped == true,
				torn = t.torn == true,
			})
		end
	end

	-- Its owner `home` left mid-climb (S5-03d2, D-302): each of theirs taken up is lost to their
	-- save as they go, and stays where it is, a find like any other now, so a friend who carries
	-- it aboard keeps it. Fired in the frame they leave, so it rides in their save's last write.
	local function strand(home: number)
		for _, t in tools do
			if t.home == home and t.up then
				lost(t)
				t.home = nil
				t.up = nil
			end
		end
	end

	-- Every find out of the job box of UserId `home` goes back into it (its owner left, D-293): out
	-- of whoever's hands or off whoever's head holds it, or off the floor where it lies, in a glint.
	-- One set down (`place`), with its piece out, or in a monster's arms is left to its system.
	local function recall(home: number)
		local gone = false
		for id, t in tools do
			if t.home ~= home or t.placed or outs[t.model] or t.away then
				continue
			end
			local holder: Player? = nil
			for p, h in hands do
				if Carry.find(h.carry, id) then
					holder = p
					break
				end
			end
			local wearer: Player? = nil
			for p, worn in heads do
				if worn == id then
					wearer = p
					break
				end
			end
			if not (holder or wearer or grounds[id]) then
				continue
			end
			if wearer then
				offHead(wearer)
			end
			local h = if holder then hands[holder] else nil
			if h then
				Carry.remove(h.carry, id)
			end
			tools[id] = nil
			grounds[id] = nil
			unoffer(t)
			if t.model.Parent then
				glint(t.body.Position)
			end
			-- back in the box: a crack it took while out comes home with it (D-296)
			taken:fire({
				home = home,
				name = named(t),
				how = "Back",
				cracked = t.chipped == true,
				torn = t.torn == true,
			})
			t.owner = nil
			stow(t)
			t.model:Destroy()
			gone = true
			for _, p in { holder, wearer } do
				if p and p.Parent then
					dress(p)
					publish(p)
				end
			end
		end
		if gone then
			loose:fire(nil)
		end
	end

	-- `player` leaving: each find of theirs going on their trip (`going`, S5-03d4) goes from the
	-- lobby with them, quietly, out of their slots or off their head; nothing told, as it isn't back
	-- in its box (the group's server deals it, its crack with it).
	local function leaveOnTrip(player: Player)
		local h = hands[player]
		local worn = heads[player]
		for id, t in tools do
			if not t.away or (t.owner ~= player and id ~= worn) then
				continue
			end
			if id == worn then
				offHead(player)
			end
			if h then
				Carry.remove(h.carry, id)
			end
			tools[id] = nil
			grounds[id] = nil
			unoffer(t)
			t.owner = nil
			stow(t)
			t.model:Destroy()
		end
	end

	-- A worn-out tool breaking (S1-08), wherever it is now: out of its owner's slots, it jumps out
	-- of the hand with its own snap and a burst of its bits, tumbles to the floor and clanks as it
	-- lands (keepers hear it, as a dropped tool), lies there a moment, then fades. Never silent,
	-- never just gone.
	-- `fall`: a worn find spent on a head (the hard hat, F-G1b4b): it slips off from `from` with a
	-- smaller hop and cracks apart as it hits the floor (`snap`, `bits`), not in the air.
	local function shatter(t: Tool, fall: Fall?)
		if tools[t.id] ~= t then
			return -- gone already: kept, or the floor it lay on cleared
		end
		tools[t.id] = nil
		lost(t) -- used up on the climb
		local row = Catalog[t.key]
		local w = row.wear
		local snap = if fall then fall.snap elseif w then w.snap else nil
		local colours = if fall then fall.bits elseif w then w.bits else nil
		local jump = if fall then fall.up else BREAK_JUMP
		local owner = t.owner
		local inHand = t.weld ~= nil
		local character = if owner then owner.Character else nil
		local root = if owner then rootOf(owner) else nil
		-- where it breaks: in the hand it's welded to, at its owner's hand if it was put away, or
		-- where it lies
		local pose = t.body.CFrame
		if fall then
			pose = fall.from
		elseif owner and not inHand and t.model.Parent == nil then
			local hand = if character then handOf(character) else nil
			pose = if hand then hand.CFrame else if root then root.CFrame else pose
		end
		if owner then
			local h = hands[owner]
			if h then
				Carry.remove(h.carry, t.id)
			end
		end
		unoffer(t)
		stow(t)
		t.owner = nil
		local model, body = t.model, t.body
		model.Name = "Broken"
		body.CFrame = pose
		body.CanCollide = true
		body.CanQuery = false
		body.CanTouch = false
		model.Parent = Workspace
		body.Anchored = false
		local ahead = if root then root.CFrame.LookVector else Vector3.zero
		local function spin(): number
			return (math.random() * 2 - 1) * BREAK_SPIN
		end
		body.AssemblyLinearVelocity = ahead * (if fall then fall.ahead else BREAK_AHEAD)
			+ Vector3.new(0, jump, 0)
		body.AssemblyAngularVelocity = Vector3.new(spin(), spin(), spin())
		-- the server's to move, so every screen sees the same tumble
		pcall(function() -- pcall: refused if the engine has it anchored to something still
			body:SetNetworkOwner(nil)
		end)
		-- its snap and its bits flying from `at`
		local function burst(at: Vector3)
			if not (snap and colours) then
				return
			end
			Tools.play(snap, body, BREAK_REACH)
			for i = 1, if #colours > 0 then BITS else 0 do
				local c = colours[(i - 1) % #colours + 1]
				local function between(r: { number }): number
					return r[1] + math.random() * (r[2] - r[1])
				end
				local bit = Instance.new("Part")
				bit.Name = "Bit"
				bit.Size =
					Vector3.new(between(BIT_SIZE), between(BIT_SIZE) * 0.5, between(BIT_SIZE))
				bit.Color = Color3.fromRGB(c[1], c[2], c[3])
				bit.Material = Enum.Material.Metal
				bit.CastShadow = false
				bit.CanQuery = false
				bit.CanTouch = false
				bit.CFrame = CFrame.new(at)
					* CFrame.Angles(
						math.random() * 6.28,
						math.random() * 6.28,
						math.random() * 6.28
					)
				local dir = Vector3.new(
					math.random() * 2 - 1,
					math.random() * 0.8 + 0.2,
					math.random() * 2 - 1
				)
				bit.AssemblyLinearVelocity = dir.Unit * between(BIT_SPEED)
				bit.AssemblyAngularVelocity = Vector3.new(spin(), spin(), spin()) * 2
				bit.Parent = model
				pcall(function() -- pcall: as the tool's own
					bit:SetNetworkOwner(nil)
				end)
			end
		end
		local at = body.Position
		if not fall then
			burst(at)
		end
		-- its clank as it lands: the fall from here to the floor under it, at this place's gravity
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local skip: { Instance } = { model }
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(skip, p.Character)
			end
		end
		params.FilterDescendantsInstances = skip
		local floor = Workspace:Raycast(at, Vector3.new(0, -20, 0), params)
		local drop = if floor then math.max(0, at.Y - floor.Position.Y) else 3
		local g = math.max(1, Workspace.Gravity)
		local falls = (jump + math.sqrt(jump * jump + 2 * g * drop)) / g
		task.delay(falls, function()
			if model.Parent then
				if fall then
					burst(body.Position) -- it cracks apart as it hits
				end
				Tools.play(row.drop, body, Carry.DropHeard)
				landed:fire({ key = t.key, at = body.Position, reach = Carry.DropHeard })
			end
		end)
		task.delay(BROKEN_LIES, function()
			if not model.Parent then
				return
			end
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") then
					TweenService:Create(part, BROKEN_FADE, { Transparency = 1 }):Play()
				end
			end
			task.delay(BROKEN_FADE.Time + 0.1, function()
				model:Destroy()
			end)
		end)
		if owner and owner.Parent then
			if inHand and broke then
				broke:FireClient(owner, t.key)
			end
			dress(owner)
			publish(owner)
			changed:fire({ player = owner, kind = "Break" })
		end
	end

	-- Whether `player`'s hand may move now (the rate check); spends one if so.
	local function allowed(h: Hand): boolean
		-- a tool breaking in your hand (its last use spent): the hand holds it till it goes
		local held = Carry.held(h.carry)
		local tool = if held then tools[held] else nil
		if tool and not Wear.usable(tool.uses) then
			return false
		end
		local t = now()
		local may, left = Carry.allow(h.last, h.burst, t)
		if not may then
			return false
		end
		h.last, h.burst = t, left
		return true
	end

	pickUp = function(t: Tool, player: Player)
		-- range: a living player near a tool still on the floor
		local root = rootOf(player)
		if not root or t.owner ~= nil or t.model.Parent ~= lying then
			return
		end
		if player:GetAttribute(Kept.Attribute) == true then
			return -- wrapped: no hands to pick anything up with (L-07a)
		end
		if (root.Position - t.body.Position).Magnitude > Carry.PickReach + REACH_SLACK + 2 then
			return
		end
		-- a shut door between you and it: your screen hid its prompt (BehindDoors)
		for _, unit in CollectionService:GetTagged(StorageUnit.UnitKit.Tag) do
			if
				unit:IsA("Model")
				and unit:IsDescendantOf(Workspace)
				and unit:FindFirstChild("DoorOrigin", true)
				and StorageUnit.RollUpDoor.keepsApart(unit, root.Position, t.body.Position)
			then
				return
			end
		end
		local h = handOfPlayer(player)
		local big = bothHands(h)
		if big then
			if t.refuse then
				t.refuse(`Drop the {string.lower(big.name)} first`, player)
			end
			return
		end
		if Carry.room(h.carry) == nil then
			if t.refuse then
				t.refuse("Hands full", player)
			end
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		Carry.take(h.carry, t.id)
		unoffer(t)
		t.owner = player
		grounds[t.id] = nil
		dress(player)
		publish(player)
		local character = player.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or root, HAND_SOUND_REACH)
		changed:fire({ player = player, kind = "PickUp" })
		if Catalog[t.key].find then
			loose:fire(nil)
		end
	end

	local function onSwitch(player: Player, slot: unknown)
		-- type: a whole slot number
		local s = Carry.slot(slot)
		if not s then
			return
		end
		-- range: a living character
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		-- rate
		if not allowed(h) then
			publish(player)
			return
		end
		-- both hands on a big tool: no switching away from it
		local big = bothHands(h)
		if big and s ~= h.carry.active then
			tell(player, `Drop the {string.lower(big.name)} first`)
			publish(player)
			return
		end
		if Carry.select(h.carry, s) then
			h.moved = now()
			dress(player)
			changed:fire({ player = player, kind = "Switch" })
		end
		publish(player)
	end

	-- ToolPocket: `down` true puts the tool on your slot away, false brings it back up.
	local function onPocket(player: Player, down: unknown)
		-- type: a boolean
		if type(down) ~= "boolean" then
			return
		end
		-- range: a living character
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		-- rate
		if not allowed(h) then
			publish(player)
			return
		end
		-- both hands on a big tool: it rides on your shoulder, it can't be put away (your screen
		-- answers this press itself)
		if down and bothHands(h) then
			publish(player)
			return
		end
		if Carry.pocket(h.carry, down) then
			h.moved = now()
			dress(player)
			changed:fire({ player = player, kind = "Pocket" })
		end
		publish(player)
	end

	-- ToolUse: nothing to check for type (it takes nothing); range: a living character with a
	-- tool in hand that has a verb; then its own rate.
	local function onUse(player: Player)
		if not rootOf(player) then
			return
		end
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		local row = if t then Catalog[t.key] else nil
		if not (t and row and row.verb and Wear.usable(t.uses)) then
			return
		end
		if t.sealed then
			return -- still in its packaging: your screen crinkles the pack and shakes it (HornView)
		end
		local at = now()
		local may, left = Carry.allow(h.usedLast, h.usedBurst, at)
		if not may then
			return
		end
		h.usedLast, h.usedBurst = at, left
		used:fire({ player = player, key = t.key, model = t.model })
	end

	local function onDrop(player: Player)
		-- range: a living character with something in hand
		local root = rootOf(player)
		if not root then
			return
		end
		local h = handOfPlayer(player)
		if Carry.held(h.carry) == nil then
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		local id = Carry.release(h.carry) :: string
		local t = tools[id]
		if t then
			t.kept = nil -- set down somewhere else: its old spot's forgotten
		end
		publish(player)
		if not t then
			return
		end
		local from = t.body.CFrame * t.body.PivotOffset
		local _, facing = root.CFrame:ToOrientation()
		-- crosswise in front of you, as a dropped tool lands, a little askew; sealed, its pack's
		-- window turned back to you, as you'd set a boxed thing down
		local yaw = if t.sealed
			then math.deg(facing) + 180 + math.random(-12, 12)
			else math.deg(facing) + 90 + math.random(-25, 25)
		local at = dropPoint(root)
		-- let go at a run, mid-fall or from high up, a fragile find cracks as it lands (F-G1e5e)
		local speed, fall = root.AssemblyLinearVelocity.Magnitude, from.Position.Y - at.Y
		local hard = cracks(t, speed, fall)
		-- sealed, the same hard drop tears its pack off instead (S5-02b2b2)
		local tear = Seal.tears(t.sealed == true, speed, fall)
		layDown(t, resting(t.key, at, yaw, t.sealed), from, hard, tear)
		changed:fire({ player = player, kind = "Drop" })
	end

	local function onGive(player: Player, target: unknown)
		-- type: a player in this server, not you
		if typeof(target) ~= "Instance" or not (target :: Instance):IsA("Player") then
			return
		end
		local friend = target :: Player
		if friend == player or friend.Parent ~= Players then
			return
		end
		if
			player:GetAttribute(Kept.Attribute) == true
			or friend:GetAttribute(Kept.Attribute) == true
		then
			return -- either of you wrapped (L-07a)
		end
		-- range: both alive, within reach, something in your hand, room in theirs
		local root, theirs = rootOf(player), rootOf(friend)
		if not (root and theirs) then
			return
		end
		if (root.Position - theirs.Position).Magnitude > Carry.GiveReach + REACH_SLACK then
			return
		end
		local h, them = handOfPlayer(player), handOfPlayer(friend)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (id and t) then
			return
		end
		if Carry.room(them.carry) == nil or bothHands(them) then
			tell(player, "Their hands are full")
			return
		end
		-- rate
		if not allowed(h) then
			return
		end
		Carry.release(h.carry)
		Carry.take(them.carry, id)
		t.owner = friend
		t.kept = nil -- a friend's now: the spot was yours to snap back to
		stow(t)
		dress(player)
		dress(friend)
		publish(player)
		publish(friend)
		local character = friend.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or theirs, HAND_SOUND_REACH)
		tell(friend, `{Catalog[t.key].name} from {player.DisplayName}`)
		changed:fire({ player = player, kind = "Give" })
	end

	local function addPlayer(player: Player)
		handOfPlayer(player)
		publish(player)
		local function onCharacter(character: Model)
			character:WaitForChild("LeftHand", 5)
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				-- goes with the humanoid
				humanoid.Died:Connect(function()
					local root = character:FindFirstChild("HumanoidRootPart")
					dropAll(player, if root and root:IsA("BasePart") then root else nil)
				end)
			end
			if character.Parent then
				dress(player)
				character:WaitForChild("Head", 5)
				wearOn(player)
				pace(player, handOfPlayer(player))
			end
		end
		table.insert(connections, player.CharacterAdded:Connect(onCharacter))
		-- a character replaced without dying takes its held tool out first, so it isn't destroyed
		-- with it; the next character gets it back in hand
		table.insert(
			connections,
			player.CharacterRemoving:Connect(function()
				local h = hands[player]
				local held = if h then Carry.held(h.carry) else nil
				local t = if held then tools[held] else nil
				if t and t.owner == player then
					stow(t)
				end
				local worn = heads[player]
				local w = if worn then tools[worn] else nil
				if w then
					stow(w)
				end
			end)
		)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end

	local system = {
		name = "Slots",
		changed = changed,
		used = used,
		landed = landed,
		loose = loose,
		taken = taken,
	}

	function system.start(_: any, _context: Brix.Context)
		local f = Workspace:FindFirstChild("Tools")
		if not f then
			f = Instance.new("Folder")
			f.Name = "Tools"
			f.Parent = Workspace
		end
		lying = f :: Folder
		local rf = ReplicatedStorage:FindFirstChild(Tools.RemoteFolder)
		if not rf then
			rf = Instance.new("Folder")
			rf.Name = Tools.RemoteFolder
			rf.Parent = ReplicatedStorage
		end
		local function remote(name: string): RemoteEvent
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = rf
			table.insert(remotes, r)
			return r
		end
		table.insert(connections, remote(Tools.SwitchRemote).OnServerEvent:Connect(onSwitch))
		table.insert(connections, remote(Tools.PocketRemote).OnServerEvent:Connect(onPocket))
		table.insert(connections, remote(Tools.DropRemote).OnServerEvent:Connect(onDrop))
		table.insert(connections, remote(Tools.GiveRemote).OnServerEvent:Connect(onGive))
		table.insert(connections, remote(Tools.UseRemote).OnServerEvent:Connect(onUse))
		notice = remote(Tools.NoticeRemote)
		broke = remote(Tools.BrokeRemote)
		snatched = remote(Tools.SnatchedRemote)
		table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				leaveOnTrip(player)
				dropAll(player, rootOf(player))
				hands[player] = nil
				heads[player] = nil
				strand(player.UserId) -- taken up: lost, and a friend's to carry aboard
				recall(player.UserId) -- the rest: back in the box
			end)
		)
		for _, player in Players:GetPlayers() do
			addPlayer(player)
		end
		if RunService:IsStudio() then
			-- Studio only: Workspace's "DevTake" set to a player's name takes up for them the find
			-- lying nearest them, as its Take prompt would (the MCP's client never sees a prompt)
			table.insert(
				connections,
				Workspace:GetAttributeChangedSignal("DevTake"):Connect(function()
					local name = Workspace:GetAttribute("DevTake")
					local player = if type(name) == "string"
						then Players:FindFirstChild(name)
						else nil
					local root = if player and player:IsA("Player") then rootOf(player) else nil
					if not (player and player:IsA("Player") and root) then
						return
					end
					local best: Tool? = nil
					for _, t in tools do
						local far = (t.body.Position - root.Position).Magnitude
						if
							t.owner == nil
							and t.model.Parent == lying
							and (not best or far < (best.body.Position - root.Position).Magnitude)
						then
							best = t
						end
					end
					if best then
						pickUp(best, player)
					end
				end)
			)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, r in remotes do
			r:Destroy()
		end
		table.clear(remotes)
		changed:disconnectAll()
		used:disconnectAll()
		landed:disconnectAll()
		loose:disconnectAll()
		taken:disconnectAll()
	end

	function system.lay(_: any, key: string, at: Vector3, yaw: number, sealed: boolean?): string?
		local pose = resting(key, at, yaw, sealed)
		local model = Tools.clone(key, pose)
		if not model then
			return nil
		end
		local body = Tools.body(model)
		if not body then
			model:Destroy()
			return nil
		end
		-- on the server's model, so every screen sees it in its pack wherever it goes
		local wrapped = sealed == true
			and Pack.wrap(model, body, Catalog[key].size, Tools.bounds(key))
		if sealed and not wrapped then
			pose = resting(key, at, yaw) -- no pack in the place: it lies as a loose find
			model:PivotTo(pose)
		end
		nextId += 1
		local id = `{key}{nextId}`
		local t: Tool = {
			id = id,
			n = nextId,
			key = key,
			model = model,
			body = body,
			owner = nil,
			uses = Wear.full(key),
			sealed = if wrapped then true else nil,
		}
		tools[id] = t
		layDown(t, pose, nil)
		return id
	end

	function system.clear(_: any, inside: (at: Vector3) -> boolean): number
		local gone = 0
		for id, t in tools do
			if t.owner == nil and t.model.Parent == lying and inside(t.body.Position) then
				tools[id] = nil
				grounds[id] = nil
				lost(t) -- left with a floor the climb leaves, or the climb over
				unoffer(t)
				t.model:Destroy()
				gone += 1
			end
		end
		if gone > 0 then
			loose:fire(nil)
		end
		return gone
	end

	function system.out(_: any, model: Model, out: Out?)
		if out then
			outs[model] = out
		else
			outs[model] = nil
		end
		loose:fire(nil)
	end

	function system.finds(_: any, each: (n: number, at: Vector3, model: Model) -> ())
		for id, t in tools do
			local out = outs[t.model]
			if out then
				-- where its piece is, however the rest is held (not in a monster's arms)
				local at = if t.weld and t.weld.Name == Tools.CarriedName then nil else out.at()
				if at then
					each(t.n, at, t.model)
				end
				continue
			end
			local at = grounds[id]
			if at and t.owner == nil and t.model.Parent == lying and Catalog[t.key].find then
				each(t.n, at, t.model)
			end
		end
	end

	-- A find by its number: the one lying loose (`lifted` false) or in a monster's arms.
	local function numbered(n: number, lifted: boolean): Tool?
		for id, t in tools do
			if t.n == n and t.owner == nil and (not grounds[id]) == lifted then
				return t
			end
		end
		return nil
	end

	-- Find `t`, its piece out, taken out of wherever it is so the piece can bring it together for
	-- a monster's hands in `holder`: out of its carrier's slots (their screen told, as `snatch`'s)
	-- or off the floor, anchored where it is.
	local function free(t: Tool, holder: Instance)
		local owner = t.owner
		local h = if owner then hands[owner] else nil
		local slot = if h then Carry.find(h.carry, t.id) else nil
		if h then
			Carry.remove(h.carry, t.id)
		end
		unoffer(t)
		grounds[t.id] = nil
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.owner = nil
		t.body.Anchored = true
		t.model.Name = t.key -- no longer the one in a hand, for anyone looking this frame
		if owner and h then
			dress(owner)
			publish(owner)
			if snatched and slot then
				snatched:FireClient(owner, t.key, slot, holder)
			end
			changed:fire({ player = owner, kind = "Taken" })
		end
	end

	-- The find numbered `n` with a piece out, if one is.
	local function outNumbered(n: number): Tool?
		for _, t in tools do
			if t.n == n and outs[t.model] then
				return t
			end
		end
		return nil
	end

	function system.lift(_: any, n: number, part: BasePart, holder: Instance): Weld?
		local away = outNumbered(n)
		local t = away or numbered(n, false)
		if not t then
			return nil
		end
		local out = outs[t.model]
		if away and out then
			-- the car out on the floor (F-G1b3c3): the whole find, together where the car is
			local at = out.at()
			local d = if at then at - part.Position else nil
			if
				not d
				or Vector3.new(d.X, 0, d.Z).Magnitude > OUT_GRASP
				or (t.weld and t.weld.Name == Tools.CarriedName)
			then
				return nil
			end
			free(t, holder)
			outs[t.model] = nil
			out.gather(true)
		elseif t.model.Parent == lying then
			unoffer(t)
			grounds[t.id] = nil
		else
			return nil
		end
		local box = Tools.bounds(t.key)
		local middle = t.body.PivotOffset * CFrame.new(box.Centre)
		local weld = Instance.new("Weld")
		weld.Name = Tools.CarriedName
		weld.Part0 = part
		weld.Part1 = t.body
		weld.C0 = part.CFrame:ToObjectSpace(t.body.CFrame * middle)
		weld.C1 = middle
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Name = t.key
		t.model.Parent = holder
		loose:fire(nil)
		return weld
	end

	function system.putDown(_: any, n: number, at: Vector3, yaw: number, held: CFrame?)
		local t = numbered(n, true)
		if not (t and t.weld) then
			return
		end
		-- the pivot, from where its middle is held (as `lift` measures the middle)
		local from = if held
			then held * CFrame.new(Tools.bounds(t.key).Centre):Inverse()
			else t.body.CFrame * t.body.PivotOffset
		local pose = resting(t.key, at, yaw, t.sealed)
		t.weld:Destroy()
		t.weld = nil
		t.body.Anchored = true
		layDown(t, pose, nil)
		-- set down, not dropped: a short ease from its hands to the floor, no clank
		t.model:PivotTo(from)
		TweenService:Create(t.body, PUT_DOWN, { CFrame = pose * t.body.PivotOffset:Inverse() })
			:Play()
	end

	local function worth(key: string): number?
		return Carry.worth(Catalog[key])
	end

	function system.prize(_: any, player: Player): number
		local h = hands[player]
		if not h then
			return 0
		end
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			prizeKeys[i] = if t then t.key else ""
		end
		local slot = Carry.prize(prizeKeys, h.carry.active, worth)
		local id = if slot ~= 0 then h.carry.slots[slot] else nil
		local t = if id then tools[id] else nil
		return if t then t.n else 0
	end

	function system.snatch(
		_: any,
		player: Player,
		n: number,
		part: BasePart,
		holder: Instance
	): (Weld?, CFrame?)
		local h = hands[player]
		if not h then
			return nil, nil
		end
		local slot, t = 0, nil :: Tool?
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local c = if id then tools[id] else nil
			if c and c.n == n then
				slot, t = i, c
				break
			end
		end
		if not t then
			return nil, nil
		end
		local out = outs[t.model]
		if out then
			-- its piece out (the RC car, F-G1b3c3): home into it first, the whole find torn away
			outs[t.model] = nil
			out.gather(false)
		end
		local box = Tools.bounds(t.key)
		local middle = t.body.PivotOffset * CFrame.new(box.Centre)
		-- where it was: in their hand (or on their shoulder) as everyone saw it, else their middle
		local root = rootOf(player)
		local from = if t.weld and t.model.Parent
			then t.body.CFrame * middle
			elseif root then root.CFrame
			else part.CFrame
		Carry.remove(h.carry, t.id)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.owner = nil
		t.model:PivotTo(from * middle:Inverse() * t.body.PivotOffset)
		local weld = Instance.new("Weld")
		weld.Name = Tools.CarriedName
		weld.Part0 = part
		weld.Part1 = t.body
		weld.C0 = part.CFrame:ToObjectSpace(from)
		weld.C1 = middle
		weld.Parent = t.body
		t.weld = weld
		t.body.Anchored = false
		t.model.Name = t.key
		t.model.Parent = holder
		dress(player)
		publish(player)
		if snatched then
			snatched:FireClient(player, t.key, slot, holder)
		end
		changed:fire({ player = player, kind = "Taken" })
		return weld, from
	end

	function system.carried(_: any, player: Player): ({ string }, number)
		local h = handOfPlayer(player)
		local out = {}
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			out[i] = if t then t.key else ""
		end
		-- a pocketed tool isn't in your hand: no slot is (0), so Lock, Cut, Saw and Lean see a
		-- tool carried but not held
		return out, Carry.hand(h.carry)
	end

	function system.dropAll(_: any, player: Player)
		dropAll(player, rootOf(player))
	end

	function system.keep(_: any, player: Player): ({ string }, { string }, { Moved })
		local h = hands[player]
		if not h then
			return {}, {}, {}
		end
		-- a find out of a job box that no gate keeps for `player`: one out of their own (D-302),
		-- or one that never went up (D-293: kept for no one)
		local function mine(t: Tool): boolean
			return t.home ~= nil and (t.home == player.UserId or not t.up)
		end
		local ids = Carry.keep(h.carry, function(id: string): boolean
			local t = tools[id]
			local row = if t then Catalog[t.key] else nil
			-- a find whose piece is still out is left behind with the floor (F-G1b3c3): it stays
			-- in your slots till the piece goes with the floor (`lose`); one out of your own job
			-- box is already yours, so it stays in your slots, at risk on the next floor (D-302)
			return row ~= nil and row.find == true and not (t and (outs[t.model] or mine(t)))
		end)
		local keys: { string } = {}
		local chipped: { string } = {}
		local moved: { Moved } = {}
		-- the find on your head is kept with the rest, going from your head in a glint
		local worn = heads[player]
		local w = if worn then tools[worn] else nil
		if w and not outs[w.model] and not mine(w) then
			glint(w.body.Position)
			offHead(player)
			table.insert(ids, w.id)
		end
		for _, id in ids do
			local t = tools[id]
			if t then
				tools[id] = nil
				local home = t.home
				if home then
					-- a friend's, taken up: theirs now (S5-03d2), told apart for both saves
					table.insert(moved, {
						home = home,
						name = named(t),
						cracked = t.chipped == true,
						torn = t.torn == true,
					})
				else
					table.insert(keys, named(t))
					if t.chipped then
						table.insert(chipped, t.key)
					end
				end
				if t.model.Parent then
					glint(t.body.Position) -- the one in your hand, as everyone near saw it
				end
				stow(t)
				t.model:Destroy()
			end
		end
		if #keys + #moved > 0 then
			dress(player)
			publish(player)
			changed:fire({ player = player, kind = "Keep" })
		end
		return keys, chipped, moved
	end

	function system.takeUp(_: any, model: Model): (string?, boolean)
		for id, t in tools do
			if t.model == model then
				if t.owner ~= nil or t.model.Parent ~= lying or outs[model] or t.home ~= nil then
					return nil, false
				end
				tools[id] = nil
				grounds[id] = nil
				unoffer(t)
				glint(t.body.Position)
				t.model:Destroy()
				loose:fire(nil)
				return named(t), t.chipped == true
			end
		end
		return nil, false
	end

	function system.up(_: any, player: Player)
		local worn = heads[player]
		for id, t in tools do
			if t.home and (t.owner == player or id == worn) then
				t.up = true
			end
		end
	end

	function system.going(_: any, players: { Player }): { Up }
		local riders: { [number]: true } = {}
		for _, player in players do
			riders[player.UserId] = true
		end
		local ups: { Up } = {}
		for _, player in players do
			local worn = heads[player]
			for id, t in tools do
				local home = t.home
				if
					home
					and riders[home]
					and (t.owner == player or id == worn)
					and not t.placed
					and not outs[t.model]
				then
					t.away = true
					table.insert(ups, {
						owner = home,
						name = named(t),
						holder = player.UserId,
						cracked = t.chipped == true,
						worn = id == worn,
					})
				end
			end
		end
		return ups
	end

	function system.stay(_: any, player: Player)
		local worn = heads[player]
		local gone: { [number]: true } = {}
		for id, t in tools do
			if t.away and (t.owner == player or id == worn) then
				t.away = nil
				local home = t.home
				if home and not Players:GetPlayerByUserId(home) then
					gone[home] = true
				end
			end
		end
		for home in gone do
			recall(home) -- its owner went on the trip without it: back in their box
		end
	end

	function system.lose(_: any, model: Model, sound: Tools.SoundSpec)
		outs[model] = nil
		local t: Tool? = nil
		for _, c in tools do
			if c.model == model then
				t = c
				break
			end
		end
		if not t then
			return
		end
		tools[t.id] = nil
		grounds[t.id] = nil
		lost(t) -- its piece gone with a floor
		unoffer(t)
		local owner = t.owner
		local h = if owner then hands[owner] else nil
		local inHand = h ~= nil and t.weld ~= nil and t.model.Parent ~= nil
		-- its sound from where it was: its carrier (in a hand or a pocket), else where it lay
		local root = if owner then rootOf(owner) else nil
		if root then
			Tools.play(sound, root, HAND_SOUND_REACH)
		elseif t.model.Parent then
			local spot = Instance.new("Attachment")
			spot.Name = "Lost"
			spot.WorldPosition = t.body.Position
			spot.Parent = Workspace.Terrain
			Tools.play(sound, spot, HAND_SOUND_REACH)
			task.delay(sound.length / (sound.pitch or 1) + 1, function()
				spot:Destroy()
			end)
		end
		if h then
			Carry.remove(h.carry, t.id)
		end
		t.owner = nil
		stow(t)
		t.model:Destroy()
		if owner and h then
			dress(owner)
			publish(owner)
			if inHand and broke then
				broke:FireClient(owner, t.key)
			end
			changed:fire({ player = owner, kind = "Spend" })
		end
		loose:fire(nil)
	end

	function system.spend(_: any, player: Player, key: string): boolean
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key) then
			return false
		end
		Carry.release(h.carry)
		tools[t.id] = nil
		lost(t)
		stow(t)
		t.model:Destroy()
		publish(player)
		changed:fire({ player = player, kind = "Spend" })
		return true
	end

	-- The tool in `player`'s hand when it's a find out of their own job box that never went up the
	-- climb and isn't in its pack: only such a find can be set down in their home by hand.
	local function ownHeld(player: Player): Tool?
		local id = Carry.held(handOfPlayer(player).carry)
		local t = if id then tools[id] else nil
		if t and ownBox(t, player.UserId) then
			return t
		end
		return nil
	end

	function system.heldFromBox(_: any, player: Player): string?
		local t = ownHeld(player)
		return if t then named(t) else nil
	end

	function system.setDown(_: any, player: Player): boolean
		local t = ownHeld(player)
		if not t then
			return false
		end
		Carry.release(handOfPlayer(player).carry)
		tools[t.id] = nil
		unoffer(t)
		if t.chipped then -- back in the box first: a crack it took while out comes home with it
			taken:fire({
				home = player.UserId,
				name = named(t),
				how = "Back",
				cracked = true,
				torn = false,
			})
		end
		t.owner = nil
		stow(t)
		t.model:Destroy()
		dress(player)
		publish(player)
		changed:fire({ player = player, kind = "Place" })
		return true
	end

	function system.wear(_: any, player: Player, key: string): number?
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key and t.uses) then
			return nil
		end
		local left, gone = Wear.spend(t.uses)
		t.uses = left
		-- on the model first: a screen learning of a blast already knows it was the last
		t.model:SetAttribute(Wear.ModelAttribute, left)
		publish(player)
		local w = Catalog[key].wear
		if gone and w then
			task.delay(w.late, shatter, t)
		end
		return left
	end

	function system.place(_: any, player: Player, key: string): (string?, Model?)
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key) then
			return nil, nil
		end
		Carry.release(h.carry)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		t.body.Anchored = true
		t.owner = nil
		t.placed = true
		t.model.Name = t.key
		publish(player)
		changed:fire({ player = player, kind = "Place" })
		return t.id, t.model
	end

	function system.toHead(_: any, player: Player, key: string): Model?
		local h = handOfPlayer(player)
		local id = Carry.held(h.carry)
		local t = if id then tools[id] else nil
		if not (t and t.key == key and Head.fit(key) and rootOf(player)) or heads[player] then
			return nil
		end
		Carry.release(h.carry)
		if t.weld then
			t.weld:Destroy()
			t.weld = nil
		end
		heads[player] = t.id
		wearOn(player)
		dress(player)
		publish(player)
		changed:fire({ player = player, kind = "Wear" })
		return t.model
	end

	function system.worn(_: any, each: (player: Player, model: Model) -> ())
		for player, id in heads do
			local t = tools[id]
			if t and t.model.Parent and rootOf(player) then
				each(player, t.model)
			end
		end
	end

	function system.breakWorn(_: any, player: Player): boolean
		local id = heads[player]
		local t = if id then tools[id] else nil
		if not t then
			return false
		end
		local from = t.body.CFrame -- on their head, before it comes off
		offHead(player)
		shatter(t, {
			from = from,
			up = Headlamp.FallUp,
			ahead = Headlamp.FallAhead,
			snap = Headlamp.Crack,
			bits = Headlamp.Bits,
		})
		return true
	end

	function system.onThem(_: any, player: Player, each: (model: Model) -> ())
		local h = handOfPlayer(player)
		for i = 1, Carry.Slots do
			local id = h.carry.slots[i]
			local t = if id then tools[id] else nil
			if t then
				each(t.model)
			end
		end
		local worn = heads[player]
		local t = if worn then tools[worn] else nil
		if t then
			each(t.model)
		end
	end

	function system.handBack(_: any, player: Player, id: string): string?
		local t = tools[id]
		if not (t and t.placed) or not rootOf(player) then
			return ""
		end
		local h = handOfPlayer(player)
		local big = bothHands(h)
		if big then
			return `Drop the {string.lower(big.name)} first`
		end
		if Carry.room(h.carry) == nil then
			return "Hands full"
		end
		if not allowed(h) then
			return ""
		end
		t.placed = nil
		Carry.take(h.carry, t.id)
		t.owner = player
		dress(player)
		publish(player)
		local character = player.Character
		local hand = if character then handOf(character) else nil
		Tools.play(Catalog[t.key].pickUp, hand or t.body, HAND_SOUND_REACH)
		changed:fire({ player = player, kind = "PickUp" })
		return nil
	end

	-- A new `key` into a free slot of `player`'s and their hand: the slot, or nil. `quiet`: no
	-- pick-up sound here, as the screens play it when the thing reaches the hand (a buy at the
	-- car's machine, MachineVend; a find out of the job box, BoxPanelView). `home`: the UserId
	-- whose job box it came out of; `gold`: a Gold of find `key`, its model gilded. Its tool too.
	local function make(
		player: Player,
		key: string,
		quiet: boolean?,
		home: number?,
		gold: boolean?,
		since: number?,
		sealed: boolean?
	): (number?, Tool?)
		local root = rootOf(player)
		local h = handOfPlayer(player)
		if not root or Catalog[key] == nil or bothHands(h) or Carry.room(h.carry) == nil then
			return nil
		end
		local model = Tools.clone(key, root.CFrame)
		local body = if model then Tools.body(model) else nil
		if not (model and body) then
			if model then
				model:Destroy()
			end
			return nil
		end
		if gold then
			Gold.gild(model) -- on the server's model, so every screen sees it gold wherever it goes
		end
		-- sealed (S5-02b2b1), wrapped on the server's model the same way; never a Gold
		local wrapped = sealed == true
			and not gold
			and Pack.wrap(model, body, Catalog[key].size, Tools.bounds(key))
		nextId += 1
		local t: Tool = {
			id = `{key}{nextId}`,
			n = nextId,
			key = key,
			model = model,
			body = body,
			owner = player,
			uses = Wear.full(key),
			home = home,
			gold = gold,
			sealed = if wrapped then true else nil,
		}
		tools[t.id] = t
		local slot = Carry.take(h.carry, t.id, since ~= nil and h.moved > since)
		dress(player)
		publish(player)
		if not quiet then
			local character = player.Character
			local hand = if character then handOf(character) else nil
			Tools.play(Catalog[key].pickUp, hand or root, HAND_SOUND_REACH)
		end
		changed:fire({ player = player, kind = "PickUp" })
		return slot, t
	end

	function system.give(
		_: any,
		player: Player,
		key: string,
		quiet: boolean?,
		since: number?,
		sealed: boolean?
	): boolean
		return make(player, key, quiet, nil, nil, since, sealed) ~= nil
	end

	function system.unbox(_: any, player: Player, key: string, kept: HandPlace.Pose?): number?
		local base = Gold.base(key) -- a Gold's find: carried as the find, gilded
		local sealed = Seal.base(key) -- a sealed one's (D-427): carried as the find, in its pack
		local find = base or sealed or key
		local row = Catalog[find]
		if not (row and row.find) then
			return nil
		end
		local n, t = make(player, find, true, player.UserId, base ~= nil, nil, sealed ~= nil)
		if t and sealed and not t.sealed then
			t.torn = true -- the place lacks its pack: dealt plain, settled as the sealed one
		end
		if t and kept then
			t.kept = table.clone(kept)
			publish(player)
		end
		return n
	end

	function system.keeps(_: any, player: Player): boolean
		for _, id in handOfPlayer(player).carry.slots do
			local t = tools[id]
			if t and t.kept then
				return true
			end
		end
		return false
	end

	function system.forget(_: any, player: Player)
		local any = false
		for _, id in handOfPlayer(player).carry.slots do
			local t = tools[id]
			if t and t.kept then
				t.kept = nil
				any = true
			end
		end
		if any then
			publish(player)
		end
	end

	function system.room(_: any, player: Player): boolean
		local h = handOfPlayer(player)
		return rootOf(player) ~= nil and not bothHands(h) and Carry.room(h.carry) ~= nil
	end

	function system.fromBox(_: any, player: Player): { [string]: number }
		local out: { [string]: number } = {}
		for _, t in tools do
			if t.home == player.UserId then
				local name = named(t)
				out[name] = (out[name] or 0) + 1
			end
		end
		return out
	end

	function system.boxToHead(_: any, player: Player, name: string): Model?
		if Seal.base(name) then
			return nil -- still in its pack: carried in the hand, never worn (D-427)
		end
		local base = Gold.base(name)
		local key = base or name
		local row = Catalog[key]
		local root = rootOf(player)
		if not (row and row.find and Head.fit(key) and root) or heads[player] then
			return nil
		end
		local model = Tools.clone(key, root.CFrame)
		local body = if model then Tools.body(model) else nil
		if not (model and body) then
			if model then
				model:Destroy()
			end
			return nil
		end
		if base then
			Gold.gild(model)
		end
		nextId += 1
		local t: Tool = {
			id = `{key}{nextId}`,
			n = nextId,
			key = key,
			model = model,
			body = body,
			owner = player,
			uses = Wear.full(key),
			home = player.UserId,
			gold = base ~= nil,
		}
		tools[t.id] = t
		heads[player] = t.id
		wearOn(player)
		dress(player)
		publish(player)
		changed:fire({ player = player, kind = "Wear" })
		return model
	end

	function system.carryUp(_: any, holder: Player, u: Up, quiet: boolean): boolean
		local base = Gold.base(u.name)
		local sealed = Seal.base(u.name) -- still in its pack across the trip (D-427)
		local key = base or sealed or u.name
		local row = Catalog[key]
		if not (row and row.find) then
			return false
		end
		local t: Tool? = nil
		if u.worn and system.boxToHead(system, holder, u.name) then
			local id = heads[holder]
			t = if id then tools[id] else nil
		end
		if not t then
			local _, made = make(holder, key, quiet, u.owner, base ~= nil, nil, sealed ~= nil)
			t = made
			if made and sealed and not made.sealed then
				made.torn = true -- the place lacks its pack: settled as the sealed one
			end
		end
		if not t then
			return false
		end
		t.home = u.owner
		t.up = true
		-- cracked as it left the lobby: drawn on its glass for every screen, quietly (D-296)
		local glass = row.fragile
		if u.cracked and glass and not t.gold then
			t.chipped = true
			Chip.mark(t.model, glass)
			t.model:SetAttribute(Chip.Attribute, true)
		end
		return true
	end

	function system.onHead(_: any, player: Player): (string?, boolean)
		local id = heads[player]
		local t = if id then tools[id] else nil
		if not t then
			return nil, false
		end
		return named(t), t.home == player.UserId
	end

	function system.hangUp(_: any, player: Player, name: string): Vector3?
		local id = heads[player]
		local t = if id then tools[id] else nil
		if not (t and t.home == player.UserId and named(t) == name) then
			return nil
		end
		local at = t.body.Position
		if t.model.Parent then
			glint(at) -- off your head in a glint, as one going back into the box does
		end
		offHead(player)
		tools[t.id] = nil
		grounds[t.id] = nil
		unoffer(t)
		-- back in the box: a crack it took while out comes home with it (D-296)
		taken:fire({
			home = player.UserId,
			name = name,
			how = "Back",
			cracked = t.chipped == true,
			torn = t.torn == true,
		})
		t.owner = nil
		stow(t)
		t.model:Destroy()
		dress(player)
		publish(player)
		changed:fire({ player = player, kind = "Wear" })
		return at
	end

	function system.lower(_: any, id: string, at: Vector3, yaw: number, still: boolean?)
		local t = tools[id]
		if not (t and t.placed) then
			return
		end
		t.placed = nil
		layDown(
			t,
			resting(t.key, at, yaw, t.sealed),
			if still then nil else t.body.CFrame * t.body.PivotOffset
		)
	end

	return system :: any -- any: the table is the Slots shape built field by field above
end

return Slots
