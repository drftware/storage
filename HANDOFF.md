# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1d2 done: the room fits the band, ends at its corners (D-445) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1d3, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code** and `rojo serve` (port 34872) is connected: edits reach Studio's
  Edit place live; restart Play to run them.
- **The build camera at the bar on Small and XL** (D-445, `docs/art/s5-03j1d2-small.png`, `-xl.png`):
  your room alone on the dark (`ArrangeStage`), its walls' and floor paint's runs past the corners
  masked (`BuildView.runs`, masks built in `ArrangeCamera.gather`), the home view as near as the
  room fits the band (`BuildView.fit`; `aim` keeps the room centred in it), the limit bar top left,
  world buttons off while open. Small stands 26 studs out (its 10-stud walls bind), XL about 70.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`; `CameraTest` (client).
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1d3 The build camera on Medium and Large, its shots and its close
The moment: whatever home you own, Arrange lifts you out over it, the room whole and clear above
the tray; the front tab dips to your door; Done swoops you back into your eyes.
1. `get_studio_state`; Play. Server: `ArrangeTest:Invoke(player, "size", "Medium")`, wait 4,
   pivot to (62, 3, 479). Click Arrange (692, 27) then `wait` 2500 in the same list. Capture by
   STUDIO.md's "Capturing the phone" (screencapture, not `screen_capture`).
2. Medium, then Large: captured at the home view; `CameraTest` "state" and "right" 98-point drags
   round the circle. Look for: masks fading with their walls (no dark slab standing in front of
   the room from behind), nothing of the lobby showing at the screen's edges.
3. The front tab (gui 138, 328): the dip to the door; after a card chip, the hall dip. Done
   (666, 38): the swoop back into your eyes, the world back as it lands. WASD on a desktop
   device in the simulator's menu (`user_keyboard_input`).
4. A tap on a find in the room still lifts it (today's drag), so S5-03j2 starts from a base
   that works. Fix only what's broken; anything bigger goes to S5-03j2's lines.
5. Tune `Arrange.Camera` by what's seen, each change in DECISIONS. Stop Play; don't save.
   Captures to `docs/art/` at half scale (`sips -Z 336`).
**Acceptance:** Medium and Large seen and captured; the dips, the close and a lift seen; check green.
**Read first:** D-445 in DECISIONS; ROADMAP's S5-03j1d3 (grep it); `fit` and `runs` in
`src/shared/Home/BuildView.luau` (grep); `orbitFor` and `gather` in `ArrangeCamera.luau` (grep);
STUDIO.md's "build camera over a smaller home" section.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j1d3 comes S5-03j2 (drag it, let go). A yellow sliver shows at the A16's right edge
   (gui ~628, 100) in Arrange: not a world part; check what UI it is. `ArrangeCamera.Room.slot` is no longer read
   (D-443): drop it and ArrangeView's `slotBox` when next in there. `BuildView.eyeBox` is now called
   with a negative gap (D-444): rename it to say "reach past the walls" when next in there. After
   S5-03j and k: the home's three "Polish:" lines under S5-03g2b (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby place
   (D-352). A taken-out find comes out whole even when the save has it cracked.
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
