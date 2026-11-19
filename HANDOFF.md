# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2b2b1 done: twist, R, wheel, Free in code (D-453) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j2b2b2, c, j3 to j7, ENG-29, k1 to k6.
- **Turning a held thing is in code, untested in Studio** (S5-03j2b2b1, D-453): a twist or the
  wheel (a quarter a notch) on a carried thing turns it (`ArrangeHand.twist`), a ratchet and spin
  per quarter, Free's soft tick every 15 degrees; `ArrangeTurn` (new) holds R, Alt and the Free
  switch under Done; `settle` keeps a thing in by `Turning.reach` at any angle.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2b2b2 Turning, seen in Studio
The moment: R or the wheel clicks a held crate round; Free sets it askew and it stays askew.
1. STUDIO.md's two tells first (is Studio on tonight's code). Play at A16 (685 by 338), Medium
   home; Arrange is (681, 37); MCP clicks land about 47 points left of the gui point.
2. Select a crate (tap it): press R (`user_keyboard_input`): a quarter, click-click, spin past.
   Drag it and press R mid-drag. If the MCP mouse can't hold a drag and roll the wheel, send the
   hand a twist from a Client `execute_luau` (a `{kind = "twist", angle = math.pi / 2, target =
   <the crate>}` while carrying) or extend ArrangeCamera's Studio-only `CameraTest`.
3. Tap the Free switch under Done: it lights honey at a glance (capture it on and off). Drag the
   crate with Free on and twist it to an odd angle (a twist of 0.6 radians); let go. It lands
   askew, green; the server keeps it (Output quiet; `Arranged` has it at that turn).
4. Stop and Play again (a rejoin): it comes back at that angle, and nothing drawn overlaps it.
5. Hold Alt (a Client `execute_luau` can't hold keys: try `user_keyboard_input`; else judge from
   the switch). Fix what reads wrong; capture `docs/art/s5-03j2b2b-*.png` at half scale.
**Acceptance:** R, a twist and Free seen working at A16; a free angle survives a rejoin; check
green. **Budget:** about 100k context for a Studio check (S5-03j2b1b's note).
**Read first:** ROADMAP's S5-03j2b2b2; STUDIO.md's "Arrange's build camera, first try in Play";
`src/client/ArrangeTurn.luau`; ArrangeHand's `twist` and `turnNow`; ArrangeCamera's `CameraTest`.

## Queue (next sessions, the owner's ticket order)
0. A card dragged up out of the tray is the tray's own drag, not Gestures', so the wheel zooms
   and a second finger can't twist it (R and Free work): route the wheel to the hand while a
   tray drag carries (D-453). After S5-03j2: at the view Arrange opens with, a crate is about 16 points across on a Medium
   home (D-449): the camera's fit may want to open closer; the wheel zooms the eye through the
   unit's facade (`Colliders.FacadeRight`; STUDIO.md). D held 0.35 s slides the room half off
   the screen (black beyond): the slide may want a limit. The yellow sliver at Arrange's right
   edge is the minimap's "You" marker shown while its window is away (D-447): hide it. Drop the
   unread `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444).
   Projections from `ViewportSize` by hand land 10 points low on a notched phone: use `lens`'s
   screen (D-446). `ToolView.luau` ~1293 reads `WorldToViewportPoint`'s on-screen flag as
   "ahead" (D-451). Arrange reopens on the last tab: does the doc want that?
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
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
