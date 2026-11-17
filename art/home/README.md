# The home

The home's kit (D-259, D-263): what makes the ground floor and its units a calm place of your
own rather than the climb. Built from code in Blender 5.2 headless, the unit's way
(`art/unit/README.md`).

## Texture sets (S5-03a2b1, D-264)

`scripts/art.sh home` bakes them into `out/textures` in seconds, with the unit's bake
(`art/unit/bake.py`, taught the sets' sizes by `build.register`). Recipes in `looks.py`.

| Set | Size | Tiles | What it is |
|---|---|---|---|
| Plaster | 512² | 4 x 4 studs | painted plaster: the paint is the part's Color (Overlay, the map's alpha near 0), the maps add a roller's stipple, a satin sheen and the faintest cloud |
| Wood | 1024² | 8 x 8 studs | oiled oak planks, twelve across, ends staggered, each plank its own shade, a fine bevel at every seam, no scratches |

The ground floor (`art/lobby`) wears both; its wood trim takes one plank of the Wood bake
drawn out along its length (`wood_uv`), so beams and rails show grain but no plank joints.
Sheets: `art/sheets/lobby-spawn.png`, `lobby-unit.png`, `lobby-inside.png`.

## The front and the furnishings (S5-03a2b2, D-266)

`scripts/art.sh home` runs `textures`, `door` (HomeDoor on the M's own door parts: build the
unit's M first) and `export` (`out/Home.fbx`, `src/shared/Home/Specs.luau`), under a minute.
More sets: Leaf (512x1024: four leaf columns, soil below V 0.12), Fabric (512², tinted),
Rug (512², baked colours), HomeDoor (1024², the DoorKit's layout, tinted).

| Part | Set | Tris | What it is |
|---|---|---|---|
| Facade, FacadeBack | Plaster | 36 each | the wall across the front, outside and in |
| Casing | Wood | 360 | casing, plinths, cornice, reveal lining, baseboards, rail |
| Frame | TrimSheet | 1348 | the M's mechanism only (`parts.frame(dress=False)`) |
| Switch, SwitchToggle | plain | 44 each | the plate and its rocker (pivot at its middle) |
| Lamp | plain | 76 | the unit's round ceiling lamp |
| CurtainClosed, Slat_A/B/C, BottomBar, LatchBolt, Hardware, Drum | HomeDoor | the M's | the door, kept new |
| Pot, Plant | Plaster, Leaf | 236, 528 | a snake plant in a cream pot |
| Bench | Wood | 404 | an oak bench with a back |
| Planter, PlanterSeat, PlanterPlants | Plaster, Wood, Leaf | 24, 176, 2196 | the island you sit round |
| Rug, Beanbag | Rug, Fabric | 12, 360 | the starter rug and beanbag |
| FloorLamp, LampShade | Wood, Fabric | 288, 192 | the starter floor lamp |
| Shelf, ShelfBack | Wood, Plaster | 372, 12 | the shelf (S5-03c1a, D-284): oak, six cubbies, a cream back |
| JobBox, JobBoxLid, JobBoxFittings, JobBoxRunners | Plaster, Plaster, plain, Wood | 760, 308, 432, 88 | the job box (S5-03c2a1, D-287): an open steel chest and its tray lid (the game paints them dusty blue), graphite handles, hasp and piano hinge, oak runners; the lid hinges on `Specs.JobBox.Hinge` |
| MirrorFrame, MirrorBevel, MirrorPads | Wood, plain, plain | 124, 32, 176 | the mirror (S5-03f1, D-314): a moulded oak frame mitred round the glass (`ring`), the glass's bevelled edge, felt pads; where it stands and its glass are `Specs.Mirror` |
| Rail, RailHangers, RailSteel, RailWheels | Wood, Wood, plain, plain | 660, 324, 636, 144 | the clothes rail (S5-03f2a, D-315): oak posts on castors, a shoe rack, a hat shelf with a gallery, oak hangers on a graphite bar; numbers `GARMENT*` in `home_spec.py` (`RAIL` there is the wall's paint rail); where it stands and its rows are `Specs.Rail` |

Home.fbx: 15,576 triangles in 38 parts (with the clothes rail, uploaded in place, S5-03f2a). Sheets (drawn by `art/lobby`): `lobby-home.png` (your
unit from the floor), `lobby-nook.png` (a bench and a planter), `lobby-unit.png`,
`lobby-inside.png`, `lobby-spawn.png`, `lobby-mirror*.png`, `lobby-rail*.png`.

## The looks a player gives their home (S5-03g1a, D-321)

What a player picks to make the unit theirs (idea 18; Animal Crossing's wallpaper and flooring,
Bloxburg's paint), calm and warm (D-263) with a couple of fun ones. Recipes in `looks.py`, the
palettes in `home_spec.py` (written to `Home.Specs.Looks`; ids are what a save keeps). Every floor
set tiles at 8 x 8 studs and every paper at 4 x 4, so one floor panel and one wall panel (UVs in
studs over the tile, S5-03g2) wear any. A look's colour is the part's Color (Overlay).
`scripts/art.sh home textures` bakes every set; to bake a few, `blender -b --factory-startup -P
art/home/build.py -- --stage textures --sets FloorTiles,PaperLeaves` (the rest keep their maps).

| Look | Set | Size | Tiles | What it is | Its colour |
|---|---|---|---|---|---|
| Boards | Wood | 1024² | 8 x 8 | the oak planks a home starts with | baked |
| Carpet | FloorCarpet | 512² | 8 x 8 | a soft cut pile, a heather of lighter fibres, faint vacuum lanes that come and go | Oatmeal, Sage, Rose, Denim, Cocoa |
| Checker | FloorTiles | 1024² | 8 x 8 | 1.33-stud glazed squares, cream ones baked, pale grout, rounded edges | Terracotta, Sage, Sky, Cherry, Charcoal |
| Matting | FloorMatting | 1024² | 8 x 8 | 2-stud interlocking rubber mats, square teeth at the joins, cream, clay, teal and mustard crumb | Charcoal, Slate, Forest, Plum, Clay |
| Plain | Plaster | 512² | 4 x 4 | painted plaster, as a home starts | the paint |
| Stripes | PaperStripes | 512² | 4 x 4 | half-stud satin cream stripes, a pinstripe down each painted one | the paint |
| Leaves | PaperLeaves | 1024² | 4 x 4 | a tossed leaf and a small one in every stud square, sage, deep green and olive | the paint |
| Daisies | PaperDaisies | 512² | 4 x 4 | a five-petal cream daisy, mustard middle, in every stud square | the paint |

Paints: WarmWhite `#E8DFCF` (a home's), Butter, Blush, Sage, DuckEgg, Lavender, Terracotta, Ink.
Door colours: Clay `#B5684E` (a home's), Mustard, Tomato, Rose, Plum, Sky, Mint, Cream, each
reading against the lobby's teal. `scripts/art.sh home looks` draws `art/sheets/home-floors.png`
(seconds): eight units as you walk in, each a floor, a paper and a paint, with the starter beanbag
and lamp; under them the door colours as flat doors on the teal, until g3 shows them on the door.
The sets aren't in Home.fbx: g2's panels carry them into Studio.

## Into Studio (S5-03a2b3, D-268)

`lune run scripts/upload_art Home` (asset 110439035194989 in `assets.json`), then in Edit load it
(`InsertService:LoadAsset`), run `prepare(model)` from a fresh copy of the Home module and put it
at `ReplicatedStorage.Props.Home`. `Lobby.lay` dresses every unit's gap and the floor from it.
The fresh copy matters: the MCP's Edit `require` keeps the first copy it loaded all session, so
clone all of `ReplicatedStorage.Shared` into a temporary folder in ServerStorage (Home's `Spots`
requires `"../Save"` by path, so a lone clone of Home fails to load), require its Home, then
destroy the folder (S5-03c2a2: a stale copy left the job box grey and unanchored). Check the
result: every new piece painted and `Anchored`, and `prepare`'s worst under a hundredth of a stud.
