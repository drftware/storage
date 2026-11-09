# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 37 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05b2 is done** (D-046): once the right code's gate slams open, a 30 s clock runs for everyone
  within 240 studs (a floor); at zero the gate slams shut on its own and a Brix Zone over the car
  says who rode. The clock is the elevator's LED digits in the middle of the top bar (green, red
  from 10, jumping each second); a PA chime starts it; from 10 s the car's lamp blinks ever faster
  and a heartbeat swells and quickens; a bell rings each of the last five seconds. "Going up" (a
  lurch, then the stand-in ride's fade back to the spawn) or "Left behind" (the car's light
  draws away). The dev floor re-arms the elevator after each ride.
- **New code:** `src/shared/Elevator/Departure.luau` (pure, `tests/departure.spec.luau`, 6,188
  checks), `src/client/GateClock.luau`; `Elevators` keeps the clock (`Departs`, `Aboard`,
  `departed`), `ElevatorView` the lamp, `LedReadout.row` draws any row of LED digits.
- **Verified in Studio** on the Galaxy A16: the countdown, its sounds and the lamp, frame by
  frame; a run through the closing gate (crossed at 28% shut) counted aboard and ridden back;
  left behind. Two players and the sound mix are the owner's (`OWNER.md`).
- The owner said at kickoff the current state "is fine for now"; no test results came with it.
- L-11 is split into L-11a (the flashlight), L-11b (two slots and your hands), L-11c (bolt
  cutters and the padlock): Brix has no inventory.

## Next task: L-11a The flashlight
The moment: the hall's light clicks off behind you and you thumb your torch on: a small warm cone,
a click, the beam shaking a little as you walk; a friend's beam swinging round a corner tells you
where they are. Everyone carries one (GDD).
1. Owner test results first (`OWNER.md`).
2. Read ROADMAP L-11a and the GDD's flashlight lines (docs tools: search "flashlight"; only what
   it says about the torch: battery, flicker, who sees it). Proven-mechanic line: DOORS' and
   Lethal Company's flashlights.
3. Art first, the unit's way: `art/flashlight/` (spec.py, build.py, as `art/finds/`), an old
   plastic torch at a hand's size, baked PBR, FBX, look sheets; import it (STUDIO's FBX recipe)
   to `ReplicatedStorage.Props.Flashlight`; say in OWNER.md to save the place.
4. Held in first person, low right, with a little walk sway (a pure module for the sway and the
   beam's numbers, Lune specs); a SpotLight beam with Shadows, its range and angle in shared
   Config. The other players see your torch in your hand and its beam.
5. On and off: one phone button (thumb-sized, above the jump button), F, gamepad; the server owns
   the state (a validated, rate-limited remote, as the keypad's), the click heard nearby.
6. Light budget on the A16 (one shadowed SpotLight per player; check with six).
**Acceptance:** checks green; art built by script with sheets; Lune specs for the sway and beam;
in Studio on the Galaxy A16 the torch in hand, its button, the beam in a dark hall (shots); a
friend's beam seen (OWNER.md two-player test).
**Read first:** ROADMAP L-11a; the GDD's flashlight lines; `art/unit/README.md` ("How it's
made"); `art/finds/spec.py` and `build.py` (the latest small prop); docs/STUDIO.md ("Importing
kit pieces", the Blender traps); `src/server/Elevators.luau` (by grep: `press`, the remote checks).

## Queue (the next run's order, from ROADMAP)
1. L-11a; L-11b; L-11c; L-06b the Mannequin hunts (Brix ENG-07); L-04e (keep each note's sight
   line clear); L-12; L-13; L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted` (the alarm
   sends them to the lobby); the GDD's director "turns everything up" on the gate's clock
   (`Departure`); L-08 replaces the stand-in ride (`Elevators.departed`, DevCorridor's re-arm).
4. **Check:** floor 3's laying peaked at 12.2 ms in a frame this session (14.9, 25.6 before).
5. Studio traps (docs/STUDIO.md): set the Device Simulator's device in Edit before Play and stop
   it after; trigger a prompt with `InputHoldBegin`/`End`; a capture right after a teleport
   comes back black, take it again; screen captures land 2 s or more late, so hold a headline
   on screen to shoot it; Studio runs about 15 fps under the simulator.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
