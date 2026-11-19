# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1d1 done: the roof comes off (D-444) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1d2, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code** and `rojo serve` (port 34872) is connected: edits reach Studio's
  Edit place live; restart Play to run them.
- **The build camera now looks down into an open-topped room** (D-444): while its orbit is the
  view, `ArrangeStage` (client) hides everything but your unit and the players for your screen
  (`LocalTransparencyModifier`), lays a dark Neon floor, clears the haze and blur and raises the
  ambient light; all put back on `drop`. The eye goes anywhere within `Around` (20) of the walls,
  no ceiling; home view: a front corner at `HomeTilt` 0.95. Orbit to fixed shot is always a dip.
- **Not at the bar yet** (`docs/art/s5-03j1d-small-stage.png`, before: `-small-before.png`): the
  sliding walls' long ends past the corners (D-354) stand in the dark; the room is a little dim
  and sits high in the band (walls under the top bar); the door's Close and Slam still show.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`; `CameraTest` (client).
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1d2 The build camera at the bar, on every size, and its fixed shots
The moment: whatever home you own, Arrange lifts you out over it, the room whole and clear in the
band above the tray, and you want to start placing things.
1. `get_studio_state`; Play. Server: `ArrangeTest:Invoke(player, "size", "Small")`, pivot to
   (62, 3, 479). Click Arrange (692, 27) then `wait` 2500 in the same list. Capture (STUDIO.md).
2. **Mask the walls' long ends.** A smaller home's Left and Right walls run the XL depth and its
   Back wall the XL width (Small, Unit1: Left/Right x 60.3 to 89.9 at z 473.6 and 482.4, Back
   z 468 to 488 at x 68.4). Write a pure `BuildView.runs(room box, wall boxes)` (Lune spec first)
   giving each run past a corner as a box; `ArrangeStage` or `ArrangeCamera.gather` makes a Neon
   `Cam.Void` box a hair bigger than each run and adds it to that wall's fade group, so it fades
   with its wall and otherwise hides the run against the dark.
3. **Fit the home view to the band:** the distance from the floor's size, `HomeTilt` and the band
   (ArrangeView's `clear`, 58 to 186 on the A16), pure in `BuildView` with a spec; the room's floor
   whole in the band. Light a touch brighter (`Arrange.Camera.Light`, try 150, 140, 128).
4. **Hide the door's Close and Slam and the job box's Open while Arrange is open** (they're
   ProximityPrompts; check on create.roblox.com whether `ProximityPromptService.Enabled` can be set
   from a client before using it, else disable each prompt in your unit locally; note it in STUDIO).
5. Medium, Large, XL: `CameraTest` "state" and "right" 98-point drags round the circle. The front
   tab (gui 138, 328): the dip to the door; after a card chip, the hall dip. Done (666, 38): the
   swoop back into your eyes, the world back as it lands. WASD via `user_keyboard_input`.
6. Tune `Arrange.Camera` by what's seen, each change in DECISIONS. Stop Play; don't save.
   Captures to `docs/art/` at half scale (`sips -Z 336`).
**Acceptance:** each size seen and captured at the bar; the fixed shots and the close seen; check green.
**Read first:** D-444 in DECISIONS; ROADMAP's S5-03j1d2 (grep it); `src/client/ArrangeStage.luau`
(whole, 170 lines); `orbitFor`, `gather` and `step` in `ArrangeCamera.luau` (grep); STUDIO.md's
"build camera over a smaller home" section.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j1d2 comes S5-03j2 (drag it, let go). `ArrangeCamera.Room.slot` is no longer read
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
