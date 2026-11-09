# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 39 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-11b is done** (D-048): two tool slots, Lethal Company's way. The bolt cutters are built by
  script (`art/boltcutters/`, baked, sheets), uploaded and prepared at
  `ReplicatedStorage.Props.Tools.BoltCutters`. A tool lies on a floor with "Pick up"; it comes
  into your hand with a clank; the bar at the bottom shows each slot as a 3D picture (tap, 1/2,
  d-pad); Drop (button, G, d-pad down) lets it fall ahead of you; "Give" on a friend hands it
  over. Yours sways low on the left of your view; friends see it in your left hand.
- **New code:** `src/shared/Tools/` (`init`, `Catalog` a row per tool, `Carry` pure with
  `tests/carry.spec.luau`, generated `Specs/BoltCutters`), `src/server/Slots.luau`,
  `src/client/ToolView.luau`. The test hall's "Bolt cutters" post is gone: two pairs lie on
  floors (`DevCorridor`'s `CUTTERS`). `Slots` keeps `CarriesBoltCutters` for `Doors` until L-11c.
- **Verified in Studio:** pick up, switch, switch back, drop, the bar, the slot picture and the
  held tool, on a computer and on the Galaxy A16 by gamepad keys. Handing over (two players) and
  the phone's real taps are the owner's (`OWNER.md`). Studio left in Edit, simulator off.
- No owner test results came this session (the overnight run).

## Next task: L-11c The padlock, and the cutters at work
The moment: you hold the cutters to a padlocked door, hold Cut, the jaw bites the shackle with a
snap and the padlock clatters to the floor. And the padlock you carry snaps shut on a door.
1. Owner test results first (`OWNER.md`).
2. Read ROADMAP L-11c and the GDD's lines on the padlock and bolt cutters (docs tools: search
   "padlock"; only its use, its cost, "One padlock per use").
3. Art first, as the cutters: `art/padlock/` (spec.py, build.py borrowing the finds' bake, as
   `art/boltcutters/build.py`): a brass-bodied padlock with a steel shackle, at a hand's size;
   FBX, sheets; upload (`scripts/upload_art`), insert, `Tools.prepare(model, "Padlock")`.
4. Its row in `Tools/Catalog.luau`; lay one in the test hall (`DevCorridor`'s `CUTTERS`).
5. `Doors` reads the slots (`Slots:carried`) for `Door.Tools`: the cutters in your hand to Cut, a
   padlock in your hand to lock (and the padlock leaves your slots when it's on the door). Drop
   the `CarriesBoltCutters` stand-in in `Slots.publish` and `Doors.carries`.
6. The feedback: the jaw's snap at the shackle, the lock's clatter, a refusal naming the fix
   ("Hold the bolt cutters").
7. If the art and the use won't fit one session, split L-11c in ROADMAP and stop at the art.
**Acceptance:** checks green; art built by script with sheets; Lune specs for any new rules; in
Studio: cut a padlocked door with the cutters in hand and lock one with a padlock (Galaxy A16
shots); two players in OWNER.md.
**Read first:** ROADMAP L-11c; the GDD's padlock lines; `art/boltcutters/build.py`;
`src/server/Slots.luau` (`carried`, `publish`); `src/server/Doors.luau` (grep `carries`);
`src/shared/StorageUnit/Door.luau` (grep `Tools`).

## Queue (the next run's order, from ROADMAP)
1. L-11c; L-06b the Mannequin hunts (Brix ENG-07; it reads `Flashlights:isOn`/`aim` to freeze);
   L-04e (lay each unit's tool with `Slots:lay`; keep each note's sight line clear); L-12; L-13;
   L-14; then L-07, L-08, L-10, L-09.
2. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
3. L-06b's keepers hear doors on `Doors.acted`, the keypad on `Elevators.acted` and a dropped tool
   on `Slots.changed`; keepers with eyes see a torch (`Flashlights.switched`, GDD).
4. **Check:** floor 3's laying peaked at 12.2 ms in a frame (session 37; 8.7 ms this session).
5. Studio traps (docs/STUDIO.md): set the Device Simulator's device in Edit before Play (its calls
   are written there) and stop it after; the MCP's E reaches prompts but one per key shows, so
   stand away from the posts; judge light at a fixed Quality Level; the MCP's clicks don't reach a
   ScreenGui button; a capture right after a teleport comes back black, take it again.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
