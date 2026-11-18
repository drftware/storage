# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03h5b (D-355) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03h5 done: h5a's movable walls (D-354) and h5b's narrower Small doorway (D-355) both **seen
  in Studio Play at A16 size**: all four sizes' walls, corners and lamp, the door counting you in
  by Small's room, Small's doorway from the hall, close and inside, Medium's wider. Captures
  `docs/art/S5-03h5a-*.jpg`, `S5-03h5b-*.jpg`. Home.fbx re-uploaded (same asset), the place's
  `Props.Home` template replaced in Edit (Casing split; CasingLeft/Right, CasingHead, FillLeft/
  Right slide by `Walls.doorway`). Test save: XL, though the last size pass left it at Medium.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size" (STUDIO.md). Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the cards' vote,
  faces and screen (D-403 to D-405), c1 to c3 (D-406 to D-408), c4a to c4c caught there: down
  the shaft, friends see you dragged under, the lobby car waits open and humming, its dial on
  the team's floor (D-409 to D-411). Next: S4-03d (ride floors 1 to 5 with the cards in Play).

## Next task: S5-03h6 The walls grind back (idea 31)
The moment: you grow your home while you're in it and watch: the partitions slide out along the
floor, the back wall rolls away, Small's doorway widens, dust drifts down from the wall tops, the
steel grinds and clunks home, and everything you set out stays where it was (Animal Crossing's
house growing; ROADMAP S5-03h6).
1. Pure first (`Sizes`, `tests/walls.spec`): the walls' and doorway's place part way between two
   sizes (insets lerped; `onWall` from insets), eased; spec tests.
2. A client view (new, e.g. `HomeGrowView`): on a home's `HomeSize` change, if it's streamed in
   and you're near, play ~2.5 s over the server's snap: each wall model `PivotTo` the blend, the
   doorway by `Walls.doorway(unit, frame, inset)` (takes any inset), the lamp; pieces that rode a
   wall (the shelf on the back wall) glide from their old pivot to the new (match by name).
3. Feedback in the same ticket: the steel's grind looped under the slide (pitch with speed), a
   clunk at the end, a small camera shake, a few dust puffs falling from each moving wall's top
   (phone-cheap: one emitter per wall, a short burst). No words.
4. Arrange open during a grow re-measures its inside box (queued, h6 should).
5. See it in Studio Play at A16: Small to Medium (doorway widens), to Large, to XL (walls away at
   the end); capture mid-grind `docs/art/S5-03h6-*.jpg`.
**Acceptance:** seen growing at each step; nothing flickers; check green; OWNER.md line; Next task
then S5-03g3c (choosing a name card's style).
**Read first:** ROADMAP S5-03h6; D-354, D-355; `src/shared/Home/Walls.luau`; `Sizes.luau`; the
home doc's idea 31 (docs tools, by heading); STUDIO.md "Seeing a home at every size in one pass".

## Queue (next sessions, the owner's ticket order)
1. S5-03g3c after h6; S5-03d4; S5-03a2d the cars' triangles. Small's doorway's inside boards
   are oak, not the picked paint (D-355, my call). Sitting's leftovers (D-353): cross-legged on the blanket needs an animation of our
   own (script joint writes lose to a seated body's Animator, STUDIO.md); lying on the bed.
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
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 355.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
