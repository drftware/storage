# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i2b (D-352) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i). i1,
  i2 and i3 are done; i4 (sit on the furniture) is left, then S5-03h5.
- i2b, seen in Studio Play at A16 size: in Arrange a tap on a cubby's find lifts it, growing out
  of its cubby (`Shelf.hit` tests its box: cubby finds can't be raycast); Place set the teddy on
  the folding table, Put away sent the boombox to the box (`Spots.offShelf`, Place/PutAway carry
  the spot); a tap on the boards still lifts the shelf (`docs/art/S5-03i2b-*`).
- Test save: teddy and moon lamp on the folding table; cubbies 2 and 4 empty.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway" (STUDIO.md). Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the cards' vote,
  faces and screen (D-403 to D-405), c1 to c3 (D-406 to D-408), c4a down the shaft to the lobby
  car (D-409, the fall seen in Play; Trips' `mayStand` now skips `SentDownAt`). Next: S4-03c4b
  friends see you taken (the body dragged down in red), and a real catch there seen; then S4-03d.

## Next task: S5-03i4 Sit on the furniture
The moment: you walk up to the milk crate in your home and sit on it, the beanbag sinks you in,
you sit cross-legged on the blanket by the pallet, and you lie back on the camp bed; a friend
sits beside you (D-345; Bloxburg's and Adopt Me's furniture you sit on).
1. Read how `Home.piece` adds Seats (`Home.Seats`, src/shared/Home/init.luau ~207 and ~405) and
   which pieces Arranging draws with it (the beanbag already has one).
2. Pure first (`tests/homefurniture.spec` or a new spec): a seat row for MilkCrate, Blanket and
   CampBed (two along the bed) from `Home.Specs.Tops` heights, each inside its piece's box,
   facing out its front.
3. Draw them: every drawn piece gets its seats, a moved piece's seats move with it; none while
   it's lifted in Arrange (the ghost is inert), and Arrange open never sits you.
4. Feel: a soft sit sound (a cushion's thump; the crate a wood knock), the camera easing, and
   standing up by jumping as Roblox does. Lie on the bed if a Roblox Seat allows it (a sleeping
   pose is an untested bet: `OWNER.md`, else sit).
5. Sit on each in Studio Play at A16 size; capture `docs/art/S5-03i4-*.jpg`.
**Acceptance:** spec green; sat on each in Studio; check green; OWNER.md line; then the Next
task is S5-03h5 (the walls drawn by size).
**Read first:** D-345; `src/shared/Home/init.luau` (Seats, `piece`); `src/server/Arranging.luau`
(`drawPiece`); `src/shared/Home/Furniture.luau` (rows); DECISIONS' S5-03g4 tops note
(`Home.Specs.Tops`); `tests/homefurniture.spec.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03h5, h6 (once i4 is done, the Next task is S5-03h5, the walls drawn by size); S5-03g3c;
   S5-03d4; S5-03a2d the cars' triangles.
2. A lamp left on at home kept through a rejoin or a re-lay (D-351: the stamp is the model's); a
   lit find taken comes into your hand unlit; the shelf's cubby finds' own buttons. A friend's
   take: the real find shows in their hand before the flying copy lands. The steel shelf's lower
   tiers. In Arrange the job box's "Open" shows over the room. A lifted lit piece's light stays
   where it was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while
   Arrange is open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux
   cards unseen. Gift cards unseen (D-343, D-344). Arrange's limit bar hides the back wall in an
   XL home. A box lid opening into a piece behind it. In Arrange the unit door's buttons show.
   Take reaches through a wall (Takes.near has no in-home check, as Press has). A refused place
   out of a cubby sliding back in, shrinking, not yet seen (D-352).
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277,
   D-297, D-299 to D-302, D-304, D-305, D-308, D-309, D-311 to D-351.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
