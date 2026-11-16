# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 205 (each floor harder) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S4-01 done. S4-01b (D-228): the floor rules step up on floors 8 "More doors" (50), 10 "Four
  loose", 12 "Big floors" (a third plan, `Big`, 7 by 4 junctions, keeps 60), 15 "Two notes behind
  padlocks" (`lockedNotes`, a count now), 20 "More doors still" (70), 25 "Five loose", then hold.
  The notes stay four (`OWNER.md` decides). The 99-door cap now runs after the thinning; floors
  1 to 6 lay exactly as before. Laying's first slice is split: worst frame 5 to 7 ms (was up to 46).
- Seen in Studio Play: floors 8, 11 and 25 laid for real (25 with both locked notes padlocked),
  floor 11's code typed by remote rode to floor 12 (Big, 58 doors); floors 3 to 60 laid from the
  server, 70 to 100 ms of work. No new warnings. Play stopped; `DevFloorNumber` cleared. Not seen:
  anyone playing a high floor, two players, a phone (`OWNER.md` "Feel each floor get harder").
- Studio holds doubled modules, `FloorRules` too (STUDIO.md, OWNER.md).
- Find art (`art/finds/WAVES.md`): chattering teeth built, not imported; next the walking robot.

## Next task: F-G1b Using a find plays what it does
ROADMAP F-G1b. The moment: you take a find you've never seen, press its one verb, and it does
the thing it is: a lamp lights the unit, the jack-in-the-box cranks and pops, the cymbal monkey
clashes (and a monster hears it), the RC car drives off. Each use has its own sound and motion on
every screen.
1. Look first: ROADMAP F-G1b (grep `F-G1b`, ~line 2363) for the plan; `Tools/Catalog.luau`
   (grep `verb`: the air horn's "Blow" is the one press that exists); `src/server/Slots.luau`
   (grep `verb`, `ToolUse`) for how a press reaches the server; `Finds/Pose.luau`'s `at` and
   `Finds/init.luau`'s `pose` for how a find's joints are stood.
2. Too big for one session? Split first in ROADMAP: F-G1b1 the lamps and the jack (light and a
   pop, no monsters involved), F-G1b2 the cymbal monkey's lure and the RC car's drive.
3. Each find's one line is in `art/finds/WAVES.md`; its motions (`Wind`, `Play`, `Pop`, `Shut`,
   `Chatter`, `Drive`) are in its set's generated Luau (`src/shared/Finds/Sets/*.luau`; never edit).
   The server says which motion and when; each client writes the joints' C0 from `Pose.at`.
4. Noisy finds draw monsters only when used (D-188); lit lamps count against the cap on real
   lights (GDD tech plan). Every use answers with motion and sound in the same ticket.
5. Studio: `DevFloorNumber` 1, take a find (F-G1a's recipe in D-203), press it, read Output.
**Acceptance:** checks green; each used find plays its motion and sound in Studio Play; a use is
validated and rate-limited on the server; `OWNER.md` says how to try each.
**Read first:** ROADMAP F-G1b; `src/shared/Tools/Catalog.luau` (grep `verb`);
`src/server/Slots.luau` (grep `verb`); `src/shared/Finds/Pose.luau`; D-203; `art/finds/WAVES.md`.

## Queue (next sessions, the owner's ticket order)
1. **S3-05a, then S3-05b: caught players each in an empty unit of their own** (the owner's
   playtest bugs, Nov 15): the run's sessions 11 and 12, right after F-G1b, before the run ends.
   Then S4-02 to S4-05 (5 coins a trapped monster, D-188). Any ticket that adds finds starts
   from the catalog doc the GDD's finds section links.
2. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
3. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
4. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
5. Small: the shop's polish (ROADMAP S3-04b); Free Everyone's swap sound (Cut Free's click
   pitched down for now); Free a Friend's pills don't follow the map off screen; coin count and
   corner map up while wrapped; "rbxassetid://203785492 failed"; `ConfigService: Config value
   not found` (the `sell*` switches, now ten); "Stand one" never shows from the MCP;
   two-player reveal/coins/notes; a dropped find bumps a walker (D-182); rbxassethash warnings;
   Packrat's dead Slots entry; Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215);
   the save's "best floor" still reads 0 after a ride (seen again 11 to 12: check it's written).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
