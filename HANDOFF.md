# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 133 (S1-10b1 The machine's art) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10b split in two** (ROADMAP): b1, the machine's art (done); b2, the machine in every
  car, waking on the ride (next). The session hit its context cap after the art.
- **S1-10b1 built (D-145):** `art/machine/` (README; `scripts/art.sh machine`). Eight MeshParts:
  textured `Machine`, `MachineCoil`, `MachineButton`, `MachineFlap` (one Machine set, 1024);
  untextured `MachineGlass`, `MachineTubes`, `MachinePrices`, `MachineSign`. Built in the
  machine's frame (origin on the floor under its middle, front toward -Z), the coil, button and
  flap on their own origins. `src/shared/Machine/Specs.luau` is generated: bays, coils,
  buttons, price windows, flap hinge, sign, glass, `InCar` (its place in the elevator's frame)
  and each part's `Centre` and `Size`. Look sheets `art/sheets/machine-*.png` show it in the
  elevator's own car, awake and dark. `scripts/upload_art.luau` has its Machine entry; not
  uploaded yet. Nothing in the game uses it yet.
- Studio in Edit, `DevFloorSeed` 7. Studio's id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-10b2 The machine in every car, waking on the ride
The moment: the gate slams, the car shudders, and in the back corner the dark machine blinks
awake: its tubes tink, tink and catch one row at a time, the sign buzzes on, cold light spills
over your friends.
1. Upload: `lune run scripts/upload_art Machine`; insert the asset with the MCP; write
   `src/shared/Machine/init.luau` with `prepare(model)` modelled on `Elevator.prepare`
   (`src/shared/Elevator/init.luau` 152-215): square each part by `Specs.Parts[name].Centre`;
   clone `MachineCoil` and `MachineButton` into each bay (`Specs.Bays`: a coil's middle, a
   button's back), hang the flap at `FlapHinge`; glass Material Glass; tubes, sign and prices
   plain until lit; one SurfaceGui on the prices' front with a dim red "--" per window; a
   SurfaceGui on the sign's front drawing a keyhole-coin emblem (no words); two SurfaceLights
   off (the tubes' Back face into the bays, the glass's Front face into the car, cold white,
   no shadows); collisions: the cabinet Box, the rest off. Save it as `Props.Machine` (a Model,
   tagged by place, not by template). `Machine.place(car)` clones it to `car pivot *
   CFrame.new(InCar)`, called in `FloorBuilder` after `Elevator.clone` (line ~338).
2. Pure wake curve in `src/shared/Machine/Wake.luau` + `tests/machine.spec.luau`: per tube and
   for the sign, the share lit `since` seconds into a ride (starter flickers then catch, rows
   staggered; times Ride.lamp's dips; 0 from `Ride.opens()`); dark if `from == Ride.Lobby`.
3. `src/client/MachineView.luau` (a Brix system in `init.client.luau`): for each tagged machine,
   follow its car's `Ride` attribute (`Ride.decode`, `RideClock`) and the `rode` rule from
   `ElevatorView` (`aboardChanged`, line ~441); step only while waking or dying.
4. Sounds: find a fluorescent starter tink and a hum (Pro Sound Effects via `search_asset`),
   measure them (STUDIO.md line ~475 shows how), hum looped on its steady stretch.
5. Verify in Play: Workspace `DevFloorNumber` 1, code from Output, ride; `DevRideHold` (a
   number of seconds) freezes a ride's frame on screen for a capture. Judge at phone size.
**Acceptance:** checks green; the machine seen in the car in Play, lit on a ride from floor 1
and dark on the first ride.
**Read first:** ROADMAP S1-10b2; `art/machine/README.md`; `src/shared/Machine/Specs.luau`;
`src/shared/Elevator/init.luau` 152-215 and 405-428; `src/client/ElevatorView.luau` 385-450.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10b2 (next), S1-10c, then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and
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
