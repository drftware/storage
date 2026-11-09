# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 36 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05b1d is done** (D-045): two steps into a note's unit a "Read" button shows under the note;
  a tap lifts the note onto the screen with a paper flap, crooked as it hangs, its real paper
  mesh in a ViewportFrame and its four slots in Kalam over its writing area, the digit 7.7 mm on
  the Galaxy A16. A tap, Read again (E, X), B, a click, walking out to the doorway or dying drops
  it, after a 0.3 s grace. The world behind dims to 55%; you can still walk.
- **`src/shared/Elevator/NoteCard.luau`** (pure): the button's reach and offsets, `LetGo`,
  `layout(width, height, top, count)`, `slots(text)`, Kalam's measured metrics;
  `tests/notecard.spec.luau` (395 checks over eight screens). `Elevator.read(note)` returns a
  note's writing. `NoteView` holds the prompts and the card.
- **Verified in Studio** on the Galaxy A16 with Unit 313's `_ 0 _ _`: the card (shot
  `docs/art/L-05b1d-card.jpg`), the grace, and every drop but the mouse click (the simulator has
  no mouse). The MCP's touch can't press a prompt's button, so a real tap on Read is the owner's.
- Kickoff had no owner results; `OWNER.md` now lists L-05b1d's checks after L-05b1b's.

## Next task: L-05b2 The gate's timer
The moment: the code is right, the gate folds open, and the clock starts. 30 s later it folds
shut on its own, as Dandy's World's elevator does, and the last friend sprints for the narrowing
gap. The car leaves with whoever is aboard (a stand-in until L-08's ride).
1. Owner test results first (`OWNER.md`).
2. Read ROADMAP L-05b2 and the GDD's elevator section (docs tools, only that section). Check
   Brix's Zone (aboard the car) and the Host's Clock in `docs/FRAMEWORK.md` before building.
3. Server (`Elevators`): on "Right", start the timer on the Host's clock; at 30 s fold the gate
   shut with `Gate`'s motion (`Gate.encode`), and say who is aboard by a Zone over the car. Feel
   numbers in shared Config: the 30 s, when the warning starts.
4. Feedback in the same ticket: a countdown you feel (the lamp blinking faster, a bell in the
   last seconds; `Elevator/Sounds.luau` cues), and the fold's own sound and slam as now.
5. The leaving stand-in: those aboard told so ("Going up"), the rest left in the lobby.
6. Lune specs for any pure timing; Studio on the Galaxy A16: the countdown, the fold, a run
   through the closing gap (`Gate.gap`).
**Acceptance:** checks green; Lune specs for the timer's pure parts; in Studio the gate folds
shut 30 s after the code with its warning and sound, and the aboard list is right with one
player in and one out; `OWNER.md` has the two-player test.
**Read first:** ROADMAP L-05b2; docs/FRAMEWORK.md (Zone, Clock); `src/server/Elevators.luau`
(by grep: `Right`, `write`, `arm`); `src/shared/Elevator/Gate.luau` (by grep: `gap`, `encode`,
`duration`); `src/shared/Elevator/Sounds.luau` (by grep: `fold`, `Bell`); D-042 (DECISIONS).

## Queue (the next run's order, from ROADMAP)
1. L-05b2; L-11 tools in hand; L-06b the Mannequin hunts (Brix ENG-07); L-04e (keep each note's
   sight line clear); L-12; L-13; L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted` (the alarm
   sends them to the lobby), walk on `Pose.at`; L-08 lays the next floor during the ride.
4. **Check:** floor 3's laying peaked at 14.9 ms in a frame this session (25.6, 15.9, 13.0
   before). Find what loads `rbxassetid://203785492` ("Asset type does not match", six times).
5. Studio traps (docs/STUDIO.md): set the Device Simulator's device in Edit before Play and stop
   it after; trigger a prompt with `InputHoldBegin`/`End` (the MCP's touch can't press one); a
   capture right after a teleport comes back black, take it again; judge light after 10 s.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
