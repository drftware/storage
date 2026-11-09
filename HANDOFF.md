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
  From the doorway the digit is a speck, so the owner picked a Read button (L-05b1d, next).
  Not re-punched this session (5062 opened the gate in session 34). A note costs 0.43 ms to lay.
- The owner settled D-042's keypad rules and L-05b1c's solo feel ("looks good", Nov 8), and
  chose the Read button for notes (D-044).

## Next task: L-05b1d Read a note
The owner's pick (Nov 8, D-044): a "Read" button holds a note up on your screen, as DOORS shows
the hint in a library book. The moment: the door lifts, the yellow square on the back wall, two
steps in, tap Read, and the digit is big and plain: "I've got a 0, second!"
1. Owner test results first (`OWNER.md`).
2. In `NoteView`, a "Read" prompt per tagged note (`Elevator.NoteTag`), made on the client the
   way `KeypadPad` makes the keypad's; mind STUDIO.md's prompt traps (sight line, stacking).
3. The card: the note's own paper (its colour or texture from `ReplicatedStorage.Props.Note`'s
   Paper) and Kalam ink (`Elevator.Specs.Note`), its digits in their slots as tall as the A16
   allows; it lifts in with a paper rustle and drops away on a tap, Read again, walking off,
   death. A SurfaceGui may not draw inside a ViewportFrame: check before building on one.
4. Touch, mouse (FreeCursor's `need` if the cursor must be free), keyboard E, gamepad.
5. Studio on the Galaxy A16: open a note's unit, Read, shots of the card; close each way.
**Acceptance:** checks green; Lune specs for any pure layout (the slots' sizes); in Studio every
note's card readable at a glance on the A16 and closing every way; `OWNER.md` has what to judge.
**Read first:** ROADMAP L-05b1d; D-044 (DECISIONS); `src/client/NoteView.luau`;
`src/client/KeypadPad.luau` (by grep: `Prompt`, `open`, `close`); docs/STUDIO.md "Camera and
prompts"; `src/shared/Elevator/init.luau` (by grep: `Note`, `write`).

## Queue (the next run's order, from ROADMAP)
1. L-05b1d; L-05b2 the gate's timer (30 s after the code it shuts on its own, Dandy's World; Brix
   Zone and Clock; `Gate.gap`); L-11 tools in hand; L-06b the Mannequin hunts (Brix ENG-07); L-04e (keep each note's
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
