# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 35 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05b1b is done** (D-044): the floor's loop now runs from the notes. FloorBuilder takes the
  floor's deal (`lay(floor, origin, parent, deck)`) and sticks each dealt note on its unit's back
  wall as it lays the unit: facing the door, eye height, on a rib, a little off the middle and
  crooked, 1.6 times the art's size. Notes carry the `CodeNote` tag (`Elevator.NoteTag`).
- **`src/shared/Elevator/NoteSpot.luau`** (pure): `inUnit(depth, number)` and the feel numbers;
  `tests/notespot.spec.luau` (75,928 checks: on the wall, seen whole through the doorway, the
  digit about 2 mm on an A16 from 5 studs, varied unit to unit).
- **`src/client/NoteView.luau`**: loads Kalam at start (by measuring text in it) and redraws any
  note that arrived first.
- **Verified in Studio** (Galaxy A16): floor 3's four notes (Units 313, 377, 332, 367) spell its
  code, 5062; a note is a plain square from a big unit's doorway and its "5" reads from 6 studs.
  From the doorway the digit is a speck: the owner picks whether that's fine (`OWNER.md`).
  Not re-punched this session (5062 opened the gate in session 34). A note costs 0.43 ms to lay.
- The owner settled D-042's keypad rules and L-05b1c's solo feel ("looks good", Nov 8).

## Next task: L-05b2 The gate's timer
The moment: the gate folds open and the whole floor hears the clock start; 30 s later the gate
ratchets shut on its own, and the last friend dives through the closing gap or is left behind.
1. Owner test results first (`OWNER.md`), above all L-05b1b's notes and its doorway decision.
2. Read the GDD's "Codes, the elevator and the roof" bullet "Right code" (docs tools: search the
   tab for "Right code."): 30 s for everyone on the floor, nobody can send it early.
3. Check Brix first (`docs/FRAMEWORK.md`: Zone for who's aboard, Clock for the countdown).
4. On the right code, `Elevators` starts a 30 s countdown (a Config number with its comment);
   at zero it moves the gate shut (`moveGate`), the collider following, and marks who's aboard.
5. The countdown everyone feels, every action answering: the car's lamp and a bell as it runs
   out, the gate's own ratchet and slam on close (`Elevator/Sounds.luau`), a toast at most.
   `Gate.gap` says the gap left, so someone sprinting through it makes it or doesn't.
6. The car "leaves" with whoever is aboard: a stand-in (print, a fade) until L-08's ride.
**Acceptance:** checks green; Lune specs for the countdown's pure rules (aboard, timing, the
close); in Studio on the Galaxy A16 the gate shuts 30 s after the code with its warning, and a
player outside is left; `OWNER.md` has what to judge, two players included.
**Read first:** ROADMAP L-05b2; GDD "Right code."; `src/server/Elevators.luau` (by grep:
`open`, `moveGate`, `step`); `src/shared/Elevator/Gate.luau` (`gap`, the motion);
`src/shared/Elevator/Sounds.luau`; `docs/FRAMEWORK.md` (Zone, Clock).

## Queue (the next run's order, from ROADMAP)
1. L-05b2; L-11 tools in hand; L-06b the Mannequin hunts (Brix ENG-07); L-04e (keep each note's
   sight line clear); L-12; L-13; L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted` (the alarm
   sends them to the lobby), walk on `Pose.at`; L-08 lays the next floor during the ride.
4. **Check:** floor 3's laying peaked at 25.6 ms in a frame (15.9 and 13.0 before; 168 ms on the
   first Play after a sync, which doesn't count). Re-measure; find what loads
   `rbxassetid://203785492` ("Asset type does not match", six times).
5. Studio traps (docs/STUDIO.md): set the Device Simulator's device in Edit before Play and stop
   it after; a capture right after a teleport comes back black, take it again; turn the client's
   camera, not the capture's; trigger a prompt with `InputHoldBegin`/`End`; judge light after 10 s.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
