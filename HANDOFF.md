# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j6b2a done: a lit group carried, turned, put away, undone on the screen (D-469) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j6b2b, j7 (its ROADMAP line holds the conductor's
  five capture notes), ENG-29, k1 to k6.
- **The group's screen is built, unseen** (S5-03j6b2a, D-469): `ArrangeGroup` (a drag on a lit
  thing lifts one ghost per root into one Highlighted model, slides on the floor by the grid,
  judged by `Group.apply` tried and undone on the room's judge; lands heaviest first, a thud
  each; Turn and Put away from the ring; `replay` for undo). `ArrangeBox.dim`,
  `ArrangeUndo.recordGroup`. In Studio Play the client loads it clean; nothing driven yet.
- **Studio:** `rojo serve` in sync; Edit, unsaved; Play spawns you outside home (STUDIO.md).
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j6b2b Several at once, seen in Studio
The moment: three things lit by the box; you drag the crate and the lamp and rug come along; let
go and all three land, thud by weight, as one move; one Undo puts all three back. As The Sims 4.
1. In Play at A16 (Medium home, STUDIO.md "Getting into Arrange in Play"), set out three finds
   near each other (`ArrangeTest` "place"), open Arrange, box them with a held drag on bare floor
   (`CameraTest` "drag" from the floor), and capture the ring round the group.
2. Drag one lit thing (`CameraTest` "drag" starting on it): capture mid-drag green, then pushed
   into a wall or the job box (red), then the landing. Check on the server (`ArrangeTest` "rows")
   that all three moved as one ask, and that a refused drop changed nothing.
3. The ring's Turn (and its refusal), Put away (each flies to its card), then Undo and Redo of
   both. Capture each to `docs/art/s5-03j6b2b-*` at half scale; look at them.
4. Fix what's seen (the ring hugging the right box, the tray out of the way while carried, the
   ghost offsets, a stuck "busy" after a timeout). Polish by name stays in ROADMAP.
**Acceptance:** green; seen in Studio Play: a boxed three land as one ask; one Undo puts all three
back; a refused group changes nothing on the server or the screen.
**Read first:** `src/client/ArrangeGroup.luau` (whole, 936 lines; or by function); D-469;
`docs/STUDIO.md` "Arrange's build camera, first try in Play" (its CameraTest and ArrangeTest
lines); `src/client/ArrangeView.luau` 410-500 (the group's wiring).

## Queue (next sessions, the owner's ticket order)
0. After j6b2b: j7. The box's glow is faint from the opening view (D-467). Polish by name: the place's squash, a drag's tilt. The huge held-find view at
   the bottom left hides the crates at phone size. Pallet and camp bed cards float back in the
   Small room (D-461). A tray card's drag isn't Gestures': the wheel zooms, no twist (D-453).
   Arrange's opening view: crates ~16 points across (D-449). D held slides the room half off
   screen. Hide the minimap's "You" sliver (D-447). Drop `ArrangeCamera.Room.slot`, `slotBox`
   (D-443); rename `BuildView.eyeBox` (D-444). Hand projections land 10 points low on a notch:
   use `lens` (D-446). `ToolView.luau` ~1293 reads the on-screen flag as "ahead" (D-451).
   Arrange reopens on the last tab. A blocked let-go may be judged blocked again (D-456). One
   lamp drag tocked three times (D-457). While a find is held at home, the crate's Sit and the job box's Open sit over its kept spot and hide it (D-466): those buttons should step aside near the aim. A cubby find can't be held to open Arrange yet (D-466).
   After S5-03j and k: S5-03g2b's three "Polish:" lines (D-326 to D-328), then g3b.
1. Small's doorway's inside boards are oak, not the picked paint (D-355). Sitting (D-353).
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; a lifted lit piece's light; a grow while Arrange is open closes it (D-356);
   Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused cubby place
   (D-352). A cracked taken-out find comes out whole. A cubby Take keeps no spot (D-465).
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
