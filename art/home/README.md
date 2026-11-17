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

Home.fbx: 10,664 triangles in 25 parts. Sheets (drawn by `art/lobby`): `lobby-home.png` (your
unit from the floor), `lobby-nook.png` (a bench and a planter), `lobby-unit.png`,
`lobby-inside.png`, `lobby-spawn.png`.

## Into Studio (S5-03a2b3, D-268)

`lune run scripts/upload_art Home` (asset 110439035194989 in `assets.json`), then in Edit load it
(`InsertService:LoadAsset`), `require(game.ReplicatedStorage.Shared.Home).prepare(model)` and put
it at `ReplicatedStorage.Props.Home`. `Lobby.lay` dresses every unit's gap and the floor from it.
