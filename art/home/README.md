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

## Still to build (S5-03a2b2)

The home front (a clean roll-up door in a warm colour on the climb's door rig, a painted frame,
a light switch plate inside by the door), potted plants and benches for the ground floor, and a
rug, a beanbag and a floor lamp for every unit.
