# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03h5a (D-354) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03h5 split: h5a done (commit 8134bb2), h5b next, then h6. A smaller home now stands inside
  three movable walls (`Home.Walls`: steel slab under a clone of its own panel, XL-long, slid by
  `Sizes.onWall`); the ceiling lamp, Arrange's fixed lamp and button box, the door's count
  (`RoomWidth`/`RoomDepth`), the lights' room and the look's wipe all read `HomeSize` (Small for a
  spare). **Passes checks, untested in Studio**: Studio was in another session's Play throughout.
- Test save (XL): crate, blanket, camp bed, beanbag on the rug; teddy, moon lamp on the table.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size" (STUDIO.md). Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the cards' vote,
  faces and screen (D-403 to D-405), c1 to c3 (D-406 to D-408), c4a down the shaft to the lobby
  car (D-409, the fall seen in Play; Trips' `mayStand` now skips `SentDownAt`). Next: S4-03c4b
  friends see you taken (the body dragged down in red), and a real catch there seen; then S4-03d.

## Next task: S5-03h5b Small's narrower doorway (after seeing h5a)
The moment: your first unit is snug, a Small home with a doorway to match; grow it to Medium and
the door is plainly wider (ROADMAP S5-03h5b; Animal Crossing's house rooms by size).
1. See h5a first, in Studio Play at A16 size (`ArrangeTest` "size": Small, Medium, Large, XL): the
   walls at each size, corners closed, the lamp over the middle, the door shut with you inside,
   Arrange only inside the walls; capture `docs/art/S5-03h5a-*.jpg`; fix what's off. Check a Steel
   slab's and a Face's real Size and frame (`Walls.lay` assumes the panel's thickness is Size.Z).
2. Art first (`art/home/front.py`): a Small front round the S door's 6-wide opening in the same
   wall: plaster and oak casing fill the M's sides, lining back to the curtain's slot, the M
   curtain rolling behind them; separate parts so h6 can slide them apart; rebuild with
   `scripts/art.sh home`, upload (`scripts/upload_art.luau`), insert, look sheets at phone size.
3. Wire it: `Walls.size` shows the Small front at Small, the M's at Medium and up.
4. See Small and Medium in Studio Play at A16 size; capture `docs/art/S5-03h5b-*.jpg`.
**Acceptance:** h5a seen at all four sizes; the Small doorway seen; check green; OWNER.md line;
then the Next task is S5-03h6 (the walls grind back, sound and motion, dust), then S5-03g3c.
**Read first:** ROADMAP S5-03h5 to h6; DECISIONS D-354, D-266 (the home front);
`src/shared/Home/Walls.luau`; `art/home/front.py`; `art/unit/spec.py` (SIZES); STUDIO.md "Home
1's room".

## Queue (next sessions, the owner's ticket order)
1. S5-03h6 (the walls grind back) after h5b; S5-03g3c; S5-03d4; S5-03a2d the cars'
   triangles. Sitting's leftovers (D-353): cross-legged on the blanket needs an animation of our
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
