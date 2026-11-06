# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-05, session 3 · **Checks:** green · **Git:** `storage-unit`, local only (`main` has no commits yet).

## State
- **The game runs in Studio** (P0-02): Rojo tree with night lighting and streaming; Brix mounted at `vendor/brix`
  (`4c21b5f`), a Host on each side (`src/server/init.server.luau`, `src/client/init.client.luau`); the client's
  `DoorView` system draws doors; the Studio-only `DevCorridor` system builds nine real units in Play.
- **Art goes up through Open Cloud** (D-010), as porch-pirates does: `lune run scripts/upload_unit` (key in the
  git-ignored `.config/.env`, now in place). The unit is Model asset 135739386247346, inserted and prepared into
  `ReplicatedStorage.Units.M` in Studio's place, which is still unsaved "Place1" (OWNER.md).
- **Verified in Studio, one player:** corridor builds (doors on their lines, shared walls dropped, 105 and 108
  padlocked); Open takes 2 s and draws open on the client; the collider leaves the doorway; padlock and lock-while-
  moving refuse. Not yet: prompts by key, slam, lift, streaming, counts, phone size, two players.
- The MCP's `execute_luau` can't read streaming radii or Technology (docs/STUDIO.md, Tools); Rojo serve needs the
  owner's Connect click each session.

## Next task: P0-02b The corridor, played
The moment: a friend sprints into a unit, you slam the door on them, and both screens agree it's shut.
1. Owner verdicts or test results first. Start `rojo serve default.project.json` in the background and ask the
   owner to click Connect. Check Studio still has the template (`ReplicatedStorage.Units.M`); if the place was
   lost, rebuild it per `art/unit/README.md` "Into Studio" step 2 from `art/unit/assets.json`.
2. Play (start_stop_play). Walk to 101 with `character_navigation` and press each key with `user_keyboard_input`:
   Q, E, F, G, R (Lock and Unlock), and T inside. Read results on the server (`DoorMotion`, `DoorLocked`,
   `DoorCollider` size) and look with `screen_capture`. Prompts are CoreGui, so read `prompt.ObjectText` for the
   refusal flashes ("Padlocked" at 105, "Shut it first" on an open door).
3. Check on screen: bolt and padlock appear on lock; paint colours and plates 101 to 108 read; the slam lands and
   bounces; the curtain coils on the drum with no gaps or popping.
4. Streaming: press E at the "Go far" post, then on the client check the hall's units streamed out (Workspace
   descendants), "Come back", and check each door's pose matches its `DoorMotion` after streaming back in.
5. Counts: triangles and draw calls for the hall (rbx-scene-analysis or rbx-perf-profiling skill), into STUDIO.md.
6. Phone size: Device Simulator on a small Android in landscape (rbx-device-simulator-lua), screenshots of the
   hall, an open unit and a padlocked door to `docs/art/P0-02-*.jpg`.
7. Light level: the hall reads bright for after hours (`docs/art/P0-02-hall.jpg`). Check Technology is Future
   (OWNER.md), then tune the tube lights and Ambient in `DevCorridor.luau` and `default.project.json` until a
   dead light would mean a dark stretch; note the numbers. The real fixture is P0-03's.
8. Fix anything wrong in the rig with a failing Lune spec first where it's pure. Then hand the two-player test to
   the owner (OWNER.md has it).
**Acceptance:** checks green; every prompt and refusal shown working in Play with screenshots; streaming out and
back keeps doors right; counts and phone-size shots saved; STUDIO.md updated.
**Read first:** `src/server/DevCorridor.luau`; `src/shared/StorageUnit/RollUpDoor.luau` (header, `play`,
`setLocked`); `docs/STUDIO.md` ("Getting assets into Roblox", "Tools"); `art/unit/README.md` ("Moving the door").

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09), then the rest of the game.
4. **Polish waiting:** judge sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong.
5. **Found this session:** S and L need FBXs and uploads before they can be used (`SIZES` in `upload_unit`).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
