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

type Art = {
	key: string,
	path: string,
	manifest: string,
	description: string,
	image: boolean?, -- a picture (a find's glow mask), not an FBX: never updated in place
}
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
		key = "DentM",
		path = "art/unit/out/DoorDent_M.fbx",
		manifest = "art/unit/assets.json",
		description = "A storage unit's roll-up door slats, bowed out where something beat on it",
	},
	{
		key = "DentS",
		path = "art/unit/out/DoorDent_S.fbx",
		manifest = "art/unit/assets.json",
		description = "A small storage unit's roll-up door slats, bowed out where something beat on it",
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
		key = "Packrat",
		path = "art/packrat/out/Packrat.fbx",
		manifest = "art/packrat/assets.json",
		description = "A tall faceless bundle of grey moving blankets bound in packing tape, with long bare arms",
	},
	{
		key = "Elevator",
		path = "art/elevator/out/Elevator.fbx",
		manifest = "art/elevator/assets.json",
		description = "A freight elevator: its car, folding lattice gate, landing frame, keypad and a sticky note",
	},
	{
		key = "Lobby",
		path = "art/lobby/out/Lobby.fbx",
		manifest = "art/lobby/assets.json",
		description = "A self-storage building's front office at night: six freight elevator bays, a glass front door, a counter, shelves and a cart rack",
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
		key = "Coin",
		path = "art/coin/out/Coin.fbx",
		manifest = "art/coin/assets.json",
		description = "A worn old gold coin: a beaded rim, a keyhole stamped through its middle, a reeded edge",
	},
	{
		key = "Battery",
		path = "art/battery/out/Battery.fbx",
		manifest = "art/battery/assets.json",
		description = "A chunky D-cell battery: a black wrap with an amber band, a plus and a lightning bolt",
	},
	{
		key = "Machine",
		path = "art/machine/out/Machine.fbx",
		manifest = "art/machine/assets.json",
		description = "A self-storage supply vending machine: an oxblood cabinet, a glass front over coiled bays, push buttons and a coin plate",
	},
	{
		key = "Breaker",
		path = "art/breaker/out/Breaker.fbx",
		manifest = "art/breaker/assets.json",
		description = "A grey steel safety switch box on a plywood board: a side lever with a red grip, a pilot lamp, a conduit up the wall",
	},
	{
		key = "Packed",
		path = "art/packed/out/Packed.fbx",
		manifest = "art/packed/assets.json",
		description = "Stacks of cardboard moving boxes piled to the ceiling, as in a packed storage unit",
	},
	{
		key = "Stuff",
		path = "art/stuff/out/Stuff.fbx",
		manifest = "art/stuff/assets.json",
		description = "An old quilted mattress stood on its end and a rolled-up patterned rug tied with rope",
	},
	{
		key = "Saw",
		path = "art/saw/out/Saw.fbx",
		manifest = "art/saw/assets.json",
		description = "A cordless reciprocating saw: green body, black rubber boot and grip, a demolition blade",
	},
	{
		key = "AirHorn",
		path = "art/airhorn/out/AirHorn.fbx",
		manifest = "art/airhorn/assets.json",
		description = "A marine air horn: a white steel can with a black band, an orange trumpet in a black collar",
	},
	{
		key = "BubbleWrap",
		path = "art/bubblewrap/out/BubbleWrap.fbx",
		manifest = "art/bubblewrap/assets.json",
		description = "A roll of clear bubble wrap on a cardboard core, taped shut, and a sheet of it laid flat",
	},
	{
		key = "KeptWrap",
		path = "art/keptwrap/out/KeptWrap.fbx",
		manifest = "art/keptwrap/assets.json",
		description = "Clear stretch film wound in overlapping bands round a standing body, gathered over the crown",
	},
	{
		key = "FaintMark",
		path = "art/mark/out/FaintMark.fbx",
		manifest = "art/mark/assets.json",
		description = "A small hasty chalk ring with a dot in it, scrawled on a steel door frame",
	},
	{
		key = "Ladder",
		path = "art/ladder/out/Ladder.fbx",
		manifest = "art/ladder/assets.json",
		description = "An aluminium extension ladder, collapsed: base and fly sections, rope and pulley",
	},
	{
		key = "Cart",
		path = "art/cart/out/Cart.fbx",
		manifest = "art/cart/assets.json",
		description = "A platform cart: orange steel deck, rubber mat, push handle, four casters",
	},
	{
		key = "CrawlHole",
		path = "art/hole/out/CrawlHole.fbx",
		manifest = "art/hole/assets.json",
		description = "A crawl hole sawn through a storage unit's corrugated steel side wall, its cut-out panel",
	},
	{
		key = "TopHole",
		path = "art/tophole/out/TopHole.fbx",
		manifest = "art/tophole/assets.json",
		description = "A hole sawn down through a storage unit's steel top, its cut-out panel fallen below",
	},
}
local MODEL: OpenCloud.Kind = { assetType = "Model", contentType = "model/fbx" }
-- An Open Cloud "Decal" upload answers with the image's own ID, which a SurfaceAppearance's
-- EmissiveMaskContent takes (docs/STUDIO.md, "A find's glow mask").
local IMAGE: OpenCloud.Kind = { assetType = "Decal", contentType = "image/png" }

-- The finds kit's sets (art/finds/<set>/, art/finds/CRAFT.md): every find's FBX, and the glow
-- mask of each find that lights, join the list by themselves, keyed by the find's name.
local SETS = "art/finds"
local function spaced(name: string): string
	return string.lower(string.gsub(name, "(%l)(%u)", "%1 %2"))
end
local sets: { string } = {}
for _, dir in fs.readDir(SETS) do
	if fs.isDir(`{SETS}/{dir}`) and fs.isDir(`{SETS}/{dir}/out`) and fs.isFile(`{SETS}/{dir}/spec.py`) then
		table.insert(sets, dir)
	end
end
table.sort(sets)
for _, dir in sets do
	local out, manifest = `{SETS}/{dir}/out`, `{SETS}/{dir}/assets.json`
	local names: { string } = {}
	for _, file in fs.readDir(out) do
		local name = string.match(file, "^(%u%w*)%.fbx$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	for _, name in names do
		table.insert(ART, {
			key = name,
			path = `{out}/{name}.fbx`,
			manifest = manifest,
			description = `A {spaced(name)}: one of the finds in a storage unit`,
		})
		local mask = `{out}/textures/{name}_Emissive.png`
		if fs.isFile(mask) then
			table.insert(ART, {
				key = name .. "Emissive",
				path = mask,
				manifest = manifest,
				description = `Where a {spaced(name)} glows when it's on`,
				image = true,
			})
		end
	end
end

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
		if art.image then IMAGE else MODEL,
		if entry and not art.image then entry.assetId else nil,
		art.description
	)
	manifest[art.key] = { sha256 = hash, assetId = id }
	fs.writeFile(art.manifest, serde.encode("json", manifest, true) .. "\n")
	print(`  {art.path} -> {id}`)
end

-- Every kit-built find's asset IDs as Luau, so Studio can import a whole set in one call
-- (Finds/Kit.luau's `import`). Rewritten from the manifests on every run that uploads.
if not dry then
	local lines = {
		"--!strict",
		"-- Generated by scripts/upload_art.luau from art/finds/<set>/assets.json. Don't edit.",
		"-- Each find's uploaded Model asset and, if it lights, its glow mask's image (Finds/Kit.luau).",
		"",
		"return {",
	}
	for _, dir in sets do
		local manifest = manifestOf(`{SETS}/{dir}/assets.json`)
		local names: { string } = {}
		for key in manifest do
			if not string.match(key, "Emissive$") then
				table.insert(names, key)
			end
		end
		table.sort(names)
		table.insert(lines, `\t{string.upper(string.sub(dir, 1, 1))}{string.sub(dir, 2)} = \{`)
		for _, name in names do
			local mask = manifest[name .. "Emissive"]
			local glow = if mask then `, Emissive = {mask.assetId}` else ""
			table.insert(lines, `\t\t{name} = \{ Model = {manifest[name].assetId}{glow} \},`)
		end
		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")
	fs.writeFile("src/shared/Finds/Uploads.luau", table.concat(lines, "\n") .. "\n")
end
print(`upload_art: {changed} changed{if dry then " (dry run)" else ""}`)
