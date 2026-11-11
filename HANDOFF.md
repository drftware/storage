# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 90 (overnight run, 5 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-06c2 done (D-102): the catch is a jump scare.** The hall goes silent and the HUD goes;
  your view is wrenched to its face and held (0.48 s); its head twitches back and rushes your eye
  as the view crash-zooms, with a scream, "Razormorph K" and a whoosh, its own groan and scrape
  (row beat Lunge); it lands taller than the screen with its thunk (Catch) and a hard knock,
  presses in, then a cut to black at 0.96 s (`Caught.Dark`, when the server moves you). "Caught"
  in the black over your own squeal; a slow wake (eyes crack, shut, open; blurred, grey; the
  hall's sound back). Friends see the film climb you as you turn once round (`Kept.wind`,
  KeptWrapOn, was KeptSqueal); the server wraps you at the catch now. Code: `CaughtLunge`, `Caught`,
  `Pose.Poses.Lunge`, `Mannequin.head`. Verified in Studio (log in ROADMAP).
- **Testing:** docs/STUDIO.md, "Testing the catch from the MCP" (157's guard; Workspace's
  `DevCatchHold` stops the catch on a frame) and "Sounds measured for the catch". By ear, on a
  phone and with a friend: the owner's (`OWNER.md`).
- Studio: nothing imported this session; left in Edit, seed 7, floor 1; `DevCatchHold` unset.

## Next task: L-08a The ride
The moment: the gate shuts, the car shudders and climbs while a floor counter ticks, and its
doors open on a new hall, as Dandy's World's elevator carries the team between floors.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08 and L-08a, D-046 (the leaving and today's stand-in ride: 4 s to black, then
   back to the spawn), `Departure` (the gate's clock, `AboardAttribute`: who rode) and the GDD's
   elevator section only (docs tools, never WebFetch). Brix's round loop (ENG-13) hadn't landed on
   Nov 10: check `docs/FRAMEWORK.md` and Brix's ROADMAP before building any of the loop here.
3. The ride on the server's clock, as the gate's is (one replicated value every screen counts
   from): everyone aboard rides, nobody else. Their screens: a lurch as it starts, a shudder and
   rumble while it climbs, the car's readout counting up (`Readout`), a slowing and a ding as it
   arrives, the doors opening. Feel numbers in shared Config with comments; pure timing curves
   Lune-tested.
4. Until L-08b lays the next floor, the car arrives at a stand-in (the same floor's lobby, the
   counter one higher); replace DevCorridor's stand-in ride (`Departure.Ride`, line ~578).
5. Sounds measured (docs/STUDIO.md's way), for a phone first: motor hum, cable clanks, the ding.
6. Left behind stays as it is (L-08c's); the lobby stays out of scope (L-08e waits on the owner).
**Acceptance:** checks green; in Studio on seed 7, floor 1: punch 1097, board, the gate shuts at 0,
the ride logged frame by frame (lurch, shake, counter ticks, arrival), sounds measured playing on
riders' screens only, a capture mid-ride and at the doors opening; Output clean; no per-frame
allocation in the ride's step.
**Read first:** ROADMAP L-08/L-08a; D-046; `src/shared/Elevator/Departure.luau`;
`src/server/Elevators.luau`; `src/client/ElevatorView.luau`; the GDD's elevator section.

## Queue (the next run's order, from ROADMAP)
1. L-08b the next floor, L-08c left behind, L-08d the climb ends. L-08e (the start, in the
   lobby) waits for the owner's lobby plan (Nov 11).
2. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
3. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
4. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
5. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
