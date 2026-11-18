# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i1c2 (D-349) · **Checks:** green · **Git:** `main`, not pushed;
Brix `7f25310`. Uncommitted NextFloor, NextFloorCards and their specs: the climb run's.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i). i1
  is done: the starter pieces are rows, lifted and moved in Arrange (D-346 to D-348), and held
  through a rejoin and a resize (i1c2, D-349, captures `docs/art/S5-03i1c2-*`). i2a next.
- i1c2, seen at A16 size: the job box stopped at its line and opened clear; the rail moved
  with its hangers and Wear; the rug went away with its beanbag and back; a true rejoin held.
- Found and fixed: made Small, the whole set went in the box, the job box too. Now a shrunk
  home takes its size's layout first (`Layout.grow`) and a save without its job box gets it
  back (`Layout.withBox`); XL to Small to XL seen, the shelf back centred with its finds.
- Test save: XL, everything set out, six finds in the shelf, the hard hat worn. Hooks:
  `ArrangeTest` "place", "putAway", "rows", "relay", "size" (STUDIO.md's last section). Home
  doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), S4-03a the vote (D-403),
  S4-03b1 the faces (D-404), S4-03b2 the cards on screen (D-405, seen on the A16: press, heads,
  change of mind, the winner lit). Next: S4-03c each version felt on its floor (ROADMAP's c
  lines); S4-03d first sees the flare, the car change and the bigger coin strip.

## Next task: S5-03i2a Take a find from where it stands
The moment: you walk up to the teddy in your shelf, press Take, and it hops into your hand with
its pick-up sound, as a find on a climb does; the cubby is empty and the box's count is right.
1. Failing Lune spec first: a pure take (in `Save`, say `Save.unshelf(data, i, name)`, and a
   placed row's removal with its riders boxed, as Arranging's `putAway` does): owned counts
   unchanged, `Save.boxed` one more of it so `Slots:unbox` can carry it, refused for a spot not
   holding that name. Then wire it.
2. Server: a Take button (`Prompts.make`, as Coins' Take) on each cubby find (Shelves) and each
   find set out (Arranging's drawn finds, not furniture), holder only (HomeCards hides others').
   On a press: rate limit, your own home, reach, not wrapped, a free slot (else ignore the
   press), then free the spot or row and `Slots:unbox` in the same step (give `unbox` a flag
   so the pick-up sound plays), re-lay the shelf or redraw.
3. Client: the copy hops into your hand (BatteryView's flight on a `TakenBy` stamp) and the
   hand shows it; nothing snaps.
4. Studio Play at A16 size: Take a cubby find, a find on a top and one on the floor; rejoin:
   none doubled or lost (rows and the box's count). Capture `docs/art/S5-03i2a-*.jpg`.
**Acceptance:** check green; the spec fails before the fix; each Take seen in Studio.
**Read first:** D-345 and D-293; `src/server/JobBoxes.luau` 215-280 (the take checks);
`src/server/Slots.luau` `unbox`/`fromBox` (about 1993); `src/shared/Save.luau` 200-290;
`src/server/Arranging.luau` `putAway` (452); `src/server/Shelves.luau`'s header.

## Queue (next sessions, the owner's ticket order)
1. S5-03i2b lift a find out of the shelf in Arrange, i3 every find's button, i4 sit
   (D-345); then S5-03h5, h6; S5-03g3c a card's style; S5-03d4; S5-03a2d the cars' triangles.
2. The steel shelf's lower tiers. In Arrange the job box's "Open" shows over the room. A lifted
   lit piece's light stays where it was until it's set down. The looks' polish (g2b2, g2b3,
   g3b). A size change while Arrange is open doesn't rebuild the screen's judge (h6 should).
   Units: plans small; Robux cards unseen. A gift buyer's `bought` counts only a spare's gift
   (D-343); the Gift cards unseen (D-344). Arrange's limit bar hides the back wall in an XL
   home. A box lid opening into a piece behind it (only walls are kept clear). In Arrange the
   unit door's Close, Slam and Switch show over the room when you stood by the door.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277,
   D-297, D-299 to D-302, D-304, D-305, D-308, D-309, D-311 to D-349.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
