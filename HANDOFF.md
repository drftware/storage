# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 19 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **Phase 0 is done.** P0-04 gave the door its sounds and the slam its jolt (D-026). Each screen
  plays a door's sounds from the motion the server already replicates: while it moves, a real
  roll-up door's rattle follows its speed (`DoorSound.roll`); one-shots land when
  `Motion.strikes` says the door hits something (the slam's bang, thump and bounce clatter; a
  close settling; the stop bolts at the top), plus the latch as a lift starts and the bolt and
  padlock when locking. `src/client/DoorSounds.luau` plays them at the door on the server's clock;
  `src/client/CameraShake.luau` jolts anyone within 6 studs of a slam (fading out by 30). All
  sounds are Pro Sound Effects; each stretch was found by measuring loudness in Studio
  (`docs/STUDIO.md`, "Measuring a sound").
- **Verified in Studio** (one player, server calls on units 101 and 102): every cue within a frame
  of its strike (the bang 0.277 s after a full slam starts, the bounce 0.26 s later, the top at
  2.0 s, the lift's top at 6.0 s); the roll loud through an open, quiet for a peek, dipping at
  the lift's heaves; first plays start at their stretch; the slam's jolt 0.64 degrees beside it.
  No errors in Output. Not done here: hearing them (no one here can listen), a phone, two players
  (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-01a The floor as data from a seed
The moment: every climb is a new floor to learn, so friends replay for the layout as much as the
scare. This half is pure: the whole floor as data, proven by tests; L-01b lays it in Studio.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's floor section (docs tools; search "tile", "lobby", "floor") for the grid, unit
   sizes per row, the elevator lobby, numbering and paint per floor.
3. Shape the data: halls as straights and junctions (kind and turn, `Specs.Junctions.<name>.Arms`),
   each slot a unit (size, number, colour) or a plain wall, dead ends, every fixture (where, its
   power zone), the lobby. Brix Schema for the rows, Brix Random (seeded) for choices.
4. Write it pure (`src/shared/Floor.luau` or a `Floor/` folder), string-requiring its siblings.
   The rules in ROADMAP L-01: a straight between two junctions; a T's far side two M slots, a
   corner's outer sides S slots; the overlapping back-corner slot a plain wall; a fixture every 24
   studs and over each junction's middle.
5. Lune spec over 200 seeds: same seed, same floor; every rule holds; numbers unique; every hall
   stretch watched; the lobby reachable. Print one seed as a small text map for the owner.
**Acceptance:** checks green; every rule holds for 200 seeds; a map the owner can judge.
**Read first:** `docs/ROADMAP.md` (L-01); the GDD's floor section; D-023 in `docs/DECISIONS.md`;
`src/shared/CorridorKit/Specs.luau` (lengths, junction arms); `src/shared/CorridorKit/init.luau`
(`place`, `junction`, `wall`, `hang`: what L-01b will feed); `src/server/DevCorridor.luau` (how
the test hall is laid by hand now).

## Queue (the next run's order, from ROADMAP)
1. **L-01b** lays the data with the kits, then L-02 (doors as the GDD's state machine; a
   padlocked door rattles when tried), L-04 to L-08. L-05 adds "flash every light" to
   `MotionLights` for the wrong code; L-06's keepers hear doors by `DoorSound.Actions`.
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
3. **Polish waiting** (ROADMAP): the bolt and padlock moving; a shut door muffling sounds; a
   less-shake setting; a sound mix; a lit tube's hum; fading a far pool if the budget swap shows;
   the kit's own texture copies; cheaper chain links; a red glow round a Seen eye; a haze edge at
   low graphics; sizes S and L; a client-side door collider; the padlock too small; the cursor
   hint once ever; the junctions' overlapping decks seen from a unit.
4. In Edit, `require` a `:Clone()` of a module for fresh code (docs/STUDIO.md). Any reader of a
   tag skips templates in ReplicatedStorage (the light and door systems do). Measure render cost
   early. Probing sounds: poll `IsPlaying`, as deferred `Played` handlers miss first plays.
5. Play logs `rbxassetid://203785492 ... Asset type does not match` six times; not from this
   repo's code; find its source when convenient.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
