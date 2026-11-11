--!strict
--[[
	KeptPlayers: getting kept on the server (L-07a, the GDD's "Getting kept"), a system. It takes
	`Keepers.caught`: the keeper's hands have closed, the caught player's screen is going black
	(`Caught`, CaughtView), and Keepers has marked them kept (`Kept.Attribute`), so no keeper sees
	them and no prompt answers them (`Prompts.wrapped`).

	At once: everything they carried drops where they stood (`Slots:dropAll`), they're held still
	(their root anchored, so only the server moves them), and the building picks the unit it
	stores them in (`Kept.choose`: a shut unit away from them with nobody and no keeper in it, an
	unopened one first). That unit is never dealt now (`Deals:hold`), so the friend who opens it
	finds only them. Once their screen is black (`Caught.Dark`) they're put inside it, past its
	middle facing the door (`Kept.Back`), and their screen opens on the dark inside. There they
	stand wrapped head to foot in clear film (L-07b): a copy of `Props.KeptWrap` fitted to their
	body at rest (`Kept.fit`), welded on, so the friend who lifts the door finds them in it. Their
	own screen never shows it (CaughtView), and every screen plays the film's squeal (KeptSqueal).

	Inside, they can bang on their door (L-07c, `Remotes.Bang`, `Kept.ready`'s rate): the door
	jolts and thuds as a trapped keeper's does (`Doors:move`, "Bang"), so keepers hear it as they
	hear that, and the floor's model carries the bang (`Kept.BangsAttribute`) so friends' screens
	and corner maps mark the unit however far off they are. They also get `Kept.InsideValue`, the
	unit they're in, for their own screen's light under the door.

	A friend lets them out (L-07d): with the unit's door all the way up, a Cut free button stands
	on the film in front of the kept body (`Kept.CutUp`, `CutAhead`). While a friend holds it the
	film strains (the wrap's `Kept.PullAttribute`, which every screen hears); when the hold lands
	the server judges it (`Kept.cut`: not themselves, not kept, alive, in front of the unit or in
	it and within reach, a full hold) and tears the film off: the wrap is unwelded, left anchored
	where they stand with when it tore, who it freed and who cut (`Kept.TornAttribute` and the
	rest), so every screen plays the rip and its slump to the ankles (CutFreeView), and is gone
	once that's played. The door going up no longer lets anyone out. Leaving, dying or a new
	character lets them go too, as does their floor going away. A catch on a floor this doesn't
	know, or with no unit free, holds them through the wrap and lets them go where they stand.

	Left too long (L-07e), the building padlocks their door. Each keep has a clock
	(`Kept.clock`, `PadlockAfter`) that runs only while the door is down (`Kept.tick`); for its
	last `PadlockWarn` seconds the player carries `Kept.WarnAttribute` (when it goes on), so every
	screen hears a hand work a padlock at the door and counts it down (PadlockView). Run out with
	the door down and still, `Doors:lock` puts the game's own padlock on: the bolt and the click
	on every screen near (DoorSounds), "Padlocked" on its buttons, and `Kept.PadlockedAttribute`
	on the player. From then Cut free waits for a friend's bolt cutters and the door going up.
	One padlock a keep: once it's been on (the building's, or a friend's by hand), the clock is
	done. Let out, the clock stops; a padlock still on stays on the empty unit.

	In Studio only, `ServerStorage.CutFreeTest` (a BindableFunction, server-side, so no client
	reaches it) judges a cut by any body, a stand-in friend for a one-player test:
	`Invoke(keptPlayer, body, heldSeconds)` returns the refusal or "Cut" (docs/STUDIO.md).
	Workspace's `DevPadlockSeconds` attribute (Studio only, `Kept.DevPadlock`) shortens the
	padlock's clock for each keep that starts after it's set.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Deals = require(script.Parent.Deals)
local Doors = require(script.Parent.Doors)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Keepers = require(script.Parent.Keepers)
local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptWrap = require(ReplicatedStorage.Shared.KeptWrap.Specs)
local Prompts = require(script.Parent.Prompts)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)

export type KeptPlayers = Brix.System & {
	-- A laid floor's deck and its units, each by its slot's index (FloorBuilder's `Laid.slots`):
	-- players caught on it are stored in its units, until `floor` (the floor's model) is destroyed.
	add: (self: any, deck: Deal.Deck, units: { [Model]: number }, floor: Instance) -> (),
}

-- A laid floor: its deck, units and their slots, its model (where its bangs are marked for
-- every screen) and each unit's latest bang, by slot.
type Floor = {
	deck: Deal.Deck,
	units: { Model },
	slots: { [Model]: number },
	model: Instance,
	bangs: { [number]: Kept.Bang },
}

-- Someone kept: the character they were caught in, its root (anchored while kept), the unit
-- they're stored in and its floor (nil when there was none), the film round them and the value
-- naming their unit once they're in it (`inside`), and when their last bang landed. Once inside,
-- their Cut free button (`prompt`, on `cutAt`), when each friend's hold on it began (the
-- server's clock) and who is holding it now.
type Held = {
	character: Model,
	root: BasePart,
	unit: Model?,
	floor: Floor?,
	wrap: BasePart?,
	value: ObjectValue?,
	inside: boolean,
	banged: number?,
	cutAt: Attachment?,
	prompt: ProximityPrompt?,
	refuse: ((text: string) -> ())?,
	began: { [Player]: number },
	pulling: { [Player]: true },
	gone: { RBXScriptConnection },
	-- The padlock's clock once they're inside: seconds of counted time left (nil before, and
	-- once a padlock has been on), its warning's lead, the warning's due time as published
	-- (nil while it isn't showing), and whether their door has been padlocked.
	left: number?,
	lead: number,
	due: number?,
	padlocked: boolean,
}

-- What a friend's Cut free shows when the server refuses one they could fix, in place of the kept
-- friend's name for a moment. The rest (themselves, kept, down, the door shut) never offer the
-- button at all.
local CUT_FIX: { [string]: string } = {
	Short = "Hold to cut",
	Far = "Get closer",
	Outside = "Get closer",
}

local function box(size: Vector3, centre: Vector3): Kept.Box
	return { size = { size.X, size.Y, size.Z }, centre = { centre.X, centre.Y, centre.Z } }
end
local DRAWN = box(KeptWrap.Body.Size, KeptWrap.Body.Centre)
local WRAP = box(KeptWrap.Wrap.Size, KeptWrap.Wrap.Centre)

-- The body's box standing at rest, from its root: each body part (the character's own parts, not
-- its hats or hair) placed by its joints' rest offsets, Motor6D or AnimationConstraint, so an
-- arm caught mid-swing doesn't size the wrap. Nil when no part hangs off the root.
local function restBox(character: Model, root: BasePart): Kept.Box?
	local links: { { a: BasePart, b: BasePart, offset: CFrame } } = {}
	for _, j in character:GetDescendants() do
		if j:IsA("Motor6D") then
			local a, b = j.Part0, j.Part1
			if a and b then
				table.insert(links, { a = a, b = b, offset = j.C0 * j.C1:Inverse() })
			end
		elseif j:IsA("AnimationConstraint") then
			local a0, a1 = j.Attachment0, j.Attachment1
			local a, b = a0 and a0.Parent, a1 and a1.Parent
			if a0 and a1 and a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				table.insert(links, { a = a, b = b, offset = a0.CFrame * a1.CFrame:Inverse() })
			end
		end
	end
	local at: { [BasePart]: CFrame } = { [root] = CFrame.identity }
	local found = true
	while found do
		found = false
		for _, l in links do
			local from = at[l.a]
			if from and not at[l.b] then
				at[l.b] = from * l.offset
				found = true
			end
		end
	end
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for part, cf in at do
		if part ~= root and part.Parent == character then
			local h = part.Size / 2
			for _, c in
				{
					Vector3.new(1, 1, 1),
					Vector3.new(1, 1, -1),
					Vector3.new(1, -1, 1),
					Vector3.new(1, -1, -1),
				}
			do
				local p, q = cf * (h * c), cf * (-h * c)
				lo, hi = lo:Min(p):Min(q), hi:Max(p):Max(q)
			end
		end
	end
	if lo.X > hi.X then
		return nil
	end
	return box(hi - lo, (hi + lo) / 2)
end

local KeptPlayers = {}

function KeptPlayers.new(): KeptPlayers
	local floors: { [Instance]: Floor } = {}
	local held: { [Player]: Held } = {}
	local holding: { [Model]: Player } = {} -- each unit's kept player
	local connections: { Brix.SignalConnection } = {}
	local joins: { RBXScriptConnection } = {}
	local doors: Doors.Doors? = nil
	local deals: Deals.Deals? = nil
	local slots: Slots.Slots? = nil
	local keepers: Keepers.Keepers? = nil
	local random = Brix.Random.new({ seed = os.time() })
	local warned = false
	local bangRemote: RemoteEvent? = nil
	local cutTest: BindableFunction? = nil

	-- Puts `floor`'s marks on its model for every screen: the bangs still showing at `now`.
	local function publishBangs(floor: Floor, now: number)
		for slot, b in floor.bangs do
			if Kept.mark(now - b.at) <= 0 then
				floor.bangs[slot] = nil
			end
		end
		floor.model:SetAttribute(Kept.BangsAttribute, Kept.encodeBangs(floor.bangs, now))
	end

	-- Wraps `h`'s body head to foot in film, fitted to it at rest and welded to its root: what a
	-- friend finds when they lift the door. No collision, weight or shadow: it's only seen.
	local function wrapUp(h: Held)
		local props = ReplicatedStorage:FindFirstChild("Props")
		local template = props and props:FindFirstChild(Kept.Wrap)
		if not (template and template:IsA("BasePart")) then
			if not warned then
				warned = true
				warn(
					"KeptPlayers: no ReplicatedStorage.Props.KeptWrap, so the kept stand unwrapped (art/keptwrap/README.md)"
				)
			end
			return
		end
		local fit = Kept.fit(restBox(h.character, h.root) or DRAWN, DRAWN, WRAP)
		local offset = CFrame.new(fit.centre[1], fit.centre[2], fit.centre[3])
		local wrap = template:Clone()
		wrap.Size = Vector3.new(fit.size[1], fit.size[2], fit.size[3])
		wrap.Anchored = false
		wrap.CanCollide, wrap.CanTouch, wrap.CanQuery = false, false, false
		wrap.Massless = true
		wrap.CastShadow = false
		wrap.Transparency = Kept.WrapBlend
		wrap.CFrame = h.root.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1, weld.C0 = h.root, wrap, offset
		weld.Parent = wrap
		wrap:AddTag(Kept.WrapTag) -- so every screen finds it for the strain and the tear
		wrap.Parent = h.character
		h.wrap = wrap
	end

	-- Tears `h`'s film off `player`, cut free by `cutter` (a UserId, 0 for none): unwelded and left
	-- standing where they stood, so every screen plays the rip and the slump (CutFreeView) from
	-- when it tore; gone once that has played.
	local function tear(h: Held, player: Player, cutter: number)
		local wrap = h.wrap
		if not wrap then
			return
		end
		h.wrap = nil
		wrap.Anchored = true
		for _, j in wrap:GetChildren() do
			if j:IsA("JointInstance") then
				j:Destroy()
			end
		end
		wrap:SetAttribute(Kept.PullAttribute, nil)
		wrap:SetAttribute(Kept.FreedAttribute, player.UserId)
		wrap:SetAttribute(Kept.CutterAttribute, cutter)
		-- it lists toward the door, a little to one side or the other
		wrap:SetAttribute(Kept.LeanAttribute, (random:nextNumber() - 0.5) * math.rad(70))
		wrap:SetAttribute(Kept.TornAttribute, Workspace:GetServerTimeNow())
		wrap.Parent = Workspace
		task.delay(Kept.tearLength() + 0.5, function()
			wrap:Destroy()
		end)
	end

	-- Lets `player` go: their root free, the kept mark off (their screen opens up, keepers see
	-- them again), their unit free for the next. Cut free (`cutter`, a UserId, 0 for none), the
	-- film is torn off them; any other way it just goes.
	local function letGo(player: Player, why: string, cutter: number?)
		local h = held[player]
		if not h then
			return
		end
		held[player] = nil
		for _, c in h.gone do
			c:Disconnect()
		end
		if h.unit and holding[h.unit] == player then
			holding[h.unit] = nil
		end
		if h.cutAt then
			h.cutAt:Destroy() -- and its button
		end
		if h.wrap then
			if cutter then
				tear(h, player, cutter)
			else
				h.wrap:Destroy()
			end
		end
		if h.value then
			h.value:Destroy()
		end
		-- out: the clock stops, and the lines about them go (a padlock on stays on the unit)
		h.left, h.due = nil, nil
		if player.Parent then
			player:SetAttribute(Kept.WarnAttribute, nil)
			player:SetAttribute(Kept.PadlockedAttribute, nil)
		end
		-- out: their unit stops marking for friends at once
		local floor, unit = h.floor, h.unit
		local slot = if floor and unit then floor.slots[unit] else nil
		if floor and slot and floor.bangs[slot] and floor.model.Parent then
			floor.bangs[slot] = nil
			publishBangs(floor, Workspace:GetServerTimeNow())
		end
		if h.root.Parent then
			h.root.Anchored = false
		end
		if player.Parent then
			player:SetAttribute(Kept.Attribute, nil)
		end
		if RunService:IsStudio() then
			print(`KeptPlayers: {player.Name} is let out ({why})`)
		end
	end

	-- Whether a keeper's feet stand inside `unit` (face: its door's outer face) of `depth` and
	-- `width` studs: a keeper trapped or roaming in it, whatever its deal said.
	local function keeperIn(face: CFrame, width: number, depth: number): boolean
		local k = keepers
		if not k then
			return false
		end
		local found = false
		k:feet(function(_body: Model, at: Vector3)
			local p = face:PointToObjectSpace(at)
			if math.abs(p.X) < width / 2 and p.Z > 0 and p.Z < depth and math.abs(p.Y) < 4 then
				found = true
			end
		end)
		return found
	end

	-- The unit on `floor` the building stores someone caught at `at` in, or nil.
	local function pick(floor: Floor, at: Vector3): Model?
		local d = doors
		if not d then
			return nil
		end
		local deck = floor.deck
		local list: { Kept.Unit } = {}
		for i, unit in floor.units do
			local index = floor.slots[unit]
			local spec = Specs[deck.floor.slots[index].size]
			local face = FloorBuilder.face(unit)
			local contents = deck.dealt[index]
			list[i] = {
				x = face.Position.X,
				z = face.Position.Z,
				shut = d:stateOf(unit) == "Closed",
				dealt = contents ~= nil,
				keeper = (if contents
					then contents.kind == "Asleep" or contents.kind == "Awake"
					else index == deck.guarded) or keeperIn(face, spec.Width, spec.Depth),
				holding = if holding[unit] then true else false,
			}
		end
		local i = Kept.choose(list, at.X, at.Z, random)
		return if i then floor.units[i] else nil
	end

	-- Where in `unit` its kept player stands: past its middle, facing the door, feet on its floor,
	-- for a root `rootHeight` studs over the feet.
	local function inside(floor: Floor, unit: Model, rootHeight: number): CFrame
		local index = floor.slots[unit]
		local spec = Specs[floor.deck.floor.slots[index].size]
		return FloorBuilder.face(unit) * CFrame.new(0, rootHeight, spec.Depth * Kept.Back)
	end

	-- Whether `h`'s door is all the way up: the only time their Cut free shows.
	local function doorUp(h: Held): boolean
		local d, unit = doors, h.unit
		return d ~= nil and unit ~= nil and d:stateOf(unit) == "Open"
	end

	-- `h`'s film strains while friends hold Cut free on it: how many, for every screen to hear.
	local function setPull(h: Held)
		local wrap = h.wrap
		if not wrap then
			return
		end
		local n = 0
		for _ in h.pulling do
			n += 1
		end
		wrap:SetAttribute(Kept.PullAttribute, if n > 0 then n else nil)
	end

	-- What stops `body` (a friend's character; `cutter` its player, nil for Studio's stand-in)
	-- cutting `kept` free now, after holding `heldFor` seconds: nil when nothing does
	-- (`Kept.cut`). Places go into the kept unit's frame, its door's outer face at the floor.
	local function judge(
		kept: Player,
		h: Held,
		cutter: Player?,
		body: Model?,
		heldFor: number?
	): Kept.CutRefusal?
		local floor, unit, cutAt = h.floor, h.unit, h.cutAt
		local found = body and body:FindFirstChild("HumanoidRootPart")
		local root = if found and found:IsA("BasePart") then found else nil
		local humanoid = body and body:FindFirstChildOfClass("Humanoid")
		local at, cut, width, depth = { 0, 0, 0 }, { 0, 0, 0 }, 0, 0
		if floor and unit and cutAt then
			local spec = Specs[floor.deck.floor.slots[floor.slots[unit]].size]
			local face = FloorBuilder.face(unit)
			width, depth = spec.Width, spec.Depth
			local c = face:PointToObjectSpace(cutAt.WorldPosition)
			cut = { c.X, c.Y, c.Z }
			if root then
				local p = face:PointToObjectSpace(root.Position)
				at = { p.X, p.Y, p.Z }
			end
		end
		return Kept.cut({
			self = cutter == kept or body == h.character,
			alive = root ~= nil and humanoid ~= nil and humanoid.Health > 0,
			kept = cutter ~= nil and Prompts.wrapped(cutter),
			inside = h.inside and cutAt ~= nil,
			open = doorUp(h),
			held = heldFor,
			at = at,
			cut = cut,
			width = width,
			depth = depth,
		})
	end

	-- Puts `player`'s Cut free button on the film in front of them, shown while their door is all
	-- the way up. A friend's hold strains the film; when it lands the server judges it and, if
	-- it stands, tears the film off and lets them go.
	local function armCut(player: Player, h: Held)
		local at = Instance.new("Attachment")
		at.Name = "CutFree"
		at.CFrame = CFrame.new(0, Kept.CutUp, -Kept.CutAhead)
		at.Parent = h.root
		local p = Prompts.make(at, {
			objectText = player.DisplayName,
			actionText = Kept.CutText,
			key = Enum.KeyCode.E, -- Open's, which never shows on a door that's all the way up
			pad = Enum.KeyCode.ButtonX,
			reach = Kept.CutReach,
			hold = Kept.CutHold,
		})
		p.Enabled = doorUp(h)
		h.cutAt, h.prompt = at, p
		h.refuse = Prompts.refuser(p, function()
			return player.DisplayName
		end)
		table.insert(
			h.gone,
			p.PromptButtonHoldBegan:Connect(function(cutter: Player)
				if held[player] ~= h or cutter == player or Prompts.wrapped(cutter) then
					return
				end
				h.began[cutter] = Workspace:GetServerTimeNow()
				h.pulling[cutter] = true
				setPull(h)
			end)
		)
		table.insert(
			h.gone,
			p.PromptButtonHoldEnded:Connect(function(cutter: Player)
				local b = h.began[cutter]
				-- a hold let go early never counts toward a later trigger
				if b and Workspace:GetServerTimeNow() - b < Kept.CutHold - Kept.CutSlack then
					h.began[cutter] = nil
				end
				if h.pulling[cutter] then
					h.pulling[cutter] = nil
					setPull(h)
				end
			end)
		)
		table.insert(
			h.gone,
			p.Triggered:Connect(function(cutter: Player)
				if held[player] ~= h then
					return
				end
				local b = h.began[cutter]
				h.began[cutter] = nil
				if h.pulling[cutter] then
					h.pulling[cutter] = nil
					setPull(h)
				end
				local heldFor = if b then Workspace:GetServerTimeNow() - b else nil
				local why = judge(player, h, cutter, cutter.Character, heldFor)
				if why then
					local fix, refuse = CUT_FIX[why], h.refuse
					if fix and refuse then
						refuse(fix)
					end
					if RunService:IsStudio() then
						print(
							`KeptPlayers: {cutter.Name}'s Cut free on {player.Name} refused ({why})`
						)
					end
					return
				end
				letGo(player, `{cutter.Name} cut them free`, cutter.UserId)
			end)
		)
	end

	local function onCaught(catch: Keepers.Catch)
		local player = catch.player
		if held[player] or not player.Parent then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (character and root and root:IsA("BasePart") and humanoid) then
			player:SetAttribute(Kept.Attribute, nil)
			return
		end
		-- what you carried drops where you stood, before you're held
		if slots then
			slots:dropAll(player)
		end
		root.Anchored = true
		local floor = floors[catch.floor]
		local unit = if floor then pick(floor, root.Position) else nil
		local h: Held = {
			character = character,
			root = root,
			unit = unit,
			floor = if unit then floor else nil,
			inside = false,
			began = {},
			pulling = {},
			gone = {},
			lead = 0,
			padlocked = false,
		}
		held[player] = h
		table.insert(
			h.gone,
			humanoid.Died:Connect(function()
				letGo(player, "died")
			end)
		)
		table.insert(
			h.gone,
			character.AncestryChanged:Connect(function()
				if not character.Parent then
					letGo(player, "their character went")
				end
			end)
		)
		if not (floor and unit) then
			if RunService:IsStudio() then
				print(
					`KeptPlayers: no unit free for {player.Name}; held through the wrap where they stand`
				)
			end
			task.delay(Caught.Wrap, function()
				if held[player] == h then
					letGo(player, "no unit to keep them in")
				end
			end)
			return
		end
		holding[unit] = player
		if deals then
			deals:hold(unit)
		end
		local to = inside(floor, unit, humanoid.HipHeight + root.Size.Y / 2)
		-- the unit may be far off: start streaming it in around them while the screen goes black;
		-- held anchored, they can't fall if it isn't in yet
		task.spawn(function()
			local ok, err = pcall(function()
				player:RequestStreamAroundAsync(to.Position)
			end)
			if not ok then
				warn(`KeptPlayers: couldn't stream around {unit.Name} for {player.Name}: {err}`)
			end
		end)
		task.delay(Caught.Dark, function()
			if held[player] ~= h or not character.Parent then
				return
			end
			character:PivotTo(to)
			wrapUp(h)
			h.inside = true
			local dev = Workspace:GetAttribute(Kept.DevPadlock)
			h.left, h.lead =
				Kept.clock(if RunService:IsStudio() and type(dev) == "number" then dev else nil)
			armCut(player, h)
			local value = Instance.new("ObjectValue")
			value.Name = Kept.InsideValue
			value.Value = unit
			value.Parent = player
			h.value = value
			if RunService:IsStudio() then
				print(`KeptPlayers: {player.Name} is wrapped and kept in {unit.Name}`)
			end
		end)
	end

	-- Remotes.Bang: a kept player hits their door. Nothing to check for type (it takes nothing);
	-- range: kept and inside their unit (not in the black on the way there); then the rate, one
	-- bang a door's jolt with a little slack (`Kept.ready`). The door jolts and thuds on every
	-- screen near, and keepers hear it, as a trapped keeper's blow (`Doors:move`); the floor marks
	-- the unit for friends' screens and maps.
	local function onBang(player: Player)
		local h = held[player]
		local floor, unit, d = h and h.floor, h and h.unit, doors
		if not (h and h.inside and floor and unit and d) then
			return
		end
		local now = Workspace:GetServerTimeNow()
		if not Kept.ready(h.banged, now, Kept.BangSlack) then
			return
		end
		local was = h.banged
		h.banged = now
		if not d:move(unit, "Bang") then
			return -- its door is on its way up or down: nothing to hit
		end
		local slot = floor.slots[unit]
		local at = FloorBuilder.face(unit).Position
		floor.bangs[slot] =
			{ slot = slot, user = player.UserId, at = now, x = at.X, y = at.Y, z = at.Z }
		publishBangs(floor, now)
		if RunService:IsStudio() and (was == nil or Kept.mark(now - was) <= 0) then
			print(`KeptPlayers: {player.Name} bangs on {unit.Name}'s door`)
		end
	end

	-- `h`'s door has been padlocked (`byBuilding`: the clock ran out; else by a friend's hand):
	-- the clock is done, the countdown goes, and every screen knows it's on.
	local function markPadlocked(player: Player, h: Held, byBuilding: boolean)
		h.padlocked, h.left, h.due = true, nil, nil
		player:SetAttribute(Kept.WarnAttribute, nil)
		player:SetAttribute(Kept.PadlockedAttribute, true)
		if RunService:IsStudio() then
			local by = if byBuilding then "the building" else "hand"
			print(`KeptPlayers: {player.Name}'s door is padlocked by {by}`)
		end
	end

	-- A kept player's Cut free shows only while their door is all the way up; a padlock on their
	-- door cut off clears their Padlocked.
	local function onChanged(change: Doors.DoorChange)
		local player = holding[change.unit]
		local h = player and held[player]
		if not (player and h) then
			return
		end
		local p = h.prompt
		if p then
			p.Enabled = change.state == "Open"
		end
		if change.state ~= "Locked" and player:GetAttribute(Kept.PadlockedAttribute) ~= nil then
			player:SetAttribute(Kept.PadlockedAttribute, nil)
			if RunService:IsStudio() then
				print(`KeptPlayers: the padlock on {player.Name}'s door is off`)
			end
		end
	end

	-- Each kept player's padlock clock, on the server's (`Kept.tick`): it runs while their door is
	-- down, warns for its last stretch (`Kept.WarnAttribute`, set as the warning starts or
	-- comes back after the door's been up, cleared while it's up), and padlocks the door once
	-- it's out with the door down and still. A door padlocked by hand first ends the clock too.
	local function stepClocks(dt: number)
		local d = doors
		if not d then
			return
		end
		for player, h in held do
			local unit, left = h.unit, h.left
			if not (h.inside and unit and left) then
				continue
			end
			local state = d:stateOf(unit)
			if state == "Locked" then
				markPadlocked(player, h, false)
				continue
			end
			local now = Workspace:GetServerTimeNow()
			local warning, lock
			left, warning, lock = Kept.tick(left, h.lead, dt, state)
			h.left = left
			if warning and not h.due then
				h.due = now + left
				player:SetAttribute(Kept.WarnAttribute, h.due)
				if RunService:IsStudio() then
					print(
						`KeptPlayers: a padlock's coming for {player.Name} in {Kept.seconds(left)} s`
					)
				end
			elseif not warning and h.due then
				h.due = nil
				player:SetAttribute(Kept.WarnAttribute, nil)
			end
			-- refused while the door still jolts from a bang: tried again next step
			if lock and d:lock(unit, true) then
				markPadlocked(player, h, true)
			end
		end
	end

	local system = { name = "KeptPlayers" }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Doors, Deals, Slots and Keepers fill these
		doors = (context.registry:get("doors") :: any) :: Doors.Doors?
		deals = (context.registry:get("deals") :: any) :: Deals.Deals?
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers?
		local k = keepers
		if k then
			table.insert(connections, k.caught:connect(onCaught))
		else
			warn("KeptPlayers: no Keepers system, so nobody is ever kept")
		end
		local d = doors
		if d then
			table.insert(connections, d.changed:connect(onChanged))
		end
		table.insert(
			joins,
			Players.PlayerRemoving:Connect(function(player: Player)
				letGo(player, "left")
				-- a friend who leaves mid-hold lets go of the film
				for _, h in held do
					h.began[player] = nil
					if h.pulling[player] then
						h.pulling[player] = nil
						setPull(h)
					end
				end
			end)
		)
		local folder = ReplicatedStorage:FindFirstChild(Caught.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Caught.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = Kept.BangRemote
		remote.Parent = folder
		bangRemote = remote
		table.insert(joins, remote.OnServerEvent:Connect(onBang))
		if RunService:IsStudio() then
			-- a stand-in friend for a one-player test: judges a cut by any body
			local test = Instance.new("BindableFunction")
			test.Name = "CutFreeTest"
			-- any: a BindableFunction's arguments, checked here
			test.OnInvoke = function(kept: any, body: any, heldFor: any): string
				local h = if typeof(kept) == "Instance" and kept:IsA("Player")
					then held[kept]
					else nil
				if not h or typeof(body) ~= "Instance" or not body:IsA("Model") then
					return "NotKept"
				end
				local why =
					judge(kept, h, nil, body, if type(heldFor) == "number" then heldFor else nil)
				if why then
					print(`KeptPlayers: a stand-in's Cut free on {kept.Name} refused ({why})`)
					return why
				end
				letGo(kept, `a stand-in, {body.Name}, cut them free`, 0)
				return "Cut"
			end
			test.Parent = ServerStorage
			cutTest = test
		end
	end

	function system.step(_: any, dt: number)
		if next(held) ~= nil then
			stepClocks(dt)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in joins do
			c:Disconnect()
		end
		table.clear(joins)
		for player in held do
			letGo(player, "the server stopped")
		end
		table.clear(floors)
		if bangRemote then
			bangRemote:Destroy()
			bangRemote = nil
		end
		if cutTest then
			cutTest:Destroy()
			cutTest = nil
		end
	end

	function system.add(_: any, deck: Deal.Deck, laid: { [Model]: number }, floor: Instance)
		local units: { Model } = {}
		for unit in laid do
			table.insert(units, unit)
		end
		-- a steady order, so a seed's choices don't hang on how the table iterates
		table.sort(units, function(a: Model, b: Model)
			return laid[a] < laid[b]
		end)
		floors[floor] = { deck = deck, units = units, slots = laid, model = floor, bangs = {} }
		floor.Destroying:Once(function()
			floors[floor] = nil
			for player, h in held do
				if h.unit and laid[h.unit] then
					letGo(player, "their floor went")
				end
			end
		end)
	end

	return system
end

return KeptPlayers
