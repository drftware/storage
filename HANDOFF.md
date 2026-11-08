# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 34 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05b1c is done** (D-043): the keypad and gate on every screen. The floor's loop now runs
  end to end in Studio: walk to the keypad, tap "Use", punch the code, the gate folds open.
- **`src/client/ElevatorView.luau`**: gate folded from `Gate.Attribute` (only moving ones
  stepped), the slam's jolt, keys sunk, the readout's LEDs on a card off the glass, the status
  light and glow, every sound on the server's clock; `press(model, key)` for local presses.
- **`src/client/KeypadPad.luau`**: the on-screen keypad from the keypad's "Use" prompt, 58%
  across, 92% of the height (44-point keys on the A16); touch, mouse (FreeCursor's new
  `need`), keyboard digits and Backspace, gamepad. **`LedReadout`** draws seven-segment LEDs.
- **Pure, Lune-checked:** `Elevator/Readout.luau` (segments, tones, blink, live) and
  `Elevator/Sounds.luau` (rows and timing: the fold's slam lands on the gate's for any travel).
- **`SoundPrimer`**: a recording's first play in a session starts 0.26 to 0.35 s late even
  preloaded; it plays each once silently. **DoorSounds doesn't use it yet** (Queue 2).
- Server: a clear now carries `by`; the remote's name lives in `Keypad.RemoteFolder/RemoteName`.
  `Elevator.Readout` the colour is now `ReadoutGlass` (the name went to the module).
- **Verified in Studio** (A16 and desktop): 0000's buzzer and bell, blink in step on wall, pad
  and light, keys dead 3.5 s; Clear's low beep; 5062 green, ding, latch, the fold's slam on the
  gate's hit (after priming), the pad sliding away; walking off closes it; a faked friend's press
  sinks and beeps. Not tested: two real clients, a gamepad, stream-in mid-fold.

## Next task: L-05b1b The notes in their units
The moment: someone shouts "I've got a 7!" from a unit's doorway, the note's digit plain in the
torch, and the team assembles the code at the keypad.
1. Owner test results first (`OWNER.md`), above all L-05b1c's feel and D-042's rules.
2. Read the GDD's "Codes, the elevator and the roof" section for where notes go and how many.
3. `Deal.new` already deals the code and which units hold its notes (`Deal.Note`: slot, places);
   lay one note per dealt unit as FloorBuilder lays that unit (`Elevator.note(pivot, parent,
   text)`, text like `_ 7 _ _`), on a box or the unit's wall, seen from its doorway.
4. Preload Kalam on clients before notes show (in Edit the first note drew no digits until
   refreshed; STUDIO.md "Kalam").
5. Studio on the Galaxy A16: open a note's unit, read it, punch the floor's code; shots.
**Acceptance:** checks green; Lune specs for any new pure placement code; in Studio every dealt
note readable from its unit's doorway and the code they spell opens the gate; `OWNER.md` has
what to judge.
**Read first:** ROADMAP L-05b1b; GDD "Codes" (docs tools); `src/shared/Deal.luau` (by grep:
`Note`, `code`); `src/server/FloorBuilder.luau` (by grep: units laid, `laid`);
`src/shared/Elevator/init.luau` (`note`, `write`); `src/server/DevCorridor.luau` (`devFloor`).

## Queue (the next run's order, from ROADMAP)
1. L-05b1b; L-05b2 the gate's timer; L-11 tools in hand; L-06b the Mannequin hunts (Brix
   ENG-07); L-04e; L-12; L-13; L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted` (the alarm
   sends them to the lobby), walk on `Pose.at`; L-08 lays the next floor during the ride.
4. **Check:** floor 3 peaked at 15.9 ms in a frame while laying (13.0 last time). Re-measure;
   find what loads `rbxassetid://203785492` ("Asset type does not match", six times).
5. Studio traps (docs/STUDIO.md): touch taps from the MCP land at 0.9 of x on the A16; trigger
   a prompt with `InputHoldBegin`/`End`; captures never draw prompts; `require` in Edit is
   cached; set the Device Simulator's device before Play; wait for the elevator to stream in.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
