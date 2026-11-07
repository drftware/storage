# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 16 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The plain wall and the dead end are built** (P0-03c, D-022): a unit's front without the
  door, the units' painted corridor wall to 10 with an R-panel above to the deck. The plain wall
  (`Wall`, 12 wide) takes a unit's place on the door faces' line; the dead end (`DeadEnd`, 32
  wide) closes a hall's end and the deck over it. Built in Blender from `art/corridor/`
  (`pieces.plain_wall`, `dead_end`), uploaded (Wall 138816629045048, DeadEnd 100123098873935) and
  stored in the place at `ReplicatedStorage.Corridor`.
- **Code:** `CorridorKit.wall(name, cframe, paint, parent)` puts one up at a door-face frame;
  `frame` reads a wall's from its flat Facade and the Panel behind it. The test hall has four
  plain walls past the last units and a dead end at each end. `HallLight.exitSign(sign, facing)`
  now hangs its glow 1.5 off the wall (dimmer: 0.2, range 10), so the far end reads as a wall.
- **Verified in Studio** (Galaxy A16, Level01 and Level21, `docs/art/P0-03c-*.jpg`): both import
  whole and prepare with the frame facing the hall; no seams where they meet units, the floor or
  the deck; the end reads as a wall from the spawn. From the spawn: 73,844 triangles in 28
  opaque draws (was 71,400 in 21). Walking into the corners is the owner's (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: P0-03d The corner, T and cross
The moment: the blind corner. You round a turn not knowing what waits, and the building still
looks like one building there: no seam in the floor, the ceiling's steel carried round.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's tech plan "Layout" (docs tools; search "Layout") for the tile set.
3. Decide the deck: a real building's deck and joists run one way over every hall, but the
   straight piece's flutes run along its own hall, so a turned piece's run across. Pick (a) one
   way for the whole floor (a turned straight wears a deck turned back), or (b) junction pieces
   that bridge both. Default (a) if it keeps the seams away; record it in DECISIONS.
4. Model the junctions in `art/corridor/` on the 8-stud floor joint and the 6-stud joist beat:
   the corner, T and cross, each with its own FBX; the walls a junction needs come from
   `CorridorKit.wall` (plain walls on its closed sides, a dead end for a T's stub if needed).
5. Teach `CorridorKit` their names and frames; add a turn to the test hall (`building`) so a
   corner and a T can be walked, keeping the 24-stud grid (D-020).
6. Judge at phone size, Level01 and Level21, at each joint; shots `docs/art/P0-03d-*.jpg`;
   update the render cost.
**Acceptance:** checks green; each junction imported and placed, no seams at its joints with the
straight pieces; shots; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-03d); the GDD's "Layout"; `art/corridor/README.md`;
`art/corridor/pieces.py` (`floor`, `deck`, `ceiling`); `src/shared/CorridorKit/init.luau`
(`frame`); `src/server/DevCorridor.luau` (`building`).

## Queue (the next run's order, from ROADMAP)
1. **L-03 Motion lights** (moved up by the owner, Nov 7): fixtures wake as you walk the hall,
   server-owned, through `CorridorKit.hang`, `HallLight.light` and `HallLight.eye` (the eye flares
   to Seen as it trips, with the GDD's click). A lit fixture is two lights (D-017); the owner
   judges the three-fixture budget once built.
2. **P0-04 The door's sounds and feel**, then **Phase 1** (ROADMAP). L-01 lays pieces with
   `CorridorKit.place`, hall sides as 12-stud slots of units or `CorridorKit.wall("Wall", ...)`,
   and a dead end on any open end; fixtures go midway between joists.
3. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
4. **Polish waiting** (ROADMAP): the kit's own copies of the unit's textures; cheaper chain links;
   a red glow round a Seen eye; a faint haze edge near the ceiling at low graphics; a peeked unit
   lights evenly at low graphics; re-run `UnitKit.prepare` so the template saves at 1.2 deep;
   sizes S and L; a client-side door collider; the padlock is too small; the cursor hint once ever.
5. In Edit, `require` a `:Clone()` of a module for fresh code (docs/STUDIO.md). Any reader of the
   units' tag skips the template.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
