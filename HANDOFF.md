# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 146 (the owner's five fixes, D-158) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The owner's Nov 14 fixes are in (D-158).** Anyone still in a car as its gate shuts on a
  floor is stood on the landing, facing the hall (`Elevators` `stepOut`). A lobby trip's black
  now comes 4.8 s into the ride (`Trip.FadeAt`), and the group's server waits for each screen's
  `Remotes.TripReady` (at most `Trip.LoadMost`) before standing them in the ride. Until a
  floor's first power cut, a loose Mannequin heads for the box on half its picks
  (`Breaker.ErrandFirst`). The coin count's coin is a rendered picture (`Coins.Icon`,
  `art/coin/build.py --stage icon`). The lobby template's floor slab was 7 studs into the cars
  (the flicker): moved back onto its spec in Edit.
- **Verified in Studio Play** with Workspace `DevTrip` "Arrive": stood in floor 1's car mid-ride,
  the gate opened, and 6 s later "Elevators: 1 stepped out as the gate shut on floor 1", the
  player moved from 4 studs in the car to 4 studs out. The coin picture loaded and showed in the
  top bar. The laid lobby's floor runs -72 to 0 (the bay wall's face). Output clean but the
  known asset lines. `DevTrip` cleared after; Studio left in Edit. Not seen: the real teleport
  on a phone, and the first power cut in a real climb (both in `OWNER.md`).

## Next task: S2-04 A wrong code lets monsters out
First fix the bug at Queue 1 if the owner says so (it's small). Then:
The moment: you punch a wrong code, the alarm screams, the hall goes dark, and somewhere a door
rolls up by itself; every monster out there turns for the keypad you're standing at.
1. Read ROADMAP S2-04 and the GDD's "Codes" / wrong-code lines (docs tools, that section only).
   It's big: split it in ROADMAP first, likely (a) which units roll up and the keypad's lock
   growing 3.5, 7, 14 s, (b) the doors rolling up by themselves and loose monsters heading for
   the keypad, (c) the hall lights going out for the alarm (today a wrong code flashes every
   light on: check `MotionLights.flash` and the GDD; a conflict goes in `OWNER.md`).
2. Which units: ones with a monster in them, sleepers first (`Keepers:sleepers`), then dealt
   units holding one; 1 on the first wrong code, 3 on the second, 5 after (count per floor).
   A sleeper's unit rolling up can use `Deals:dealShut` then lift the door.
3. Pure rules in a shared module with a Lune spec; feel numbers in Config with comments.
4. Verify in Studio Play on the dev floor (keypad code 2274 on seed 7): a wrong code rolls up
   one monster's door; the keypad stays dead longer each time; Output one line a wrong code.
**Acceptance:** checks green; a spec for the pure part; in Play the first piece works; Output
clean; Studio left in Edit.
**Read first:** ROADMAP S2-04; DECISIONS D-157; `src/server/Elevators.luau` (grep `wrong`,
`alarm`, `dead`); `src/server/Keepers.luau` (grep `onKeypad`, `wakeDue`, `anyoneOn`);
`src/server/Deals.luau` (grep `dealShut`); `src/server/Doors.luau` (grep `function system.move`).

## Queue (next sessions per ROADMAP Phase 2)
1. **Bug, found this session:** `Keepers` `anyoneOn` counts a player on a floor by height alone,
   but a climb's floors all stand at one height, `Climb.Spacing` apart along -Z, so the floor
   above starts its waking clock the moment it's laid (D-157 meant the first step on it). Fix:
   also require `Climb.on(on.floor, p.X, p.Z)` on the floor-local point, as `Climbs`' `onFloor`
   does; a Lune check if it can be pure. In Studio the dev floor 3's clock also starts at spawn.
2. S2-04 (next), then S2-05. S2-06 and L-08e3c wait on `OWNER.md`. R-01 is for later.
3. Found S2-03b: loose keepers hear a pounding door and go to look (felt as a feature; watch
   it). Deals' Studio line for a woken unit says "asleep" though it stands awake: Output only.
4. Found S2-03a: with waves on, a floor can hold more loose keepers than `Deal.awakeCap`;
   `Waking.AwakeMost` (six) bounds it. Watch it on a phone.
5. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
6. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
7. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
