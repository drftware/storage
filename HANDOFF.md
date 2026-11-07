# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 21 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-01b is done** (D-028): the small unit (8 by 8, a 6-wide door) is uploaded (asset
  121484947459865, `art/unit/assets.json`) and kept at `ReplicatedStorage.Units.S` beside the M,
  prepared by `UnitKit.prepare(model, "S")`. It wears the M's five texture sets: a narrower door
  shows the middle of the slats', bar's and drum's texture at the M's grain (`Spec.u_across`), and
  its hardware copies the M's atlas pack (`bake.copy_atlas`). Its curtain, motion and sound cues
  are the M's exactly (`tests/curtain.spec.luau` runs both fixtures).
- **The test hall** (DevCorridor): the short hall past the corner is three S a side, 109 to 114,
  112 padlocked; plain walls there if the place lacks the S template.
- **Verified in Studio** (one player, Output clean but the known `203785492` lines): on unit 110,
  through its prompts, Peek (1.15 in 1 s), Open (2 s), Close, Slam (lands 0.28 s, the bang on
  that frame, the bounce's clatter at 0.55 s), Lock (bolt 0.39 into the guide, padlock on, latch
  then snap), "Padlocked" on Open, Unlock, "Shut it first" on an open door, and Lift from inside
  (6 s heave, the top's clunk). The door's collider is 6 by 7.94 shut and a sliver at 7.71 open.
- **Phone shots** (Galaxy A16, Level 01 and 21): `docs/art/L-01b-rows.jpg`, `L-01b-doors.jpg`;
  Blender sheets `art/sheets/unit-S-*.png`. The owner judges them (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-01c Lay a floor in Studio from the data
The moment: a seed becomes a real floor you can walk, long aisles of doors in the dark with a
loop to run round and dead ends to get cornered in, the same every time for that seed.
If it won't fit one session, split it in ROADMAP first (say, laying halls and walls; then units
and lights).
1. Owner test results first (`OWNER.md`).
2. A server module that lays `Floor.generate(n, Brix.Random.new({ seed = s }))`: each hall piece
   at its frame (`Floor.dir(turn)`) with `CorridorKit.place` / `junction`; each slot a unit (the
   M or S template, painted `UnitKit.Colours.Door[floor.paint]`, numbered, its `drops` mapped to
   WallLeft or WallRight by which side it stands, as `DevCorridor`'s `dropSharedWall` does) or the
   kit's `Wall` / `ShortWall`; the dead ends; a fixture over every piece tagged
   `MotionLight.Tag` with `MotionLight.PowerAttribute` set to its zone; the lobby a plain stand-in
   room (`Floor.LobbySize`, `Floor.ElevatorDepth`) until L-05.
3. Teach `CorridorKit.junction` to leave out the kit's wall where `Floor.JunctionSlots` puts a
   unit.
4. Build in chunks (`task.wait` between) and parent each chunk once: about 80 units.
5. In Studio, lay a seed (a dev switch, or DevCorridor building a floor instead of its hall), print
   `Floor.map` to Output, walk it: no gaps at junction slots, lights waking, doors working.
**Acceptance:** checks green; a floor laid in Studio matches its printed map; no new errors in
Output; render stats from the lobby and a long aisle; shots and what to judge in `OWNER.md`.
**Read first:** `docs/ROADMAP.md` (L-01); `docs/DECISIONS.md` D-027; `src/shared/Floor.luau`
(its types, `dir`, `JunctionSlots`, `map`); `src/shared/CorridorKit.luau` (`place`, `junction`,
`wall`, `hang`); `src/server/DevCorridor.luau` (`unitRows`, `placeUnit`, `turn`).

## Queue (the next run's order, from ROADMAP)
1. Then L-02 (doors as the GDD's state machine; a padlocked door rattles when tried), L-04 to
   L-08. L-05 adds "flash every light" to `MotionLights` for the wrong code and builds the lobby
   in the room `Floor.LobbySize` and `Floor.ElevatorDepth` hold; L-06's keepers hear doors by
   `DoorSound.Actions`.
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
3. **Polish waiting** (ROADMAP): the L unit (render it; tile its wider door's texture rather than
   stretch it); L units on a floor; the bolt and padlock moving; a shut door muffling sounds; a
   less-shake setting; a sound mix; a lit tube's hum; fading a far pool; the kit's own texture
   copies; cheaper chain links; a red glow round a Seen eye; a haze edge at low graphics; a
   client-side door collider; the padlock too small; the cursor hint once ever; the junctions'
   overlapping decks seen from a unit.
4. In Edit, `require` a `:Clone()` of a module (docs/STUDIO.md). A teleported player doesn't wake
   the hall lights: walk a few studs before a capture (docs/STUDIO.md).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
