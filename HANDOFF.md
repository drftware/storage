# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 204 (the floor rules) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S4-01a done (D-226): `FloorRules.at(n)` is one frozen row per floor (any number, 1 to 100 and
  past): plan, doors kept, notes, padlocks, a padlocked note, most loose, packed share, teaching.
  Four named steps (1 "Learning the doors", 3 "Full size", 5 "Three loose", 6 "A note behind a
  padlock") plus the packed curve; today's numbers unchanged. `Floor.planFor`, `Deal`, `Waking`
  and `Keepers` read it. `Climb.Top`/`Building` are gone; the escape ("Made it") is kept unfired.
- Seen in Studio Play: floor 3 (code typed by remote) rode to floor 4, which laid with 40 units,
  4 notes, 5 padlocks and paid 14 coins; floors 5 and 101 started straight away (`DevFloorNumber`,
  now uncapped) laid and dealt, plates "10102". No new warnings. Play stopped; the attribute is
  cleared again. Not seen: two players, a long climb, a phone (`OWNER.md` "Climb past floor 3").
- Studio holds doubled modules, `FloorRules` too (STUDIO.md, OWNER.md). A second find-art run
  (the rest of the wind-ups and the squishies) is planned in `art/finds/WAVES.md`.

## Next task: S4-01b What changes floor to floor
ROADMAP S4-01b. The moment: each floor up feels a notch tighter (more doors to search, more
monsters loose, the code harder to piece together), and the team can name what changed.
1. Look first: `src/shared/FloorRules.luau` (whole, ~170 lines); the GDD's "Floor rules" (docs
   tools: `read` ref node `15cf0df0-0c6f` in project `UtmFtWGEMRQkNmWmCEhFWN`, payload
   `{kind: "search", text: "Floor rules"}`); D-226 (grep `^## D-226`).
2. Design new steps past floor 6, each named for what players meet, each with a hit-game
   precedent and its player moment, defaults in `OWNER.md`: more doors kept, more loose (never
   past `Waking.AwakeMost`, 6, the phone cap), fewer notes (`notes` must be 1, 2 or 4: `Deal`
   splits the 4 digits `4 // count` a note). Steady, with a plateau well before 100.
3. Doors: the Full plan's halls have room for about 80 units (60 to 99), so more than about 50
   kept needs a bigger shape: add one to `Floor.Plans` and to `FloorRules.Plan`. `floor.spec`
   groups floors as `number <= 2` short / else full (grep `counts`, `band`, ~line 874 and 938):
   make it compare each floor's units to its own rules. Keep `Floor.MaxUnits` (99) in mind.
4. Specs: extend `tests/floorrules.spec` for the new steps; `climb.spec` deals `FLOORS = 10` per
   climb (raise it if a step lands past 10). The other per-floor curves (Waking, Pay, Breaker
   errands, Grades) may stay where they are; pull one into a step only if it reads better named.
5. Studio: `DevFloorNumber` on each new step's first floor (and a big one, e.g. 60): Output's
   "floor N laid, ... ms" line shows lay time (floor 3 took 4.1 s, 12 ms at most a frame); a
   bigger plan must stay in that range. Ride one floor (STUDIO.md "Testing the ride from the
   MCP": DevCorridor prints each floor's code; the car is `DevCorridor.FloorN.Lobby.Elevator`).
   Clear `DevFloorNumber` after.
**Acceptance:** checks green; each step named and proven in the spec; each new step's floor lays
in Studio Play with no new warnings and lay time in range; `OWNER.md` says what to feel at each.
**Read first:** `src/shared/FloorRules.luau`; GDD "Floor rules"; D-226; `src/shared/Floor.luau`
(grep `Plans`, `planFor`); `tests/floor.spec.luau` (grep `band`); ROADMAP S4-01b.

## Queue (next sessions, the owner's ticket order)
1. **F-G1b Using a find plays what it does** (ROADMAP F-G1). Any ticket that adds finds starts
   from the catalog doc the GDD's finds section links.
2. **S3-05a, then S3-05b: caught players each in an empty unit of their own** (the owner's
   playtest bugs, Nov 15): the run's sessions 11 and 12, right after F-G1b, before the run ends.
   Then S4-02 to S4-05 (5 coins a trapped monster, D-188).
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
6. Small: the shop's polish (ROADMAP S3-04b); Free Everyone's swap sound (Cut Free's click
   pitched down for now); Free a Friend's pills don't follow the map off screen; coin count and
   corner map up while wrapped; "rbxassetid://203785492 failed"; `ConfigService: Config value
   not found` (the `sell*` switches, now ten); "Stand one" never shows from the MCP;
   two-player reveal/coins/notes; a dropped find bumps a walker (D-182); rbxassethash warnings;
   Packrat's dead Slots entry; Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215);
   the save's "best floor" read 0 after riding to floor 4 (check it's written at the climb's end).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
