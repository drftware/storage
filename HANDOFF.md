# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 223 (the ground floor in the game) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). S5-03a2a is done (D-262): the 156-deep
  ground floor is exported, uploaded (asset 80376262399856), imported as `Props.Lobby` and the
  place saved (version 57). `Lobby.front` stands the climb's M unit in each of the 12 gaps
  (walls, floor, top dropped; oxblood door; tagged, so Doors runs it; anyone may open any one).
- Light (pulled in from a2b): fills in three rows of two; each front's bulb is a home's
  (`UnitLight.Home`: reach 22, 1.7 times as bright, no shadow, real whenever lit). Verified in
  Studio Play: twelve fronts, a door rolling, every open unit warm from the spawn, a car taking
  you to floor 1. Not yet on a phone or in the A16 emulator.
- The name cards over the doors (`Specs.Cards` `Unit1` to `Unit12`) are laid empty: a3 writes
  each owner's name.

## Next task: S5-03a2b The ground floor weighed for a phone
The moment: on a low-end Android you load in and run 150 studs to the cars past twelve lit
units, and it never stutters.
1. Count what the lobby draws, all twelve doors open: triangles (the room's `Specs.Parts`
   sum, 87,446, plus twelve M fronts and six cars), real lights (Client: enabled `Light`s under
   `Workspace.FrontOffice`; expect 25: 6 fills, 12 home bulbs, 6 car lamps, the porch) and
   shadowed ones. Compare with the GDD tech plan's caps.
2. Trim where it passes: try 4 fills (rows at, say, 40 and 116) and judge the spawn view by
   captures; leave out of each front any part nobody sees (look at `FacadeBack` and the slat
   templates); keep the cars, carts and trips untouched.
3. Time the run from the spawn to a car at the game's walk speed (GDD: under 15 s).
4. Write the numbers in D-263 and the phone steps in `OWNER.md` ("Walk the new ground floor").
**Acceptance:** check green; D-263 has the counts before and after; the spawn view still reads
lit with warm doorways (set the client's camera before each capture, STUDIO.md); a car still
takes you up.
**Read first:** D-262 (grep "^## D-262" docs/DECISIONS.md); the GDD's tech plan section (docs
tools, search the heading); `src/shared/Lobby/init.luau` (`Fill` ~66-82, `front`, `lay`);
`src/shared/UnitLight.luau` (`Home`); `docs/STUDIO.md` "The hall's render cost" (583 on);
`art/lobby/README.md` "Not verified yet".

## Queue (next sessions, the owner's ticket order)
1. S5-03a3 a unit each (a Brix plots system first, D-252; the owner's name on its card, the
   doors' rules), F-G1b4a the hard hat on your head (no run-down at home, D-259), S5-03b the
   mirror test, then S5-03c to h.
2. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the camera-
   turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`, then the pin.
4. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
5. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259 when
   next opened (lamps and RC car "at home"; hard hat, skates, slippers).
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off the one arrival spot (`ClimbEnd.spot`); the driving torch's rules
   vs what's seen (D-257); Play logs assets 92259888500166 (box opens, 27 fails) and 203785492
   (type mismatch). Small polish: ROADMAP lists it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
