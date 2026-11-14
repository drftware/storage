# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 123 (S1-04b1 The stuff's art) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-04b1 is built** (D-135). `art/stuff/` builds a Mattress (stood on its end, leaning on a
  wall, stained, 568 triangles) and a Carpet (a rolled rug tied with rope, stood on its end in a
  corner, 774) in one Stuff texture set; four box stacks (Tower, Wall, Heap, Column) are data in
  `src/shared/Stuff/Specs.luau`, reusing `Props.Boxes`. Both pieces are in the place at
  `ReplicatedStorage.Props.Stuff` (asset 116353643690626, prepared). `Stuff.lay(name, pivot,
  parent)` lays a piece or a stack, its middle on the floor, front to the pivot's LookVector,
  back for a wall; `Stuff.size(name)` its across, tall, deep. **Seen in Studio** (Edit, copies of
  the S and M unit templates, door hidden, bulb at `UnitLight`'s settings, from the doorway at
  eye height, also at 668 px wide): the mattress reads quilted and stained against the S unit's
  left wall, the carpet as a tied rug in the back corner, the Tower and Heap stand square in the M
  unit. Nothing deals them yet. The place isn't saved by me (the owner saves as they go).
- Studio syncs (Rojo connected). Target only "Storage (placeId: 113250085204323)" by its
  `studio_id`; a Brix Studio may be open too. Left in Edit, workspace as found.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-04b2 Stuff dealt into units
The moment: a door goes up on a unit with no coins and somebody's stuff is in there, a mattress
leaning on the wall, boxes stacked to the bulb, so every door is worth opening.
1. Read ROADMAP S1-04b2 and GDD "Doors" (docs tools, search "bare"): of the units with nothing to
   take, some are bare and some hold stuff. Default (OWNER.md line if new): about half of the
   coinless units get one thing, any of `Stuff.Pieces` and `Stuff.Stacks`.
2. `Deal`: draw it after the coins, so no seed's other draws move (holetrap.spec's replayed
   seed and coins.spec check this); a find, tool or keeper unit gets none.
3. `DealSpot`: stand it with its back to a wall (`Stuff.size`: deep is the back's side), the
   mattress on a side wall where the doorway sees its face, stacks and the carpet at the back;
   clear of the door's line, the crawl hole spots, the landing, the coins and the note's sight.
4. `Deals` lays it with `Stuff.lay` into the unit's hall piece when the unit is first opened, as
   finds are; Studio prints it. Check the S unit fits every thing (tests/stuff.spec does).
5. Lune specs for the rate and the spot; then Studio Play: open coinless units on the dev floor
   and say exactly what stood where. Collision: pieces collide as boxes; check a player can't
   wedge between the mattress and the wall.
**Acceptance:** checks green; Lune specs prove the rate, that other draws don't move, and that
every spot is clear and against a wall; seen in Play (say exactly what).
**Read first:** ROADMAP S1-04b2; `src/shared/Stuff/init.luau`; `src/shared/Deal.luau` (the coins'
draw); `src/shared/DealSpot.luau` (`inUnit`, the coins' spot); `src/server/Deals.luau`;
`tests/coins.spec.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-04b2 (next), then S1-05 Finds you carry. S1-02 Recording waits on Brix ENG-12 (a Brix
   session is building it). S2-06 and L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-04b1: the stacks' boxes all wear the same few marker words; more words and more
   stuff are in ROADMAP's polish list.
3. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you (Brix retries a held claim every 5 s). If too slow once saved cash
   shows, a Brix ticket in neutral terms: retry sooner after a hold being let go.
4. Found S1-03: Deal's padlock count is a share of the units, so floors get about half as many
   padlocks. S1-07 sets padlocks afresh.
5. Found L-08e3b: a lobby car's `far` isn't cleared when its group's trip fails; it ages out.
6. Found L-08e4b1: no PlayerModule in PlayerScripts in Play, so WatchView's `controls` lookup
   fails quietly (controls may stay on while you watch; untested).
7. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim. Older: git log of
   HANDOFF (session 116).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
