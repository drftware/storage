# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2b1b done: the ring seen in Studio (D-451) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j2b2a, b, c, j3 to j7, ENG-29, k1 to k6.
- **The ring is seen in Studio** (S5-03j2b1b, D-451, `docs/art/s5-03j2b-*.png`), with six
  fixes (D-451): Turn's arrow, Put away's box, `Ring.place`'s `avoid` (Done, the limit bar), a
  fresh one let go and put back, four turns home (`Lifted.turnRun`), a tall thing's ring. The
  camera holds still through a drag (logged per frame).
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2b2a Any angle, pure
The moment (j2b2b builds on this): two fingers on a chair twist it round, clicking into
quarters; with Free on it stops at any angle.
1. Read ROADMAP's S5-03j2b2 and its split (grep "S5-03j2b2a"); the plan doc's "Turning"
   section only (docs tools: read with a search for its heading).
2. Write `src/shared/Home/Turning.luau` (pure, header comment, small typed interface) with
   `tests/turning.spec.luau` first: given a start turn (degrees) and a twist (radians from
   Gestures), the turn to show; snapped to quarters unless `free`; negative and past-360
   twists; a quarter press and a twist agree.
3. Check whether any angle survives end to end: the server's Arranging (grep `turn` in
   `src/server` for the Place remote's checks), Brix's `Placements` (turned footprints: does it
   take 37 degrees?) and the save's encoding. For each that refuses, a failing spec, then widen
   it. A Brix change is a Brix ticket by `../engine/AGENTS.md` (`git -C ../engine status
   --short` clean first), then move `vendor/brix` and note it in `docs/FRAMEWORK.md`. Wire
   nothing on screen yet: j2b2b does.
**Acceptance:** `Turning` and any widened checks have Lune specs; a 37-degree pose passes the
server's check and the judge in specs; check green.
**Read first:** ROADMAP's S5-03j2b2 block; the plan doc's "Turning"; `src/shared/Home/Arrange.luau`
(grep `Turn`); the server's Place handler (grep `PlaceRemote`); Brix `Placements`' turn
handling (grep `turn` in `vendor/brix`); `ArrangeHand.settle` (lines ~286 to 320).

## Queue (next sessions, the owner's ticket order)
0. After S5-03j2: at the view Arrange opens with, a crate is about 16 points across on a Medium
   home (D-449): the camera's fit may want to open closer; the wheel zooms the eye through the
   unit's facade (`Colliders.FacadeRight`; STUDIO.md). D held 0.35 s slides the room half off
   the screen (black beyond): the slide may want a limit. The yellow sliver at Arrange's right
   edge is the minimap's "You" marker shown while its window is away (D-447): hide it. Drop the
   unread `ArrangeCamera.Room.slot` and `slotBox` (D-443); rename `BuildView.eyeBox` (D-444).
   Anything that projects from `ViewportSize` by hand lands 10 points low on a notched phone:
   give it `lens`'s screen (D-446). `ToolView.luau` ~1293 reads `WorldToViewportPoint`'s
   on-screen flag as "ahead" (D-451). Arrange reopens on the last tab: does the doc want that?
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
