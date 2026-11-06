# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-05, session 1 · **Checks:** green · **Git:** `storage-unit` committed locally (`main` has no
commits yet), no remote.

## State
- **The storage unit is built** (P0-01): the 10x10 unit and its roll-up door, made as code in Blender
  (`art/unit/`), with baked PBR textures, `art/unit/out/StorageUnit_M.fbx` for the 3D Importer, and the door rig in
  `src/shared/StorageUnit/` (Lune specs green). Look sheets and door animations are in `art/sheets/`.
- **Nothing has been in Roblox Studio yet.** The FBX re-imports cleanly in Blender; the importer's pivots and
  alpha mode are the open risks (`docs/STUDIO.md`).
- The handoff system mirrors Time Snatchers: AGENTS.md rules, this file, OWNER.md, `docs/`, a Stop hook, `/wrap`.
- **Systems come from Brix first** (D-008, `docs/FRAMEWORK.md`): its core, Schema, Signal, Random and Zones are
  ready; the keepers' chase lands with its ENG-06 and ENG-07; remotes, saves, config and a round loop are planned.

## Next task: P0-02 The Roblox project, and the unit in Studio
The moment: in Studio Play, walk up to a real storage unit, peek under its door, haul it open and slam it, while a
friend in the next unit sees the same door move and gets blocked by it.
1. If the owner pasted a verdict on the unit's look or test results, act on them first.
2. Finish the Rojo tree: `src/server` → ServerScriptService.Server with an entry script; the place's settings in
   `default.project.json` (StreamingEnabled, Lighting on Future with an Atmosphere for the corridor); an `assets/`
   folder for model files. Mount Brix as a git submodule at `vendor/brix`, pinned to its latest commit and mapped
   to `ReplicatedStorage.Brix` (`docs/FRAMEWORK.md`); start the server and client on a Brix Host, empty for now.
3. Bring the unit in. If this session can drive Studio (a Studio MCP tool or computer use), import
   `art/unit/out/StorageUnit_M.fbx` per `art/unit/README.md` "Into Studio", run `UnitKit.prepare`, and save the
   result as `assets/units/StorageUnit_M.rbxm` mapped by Rojo to `ReplicatedStorage.Units.M`. If it can't, write
   those exact steps in OWNER.md, build steps 4 and 5 against that path, and stop for the owner.
4. A dev corridor (Studio-only server script): four units a side of an 8-stud hall, shared walls dropped, numbered
   and painted, with dev prompts on each door (Peek, Open, Close, Slam, Lock) that call `RollUpDoor` directly. The
   real door gameplay is L-02, not this.
5. Play with two clients (Test, Clients and Servers): every action looks right and the DoorCollider blocks or frees
   each player; bolt and padlock; paint; plate numbers; units streaming out and back in. Save phone-size
   screenshots to `docs/art/P0-02-*.png`.
6. Write in `docs/STUDIO.md` what the importer really did (pivots, AlphaMode) and the corridor's triangle and
   draw-call counts; fix anything wrong in the rig.
**Acceptance:** checks green with Brix mounted; two-client Play shows every door action looking and blocking right
for both players; screenshots saved; STUDIO.md records the importer's real behaviour. If the import waits on the owner, everything
else is done and OWNER.md lists the steps.
**Read first:** `art/unit/README.md` ("Into Studio", "Moving the door"); `docs/STUDIO.md`;
`src/shared/StorageUnit/UnitKit.luau` (header and `prepare`); `src/shared/StorageUnit/RollUpDoor.luau` (header);
`default.project.json`; `docs/FRAMEWORK.md`.

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
3. **Phase 1, the loop with real assets** (the owner's plan): L-01 floor generator, L-02 doors as the GDD's state
   machine, L-03 motion lights, L-04 what's behind the door, L-05 notes, keypad and elevator, L-06 the Mannequin,
   L-07 getting kept and rescued, L-08 the ride and a second floor, L-09 hone until friends ask for another run.
   Each ticket names its Brix piece; L-06 waits on Brix's Pursuit (ENG-06, ENG-07).
   Each art piece a loop ticket needs (elevator, keypad, notes, the Mannequin) is built first, the unit's way.
4. **Then Phase 2:** the rest of the floors and the game (ROADMAP).
5. **Polish waiting:** judge sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
