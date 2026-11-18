# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03g3c (D-357) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03g3c done (D-357): Arrange's front tab has a second row, your name card's four styles as
  little plates with your name on them (`LooksTab`'s `plate`). The stencil picks; the painted
  board and chalk wear a gold coin, the neon the Robux mark (`Looks.cardLock`), a shade darker;
  a tap on one only shakes it and pops the mark. A card chip dips the camera through black out to
  the hall facing your plate (ArrangeView `hall`, `dip`, `Arrange.Feel.Hall*`), a door chip back
  in. A new style's plate swings down on its top edge, bounces and clacks on every screen near
  (HomeCards `swing`, `Holding.Card.Swing`). **Passes checks, untested in Studio**: in Play
  at A16 the MCP's click on the Arrange button (`Arrange.CanvasGroup.TextButton`, shown at the
  top right inside Unit1) didn't open it this launch, nor a slow press; context ran out.
- h6's other grows (Medium to Large, Large to XL, the hold till you walk in) still unseen:
  Studio was another session's for most of this one. Both passes are OWNER.md steps.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size" (grows the counter's way; STUDIO.md "Watching a home grow"). Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1; its `LookFrame` +Z runs into the room).
- **Climb run:** done: the fix pass (D-400), S4-02 (D-401), S4-04 (D-402), and S4-03 the
  next-floor cards, all four versions picked on rides and seen in Play (D-403 to D-413). Next:
  S4-05 The big find (not yet planned: split it in ROADMAP first, its art the finds' way, then
  the climb; Lethal Company's heavy scrap).

## Next task: S5-03d4 A taken-up find across the trip
**The conductor clears this with the climb chain before it starts: it touches `GatePay`,
`Slots`, `Climbs` and the trip, which are theirs.**
The moment: you take your lucky boombox up from your home, ride the freight car to floor 1, and
it's in your hand up there, and if the climb's server goes down mid-run you still have it
(Lethal Company's ship loot carried between moons; D-304, D-305).
1. Read how the trip leaves today (`Trips`, `Climbs`): what the teleport's data carries, and
   where a live climb's server deals each rider's slots (`Slots`, `GatePay`).
2. Put each rider's taken-up finds (the find, its key, cracked or not) in the trip's data.
3. On the climb's server, check each against that rider's save (`Save.boxed`, the taken flag
   D-304 sets) and deal the good ones into their slots already up; drop anything the save
   doesn't back. The lobby doesn't recall what left on the trip.
4. Lune specs for the check (a forged or missing find is refused; a cracked one stays cracked).
5. Untestable in Studio (one server): exact steps in OWNER.md, with a live shutdown mid-climb
   (D-305: nothing taken up may be struck).
**Acceptance:** the trip carries the taken-up finds; the climb server deals only what the save
backs; specs green; check green; OWNER.md steps. Next task then: the next home piece in ROADMAP
(S5-03g3d, card styles at the counter, unless the owner reorders).
**Read first:** ROADMAP S5-03d4; D-304, D-305; `src/server/Trips.luau`; `src/server/Slots.luau`;
`src/server/Climbs.luau`; `src/server/GatePay.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g3d (card styles sold at the counter); S5-03a2d the cars' triangles. Small's doorway's
   inside boards are oak, not the picked paint (D-355, my call). Sitting's leftovers (D-353):
   cross-legged on the blanket needs an animation of our own; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit;
   the cubby finds' own buttons; a friend's take shows before the flying copy lands; the steel
   shelf's lower tiers; Arrange shows the job box's "Open" and the door's buttons; a lifted lit
   piece's light; a grow while Arrange is open closes it (D-356); Robux unit and gift cards
   unseen; the XL limit bar; Take through a wall; a refused cubby place (D-352).
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 357.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
