# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, ENG-27 Gestures in Brix (D-437) · **Checks:** green · **Git:** `main`, not pushed; Brix `f291d7f`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order: ENG-28, S5-03j1, ENG-26c, j2 to j7, ENG-29, k1 to k6.
- **ENG-27 done** (D-437): `Brix.Gestures` reads fingers, mouse, wheel, sticks and triggers into
  one intent at a time (tap, double tap, hold, drags with a flick speed; the camera's slide,
  pinch, twist, tilt). The pin is at `f291d7f`; nothing in the game uses it yet (S5-03j1 wires it).
- L-11a2 done (D-435). The home (S5-03) a to i done; its "Polish:" lines wait (Queue).
- Studio hooks: `CardTest`; `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows",
  "fromShelf", "shelfAway", "size"; `GrowTest` "cash"; Trips' `DevTripFinds`. Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1),
  cash 38, no card styles owned, Boombox 10, Skates 1.
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: ENG-28 The orbit camera, in Brix (S5-03j's second piece)
The build camera's maths: The Sims' camera you turn, slide, zoom and tilt, gliding on springs,
never snapping. Built in `../engine` by Brix's own AGENTS.md (neutral names, its checks, its own
commit with no trailer, its untracked HANDOFF), then the game's pin moves (D-252).
1. Read Brix's AGENTS.md; file ENG-28 in Brix's ROADMAP (after ENG-27).
2. Contract and suite first. State: a focus point on the floor, a heading, a tilt and a distance,
   each eased toward its goal by a stock Smoothing. In: Gestures' intents' numbers (a slide in
   screen points turned to studs from the distance and the field of view, a twist in radians, a
   tilt in points, a pinch's scale about a point, a drag's flick speed for a drift that dies away),
   an edge follow while something is dragged near the screen's edge, and a reset to the home view.
   Limits: a box the focus can't leave, near and far stops, tilt from straight down to eye height.
   Out: a camera position and a look point. `step(dt)`, allocation-free. Pure.
3. Implement until the suite passes; a bench for a step; a module page in `docs/modules/`.
4. Commit in Brix; move `vendor/brix` (`git -C vendor/brix fetch ../../engine main`, then check
   out FETCH_HEAD); note it in `docs/FRAMEWORK.md`.
**Acceptance:** each promise fails its suite when broken; `scripts/check.sh` green here and
Brix's checks green there; nothing in the game uses it yet (S5-03j1 wires it).
**Read first:** the doc's camera list (Part 1, "The camera"); ROADMAP's ENG-28 line (grep
`ENG-28`); `../engine/AGENTS.md`; `../engine/src/Contracts/Smoothing.luau`;
`../engine/docs/modules/Gestures.md`; `../engine/docs/modules/Smoothing.md`.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j and k: the home's three "Polish:" lines under S5-03g2b (the hand-over's shade,
   D-326, D-327; the mirror keeping the old look; the floor's wipe under the tray, D-328), then
   g3b's plate swapping in plays (ROADMAP's "Polish (g3b)").
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352). A taken-out
   find comes out whole even when the save has it cracked. Several of these may fall out of
   S5-03j's rebuild: check each against it before building.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 361.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
