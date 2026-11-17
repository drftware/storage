# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 271 (S5-03g3a1, the door's colour saved, painted and rolled) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). A door's colour is saved (`looks.door`, save version
  10), picked through `PickLook` ("door"), and rolls down the slats on every screen (D-329), seen
  in Play on the A16 simulator from the hall. There's no button for it yet: that's the Next task.
- Rojo is connected: Studio's scripts are the working tree's. The A16 is set from the shell
  (STUDIO.md, "Picking the A16 from the shell"); if taps time out, `caffeinate -u -t 3`.
- Test save: cash 478, HardHat on the rail, Green worn; Unit1 (frame at 60, 0, 478) in Sage,
  Daisies and a Rose carpet, its door Rose. Its door opens when you arrive.
- Stage only your own paths (the find run's `art/finds/`, `src/shared/Finds/` and hunks stay).

## Next task: S5-03g3a2 Your front, a third tab
The moment: on Arrange you tap the little door tab, the camera swings round to face your door, and
a tap on Mustard rolls it mustard from the top down with a squish. Bloxburg's build mode tabs.
1. Read ArrangeView's tabs (`showTab`, the `for i = 1, 2` tab loop near line 1563, `view`,
   `openNow`) and LooksTab's `row`, `chip`, `refresh`, `attach`.
2. LooksTab: a page argument ("room" or "front"); the front page is one row of the eight door
   dots (`Specs.Looks.Doors`), ringed from the unit's `Looks.DoorAttribute` (watch it too);
   `current` learns "door". Its height `ROW + PAD * 2` (66). Leave room for g3c's second row.
3. ArrangeView: three tabs (finds, room, front); `onLooks` becomes a tab number; the front tab's
   icon a small roll-up door (a rounded frame with three slat lines) in clay.
4. The camera: on the front tab it eases (RISE) to face the door from inside (from about a third
   of the room back, a little over head height, looking at the doorway's head so the coil shows
   when open), and back to `view(r)` on the other tabs. Lifting a find stays as it is.
5. Play on the A16 (see STUDIO.md: an execute_luau's Scriptable camera is reset after the call):
   open Arrange, the front tab, tap two colours with the door shut and open; walk out and judge
   it from across the floor. Capture to `docs/art/`.
**Acceptance:** check green; three tabs fit the tray's top edge; the front tray is one row; the
camera turns to the door and back with no snap; the door rolls on a tap and the ring moves; no
text.
**Read first:** ROADMAP S5-03g3a2; D-329; `src/client/LooksTab.luau`; `src/client/ArrangeView.luau`
(lines 1040-1060, 1170-1290, 1540-1615); `src/shared/Home/Looks.luau` (top 90 lines).

## Queue (next sessions, the owner's ticket order)
1. S5-03g3b name card plates, g3c choosing a card's style (the front tab's second row; the store's
   rules: not-owned marked, never a popup), g4 (furniture at the counter, the glows near only;
   neon's light budget on the A16), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars'
   hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2 and g2b3): the sheet a shade darker than the panel at the
   hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's wipe
   half under the looks tray.
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-329.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
9. Share one `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`).
10. The HUD coin count read 0 in Play again (Nov 17, four times) with the save's cash at 478.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
