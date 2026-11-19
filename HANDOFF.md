# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j5a2 done: placing by hand seen in Studio, fixed (D-464) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j5b1, j5b2, j6, j7, ENG-29, k1 to k6.
- **Placing by hand works in Studio Play at A16** (D-463, D-464): look at the job box's top with
  a find from your box in hand, a faint breathing copy shows, Drop reads Place, one press sets it.
  The hand's aim now stops at the first thing the look hits (`PlaceAim.aim`'s `AimOptions`).
- **Studio:** `rojo serve` (port 34872) running and in sync; Studio left in Edit, place unsaved.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j5b1 A taken find keeps its spot, faintly, and snaps back into it
The moment: you take the lamp off the job box to carry it about; a faint lamp stays where it
stood; change your mind, look back at the job box, and the copy clicks into that very spot.
Precedent: The Sims' and Animal Crossing's picked-up furniture leaving its footprint to drop back.
1. Read the plan's "Placing by hand" section (docs tools) for the kept spot's look and rules.
2. Server: Take (`Arranging` `takeOut`) keeps the find's last pose with the hand (a per-slot mark
   beside `HandPlace.slotAttribute`, written by Slots, cleared when it's set down, put away or
   you leave your home). No save change unless the plan says so.
3. Screen: `HandPlaceView` draws the kept spot as a still faint copy (not breathing, fainter) and
   its aim snaps to it when the look lands within a step of it (a pure helper with a Lune spec).
   Built to extend: no find names; the spot is a pose, not an id rule.
4. Seen in Studio Play at A16 (STUDIO.md "Placing by hand in Play" has the setup and drags) and
   captured to `docs/art/s5-03j5b1-*` at half scale plus a close-up.
**Acceptance:** green; the spot shows after Take, snaps back, clears on set-down and on leaving;
the server refuses a stale spot as any far or bad ask.
**Read first:** DECISIONS D-463, D-464; `src/client/HandPlaceView.luau` 140-200 (seen, frame)
and 260-300 (start); `src/server/Arranging.luau` 600-650 (takeOut) and 520-533 (placeHeld);
`src/shared/Home/HandPlace.luau`; ROADMAP S5-03j5 (grep `j5b1`).

## Queue (next sessions, the owner's ticket order)
0. j5b2 next (a held finger opens Arrange lifted: `ArrangeView.new`'s `hold` opener exists for
   box pieces, `init.client.luau` 106). Polish by name: the place's squash, a drag's tilt.
   The huge held-find view at the bottom left hides the crates at phone size. Pallet and camp
   bed cards float back in the Small room (D-461). A tray card's drag isn't Gestures': the wheel
   zooms, no twist (D-453). Arrange's opening view: crates ~16 points across (D-449). D held
   slides the room half off screen. Hide the minimap's "You" sliver (D-447). Drop
   `ArrangeCamera.Room.slot`, `slotBox` (D-443); rename `BuildView.eyeBox` (D-444). Hand
   projections land 10 points low on a notch: use `lens` (D-446). `ToolView.luau` ~1293 reads
   the on-screen flag as "ahead" (D-451). Arrange reopens on the last tab. A blocked let-go may
   be judged blocked again (D-456). One lamp drag tocked three times (D-457).
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353).
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby place
   (D-352). A taken-out find comes out whole even when the save has it cracked.
3. The home's warm fill (D-290). Brix (in `../engine`): ENG-25b's two-client run; Driving's
   stick read (D-254); a PlayerSaves hook before a leaving save's last write.
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
