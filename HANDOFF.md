# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i1c1 (D-348) · **Checks:** green · **Git:** `main`, not pushed;
Brix `7f25310`. Uncommitted FloorBuilder, NextFloor(s), nextfloor.spec: the climb run's.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i). i1a
  (rules), i1b (the server lays them) and i1c1 (lift them in Arrange, D-348) done; i1c2 next.
- i1c1, seen in Studio Play at Galaxy A16 size on the XL test save (captures
  `docs/art/S5-03i1c-*`): i1b's laying held (the old set adopted where it stood, six finds in
  the shelf, the mirror reflecting); in Arrange the shelf lifted with its finds from mid-room to
  the back wall (red at the middle, where the camp bed reaches in; green a step left), the
  mirror carried to the left wall turned and leant by itself (Turn hidden), the job box moved
  with no Put away, the lamp moved; the box's Open, the mirror's Try on followed; "relay" laid
  all four where they were left. The lid swung about the moved box's hinge (88 degrees).
- Found and fixed after the pass, unseen: the box pushed flush put its open lid in the wall; now
  it stops `BoxOff` (0.8) off any wall (`Layout.clearOf`; the server refuses nearer, "wall").
- Test save: XL; the job box saved FLUSH at (8.75, 1.5, 90), from before the fix. Hooks:
  `ArrangeTest` "rows", "relay", "size". Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), S4-03a the next-floor
  vote (`NextFloor`, `NextFloors`, floors dealt after the vote; D-403, untested in Studio).
  Next: S4-03b the cards on the car's panel (ride floor 1 to 2 in Play first: Output's "picked";
  read the car's `NextFloorOffer`/`Presses`/`Picked`, press `NextFloorPress`).
  Uncommitted `ArrangeView`, `Home/*` and `layout.spec` are the home chain's work in progress.

## Next task: S5-03i1c2 The moves hold through a rejoin and a resize, seen in Studio
The moment: you rejoin and your shelf is on the back wall where you put it; your home grows and
the mirror rides its wall out, still leaning; the box by the door opens clear of the wall.
1. Studio Play (`list_roblox_studios`; one Play at a time; the A16 set in Edit first, see
   STUDIO.md's last section; stop after). In Arrange lift the flush job box and push it at the
   left wall: it stops at its line (green), Place; set its `Lid` to 1 from the server and
   capture it open clear of the wall.
2. Move the clothes rail (its hangers and Wear ride it; press Wear after); put the rug away and
   set it out again (the beanbag on it goes in the box first, D-338 riders).
3. A true Stop and Play: everything where it was left, finds in the shelf. Then "size" Small:
   what rides its wall stays against it, what doesn't fit goes in the box; "size" XL back.
4. Captures `docs/art/S5-03i1c2-*.jpg` (after the rejoin, Small, the open box). Fix what's off;
   then, with room, carry on into S5-03i2.
**Acceptance:** check green; each step seen in Studio with a capture or an Output line.
**Read first:** D-348; `src/client/ArrangeView.luau` (settle, fitsAt, awayNow);
`src/shared/Home/Layout.luau` (grow, leanTo, clearOf); `src/server/Rails.luau` (lay);
STUDIO.md's "Arrange on the A16, lifting a home's own pieces".

## Queue (next sessions, the owner's ticket order)
1. S5-03i2 take anything, i3 every find's button, i4 sit
   (D-345); then S5-03h5, h6; S5-03g3c a card's style; S5-03d4; S5-03a2d the cars' triangles.
2. The steel shelf's lower tiers. In Arrange the job box's "Open" shows over the room. A lifted
   lit piece's light stays where it was until it's set down. The looks' polish (g2b2, g2b3,
   g3b). A size change while Arrange is open doesn't rebuild the screen's judge (h6 should).
   Units: plans small; Robux cards unseen. A gift buyer's `bought` counts only a spare's gift
   (D-343); the Gift cards unseen (D-344). Arrange's limit bar hides the back wall in an XL
   home. A box lid opening into a piece behind it (only walls are kept clear). The test save's
   camp bed reaches 1.9 past the back wall (its row from before the walls held it).
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277,
   D-297, D-299 to D-302, D-304, D-305, D-308, D-309, D-311 to D-348.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
