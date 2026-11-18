# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03h6 (D-356) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03h6 done (D-356): a home that grows grinds its walls back. The server still snaps
  (`Walls.size`); a grow goes through Arranging's `regrow` (size kept through the re-lay, moved
  pieces stamped `GrewFrom`, the unit `GrewFrom`/`GrewAt`). `HomeGrowView` plays 2.6 s over it:
  walls, doorway, lamp, paint (`Walls.place` at `Sizes.between`), moved pieces shifted; grind,
  thumps, shake, dust. The holder's home holds the old size until they're next inside. **Seen
  in Studio Play at A16**: Small to Medium from inside (captures `docs/art/S5-03h6-*.jpg`).
  Not yet seen: Medium to Large, Large to XL, the hold, the dust at phone size; not heard.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size" (now grows the counter's way; STUDIO.md "Watching a home grow"). Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium.
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), and S4-03 the
  next-floor cards, all four versions picked on rides and seen in Play (D-403 to D-413). Next:
  S4-05 The big find (not yet planned: split it in ROADMAP first, its art the finds' way, then
  the climb; Lethal Company's heavy scrap).

## Next task: S5-03g3c Choosing a name card's style (and h6's other grows seen)
The moment: on the paint tab you flick through the name card's styles and your door's card
swaps to the one you pick; the ones you don't own yet sit there with a small coin or Robux mark,
waiting for the counter (Animal Crossing's catalogue; ROADMAP S5-03g3c).
1. First, see h6's rest in one Studio Play at A16 (STUDIO.md "Watching a home grow"): from inside,
   Medium to Large and Large to XL (walls hidden at the end, nothing flickers); then Small, walk
   out, "Medium", walk back in (it grows round you). Fix what's off; capture
   `docs/art/S5-03h6-*.jpg`.
2. The paint tab (`LooksTab`) gets a row of the card's styles (`Specs.Cards`), each a chip with
   its look; Starter styles pick at once through the existing look remote (the server's
   `Looks` checks); Cash and Robux ones show a small coin or Robux mark, and a tap does nothing
   until owned (no popup, no words).
3. Picking answers: the chip's press, the plate over your door swapping; specs for new rules.
4. See it in Studio Play at A16: pick each Starter style, tap a locked one; capture
   `docs/art/S5-03g3c-*.jpg`.
**Acceptance:** a Starter style picked from the tab shows over the door; a locked one can't be;
check green; OWNER.md line; Next task then S5-03d4 (the conductor clears it with the climb chain).
**Read first:** ROADMAP S5-03g3c; D-322, D-328, D-331; `src/client/LooksTab.luau`;
`src/shared/Home/Looks.luau`; STUDIO.md "Watching a home grow".

## Queue (next sessions, the owner's ticket order)
1. S5-03d4 after g3c; S5-03a2d the cars' triangles. Small's doorway's inside boards
   are oak, not the picked paint (D-355, my call). Sitting's leftovers (D-353): cross-legged on the blanket needs an animation of our
   own (script joint writes lose to a seated body's Animator, STUDIO.md); lying on the bed.
2. A lamp left on at home kept through a rejoin or a re-lay (D-351: the stamp is the model's); a
   lit find taken comes into your hand unlit; the shelf's cubby finds' own buttons. A friend's
   take: the real find shows in their hand before the flying copy lands. The steel shelf's lower
   tiers. In Arrange the job box's "Open" shows over the room. A lifted lit piece's light stays
   where it was until it's set down. The looks' polish (g2b2, g2b3, g3b). A grow while Arrange is
   open now closes it (D-356); rebuilding it in place instead is polish. Units: plans small; Robux
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
