# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j4b2 done: what's in the way glows (D-462) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j5a, j5b, j6, j7, ENG-29, k1 to k6.
- **S5-03j4 is done** (D-460 to D-462). Last: Brix's `Placements.blocking` feeds `ArrangeBlockers`,
  lighting what a red ghost presses into, one dull bump; seen at A16 (`docs/art/s5-03j4b2-*`).
  Put away's flight is too quick to capture (STUDIO.md).
- **Studio has tonight's code** (`rojo serve`, port 34872): restart Play to run edits.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j5a Place a held find where you look
The moment: in your own home, holding the teddy, you look at the job box's top and a see-through
teddy sits there, snapped and turned to the room; Drop reads Place, and one press sets it down
with the landing's knock (Animal Crossing's and The Sims' place-from-hand).
1. Read the plan doc's "Placing by hand" section. In your own home, while a find is held (the
   tool system), aim from the camera's ray with the hand's own aiming and judge (`aim`,
   `settle`, `fitsAt` in `ArrangeHand`): move the shared parts out into a module both use
   rather than copying them. A see-through copy (green-free: just faint) shows where it fits;
   nothing shows where it doesn't.
2. Drop's button (`ToolView`) reads Place while the copy shows; pressed, a new ask to
   `Arranging` sets it on that spot in one server step: type, range, ownership (your home, your
   held find), reach and rate checked as Take (D-350) and Place are; the save changes once.
   Elsewhere Drop is unchanged. No text explaining anything.
3. Lune specs for any pure piece; Studio at A16: hold a find in your home, capture the copy and
   the Place button (half scale plus a full-scale close-up in `docs/art/`).
**Acceptance:** green; the server refuses a bad, far or someone else's ask; seen in Studio.
**Read first:** ROADMAP S5-03j5 (grep); DECISIONS D-350; `src/server/Arranging.luau` `onPlace`
(630-700) and `takeOut` (568-600); `src/client/ToolView.luau` 495-520 (Drop); `ArrangeHand.luau`
`aim` to `standAt` (302-500); the plan doc's "Placing by hand".

## Queue (next sessions, the owner's ticket order)
0. S5-03j5b next after j5a (ROADMAP's split). Polish by name: the place's squash, a drag's tilt.
   Pallet and camp bed cards float back in the Small room (no free spot near the middle?):
   check (D-461). A tray card's drag isn't Gestures': the wheel zooms, no twist (route the wheel, D-453).
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
