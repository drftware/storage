# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 15 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The hall light is built** (P0-03b, D-021): a steel strip light on two jack chains from the
  deck, midway between two joists, with a motion sensor on one end whose red half-sphere dome is
  the building's eye. Built in Blender from `art/corridor/` (`pieces.fixture`), its lens read from
  `HallLight.Height` and `TubeSize` so it sits exactly where the light was tuned; uploaded (asset
  71843070521517) and stored in the place at `ReplicatedStorage.Corridor.Fixture`.
- **Code:** `CorridorKit.hang(cframe, parent)` puts one up and returns `{ model, diffuser, eye }`;
  `HallLight.light(diffuser, level)` lights the lens as before; the new `HallLight.eye(eye,
  state)` sets Watching (red glow), Seen (full red) or Blind (dead plastic). The test hall hangs
  three: weak by the spawn (-18), lit over 105 (6, eye Seen), dead past the last units (30).
- **Verified in Studio** (Galaxy A16, Level01 and Level21, `docs/art/P0-03b-phone.jpg`): the
  fixture imports whole with the lens and eye untextured, prepares to lens middle 12.1; reads as
  a hung light up close; the eye stays a clean dot at full red at both qualities; no haze edge
  on the housing at Level01. From the spawn: 71,400 triangles in 21 opaque draws (was 65,400 in
  18); each fixture is about 2,000 triangles, half of it chain.
- In a fully dark hall only the nearest eye or two read on a phone (a sharp dot, then
  pin-pricks); the owner judges that (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `scripts/upload_art` now takes keys (`lune run scripts/upload_art Fixture`).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: P0-03c The plain wall and the dead end
The moment: the hall that stops. You sprint round a turn and hit a wall with nothing to hide
behind, and a keeper can wait at the mouth (GDD: Dead ends). And where no unit stands, the hall
still reads as the same building.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's "Dead ends" line and the tech plan's "Layout" (docs tools; search "dead end").
3. Model both in `art/corridor/` on the straight piece's grid and the unit's textures: the plain
   wall (a hall side with no unit: what a real storage building has there) as a piece or a wall
   panel that fits the 12-stud unit beat, and the dead end (end wall at the hall's end, the deck
   and floor closed off). Own FBX each, or one with parts; colliders from the spec.
4. Teach `CorridorKit` their names, prepare and place them; replace `DevCorridor`'s plain bay
   walls and end walls (`building`). Keep the exit sign readable on the far end wall.
5. Judge at phone size, Level01 and Level21, looking down the hall both ways; shots
   `docs/art/P0-03c-*.jpg`; update the render cost.
**Acceptance:** checks green; both imported and placed in the test hall with no seams or gaps
against the straight pieces and units; shots; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-03c); the GDD's "Dead ends" and "Layout"; `art/corridor/README.md`;
`art/corridor/pieces.py` (`floor`, `ceiling`); `src/server/DevCorridor.luau` (`building`);
`src/shared/CorridorKit/init.luau` (`prepare`).

## Queue (the next run's order, from ROADMAP)
1. **P0-03d The corner, T and cross:** the floor's joints and the deck's ribs and joists carried
   round a turn and across a crossing without a seam.
2. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, through `CorridorKit.hang`, `HallLight.light` and `HallLight.eye` (the eye flares
   to Seen as it trips, with the GDD's click). A lit fixture is two lights (D-017); the owner
   judges the three-fixture budget once built.
3. **P0-04 The door's sounds and feel**, then **Phase 1** (ROADMAP). L-01 lays pieces with
   `CorridorKit.place`; pieces come in 24-stud steps (D-020); fixtures go midway between joists.
4. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`).
5. **Polish waiting** (ROADMAP): cheaper chain links if triangles bite; a red glow round a Seen
   eye if the light budget allows; a faint haze edge near the ceiling at low graphics; a peeked
   unit lights evenly at low graphics; re-run `UnitKit.prepare` so the template saves at 1.2 deep;
   sizes S and L; a client-side door collider; the padlock is too small; the cursor hint once ever.
6. In Edit, `require` a `:Clone()` of a module for fresh code (docs/STUDIO.md). Any reader of the
   units' tag skips the template.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
