# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 220 (the home planned and approved) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The owner approved the home (D-259): a unit of your own on the ground floor, the front office
  re-laid with six units down each side wall facing the open middle, so everyone sees everyone's
  finds. The plan is its own Claude Doc, "Your unit: the home in the lobby"
  (https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww; docs tools, never WebFetch): 31 numbered
  ideas, a drawing of the layout, and "What you decided (Nov 16)", which wins where ideas differ.
  ROADMAP's S5-03 lists its pieces in the owner's order; it goes ahead of S4-02.

## Next task: S5-03a1 The ground floor's art
The moment: you walk out of the car across the ground floor, every open unit down both walls
shows someone's finds, and yours has your name over it (Grow a Garden's plots round one open
ground; the home doc's "Where it goes", ideas 1 to 5 and 31).
1. Re-lay `art/lobby/spec.py` and `build.py` as the ground floor. Keep exactly: the back wall
   with the six bays (the export checks them against `art/elevator/spec.py`), the glass front
   and door, the counter and its shelves, the cart rack's six slots. The room gets deeper.
2. Six unit slots down each side wall (12 in all), each XL inside (20 across, 30 deep, D-259)
   behind the wall, with a roll-up door opening onto the floor built from `art/unit`'s parts
   (the climb's door, so it rolls the same), a name card frame over each door, a warm bulb
   inside. Smaller units will stand inside a slot behind partitions later (S5-03h): leave room.
3. Load-in spot far enough in that a new player is in a car within 15 s (about 16 studs a
   second at a run); keep the joists, deck and hall lights the corridor kit's.
4. Under 20,000 triangles a part; rebuild with `scripts/art.sh`; new look sheets (load-in view,
   a unit seen from the floor, from inside a unit, the plan) judged at phone size.
5. `Lobby/Specs` regenerated with each slot's door point, inside box and name card spot, for
   a2 (laying it in the game) and a3 (handing units out) to read. Don't change game code beyond
   what keeps today's lobby working; a2 does the rest.
**Acceptance:** check green; the sheets show the ground floor and its 12 units at phone size;
`Lobby/Specs` has the slots; in Studio Play the game still lays the lobby and a car still takes
you on a climb (or, if the import must wait for a2, say so here and in OWNER.md).
**Read first:** the home doc's "What you decided", "Where it goes" and "Your unit" (docs tools);
D-259 (grep "^## D-259" docs/DECISIONS.md); `art/lobby/README.md`; `art/lobby/spec.py`;
`art/unit/README.md` (its parts and sizes); `src/shared/Lobby/init.luau` (how the room is laid).

## Queue (next sessions, the owner's ticket order)
1. S5-03a2 the ground floor laid in the game, S5-03a3 a unit for each player (a Brix plots
   system first, D-252), then F-G1b4a the hard hat on your head (its ROADMAP entry has the
   steps; at home it doesn't run down, D-259), then S5-03b the mirror test, then S5-03c to h.
2. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
3. Brix ticket: Driving's default stick read requires `PlayerScripts.PlayerModule`, which places
   on Roblox's Input Action System lack; fall back to `Humanoid.MoveDirection` turned by the
   camera, as this game's `input` does (D-254). Built in `../engine` by its rules, then the pin.
4. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
5. The item catalog doc still says "at home" for the six lamps and the RC car; `WAVES.md` has
   the new lines (D-250). The catalog's hard hat, skates and slippers and the design doc's
   finds section need D-251 and D-259. Bring both in line when they're next opened.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Trips stands every late arrival or respawn on the one arrival spot; two at once overlap
   until physics pushes them apart. Spread them (`ClimbEnd.spot`) as the carry's fallback does.
8. While you drive, your torch is still on in the game's rules, tested from your head along
   where the hood looks, though friends see it held at the floor (D-257). Make the rules match
   what's seen (aim it at the floor while driving) or put it to the owner.
9. Small (ROADMAP lists them): the RC car's polish; the lamps going out, the finds' press
   sounds and hand, the monkey and toy car's polish; B-05b2b's box round the bend; L-08e3c,
   L-14b2d wait; S3-04b's polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped
   find bumps a walker (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2
   leftovers, box words (D-215); opening a box in Play logs rbxassetid://92259888500166 failing
   27 times; Play logs rbxassetid://203785492 "Asset type does not match" six times.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
