# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i4 (D-353) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works. S5-03i is done: i1 to
  i4. i4, seen in Studio Play at A16 size: Sit shows over the crate, the beanbag, the blanket and
  the camp bed's two places (`Sits`, `HomeSitView`, `Home.Sit`; R/ButtonB, anyone in the home);
  a real R press sat you on the crate and the blanket, Space stood you up, the view glided in
  (`docs/art/S5-03i4-*`). Not built: cross-legged on the blanket (queued).
- Test save (XL): crate, blanket, camp bed, beanbag on the rug; teddy, moon lamp on the table.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size" (STUDIO.md). Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the cards' vote,
  faces and screen (D-403 to D-405), c1 to c3 (D-406 to D-408), c4a down the shaft to the lobby
  car (D-409, the fall seen in Play; Trips' `mayStand` now skips `SentDownAt`). Next: S4-03c4b
  friends see you taken (the body dragged down in red), and a real catch there seen; then S4-03d.

## Next task: S5-03h5 The walls drawn by size
The moment: you buy your first unit and it's snug, a Small home that looks small, the walls close
round you; grow it to Medium and the room is plainly bigger, the door wider (ROADMAP S5-03h5;
Animal Crossing's house rooms by size). Split it in ROADMAP first if it won't fit one session.
1. Read how a home's size is kept and laid now (`Home.Sizes`, `Arranging`'s `lay`, the room the
   door counts you in by, `HomeUses.room`) and what the art has per size (`art/home/home_spec.py`).
2. Art first, the unit's way: the partitions and the back wall where each size ends (the unit
   kit's steel, the home's panels following, D-325) and the door frame per size (Small's doorway
   narrower than the M door); rebuild with `scripts/art.sh home`; look sheets at phone size.
3. Pure first (a spec): each size's room box from the art (width, depth, the door's span), the
   room the door counts you in by and Arrange's inside box from it.
4. Wire it: a home lays its walls and door frame for its size; Press's room, Arrange's box and
   the door's count all read the same box.
5. See each size in Studio Play at A16 size (`ArrangeTest` "size"): Small, Medium, Large, XL;
   capture `docs/art/S5-03h5-*.jpg`.
**Acceptance:** spec green; each size seen in Studio; check green; OWNER.md line; then the Next
task is S5-03h6 (the walls grind back).
**Read first:** ROADMAP S5-03h5 and h6; DECISIONS D-325 and D-346 (layouts by size);
`src/shared/Home/Sizes.luau`; `art/home/home_spec.py` (sizes); `src/server/Arranging.luau`
(`lay`); STUDIO.md "Home 1's room".

## Queue (next sessions, the owner's ticket order)
1. S5-03h6 (the walls grind back) once h5 is done; S5-03g3c; S5-03d4; S5-03a2d the cars'
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
