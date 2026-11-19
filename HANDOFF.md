# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-19, S5-03j5b2 done: hold a finger on your thing, Arrange opens with it lifted (D-466) · **Checks:** green · **Git:** `main`, not pushed; Brix `cea1259`.

## State
- **The owner's priority (D-436):** Arrange rebuilt as a room editor (S5-03j), then recipes
  (S5-03k). Plan: https://claude.ai/artifact/Q83TRkqn8gsM9t5r8n1ZQU (docs tools, your section
  only; search its heading). Order now: S5-03j6, j7, ENG-29, k1 to k6.
- **Placing by hand is whole** (S5-03j5, D-463 to D-466): a held find shows where you look and
  Place sets it; a Taken find keeps a faint spot it snaps back into; a finger held 0.45 s on one
  of your things (`HomeHoldView`) opens Arrange with it lifted under that finger
  (`ArrangeView`'s `grab`, `ArrangeHand.carryHeld`). All seen in Studio Play at A16, captured to
  `docs/art/s5-03j5b2-*` (`screen_capture` still times out; STUDIO.md's newest section).
- **Studio:** `rojo serve` (34872) in sync; Studio in Edit, place unsaved. Capture with macOS.
- **Climb run, on hold till S5-03j and k (Nov 18):** S5-01d's torch, S5-02b2c2, S4-06, S4-07, S5-04, S5-06.

## Next task: S5-03j6 Several at once
The moment: in Arrange you drag a box round the crate and the lamp on it and the rug; all three
light up selected; drag any one and they move together, turn together, put away together, and
the server takes them as one move (one undo). As The Sims 4's build-mode multi-select.
1. Read the plan's "Several at once" section and its feedback rows (the doc wins over ROADMAP).
2. Split it in ROADMAP first if it won't fit (likely: j6a the box drag and the selection's look on
   screen, a pure selection core with Lune specs; j6b moving, turning and putting away together;
   j6c the server's one move and one undo step). Do one green piece.
3. The box drag: which gesture starts it must not fight the camera's slide (Brix Gestures; ENG-27
   may need a new intent: if so, build it in `../engine` by Brix's AGENTS.md, then move the pin).
4. Each piece in its own module (a pure `Selection` core in `src/shared/Home/`); ArrangeView
   only wires. Names no find: what moves together is read from the placements and catalog rows.
5. The server: one ask carrying several moves, judged all or none (checked as Place is: type,
   range, ownership, reach, rate): a group never half-lands, and History keeps it as one step.
6. Feedback per the doc's table; seen in Studio Play at A16, captured to `docs/art/s5-03j6-*`.
**Acceptance:** green; a box round three things selects exactly those; they land as one; one Undo
puts all three back; a refused group changes nothing.
**Read first:** the plan's "Several at once"; ROADMAP S5-03j6 (grep `S5-03j6`);
`src/client/ArrangeHand.luau` 1330-1360 (`drop`) and 1509-1560 (`replay`);
`src/shared/Home/History.luau` 1-60; `src/server/Arranging.luau` 820-850 (its remotes);
`vendor/brix/docs/modules/Gestures.md`.

## Queue (next sessions, the owner's ticket order)
0. After j6: j7. Polish by name: the place's squash, a drag's tilt. The huge held-find view at
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
