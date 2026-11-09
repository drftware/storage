--!strict
--[[
	Sends the game's built art to Roblox through Open Cloud, the way porch-pirates ships its art:
	no 3D Importer, no clicks. Each FBX in ART (the storage unit, the corridor kit's pieces, the boxes) becomes
	a Model asset on its first upload; later uploads update it in place, keeping its ID. The FBX's
	embedded textures arrive as SurfaceAppearances. Records each file's hash and asset ID in its
	folder's assets.json; a session then inserts the asset in Studio and prepares it
	(art/unit/README.md and art/corridor/README.md, "Into Studio").

		lune run scripts/upload_art        upload what changed since the last upload
		lune run scripts/upload_art dry    say what would go up, touch nothing
		lune run scripts/upload_art Fixture  only the named art (its key below); works with dry

	Needs .config/.env (git-ignored): ROBLOX_API_KEY (Assets read and write) and ROBLOX_CREATOR_ID
	(the key owner's user ID or username). The key is never printed.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local OpenCloud = require("./lib/OpenCloud")

type Art = { key: string, path: string, manifest: string, description: string }
local ART: { Art } = {
	-- the unit's size L joins when its FBX is built
	{
		key = "M",
		path = "art/unit/out/StorageUnit_M.fbx",
		manifest = "art/unit/assets.json",
		description = "A self-storage unit with a working roll-up door",
	},
	{
		key = "S",
		path = "art/unit/out/StorageUnit_S.fbx",
		manifest = "art/unit/assets.json",
		description = "A small self-storage unit with a working roll-up door",
	},
	{
		key = "Straight",
		path = "art/corridor/out/Corridor_Straight.fbx",
		manifest = "art/corridor/assets.json",
		description = "A straight stretch of a storage building's hall: its floor and steel ceiling",
	},
	{
		key = "Wall",
		path = "art/corridor/out/Corridor_Wall.fbx",
		manifest = "art/corridor/assets.json",
		description = "A plain stretch of a storage building's hall wall, where no unit stands",
	},
	{
		key = "ShortWall",
		path = "art/corridor/out/Corridor_ShortWall.fbx",
		manifest = "art/corridor/assets.json",
		description = "A short plain stretch of a storage building's hall wall, a small unit wide",
	},
	{
		key = "Corner",
		path = "art/corridor/out/Corridor_Corner.fbx",
		manifest = "art/corridor/assets.json",
		description = "Where a storage building's hall turns a corner: its floor and steel ceiling",
	},
	{
		key = "T",
		path = "art/corridor/out/Corridor_T.fbx",
		manifest = "art/corridor/assets.json",
		description = "Where a storage building's hall meets another: its floor and steel ceiling",
	},
	{
		key = "Cross",
		path = "art/corridor/out/Corridor_Cross.fbx",
		manifest = "art/corridor/assets.json",
		description = "Where two of a storage building's halls cross: their floor and steel ceiling",
	},
	{
		key = "DeadEnd",
		path = "art/corridor/out/Corridor_DeadEnd.fbx",
		manifest = "art/corridor/assets.json",
		description = "The wall at the end of a storage building's hall, closed to the ceiling",
	},
	{
		key = "Fixture",
		path = "art/corridor/out/Corridor_Fixture.fbx",
		manifest = "art/corridor/assets.json",
		description = "A storage building's hall light: a strip light on two chains with a motion sensor",
	},
	{
		key = "Bulb",
		path = "art/corridor/out/Corridor_Bulb.fbx",
		manifest = "art/corridor/assets.json",
		description = "A caged bulb on a short cord, hung inside a self-storage unit",
	},
	{
		key = "Mannequin",
		path = "art/mannequin/out/Mannequin.fbx",
		manifest = "art/mannequin/assets.json",
		description = "A faceless fibreglass shop mannequin, jointed and chipped, left too long in storage",
	},
	{
		key = "Elevator",
		path = "art/elevator/out/Elevator.fbx",
		manifest = "art/elevator/assets.json",
		description = "A freight elevator: its car, folding lattice gate, landing frame, keypad and a sticky note",
	},
	{
		key = "Boxes",
		path = "art/boxes/out/Boxes.fbx",
		manifest = "art/boxes/assets.json",
		description = "Moving boxes in a self-storage unit: small, medium, large, wardrobe and an opened one",
	},
	{
		key = "Bedroom",
		path = "art/finds/out/Bedroom.fbx",
		manifest = "art/finds/assets.json",
		description = "A 1980s bedroom's things left in storage: a boombox, a portable TV, a teddy, roller skates",
	},
	{
		key = "Flashlight",
		path = "art/flashlight/out/Flashlight.fbx",
		manifest = "art/flashlight/assets.json",
		description = "An old two-battery plastic torch, faded yellow with black ends and a rubber button",
	},
	{
		key = "BoltCutters",
		path = "art/boltcutters/out/BoltCutters.fbx",
		manifest = "art/boltcutters/assets.json",
		description = "A pair of 18-inch bolt cutters: chipped red handles, black rubber grips, a forged steel jaw",
	},
	{
		key = "Padlock",
		path = "art/padlock/out/Padlock.fbx",
		manifest = "art/padlock/assets.json",
		description = "An open laminated steel padlock: six riveted plates, a hardened shackle, a brass keyway",
	},
	{
		key = "Saw",
		path = "art/saw/out/Saw.fbx",
		manifest = "art/saw/assets.json",
		description = "A cordless reciprocating saw: green body, black rubber boot and grip, a demolition blade",
	},
}
local MODEL: OpenCloud.Kind = { assetType = "Model", contentType = "model/fbx" }

local dry = false
local only: { [string]: true } = {}
for _, arg in process.args do
	if arg == "dry" then
		dry = true
	else
		only[arg] = true
	end
end
type Manifest = { [string]: { sha256: string, assetId: number } }
local manifests: { [string]: Manifest } = {}
local function manifestOf(path: string): Manifest
	if not manifests[path] then
		manifests[path] = if fs.isFile(path) then serde.decode("json", fs.readFile(path)) else {}
	end
	return manifests[path]
end

local session: OpenCloud.Session? = nil
local changed = 0
for _, art in ART do
	if next(only) ~= nil and not only[art.key] then
		continue
	end
	if not fs.isFile(art.path) then
		print(`upload_art: {art.path} is missing; build it with scripts/art.sh`)
		process.exit(1)
	end
	local manifest = manifestOf(art.manifest)
	local hash = serde.hash("sha256", fs.readFile(art.path))
	local entry = manifest[art.key]
	if entry and entry.sha256 == hash then
		continue
	end
	changed += 1
	if dry then
		print(`  would upload {art.path}{if entry then ` over {entry.assetId}` else " as a new asset"}`)
		continue
	end
	session = session or OpenCloud.session()
	local id = OpenCloud.upload(
		session :: OpenCloud.Session,
		art.path,
		MODEL,
		if entry then entry.assetId else nil,
		art.description
	)
	manifest[art.key] = { sha256 = hash, assetId = id }
	fs.writeFile(art.manifest, serde.encode("json", manifest, true) .. "\n")
	print(`  {art.path} -> {id}`)
end
print(`upload_art: {changed} changed{if dry then " (dry run)" else ""}`)
