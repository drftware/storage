# The corridor kit

The building's hall, as pieces a floor is laid from (the GDD's tile set: straight, corner, T,
cross, dead end). Built from code in Blender 5.2, the way the unit is (`art/unit/README.md`), and
wearing the unit's own baked texture sets, so the kit bakes nothing.

| | |
|---|---|
| ![hall](../sheets/corridor-hall.png) | ![ceiling](../sheets/corridor-ceiling.png) |

Sheets in `art/sheets/`: `corridor-hall` (a player's eyes down two pieces), `corridor-ceiling`
(looking up under a light), `corridor-seam` (straight down on the joint between two pieces). The
units there are plain stand-in boxes; the light is render dressing. In-game shots are in
`docs/art/P0-03a-*.jpg`.

## Built so far

**Straight** (P0-03a): 24 studs of hall, the length of two M units a side (three S) and one hall
light's stretch. Two MeshParts:

| Part | Set | Tris | What it is |
|---|---|---|---|
| Floor | Concrete | 12 | the hall's slab between the two rows of door faces, top at 0 |
| Ceiling | TrimSheet | 1700 | a corrugated steel deck (painted strip) over the hall and the units either side, on four open-web steel joists (raw-steel strip) |

A hall of straight pieces draws in two calls: Roblox instances identical meshes.

## Numbers (studs; `spec.py` holds them all)

| | |
|---|---|
| Frame | origin at the middle of the hall floor, on the floor; the hall runs along X |
| Hall | 8 wide, door face to door face |
| Ceiling | 32 across (the hall and a 12-deep row of units each side); deck underside 14, closed top 14.35 |
| Joists | every 6, half a spacing in from each end; lowest steel at 12.8 |
| Floor texture | repeats every 8 with a saw-cut joint on its edge; a piece's UVs start on that edge |

Why these: pieces are a multiple of 8 long, so two pieces meet on a joint and never show a seam,
and a multiple of 6, so the joists keep their beat across pieces. The haze under a lit tube
reaches 12.6 (`HallLight.HazeHeight` 9.6 plus a puff's 3), and low graphics draws a hard line
where a puff cuts into anything, so the joists stop at 12.8. `tests/corridor.spec.luau` holds
those rules against the game's numbers, and the export refuses to build if the haze would reach
the joists.

## Into Studio

1. **Build and upload:** `scripts/art.sh corridor` (under a minute), then
   `lune run scripts/upload_art`. Each piece is its own FBX, `out/Corridor_<Piece>.fbx`, and its
   own Model asset, recorded in `assets.json`. Blender stamps the export time into the FBX, so a
   rebuild always uploads again (in place, same ID).
2. **Insert and prepare** (through Studio's MCP or the command bar), with Rojo synced:
   ```lua
   -- insert_asset(<id from assets.json>) into Workspace, then:
   local CorridorKit = require(game.ReplicatedStorage.Shared.CorridorKit)
   local m = workspace.Corridor_Straight
   m:FindFirstChildOfClass("PackageLink"):Destroy() -- a plain model, not a package
   -- remove the insert's "Assistant:<guid>" tag too
   CorridorKit.prepare(m, "Straight")
   m:PivotTo(CFrame.identity)
   m.Name = "Straight"; m.Parent = game.ReplicatedStorage.Corridor -- make the folder once
   ```
   `prepare` finds the piece's frame from its floor's own box (the insert turns it to some angle
   about Y), anchors everything, takes the meshes out of physics and adds box colliders from the
   spec (the floor is Concrete and the ceiling Metal, for footsteps), pivots the model on its
   frame and streams it whole.
3. **Save the place.** The template lives in it (D-009). `CorridorKit.place("Straight", cframe,
   parent)` clones it into a floor; `DevCorridor` lays three.

## How it's made

```
art/corridor/spec.py    every number; writes src/shared/CorridorKit/Specs.luau
art/corridor/pieces.py  the pieces' parts, UV-mapped with the unit's mappers (art/unit/geo.py)
art/corridor/build.py   stages: export (FBX + Specs) | renders (look sheets)
```

It imports the unit's `geo`, `bake` (textured materials), `nodes` and `render` helpers, and reads
the unit's baked maps from `art/unit/out/textures/`.

## Next

- **P0-03b The fixture:** the motion light, the building's eyes, hung between two joists.
- **P0-03c The junctions:** corner, T, cross and dead end, and the plain walls a hall has where
  no unit stands (the test hall uses plain blocks for now).
