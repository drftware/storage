# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-08, session 31 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-05a1 is done** (D-040): the freight elevator's art, built in Blender (`art/elevator/`): the
  car (12.5 x 11 x 9.6 inside: cream riveted panels, oak bumper boards, diamond plate, a caged
  lamp), its collapsible lattice gate (13 pickets, 72 straps), the landing's striped steel frame
  and sill, the keypad (ten engraved keys, a red readout, a status light) and the sticky note.
  9,966 triangles. `Elevator.fbx`, the generated `src/shared/Elevator/Specs.luau` and five sheets
  (`art/sheets/elevator-*.png`). Not yet uploaded or in Studio.
- **The gate is posed by code:** `src/shared/Elevator/Gate.luau` (pure, 9,229 Lune checks) puts
  every picket and strap for any spread; the sheets pose it the same way (`spec.gate_pose`).
- **The notes' digits are the game's to write** (D-040): a SurfaceGui in Kalam Bold inside
  `Specs.Note.Write`, slots like `_ 7 _ _`.
- **L-05a is split** (ROADMAP): L-05a1 the art (done), L-05a2 the elevator in Studio.
- **Brix's chase isn't ready:** ENG-06a, ENG-06b and ENG-07 are still open in `../engine`.

## Next task: L-05a2 The elevator in Studio
The moment: the last friend sprinting for the lit car as its gate folds shut. This ticket puts
the car where that happens: in the dev floor's lobby, prepared, its gate posed by code.
1. Owner test results first (`OWNER.md`): the elevator's and the Mannequin's sheets, then older.
2. Check `../engine/docs/ROADMAP.md`: if ENG-06 and ENG-07 have landed, say so and do L-06b
   instead. Don't edit Brix.
3. `lune run scripts/upload_art Elevator`, then `insert_asset` it and remove its PackageLink and
   `Assistant:` tag.
4. Write `src/shared/Elevator/init.luau`: `prepare(model)` (pivots as `Mannequin.prepare` sets
   them, each part anchored and collision-free, colliders from `Specs.Colliders`; `Lamp` casting
   no shadow; `LampGlass` Neon with a PointLight at `Specs.Lamp` using FloorBuilder's lamp
   values; `KeypadReadout` dark red glass; `KeypadLight` red Neon; the gate's 12 pickets, lead
   and 72 straps cloned from `GatePicket`, `GateLead`, `GateStrap` into a `Gate` folder; `Note`
   moved to `ReplicatedStorage.Props.Note`); `setGate(model, shut)` from `Gate.pose` (strap
   `CFrame.Angles(0, 0, Angle)`); `clone(pivot, parent)`; `note(pivot, parent, text)` writing the
   digits as UnitKit writes unit numbers. Template at `ReplicatedStorage.Props.Elevator`.
5. FloorBuilder: lay the elevator at the lobby's back (pivot `origin * CFrame.new(0, 0, half)`,
   facing -Z), the back wall built round `Specs.Opening`, the stand-in's car floor and lamp gone.
6. In Studio, Galaxy A16: from the hall's mouth, from the gate, aboard; the gate at 0, 0.5, 1 in
   Edit; a note with `_ 7 _ _` on a box. Shots in `docs/art/`. Save the place.
**Acceptance:** checks green; the elevator in the dev floor's lobby, its gate posed at three
spreads, a written note, verified in Studio; shots in `docs/art/`; `OWNER.md` has what to judge.
**Read first:** `art/elevator/README.md`; `src/shared/Elevator/Gate.luau`;
`src/shared/Mannequin/init.luau` (`prepare`); `src/server/FloorBuilder.luau` (`lobby`, by grep);
`docs/STUDIO.md` (Getting assets in, Importing kit pieces); `UnitKit.luau` (grep `SurfaceGui`).

## Queue (the next run's order, from ROADMAP)
1. L-05a2 the elevator in Studio; L-05b notes, keypad and gate working (notes where `Deal` puts
   them, the timer, a wrong code's alarm); L-11 tools in hand; L-06b the Mannequin hunts (Brix
   ENG-06, ENG-07); L-04e the deal on the floor; L-12 the saw and hole trap; L-13 the tops and
   the ladder; L-14 the other tools; then L-07, L-08, L-10, L-09.
2. L-05b presses a key by moving it `Specs.Keypad.Travel` along +Z, writes the readout on
   `KeypadReadout`, closes the gate with `setGate` over a second or two, and adds "flash every
   light" to `MotionLights`; L-06b's keepers hear doors on `Doors.acted`, walk on `Pose.at`;
   L-08 lays the next floor during the ride.
3. **Polish waiting** (ROADMAP): new from L-05a1, a floor dial over the landing, a trim sheet if
   the big trim reads soft (41 texels a stud), tally marks in the car, the shaft for the ride.
4. Studio traps (docs/STUDIO.md): an imported part's pivot carries the FBX's Z-up turn (take the
   part's own rotation); a prompt triggers from the MCP only while the camera faces it; captures
   can time out mid-Play (take the shots that matter first); standing still lets the hall go dark
   in 7.5 s; set the Device Simulator's device before its orientation.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
