# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 132 (S1-10a The ride grows to about 20 seconds) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10 split in three** (ROADMAP): a, the ride's length (done); b, the machine's art in the
  car, waking on the ride; c, buying. The session ran out of context reading, so a is small.
- **S1-10a built (D-144):** every ride takes about 20 s, a slow freight grind at about a stud a
  second: level at 18.8 s, the gate folding at 19.5, three cable clanks (4.6, 8.9, 13.4). The
  motor and rumble loop on their steady stretches (`Recording.Loop`, `Ride.position`; seen in
  Play, clean). Riders hand off to the next car on the last clank; lobby trips land 6.2 s before
  the car levels, as before; `Boarding.Back` follows the ride; a left-behind player stands in
  the dark lobby until 3 s before the hand-off. Unseen: a whole ride arriving on a next floor
  (seed 7's dev floor is the climb's top, so its ride ends the climb).
- **S1-07b seen in Play:** a battery laid in seed 7's unit 309 and taken; the torch went from
  27 s back to full. Its flight not watched. Studio in Edit, `DevFloorSeed` 7.

## Next task: S1-10b The machine: art, in every car, waking on the ride
The moment: the gate slams, the car shudders, and in the back corner a dark vending machine
blinks awake: its tubes tink, tink and catch, the sign buzzes on, cold light spills over your
friends. Nine coins in your pocket and the price windows glowing red.
1. Read ROADMAP S1-10b: the full plan (sizes, layout, parts, where it stands in the car) is
   there, worked out Nov 14 from the GDD. Don't redo that design; build it.
2. Art, the unit's way: `art/machine/` modelled on `art/battery/build.py` (the finds' kit:
   `kit.Find`, `kit.Look`, `kit.Coat`, `kit.bake_set`), geometry from `art/unit/geo.py`
   (`box` with bevel, `cylinder`, `sweep` for the coil's helix). Several MeshParts sharing one
   Machine set (as the finds share theirs); untextured parts get a plain material (the
   elevator's `LampGlass` is the precedent). Write `src/shared/Machine/Specs.luau` (sizes, the
   bays' middles, button and price-window places, where the machine stands in the car in the
   elevator's frame). Look sheets in `art/sheets/machine-*.png`; judge at phone size.
3. Upload (`scripts/upload_art.luau`: add a Machine entry), insert with the MCP, prepare it
   into `ReplicatedStorage.Props.Machine` (STUDIO.md "Importing kit pieces").
4. The server places a machine in every floor's car (and not the lobby's cars). The client
   (a new `MachineView`, or ElevatorView) lights it from the ride's `Ride` attribute: dark when
   the ride's `from` is the lobby (`Ride.Lobby`); else waking just after the gate hits its post,
   dying as the gate starts to fold (`Ride.opens()`). Find and measure a starter tink and a hum
   (Pro Sound Effects via `search_asset`; STUDIO.md has how sounds were measured).
5. Spec: the machine's numbers (bays inside the window, clear of the car's walls and gate).
**Acceptance:** checks green; the machine seen in the car in Play, lit on a ride from floor 1
(Workspace `DevFloorNumber` 1, code from Output) and dark on the first ride.
**Read first:** ROADMAP S1-10b; `art/battery/build.py`; `art/battery/spec.py`; `art/elevator/
spec.py` (the car's numbers); `src/client/ElevatorView.luau` (how the lamp follows the ride);
STUDIO.md "Importing kit pieces".

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10b (next), S1-10c, then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and
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
