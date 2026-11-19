# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j3c2 done: the height handle (D-459) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j4a, j4b, j5 to j7, ENG-29, k1 to k6.
- **The height handle** (D-459): an up-down button over a selected wall thing (`Ring.handle`);
  its drag goes to the hand's `raiseStart`/`raiseBy`/`raiseStop` (`WallHang.along`, `raise`,
  `settle`). Seen in Studio at A16, `docs/art/s5-03j3c2-handle-*.png`.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j4a Undo and redo
The moment: you shove the bed into the wrong corner, tap Undo and it glides back; Redo sends it
again, as The Sims 4's build mode undo. Only while Arrange is open; closing forgets the list.
1. The plan doc's undo lines (search "Undo" in the doc's room editor section) and ROADMAP's
   S5-03j4 lines. Check Brix (`../engine/src`, `docs/FRAMEWORK.md`) for an undo list: none
   exists today. A plain undo/redo list is generic, so build it in Brix by its AGENTS.md (neutral
   name, contract, suite, module page, its own commit), then move `vendor/brix` (D-252);
   `git -C ../engine status --short` must be clean first.
2. What one entry holds: a thing's id and its pose before and after (or "in the box" for a set
   out or put away), read from the hand's moves (`placeNow` ~996, `awayNow` ~1184, `another`
   ~1545, and the answer in `answered` ~1251: record only what the server accepted).
3. Undo and Redo send ordinary Place or Put away asks (no new remote): the server judges them as
   any move, so a spot taken since is refused and the entry dropped, with the refusal's usual
   answer. A find from the box undone back to the box is a Put away.
4. Two round buttons beside Done (ArrangeView ~1238, kept clear by the ring's `avoid`), icons not
   words (a curved arrow each way), dim when there's nothing to undo; Ctrl+Z / Ctrl+Y on a
   keyboard. The thing glides on the usual LAND tween with its knock or thud.
5. Studio at A16: move a crate, Undo, Redo; capture half scale plus a close-up of the buttons.
**Acceptance:** green, Brix's suite too; the list's specs; undo and redo seen in Studio.
**Read first:** ROADMAP S5-03j4 (grep it); `ArrangeHand.luau` 996-1050, 1184-1200, 1251-1300;
`ArrangeView.luau` 1232-1300; `src/server/Arranging.luau` 1-60; `../engine/AGENTS.md`.

## Queue (next sessions, the owner's ticket order)
0. A tray card's drag isn't Gestures': the wheel zooms, no twist (route the wheel, D-453).
   At Arrange's opening view a crate is ~16 points across (D-449): open closer; the wheel zooms
   through the facade (STUDIO.md). D held slides the room half off screen: limit it. Hide the
   minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename
   `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch: use `lens`
   (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451). Arrange reopens
   on the last tab: does the doc want that? `aim`'s room `REACH` stays 2.5 (D-455). A blocked
   let-go's slide settles flush and lined up and may be judged blocked again: watch (D-456).
   One lamp drag off the job box tocked three times (D-457): find the third surface.
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
