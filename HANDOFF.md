# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-05, session 2 · **Checks:** green · **Git:** `storage-unit`, local only (`main` has no commits yet).

## State
- **The storage unit is built** (P0-01): Blender-made unit and roll-up door (`art/unit/`), baked PBR textures,
  `art/unit/out/StorageUnit_M.fbx`, and the door rig in `src/shared/StorageUnit/` (Lune specs green).
- **Sessions can now drive Studio.** Studio's MCP server was only set up for the owner's Game1 folder; `.mcp.json`
  now starts it here too, from the next session on (session 2 stopped early so P0-02 runs with it). Nothing has
  been in Studio yet, and no P0-02 code is written.
- **D-009:** Rojo can't live-sync imported meshes, so the unit template lives in the place at
  `ReplicatedStorage.Units.M`, not in Rojo's tree; the repo keeps a saved copy at `assets/units/M.rbxm`.

## Next task: P0-02 The Roblox project, and the unit in Studio
The moment: in Studio Play, walk up to a real storage unit, peek under its door, haul it open and slam it, while a
friend in the next unit sees the same door move and gets blocked by it.
1. Owner verdicts or test results first. Then find the Studio tools (ToolSearch `studio`, `run_code`,
   `Roblox_Studio`) and check Studio has this game's place open. If not, walk through OWNER.md's Studio item.
2. **Brix:** `git clone ../engine vendor/brix`, check out `4c21b5f` (pushed, untagged), set its origin to
   `https://github.com/drftware/brix`, then `git submodule add https://github.com/drftware/brix vendor/brix` adopts
   it, and `git submodule absorbgitdirs`. Rojo: `ReplicatedStorage.Brix` → `vendor/brix/default.project.json`.
3. **Entry points on Brix's Host:** `src/server/init.server.luau` → ServerScriptService.Server, and
   `src/client/init.client.luau` replacing `StorageUnitDoors.client.luau`. Each builds `Brix.Host.new({ systems })`,
   `start`s it, `advance`s it on Heartbeat and `stop`s it on close. Systems follow `System.luau`: `name`,
   `start(context)` that never yields, `stop()`. The client's door watcher becomes one (make
   `RollUpDoor.watchTagged` return a stop function).
4. **Place settings** in `default.project.json`: StreamingEnabled, MinRadius 64, TargetRadius 256, StreamOutBehavior
   Opportunistic; Lighting Future, ClockTime 0, Brightness 0, near-black Ambient, an Atmosphere for haze down the
   hall. Check whether Rojo 7.7.1 takes comments in project files (feel numbers want them) and whether serve can
   set Technology and StreamingEnabled; if not, set them through Studio.
5. **Import:** 3D Importer per `art/unit/README.md` "Into Studio" (if the tools can't run the dialog, the owner
   does just that), then with the tools: log each SurfaceAppearance's AlphaMode and each part's PivotOffset
   before `UnitKit.prepare`, prepare, check the bounds read about 12 x 10 x 12, move it to
   `ReplicatedStorage.Units.M`, save the place, and get `assets/units/M.rbxm` saved (Save to File).
6. **Dev corridor** (`src/server/DevCorridor.luau`, a Studio-only System; prompts call `RollUpDoor` directly):
   hall along X, 8 wide, corridor faces at z = ±4; four units a side at x = -18, -6, 6, 18, backs at z = ±16.
   Place each clone by its outer face, `RollUpDoor.frame(u) * CFrame.new(0, 0, -spec.CurtainPlane)`, with
   `u:PivotTo(target * face:ToObjectSpace(u:GetPivot()))`, and paint, number and lock before parenting. After the
   first unit in a row, drop whichever of WallLeft/WallRight sits at lower X (`dropWall` looks at direct children
   only; `Colliders` reuses those names). Hall floor top at -0.05 so it can't fight unit floors; building ceiling
   at 16 (wire tops at 10); four cold tube lights (SurfaceLight, shadows on); spawn at the -X end; during Play only,
   disable other SpawnLocations and remove a Baseplate. Prompts on an Attachment 1.5 studs into the hall, each on
   its own key or they hide each other: Peek Q, Open E, Close F, Slam G, Lock/Unlock R, plus Lift inside. Refusals
   flash the ObjectText ("Padlocked", "Shut it first"). Doors cycle the four colours, numbers 101 to 108 (odd one
   side), 105 and 108 start padlocked. Streaming: a lone unit at x = 700 with "Go far" and "Come back" prompts
   (`RequestStreamAroundAsync`, then `PivotTo`).
7. **Play** with two clients, through the tools where they reach and the owner where they don't: each door action
   looks right and the DoorCollider blocks or frees each player; bolt and padlock; paint; plates; units streaming
   out and back in with their doors in the right state. Phone-size screenshots to `docs/art/P0-02-*.png`.
8. `docs/STUDIO.md`: what the importer did (pivots, AlphaMode), what the MCP can and can't do, the corridor's
   triangle and draw-call counts. Fix anything wrong in the rig.
**Acceptance:** checks green; Brix mounted and both Hosts start clean in Play; two-client Play shows every door
action looking and blocking right for both players; screenshots saved; STUDIO.md records the importer's behaviour.
**Read first:** `art/unit/README.md` ("Into Studio", "Moving the door"); `docs/FRAMEWORK.md` (last section);
`../engine/src/Contracts/System.luau`; `src/shared/StorageUnit/UnitKit.luau` (`prepare`, `dropWall`);
`src/shared/StorageUnit/RollUpDoor.luau` (header, `frame`, `watchTagged`); `default.project.json`.

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09), then the rest of the game.
4. **Polish waiting:** judge sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
