# Code map

Where code lives, one line per module: path, then what it owns. Read only the rows your ticket
touches. This file is read on demand, never at session start; keep each row to one line.

| Path | Owns |
| --- | --- |
| `default.project.json` | Rojo tree: `src/shared` → ReplicatedStorage.Shared, `src/client` → StarterPlayerScripts.Client (P0-02 adds the server and Brix) |
| `src/shared/StorageUnit/init.luau` | The package: Curtain, Motion, RollUpDoor, UnitKit, Specs |
| `src/shared/StorageUnit/Curtain.luau` | Pure roll-up kinematics: rise → every slat's frame and the drum angle (port of `art/unit/curtain.py`) |
| `src/shared/StorageUnit/Motion.luau` | Pure door timing curves per action, targets, the replicated motion string |
| `src/shared/StorageUnit/RollUpDoor.luau` | Server `play`/`setLocked`/`rise` and the DoorCollider; client `watchTagged` rigs, the lazy slat chain, posing |
| `src/shared/StorageUnit/UnitKit.luau` | One-time `prepare` of an imported unit; `paint`, `number`, `dropWall` |
| `src/shared/StorageUnit/Specs/` | Generated per size by `art/unit/build.py --stage export`; never hand-edit |
| `src/client/StorageUnitDoors.client.luau` | Starts door rendering for every unit tagged `StorageUnit` |
| `tests/*.spec.luau` | Lune specs (curtain against Python's fixture, motion timings); `tests/fixtures/` from `art/unit/fixture.py` |
| `art/unit/` | The unit's Blender pipeline; its README is the asset's doc |
| `art/unit/out/` | Built outputs: `StorageUnit_M.fbx`, `textures/` (five sets), `M/unit.blend` |
| `art/sheets/` | Look sheets and door animations |
| `.mcp.json` | Starts Studio's MCP server so a session can drive Studio (`docs/STUDIO.md`, Tools) |
| `scripts/check.sh` | Format, lint, strict types, Rojo build, Lune tests |
| `scripts/art.sh` | Rebuild the unit's art (`SIZE=L scripts/art.sh geo export` for another size) |
| `scripts/hooks/require-handoff.sh` | Stop hook: blocks ending a turn without a written, committed handoff |
