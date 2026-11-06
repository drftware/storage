# Code map

Where code lives, one line per module: path, then what it owns. Read only the rows your ticket
touches. This file is read on demand, never at session start; keep each row to one line.

| Path | Owns |
| --- | --- |
| `default.project.json` | Rojo tree (JSON with comments): Brix → ReplicatedStorage.Brix, `src/shared` → ReplicatedStorage.Shared, `src/server` → ServerScriptService.Server, `src/client` → StarterPlayerScripts.Client; streaming and Lighting settings with what each does to the player |
| `vendor/brix/` | Brix, a git submodule pinned at `4c21b5f` (docs/FRAMEWORK.md) |
| `src/shared/StorageUnit/init.luau` | The package: Curtain, Motion, RollUpDoor, ShutIn, UnitKit, Specs |
| `src/shared/StorageUnit/Curtain.luau` | Pure roll-up kinematics: rise → every slat's frame and the drum angle (port of `art/unit/curtain.py`) |
| `src/shared/StorageUnit/Motion.luau` | Pure door timing curves per action, targets, the replicated motion string |
| `src/shared/StorageUnit/RollUpDoor.luau` | Server `play`/`setLocked`/`rise` and the DoorCollider (`ColliderDepth`, `fitCollider`); `spec`; client `watchTagged` rigs, the lazy slat chain, posing |
| `src/shared/StorageUnit/UnitKit.luau` | One-time `prepare` of an imported unit; `paint`, `number`, `dropWall` |
| `src/shared/StorageUnit/ShutIn.luau` | Pure: who a shut door hides from whom (inside the unit's room or not, door shut or not); `tests/shutin.spec.luau` |
| `src/shared/StorageUnit/Specs/` | Generated per size by `art/unit/build.py --stage export`; never hand-edit |
| `src/server/init.server.luau` | The server's Brix Host: declares its systems, steps them on Heartbeat, stops them on close |
| `src/server/DevCorridor.luau` | Studio-only system: a test hall of nine real units with a prompt per door action, and the streaming test (Go far, Come back) |
| `src/client/init.client.luau` | The client's Brix Host, stepped on RenderStepped |
| `src/client/DoorView.luau` | Client system: draws every unit's door (starts and stops `RollUpDoor.watchTagged`) |
| `src/client/BehindDoors.luau` | Client system: stops drawing anyone a shut door stands between you and (`LocalTransparencyModifier`), so arms never show through |
| `tests/*.spec.luau` | Lune specs (curtain against Python's fixture, motion timings); `tests/fixtures/` from `art/unit/fixture.py` |
| `art/unit/` | The unit's Blender pipeline; its README is the asset's doc |
| `art/unit/out/` | Built outputs: `StorageUnit_M.fbx`, `textures/` (five sets), `M/unit.blend` |
| `art/sheets/` | Look sheets and door animations |
| `.mcp.json` | Starts Studio's MCP server so a session can drive Studio (`docs/STUDIO.md`, Tools) |
| `scripts/check.sh` | Format, lint, strict types, Rojo build, Lune tests |
| `scripts/upload_unit.luau` | `lune run scripts/upload_unit [dry]`: uploads changed unit FBXs through Open Cloud, records IDs in `art/unit/assets.json` (D-010) |
| `scripts/lib/OpenCloud.luau` | Open Cloud upload and poll; reads the key from the git-ignored `.config/.env` |
| `art/unit/assets.json` | Upload manifest: size → FBX hash and Model asset ID. Written only by the upload script |
| `docs/art/` | In-game screenshots per ticket |
| `scripts/art.sh` | Rebuild the unit's art (`SIZE=L scripts/art.sh geo export` for another size) |
| `scripts/hooks/require-handoff.sh` | Stop hook: blocks ending a turn without a written, committed handoff |
