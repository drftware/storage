--!strict
--[[
	Sends the game's built art to Roblox through Open Cloud, the way porch-pirates ships its art:
	no 3D Importer, no clicks. Each FBX in ART (the storage unit, the corridor kit's pieces) becomes
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
	-- the unit's sizes S and L join when their FBX is built
	{
		key = "M",
		path = "art/unit/out/StorageUnit_M.fbx",
		manifest = "art/unit/assets.json",
		description = "A self-storage unit with a working roll-up door",
	},
	{
		key = "Straight",
		path = "art/corridor/out/Corridor_Straight.fbx",
		manifest = "art/corridor/assets.json",
		description = "A straight stretch of a storage building's hall: its floor and steel ceiling",
	},
	{
		key = "Fixture",
		path = "art/corridor/out/Corridor_Fixture.fbx",
		manifest = "art/corridor/assets.json",
		description = "A storage building's hall light: a strip light on two chains with a motion sensor",
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
