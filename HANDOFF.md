# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j3a2 done: the snapper in the hand (D-456) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j3b, j3c, j4 to j7, ENG-29, k1 to k6.
- **Snapping is live in Arrange** (D-456): a piece with a back turns to a wall as it arrives
  and sits flush; Brix's line-up fills `Lifted.lines` on every settle (not drawn yet); a find
  stands on a top only with its middle over it. Seen in Studio at A16, `docs/art/s5-03j3a2-*`.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j3b Snapping seen and heard
The moment: a cup dragged over the job box hops up with a light tock, and down again; a crate
slid beside another shows a faint line where their edges meet, as The Sims 4 draws its guides.
1. A new client module `src/client/ArrangeGuides.luau` (header, small typed interface): a pool
   of six thin anchored parts made once (`new(parent)`), faint warm white, no collide, touch,
   query or shadow; `show(frame, lines)` lays the first `lines.count` of `lines.guides` on the
   area's frame (a guide on "x" stands at x = `at` from y = `from` to `to`; floor y is the
   frame's -Z), parks the rest; `hide()`. Called only when the pose changes, never per frame.
2. `ArrangeHand` owns one: `setPose` shows `l.lines` on `Arrange.frameOn(r, pose.on)` while a
   thing is carried; hide on let go, Put away, the server's answer and `stopFollow`.
3. The tock: in `setPose`, when `was.on ~= pose.on` and either is a top (not
   `r.placements:areaOf`), play `TOCK` (the knock, higher and quieter, beside `CLINK`) instead
   of the step's tick. Check the plan doc's feedback table row for "onto a table" first.
4. Studio at A16 (STUDIO.md "Proving snapping in Play"): drag a crate beside the other till
   their edges line up and capture the line; carry the moon lamp off and onto the job box and
   read the tock's Sound under the screen's sounds folder.
**Acceptance:** green; the lines and the tock seen in Studio, captured to `docs/art/`.
**Read first:** `ArrangeHand.luau` lines 481-530 (shade, paint, setPose) and 1295-1320 (drop);
`Home/Snapping.luau` lines 166-212; `vendor/brix/src/Contracts/Placements.luau` lines 160-185;
`Home/Arrange.luau` lines 238-280 (the sounds); DECISIONS D-456; ROADMAP's S5-03j3b and j3c.

## Queue (next sessions, the owner's ticket order)
0. A tray card's drag isn't Gestures': the wheel zooms, no twist (route the wheel, D-453).
   At Arrange's opening view a crate is ~16 points across (D-449): open closer; the wheel zooms
   through the facade (STUDIO.md). D held slides the room half off screen: limit it. Hide the
   minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename
   `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch: use `lens`
   (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451). Arrange reopens
   on the last tab: does the doc want that? `aim`'s room `REACH` stays 2.5 (D-455). A blocked
   let-go's slide settles flush and lined up and may be judged blocked again: watch (D-456).
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
