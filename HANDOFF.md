# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03i2a1 (D-350) · **Checks:** green (in a throwaway worktree: the
climb run's uncommitted Climbs, Keepers, GatePay, Deal, Pay, Waking are red mid-work) · **Git:**
`main`, not pushed; Brix `7f25310`.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works (ROADMAP S5-03i). i1
  is done (D-346 to D-349). i2a1 is built: take a find straight from where it stands (D-350).
- i2a1, built and green, NOT seen in Studio (Studio was in another session's Play): every find
  in a cubby and every find set out has a Take button (`Takes`), shown only to its holder and
  hidden in Arrange (HomeTakeView). A press: rate limit, your own, reach, not wrapped, a hand
  free (`Slots:room`), then stamp `TakenBy`, `Save.unshelf` or `Spots.lift`, `Slots:unbox`, one
  step. Every screen flies a copy into the hand; your hand is held by InFlight until it lands.
- Uncommitted on purpose: Climbs, GatePay, Keepers, Deal, Pay, Waking and
  `tests/floorversion.spec` are the climb run's work in progress; the home chain never stages them.
- Studio hooks: `ShelfTest:Invoke(player, "take", i)`, `ArrangeTest:Invoke(player, "take", id)`
  (STUDIO.md's i1c1 section). Test save: XL, everything set out, six finds in the shelf, the
  hard hat worn. Home doc: https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), the next-floor cards'
  vote, faces and screen (D-403 to D-405), S4-03c1 the deal and pay read the pick (D-406, seen in
  Play). Next: S4-03c2 the arrival and the version's own coin pop (ROADMAP's c2 line), then c3
  the power out, c4 caught to the lobby; S4-03d sees the flare, car change and coin strip.

## Next task: S5-03i2a2 See the take in Studio Play at Galaxy A16 size
The moment: you walk up to the teddy in your shelf, press Take, and it hops into your hand with
its pick-up sound; the cubby is empty and the box's count is right.
1. `get_studio_state` first; wait while another session is in Play. Play with the A16 device.
2. Walk to the shelf; the Take shows over a cubby find (and not on a friend's screen, if a
   second client is cheap). Press E: watch the hop and flight, hear the pick-up, see the hand.
3. Take a find on the job box's top and one on the floor (set one out in Arrange first if the
   test save has none). Hands full (three slots): the press does nothing.
4. `ArrangeTest "rows"` before and after each: the box's count and the rows right. Stop and
   Play: none doubled or lost. Fix what's wrong (spec first for pure code).
5. Capture `docs/art/S5-03i2a-1-cubby.jpg`, `-2-flight.jpg`, `-3-in-hand.jpg`.
**Acceptance:** each Take seen in Studio; check green; the OWNER.md line says what was seen.
Then carry on into S5-03i2b if room.
**Read first:** D-350; `src/client/HomeTakeView.luau`; `src/server/Takes.luau`; Shelves' `take`
and Arranging's `takeOut` (grep); STUDIO.md's i1c1 section (the A16 crop, the hooks).

## Queue (next sessions, the owner's ticket order)
1. S5-03i2b lift a find out of the shelf in Arrange, i3 every find's button, i4 sit
   (D-345); then S5-03h5, h6; S5-03g3c a card's style; S5-03d4; S5-03a2d the cars' triangles.
2. A friend's take: the real find shows in their hand before the flying copy lands (MachineVend
   holds a friend's hand; HomeTakeView only holds yours). The steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room. A lifted lit piece's light stays where it
   was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while Arrange is
   open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux cards unseen.
   A gift buyer's `bought` counts only a spare's gift (D-343); the Gift cards unseen (D-344).
   Arrange's limit bar hides the back wall in an XL home. A box lid opening into a piece behind
   it (only walls are kept clear). In Arrange the unit door's Close, Slam and Switch show.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277,
   D-297, D-299 to D-302, D-304, D-305, D-308, D-309, D-311 to D-350.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
