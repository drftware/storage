# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 27 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04c is done in Blender** (D-035): the 1980s bedroom set's first four finds, a boombox, a
  portable TV, a mended teddy and a pair of roller skates, real sizes at 10 inches a stud, one
  MeshPart each on one Bedroom atlas (colour, normal, roughness, metalness; 99 texels a stud),
  dusty on top, 1,004 to 2,248 triangles. `art/finds/` (README, `spec.py`, `build.py`), sheets
  `art/sheets/finds-*.png`; `Finds` (`prepare`, `clone`) and its generated `Specs` in
  `src/shared/Finds/`; `scripts/art.sh finds`; the `Bedroom` entry in `scripts/upload_art.luau`.
- **Not in Studio yet:** not uploaded, not imported, not judged at phone size. In Blender's unit
  shot (`finds-unit.png`, a dim warm bulb, from the doorway) all four read plainly among the boxes.
- The pipeline met four Blender traps (`docs/STUDIO.md`, "Blender traps"): the build now stops if
  two faces share texels, and every stage prints the faces on unpainted texels (4 to 8 hairline
  bevel faces a find is normal; dozens means the saved unwrap no longer fits: rerun textures).
- Studio is in Edit, Device Simulator off. `rojo serve` runs on port 34872.

## Next task: L-04c2 The finds into Studio
The moment: the door goes up, the bulb stutters on, and there's something in there worth taking.
1. Owner test results first (`OWNER.md`): any swap among the four, and the set's next pieces.
2. `scripts/art.sh finds` only if `art/finds/` changed since this commit (the FBX in `out/` is
   current); then `lune run scripts/upload_art Bedroom`.
3. Insert the asset and prepare each find into `ReplicatedStorage.Props.Finds`
   (`art/finds/README.md`, "Into Studio"); check CollisionFidelity took (Box for the boombox and
   TV, Hull for the teddy and skates) and that each SurfaceAppearance has all four maps.
4. Judge on the Galaxy A16 view at Level01 and 21, in Play: clone the four into 101 among its
   boxes (`Finds.clone`), open it, look from the doorway under its bulb. Each must read for what
   it is at phone size; capture `docs/art/L-04c-finds.jpg`. If one doesn't read, tune it in
   `art/finds/spec.py` (colour, size, dust) and rebuild.
**Acceptance:** checks green; four templates at `ReplicatedStorage.Props.Finds`; each find
readable from 101's doorway under its bulb at phone size, judged in Studio; `OWNER.md` says what
to judge and that the place needs saving.
**Read first:** `art/finds/README.md`; `docs/STUDIO.md` ("Getting assets into Roblox",
"SurfaceAppearance", "Importing kit pieces"); `src/shared/Finds/init.luau`; `OWNER.md` (L-04c).

## Queue (the next run's order, from ROADMAP)
1. L-04d the director (it deals finds: tiers per find are its call, OWNER.md), then L-05 to L-08,
   and L-10 (the map) after L-05. L-05 adds "flash every light" to `MotionLights` and builds the
   lobby and elevator where `FloorBuilder`'s stand-in is; L-06's keepers hear doors on
   `Doors.acted`; L-08 lays the next floor during the ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): the finds' printed words; the bedroom set's other pieces; a
   mimic's clean finds; the teddy's fuzz and the atlas's room; a unit's bulb swinging after a
   slam; the guard's bars as a soft stripe; the boxes' second look and the wardrobe's bar; a door
   answering before the server's word; tool buttons per player; the cutters' snip; a lifted
   door's grace; a laid floor's draw cost on a phone; the L unit; the bolt and padlock moving; a
   shut door muffling sounds; a less-shake setting; a sound mix; a lit tube's hum; fading a far
   pool; the kit's texture copies; cheaper chain links; a red glow round a Seen eye; a haze edge;
   a client-side door collider; the padlock too small; the cursor hint once ever; the junctions'
   overlapping decks.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s; CollisionFidelity won't set from the MCP; set the Device Simulator's device before
   its orientation; a capture's camera across the hall can land inside the opposite unit.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
