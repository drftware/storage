# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i2a2 and S5-03i3 (D-351) · **Checks:** green in the shared checkout
(the climb run's uncommitted files included) · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i). i1,
  i2a and i3 are done; i2b (lift a find out of the shelf in Arrange) and i4 (sit) are left.
- i3, seen in Studio Play at A16 size: every find set out has its own button beside Take, the
  climb's word from its `Finds/Use` row (`Home.Press`, HomeUses, HomeUseView, FindUses'
  `setOut`); anyone inside the home may press; a light pressed at home never runs down. The
  moon lamp on a folding table switched on (`docs/art/S5-03i3-*`).
- i2a2: a real Take press lifted the boombox into your hand, after a fix to HomeTakeView (D-351).
- Not yet seen: a cubby take by a real press, the flight frame by frame, a rejoin's counts
  (OWNER.md). Test save: the moon lamp on a folding table, the monkey and teeth on the floor.
- Uncommitted on purpose: the climb run's work in progress (at this writing CoinView, GatePay,
  NextFloor, Pay, `tests/pay.spec`); the home chain never stages them.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows" (STUDIO.md).
  Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the next-floor cards'
  vote, faces and screen (D-403 to D-405), S4-03c1 the deal and pay read the pick (D-406, seen in
  Play). Next: S4-03c2 the arrival and the version's own coin pop (ROADMAP's c2 line), then c3
  the power out, c4 caught to the lobby; S4-03d sees the flare, car change and coin strip.

## Next task: S5-03i2b Lift a find out of the shelf in Arrange
The moment: in Arrange you tap the teddy in a cubby and it lifts off the shelf (not the shelf
itself), you set it on the folding table, and the cubby is empty; tap the shelf's boards and the
whole shelf still lifts.
1. Read how ArrangeView picks what a tap lifts (grep `pick` in `src/client/ArrangeView.luau`) and
   how Shelves draws a cubby find (`Shelf.Tag`, `Shelf.SpotAttribute`).
2. Pure first (a spec in `tests/homepick.spec` or a new one): a tap on a cubby find picks the find;
   the server moves it from the shelf spot to a placed row in one step (`Save.unshelf` then
   `Spots`'s place), never lost or doubled; a refused place leaves it in its cubby.
3. Server: a remote or an extra `Place` form for "from cubby i" (validate: type, range, your own
   shelf, the cubby still holds that find), rate-limited as Place is.
4. Client: the lifted cubby find flies as a lifted find does; Put away sends it to the box.
5. See it in Studio Play at A16 size; capture `docs/art/S5-03i2b-*.jpg`.
**Acceptance:** spec green; a cubby find set on a top in Studio; check green; OWNER.md line;
then S5-03i4 (sit) if room.
**Read first:** D-345, D-351; `src/client/ArrangeView.luau` (its pick); `src/server/Shelves.luau`
(`take`); `src/server/Arranging.luau` (`place`); `tests/hometake.spec.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03i4 sit (D-345); then S5-03h5, h6; S5-03g3c; S5-03d4; S5-03a2d the cars' triangles.
2. A lamp left on at home kept through a rejoin or a re-lay (D-351: the stamp is the model's); a
   lit find taken comes into your hand unlit; the shelf's cubby finds' own buttons. A friend's
   take: the real find shows in their hand before the flying copy lands. The steel shelf's lower
   tiers. In Arrange the job box's "Open" shows over the room. A lifted lit piece's light stays
   where it was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while
   Arrange is open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux
   cards unseen. Gift cards unseen (D-343, D-344). Arrange's limit bar hides the back wall in an
   XL home. A box lid opening into a piece behind it. In Arrange the unit door's buttons show.
   Take reaches through a wall (Takes.near has no in-home check, as Press has).
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
