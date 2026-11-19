# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j3c1 done: wall things slide at their height (D-458) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j3c2, j4 to j7, ENG-29, k1 to k6.
- **Wall things slide** (D-458): `Home/WallHang` (pure) keeps a hung thing's height as it's
  dragged, round corners too; `ArrangeHand.aim` uses it. Seen in Studio at A16,
  `docs/art/s5-03j3c1-sign-slides-high*.png`. `WallHang.raise` (the handle's steps) is written
  and tested but not wired.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j3c2 The height handle
The moment: tap the neon moon on the wall and a small round handle sits just above it; drag the
handle up and the moon rises along the wall a tick per half stud, as The Sims 4's wall-height
handle does (Free: by eye, no ticks).
1. A fourth ring button in `ArrangeRing` (its look: round, `Feel.RingSize`, a small up-down
   arrow icon of `bar`s), shown only for a selected thing that hangs (`WallHang.only` on its
   shape's `fits`, never an id), placed above the thing's screen box, not in the row.
2. Its drag is its own (InputBegan on the button, then UserInputService InputChanged/Ended, as
   the tray card's drag in ArrangeView ~497 and ~1456 is): screen points up are converted to
   studs on the wall by the camera (the wall point under the thing and one stud above it, both
   to the screen), then `WallHang.raise(from, by, step, area.depth, shape.depth)` (step
   `Arrange.Step`, 0 when `options.free()`), then `settle` and `setPose`. Tick per changed
   height (`tick`, ArrangeHand ~243); the Gestures camera must not pan meanwhile.
3. A new hand call, say `raiseBy(studs)`, on ArrangeHand's returned table; the ring's option
   calls it. Let go places through the usual Place path (as Turn's does: `turnNow` ~1093).
4. Studio at A16 (STUDIO.md "Proving snapping in Play", its wall-thing line): select the sign,
   drag the handle up two steps; capture to `docs/art/` half scale plus a full-scale close-up.
**Acceptance:** green; the handle seen and dragged in Studio at A16, the height moved in steps.
**Read first:** `Home/WallHang.luau` (all); `ArrangeRing.luau` 1-50, 124-170; `ArrangeView.luau`
315-335, 1232-1265; `ArrangeHand.luau` 539-560 (setPose), 1093-1130 (turnNow); DECISIONS D-458.

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
