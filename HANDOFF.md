# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-05, session 4 · **Checks:** green · **Git:** `storage-unit`, local only (`main` has no commits yet).

## State
- **The corridor plays** (P0-02b, verified in Studio, one player, by key): every door action and refusal at 101 and
  105, Lift from inside, bolt and padlock, plates 101 to 108, the curtain's coil, the slam's bounce, and streaming out
  and back with every door as left. Shots in `docs/art/P0-02b-*.jpg`. No code changed this session.
- **Found: the camera passes through every unit.** Roblox's camera stops only at parts that are CanCollide and under
  0.25 transparent (docs/STUDIO.md, "Camera and prompts"). A prepared unit's colliders are invisible and its meshes
  don't collide, so in the 8-stud hall the camera backs through the shut door behind you into the unit across the
  hall (`docs/art/P0-02b-camera-inside-102.jpg`), and the prompts you face hide because their line of sight starts
  at the camera. That's P0-02c.
- Studio's place is `storage.rbxl` with the template at `ReplicatedStorage.Units.M`. A `rojo serve` from an earlier
  session was still running (port 34872, this repo); check with `lsof -iTCP:34872` before starting another.

## Next task: P0-02c The camera stays in the hall
The moment: you back away from a door with a friend behind you, and the camera stays in the hall with you.
1. Owner verdicts first: if the owner picked a camera (OWNER.md), follow it. A first-person lock still needs this fix
   only where the head can poke a wall; third person (the default for now) needs all of it.
2. Reproduce: Play, stand at (-18, 3, 0) facing 101 at default zoom; the client's `CurrentCamera` sits past z = 4
   (inside 102). Keep this as the acceptance probe.
3. Walls: in `UnitKit.prepare`, make WallLeft, WallRight, WallBack and WireTop solid (CanCollide, CanQuery,
   CollisionFidelity Box). Their bounding boxes match their spec colliders (WallLeft is 0.2 x 10 x 11.75), so the
   visible part can stand in for the box or sit beside it; keeping the spec boxes as physics truth is the safe start.
4. Shut curtain: solid on the client only while it shows. In `Rig.pose`, set CurtainClosed's CanCollide with its
   Transparency (it hides while the chain moves). Never on the server: keepers would hit an open door. Prepare sets
   its CollisionFidelity to Box. Tried live: forgetting to clear it when hidden blocks the doorway.
5. Facade: it's a 0.001-thick panel with the doorway cut out, and a decomposition fills the doorway (tried live).
   Recommended: split it in the Blender script (`art/unit/parts.py`, `parts.facade`) into three flat pieces named
   like their spec colliders (FacadeLeft, FacadeRight, Header), each solid with Box fidelity; rebuild with
   `scripts/art.sh`, upload with `lune run scripts/upload_unit`, insert and prepare per `art/unit/README.md`
   "Into Studio". If that's too heavy, say why in DECISIONS and pick another way; the doorway must stay open.
6. Re-prepare the template in Studio's Edit mode and ask the owner to save the place (OWNER.md).
7. Play and probe: back to a shut door, the camera stays in the hall; inside a shut unit it stays inside; you walk
   in and out of an open doorway freely; Lift never shows from the hall; the server's CurtainClosed never collides.
**Acceptance:** checks green; the probes above pass in Play with screenshots; STUDIO.md, CODEMAP and README updated.
**Read first:** `src/shared/StorageUnit/UnitKit.luau` (`prepare`); `src/shared/StorageUnit/RollUpDoor.luau`
(`Rig.pose`); `docs/STUDIO.md` ("Camera and prompts", "Tools"); `art/unit/README.md` ("Parts", "Into Studio");
`art/unit/parts.py` (`facade`).

## Queue (the next run's order, from ROADMAP)
1. **P0-02d The hall measured and lit:** triangle and draw-call counts, phone-size shots, the light level (too
   bright for after hours: the facades read near white).
2. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the motion-light fixture.
3. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch, padlock.
4. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09), then the rest of the game.
5. **Polish waiting:** sizes S and L by eye (they need FBXs and uploads first); a client-side door collider if the
   ~0.1 s lag feels wrong; the padlock is too small to spot from standing height.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
