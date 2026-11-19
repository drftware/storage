# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2b1a done: select and the ring, in code (D-450) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; its feedback table is under "Every action answers"). Order now: S5-03j2b1b, j2b2, j3 to
  j7, ENG-29, k1 to k6.
- **Select and the ring are in code, untested in Studio** (S5-03j2b1a, D-450): `Ring.place`
  (pure, specs), `ArrangeRing` (Put away, Turn, Another as round icon buttons), a tap selects a
  hair up, Turn's ratchet and overshoot, the hand's `another`. The verbs bar and its × are gone.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits. Hooks:
  `ArrangeTest` ("size", "place", ...), `CameraTest` (client), `GrowTest` "cash".
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2b1b The ring seen in Studio
The moment: tap the lamp, it lifts a hair and round buttons pop in over it; Turn clicks it round
with a little spin past; the plus sets one more beside it.
1. Read ROADMAP's S5-03j2b1b (grep it) and D-450. STUDIO.md's "A drag must be one
   `user_mouse_input` call" and "Tapping a placed find" before driving Studio.
2. Run STUDIO.md's two tells that Studio has tonight's code; Play at A16 (685 by 338), Medium.
3. Tap a find: it comes up a hair with the stretch; the ring sits over it, clear of it. Turn:
   click-click, spins past and back. Put away: shrinks into the tray. Another on a find the box
   holds more of: the first settles, one more comes out beside it, turned the same, selected.
   Tap the room: the ring goes, it lands. Slide and pinch: the ring follows. A find high on the
   screen: the ring sits under it.
4. Judge the icons at phone size (crop and enlarge; `ArrangeRing`'s `turnIcon`, `awayIcon`,
   `anotherIcon` are frames) and fix what reads wrong. Check the ring's `area` against Done (top
   right) and the limit bar (top left): give `Ring.place` the band under them if the ring hits
   them.
5. The conductor's question (D-450): through one drag with no wheel, does the camera hold still
   (it may only slide near the screen's edge)? Capture the drag's start and middle and compare.
6. Capture to `docs/art/s5-03j2b-*.png` at half scale.
**Acceptance:** each of step 3 seen in Studio Play at A16 and captured; check green.
**Read first:** ROADMAP's S5-03j2b1b; D-450; `src/client/ArrangeRing.luau` (270 lines); the
hand's `another`, `turnNow` (grep); STUDIO.md's drag and "Tapping a placed find" sections.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j2: at the view Arrange opens with, a crate is about 16 points across on a Medium
   home (D-449): the camera's fit may want to open closer; the wheel zooms the eye through the
   unit's facade (`Colliders.FacadeRight`; STUDIO.md). The yellow sliver at Arrange's right edge
   is the minimap's "You" marker shown while its window is away (D-447): hide it. Drop the unread
   `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Anything
   else that projects from `ViewportSize` by hand lands 10 points low on a notched phone: give it
   `lens`'s screen (D-446). Arrange reopens on the last tab (the door shot): does the doc want
   that? After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353):
   cross-legged on the blanket needs our own animation; lying on the bed.
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
