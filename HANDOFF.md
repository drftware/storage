# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 134 (S1-10b2 The machine in every car, waking on the ride) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10b2 built (D-146):** the machine (asset 106768616385874) is prepared in the place at
  `ReplicatedStorage.Props.Machine` (`Machine.prepare`): `Cabinet` (the one collider),
  `Glass` with one SurfaceLight `CarLight`, `Coil1`-`6`, `Button1`-`6`, `Flap`, `Tube1`-`3`
  (cylinders), `Sign` (keyhole-coin emblem), `Prices` (a `Window{i}` frame per bay in its
  `Digits` SurfaceGui). `FloorBuilder` stands one in each floor's car (`Machine.place`), tagged
  `VendingMachine`; not in lobby cars (their back wall holds the results; ROADMAP polish).
- `Machine.Wake` (pure, `tests/machine.spec.luau`) and `src/client/MachineView.luau`: on a ride
  from floor 1 up, for those aboard, the tubes tink and catch bottom row first, the sign buzzes
  on, LED dashes, a hum, dips with the lamp, dark as the gate folds. Dark from the lobby.
- **Verified in Studio Play** (test hall, floor 3's car, rides staged by setting the car's
  `Ride` and `Aboard` attributes with `DevRideHold` 8): lit with every light, sound and LED
  state as designed; dark on a ride from the lobby; the car lamp unaffected. A second light into
  the bays blacked out the car, so it was dropped (docs/STUDIO.md). A real keypad ride and the
  sound levels against the motor are untested (OWNER.md).
- Studio in Edit. Studio's id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-10c Buying (split it first)
The moment: mid-ride, the machine just awake, you press a lit button; your coins clink into the
slot, the coil turns, a padlock clunks down behind the flap and flies into your hand.
Split in ROADMAP before starting (it won't fit one session): **c1 the stock shown** (steps 1-2)
and **c2 the buy** (steps 3-5).
1. Server: per ride that wakes the machine (`Machine.Wake.wakes`), deal its stock: three or four
   tools changing each ride, batteries always in the bottom bays, prices in coins (GDD guesses:
   padlock 6, bolt cutters 10, battery 3); replicate it on the machine (one attribute).
2. Client (MachineView): the tools stand in their coils (the finds' or tools' art scaled to
   about 1.8 studs), the prices drawn in the windows' LEDs (`LedReadout.row`, now dashes) once
   the bottom tube catches.
3. Each `Button{i}` a prompt (ButtonView's world buttons) only while awake; the server owns the
   price and the buy (`Coins`), validates (type, range, aboard that car, awake), rate-limits.
4. A battery calls `Flashlights:fill` (refused while the ring is full: ignore the press, no
   text); a tool goes in a slot (`Slots`).
5. Every buy answers: coins fly into the slot and count off, the button sinks
   (`Specs.ButtonTravel`), the coil turns, the item drops with a clunk, the flap swings, it
   flies to you. Record each buy (`machine` in `Record`'s reasons, `spent` with the item).
**Acceptance:** checks green; in Play, a staged ride (see State) shows the stock and prices.
**Read first:** ROADMAP S1-10c; `src/shared/Machine/init.luau` (the template);
`src/client/MachineView.luau`; `src/server/Batteries.luau` (a validated take, `Flashlights:fill`);
`src/server/Coins.luau` (grep `spend`); GDD "The ride" (the machine's stock).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10c (next, split), then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and
   L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
3. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
4. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
5. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
6. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
7. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
   find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
   on another server, the save claim may wait up to 5 s.
8. Found L-08e3b/L-08e4b1: a failed lobby car trip's `far` ages out; WatchView's `controls`
   lookup fails quietly. Owner Nov 12 "fix them later": lobby car floors splotchy, a sawn panel
   flashes see-through, the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
