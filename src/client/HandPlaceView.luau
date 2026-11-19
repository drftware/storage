--!strict
--[[
	HandPlaceView: placing a held find where you look in your own home, without opening Arrange
	(S5-03j5a, D-463; the plan's "Placing by hand"). The moment: holding the teddy, you look at the
	job box's top and a faint teddy sits there, snapped and turned to the room; the Drop button
	reads Place, and one press sets it down with the landing's knock and puff, as heavy as it is.
	Precedents: Grow a Garden's held egg or seed shown where it will go, Minecraft's outline of the
	block before you place it, Animal Crossing's and The Sims' place-from-hand.

	ToolView owns one: it says what your hand holds out (`hold`), asks whether Place is up
	(`showing`) and hands it the Drop button's press (`place`); `changed` tells it when to swap the
	button's word. Where it would go is PlaceAim's, the one aim and judge Arrange drags with, along
	the camera's look. Nowhere it fits (or out of reach, or outside your home) nothing shows and
	Drop drops as ever; no text explains anything.

	A find you Take keeps its spot (S5-03j5b1, D-465): while it's in your hand in your home, a
	fainter, still copy stands where it stood (the slot's `HandPlace.keptAttribute`, the server's),
	and a look that passes within a step of it (`HandPlace.snaps`) clicks the copy into that very
	spot, turned as it stood. Something now in its way, and it isn't shown. Precedent: The Sims'
	and Animal Crossing's picked-up furniture leaving its footprint to drop back into.

	Only while you hold a find out of your own box in your home does anything step: one
	RenderStepped, connected for that hold and gone with it.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local ArrangeHand = require(script.Parent.ArrangeHand)
local ArrangeTaps = require(script.Parent.ArrangeTaps)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local HandPlace = require(ReplicatedStorage.Shared.Home.HandPlace)
local PlaceAim = require(script.Parent.PlaceAim)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local Feel = Arrange.Feel
local LAND = TweenInfo.new(Feel.Land, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local ANSWER_WAIT = 3 -- seconds: no answer by then, the copy fades back as if refused
local LOOK = 64 -- studs: how far the look ray goes
-- studs past what the look hits first that a surface still counts: a top or the floor you look
-- at is hit at its own face, never past it (a box's side hides the floor behind it)
local PAST = 0.3
local SEE_THROUGH = 3 -- unseen parts (a collider, a sign's box) the look passes before giving up

export type HandPlaceView = {
	-- What your hand holds out: its catalog key ("" for nothing or pocketed) and its slot.
	hold: (key: string, slot: number) -> (),
	-- Whether the faint copy is showing, so Drop reads Place.
	showing: () -> boolean,
	-- Drop's press: sets the held find on the copy's spot. False when the copy isn't showing (Drop
	-- drops as ever).
	place: () -> boolean,
	destroy: () -> (),
}

local HandPlaceView = {}

-- `changed(showing)` fires as the copy comes and goes (ToolView swaps Drop's word).
function HandPlaceView.new(changed: (showing: boolean) -> ()): HandPlaceView
	local me = Players.LocalPlayer
	local taps = ArrangeTaps.new()
	local tops: { [string]: boolean } = {}
	local key, slot, own = "", 0, false
	local room: Arrange.Room? = nil
	local unit: Model? = nil
	local carried: PlaceAim.Carried? = nil
	local name = "" -- the held find's name in the save (a Gold's "Teddy:Gold")
	local copy: Model? = nil
	local parts: { BasePart } = {}
	local solid: { number } = {} -- each part's own transparency, as the find is drawn
	local shown = false
	local alpha = 0 -- how far the copy has faded in (0 gone, 1 faint)
	-- the kept spot (S5-03j5b1): where it stood when Taken, its still copy, and whether the look
	-- has snapped into it
	local kept: HandPlace.Pose? = nil
	local keptCopy: Model? = nil
	local keptParts: { BasePart } = {}
	local keptSolid: { number } = {}
	local keptAlpha = 0
	local snapped = false
	local asking = false
	local step: RBXScriptConnection? = nil
	local watch: { RBXScriptConnection } = {}
	local answer: RBXScriptConnection? = nil
	local remote: RemoteEvent? = nil -- HandPlace's ask, found as the screen starts
	-- the look's raycast: you, the copy (in the camera) and your hand's view are never in its way
	local looking = RaycastParams.new()
	looking.FilterType = Enum.RaycastFilterType.Exclude

	local function sounds(): Instance
		return me:FindFirstChildOfClass("PlayerGui") or me
	end

	local function setShown(on: boolean)
		if shown ~= on then
			shown = on
			changed(on)
		end
	end

	-- The copy's parts at `a` of the way to faint (0: unseen), breathing as it shows.
	local function fade(a: number)
		local breath = math.sin(os.clock() * (2 * math.pi / HandPlace.Breath))
		local faint = HandPlace.Faint + HandPlace.Breathe * breath
		for i, p in parts do
			p.Transparency = 1 - (1 - solid[i]) * (1 - faint) * a
		end
	end

	-- The kept spot's copy at `a` of the way to its fainter, still look (0: unseen).
	local function fadeKept(a: number)
		for i, p in keptParts do
			p.Transparency = 1 - (1 - keptSolid[i]) * (1 - HandPlace.KeptFaint) * a
		end
	end

	local function dropCopy()
		local c, k = copy, keptCopy
		copy, keptCopy = nil, nil
		table.clear(parts)
		table.clear(solid)
		table.clear(keptParts)
		table.clear(keptSolid)
		alpha, keptAlpha, snapped = 0, 0, false
		if c then
			c:Destroy()
		end
		if k then
			k:Destroy()
		end
	end

	-- A copy of the held find to show faintly: inert, untagged, gilded if it's a Gold; its parts
	-- and their own transparencies go into `into` and `drawnAs`.
	local function ghost(gold: boolean, into: { BasePart }, drawnAs: { number }): Model?
		local m = Tools.clone(key, CFrame.identity)
		if not m then
			return nil
		end
		ArrangeHand.inert(m)
		for _, tag in m:GetTags() do
			m:RemoveTag(tag)
		end
		if gold then
			Gold.gild(m)
		end
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(into, d)
				table.insert(drawnAs, d.Transparency)
			end
		end
		return m
	end

	-- Your own home, if you hold one.
	local function findHome(): Model?
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			if inst:IsA("Model") and inst:GetAttribute(Door.HolderAttribute) == me.UserId then
				return inst
			end
		end
		return nil
	end

	-- The room's judge again, from what's drawn now (a find set out, moved or taken).
	local function rebuild()
		local u = unit
		room = if u then PlaceAim.room(u, tops) else nil
		local r, c = room, carried
		if r and c then
			c.id = Spots.nextId(name, function(each: string): boolean
				return r.placements:poseOf(each) ~= nil
			end)
		end
	end

	-- Whether you stand inside your home's room now.
	local function standingIn(r: Arrange.Room, root: BasePart): boolean
		return HandPlace.inside(r.face, r.centre, r.size, root.Position)
	end

	-- How far along the look (studs) the first thing you can see is: the aim stops there, so the
	-- copy goes only where you see a surface, never behind a wall, a box's side or out the door.
	local function seen(look: CFrame): number
		for _ = 0, SEE_THROUGH do
			local hit = Workspace:Raycast(look.Position, look.LookVector * LOOK, looking)
			if not hit then
				return LOOK
			end
			if hit.Instance.Transparency < 1 then
				return hit.Distance + PAST
			end
			looking:AddToFilter(hit.Instance)
		end
		return 0
	end

	local function frame(dt: number)
		local r, c, m, camera = room, carried, copy, Workspace.CurrentCamera
		local character = me.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not (r and c and m and camera and root and root:IsA("BasePart")) then
			return
		end
		if asking then
			return -- set down: the copy is landing
		end
		local pose: Brix.PlacementPose? = nil
		local keptAt: CFrame? = nil -- where the kept spot's copy stands, while it still fits
		local snap = false
		if standingIn(r, root) then
			local look = camera.CFrame
			local far = seen(look)
			local k = kept
			if k and PlaceAim.fitsAt(r, c, k) then
				keptAt = PlaceAim.standAt(r, c, k)
			end
			local ka = keptAt
			if k and ka and HandPlace.snaps(look.Position, look.LookVector, far, ka * c.centre) then
				pose, snap = k, true -- a look back at where it stood: into that very spot
			else
				local on, x, y = PlaceAim.aim(
					r,
					c,
					Ray.new(look.Position, look.LookVector),
					tops,
					{ slack = 0, far = far }
				)
				pose = if on then PlaceAim.settle(r, c, on, x, y, false) else nil
			end
		end
		local at = if pose and PlaceAim.fitsAt(r, c, pose)
			then PlaceAim.standAt(r, c, pose)
			else nil
		local stand = if pose then Arrange.frameOn(r, pose.on) else nil
		local spot = if pose and stand
			then Arranged.pose(stand, pose.x, pose.y, pose.turn).Position
			else nil
		if at and spot and (spot - root.Position).Magnitude > HandPlace.Reach then
			at = nil -- out of reach: nothing shows
		end
		snap = snap and at ~= nil
		c.pose = if at then pose else nil
		if at then
			local was = m:GetPivot()
			-- into the kept spot it clicks, no glide: the tick and a clear tap say it's home
			local k = if alpha <= 0 or (snap and not snapped)
				then 1
				else math.min(1, dt / HandPlace.Glide)
			m:PivotTo(was:Lerp(at, k))
			alpha = math.min(1, alpha + dt / HandPlace.Fade)
		else
			alpha = math.max(0, alpha - dt / HandPlace.Fade)
		end
		if snap and not snapped then
			ArrangeHand.play(Arrange.Tick, sounds())
			taps.tap(Feedback.Taps.Tap)
		end
		snapped = snap
		fade(alpha)
		-- the kept spot's still copy, while it fits and the look isn't in it (the faint copy is)
		local kc = keptCopy
		if kc then
			local ka = keptAt
			if ka and not snap then
				if keptAlpha <= 0 then
					kc:PivotTo(ka)
				end
				keptAlpha = math.min(1, keptAlpha + dt / HandPlace.Fade)
			else
				keptAlpha = math.max(0, keptAlpha - dt / HandPlace.Fade)
			end
			fadeKept(keptAlpha)
		end
		setShown(at ~= nil)
	end

	local function stop()
		if step then
			step:Disconnect()
			step = nil
		end
		for _, w in watch do
			w:Disconnect()
		end
		table.clear(watch)
		dropCopy()
		carried, room, unit, kept = nil, nil, nil, nil
		setShown(false)
	end

	-- Starts aiming the find `key` in slot `slot` when it's out of your own box and you hold a home.
	local function start()
		local u = if own then findHome() else nil
		local gold = me:GetAttribute(Gold.slotAttribute(slot)) == true
		local m = if u then ghost(gold, parts, solid) else nil
		if not (u and m) then
			table.clear(parts)
			table.clear(solid)
			return
		end
		name = if gold then Gold.key(key) else key
		local size, centre = Arranged.bounds(m)
		unit = u
		rebuild()
		local r = room
		local probe = if r
			then Spots.nextId(name, function(each: string): boolean
				return r.placements:poseOf(each) ~= nil
			end)
			else nil
		local shape = if probe then Arrange.shapeOf(probe) else nil
		if not (r and probe and shape and size and centre) then
			m:Destroy()
			table.clear(parts)
			table.clear(solid)
			room, unit = nil, nil
			return
		end
		copy = m
		fade(0)
		m.Parent = Workspace.CurrentCamera
		-- the kept spot's still copy, drawn only while the server keeps a spot for this slot
		local keptName = HandPlace.keptAttribute(slot)
		local function readKept()
			kept = HandPlace.decode(me:GetAttribute(keptName))
			if kept and not keptCopy then
				local k = ghost(gold, keptParts, keptSolid)
				if k then
					keptCopy = k
					fadeKept(0)
					k.Parent = Workspace.CurrentCamera
				end
			end
		end
		readKept()
		table.insert(watch, me:GetAttributeChangedSignal(keptName):Connect(readKept))
		local mine: { Instance } = { Workspace.CurrentCamera }
		if me.Character then
			table.insert(mine, me.Character)
		end
		for _, viewName in { "YourTool", "YourInfrared" } do -- ToolView's views of your hand
			local view = Workspace:FindFirstChild(viewName)
			if view then
				table.insert(mine, view)
			end
		end
		looking.FilterDescendantsInstances = mine
		carried = {
			id = probe,
			shape = shape,
			spot = Spots.spot(name),
			size = size,
			centre = centre,
			starter = nil,
			pose = nil,
			turn = 0, -- faces the room's door, as a find set out at its first turn does
			backs = false,
			wall = nil,
			lines = PlaceAim.lines(),
		}
		-- what's drawn changes (set out, moved, taken): the judge is laid again
		local folder = u:FindFirstChild(Arrange.Folder)
		if folder then
			table.insert(watch, folder.ChildAdded:Connect(rebuild))
			table.insert(watch, folder.ChildRemoved:Connect(rebuild))
		end
		table.insert(watch, u:GetAttributeChangedSignal(Spots.SizeAttribute):Connect(rebuild))
		step = RunService.RenderStepped:Connect(frame)
	end

	local function hold(k: string, s: number)
		local o = k ~= "" and me:GetAttribute(HandPlace.slotAttribute(s)) == true
		if k == key and s == slot and o == own then
			return
		end
		stop()
		key, slot, own = k, s, o
		if o then
			start()
		end
	end

	-- Aims the same find again from scratch (a set-down refused: it's still in your hand).
	local function again()
		stop()
		if own and key ~= "" then
			start()
		end
	end

	-- The set-down's copy, landing on its spot while the server's word comes: gone once both
	-- have happened (set down: the drawn find stands where it landed). Refused, or no word, it
	-- goes and a fresh faint copy aims again: the find is still in your hand.
	local landing: { model: Model, landed: boolean, answered: boolean, ok: boolean }? = nil

	local function finishLanding()
		local l = landing
		if not (l and l.landed and l.answered) then
			return
		end
		landing = nil
		asking = false
		l.model:Destroy()
		if not l.ok then
			again()
		end
	end

	local function answered(id: unknown, refusal: unknown)
		local l = landing
		if l and not l.answered then
			l.answered = true
			l.ok = type(id) == "string" and id ~= "" and refusal == ""
			finishLanding()
		end
	end

	local function place(): boolean
		local r, c, m, ask = room, carried, copy, remote
		local pose = if c then c.pose else nil
		if not (r and c and m and ask and pose and shown) or asking then
			return false
		end
		local at = PlaceAim.standAt(r, c, pose)
		if not at then
			return false
		end
		asking = true
		ask:FireServer(pose.on, pose.x, pose.y, pose.turn)
		-- the copy leaves the hold's keeping: it lands even as your hand empties
		for i, part in parts do
			part.Transparency = solid[i] -- as solid as the find is drawn
		end
		copy = nil
		table.clear(parts)
		table.clear(solid)
		alpha = 0
		local l = { model = m, landed = false, answered = false, ok = false }
		landing = l
		-- it drops the last hair onto its spot, then lands as heavy as it is
		local band = Feedback.landing(name)
		local stand = Arrange.frameOn(r, pose.on)
		local base = if stand then Arranged.pose(stand, pose.x, pose.y, pose.turn) else at
		m:PivotTo(at + base.YVector * Feel.Drop * 0.5)
		local cf = Instance.new("CFrameValue")
		cf.Value = m:GetPivot()
		cf.Changed:Connect(function(v: CFrame)
			m:PivotTo(v)
		end)
		local t = TweenService:Create(cf, LAND, { Value = at })
		t.Completed:Once(function()
			cf:Destroy()
			ArrangeHand.play(band.thud, sounds())
			taps.tap(band.tap)
			ArrangeHand.puff(base, band)
			l.landed = true
			finishLanding()
		end)
		t:Play()
		task.delay(ANSWER_WAIT, function()
			if landing == l then
				answered("", "noAnswer") -- no word: as if refused, it's still in your hand
			end
		end)
		setShown(false)
		return true
	end

	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild(Spots.RemoteFolder, 60)
		local r = if folder then folder:WaitForChild(HandPlace.Remote, 60) else nil
		if r and r:IsA("RemoteEvent") then
			remote = r
			answer = r.OnClientEvent:Connect(answered)
		end
	end)

	return {
		hold = hold,
		showing = function(): boolean
			return shown
		end,
		place = place,
		destroy = function()
			stop()
			local l = landing
			if l then
				l.model:Destroy()
				landing = nil
			end
			if answer then
				answer:Disconnect()
				answer = nil
			end
			taps.destroy()
		end,
	}
end

return HandPlaceView
