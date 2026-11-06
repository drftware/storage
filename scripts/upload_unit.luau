--!strict
--[[
	Sends the storage unit's FBX to Roblox through Open Cloud, the way porch-pirates ships its art:
	no 3D Importer, no clicks. The first upload makes a Model asset; later ones update it in place,
	keeping its ID. The FBX's embedded textures arrive as SurfaceAppearances. Records each file's hash
	and asset ID in art/unit/assets.json; a session then inserts the asset in Studio and prepares it
	(art/unit/README.md, "Into Studio").

		lune run scripts/upload_unit        upload what changed since the last upload
		lune run scripts/upload_unit dry    say what would go up, touch nothing

	Needs .config/.env (git-ignored): ROBLOX_API_KEY (Assets read and write) and ROBLOX_CREATOR_ID
	(the key owner's user ID or username). The key is never printed.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local OpenCloud = require("./lib/OpenCloud")

local SIZES = { "M" } -- S and L join when their FBX is built
local MANIFEST = "art/unit/assets.json"
local MODEL: OpenCloud.Kind = { assetType = "Model", contentType = "model/fbx" }

local dry = process.args[1] == "dry"
local manifest: { [string]: { sha256: string, assetId: number } } = if fs.isFile(MANIFEST)
	then serde.decode("json", fs.readFile(MANIFEST))
	else {}

local session: OpenCloud.Session? = nil
local changed = 0
for _, size in SIZES do
	local path = `art/unit/out/StorageUnit_{size}.fbx`
	if not fs.isFile(path) then
		print(`upload_unit: {path} is missing; build it with scripts/art.sh`)
		process.exit(1)
	end
	local hash = serde.hash("sha256", fs.readFile(path))
	local entry = manifest[size]
	if entry and entry.sha256 == hash then
		continue
	end
	changed += 1
	if dry then
		print(`  would upload {path}{if entry then ` over {entry.assetId}` else " as a new asset"}`)
		continue
	end
	session = session or OpenCloud.session()
	local id = OpenCloud.upload(
		session :: OpenCloud.Session,
		path,
		MODEL,
		if entry then entry.assetId else nil,
		"A self-storage unit with a working roll-up door"
	)
	manifest[size] = { sha256 = hash, assetId = id }
	fs.writeFile(MANIFEST, serde.encode("json", manifest, true) .. "\n")
	print(`  {path} -> {id}`)
end
print(`upload_unit: {changed} changed{if dry then " (dry run)" else ""}`)
