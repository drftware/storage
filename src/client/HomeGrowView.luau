--!strict
--[[
	HomeGrowView (S5-03h6, D-356; the home doc's idea 31): your home grows and you're there to
	watch. The moment: back from the counter with a bigger unit bought, you walk in to the room you
	know, and a beat later the steel lurches free: the partitions grind out along the floor, the
	back wall rolls away, Small's doorway widens, dust sifts down off the wall tops, and the walls
	clunk home, everything you'd set out still where it was and the pieces against the walls
	carried out with them (Animal Crossing, where you come home to find your house bigger).

	The server stands a grown home at its new size at once (`Walls.size`) and marks the unit with
	the size it grew from and when (`Walls.GrewFromAttribute`, `GrewAtAttribute`); each piece it
	laid again somewhere else carries where it stood before. This view plays the slide over that
	snap, on this player's screen only:
	- someone near a home as it grows (within `Walls.Grind.Watch`, while it's news) sees it now;
	- its holder, when it grew while they were out (at the counter, say), sees their home as it
	  was until they next walk in, and then it grows round them;
	- anyone else sees it as it is.
	Each frame of the slide stands the walls, the doorway, the lamp and the picked paint part way
	(`Walls.place` with `Sizes.between`), and each piece that moved part way from where it stood
	(its parts' places as the server laid them, shifted: a find on its top or in its cubbies
	comes too). At the end everything is as the server has it. The grind is the roll-up curtain's
	rumble pitched down, its pitch and loudness riding the slide's speed; the lurch and the clunk
	are the door's thump; the dust is one emitter per moving wall along its top, a burst at the
	lurch and at the clunk and a trickle between. No words.
]]
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local Walls = require(ReplicatedStorage.Shared.Home.Walls)
local SoundPrimer = require(script.Parent.SoundPrimer)

local GRIND = Walls.Grind
local ROLL_NAME: DoorSound.SoundName = "Roll"
local THUMP_NAME: DoorSound.SoundName = "Thump"
local CLATTER_NAME: DoorSound.SoundName = "Clatter"
local ROLL = DoorSound.Sounds[ROLL_NAME]
local THUMP = DoorSound.Sounds[THUMP_NAME]
local CLATTER = DoorSound.Sounds[CLATTER_NAME]
local DUST_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local DUST_COLOUR = Color3.fromRGB(196, 186, 168) -- old plaster and concrete
local LOOK = 0.2 -- seconds between looks at whether the holder has walked in

-- A piece carried out with a wall: where it stood, where the server stands it now, and each of
-- its parts' places as the server laid them.
type Piece = { from: CFrame, to: CFrame, parts: { [BasePart]: CFrame } }

-- A home growing on this screen: held at the size it grew from until it plays, then sliding.
type Grow = {
	unit: Model,
	slot: number,
	at: number, -- the server's GrewAt: once played (or let be), not again
	from: string,
	to: string,
	k: number, -- how far along the slide stands (0 held)
	playing: boolean,
	t: number, -- seconds into the slide
	waited: number, -- seconds the holder has stood inside, before it starts
	look: number, -- seconds to the next look
	puffs: number, -- the dust trickle carried between frames
	checking: boolean,
	pieces: { [Model]: Piece },
	connections: { RBXScriptConnection },
	dust: { ParticleEmitter },
	sounds: Attachment?,
	grind: Sound?,
}

local HomeGrowView = {}

-- `kick` shakes this player's view (CameraShake's).
function HomeGrowView.new(kick: (amount: number) -> ()): Brix.System
	local me = Players.LocalPlayer
	local grows: { [Model]: Grow } = {}
	local seen: { [number]: number } = {} -- slot -> the GrewAt already shown there
	local watching: { [Model]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local stepper: RBXScriptConnection? = nil
	local random = Random.new()

	local function rootAt(): Vector3?
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.Position else nil
	end

	-- The room's width and depth at XL, from the walls' folder.
	local function measures(unit: Model): (number, number)
		local folder = unit:FindFirstChild(Walls.Folder)
		local w = if folder then folder:GetAttribute("Width") else nil
		local d = if folder then folder:GetAttribute("Depth") else nil
		return if type(w) == "number" then w else 0, if type(d) == "number" then d else 0
	end

	-- Whether you stand inside home `unit`'s room at size `size` (past its door, between its walls).
	local function inside(unit: Model, size: string): boolean
		local frame, at = Walls.frameOf(unit), rootAt()
		if not (frame and at) then
			return false
		end
		local width, depth = measures(unit)
		local side, back = Sizes.inset(size)
		local p = frame:PointToObjectSpace(at)
		return p.Z > 0.5
			and p.Z < depth - back
			and math.abs(p.X) < width / 2 - side
			and math.abs(p.Y) < 14
	end

	-- Whether you stand near enough home `unit` to watch it grow.
	local function near(unit: Model): boolean
		local frame, at = Walls.frameOf(unit), rootAt()
		return frame ~= nil and at ~= nil and (frame.Position - at).Magnitude < GRIND.Watch
	end

	-- Stands everything in `g` with the slide `k` along: the walls, the doorway, the lamp, the
	-- paint, and every piece carried with them.
	local function pose(g: Grow, k: number)
		g.k = k
		local side, back, door = Sizes.between(g.from, g.to, k)
		Walls.place(g.unit, side, back, door)
		for _, piece in g.pieces do
			if k >= 1 then
				for p, c in piece.parts do
					p.CFrame = c
				end
			else
				local shift = piece.from:Lerp(piece.to, k) * piece.to:Inverse()
				for p, c in piece.parts do
					p.CFrame = shift * c
				end
			end
		end
	end

	local function poseOne(g: Grow, piece: Piece, p: BasePart, c: CFrame)
		if g.k < 1 then
			p.CFrame = piece.from:Lerp(piece.to, g.k) * piece.to:Inverse() * c
		end
	end

	-- A piece the server laid again elsewhere as it grew: carried from where it stood.
	local function addPiece(g: Grow, model: Model)
		local from = model:GetAttribute(Walls.GrewFromAttribute)
		if g.pieces[model] or typeof(from) ~= "CFrame" then
			return
		end
		local piece: Piece = { from = from, to = model:GetPivot(), parts = {} }
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				piece.parts[d] = d.CFrame
			end
		end
		g.pieces[model] = piece
		for p, c in piece.parts do
			poseOne(g, piece, p, c)
		end
	end

	-- Something streamed or laid into a growing home: a carried piece, or a part of one (a find
	-- set in the shelf's cubby), stands where the slide has its piece.
	local function added(g: Grow, d: Instance)
		if d:IsA("Model") then
			addPiece(g, d)
			return
		end
		if not d:IsA("BasePart") then
			return
		end
		local up = d.Parent
		while up and up ~= g.unit do
			local piece = if up:IsA("Model") then g.pieces[up] else nil
			if piece then
				piece.parts[d] = d.CFrame
				poseOne(g, piece, d, d.CFrame)
				return
			end
			up = up.Parent
		end
	end

	-- The server stood the walls at the new size while this screen holds the old (they replicate
	-- or stream in after the hold began): stand them back, once they've drifted.
	local function recheck(g: Grow)
		if g.checking or g.playing then
			return
		end
		g.checking = true
		task.defer(function()
			g.checking = false
			if grows[g.unit] ~= g or g.playing then
				return
			end
			local folder, frame = g.unit:FindFirstChild(Walls.Folder), Walls.frameOf(g.unit)
			local back = if folder then folder:FindFirstChild("Back") else nil
			if not (back and back:IsA("Model") and frame) then
				return
			end
			local side, inset = Sizes.inset(g.from)
			local want = Walls.atInset(back, frame, side, inset)
			if want and (back:GetPivot().Position - want.Position).Magnitude > 0.05 then
				pose(g, 0)
			end
			Walls.show(g.unit, true)
		end)
	end

	local function sound(g: Grow, row: DoorSound.Sound, looped: boolean): Sound
		local s = Instance.new("Sound")
		s.SoundId = row.Id
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = 90
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(row.Start, row.Stop)
		if looped then
			s.LoopRegion = NumberRange.new(row.Start, row.Stop)
			s.Looped = true
		end
		s.Parent = g.sounds
		return s
	end

	-- A one-shot: `row` at `pitch` times its own and `gain` times its loudness.
	local function hit(g: Grow, row: DoorSound.Sound, pitch: number, gain: number)
		if not g.sounds then
			return
		end
		local s = sound(g, row, false)
		s.PlaybackSpeed = random:NextNumber(row.PitchMin, row.PitchMax) * pitch
		s.Volume = row.Volume * gain
		s.TimePosition = row.Start
		s:Play()
		Debris:AddItem(s, (row.Stop - row.Start) / s.PlaybackSpeed + 0.5)
	end

	-- One dust emitter along the top of each wall that moves, riding it (a child of its model).
	local function dustOn(g: Grow)
		local folder, frame = g.unit:FindFirstChild(Walls.Folder), Walls.frameOf(g.unit)
		if not (folder and frame) then
			return
		end
		local width, depth = measures(g.unit)
		local sideFrom, backFrom = Sizes.inset(g.from)
		local sideTo, backTo = Sizes.inset(g.to)
		local roomDeep, roomWide = depth - backFrom, width - 2 * sideFrom
		for _, model in folder:GetChildren() do
			local face = if model:IsA("Model") then model.PrimaryPart else nil
			local moves = if model.Name == "Back" then backTo ~= backFrom else sideTo ~= sideFrom
			if not (face and moves) then
				continue
			end
			local c = frame:PointToObjectSpace(face.Position)
			local top = c.Y + face.Size.Y / 2 - 0.5
			local size: Vector3, at: Vector3
			if model.Name == "Back" then
				size = Vector3.new(math.max(roomWide, 1), 0.2, 0.6)
				at = Vector3.new(0, top, c.Z - face.Size.Z / 2 - 0.5)
			else
				local toward = if c.X > 0 then -1 else 1
				size = Vector3.new(0.6, 0.2, math.max(roomDeep, 1))
				at = Vector3.new(c.X + toward * (face.Size.Z / 2 + 0.5), top, roomDeep / 2)
			end
			local strip = Instance.new("Part")
			strip.Name = "Dust"
			strip.Anchored = true
			strip.CanCollide = false
			strip.CanQuery = false
			strip.CanTouch = false
			strip.CastShadow = false
			strip.Transparency = 1
			strip.Size = size
			strip.CFrame = frame * CFrame.new(at)
			local e = Instance.new("ParticleEmitter")
			e.Texture = DUST_TEXTURE
			e.Color = ColorSequence.new(DUST_COLOUR)
			e.Rate = 0
			e.Lifetime = NumberRange.new(1.6, 2.8)
			e.Speed = NumberRange.new(0.3, 1.2)
			e.EmissionDirection = Enum.NormalId.Bottom
			e.SpreadAngle = Vector2.new(25, 25)
			e.Acceleration = Vector3.new(0, -1.2, 0)
			e.Drag = 1.2
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-25, 25)
			e.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1.9),
			})
			e.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			})
			e.LightInfluence = 1
			e.Parent = strip
			strip.Parent = model
			table.insert(g.dust, e)
		end
	end

	local function puff(g: Grow, count: number)
		for _, e in g.dust do
			e:Emit(count)
		end
	end

	-- Lets `g` go: on this screen it stands as the server has it from now (`restore`).
	local function finish(g: Grow, restore: boolean)
		if grows[g.unit] == g then
			grows[g.unit] = nil
		end
		seen[g.slot] = g.at
		for _, c in g.connections do
			c:Disconnect()
		end
		table.clear(g.connections)
		if restore and g.unit.Parent then
			pose(g, 1)
			Walls.show(g.unit, Sizes.of(g.to).name ~= Sizes.Biggest)
		end
		for _, e in g.dust do
			local strip = e.Parent
			if strip then
				Debris:AddItem(strip, 3)
			end
		end
		local grind = g.grind
		if grind then
			grind:Stop()
		end
		local sounds = g.sounds
		if sounds then
			Debris:AddItem(sounds, 3)
		end
		if next(grows) == nil and stepper then
			stepper:Disconnect()
			stepper = nil
		end
	end

	-- The walls lurch free and start out.
	local function play(g: Grow)
		g.playing = true
		g.t = 0
		pose(g, 0)
		Walls.show(g.unit, true)
		local frame = Walls.frameOf(g.unit)
		if frame then
			local _, depth = measures(g.unit)
			local _, back = Sizes.inset(g.to)
			local a = Instance.new("Attachment")
			a.Name = "HomeGrow"
			a.Parent = Workspace.Terrain
			a.WorldPosition = (frame * CFrame.new(0, 5, (depth - back) / 2)).Position
			g.sounds = a
			local grind = sound(g, ROLL, true)
			grind.PlaybackSpeed = GRIND.PitchLow
			grind.Volume = 0
			grind.TimePosition = ROLL.Start
			grind:Play()
			g.grind = grind
		end
		dustOn(g)
		puff(g, GRIND.Dust)
		hit(g, THUMP, 0.62, 0.8) -- the steel breaking free
		if inside(g.unit, g.from) then
			kick(GRIND.Lurch)
		end
	end

	-- The walls clunk home.
	local function land(g: Grow)
		puff(g, GRIND.Dust)
		hit(g, THUMP, 0.7, 1)
		hit(g, CLATTER, 0.8, 0.5)
		if inside(g.unit, g.to) then
			kick(GRIND.Clunk)
		end
		finish(g, true)
	end

	local function step(dt: number)
		for _, g in grows do
			if g.playing then
				g.t += dt
				local x = g.t / GRIND.Seconds
				if x >= 1 then
					land(g)
					continue
				end
				pose(g, Sizes.slide(x))
				local speed = Sizes.slideSpeed(x)
				local grind = g.grind
				if grind then
					grind.PlaybackSpeed = GRIND.PitchLow
						+ (GRIND.PitchHigh - GRIND.PitchLow) * speed
					grind.Volume = ROLL.Volume * GRIND.Volume * (0.2 + 0.8 * speed)
				end
				g.puffs += dt * GRIND.DustRun
				if g.puffs >= 1 then
					puff(g, 1)
					g.puffs -= 1
				end
			else
				g.look -= dt
				if g.look <= 0 then
					g.look = LOOK
					g.waited = if inside(g.unit, g.from) then g.waited + LOOK else 0
					if g.waited >= GRIND.Wait then
						play(g)
					end
				end
			end
		end
	end

	-- Home `unit` grew: plays it now, holds it for its holder, or lets it be.
	local function consider(unit: Model)
		local at, from =
			unit:GetAttribute(Walls.GrewAtAttribute), unit:GetAttribute(Walls.GrewFromAttribute)
		local slot = unit:GetAttribute("LobbySlot")
		if type(at) ~= "number" or type(from) ~= "string" or type(slot) ~= "number" then
			return
		end
		local to = Walls.sizeOf(unit)
		local have = grows[unit]
		if seen[slot] == at or (have and have.at == at) or not Walls.frameOf(unit) then
			return
		end
		if have then
			finish(have, true) -- grown again before the last one played: from where it stands
		end
		local mine = unit:GetAttribute(Door.HolderAttribute) == me.UserId
		local fresh = Workspace:GetServerTimeNow() - at < GRIND.Fresh
		local now = fresh and near(unit)
		if Sizes.rank(to) <= Sizes.rank(from) or not (mine or now) then
			seen[slot] = at -- someone else's, grown while you weren't by: it's as it is
			return
		end
		local g: Grow = {
			unit = unit,
			slot = slot,
			at = at,
			from = Sizes.of(from).name,
			to = to,
			k = 0,
			playing = false,
			t = 0,
			waited = 0,
			look = 0,
			puffs = 0,
			checking = false,
			pieces = {},
			connections = {},
			dust = {},
			sounds = nil,
			grind = nil,
		}
		grows[unit] = g
		for _, d in unit:GetDescendants() do
			if d:IsA("Model") and d:GetAttribute(Walls.GrewFromAttribute) ~= nil then
				addPiece(g, d)
			end
		end
		table.insert(
			g.connections,
			unit.DescendantAdded:Connect(function(d)
				added(g, d)
			end)
		)
		local folder = unit:FindFirstChild(Walls.Folder)
		local back = if folder then folder:FindFirstChild("Back") else nil
		if back and back:IsA("Model") and back.PrimaryPart then
			table.insert(
				g.connections,
				back.PrimaryPart:GetPropertyChangedSignal("CFrame"):Connect(function()
					recheck(g)
				end)
			)
		end
		pose(g, 0)
		Walls.show(unit, true)
		if not stepper then
			stepper = RunService.Heartbeat:Connect(step)
		end
		if now and (not mine or inside(unit, g.from)) then
			play(g)
		end
	end

	local function watch(inst: Instance)
		if not inst:IsA("Model") or watching[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		if not inst:FindFirstChild(Walls.Folder) then
			return -- a climb unit, or a lobby unit that isn't a home
		end
		watching[inst] = inst:GetAttributeChangedSignal(Walls.GrewAtAttribute):Connect(function()
			consider(inst)
		end)
		consider(inst)
	end

	local function unwatch(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local c = watching[inst]
		if c then
			c:Disconnect()
			watching[inst] = nil
		end
		local g = grows[inst]
		if g then -- streamed out: shown again from the top when it streams back in
			finish(g, false)
			seen[g.slot] = nil
		end
	end

	return {
		name = "HomeGrowView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { ROLL.Id, THUMP.Id, CLATTER.Id })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(function(inst)
					task.defer(watch, inst) -- deferred so a unit streaming in has its walls
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(unwatch)
			)
			for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
				watch(inst)
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for unit in watching do
				unwatch(unit)
			end
			if stepper then
				stepper:Disconnect()
				stepper = nil
			end
		end,
	}
end

return HomeGrowView
