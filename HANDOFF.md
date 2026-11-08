# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 25 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-04 is split in four** (ROADMAP): L-04a the moving boxes (done), L-04b the unit's own light,
  L-04c the first finds, L-04d the director dealing each unit on open.
- **L-04a is done** (D-032): five boxes at real moving-box sizes (Small, Medium, Large, Wardrobe,
  Open with its flaps up), one MeshPart each on one 1024² Cardboard atlas at 97 texels a stud.
  `art/boxes/` builds them (`scripts/art.sh boxes`); asset in `art/boxes/assets.json`. `Boxes`
  (`src/shared/Boxes`) has `prepare`, `clone` and the generated Specs. Templates are in the place
  at `ReplicatedStorage.Props.Boxes`, unsaved until the owner saves (`OWNER.md`).
- **Verified in Studio** (Galaxy A16 view, Play): ten boxes in unit 101 with its door open stand
  on the floor and read as boxes from the doorway, but only in a stand-in torch
  (`docs/art/L-04a-unit-torch.jpg`): the hall light stops at the doorway.
- **The owner's call** (D-033): a small dim light in each unit; players carry no torch. Default
  in `OWNER.md`: it comes on with the door and goes out when the door is shut.
- CollisionFidelity can't be set from the MCP; the owner sets it (`OWNER.md`).
- `rojo serve` runs on port 34872; Studio in Edit, Device Simulator off, Quality on Automatic.

## Next task: L-04b The unit's own light
The moment: the door goes up and a weak bulb stutters on over whatever's in there.
1. Owner test results first (`OWNER.md`), and any answer on the bulb staying on in a shut unit.
2. Read the GDD's "Lights" section only (the cap on real lights for low-end phones).
3. Art: a caged bulb on a short cord, as a piece of the corridor kit beside the hall fixture
   (`art/corridor/pieces.py`): cage and cap on the unit's TrimSheet, the glass a plain part the
   game colours Neon (as the fixture's lens). FBX, Specs, look sheet; upload and import.
4. Hang one in every unit, S and M, from the wire top's middle (`FloorBuilder` and the test hall),
   low enough to light the back wall and the boxes, high enough not to hit a head.
5. A client system beside `HallLights`: a unit's bulb comes on as its door rises (a peek lets a
   little out) with a click and a stutter, hums faintly near it, and goes out when the door shuts.
   A dim warm PointLight; only the 3 nearest lit bulbs throw light, the rest only glow. Numbers
   in shared Config with what each does to the player.
6. Judge on the Galaxy A16 view at Level01 and 21: 101 opened with the L-04a test stack inside
   (the Command Bar line in `OWNER.md`): the boxes seen from the doorway, dim, the back corners
   still dark; a shut unit black inside but for the line under the door.
**Acceptance:** checks green; a bulb in every unit, lighting with its door, judged in Studio at
phone size; `OWNER.md` says what to judge and the template to save.
**Read first:** `docs/ROADMAP.md` (L-04b); the GDD's "Lights"; `src/shared/HallLight.luau`;
`src/client/HallLights.luau`; `art/corridor/pieces.py` (the fixture); `docs/STUDIO.md` (Lighting).

## Queue (the next run's order, from ROADMAP)
1. L-04c the first finds (the 1980s bedroom set, built the boxes' way), L-04d the director, then
   L-05 to L-08, and L-10 (the map) after L-05. L-05 adds "flash every light" to `MotionLights`
   and builds the lobby and elevator where `FloorBuilder`'s stand-in is; L-06's keepers hear
   doors on `Doors.acted` (each event's `reach`); L-08 lays the next floor during the ride.
2. **Before the ladder** (ROADMAP Phase 2): close a run's back (the 16-stud gap, no floor or deck)
   and its ends at a junction's hollow block; a wire top leaves 2.8 studs under the joists.
3. **Polish waiting** (ROADMAP): the boxes' second look and the wardrobe's bar; a door answering
   before the server's word; tool buttons per player; the cutters' snip; a lifted door's grace; a
   laid floor's draw cost on a phone; the L unit; the bolt and padlock moving; a shut door muffling
   sounds; a less-shake setting; a sound mix; a lit tube's hum; fading a far pool; the kit's
   texture copies; cheaper chain links; a red glow round a Seen eye; a haze edge; a client-side
   door collider; the padlock too small; the cursor hint once ever; the junctions' overlapping
   decks (and crossing lids) seen from the tops.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts or far, unstreamed areas; standing still lets the hall go dark
   in 7.5 s, so walk a step before a lit capture; CollisionFidelity won't set from the MCP.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
