# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 221 (the ground floor's numbers) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). S5-03a1 is split (D-260). a1a is done:
  `art/lobby/spec.py` re-laid as the ground floor, 156 deep, the front measured off `FRONT`, 12 XL
  slots (`slots`, `slot_lines`, `slot_rows`, `unit_card`) with colliders, name cards, 26 hall
  lights and the Specs writer's `Slots`. Checked by script only.
- `build.py`, sheets, `Lobby.fbx` and `Lobby/Specs.luau` are still the 48-deep front office, so
  the lobby still works: never regenerate Specs without the import.

## Next task: S5-03a1b The ground floor's build and sheets
The moment: you walk out of the car across the ground floor, every open unit down both walls
shows someone's finds, and yours has your name over it (Grow a Garden's plots round one ground).
1. `build.py` walls: `check()` asserts `UNIT_WALL == C.WALL_H`, `UNIT_FACADE == C.FACADE`,
   `HANG == C.WALL_H - C.CHANNEL_DROP`, `DOOR_GAP == C.UNIT.width`. Left and Right in
   `wall_layout`: facade and kick spans between the gaps (`slot_ys` ± `DOOR_GAP/2`), cap and
   panel the whole wall, a full post on each `slot_lines` line, a half post (`C.POST` wide) on the
   lobby side of each gap edge (the M unit's own half pilaster makes it whole).
2. Slot shells from `unit_parts` with an XL spec object (width 20, depth 30, wall_height 10,
   facade 0.25): `wall_side` once per slot line (partitions are shared), `wall_back` and `top`
   per slot, and the front wall's inside face either side of the gap (quads as `facade_back`
   does, slot edge to ±6). Place each with `WALLS[side][0] @ Translation((along(y, y)[0], 0, 0))`.
   Parts `UnitWallsLeft`, `UnitWallsRight`, `UnitTops` (Partition), each under 20,000.
3. Floor out to the units' backs (as the Floor collider); the joists over 156 pass 20,000, so
   `Ceiling` becomes the deck and `JoistsLeft`/`JoistsRight` the joists; add new parts to
   `TEXSET`. Signs: a name card plate on standoffs at each `unit_card` (`CARD`), as the bays'.
4. Sheets: move the shots for the depth (spawn y -150; counter, rack, door shift by -108); add
   `unit` (one unit from the floor, its card written) and `inside` (from a unit's back corner
   out its door); lift the plan's camera. Stand the M unit's front in every gap: load
   `art/unit/build.py` as a library the way `elevator_kit` does (swap `spec`),
   `Unit(Spec("M"), coll)`, `pose(7.65)`, `bake.copy_atlas` its DoorKit parts from
   `art/unit/out/M/unit.blend`, hide its walls, floor and top, copy the rest to each slot. The
   corridor's bulb (`corridor.build_bulb`) at each `slot_rows` bulb with a warm point light.
5. `scripts/art.sh lobby`, judge the sheets at phone size, then Studio by the README's "Into
   Studio" (upload, insert, `Lobby.prepare`, replace `Props.Lobby`) and Play: you load in inside
   the door and a car still takes you up. If Studio can't be done, `git checkout` Specs.luau and
   leave export and import together to a2.
**Acceptance:** check green; sheets show the ground floor and its 12 units at phone size;
`Lobby/Specs` has `Slots`; Studio Play lays it and a car takes you on a climb (or say why not).
**Read first:** D-260 (grep "^## D-260" docs/DECISIONS.md); `art/lobby/spec.py`;
`art/lobby/build.py` by ranges (walls 113-181, export 464-493, sheets 496-640);
`art/unit/parts.py` 163-206 and 316-336; `art/unit/build.py` 62-150 (`Unit`, `pose`);
`art/lobby/README.md` "Into Studio". This session spent 200k just reading: read by ranges.

## Queue (next sessions, the owner's ticket order)
1. S5-03a2 the floor in the game (M unit fronts in the gaps, lights for 156 deep), S5-03a3 a unit
   each (a Brix plots system first, D-252), F-G1b4a the hard hat on your head (no run-down at
   home, D-259), S5-03b the mirror test, then S5-03c to h.
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
