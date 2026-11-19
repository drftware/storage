# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03j2b2a done: any angle, pure (D-452) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j2b2b, c, j3 to j7, ENG-29, k1 to k6.
- **Any angle works end to end** (S5-03j2b2a, D-452): `Home/Turning` (pure) gives the turn a
  twist or a Turn press shows; the server, Brix's judge, the save and the drawing take any angle
  (`arranged.spec` proves the footprint judged is the box drawn); the job box's lid room counts
  at any angle. Nothing on screen uses Turning yet.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j2b2b Twist, R and the wheel, Free
The moment: a second finger twists a dragged chair round, clicking each quarter; Free stops it anywhere.
1. ROADMAP's S5-03j2b2b ("From j2b2a" lines); the plan doc's "Turning" (read: search "Turning").
2. In ArrangeHand's `intent` (~line 1163), a "twist" with a target while carrying: keep the
   twist's sum since it began and the turn it began at; show `Turning.twisted(start, sum, free)`
   (negate the twist when the camera sees the face from behind: the ceiling from above). Play
   `Arrange.Ratchet` each time the shown quarter changes; with Free a soft tick every 15 degrees.
   R turns by `Turning.press` as `turnNow` does; the wheel comes as a twist with a target
   (Gestures' `wheelTurn`: a quarter, pi/2, so a notch clicks a quarter).
3. Free: Alt held, or a round switch in a corner (an icon in ArrangeRing's style, off by
   default, lit while on), swaps the grid snap for `Brix.PlacementSnap.free({ turn = 1 })`.
   `settle` (~line 290) clamps with width and depth swapped only at quarters: use the turned
   reach (|cos|, |sin|). The mirror keeps to quarters (it leans only square, D-452).
4. Studio Play at A16 (685 by 338), Medium home, Rojo connected (STUDIO.md's two tells first):
   R and the wheel on a held crate, Alt and the switch place it at an odd angle, it saves
   through a rejoin. Capture `docs/art/s5-03j2b2b-*.png`; the twist goes to OWNER.md's phone steps.
**Acceptance:** R, the wheel and a twist turn a held thing, clicking at quarters; Free places
at any angle and the server keeps it; seen in Studio at A16; check green.
**Read first:** ROADMAP's S5-03j2b2b; `Home/Turning.luau`; ArrangeHand's `intent`, `turnNow`,
`settle`; ArrangeRing's button making; ArrangeCamera's `toHand` (~487) and its Gestures options.

## Queue (next sessions, the owner's ticket order)
0. After S5-03j2: at the view Arrange opens with, a crate is about 16 points across on a Medium
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
