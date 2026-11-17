# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 257 (S5-03f2b, wearing from the rail, D-316) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror test, shelf, job box and its panel, taking out, selling, Golds,
  taking finds up, Arrange, the mirror's frame, the clothes rail, and now wearing from it.
- Wearing from the rail (D-316): `Rails` (server) stands each worn kind in your job box on the
  rail's hat shelf; Wear makes it from your box onto your head (`Slots:boxToHead`, marked from
  your box, save unwritten) and stamps its press (`FindUses:wearLit`, lit forever at home); Hang
  up puts it back (`Slots:hangUp`). Presses holder-only (HomeCards). `Save.keep` never shelves a
  worn find; `Save.unshelve` lifts an old save's hat off the shelf. Seen on the A16
  (`docs/art/S5-03f2b-worn-mirror-a16.jpg`).
- A worn find from the rail is still "out of your box": taken up in a lobby car it's at risk
  (D-302), recalled if you leave at home.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: one HardHat kept this session (on the rail); cash read 0 in Play again.
  Studio's Device Simulator is on the Galaxy A16, landscape. A world button can be pressed from a
  Client `execute_luau` (`InputHoldBegin`/`End`, STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f3 Nothing worn or switched on runs down at home
The moment: at home your hat burns for good; the minute you ride a lobby car up, it starts
counting down like any found light, so the climb's danger is real and home stays safe (D-259,
idea 23's rule). Today a hat lit at home stays lit forever even on the climb (D-277's note).
1. Read D-277's last bullet, D-259's rule, and F-G1b4b in ROADMAP (the hat spent): f3 is the
   start of its minute; split f3 in ROADMAP if it won't fit.
2. Find where a find's light is stamped `Use.Forever` (`FindUses` `atHome`, `wearLit`) and where
   you leave home (`Slots:up` from Climbs' board, or the car's gate). As you leave, restamp each
   lit find you carry or wear with its own full minute from now (`Use` rules, pure, tested first).
3. Every screen must see the new stamp (the battery's look, FindUseView); nothing at home changes.
4. `scripts/check.sh` green; in Play: wear the hat from the rail, ride a lobby car up, see its
   light start running down on floor 1 (or exact steps in OWNER.md).
**Acceptance:** check green; a failing Lune test first; the climb's countdown seen or in OWNER.md.
**Read first:** D-277, D-259; `src/server/FindUses.luau` (`atHome`, `wearLit`, `onUsed`);
`src/shared/Finds/Use.luau` (`Forever`, `press`); `src/server/Slots.luau` `system.up`;
`src/server/Climbs.luau` where it calls `up`.

## Queue (next sessions, the owner's ticket order)
1. S5-03f4, then S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-316.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. Cash shows 0 in Play while the test save says 476: not looked into (seen twice).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
