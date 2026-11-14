# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 138 (S1-11 The one faint mark) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-11 is done (D-150).** A hasty chalk ring with a dot (art/mark/, numpy-drawn texture on
  one plane, Open Cloud asset 98200031009749, template `ReplicatedStorage.Props.FaintMark` in
  the place) sits on the left jamb of one note's door. `Deal.markFrom` (pure, Lune-tested in
  `tests/mark.spec.luau`) marks a note that isn't the guarded one: always on floors 1 and 2,
  6 floors in 10 above (`MarkShare`, drawn last in `Deal.new`). FloorBuilder sticks it hidden
  in the hall piece's folder, tagged `FaintMark`. FaintMarkView shows it only in your own beam
  (`FaintMark.seen`: within 9.5 studs, 25 degrees of the beam's middle, from the front),
  blooming in and lingering out, scaled by your torch's light (`Beam.light`, new). No sound.
- **Sampled in Studio Play** (floor 1 via `DevFloorNumber`, cleared after): the mark landed on
  Unit118's left jamb (a note's unit, not the guarded one); hidden with the torch off; 0.30
  transparency (its fullest) at 4 studs straight on and 4 studs down the hall; 0.64 at 7.4
  studs; 1 with the beam 37 degrees off; seen once on screen (reads as chalk on the dark jamb).
  Not on a phone, no friend. Studio in Edit; its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-12 Cash on the results
The moment: the climb ends, the results go up on the car's wall, and the coins you didn't
spend turn into cash you keep, counted up in front of you.
1. Read ROADMAP S1-12 and the GDD's section on cash and coins (docs tools, never WebFetch);
   name the hit game the conversion comes from or flag it.
2. Server: at the climb's end (`ClimbEnds`), turn each player's unspent coins (`Coins`) into
   cash by a pure rule (Lune-tested), add it to the saved profile (`Save`, `Saving`: versioned,
   a migration if the schema changes), and grant only once it's saved.
3. Client: the results on the car's wall (`CarResults`) show the cash you earned, counted up
   with its sound; nothing that explains the rule.
**Acceptance:** checks green; the rule tested; in Play a climb's end shows the cash and the
profile holds it after a rejoin (or a Studio save read back).
**Read first:** ROADMAP S1-12; GDD cash section; `src/server/ClimbEnds.luau` (header);
`src/server/Coins.luau` (grep `spend`); `src/shared/Save.luau` (grep `version`);
`src/client/CarResults.luau` (header).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-12 (next), then ROADMAP Phase 2 Step 2. S2-06 and L-08e3c wait on `OWNER.md`. Lobby
   polish waits.
2. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
3. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
4. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
5. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
6. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
7. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
8. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
9. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
   find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
   on another server, the save claim may wait up to 5 s. Lobby fixes are "later" (owner Nov 12).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
