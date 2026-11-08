# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 32 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05a2 is done** (D-041): the freight elevator is in the place. `Elevator.prepare` made two
  templates from the upload (asset 89467597147215): `ReplicatedStorage.Props.Elevator` and
  `Props.Note`. **Unsaved** until the owner saves the place (`OWNER.md`, first).
- **`src/shared/Elevator/init.luau`:** `setGate(model, shut)` poses the gate's 85 parts in one
  `BulkMoveTo`; `clone(pivot, parent)`; `note(pivot, parent, text)` and `write(note, text)` put
  the digits in Kalam on an invisible card over the paper's writing area. The lamp's values
  (`Elevator.Lamp`) moved here from FloorBuilder; the light casts shadows.
- **FloorBuilder's lobby** is its square, the back wall built round `Specs.Opening`, the elevator
  cloned with its threshold on the wall's face; the stand-in's car floor and lamp are gone.
- **Verified in Studio:** the gate at 0, 0.5 and 1 (Edit), a note `_ 7 _ _` on a box, and on the
  Galaxy A16 from the hall's mouth, at the gate and aboard with the server shutting it to 0.75
  (`docs/art/L-05a2-*.jpg`). Laying floor 3 still peaks at 6.7 ms in a frame (6.2 before).
- **Not yet:** the gate has no collider and is laid folded open; nothing writes the readout.
- **L-05b is split** (ROADMAP): L-05b1 the notes and the keypad, L-05b2 the gate's timer.
- **Brix's chase isn't ready:** ENG-07a and ENG-07b are still open in `../engine`.

## Next task: L-05b1 The notes and the keypad
The moment: a friend shouting the last digit from a unit while you punch the first three in,
the keypad answering every press. The ticket makes the code findable and the keypad work.
1. Owner test results first (`OWNER.md`): the elevator's shots and sheets, then older.
2. Check `../engine/docs/ROADMAP.md`: if ENG-07 has landed, say so and do L-06b instead.
3. Read the GDD's "Codes, the elevator and the roof" and pick the keypad's phone control (a
   proven one, named); gaps get a default and an `OWNER.md` line.
4. Notes: stick each of `Deal`'s notes in its unit with its slots (`Elevator.note`), on the
   floor's units as they're laid; preload Kalam on clients first.
5. The gate laid shut with a collider (left post to the lead); a replicated value the clients
   animate it from (`setGate` over a second or two), never 85 server moves a step.
6. The keypad: a validated, rate-limited remote on the server (as `Doors` does); each press sinks
   its key `Specs.Keypad.Travel` along +Z with a beep and writes the readout (red dashes at
   rest); a wrong code buzzes and flashes every light on the floor (`MotionLights`, beside
   `cut`); the right one chimes and folds the gate open.
7. Studio, Galaxy A16: punch a wrong code then the right one; shots in `docs/art/`.
**Acceptance:** checks green; Lune specs for any pure code (the code check, the readout's text);
in Studio a note found in its unit, a wrong code's flash, the gate opening on the right code;
`OWNER.md` has the feel to judge and two-player steps.
**Read first:** GDD "Codes, the elevator and the roof"; `src/shared/Deal.luau` (notes, by grep);
`src/shared/Elevator/init.luau`; `src/server/Doors.luau` (its remote's checks, by grep);
`src/server/MotionLights.luau` (`cut`); `docs/FRAMEWORK.md` (what Brix has for input and remotes).

## Queue (the next run's order, from ROADMAP)
1. L-05b1 the notes and the keypad; L-05b2 the gate's timer (Brix Zone and Clock); L-11 tools in
   hand; L-06b the Mannequin hunts (Brix ENG-07); L-04e the deal on the floor; L-12 the saw and
   hole trap; L-13 the tops and the ladder; L-14 the other tools; then L-07, L-08, L-10, L-09.
2. L-06b's keepers hear doors on `Doors.acted`, walk on `Pose.at`; L-08 lays the next floor
   during the ride.
3. **Polish waiting** (ROADMAP): a floor dial over the landing, a trim sheet if the big trim
   reads soft, tally marks in the car, the shaft for the ride.
4. Studio traps (docs/STUDIO.md): in Play, capture the player's own view (turn the client's
   camera), not a placed camera, which can return a stale frame; `require` in Edit is cached
   (require a `:Clone()`); an imported part's pivot carries the FBX's Z-up turn; a prompt
   triggers from the MCP only while the camera faces it; set the Device Simulator's device
   before its orientation, in Edit.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
