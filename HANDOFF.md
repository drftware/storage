# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 87 (overnight run, 2 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-07d done (D-099): a friend cuts you free.** With your door all the way up, "Cut free" (E, a
  1 s hold) stands on the film in front of your chest; the server judges each trigger
  (`Kept.cut`: not yourself, not kept, alive, between the unit's walls and in reach, a full hold
  on its own clock). While a friend holds, the film strains; the cut rips it, strips of film fly,
  the wrap slumps to a heap round your ankles and fades (`CutFreeView`, `Kept.tearPose`); both
  views jolt, yours widens. The door going up no longer lets anyone out.
- **Testing alone:** `ServerStorage.CutFreeTest` (Studio only) judges a cut by a stand-in body
  (docs/STUDIO.md, "Testing Cut free from the MCP"). The Mannequin often catches you again
  within seconds of a cut; whether a freed player gets a grace is in `OWNER.md`.
- Studio: nothing imported this session; left in Edit, seed 7, floor 1.

## Next task: L-07e The padlock
The moment: you've been kept too long; a padlock rattles on your door and a line warns everyone,
then it clicks shut. Now a friend needs bolt cutters before they can open you up and cut you
free. Dead by Daylight's hook stages are the precedent (wait too long and it gets worse).
1. Owner test results first, if pasted.
2. Read the GDD's "Getting kept" section for the clock and what the warning is. Gaps get a
   sensible default and an `OWNER.md` line.
3. Pure rules in `Kept` (Lune-tested): the clock's length and the warning's lead (feel numbers
   with comments), which time counts (a default: only while your door is down), and a door
   that's up when time runs out (padlocked once it's down again).
4. Server (`KeptPlayers`): a clock per kept player; at the warning, a padlock-handling sound at
   the door for everyone near (found and measured as the rip was, docs/STUDIO.md) and a short
   line for the kept player and friends (the bang mark and corner map already reach them); at
   the end `Doors:lock(unit, true)`, the game's own padlock. Cut free stays shut out until a
   friend cuts the padlock (the door's Cut, bolt cutters) and opens it. Being let out stops the
   clock; decide whether the padlock stays on the empty unit.
5. Feedback in the same ticket: the warning's sound and line, the lock clicking on heard by
   the kept player and anyone near (DoorSound's PadlockShut), "Padlocked" on the kept screen.
6. A Studio-only short clock (a Workspace attribute, as `DevFloorSeed` is) so a test needn't
   wait minutes.
**Acceptance:** checks green; in Studio on seed 7, floor 1 (get kept: docs/STUDIO.md's "Testing
getting kept from the MCP"), with the short clock: the warning plays with its line; the door
padlocks at the end and its button says Padlocked; a door up at the time is padlocked only once
it's down; the padlock cut (bolt cutters), the door opened, a stand-in's cut lets you out; being
cut free first stops the clock; Output clean.
**Read first:** ROADMAP L-07e; the GDD's "Getting kept" (docs tools, that section only); D-099
and D-097; `src/server/KeptPlayers.luau`; `src/server/Doors.luau`'s `lock`; docs/STUDIO.md's
"Testing Cut free from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-06c1 a walk that frightens (the owner: today's steps sound like Pinocchio), L-06c2 the
   catch as a jump scare.
2. L-08a the ride, L-08b the next floor, L-08c left behind, L-08d the climb ends. L-08e (the
   start, in the lobby) waits for the owner.
3. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
4. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
5. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
6. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
