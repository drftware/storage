# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 18 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The motion lights are built** (L-03, D-024). The server owns every fixture tagged
  `MotionLight.Tag` (`src/server/MotionLights.luau`; the rules, pure and Lune-tested, in
  `src/shared/MotionLight.luau`): anything moving at 1 stud/s or more in its box zone (32 down the
  hall, 10 across, floor to deck) wakes it; it falls dark 5 s after the last movement it saw.
  State crosses the wire as the model's `Light` attribute; `src/client/HallLights.luau` draws it:
  eye flare, relay click (Pro Sound Effects 9118138693), tube flicker; a softer click and the eye
  sinking as it falls dark; silent death when cut. Real light only for the 3 lit fixtures nearest
  the camera. `HallLight` gained `glow`, `light(tube, level, real)`, the flicker, flare and click.
- **The test hall:** all five kit fixtures are motion lights; the hall starts dark; a breaker post
  in the T's south half cuts the north arm's two (power zone `NorthArm`).
- **Verified in Studio** (Studio window, Automatic and Level01; one player): walking wakes the
  light overhead and the one ahead; the trip plays flare, click, flicker in order; freezing
  darkened the light 5.4 s after stopping, with the soft click and the eye easing back; four lit
  gave three with real light; the breaker blinds both and restoring brings them back. No errors in
  Output. Shots `docs/art/L-03-*.jpg`. Not done here: the Galaxy A16 view, two players and the
  render cost (`OWNER.md`).
- **The templates must be saved with the place** (`OWNER.md`, top).
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: P0-04 The door's sounds and feel
The moment: the slow, loud open everyone hears and the instant slam. Each door action gets its
sound, and the slam its little shake, so a door is never a silent state change.
1. Owner test results first (`OWNER.md`).
2. Read the GDD's doors section (docs tools; search "slam" and "peek") for what each action
   sounds like and who hears it (keepers hear an open).
3. Find each sound with `search_asset` (Audio; Pro Sound Effects first): a peek's quiet scrape,
   an open's loud rattle, a slam's bang and bounce, the latch's clack, the padlock. Check each
   loads (`ContentProvider:PreloadAsync`, `docs/STUDIO.md`); list the IDs with a comment each.
4. Play them on each client from the door's replicated motion (`RollUpDoor` watches it; time
   each off its curve in `Motion`), positioned at the door, the loud ones carrying farther.
5. A slam shakes the camera a little for anyone nearby; feel numbers in shared code, commented.
6. Verify in Studio: each action's sound starts with its motion; the slam's shake.
**Acceptance:** checks green; every door action answers with its sound, timed to its motion; a
slam shakes a nearby camera; the owner judges the sounds.
**Read first:** `docs/ROADMAP.md` (P0-04); the GDD's doors section;
`src/shared/StorageUnit/Motion.luau`; `src/shared/StorageUnit/RollUpDoor.luau` (`play`, the
client's `watchTagged`); `src/client/HallLights.luau` (`playClick`, the pattern for a sound);
`docs/STUDIO.md` ("Sounds from the audio library").

## Queue (the next run's order, from ROADMAP)
1. **Phase 1** (ROADMAP), from L-01, which lays floors with `place`, `junction` and `wall` and
   tags each fixture `MotionLight.Tag` (with a `PowerZone`). Its junction rules are in ROADMAP.
   L-05 adds "flash every light" to `MotionLights` for the wrong code.
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
3. **Polish waiting** (ROADMAP): a lit tube's hum; fading a far pool if the budget swap shows;
   the kit's own copies of the unit's textures; cheaper chain links; a red glow round a Seen eye;
   a haze edge near the ceiling at low graphics; a peeked unit lighting evenly at low graphics;
   re-run `UnitKit.prepare` at 1.2 deep; sizes S and L; a client-side door collider; the padlock
   too small; the cursor hint once ever; the junctions' overlapping decks seen from a unit.
4. In Edit, `require` a `:Clone()` of a module for fresh code (docs/STUDIO.md). Any reader of a
   tag skips templates in ReplicatedStorage (both light systems do). Measure render cost early.
5. Play logs `rbxassetid://203785492 ... Asset type does not match` six times; not from this
   repo's code; find its source when convenient.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
