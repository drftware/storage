# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 33 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05b1a is done** (D-042), the keypad's rules and the server. L-05b1 is split three ways in
  ROADMAP: 1a done, 1c the keypad and gate on every screen (next), 1b the notes (after).
- **`Elevator/Keypad.luau`** (pure): `enter` checks on the fourth digit; `readout` "7 2 - -";
  `isKey`, `isCode`; the state as one counted value (`Keypad.Attribute`: count, event, typed,
  digit, who). **`Gate.luau`** gained the motion: `Gate.Attribute` (from, to, start),
  `duration`, `settles`, `at` (ease-in to the slam, a 2.5% recoil), and `pose(shut, into)`.
- **`Elevator`:** `Tag`; `clone(pivot, parent, shut)` poses, fits the collider and tags before
  parenting; `setGate` makes no tables after its first call; `fitGate`, `key`, `keypadPoint`.
- **`src/server/Elevators.luau`:** `arm(elevator, code, floor)`; the remote at
  `ReplicatedStorage.Remotes.Keypad` (payload: the elevator, then a digit or "Clear"), checked
  types, range (`Keypad.Reach` 9), rate (0.08 s), state; wrong: `MotionLights.flash(floor)`,
  dead `AlarmSeconds` 3.5, then Rest; right: the gate opens after `Gate.Delay` 0.55, its
  collider stepped. `acted` fires with how far each sound carries (for L-06b).
- **FloorBuilder** lays the gate shut (`laid.elevator`); **DevCorridor** deals floor 3's code
  from seed 7 (`Deal.new`, it's 5062), arms the elevator and prints the code.
- **Verified in Studio** (Client view, through the remote): bad payloads and a too-fast press
  dropped; 0000 Wrong, 24 hall lights lit at once, Rest 3.5 s later; Clear; 5062 Right, the
  collider shrinking 11.5 to 2.6 studs with a recoil. **Nothing on screen moves yet.**
- **Sounds found and measured** (`docs/STUDIO.md`, ids in ROADMAP). Brix's ENG-07a/b still open.

## Next task: L-05b1c The keypad and gate on every screen
The moment: a friend shouting the last digit from a unit while you punch the first three in,
the keypad answering every press, the gate slamming open on the right code.
1. Owner test results first (`OWNER.md`), above all the keypad's decisions (D-042).
2. `src/client/ElevatorView.luau`, a client system on the Host (as DoorView/DoorSounds): each
   tagged elevator in Workspace (re-done on stream-in); the gate posed from `Gate.at` each frame
   while it moves, only moving ones stepped; keys sink `Specs.Keypad.Travel` along +Z and back;
   the readout on an invisible card just off `KeypadReadout` (as the note's), red LED digits,
   dim dashes at rest, blinking on Wrong, green on Right; `KeypadLight` and the glow go green.
3. Sounds (ROADMAP lists ids and stretches): a beep each press, the buzzer then the alarm bell
   (loud, heard across the floor) on Wrong, the double-ding, the latch, then the fold timed so
   its slam lands as the gate hits. Start each `Sound` at its stretch (STUDIO.md).
4. `src/client/KeypadPad.luau`: a client prompt on the keypad ("Use", reach
   `Keypad.PromptReach`) opens the on-screen keypad right of centre, clear of the jump button;
   1-9, then [light] 0 [CLR]; its readout mirrors the wall's; a press beeps and sinks at once
   (skip the echo whose `by` is you), throttled to `PressSeconds`; dead keys during the alarm;
   closes on walking off, death, the gate opening, E or B; keyboard digits and Backspace;
   gamepad selection; slides in and fades, never snaps; a `Modal` button frees the mouse.
5. Studio, Galaxy A16: punch 0000 then 5062 from the screen keypad; shots in `docs/art/`.
**Acceptance:** checks green; Lune specs for any new pure code; in Studio the keypad answering
each press, the wrong code's alarm and lights, the gate folding open with its slam; `OWNER.md`
has the feel to judge and two-player steps (one types, one watches from the hall).
**Read first:** `src/shared/Elevator/Keypad.luau`; `src/shared/Elevator/Gate.luau` (motion, by
grep); `src/shared/Elevator/init.luau` (by grep); `src/client/DoorSounds.luau` (how a sound
plays a stretch); `src/client/FreeCursor.luau` (header); `src/client/init.client.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-05b1c; L-05b1b the notes; L-05b2 the gate's timer; L-11 tools in hand; L-06b the
   Mannequin hunts (Brix ENG-07); L-04e; L-12; L-13; L-14; then L-07, L-08, L-10, L-09.
2. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted` (the alarm
   sends them to the lobby), walk on `Pose.at`; L-08 lays the next floor during the ride.
3. **Check:** floor 3 peaked at 13.0 ms in a frame (6.7 before; the lobby now poses the gate).
   Re-measure; if it holds, breathe after the lobby. Find what loads `rbxassetid://203785492`
   (Output: "Asset type does not match", six times).
4. Studio traps (docs/STUDIO.md): capture the player's own view, not a placed camera; `require`
   in Edit is cached (require a `:Clone()`); set the Device Simulator's device before its
   orientation, in Edit; fire remotes from the Client view to test them.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
