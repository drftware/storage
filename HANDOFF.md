# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 222 (the ground floor's build and sheets) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). S5-03a1 is done (D-260, D-261):
  `art/lobby/build.py` builds the 156-deep ground floor, a gap per unit in the side walls, the
  units' shells from the unit kit at XL, the joists as `JoistsLeft`/`JoistsRight`. Every part is
  under 20,000; the room is 87,446 triangles. Sheets `art/sheets/lobby-*.png` (new: `unit`,
  `inside`) stand the M's front in each gap, ten open and lit, two shut.
- `art/lobby/out/Lobby.fbx` is the new floor, but `src/shared/Lobby/Specs.luau` is still the
  48-deep front office and the place still holds the old mesh: export, upload and import go
  together in a2a, never Specs alone.

## Next task: S5-03a2a Into the game with its unit fronts
The moment: you load in just inside the glass door, the floor runs away to the cars, and twelve
roll-up doors line the walls, each one a real door that rolls the way it does on a climb.
1. `scripts/art.sh lobby export` (writes the FBX and `Lobby/Specs.luau` with `Slots`, the new
   `Parts` and the units' colliders), then `scripts/check.sh`: fix what the new Specs breaks.
2. `Lobby.prepare`: square the new parts (`JoistsLeft`, `JoistsRight`, `UnitWallsLeft`,
   `UnitWallsRight`, `UnitTops`); its `{ "Floor", "Ceiling", "Panel" }` list (init.luau ~180)
   decides something per part: put the joists and unit parts where they belong.
3. `Lobby.lay`: for each `Specs.Slots` row, a copy of the climb's M unit (find how the floor
   builder places one: grep `dropWall` in `src/`), its WallLeft, WallRight, WallBack, Floor and
   Top dropped, pivoted so its doorway's outer face sits on `Door` looking along `Out`; paint
   its facade the lobby's walls (`Lobby.Paint.Walls`); its door shut and working as on a climb
   (a3 decides who opens it). The bulbs and the units' lights wait for a2b.
4. `lune run scripts/upload_art Lobby`, then Studio by `art/lobby/README.md` "Into Studio":
   insert, `Lobby.prepare`, replace `Props.Lobby`, save. Play: you land just inside the door
   facing the cars, no holes in the side walls, a unit's door rolls, a car takes you up.
**Acceptance:** check green; `Lobby/Specs` has `Slots`; Play lays the floor with twelve M fronts
in their gaps and you climb from a car (or say why not and leave the import with Specs undone).
**Read first:** D-261 (grep "^## D-261" docs/DECISIONS.md); `src/shared/Lobby/init.luau`
(`prepare` 126-213, `lay` 255 on); `src/shared/StorageUnit/UnitKit.luau`; the floor builder's
use of `dropWall` (grep); `art/lobby/spec.py` 283-376 (`slot_rows`, `write_luau`);
`art/lobby/README.md` "Into Studio". Read by ranges: 300k is the cap.

## Queue (next sessions, the owner's ticket order)
1. S5-03a2b lights for 156 deep (the floor before the spawn is black in `lobby-spawn.png`; each
   open unit's bulb; the phone light cap), S5-03a3 a unit each (a Brix plots system first,
   D-252), F-G1b4a the hard hat on your head (no run-down at home, D-259), S5-03b the mirror
   test, then S5-03c to h.
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
