# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03d4 (D-358) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- S5-03d (taking finds up) is done. S5-03d4 (D-358): a find out of your job box that a rider
  holds or wears goes in the trip's data (`Trip.Version` 4, `finds`) and leaves the lobby quietly
  with them (Slots' `going`; a failed trip leaves it in hand, `stay`). On the group's own server
  each rider's own word about their own finds waits for their save to load, then only what it
  backs (`Taken.backed`) is dealt into the holder's slots, already up (Slots' `carryUp`), just
  before the car rides, or as a late save loads. Seen with Studio's stand-in (DevTrip "Arrive"
  plus `DevTripFinds`, STUDIO.md): 3 of 5 dealt, the extra Skates and a made-up name refused.
  The live trip and a live shutdown mid-climb are an OWNER.md test (two accounts).
- Card styles (S5-03g3c, D-357) and h6's other grows are still unseen in Studio: OWNER.md.
- Studio hooks: `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows", "fromShelf",
  "shelfAway", "size"; Trips' `DevTripFinds`. Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1),
  Boombox 10, Skates 1.
- **Climb run:** done: the fix pass (D-400), S4-02, S4-04, S4-03 the next-floor cards (D-403
  to D-413), S4-05 split and its a, the jukebox's art (D-414: sheets, row unticked, not yet
  imported). Next: F-G1b4a the hard hat's beam; S4-05b (the big find on the climb, imports the
  jukebox) once the home chain frees `Climbs`, `GatePay`, `Slots`.

## Next task: S5-03a2d The cars' hidden triangles
**The conductor clears this with the climb chain before it starts: the six lobby cars are the
climb's Elevator, which is theirs.**
The moment: on a cheap phone, the calm ground floor runs smooth from the spawn to a car, the
cars as solid as ever. D-271 measured the spawn view at 144,616 triangles, over the default (a
climb floor's busiest, up to 112k); the six cars are 51k of it, 8.5k each.
1. In Studio Play on the Galaxy A16 simulator, at D-271's three spots, read the triangles; then
   find which of a car's parts nobody sees from the ground floor (above the ceiling, behind the
   shaft wall, under the floor), by its parts in `art/elevator/` and the car in Studio.
2. Draw those only where they're seen, as the fronts' drums are (`Home.InsideOnly`,
   `LocalTransparencyModifier` in HomeLights): on the ground floor only from inside or beside
   the car. On the climb the car rides a shaft, so check what a rider sees there before hiding
   anything on a climb floor; if unsure, hide on the ground floor only.
3. Measure again at the same spots and on a climb floor's busiest view (it mustn't grow).
4. Look at phone size from the spawn, in front of a car and riding in one: nothing visible lost.
**Acceptance:** the spawn view's triangles drop by the hidden parts; nothing seen goes missing;
the numbers in a new decision (D-359) next to D-271's table; check green. Next task then: the
next home piece in ROADMAP (S5-03g3d, card styles sold at the counter, unless the owner reorders).
**Read first:** ROADMAP S5-03a2d; D-271; `art/elevator/README.md`; `art/elevator/spec.py`;
`src/client/HomeLights.luau` (its InsideOnly part); `src/shared/Home/init.luau` (`InsideOnly`).

## Queue (next sessions, the owner's ticket order)
1. S5-03g3d (card styles sold at the counter). Small's doorway's inside boards are oak, not the
   picked paint (D-355, my call). Sitting's leftovers (D-353): cross-legged on the blanket needs
   an animation of our own; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit
   (on a trip too: the trip carries no lit state); the cubby finds' own buttons; a friend's take
   shows before the flying copy lands; the steel shelf's lower tiers; Arrange shows the job box's
   "Open" and the door's buttons; a lifted lit piece's light; a grow while Arrange is open closes
   it (D-356); Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused
   cubby place (D-352). A taken-out find comes out whole even when the save has it cracked.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 358.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
