# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j1c done on a Small home (D-443) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only). Order now: S5-03j1d, j2 to j7, ENG-29, k1 to k6.
- **Studio has tonight's code** and `rojo serve` (port 34872) is connected: edits reach Studio's
  Edit place live; restart Play to run them.
- **The build camera** (`src/client/ArrangeCamera.luau`, `Home/BuildView`, `Arrange.Camera`):
  the eye stays over the room and out through the door (`BuildView.eyeBox`, Brix's `eyeArea`),
  brought in level; the focus shows mid-band between the top bar and the tray's tabs (Brix's
  `aim`, ArrangeView's `clear`); a wall the eye nears over the room is gone (`BuildView.fade`).
  Brix ENG-28b (`3e9a2bb`) added both; the pin is there. `CameraTest` drives it (STUDIO.md).
- **Not at the bar yet** (D-443's last bullet, `docs/art/s5-03j1c-small-*`): from the door the
  lobby's walls frame the room like a doorway; over a Small room the eye sits close under the
  10-stud ceiling and the corner shelf fills the view; the door's Close/Slam and the limit bar
  sit in the band.
- Studio hooks: `CardTest`; `ShelfTest`; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; `GrowTest` "cash"; `DevTripFinds`; `CameraTest` (client).
- **Climb run (on hold until S5-03j and k are done, the owner, Nov 18):** left: S5-01d's held
  torch over the car's board, S5-02b2c2, then S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j1d The build camera at the bar, on every size, and its fixed shots
The moment: whatever home you own, Arrange lifts you out over it, the room whole and clear in the
band above the tray, and you want to start placing things.
1. `get_studio_state`; Play. Server: `ArrangeTest:Invoke(player, "size", "Small")`, pivot to
   (62, 3, 479). Click Arrange (692, 27) then `wait` 2000 in the same list. Capture (STUDIO.md).
2. Fix D-443's three faults first, judging each capture by "would a player see their room
   clearly and want to start placing things?". Ideas to try, cheapest first: let the hall part
   of `eyeBox` run as wide as the facade so the opening comes in at a corner; fade or hide
   (`LocalTransparencyModifier`) furniture between the eye and the focus; hide the door's
   prompts and the job box's "Open" while Arrange is open (Queue 2); and, if a Small room is
   still too close, look at hiding the lobby's ceiling (`UnitTops`) for you alone while Arrange
   is open so the eye can rise over the walls as The Sims' does (D-439 said no; decide by
   looking, write it in DECISIONS).
3. Then Medium, Large and XL: `CameraTest` "state" and "right" 98-point drags round the circle.
4. The front tab (third tab, gui 138, 328): the swing to the door; after a card chip, the dip to
   the hall. Done (666, 38): the swoop back into your eyes. WASD via `user_keyboard_input`.
5. Tune `Arrange.Camera`, noting each change in DECISIONS. Stop Play; don't save. Captures to
   `docs/art/` at half scale (`sips -Z 336`).
**Acceptance:** each size seen and captured at the bar; the fixed shots and the close seen; check green.
**Read first:** ROADMAP's S5-03j1d (grep it); D-443 in DECISIONS; STUDIO.md's two build camera
sections (grep "build camera"); `orbitFor`, `fadeWalls` and `open` in `ArrangeCamera.luau`
(grep); `BuildView.eyeBox`.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j1d comes S5-03j2 (drag it, let go). `ArrangeCamera.Room.slot` is no longer read
   (D-443): drop it and ArrangeView's `slotBox` when next in there. After S5-03j and k: the
   home's three "Polish:" lines under S5-03g2b (D-326, D-327, D-328), then g3b's plate swapping.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting's leftovers
   (D-353): cross-legged on the blanket needs our own animation; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352). A taken-out
   find comes out whole even when the save has it cracked. Check each against S5-03j first.
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
