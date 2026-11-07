# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 14 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **P0-03 is split** (ROADMAP): a, the straight piece (done); b, the motion-light fixture; c, the
  junctions (corner, T, cross, dead end, plain walls).
- **The straight hall piece is built** (P0-03a, D-020): 24 studs of hall, a concrete floor between
  the doors and a corrugated steel deck on open-web joists over the hall and its units. Built in
  Blender from `art/corridor/` on the unit's own textures (nothing new baked), uploaded through
  Open Cloud (`scripts/upload_art.luau`, renamed from `upload_unit`, now lists every FBX), and
  stored in the place at `ReplicatedStorage.Corridor.Straight`. `CorridorKit` (src/shared) finds a
  piece's frame, prepares the template and places copies.
- **The test hall stands on three pieces:** end walls moved from 30 to 36, spawn to x = -32,
  plain walls past the last units. Without the template it falls back to plain blocks.
- **Verified in Studio:** the piece imports whole, prepares to floor top 0 and joists 12.8; the
  hall reads at phone size at Level01 and Level21 (`docs/art/P0-03a-phone.jpg`); 65,000 triangles
  and 18 opaque draw calls from the spawn. Not checked: footsteps on the floor's collider, two
  players.
- **The template must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: P0-03b The motion-light fixture
The moment: the building's eyes. You look up and see the fixture that will see you: a housing,
its tube, and a small sensor that shows it is watching. L-03 then lights it as you walk.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's Lights section (docs tools) for what the fixture must show.
3. Model it in `art/corridor/` beside the straight piece: housing and diffuser (the tube where
   `HallLight.Height` hangs it, `HallLight.TubeSize`), two chains up to the deck between two
   joists, a sensor eye. The look sheets' fixture is the reference (`art/unit/render.py`,
   `corridor()`). Its own FBX and asset; TrimSheet for the steel; the diffuser and the sensor's
   pip need parts L-03 can light (a Neon or glowing part the game recolours).
4. Fit it to `HallLight.light`: the tube part it lights should be the fixture's diffuser, so
   `DevCorridor.fixture` places the fixture model and lights that part.
5. Judge at phone size, Level01 and Level21, lit and dark; shots `docs/art/P0-03b-*.jpg`.
**Acceptance:** checks green; fixture imported and hung in the test hall, lit through
`HallLight.light`; shots; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-03b, L-03); the GDD's Lights section;
`art/corridor/README.md`; `art/corridor/pieces.py`; `src/shared/HallLight.luau` (top numbers and
`light`); `src/server/DevCorridor.luau` (`fixture`, `building`).

## Queue (the next run's order, from ROADMAP)
1. **P0-03c The junctions:** corner, T, cross, dead end and the plain wall, on the straight
   piece's grid (8-wide hall, ceiling 32 across); replaces the test hall's plain blocks.
2. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, set through `HallLight.light` so the fill, the haze and `BehindDoors` follow.
   A lit fixture is two lights (D-017); the owner judges the three-fixture budget once built.
3. **P0-04 The door's sounds and feel**, then **Phase 1** (ROADMAP). L-01 lays pieces with
   `CorridorKit.place`; pieces come in 24-stud steps (D-020), so a generator needing 12-stud
   steps would need a half piece whose floor UVs start mid-texture.
4. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`).
5. **Polish waiting:** a faint haze edge near the ceiling at low graphics; at low graphics a
   peeked unit lights evenly; re-run `UnitKit.prepare` so the template saves at 1.2 deep; sizes S
   and L by eye; a client-side door collider if the lag feels wrong; the padlock is too small to
   spot; the cursor hint once ever.
6. **Particles added later** are thinned on low graphics too; judge them in their steady state
   (docs/STUDIO.md). Any reader of the units' tag skips the template.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
