# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1b done on a Small home (D-442) · **Checks:** green · **Git:** `main`, not pushed; Brix `b8f5d71`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1c, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code** and `rojo serve` (port 34872) is connected: edits reach Studio's
  Edit place live; restart Play to run them.
- **The build camera** (`src/client/ArrangeCamera.luau`, `Home/BuildView`, `Arrange.Camera`):
  opens out past the near walls (`BuildView.homeView`, D-442), every wall fades in turn on a
  Small home. A Studio-only `CameraTest` hook drives it as a mouse would (STUDIO.md, the build
  camera's section: also how to get into Arrange, the click points, and the MCP's camera reset).
- **Brix's nearest free spot and guide lines** (ENG-26c, D-441): `placements:nearestFree`,
  `Brix.PlacementSearch.grid`, `placements:align`; pure, j2 and j3 wire them (FRAMEWORK.md).
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`; `CameraTest` (client).
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1c The build camera on every size, and its fixed shots
The moment: whatever home you own, Arrange lifts you out over it into a dollhouse view, near walls
gone, and the front tab still swings round to face your door.
1. `get_studio_state`; Play. Server: `ArrangeTest:Invoke(player, "size", "Medium")`, pivot the
   character to (62, 3, 479). Click Arrange (692, 27), then `wait` 2000 ms in the same list.
2. `CameraTest` "state", then "right" 98-point drags round the circle: each wall's fade comes in
   as the eye passes it. Capture the opening and a side view (STUDIO.md's crop, ~300 tokens).
3. The same for Large (its corner only just fits, 0.1 stud spare) and XL (in through the door
   at `Slant`). At XL the eye can't pass a side wall: look, then decide D-440's question in
   DECISIONS (keep D-439, or say what to change and why).
4. The front tab (the third tab at gui 138, 328): the swing to the door; after a card chip, the
   dip out to the hall. Done (666, 38): the swoop back into your eyes. WASD from
   `user_keyboard_input` (keyDown, wait, keyUp) slides.
5. Tune `Arrange.Camera` by what's seen, noting each change in DECISIONS. Stop Play; don't save.
6. Save captures to `docs/art/` at half scale (`sips -Z 336`).
**Acceptance:** each size seen and captured; the fixed shots and the close seen; check green.
**Read first:** ROADMAP's S5-03j1c (grep it); STUDIO.md's "Arrange's build camera, first try in
Play" (to its end); D-442 in DECISIONS; `orbitFor` and `open` in `src/client/ArrangeCamera.luau`
(grep); `BuildView.homeView`.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j1c comes S5-03j2 (drag it, let go). After S5-03j and k: the home's three "Polish:" lines under S5-03g2b (the hand-over's shade,
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
