# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 17 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The corner, T and cross are built** (P0-03d, D-023): 24-stud squares on the straights' grid,
  built in Blender from `art/corridor/` (`pieces.junction`), uploaded (Corner 130232251748500,
  T 126231203439559, Cross 76740441869136) with a new **short wall** (an S unit's 8,
  104832527772407), and stored in the place at `ReplicatedStorage.Corridor`.
- **The ceiling at a junction:** every straight's deck runs along its own hall; a junction's
  continues its X arms, and a joist girder (a closure plate on top) carries the seam across each
  Z arm's mouth. A steel column covers each corner where two walls meet.
- **Code:** `CorridorKit.junction(name, cframe, paint, parent)` lays one turned as needed and
  stands its walls from `Specs.Junctions` (arms, walls). A piece's frame is now its floor part's
  own frame (the importer keeps FBX axes, `docs/STUDIO.md`). The test hall ends in a T under the
  exit sign: a dead end one way, a dim hall to a corner and a dark hall the other.
- **Verified in Studio** (Galaxy A16, Level01 and Level21, a debug fill light;
  `docs/art/P0-03d-*.jpg`): the four imported whole, their frames match the spec; no seam where
  the T meets the hall or its arm, the girder reads. The corner was seen once; Studio then stopped
  answering captures, so walking it and the render cost are the owner's (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-03 Motion lights the building watches
The moment: freezing under a light that just clicked on. The hall lights as you walk it, pools of
light and dark between, and each fixture's eye flares when it sees you.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's "Lights" (docs tools; search "motion light") and Brix's Zone
   (`docs/FRAMEWORK.md`): a fixture's watch area is a Zone.
3. A server-owned light system: each fixture wakes for anything moving in its zone and falls dark
   a while after it leaves (feel numbers in shared Config, each with a comment). Set every light
   through `HallLight` so `BehindDoors` keeps scaling it.
4. The eye shows its state: Watching while dark, a flare to Seen as it trips, with the GDD's
   click; Blind in a cut zone. Replicate state, not per-frame values.
5. Budget: three lit fixtures awake near a player (each is two lights, D-017); real lights near
   the camera, a glow farther out. Hang the test hall's fixtures through it.
6. Judge at phone size, Level01 and Level21; shots `docs/art/L-03-*.jpg`.
**Acceptance:** checks green; walking the test hall wakes the lights ahead and darkens those
behind; each wake answers with the eye's flare and the click; the owner judges.
**Read first:** `docs/ROADMAP.md` (L-03); the GDD's "Lights"; `docs/FRAMEWORK.md` (Zone);
`src/shared/HallLight.luau`; `src/server/DevCorridor.luau` (`fixture`, `TURN_FIXTURES`);
`src/shared/CorridorKit/init.luau` (`hang`).

## Queue (the next run's order, from ROADMAP)
1. **P0-04 The door's sounds and feel**, then **Phase 1** (ROADMAP). L-01 lays floors with
   `place`, `junction` and `wall`; its junction rules are in ROADMAP (a straight between two
   junctions; one of the two first slots beside a block of wall is a plain wall).
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
3. **Polish waiting** (ROADMAP): the kit's own copies of the unit's textures; cheaper chain links;
   a red glow round a Seen eye; a faint haze edge near the ceiling at low graphics; a peeked unit
   lights evenly at low graphics; re-run `UnitKit.prepare` so the template saves at 1.2 deep;
   sizes S and L; a client-side door collider; the padlock is too small; the cursor hint once
   ever; the junctions' overlapping decks seen from a unit.
4. In Edit, `require` a `:Clone()` of a module for fresh code (docs/STUDIO.md). Any reader of the
   units' tag skips the template. Measure render cost early: captures can stop answering.
5. Play logs `rbxassetid://203785492 ... Asset type does not match` six times; not from this
   ticket's code (not in the repo); find its source when convenient.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
