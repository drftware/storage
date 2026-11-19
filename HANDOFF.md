# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j2b done: turning seen in Studio, riders hop (D-454) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j3a, b, c, j4 to j7, ENG-29, k1 to k6.
- **Turning is seen working in Studio** (D-454): R, the wheel mid-drag, Alt, the Free switch, a
  free twist kept off the grid through a rejoin. **Riders hop** as their piece lands
  (`Home/Settle`, ArrangeHand's `bounce`), seen with two finds on the job box.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j3a The snapper, pure
The moment: a chair pushed toward a wall swings its back to it; a cup dragged over the table
hops up onto it; the thing lines up with its neighbours as faint lines flash (The Sims 4).
1. Read the plan doc's snapping lines and its feedback table's "onto a table" row (docs tools,
   search the heading). ROADMAP's S5-03j3 holds the split (a pure, b seen and heard, c walls).
2. How settle snaps now: `ArrangeHand.settle` (line ~313), `PlacementSnap.grid` and
   `Turning`; how a find picks its top today (`Arrange.frameOn`, `Spots.pieceTop`).
3. Specs first, `tests/snapping.spec.luau`, then `src/shared/Home/Snapping.luau` (pure, a
   header comment, small typed interface): the half-stud grid; a piece near a wall (within a
   reach, a Feel number) turns its back to that wall, Free aside; which top a find over a piece
   stands on and when it steps back down (a little give so it doesn't flicker at the edge).
4. Guide lines: Brix's `placements:align` (ENG-26c), one answer kept per drag (zero allocation);
   Snapping says which lines to draw; drawing them is b's.
5. Wire into `settle`; keep ArrangeView only wiring. If budget allows, see a crate pushed to a
   wall turn its back in Studio at A16 (CameraTest "carry", STUDIO.md).
**Acceptance:** specs pass; near a wall a piece faces out, over the job box a find stands on it.
**Read first:** ROADMAP's S5-03j3; the plan doc's snapping section; Brix
`vendor/brix/docs/modules/Placements.md` lines 35-55 (align); `ArrangeHand.settle` by line
range; `src/shared/Home/Turning.luau` (a pure module's pattern); `Layout.backGap` (walls).

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
