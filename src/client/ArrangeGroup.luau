--!strict
--[[
	ArrangeGroup (S5-03j6b2, D-469): several things lit by the box (ArrangeBox), carried, turned and
	put away as one in Arrange, the room editor (D-436). The moment, The Sims 4's build-mode
	multi-select: three things lit, you drag the crate and the lamp and the rug come along keeping
	their places round it, green or red all together; let go and all three land, each with its thud
	by weight, as one move; one Undo puts all three back.

	What moves where is `Home/Group` (pure): the finger's slide on the floor, snapped to the grid,
	becomes `Group.moved`; Turn is `Group.turned` (a quarter about the group's middle). The room's
	own judge (Brix's Placements, as the hand's) says green or red: `Group.apply` is tried on it and
	then undone, so the group is judged exactly as the server will judge it. One ghost per lit thing
	(what rides on it copied inside, as the hand's lift does) stands in while it moves; the drawn
	things hide, the box's glows dim. Things on a wall stay where they hang (D-468). Names no find:
	what a thing weighs and whether it's the job box come from its rows.

	ArrangeView makes one, hands it drags that begin on a lit thing, routes the ring's Turn and Put
	away to it while the box has things lit, and sends a group's undo or redo (`History.Ask.more`)
	to `replay`. Only the ghosts step, and only while they're moving.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ArrangeHand = require(script.Parent.ArrangeHand)
local ArrangeRing = require(script.Parent.ArrangeRing)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Group = require(ReplicatedStorage.Shared.Home.Group)
local History = require(ReplicatedStorage.Shared.Home.History)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)

local Feel = Arrange.Feel

local FITS = Color3.fromRGB(126, 214, 150) -- the hand's soft green: they can all stand there
local REFUSED = Color3.fromRGB(232, 92, 80) -- the hand's red: one of them can't
local LAND = TweenInfo.new(Feel.Land, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BACK = TweenInfo.new(Feel.Back, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FLOOR = "Floor" -- the room's floor area (Brix's Placements names it so)
-- The thuds of a group landing come one after another this far apart (seconds), heaviest first:
-- three distinct knocks read as three things landing, not one muddy bang.
local THUD_GAP = 0.05
-- How long a refused Turn shows red before the group floats back (seconds).
local RED_BEAT = 0.25
-- A group pressing into something: the hand's bump (the knock, low and soft).
local BUMP: Arrange.Sound = table.clone(Arrange.Knock)
BUMP.pitch = (Arrange.Knock.pitch or 1) * 0.7
BUMP.volume = (Arrange.Knock.volume or 0.5) * 0.5
BUMP.length = 0.3

export type Options = {
	room: () -> Arrange.Room?,
	tops: { [string]: boolean }, -- finds set out whose top takes another (the hand's table)
	placed: () -> Instance?, -- the folder your finds are drawn in
	sounds: () -> Instance,
	remote: (name: string) -> RemoteEvent?,
	tap: (tap: Feedback.Tap) -> (),
	-- The things the box has lit (roots), and its glows dimmed while the ghosts stand in.
	ids: () -> { string },
	dim: (on: boolean) -> (),
	-- Lets the box's things go (all put away).
	clear: () -> (),
	-- The ring round `thing` with `which`'s buttons (nil puts it away).
	ring: (thing: Model?, which: ArrangeRing.Which?) -> (),
	-- A near-edge finger slides the build camera (`ArrangeCamera.follow`).
	follow: (x: number, y: number) -> (),
	-- The tray card for `name` on screen (gui points), and its bump as a thing lands in it.
	cardAt: (name: string) -> Vector2?,
	bump: (name: string) -> (),
	-- A group change the server accepted: one undo step (`History.recordGroup`).
	changed: (changes: { History.Change }) -> (),
}

export type ArrangeGroup = {
	-- Whether `t` (what a press picked) is one of the lit things.
	owns: (t: Model?) -> boolean,
	-- Whether the ring's buttons are the group's now (things lit, the box let go).
	active: () -> boolean,
	-- Whether the group is moving or waiting for the server.
	busy: () -> boolean,
	-- The box let go: the ring comes round the lit things (or goes, with none lit).
	shown: () -> (),
	-- A drag that began on a lit thing, its moves and its end (gui points).
	intent: (i: Brix.GestureIntent<Model>) -> (),
	turnNow: () -> (),
	awayNow: () -> (),
	-- The server's word on a group ask: (verb, refusal or "", ids).
	answered: (verb: unknown, refusal: unknown, ids: unknown) -> (),
	-- A group's undo or redo: false if it can't start.
	replay: (
		ask: History.Ask,
		finished: (ok: boolean, id: string?, more: { string? }?) -> ()
	) -> boolean,
	-- The ring goes (the selection was let go).
	hide: () -> (),
}

-- One thing of a moving group.
type Piece = {
	id: string,
	name: string,
	drawn: Model,
	ghost: Model,
	riders: { Model }, -- drawn riders, hidden while their copies ride in the ghost
	from: CFrame, -- the drawn thing's pivot when lifted
	stood: Brix.PlacementPose, -- where it stood
	offset: CFrame, -- its pivot from its pose's frame
	target: CFrame,
}

local ArrangeGroup = {}

local function hide(model: Model, hidden: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function ArrangeGroup.new(options: Options): ArrangeGroup
	local play = ArrangeHand.play
	-- What's moving now (empty: nothing).
	local pieces: { Piece } = {}
	local holder: Model? = nil -- the ghosts' one model (one highlight paints them all)
	local highlight: Highlight? = nil
	local start: { Group.Member } = {} -- the floor things as they stood
	local now: { Group.Member } = {} -- where they'd stand
	local fits, carrying, asking = true, false, nil :: string?
	local dx, dy, quarters = 0, 0, 0
	local grabX, grabY = 0, 0 -- the floor point the finger took the group at
	local fingerX, fingerY, thumb = 0, 0, 0
	local step: RBXScriptConnection? = nil
	local finished: ((ok: boolean, id: string?, more: { string? }?) -> ())? = nil
	local outline: Model? = nil -- an unseen box round the lit things, for the ring to hug
	-- The group Place waiting for its answer, in the order sent: `id` for a thing moved, nil for a
	-- find set out of the box (an undone group Put away).
	local sent: { { what: string, id: string?, to: Brix.PlacementPose } } = {}

	local function shapeOf(id: string): any -- any: Brix's PlacementShape, as Group.apply takes
		return Arrange.shapeOf(id)
	end

	local function drawnOf(id: string): Model?
		local folder = options.placed()
		local m = if folder then folder:FindFirstChild(id) else nil
		return if m and m:IsA("Model") then m else nil
	end

	-- Whether thing `id` is the job box (its row says it's kept: it never goes in the box).
	local function kept(id: string): boolean
		local kind = Layout.kind(id)
		local row = if kind then Furniture.byId(kind) else nil
		return row ~= nil and row.kept == true
	end

	-- The ring round the lit things: an unseen part the size of their box.
	local function ringRound(ids: { string })
		local any = false
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, id in ids do
			local m = drawnOf(id)
			if m then
				-- its own box, not its cubby finds' (they can stand well off a shelf)
				local size, centre = Arranged.bounds(m, Shelf.Tag)
				if not (size and centre) then
					continue
				end
				local cf = m:GetPivot() * CFrame.new(centre)
				local h = size / 2
				for i = 0, 7 do
					local c = cf
						* Vector3.new(
							if i % 2 == 0 then -h.X else h.X,
							if i // 2 % 2 == 0 then -h.Y else h.Y,
							if i // 4 == 0 then -h.Z else h.Z
						)
					lo, hi = lo:Min(c), hi:Max(c)
					any = true
				end
			end
		end
		if not any then
			options.ring(nil, nil)
			return
		end
		local o = outline
		if not o then
			local made = Instance.new("Model")
			made.Name = "ArrangeGroupOutline"
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
			p.Transparency = 1
			p.Parent = made
			made.PrimaryPart = p
			o = made
			outline = made
		end
		local part = (o :: Model).PrimaryPart :: BasePart
		part.Size = hi - lo
		part.CFrame = CFrame.new((lo + hi) / 2);
		(o :: Model).Parent = Workspace.CurrentCamera
		local away = true
		for _, id in ids do
			if kept(id) then
				away = false
			end
		end
		options.ring(o, { away = away, turn = true, another = false, raise = false })
	end

	local function shown()
		local ids = options.ids()
		if #ids > 0 and #pieces == 0 then
			ringRound(ids)
		elseif #ids == 0 then
			options.ring(nil, nil)
		end
	end

	-- The floor point (the floor's `x`, `y`) under gui point `x`, `y`.
	local function floorAt(r: Arrange.Room, x: number, y: number): (number?, number?)
		local camera, a = Workspace.CurrentCamera, Arrange.frameOn(r, FLOOR)
		if not (camera and a) then
			return nil, nil
		end
		local ray = camera:ScreenPointToRay(x, y)
		local n = a.YVector
		local d = ray.Direction:Dot(n)
		if math.abs(d) < 1e-4 then
			return nil, nil
		end
		local t = (a.Position - ray.Origin):Dot(n) / d
		if t < 0 then
			return nil, nil
		end
		local p = a:PointToObjectSpace(ray.Origin + ray.Direction * t)
		return p.X, -p.Z
	end

	-- Whether `list` can all stand at once: tried on the room's judge, then undone.
	local function judge(r: Arrange.Room, list: { Group.Member }): boolean
		if #list == 0 then
			return true
		end
		local refusal = Group.apply(r.placements, list, shapeOf)
		if not refusal then
			-- (the same things, back where they stood: always fits, it's how the room was)
			local back: { Group.Member } = table.create(#list)
			for _, m in list do
				for _, s in start do
					if s.id == m.id then
						table.insert(back, s)
					end
				end
			end
			Group.apply(r.placements, back, shapeOf)
		end
		r.placements:takeEvents()
		return refusal == nil
	end

	local function paint()
		local h = highlight
		if h then
			h.OutlineColor = if fits then Color3.new(1, 1, 1) else REFUSED
			h.FillColor = if fits then FITS else REFUSED
			h.FillTransparency = if fits then 0.78 else 0.55
		end
	end

	-- Each ghost's target from `now` (a thing not in it stays where it stood), hovering while carried.
	local function aimAll(r: Arrange.Room)
		local up = if carrying then Vector3.yAxis * Feel.Hover else Vector3.zero
		for _, p in pieces do
			local to = p.stood
			for _, m in now do
				if m.id == p.id then
					to = m.pose
				end
			end
			local a = Arrange.frameOn(r, to.on)
			if a then
				p.target = Arranged.pose(a, to.x, to.y, to.turn) * p.offset + up
			end
		end
	end

	local function stopStep()
		if step then
			step:Disconnect()
			step = nil
		end
	end

	-- The ghosts ease after their targets each frame while the group is moving.
	local function startStep()
		if step then
			return
		end
		step = RunService.RenderStepped:Connect(function(dt: number)
			if carrying then
				options.follow(fingerX, fingerY)
			end
			local k = 1 - 0.5 ^ (dt / Feel.Follow)
			for _, p in pieces do
				p.ghost:PivotTo(p.ghost:GetPivot():Lerp(p.target, k))
			end
		end)
	end

	-- What stands on `id`, however high, as drawn here.
	local function ridersOf(r: Arrange.Room, id: string, out: { Model }): { Model }
		for _, rider in r.placements:standingOn(id) do
			local m = drawnOf(rider)
			if m then
				table.insert(out, m)
			end
			ridersOf(r, rider, out)
		end
		return out
	end

	-- Ghosts stand in for each of `ids` drawn here; the drawn things (and their riders) hide.
	local function lift(r: Arrange.Room, ids: { string }): boolean
		local h = Instance.new("Model")
		h.Name = "ArrangeGroup"
		table.clear(start)
		table.clear(pieces)
		for _, id in ids do
			local drawn, pose = drawnOf(id), r.placements:poseOf(id)
			local name = Spots.name(id)
			local a = if pose then Arrange.frameOn(r, pose.on) else nil
			if drawn and pose and a and name then
				local ghost = drawn:Clone()
				ArrangeHand.inert(ghost)
				for _, tag in ghost:GetTags() do
					ghost:RemoveTag(tag)
				end
				local riders = ridersOf(r, id, {})
				for _, m in riders do
					local copy = m:Clone()
					ArrangeHand.inert(copy)
					for _, tag in copy:GetTags() do
						copy:RemoveTag(tag)
					end
					copy.Parent = ghost
					hide(m, true)
				end
				hide(drawn, true)
				ghost.Parent = h
				local stood = { on = pose.on, x = pose.x, y = pose.y, turn = pose.turn }
				local pivot = drawn:GetPivot()
				table.insert(pieces, {
					id = id,
					name = name,
					drawn = drawn,
					ghost = ghost,
					riders = riders,
					from = pivot,
					stood = stood,
					offset = Arranged.pose(a, stood.x, stood.y, stood.turn):Inverse() * pivot,
					target = pivot,
				})
				if pose.on == FLOOR then
					table.insert(start, { id = id, pose = stood })
				end
			end
		end
		if #pieces == 0 then
			h:Destroy()
			return false
		end
		local light = Instance.new("Highlight")
		light.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		light.OutlineTransparency = 0
		light.Adornee = h
		light.Parent = h
		h.Parent = Workspace.CurrentCamera
		holder, highlight = h, light
		table.clear(now)
		dx, dy, quarters, fits, asking = 0, 0, 0, true, nil
		paint()
		options.dim(true)
		options.ring(nil, nil)
		play(Arrange.Lift, options.sounds())
		options.tap(Feedback.Taps.Light)
		startStep()
		return true
	end

	-- The ghosts go and the drawn things show again (unless `gone`: put away).
	local function letGo(gone: boolean)
		stopStep()
		for _, p in pieces do
			if not gone then
				hide(p.drawn, false)
				for _, m in p.riders do
					hide(m, false)
				end
			end
		end
		table.clear(pieces)
		table.clear(now)
		local h = holder
		holder, highlight, asking, carrying = nil, nil, nil, false
		if h then
			h:Destroy()
		end
		options.dim(false)
		if gone then
			options.clear()
			options.ring(nil, nil)
		else
			shown()
		end
	end

	-- Tells an undo or redo the server's word, once.
	local function finish(ok: boolean, id: string?, more: { string? }?)
		local f = finished
		finished = nil
		if f then
			f(ok, id, more)
		end
	end

	-- All float back where they stood, quietly.
	local function floatBack()
		asking = "back"
		stopStep()
		play(Arrange.Slide, options.sounds())
		local h = highlight
		if h then
			h.Enabled = false
		end
		finish(false)
		local last: Tween? = nil
		for _, p in pieces do
			local cf = Instance.new("CFrameValue")
			cf.Value = p.ghost:GetPivot()
			cf.Changed:Connect(function(v: CFrame)
				p.ghost:PivotTo(v)
			end)
			local t = TweenService:Create(cf, BACK, { Value = p.from })
			t.Completed:Once(function()
				cf:Destroy()
			end)
			t:Play()
			last = t
		end
		if last then
			last.Completed:Once(function()
				letGo(false)
			end)
		else
			letGo(false)
		end
	end

	-- All come down onto their targets, each with its thud by weight (heaviest first) and its
	-- puff; `done` once the last has landed.
	local function landAll(done: (() -> ())?)
		stopStep()
		local h = highlight
		local order = table.clone(pieces)
		table.sort(order, function(a: Piece, b: Piece): boolean
			return Feedback.landing(a.name).spread > Feedback.landing(b.name).spread
		end)
		for i, p in order do
			local cf = Instance.new("CFrameValue")
			cf.Value = p.ghost:GetPivot()
			cf.Changed:Connect(function(v: CFrame)
				p.ghost:PivotTo(v)
			end)
			local t = TweenService:Create(cf, LAND, { Value = p.target })
			t.Completed:Once(function()
				cf:Destroy()
				task.delay((i - 1) * THUD_GAP, function()
					if not p.ghost.Parent then
						return
					end
					local band = Feedback.landing(p.name)
					play(band.thud, options.sounds())
					options.tap(band.tap)
					ArrangeHand.puff(p.target, band)
					if i == #order then
						if h then
							TweenService:Create(
								h,
								TweenInfo.new(0.15),
								{ OutlineTransparency = 1, FillTransparency = 1 }
							):Play()
						end
						if done then
							done()
						end
					end
				end)
			end)
			t:Play()
		end
	end

	-- Sends `list` as one group Place (`what` each thing's id, or a find's name from the box).
	local function sendPlace(
		entries: { { what: string, id: string?, to: Brix.PlacementPose } }
	): boolean
		local remote = options.remote(Group.Remote)
		if not remote or #entries == 0 then
			return false
		end
		sent = entries
		local list = table.create(#entries)
		for _, e in entries do
			table.insert(
				list,
				{ what = e.what, on = e.to.on, x = e.to.x, y = e.to.y, turn = e.to.turn }
			)
		end
		asking = "place"
		remote:FireServer("place", list)
		task.delay(3, function()
			if asking == "place" then
				floatBack() -- no answer: as if refused
			end
		end)
		return true
	end

	-- Lets the carried or turned group go where it aims: lands as one ask, or floats back.
	local function drop()
		local r = options.room()
		carrying = false
		if not r or asking then
			return
		end
		if #now == 0 or (dx == 0 and dy == 0 and quarters % 4 == 0) then
			aimAll(r)
			landAll(function()
				letGo(false)
			end) -- set back down where they stood: nothing to ask
			return
		elseif not fits then
			floatBack()
			return
		end
		aimAll(r)
		local entries = table.create(#now)
		for _, m in now do
			table.insert(entries, { what = m.id, id = m.id, to = m.pose })
		end
		if sendPlace(entries) then
			landAll()
		else
			floatBack()
		end
	end

	-- The finger's slide to gui point `x`, `y`: the group follows, snapped, judged all together.
	local function move(x: number, y: number)
		local r = options.room()
		fingerX, fingerY = x, y
		if not (r and carrying) or asking then
			return
		end
		local fx, fy = floorAt(r, x, y - thumb)
		if not (fx and fy) then
			return
		end
		local sx = math.round((fx - grabX) / Arrange.Step) * Arrange.Step
		local sy = math.round((fy - grabY) / Arrange.Step) * Arrange.Step
		if sx == dx and sy == dy and #now > 0 then
			return
		end
		dx, dy = sx, sy
		local base = if quarters % 4 ~= 0 then Group.turned(start, FLOOR, quarters) else start
		now = Group.moved(base, FLOOR, dx, dy)
		local was = fits
		fits = judge(r, now)
		paint()
		aimAll(r)
		if was and not fits then
			play(BUMP, options.sounds())
		else
			play(Arrange.Tick, options.sounds())
			options.tap(Feedback.Taps.Tick)
		end
	end

	local function owns(t: Model?): boolean
		if not t then
			return false
		end
		local id = t:GetAttribute(Spots.IdAttribute)
		return type(id) == "string" and table.find(options.ids(), id) ~= nil
	end

	local function intent(i: Brix.GestureIntent<Model>)
		if i.kind == "dragBegan" then
			local r = options.room()
			if not r or asking or #pieces > 0 or not owns(i.target) then
				return
			end
			thumb = if i.button == "touch" then Feel.Thumb else 0
			local fx, fy = floorAt(r, i.x, i.y - thumb)
			if not (fx and fy) or not lift(r, options.ids()) then
				return
			end
			grabX, grabY = fx, fy
			carrying = true
			move(i.x, i.y)
		elseif i.kind == "dragMoved" then
			move(i.x, i.y)
		elseif i.kind == "dragEnded" then
			if carrying then
				if i.cancelled then
					carrying = false
					floatBack()
				else
					drop()
				end
			end
		end
	end

	-- Turn: the lit things swing a quarter about their middle, with the ratchet's click-click; they
	-- land as one ask, or show red a beat and float back.
	local function turnNow()
		local r = options.room()
		if not r or asking or #pieces > 0 or not lift(r, options.ids()) then
			return
		end
		quarters = 1
		now = Group.turned(start, FLOOR, quarters)
		fits = judge(r, now)
		paint()
		aimAll(r)
		play(Arrange.Ratchet, options.sounds())
		options.tap(Feedback.Taps.Tick)
		task.delay(0.07, play, Arrange.Ratchet, options.sounds())
		if fits then
			task.delay(Feel.Land, drop)
		else
			play(BUMP, options.sounds())
			asking = "red"
			task.delay(RED_BEAT, function()
				asking = nil
				floatBack()
			end)
		end
	end

	-- Each ghost flies to its tray card, shrinking, and pops in (Put away's flight, as the hand's).
	local function flyAll()
		stopStep()
		for i, p in pieces do
			local ghost, name, from = p.ghost, p.name, p.ghost:GetPivot()
			local whole = ghost:GetScale()
			local share = Instance.new("NumberValue")
			share.Changed:Connect(function(t: number)
				local camera, card = Workspace.CurrentCamera, options.cardAt(name)
				if not ghost.Parent then
					return
				elseif card and camera then
					local ray = camera:ScreenPointToRay(card.X, card.Y)
					local to = ray.Origin + ray.Direction * Feedback.FlyDepth
					ghost:PivotTo(CFrame.new(from.Position:Lerp(to, t)) * from.Rotation)
					ghost:ScaleTo(whole * (1 - (1 - Feedback.FlyEnd) * t))
				elseif t < 0.98 then
					ghost:ScaleTo(whole * (1 - t))
				end
			end)
			local seconds = if options.cardAt(name) then Feedback.Fly else Feel.Back
			local t = TweenService:Create(
				share,
				TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Value = 1 }
			)
			t.Completed:Once(function()
				share:Destroy()
				ghost.Parent = nil
				if options.cardAt(name) then
					play(Feedback.Pop, options.sounds())
					options.tap(Feedback.Taps.Tap)
					options.bump(name)
				end
			end)
			task.delay((i - 1) * THUD_GAP, t.Play, t)
		end
	end

	-- Put away: every lit thing flies into its card, as one ask.
	local function awayNow()
		local r, remote = options.room(), options.remote(Group.Remote)
		local ids = options.ids()
		for _, id in ids do
			if kept(id) then
				return -- the job box holds everything: the ring had no Put away
			end
		end
		if not (r and remote) or asking or #pieces > 0 or not lift(r, ids) then
			return
		end
		local list = table.create(#pieces)
		for _, p in pieces do
			table.insert(list, p.id)
		end
		asking = "away"
		remote:FireServer("away", list)
		task.delay(3, function()
			if asking == "away" then
				finish(false)
				letGo(false) -- no answer: they stay where they were
			end
		end)
		play(Arrange.Slide, options.sounds())
		local h = highlight
		if h then
			h.Enabled = false
		end
		flyAll()
	end

	-- Waits (briefly) for the server's drawn things to stand where the ghosts landed, then lets
	-- the ghosts go, so there's never a gap.
	local function settleOnto()
		task.spawn(function()
			local deadline = os.clock() + 1.5
			while os.clock() < deadline do
				local all = true
				for _, p in pieces do
					if not p.drawn:GetPivot().Position:FuzzyEq(p.target.Position, 0.05) then
						all = false
					end
				end
				if all then
					break
				end
				task.wait(0.05)
			end
			task.wait(Feel.Land)
			letGo(false)
		end)
	end

	local function answered(verb: unknown, refusal: unknown, ids: unknown)
		local r = options.room()
		if not r or verb ~= asking or type(refusal) ~= "string" or type(ids) ~= "table" then
			return
		end
		local got = ids :: { unknown }
		if verb == "place" then
			if refusal ~= "" then
				floatBack()
				return
			end
			-- the moves (and set-outs) into the room's judge, and one undo step
			local moved: { Group.Member } = {}
			local changes: { History.Change } = {}
			local after: { string? } = {}
			local outs: { { id: string, to: Brix.PlacementPose } } = {}
			for i, e in sent do
				local id = if type(got[i]) == "string" then got[i] :: string else e.id
				table.insert(after, id)
				local was: Brix.PlacementPose? = nil
				for _, p in pieces do
					if p.id == e.id then
						was = p.stood
					end
				end
				if e.id then
					table.insert(moved, { id = e.id, pose = e.to })
				elseif id then
					table.insert(outs, { id = id, to = e.to })
				end
				table.insert(changes, {
					name = Spots.name(id or e.what) or e.what,
					idBefore = e.id,
					before = was,
					idAfter = id,
					after = e.to,
				})
			end
			Group.apply(r.placements, moved, shapeOf)
			for _, o in outs do
				local shape = Arrange.shapeOf(o.id)
				if shape then
					r.placements:place(o.id, shape, o.to)
					if shape.top then
						options.tops[o.id] = true
					end
				end
			end
			r.placements:takeEvents()
			asking = "landing"
			if finished then
				finish(true, after[1], table.move(after, 2, #after, 1, {}))
			else
				options.changed(changes)
			end
			settleOnto()
		elseif verb == "away" then
			if refusal ~= "" then
				finish(false)
				letGo(false)
				return
			end
			local changes: { History.Change } = {}
			local function away(each: string)
				for _, rider in r.placements:standingOn(each) do
					away(rider)
				end
				r.placements:remove(each)
				r.heights[each] = nil
				options.tops[each] = nil
			end
			for _, p in pieces do
				if r.placements:poseOf(p.id) then
					away(p.id)
				end
				table.insert(changes, {
					name = p.name,
					idBefore = p.id,
					before = p.stood,
					idAfter = nil,
					after = nil,
				})
			end
			r.placements:takeEvents()
			if finished then
				finish(true)
			else
				options.changed(changes)
			end
			letGo(true)
		end
	end

	-- A group's undo or redo: all moves (and set-outs from the box) as one group Place, the moved
	-- ones gliding there; or all put away as one, flying to their cards.
	local function replay(
		ask: History.Ask,
		done: (ok: boolean, id: string?, more: { string? }?) -> ()
	): boolean
		local r = options.room()
		if not r or asking or #pieces > 0 then
			return false
		end
		local asks: { History.Ask } = { ask }
		for _, a in ask.more or {} :: { History.Ask } do
			table.insert(asks, a)
		end
		local ids: { string } = {}
		for _, a in asks do
			local id = a.id
			if id then
				if not drawnOf(id) then
					return false
				end
				table.insert(ids, id)
			elseif not a.to then
				return false
			end
		end
		if ask.to then
			if #ids > 0 and not lift(r, ids) then
				return false
			end
			local entries = table.create(#asks)
			table.clear(now)
			for _, a in asks do
				local to = a.to
				if not to then
					floatBack()
					return true
				end
				table.insert(entries, { what = a.id or a.name, id = a.id, to = to })
				if a.id then
					table.insert(now, { id = a.id, pose = to })
				end
			end
			finished = done
			aimAll(r)
			if sendPlace(entries) then
				task.delay(Feel.Land, function()
					if #pieces > 0 then
						landAll()
					end
				end)
			else
				floatBack()
			end
			return true
		end
		local remote = options.remote(Group.Remote)
		if not remote or #ids == 0 or not lift(r, ids) then
			return false
		end
		finished = done
		asking = "away"
		remote:FireServer("away", ids)
		task.delay(3, function()
			if asking == "away" then
				finish(false)
				letGo(false)
			end
		end)
		play(Arrange.Slide, options.sounds())
		flyAll()
		return true
	end

	return {
		owns = owns,
		active = function(): boolean
			return #options.ids() > 0
		end,
		busy = function(): boolean
			return #pieces > 0 or asking ~= nil
		end,
		shown = shown,
		intent = intent,
		turnNow = turnNow,
		awayNow = awayNow,
		answered = answered,
		replay = replay,
		hide = function()
			if #pieces == 0 then
				options.ring(nil, nil)
			end
		end,
	}
end

return ArrangeGroup
