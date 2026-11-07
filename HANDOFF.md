# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 22 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-01 is done** (L-01c, D-029): `FloorBuilder.lay` (server) lays a floor from `Floor` data: the
  kit's pieces, a unit at every unit slot (painted, numbered, shared side walls left out), plain
  walls at the rest, each junction's own wall left out where a unit stands
  (`CorridorKit.junction`'s `units`), dead ends, a motion light per piece in zone `Floor<n>.<zone>`,
  and a stand-in lobby lit by the elevator car's lamp. Lobby first, then nearest pieces, at most
  about 4 ms of a frame (65 ms of work for 67 units, 6.2 ms the most in one frame); each piece
  parented once.
- **The test hall** (DevCorridor) is unchanged, plus floor 3 of seed 7 laid 600 studs off at Play
  (Workspace's `DevFloorSeed`, `DevFloorNumber` change it), its map printed to Output; "Walk a
  floor" by the spawn goes there, "Come back" in its lobby returns. The door prompts moved to
  `DoorPrompts` (any laid unit gets them) until L-02.
- **Verified in Studio** (one player, Output clean but the known `203785492` lines): the floor
  checked slot by slot against its data on six floors (1, 2, 3, 4, 7, 10; one turned 90°): every
  unit at its face, every plain wall once, no wall behind a unit, every shared wall dropped, all
  lights tagged and zoned. Walked: lights wake ahead, the T's units 304 and 305 and the corner's
  S units 342 to 345 with no gap, door 343 opens on E, both posts travel.
- **Render cost** (Studio's full window, not the phone): lobby 96,344 triangles in 43 opaque
  draws; down the first aisle 111,758 in 43. All 67 units stream in at once. The owner checks a
  phone (`OWNER.md`); fixes to try are in ROADMAP's polish list. Shots: `docs/art/L-01c-floor.jpg`.
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-02 Doors as the GDD's state machine
The moment: every door answers the instant you touch it, a phone thumb never hits the wrong
action, and a padlocked door rattles in your hands, loud enough to bring something.
If it won't fit one session, split it in ROADMAP first (say, the state machine and its prompts;
then the checks and the rattle).
1. Owner test results first (`OWNER.md`).
2. Read the GDD's door section (the docs tools; only that section): its states and actions.
3. A pure door state machine in `src/shared` (closed, peeking, opening, open, slamming, locked;
   what each action does from each state, what it refuses and why), Lune spec first.
4. A server door system on Brix's Host clock replacing `DoorPrompts`: per door, prompts only for
   what its state allows (no Open on an open door, Lift only when shut), spaced with `UIOffset`
   so a phone can pick one, eye height on the door; range and rate checks; door events on a Brix
   Signal (L-06's keepers will hear them by `DoorSound.Actions`).
5. A padlocked door rattles when tried: a new `DoorSound` cue (Pro Sound Effects "Door Shake 4",
   `rbxassetid://9114152830`), with "Padlocked" on the prompt.
6. In Studio, on the test hall and a laid floor: every action from every state, refusals, the
   rattle; phone-size shots of the prompts (Galaxy A16).
**Acceptance:** checks green; spec covers every state and action; prompts tappable at phone size;
no new errors in Output; shots and what to judge in `OWNER.md`.
**Read first:** `docs/ROADMAP.md` (L-02); `docs/FRAMEWORK.md` (Host, Signal, Remotes);
`src/server/DoorPrompts.luau`; `src/shared/StorageUnit/RollUpDoor.luau` (its `play`, `setLocked`);
`src/shared/StorageUnit/Motion.luau` (its kinds); `src/shared/StorageUnit/DoorSound.luau`.

## Queue (the next run's order, from ROADMAP)
1. Then L-04 to L-08. L-04 deals contents and which doors start padlocked; L-05 adds "flash
   every light" to `MotionLights` and builds the lobby and elevator where `FloorBuilder`'s
   stand-in is; L-06's keepers hear doors by `DoorSound.Actions`; L-08 lays the next floor
   during the ride with `FloorBuilder.lay`.
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`); the
   slot behind a plain wall has no floor, seen from a wire top (ROADMAP polish).
3. **Polish waiting** (ROADMAP): a laid floor's draw cost on a phone; the L unit; the bolt and
   padlock moving; a shut door muffling sounds; a less-shake setting; a sound mix; a lit tube's
   hum; fading a far pool; the kit's own texture copies; cheaper chain links; a red glow round a
   Seen eye; a haze edge at low graphics; a client-side door collider; the padlock too small; the
   cursor hint once ever; the junctions' overlapping decks seen from a unit.
4. Studio traps (docs/STUDIO.md): `require` a `:Clone()` in Edit; walk a few studs to wake lights.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
