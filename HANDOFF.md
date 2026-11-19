# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j3b done: snapping seen and heard (D-457) · **Checks:** green · **Git:** `main`, not pushed; Brix `3e9a2bb`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j3c, j4 to j7, ENG-29, k1 to k6.
- **Snapping is seen and heard** (D-457): `ArrangeGuides` draws Brix's lines while a thing is
  carried; a hop between surfaces of different heights tocks. Seen in Studio at A16,
  `docs/art/s5-03j3b-crate-lined-up.png`.
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j3c Wall things
The moment: a neon moon dragged across a wall glides along it at the height it hung, and a
small handle above it lifts or lowers it, as The Sims 4's wall height does (Alt aside: Free).
1. Read the plan doc's section on wall things (search "wall"), and ROADMAP's S5-03j3c line.
   Wall things are any catalog row whose spot is "Wall" (`Spots`, `Furniture` rows): no ids.
2. In `ArrangeHand.aim`, a thing that fits only walls keeps its height on the wall as the finger
   moves (it slides along the wall it's on; across a corner it moves to the next wall at the
   same height). Put the pure part (height kept, clamped to the wall's area) in a pure module
   with Lune specs first (`Home/Snapping` or a new `Home/WallHang`).
3. A height handle: a small round button above the selected wall thing (ArrangeRing's look),
   drag it up or down to change only its height, grid steps unless Free; a tick per step.
4. Studio at A16 (STUDIO.md "Proving snapping in Play"): drag the neon moon (buy or add it by
   `ArrangeTest`) along a wall and raise it; capture to `docs/art/`.
**Acceptance:** green; the slide and the handle seen in Studio at A16 and captured.
**Read first:** `ArrangeHand.luau` lines 269-330 (aim) and 368-430 (settle); `Home/Spots.luau`
lines 60-90; `Home/Arranged.luau` lines 63-90; `ArrangeRing.luau` lines 1-60; DECISIONS D-455.

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
