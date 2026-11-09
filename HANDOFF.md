# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 38 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-11a is done** (D-047): everyone carries an old two-battery plastic torch, built by script
  (`art/flashlight/`, baked, sheets) and imported to `ReplicatedStorage.Props.Flashlight`. Yours
  is held low on the right of your view (sways, trails a turn, dips on the click); a right click,
  R1 or a phone button above the jump button switches it at once with a click; the server owns
  on, off and your aim; friends see the torch in your hand, its lens lit, your arm raised to your
  aim, and the nearest three friends' beams cast real light.
- **New code:** `src/shared/Flashlight/` (`init` prepare/clone/light, `Torch` pure with
  `tests/torch.spec.luau`, generated `Specs`), `src/server/Flashlights.luau`,
  `src/client/FlashlightView.luau`.
- **Verified in Studio:** the torch in hand, right click and R1, the server's state and aim, the
  beam at Level 21 and 8 and on the Galaxy A16. Found: a spotlight lights nothing within about
  3 studs at low graphics, so a soft spill PointLight rides above the torch's head (STUDIO.md).
  The phone tap, a friend's beam and arm, and six players are the owner's (`OWNER.md`).
- No owner test results came this session (the overnight run).
- ROADMAP reshaped: L-11b now builds the bolt cutters' art first (a slot needs a real tool);
  L-11c is the padlock's art and using both from the slots.

## Next task: L-11b Two slots and your hands
The moment: you spot bolt cutters on a unit's floor, tap Pick up, and they swing into your free
hand with a clank; the slots' bar at the bottom shows them; you hand them to the friend at the
padlocked door. Lethal Company's slots (two tools plus what's in your hands, GDD).
1. Owner test results first (`OWNER.md`).
2. Read ROADMAP L-11b and the GDD's lines on carrying (docs tools: search "slots" and "hands";
   only what it says about how many, dropping and handing over).
3. Check Brix for an inventory (`vendor/brix/src/init.luau`, its `docs/ROADMAP.md`); if none, add
   it to Brix's ROADMAP in neutral terms and build the smallest stand-in behind that shape.
4. Art first, the unit's way: `art/boltcutters/` (spec.py, build.py borrowing the finds' bake, as
   `art/flashlight/build.py`), long red handles and a steel jaw, at a hand's size; FBX, sheets;
   upload (`scripts/upload_art`), insert, `prepare` into `ReplicatedStorage.Props.Tools`.
5. The slots on the server: one table of tools (a row each); pick up (a prompt on a tool lying on
   a floor), switch, drop, hand to a friend; each validated and rate-limited like `Flashlights`.
   The torch stays in the hand and out of the slots.
6. On screen: the slots' bar (phone first, a button each), the held tool in first person (reuse
   `FlashlightView`'s hold), a clank on pick-up, a toast for a refusal ("Hands full").
7. If the art and the slots won't fit one session, split L-11b in ROADMAP and stop at the art.
**Acceptance:** checks green; art built by script with sheets; Lune specs for the slots' rules;
in Studio: pick up, switch, drop, hand over on the Galaxy A16 (shots); two players in OWNER.md.
**Read first:** ROADMAP L-11b; the GDD's carrying lines; `art/flashlight/build.py` (the latest
small prop); `src/server/Flashlights.luau` (remote checks); `src/client/FlashlightView.luau`
(the hold, by grep: `hold`); docs/STUDIO.md ("Importing kit pieces").

## Queue (the next run's order, from ROADMAP)
1. L-11b; L-11c; L-06b the Mannequin hunts (Brix ENG-07; it reads `Flashlights:isOn`/`aim` to
   freeze); L-04e (keep each note's sight line clear); L-12; L-13; L-14; then L-07, L-08, L-10,
   L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted` and the keypad on `Elevators.acted`; keepers with
   eyes see a torch (`Flashlights.switched`, GDD); the director "turns everything up" on the
   gate's clock (`Departure`); L-08 replaces the stand-in ride.
4. **Check:** floor 3's laying peaked at 12.2 ms in a frame (session 37).
5. Studio traps (docs/STUDIO.md): set the Device Simulator's device in Edit before Play and stop
   it after; judge light at a fixed Quality Level (Automatic drops to low graphics); the MCP's
   clicks don't reach a ScreenGui button in the simulator (use a gamepad key or ask the owner);
   a capture right after a teleport comes back black, take it again.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
