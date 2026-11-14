# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 131 (S1-07b Batteries in units) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-07b built (D-143):** about one unit in ten has a battery (`Deal.BatteryShare`, drawn
  last in `Deal.new`; nothing else a seed lays moved). A unit with one holds no stuff. It lies on
  its side in the bulb's pool clear of the unit's coins (`DealSpot` "Battery"; Deals lays the
  coins first and passes their floor on), plus up, a cold glint on its button.
- **Taking it:** `Batteries` (server) checks reach, door, rate, then `Flashlights:fill`, which
  now refuses a torch whose ring is still full (`Battery.wants`: once a tick is gone, about 25
  seconds used). `BatteryView` shows the Take button only while your torch wants one, and throws a
  taken battery end over end into the taker's torch with a clack-click (the torch's own two
  clicks, `Battery.Clack`/`Snap`); the ring's sweep is FlashlightView's, as before. A dead torch
  isn't switched on by a fill (your screen owns the switch, D-142).
- **Art:** `art/battery/` (a chunky black and amber D-cell, plus and bolt, 896 triangles), in
  the place as `ReplicatedStorage.Props.Battery` (asset 81307492172647). Sheets
  `art/sheets/battery-*.png`. `tests/battery.spec.luau` proves the deal, the spot and the rule.
- **Not seen in Play:** a battery laid or taken (the session hit its context cap). Seen in Edit:
  the modules and the art load. Owner steps in OWNER.md "Now: take a battery".
- S1-08's break still unseen (three padlock cuts). Studio in Edit, `DevFloorSeed` 7.

## Next task: S1-10 The machine on the ride
The moment: the gate shuts behind you, the car climbs, and there's a lit vending machine in the
corner; you've got 9 coins and a dying torch, so you buy a battery for 3 and the ring sweeps full
before the gate opens on the next floor.
1. **First, a quick Play check of S1-07b** (unseen): `DevTorchSeconds` 60 on Workspace, Play,
   torch on 10 s, open units (server Output names "and a battery") until one holds one, take it
   (walk up and press, or the prompt's `InputHoldBegin`/`InputHoldEnd` on the Client; STUDIO.md
   says how earlier sessions pressed buttons); see the ring fill. Fix anything broken before going on. Remove `DevTorchSeconds` after.
2. Read ROADMAP S1-10 and the GDD (docs tools: search "machine", "The ride"). The machine is art
   first, the unit's way (`art/unit/README.md`; the car is `art/elevator/`). If the art alone fills
   the session, split S1-10 in ROADMAP first (a: the machine in the car and the ride at about 20
   seconds; b: its stock, buying, the battery always there) and do a.
3. The ride grows to about 20 seconds (`src/shared/Elevator/Ride.luau`, `Climb.luau`'s timings).
4. From the second ride on it sells three or four tools for coins, stock changing each ride,
   batteries always (3 coins; OWNER.md "The flashlight's details"). Buying spends coins on the
   server (`Coins`), a battery calls `Flashlights:fill` (refused while the ring is full, no text),
   a tool goes in a slot (`Slots`). Every buy answers: a clunk as it drops, the coins counted off.
5. Record each buy: add `machine` to `Record`'s reasons and call `spent` with the item (S1-02);
   record a battery taken from a unit too (ROADMAP S1-07b polish).
**Acceptance:** checks green; the machine's stock and prices proven in a spec; a buy seen in Play.
**Read first:** ROADMAP S1-10; GDD ("machine", "The ride"); `src/shared/Elevator/Ride.luau`;
`src/server/Coins.luau`; `src/server/Batteries.luau`; `art/coin/README.md` (a small art recipe).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10 (next), then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and L-08e3c
   wait on `OWNER.md`. Lobby polish waits.
2. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
3. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
4. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
5. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
6. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
   find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
   on another server, the save claim may wait up to 5 s.
7. Found L-08e3b/L-08e4b1: a failed lobby car trip's `far` ages out; WatchView's `controls`
   lookup fails quietly. Owner Nov 12 "fix them later": lobby car floors splotchy, a sawn panel
   flashes see-through, the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
