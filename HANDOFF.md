# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 20 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-01a is done** (D-027): a floor is pure data from a seed, `src/shared/Floor.luau`.
  `Floor.generate(number, Brix.Random.new({ seed = n }))` returns the hall pieces at their frames
  (straights, corners, Ts, crosses, the lobby at the origin with its elevator toward +Z), every
  slot along a hall (a unit with its size, number and side walls to leave out, or a plain wall),
  the dead ends, a motion light over every piece with its power zone, and the doors' paint.
  Junctions sit 48 studs apart with a straight between each two; halls grow from the lobby as a
  tree, then loops join near ones. Short floors (1, 2) hold about 60 units, full ones about 80.
- **Tested in Lune only** (nothing ran in Studio): `tests/floor.spec.luau` checks 400 floors
  against every rule in D-027 and the kit's sizes and junction walls; breaking the back-corner
  rule or moving the lights makes it fail (tried). `lune run scripts/floor-map 7 3` prints a map.
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-01b The S unit into the game
The moment: a row of small doors, three to a stretch, is the cramped part of the building; the
floors now place S rows and S slots at every corner, so L-01c can't lay a floor without one.
1. Owner test results first (`OWNER.md`).
2. Export S: `SIZE=S scripts/art.sh geo export` (art/unit/README.md) writes
   `src/shared/StorageUnit/Specs/S.luau` and `art/unit/out/StorageUnit_S.fbx`. Render its look
   sheet and judge it beside the M: 8 by 8, a 6-wide door; the slats must not stretch.
3. If the curtain differs by size, give `tests/curtain.spec.luau` an S fixture from
   `art/unit/fixture.py`, as M has.
4. Upload it (`scripts/upload_art.luau`), insert it in Studio through the MCP,
   `UnitKit.prepare(model, "S")`, keep it at `ReplicatedStorage.Units.S`; add it to `OWNER.md`'s
   save-the-place line.
5. Put an S in the test hall (DevCorridor) and run every door action on it in Studio: Peek,
   Open, Close, Slam, Lock, Lift from inside; check the door's collider fits and the sounds' cues
   land on its strikes (the poll in docs/STUDIO.md, "Measuring a sound").
6. Phone-size shots beside an M (Galaxy A16, Level 01 and 21): `docs/art/L-01b-*.jpg`.
**Acceptance:** checks green; the S template in the place; every door action on an S verified in
Studio with no errors in Output; shots and what to judge in `OWNER.md`.
**Read first:** `art/unit/README.md` (building a size, "Into Studio"); `docs/ROADMAP.md` (L-01,
and the polish line on sizes S and L); `src/shared/StorageUnit/UnitKit.luau` (`prepare`);
`src/shared/StorageUnit/Specs/init.luau`; `scripts/upload_art.luau` (its header);
`src/server/DevCorridor.luau` (`placeUnit`, the far unit 901).

## Queue (the next run's order, from ROADMAP)
1. **L-01c** lays a floor in Studio from `Floor` (ROADMAP L-01): pieces at `Floor.dir(turn)`,
   units painted `UnitKit.Colours.Door[floor.paint]` and numbered, `drops` mapped to WallLeft or
   WallRight by which side each stands (DevCorridor's `dropSharedWall`), `CorridorKit.junction`
   taught to leave out the kit's wall where `Floor.JunctionSlots` puts a unit, fixtures tagged
   with `MotionLight.PowerAttribute` set to their zone, the lobby a stand-in until L-05. Print
   `Floor.map` to Output for the seed laid.
2. Then L-02 (doors as the GDD's state machine; a padlocked door rattles when tried), L-04 to
   L-08. L-05 adds "flash every light" to `MotionLights` for the wrong code and builds the lobby
   in the room `Floor.LobbySize` and `Floor.ElevatorDepth` hold; L-06's keepers hear doors by
   `DoorSound.Actions`.
3. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
4. **Polish waiting** (ROADMAP): L units on a floor (a dead end's far wall); the bolt and padlock
   moving; a shut door muffling sounds; a less-shake setting; a sound mix; a lit tube's hum;
   fading a far pool; the kit's own texture copies; cheaper chain links; a red glow round a Seen
   eye; a haze edge at low graphics; a client-side door collider; the padlock too small; the
   cursor hint once ever; the junctions' overlapping decks seen from a unit.
5. In Edit, `require` a `:Clone()` of a module (docs/STUDIO.md). Play logs
   `rbxassetid://203785492 ... Asset type does not match` six times, not from this repo's code.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
