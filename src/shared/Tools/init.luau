--!strict
--[[
	The tools in the place (L-11b, D-048): what you carry in your two slots. Each tool's template is
	a MeshPart in a Model at ReplicatedStorage.Props.Tools.<template>, imported once (Rojo can't
	sync imported meshes, D-009) and prepared by `prepare`: its grip (where a hand closes) at the
	model's pivot, its business end towards the LookVector. A tool may have a second part that
	moves on it later (the ladder's fly, `<template>Fly`), welded to the first. `Catalog` holds the
	rows, `Carry` the slots' rules, `Specs/<key>` each tool's generated sizes, `Leaning` and `Leaned`
	the ladder leaned on a front and climbed.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Carry = require(script.Carry)
local Catalog = require(script.Catalog)

local Tools = {}
Tools.Carry = Carry
Tools.Catalog = Catalog

export type Row = Catalog.Row
export type SoundSpec = Catalog.Sound
export type CarryState = Carry.Carry
export type Piece = { Size: Vector3, Centre: Vector3, Triangles: number }
-- A tool's generated sizes: its body, and for a tool of two parts the second (`Fly`) and both
-- together (`Bounds`), each from the grip.
export type Specs = { Body: Piece, Fly: Piece?, Bounds: Piece? }

-- The attributes the server keeps on each Player for every screen: what's in each slot (the
-- catalog key, or "" for empty) and which slot is in your hand.
Tools.SlotAttribute = "ToolSlot" -- ToolSlot1, ToolSlot2
Tools.HandAttribute = "ToolHand"
-- On a tool's model: its catalog key (so a screen knows a model's row).
Tools.KindAttribute = "Tool"
Tools.RemoteFolder = "Remotes"
Tools.SwitchRemote = "ToolSwitch" -- client → server: the slot you want in your hand
Tools.DropRemote = "ToolDrop" -- client → server: drop what's in your hand
Tools.GiveRemote = "ToolGive" -- client → server: hand what's in your hand to a friend
Tools.NoticeRemote = "ToolNotice" -- server → client: a short line for your screen
Tools.UseRemote = "ToolUse" -- client → server: use what's in your hand (its row's `verb`: Blow)
Tools.HeldName = "HeldTool" -- the model's name in a character's hand
-- A door's Lock button (Doors): every screen hides it unless a padlock is in that player's hand.
Tools.LockTag = "PadlockButton"
-- A wall's Saw button (Saws): every screen hides it unless that player carries a saw.
Tools.SawTag = "SawButton"
-- A unit front's Lean button (Ladders): every screen hides it unless the ladder is in that player's
-- hand.
Tools.LeanTag = "LeanButton"
-- On a button a tool works away from a door (Saws' "Saw"): the action, as `DoorAction` is a door's,
-- so your view brings the tool out while you hold it.
Tools.ActionAttribute = "ToolAction"

-- The attribute name for slot `i`.
function Tools.slotAttribute(i: number): string
	return Tools.SlotAttribute .. i
end

-- A tool's generated sizes (art/<tool>/spec.py's export), by catalog key.
function Tools.specs(key: string): Specs
	local m = script.Specs:FindFirstChild(key)
	assert(m and m:IsA("ModuleScript"), `Tools: no Specs for {key}`)
	return (require :: any)(m) -- any: a generated module, required by name
end

-- The whole tool's box, every part together (what lies on a floor and what a unit must fit).
function Tools.bounds(key: string): Piece
	local specs = Tools.specs(key)
	return specs.Bounds or specs.Body
end

local function folder(): Instance?
	local props = ReplicatedStorage:FindFirstChild("Props")
	return if props then props:FindFirstChild("Tools") else nil
end

-- The template for catalog key `key`, if the place has it.
function Tools.template(key: string): Model?
	local row = Catalog[key]
	local f = folder()
	local t = if row and f then f:FindFirstChild(row.template) else nil
	return if t and t:IsA("Model") then t else nil
end

-- Scenery that never touches anything: welded in a hand, held to a camera or lying on a floor,
-- it must not push, trip a zone or block a ray (a prompt's line of sight included).
local function inert(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end
Tools.inert = inert

--[[
	The import's last step, once, in Edit from the command bar or the MCP: `import` is the inserted
	model (its PackageLink already removed) holding the MeshPart named after the row's template. It
	becomes the template: square to the world with the grip at the origin and the part's pivot
	there, nothing colliding, and is moved into ReplicatedStorage.Props.Tools.
]]
function Tools.prepare(import: Model, key: string): Model
	local row = Catalog[key]
	assert(row, `Tools.prepare: no catalog row {key}`)
	local body = import:FindFirstChild(row.template)
	assert(body and body:IsA("MeshPart"), "Tools.prepare: not the import")
	local specs = Tools.specs(key)
	inert(body)
	body.CastShadow = true
	body.CFrame = CFrame.new(specs.Body.Centre)
	body.PivotOffset = CFrame.new(-specs.Body.Centre)
	-- a second part (the ladder's fly): where it sits on the body, welded there, so a hand's weld
	-- and an anchored body both carry it; never anchored itself, or a hand would be
	local second = import:FindFirstChild(row.template .. "Fly")
	if specs.Fly then
		assert(second and second:IsA("MeshPart"), `Tools.prepare: no {row.template}Fly`)
		inert(second)
		second.Anchored = false
		second.CastShadow = true
		second.CFrame = CFrame.new(specs.Fly.Centre)
		local weld = Instance.new("Weld")
		weld.Name = "FlyWeld"
		weld.Part0 = body
		weld.Part1 = second
		weld.C0 = CFrame.new(specs.Fly.Centre - specs.Body.Centre)
		weld.Parent = second
	end
	import.Name = row.template
	import.PrimaryPart = body
	import.WorldPivot = CFrame.identity
	local props = ReplicatedStorage:FindFirstChild("Props")
	assert(props, "Tools.prepare: no ReplicatedStorage.Props")
	local f = props:FindFirstChild("Tools")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Tools"
		f.Parent = props
	end
	local old = f:FindFirstChild(row.template)
	if old and old ~= import then
		old:Destroy()
	end
	import.Parent = f
	return import
end

-- A copy of `key`'s template with its grip at `at`, tagged with its key. Nil, with a warning, if
-- the place is missing the template. Not parented.
function Tools.clone(key: string, at: CFrame): Model?
	local t = Tools.template(key)
	if not t then
		warn(
			`Tools: no template for {key} at ReplicatedStorage.Props.Tools; import it (art/boltcutters/README.md)`
		)
		return nil
	end
	local model = t:Clone()
	model:SetAttribute(Tools.KindAttribute, key)
	model:PivotTo(at)
	return model
end

-- The part a tool's model is held by (its first MeshPart; a second rides on it).
function Tools.body(model: Model): BasePart?
	local p = model.PrimaryPart
	if p then
		return p
	end
	return model:FindFirstChildWhichIsA("BasePart")
end

-- A Sound playing only `s`'s stretch of its recording, parented to `parent`. Heard to `reach`
-- studs (full volume within a few).
function Tools.sound(s: SoundSpec, parent: Instance, reach: number): Sound
	local snd = Instance.new("Sound")
	snd.SoundId = s.id
	snd.Volume = s.volume
	snd.PlaybackSpeed = s.pitch or 1
	snd.PlaybackRegionsEnabled = true
	snd.PlaybackRegion = NumberRange.new(s.from, s.from + s.length)
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 4
	snd.RollOffMaxDistance = reach
	snd.Parent = parent
	return snd
end

-- Plays `s` once at `parent` and cleans up after.
function Tools.play(s: SoundSpec, parent: Instance, reach: number)
	local snd = Tools.sound(s, parent, reach)
	snd.TimePosition = s.from
	snd:Play()
	task.delay(s.length / (s.pitch or 1) + 0.5, function()
		snd:Destroy()
	end)
end

-- Every sound id the catalog plays, to prime on a screen (SoundPrimer).
function Tools.soundIds(): { string }
	local ids = {}
	for _, row in Catalog do
		table.insert(ids, row.pickUp.id)
		table.insert(ids, row.drop.id)
	end
	return ids
end

return Tools
