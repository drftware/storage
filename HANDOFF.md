# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 91 (overnight run, 6 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08a done (D-103): the ride.** On the server's clock (`Ride.Attribute` as the gate hits its
  post, `arrived` as it levels at 9.6 s, the gate folding at 10.3 s). The car never moves: riders'
  screens slide a sleeve of shaft down past the gate (RideView: the hall going black, a header,
  concrete with the next floor's number painted on it, the next sill, its black mouth lifting off
  the hall), the sway held on the camera (CameraShake `hold`), the lamp dipping (ElevatorView), an
  amber readout over the gate inside plus the top-bar plate (GateClock) ticking over as the brakes
  bite, and measured sounds. The car arrives back at the same lobby one floor higher; DevCorridor
  arms it again 6 s after its gate opens. Verified in Studio (log in ROADMAP).
- **Testing:** Workspace `DevRideHold` (Studio only) holds every ride at a moment, server and
  screens; recipe in docs/STUDIO.md, "Testing the ride from the MCP". By ear, on a phone and with
  a friend: the owner's (`OWNER.md`).
- Studio: nothing imported this session; left in Edit, seed 7, floor 1; `DevRideHold` unset.

## Next task: L-08b The next floor
The moment: the gate opens on a floor nobody has seen, and the one below is gone, as each of
Dandy's World's elevator stops opens on a new floor.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08b (its hand-off notes) and D-103. Brix's round loop (ENG-13) hadn't landed on
   Nov 11: check `docs/FRAMEWORK.md` and Brix's ROADMAP before building any loop here.
3. As the car leaves, deal floor n+1 (`Deal.new`, its harder odds) and lay it during the ride at
   its own origin, far enough that a phone never streams both; add it to every floor system
   DevCorridor adds floor 1 to (deals, kept players, keepers, wraps, minimaps). Floor 1 laid in
   2.27 s, inside the ride's 9.6.
4. The hand-off mid-ride, while the shaft hides everything (about `Ride.cruising()` +
   `Ride.Cruise / 2`): ask the riders' streams for the new lobby (`Player:RequestStreamAroundAsync`,
   verify it), write the same `Ride.Attribute` on the new car, move each rider to the same spot in
   it (turned if it faces another way), and let `Elevators` run that car's arrival (today only the
   car that left arrives: add a way to take a ride over). RideView already follows a ride onto a
   car the rider stands in; check the view doesn't jump.
5. Arm the new car with its code and number; clear floor n once its riders are off it. Whoever
   was left behind goes to the spawn for now (L-08c makes them watch). Replace DevCorridor's
   stand-in (its `arrived` handler that re-arms the same floor).
6. No lobby (L-08e waits on the owner), no new keepers.
**Acceptance:** checks green; in Studio on seed 7: punch 1097, ride, the gate opens on floor 2's
own lobby (a different layout, its code printed), floor 1 gone; a frame-by-frame log across the
hand-off shows no jump in the view or the shaft; ride on to floor 3; Output clean.
**Read first:** ROADMAP L-08b; D-103; `src/server/Elevators.luau`; `src/server/DevCorridor.luau`
(the floor's laying, from `local random = Brix.Random.new`); `src/client/RideView.luau` (`check`);
`src/server/FloorBuilder.luau` (`lay`).

## Queue (the next run's order, from ROADMAP)
1. L-08c left behind, L-08d the climb ends. L-08e (the start, in the lobby) waits for the
   owner's lobby plan (Nov 11).
2. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
3. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
4. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
5. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
